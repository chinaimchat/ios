//
//  WKApiHostPool.m
//  WuKongBase
//

#import "WKApiHostPool.h"
#import "WKApp.h"

static NSString * const kPreferredHostKey = @"preferred_api_host";

/// 首选 host 变化时，联动更新 WKApp.shared.config 的系列 URL。
/// 目的：SDWebImage / WKImageView 等 SPA 外的资源加载器会按 fileBrowseUrl / imageBrowseUrl
/// 拼出完整 URL；若这些字段写死在启动瞬间的 host 上，运行期域名切换时新拉的图仍旧命中死域名。
static void _updateAppConfigURLsForHost(NSString *host) {
    if (host.length == 0) return;
    WKAppConfig *config = [WKApp shared].config;
    if (config == nil) return;
    NSString *scheme = @"https";
    NSURL *apiURL = [NSURL URLWithString:config.apiBaseUrl];
    if (apiURL.scheme.length > 0) {
        scheme = apiURL.scheme;
    }
    NSString *newBase = [NSString stringWithFormat:@"%@://%@/v1/", scheme, host];
    NSString *newWebBase = [NSString stringWithFormat:@"%@://%@/web/", scheme, host];
    NSString *newWS = [NSString stringWithFormat:@"wss://%@/ws", host];

    void (^apply)(void) = ^{
        config.apiBaseUrl = newBase;
        config.fileBaseUrl = newBase;
        config.fileBrowseUrl = newBase;
        config.imageBrowseUrl = newBase;
        config.reportUrl = [NSString stringWithFormat:@"%@report/html", newBase];
        config.privacyAgreementUrl = [NSString stringWithFormat:@"%@privacy_policy.html", newWebBase];
        config.userAgreementUrl = [NSString stringWithFormat:@"%@user_agreement.html", newWebBase];
        // 不改写 connectURL：IM 长连接由 setGetConnectAddr 回调（走 /v1/users/{uid}/im 拿 tcp_addr）提供真实地址；
        // connectURL 只是 clusterOn==NO 时的兜底，保持初始值即可，避免打断在线长连。
    };
    if ([NSThread isMainThread]) {
        apply();
    } else {
        dispatch_async(dispatch_get_main_queue(), apply);
    }
}

@implementation WKApiHostPool

+ (NSArray<NSString *> *)hosts {
    static NSArray<NSString *> *_hosts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hosts = @[
            @"coolapq.com",
            @"nykjh.com",
            @"lwijf.com",
            @"lhqrx.com",
            @"lqxybw.cn",
            @"vowjyo.cn",
            @"pifqtq.cn",
            @"xegjzf.cn",
            @"hailsv.cn",
            @"wvyexex.cn",
            @"xwxxkxl.cn",
        ];
    });
    return _hosts;
}

+ (NSString *)preferredHost {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *cached = [defaults stringForKey:kPreferredHostKey];
    NSArray<NSString *> *hosts = [self hosts];
    if (cached.length > 0 && [hosts containsObject:cached]) {
        return cached;
    }
    uint32_t idx = arc4random_uniform((uint32_t)hosts.count);
    NSString *picked = hosts[idx];
    [defaults setObject:picked forKey:kPreferredHostKey];
    [defaults synchronize];
    return picked;
}

+ (void)savePreferredHost:(NSString *)host {
    if (host.length == 0) return;
    if (![[self hosts] containsObject:host]) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *cur = [defaults stringForKey:kPreferredHostKey];
    if ([cur isEqualToString:host]) return;
    [defaults setObject:host forKey:kPreferredHostKey];
    [defaults synchronize];
    // 让 config 里的图片/文件/Web URL 立即跟上新 host，避免 SDWebImage 等走死域名。
    _updateAppConfigURLsForHost(host);
}

+ (NSArray<NSString *> *)orderedHosts {
    NSString *preferred = [self preferredHost];
    NSMutableArray<NSString *> *ordered = [NSMutableArray arrayWithCapacity:[self hosts].count];
    [ordered addObject:preferred];
    for (NSString *h in [self hosts]) {
        if (![h isEqualToString:preferred]) {
            [ordered addObject:h];
        }
    }
    return [ordered copy];
}

+ (BOOL)isPoolHost:(NSString *)host {
    if (host.length == 0) return NO;
    return [[self hosts] containsObject:host];
}

+ (NSString *)defaultApiBaseURL {
    return [NSString stringWithFormat:@"https://%@/v1/", [self preferredHost]];
}

+ (NSString *)defaultConnectURL {
    return [NSString stringWithFormat:@"wss://%@/ws", [self preferredHost]];
}

+ (BOOL)shouldFailoverForError:(NSError *)error task:(NSURLSessionTask *)task {
    if (error == nil) return NO;

    // 1) AFN 把 HTTP 非 2xx 包在 error 里，response 存在 error.userInfo 里。
    NSHTTPURLResponse *httpResp = error.userInfo[@"com.alamofire.serialization.response.error.response"];
    if (httpResp == nil && [task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResp = (NSHTTPURLResponse *)task.response;
    }
    if (httpResp && httpResp.statusCode >= 500 && httpResp.statusCode <= 599) {
        return YES;
    }
    if (httpResp && httpResp.statusCode >= 400 && httpResp.statusCode <= 499) {
        // 4xx 是业务错，不切换（否则所有候选都会被探测一遍）。
        return NO;
    }

    // 2) 网络级错误：NSURLErrorDomain + 一组"连不上"错误码。
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorTimedOut:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorDNSLookupFailed:
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorSecureConnectionFailed:
            case NSURLErrorServerCertificateUntrusted:
            case NSURLErrorServerCertificateHasBadDate:
            case NSURLErrorServerCertificateHasUnknownRoot:
            case NSURLErrorServerCertificateNotYetValid:
            case NSURLErrorClientCertificateRejected:
            case NSURLErrorDataNotAllowed:
                return YES;
            default:
                return NO;
        }
    }
    return NO;
}

+ (NSString *)urlStringForPath:(NSString *)requestPath
                     targetHost:(NSString *)targetHost
                    currentBase:(NSURL *)currentBase {
    if (requestPath.length == 0 || targetHost.length == 0) {
        return requestPath ?: @"";
    }

    // 绝对 URL
    if ([requestPath hasPrefix:@"http://"] || [requestPath hasPrefix:@"https://"]) {
        NSURLComponents *comps = [NSURLComponents componentsWithString:requestPath];
        if (comps == nil || comps.host.length == 0) {
            return requestPath;
        }
        // 第三方 URL（不在池中）不改写，原样返回。
        if (![self isPoolHost:comps.host]) {
            return requestPath;
        }
        comps.host = targetHost;
        return comps.string ?: requestPath;
    }

    // 相对路径：以 currentBase（形如 https://HOST/v1/）为基，替换 host。
    NSString *scheme = currentBase.scheme.length > 0 ? currentBase.scheme : @"https";
    NSString *basePath = currentBase.path.length > 0 ? currentBase.path : @"/v1";
    NSString *trimmedBase = [basePath hasSuffix:@"/"] ? [basePath substringToIndex:basePath.length - 1] : basePath;
    NSString *relative = [requestPath hasPrefix:@"/"] ? requestPath : [@"/" stringByAppendingString:requestPath];
    return [NSString stringWithFormat:@"%@://%@%@%@", scheme, targetHost, trimmedBase, relative];
}

@end
