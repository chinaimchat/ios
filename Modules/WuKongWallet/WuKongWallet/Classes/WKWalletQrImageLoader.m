#import "WKWalletQrImageLoader.h"
#import "WKWalletRechargeQrURL.h"
#import <WuKongBase/WuKongBase.h>

@interface WKWalletQrHopDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property (nonatomic, copy) void (^completion)(NSData *_Nullable data, NSHTTPURLResponse *_Nullable resp, NSError *_Nullable err);
@property (nonatomic, strong) NSMutableData *accum;
@end

@implementation WKWalletQrHopDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _accum = [NSMutableData data];
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.accum appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse *http = nil;
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        http = (NSHTTPURLResponse *)task.response;
    }
    if (self.completion) {
        self.completion(self.accum, http, error);
    }
    self.completion = nil;
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    (void)response;
    (void)request;
    completionHandler(nil);
}

@end

static BOOL WKWalletQrPathNeedsAuthHeaders(NSURL *url) {
    if (!url) {
        return NO;
    }
    NSString *p = url.path.lowercaseString;
    return [p containsString:@"/v1/file/preview"];
}

static void WKWalletQrApplyPublicHeaders(NSMutableURLRequest *req) {
    NSDictionary *(^block)(void) = [WKAPIClient sharedClient].config.publicHeaderBLock;
    if (!block) {
        return;
    }
    NSDictionary *h = block();
    if (![h isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [h enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *_Nonnull stop) {
        (void)stop;
        [req setValue:[NSString stringWithFormat:@"%@", obj] forHTTPHeaderField:key];
    }];
}

static BOOL WKWalletQrPerformAuthNoRedirectHop(NSURL *url, NSData *__autoreleasing *outData, NSHTTPURLResponse *__autoreleasing *outResp, NSError *__autoreleasing *outErr) {
    WKWalletQrHopDelegate *del = [[WKWalletQrHopDelegate alloc] init];
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    cfg.timeoutIntervalForRequest = 120;
    cfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg delegate:del delegateQueue:nil];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    WKWalletQrApplyPublicHeaders(req);

    __block NSData *got = nil;
    __block NSHTTPURLResponse *hr = nil;
    __block NSError *er = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    del.completion = ^(NSData *d, NSHTTPURLResponse *r, NSError *e) {
        got = d;
        hr = r;
        er = e;
        dispatch_semaphore_signal(sem);
    };

    [[session dataTaskWithRequest:req] resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    if (outData) {
        *outData = got;
    }
    if (outResp) {
        *outResp = hr;
    }
    if (outErr) {
        *outErr = er;
    }
    return YES;
}

static NSData *WKWalletQrFetchBareFollowingRedirects(NSURL *url, NSError *__autoreleasing *outErr) {
    __block NSData *bd = nil;
    __block NSError *be = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        bd = data;
        be = error;
        if (!be && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger c = [(NSHTTPURLResponse *)response statusCode];
            if (c < 200 || c >= 300) {
                be = [NSError errorWithDomain:@"WKWalletQrImageLoader" code:(int)c userInfo:@{ NSLocalizedDescriptionKey: @"HTTP error" }];
            }
        }
        dispatch_semaphore_signal(sem);
    }] resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    if (outErr) {
        *outErr = be;
    }
    return bd;
}

@implementation WKWalletQrImageLoader

+ (UIImage *)qrImageFromString:(NSString *)string side:(CGFloat)side {
    if (string.length == 0 || side < 1) {
        return nil;
    }
    NSData *data = [string dataUsingEncoding:NSISOLatin1StringEncoding];
    if (!data.length) {
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *out = filter.outputImage;
    if (!out) {
        return nil;
    }
    CGFloat scale = side / out.extent.size.width;
    CGAffineTransform t = CGAffineTransformMakeScale(scale, scale);
    CIImage *scaled = [out imageByApplyingTransform:t];
    CIContext *ctx = [CIContext contextWithOptions:nil];
    CGImageRef cg = [ctx createCGImage:scaled fromRect:scaled.extent];
    if (!cg) {
        return nil;
    }
    UIImage *img = [UIImage imageWithCGImage:cg scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp];
    CGImageRelease(cg);
    return img;
}

+ (void)loadImageFromURL:(NSURL *)url completion:(void (^)(UIImage *_Nullable))completion {
    if (!url) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, __unused NSURLResponse *response, __unused NSError *error) {
        UIImage *img = nil;
        if (data.length) {
            img = [UIImage imageWithData:data];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(img);
            }
        });
    }];
    [task resume];
}

+ (void)loadRechargeChannelQrImageWithRawString:(NSString *)raw completion:(void (^)(UIImage *_Nullable))completion {
    NSString *abs = [WKWalletRechargeQrURL absoluteURLStringForChannelQrRaw:raw ?: @""];
    if (abs.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
        return;
    }
    NSURL *first = [NSURL URLWithString:abs];
    if (!first) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSURL *current = first;
        NSData *finalData = nil;
        for (int hop = 0; hop < 10; hop++) {
            NSString *path = current.path.lowercaseString ?: @"";
            if ([path containsString:@"file/upload"]) {
                finalData = nil;
                break;
            }
            if (WKWalletQrPathNeedsAuthHeaders(current)) {
                NSData *body = nil;
                NSHTTPURLResponse *resp = nil;
                NSError *e1 = nil;
                WKWalletQrPerformAuthNoRedirectHop(current, &body, &resp, &e1);
                if (e1) {
                    finalData = nil;
                    break;
                }
                NSInteger code = resp.statusCode;
                if (code >= 300 && code < 400) {
                    NSString *loc = resp.allHeaderFields[@"Location"];
                    if (loc.length == 0) {
                        loc = resp.allHeaderFields[@"location"];
                    }
                    if (loc.length == 0) {
                        finalData = nil;
                        break;
                    }
                    NSURL *next = [NSURL URLWithString:loc relativeToURL:current];
                    current = next.absoluteURL;
                    continue;
                }
                if (code >= 200 && code < 300) {
                    finalData = body;
                    break;
                }
                finalData = nil;
                break;
            } else {
                NSError *e2 = nil;
                finalData = WKWalletQrFetchBareFollowingRedirects(current, &e2);
                if (e2) {
                    finalData = nil;
                }
                break;
            }
        }

        UIImage *img = finalData.length ? [UIImage imageWithData:finalData] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(img);
            }
        });
    });
}

@end
