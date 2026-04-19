#import "WKWalletRechargeQrURL.h"
#import <WuKongBase/WuKongBase.h>

@implementation WKWalletRechargeQrURL

+ (NSString *)normalizeJsonWrappedUrl:(NSString *)t {
    if (t.length == 0) {
        return t;
    }
    if (([t hasPrefix:@"\""] && [t hasSuffix:@"\""]) || ([t hasPrefix:@"'"] && [t hasSuffix:@"'"])) {
        return [[t substringWithRange:NSMakeRange(1, t.length - 2)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return t;
}

+ (NSString *)stripLeadingV1FromRelativePath:(NSString *)path {
    if (path.length == 0) {
        return path;
    }
    NSString *p = path;
    NSString *lower = [p lowercaseString];
    if ([lower hasPrefix:@"v1/"]) {
        p = [p substringFromIndex:3];
    } else if ([lower isEqualToString:@"v1"]) {
        p = @"";
    }
    return p;
}

+ (NSString *)encodePathSegmentsForUrl:(NSString *)path {
    if (path.length == 0) {
        return path;
    }
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *seg in [path componentsSeparatedByString:@"/"]) {
        if (seg.length == 0) {
            continue;
        }
        NSString *enc = [seg stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        [parts addObject:enc ?: seg];
    }
    return [parts componentsJoinedByString:@"/"];
}

+ (NSString *)collapseDuplicateV1InUrl:(NSString *)urlStr {
    if (urlStr.length == 0) {
        return urlStr;
    }
    NSRange r = [urlStr rangeOfString:@"/v1/v1/"];
    if (r.location == NSNotFound) {
        return urlStr;
    }
    NSMutableString *m = [urlStr mutableCopy];
    while ([m rangeOfString:@"/v1/v1/"].location != NSNotFound) {
        [m replaceOccurrencesOfString:@"/v1/v1/" withString:@"/v1/" options:0 range:NSMakeRange(0, m.length)];
    }
    return m;
}

+ (NSString *)apiBaseUrlV1 {
    NSString *base = [WKAPIClient sharedClient].config.baseUrl ?: @"";
    if (base.length == 0) {
        return @"";
    }
    if ([base hasSuffix:@"/"]) {
        return base;
    }
    return [base stringByAppendingString:@"/"];
}

+ (NSString *)getShowUrl:(NSString *)url {
    if (url.length == 0) {
        return url;
    }
    NSString *t = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lower = [t lowercaseString];
    if ([lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"]) {
        return [self collapseDuplicateV1InUrl:t];
    }
    NSString *base = [self apiBaseUrlV1];
    if (base.length == 0) {
        return t;
    }
    while ([t hasPrefix:@"/"]) {
        t = [t substringFromIndex:1];
    }
    t = [self stripLeadingV1FromRelativePath:t];
    NSString *encoded = [self encodePathSegmentsForUrl:t];
    return [self collapseDuplicateV1InUrl:[NSString stringWithFormat:@"%@%@", base, encoded]];
}

+ (NSString *)getFilePreviewShowUrl:(NSString *)relativePath {
    if (relativePath.length == 0) {
        return relativePath;
    }
    NSString *p = [relativePath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lower = [p lowercaseString];
    if ([lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"] || [lower hasPrefix:@"data:image"]) {
        return [self collapseDuplicateV1InUrl:p];
    }
    while ([p hasPrefix:@"/"]) {
        p = [p substringFromIndex:1];
    }
    p = [self stripLeadingV1FromRelativePath:p];
    NSString *lower2 = [p lowercaseString];
    NSString *pathForEncode;
    if ([lower2 hasPrefix:@"file/preview/"] || [lower2 isEqualToString:@"file/preview"]) {
        pathForEncode = p;
    } else {
        pathForEncode = [NSString stringWithFormat:@"file/preview/%@", p];
    }
    NSString *encoded = [self encodePathSegmentsForUrl:pathForEncode];
    NSString *base = [self apiBaseUrlV1];
    return [self collapseDuplicateV1InUrl:[NSString stringWithFormat:@"%@%@", base, encoded]];
}

+ (NSString *)absoluteURLStringForChannelQrRaw:(NSString *)raw {
    NSString *t = [self normalizeJsonWrappedUrl:[raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    if (t.length == 0) {
        return @"";
    }
    NSString *lower = [t lowercaseString];
    if ([lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"] || [lower hasPrefix:@"data:image"]) {
        return [self collapseDuplicateV1InUrl:t];
    }
    NSString *l2 = [t lowercaseString];
    if ([l2 hasPrefix:@"file/preview"] || [l2 containsString:@"recharge_qr"]) {
        return [self getFilePreviewShowUrl:t];
    }
    return [self getShowUrl:t];
}

@end
