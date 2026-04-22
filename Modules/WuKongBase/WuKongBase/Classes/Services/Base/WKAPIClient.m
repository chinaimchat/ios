//
//  WKAPIClient.m
//  Common
//
//  Created by tt on 2018/9/12.
//

#import "WKAPIClient.h"
#import <PromiseKit/PromiseKit.h>
#import "WKLogs.h"
#import "WKModel.h"
#import "WKApp.h"
#import "WKApiHostPool.h"
#import <objc/objc.h>

@implementation  WKAPIClientConfig

-(void) setPublicHeaderBLock:(NSDictionary*(^)(void)) headerBLock{
    _publicHeaderBLock = headerBLock;
}

@end

//static AFHTTPSessionManager *_sessionManager;

@interface WKAPIClient()
@property(nonatomic,strong) AFHTTPSessionManager *sessionManager;
@end
@implementation WKAPIClient

+ (instancetype)sharedClient {
    static WKAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[WKAPIClient alloc] init];
    });
    
    return _sharedClient;
}

-(void) setConfig:(WKAPIClientConfig*)config{
    _config = config;
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:config.baseUrl]];
    if([config.baseUrl hasPrefix:@"https"]) {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        _sessionManager.securityPolicy = securityPolicy;
    }
//     if (config.httpsOn) {
//
//     }
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI =  [NSSet setWithObjects:@"GET", @"HEAD", nil];
}




-(AnyPromise*) GET:(NSString*)path parameters:(nullable id)parameters model:(Class) modelClass {
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    __weak typeof(self) weakSelf = self;
    return [self GET:[self pathURLEncode:requestPath] parameters:parameters].then(^(id responseObj){
        
        return [weakSelf resultToModel:responseObj model:modelClass];
    });
}


-(NSURLSessionDataTask*) taskGET:(NSString*)path parameters:(nullable id)parameters model:(Class)modelClass callback:(void(^)(NSError *error,id result))callback{
    __weak typeof(self) weakSelf = self;
    return [self taskGET:[self pathURLEncode:path] parameters:parameters callback:^(NSError *error, id result) {
        if(error) {
            if(callback) {
                callback(error,nil);
            }
            return;
        }
        if(callback) {
            callback(nil,[weakSelf resultToModel:result model:modelClass]);
        }
    }];
}

-(NSURLSessionDataTask*) taskGET:(NSString*)path parameters:(nullable id)parameters callback:(void(^)(NSError *error,id result))callback{
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self logRequestStart:requestPath params:parameters method:@"GET"];
    __weak typeof(self) weakSelf = self;
    [weakSelf resetPublicHeader];
   NSURLSessionDataTask *task =[weakSelf.sessionManager GET:[NSString stringWithFormat:@"%@",[self pathURLEncode:requestPath]] parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       [weakSelf logRequestEnd:task response:responseObject];
       if(callback) {
           callback(nil,responseObject);
       }
   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       NSError *er;
       if(weakSelf.config.errorHandler){
          er =  weakSelf.config.errorHandler(nil,error);
       }
       if(!er) {
           er = error;
       }
       if(callback) {
           callback(error,nil);
       }
   }];
    return  task;
}

-(AnyPromise*) GET:(NSString*)path parameters:(nullable id)parameters {
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self logRequestStart:requestPath params:parameters method:@"GET"];
    __weak typeof(self) weakSelf = self;
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [weakSelf performMethod:@"GET"
                     requestPath:[weakSelf pathURLEncode:requestPath]
                      parameters:parameters
                         headers:nil
                        resolver:resolve];
    }];
}

-(NSString*) pathURLEncode:(NSString*)path {
    return [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

-(AnyPromise*) POST:(NSString*)path parameters:(nullable id)parameters model:(Class) modelClass{
    __weak typeof(self) weakSelf = self;
    return [weakSelf POST:path parameters:parameters].then(^(id responseObj){
        
        return [self resultToModel:responseObj model:modelClass];
    });
}

-(NSURLSessionDataTask*) fileUpload:(NSString*)path data:(NSData*)data progress:(void(^)(NSProgress *progress)) progressCallback completeCallback:(void(^)(id resposeObject,NSError *error)) completeCallback {
    return [self fileUpload:path data:data fileName:@"filename" progress:progressCallback completeCallback:completeCallback];
    
}

-(NSURLSessionDataTask*) fileUpload:(NSString*)path data:(NSData*)data fileName:(NSString*)fileName progress:(void(^)(NSProgress *progress)) progressCallback completeCallback:(void(^)(id resposeObject,NSError *error)) completeCallback {
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self resetPublicHeader];
    NSString *mimeType = @"application/octet-stream";
    NSString *ext = fileName.pathExtension.lowercaseString;
    if([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
        mimeType = @"image/jpeg";
    } else if([ext isEqualToString:@"png"]) {
        mimeType = @"image/png";
    } else if([ext isEqualToString:@"gif"]) {
        mimeType = @"image/gif";
    } else if([ext isEqualToString:@"mp4"]) {
        mimeType = @"video/mp4";
    } else if([ext isEqualToString:@"mov"]) {
        mimeType = @"video/quicktime";
    }
    return  [_sessionManager POST:[self pathURLEncode:requestPath] parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
      [formData appendPartWithFileData:data name:@"file" fileName:fileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if(progressCallback) {
            progressCallback(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(completeCallback) {
            completeCallback(responseObject,nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(completeCallback) {
            completeCallback(nil,error);
        }
    }];
}

-(NSURLSessionDataTask*) fileUpload:(NSString*)path fileURL:(NSString*)fileUrl progress:(void(^)(NSProgress *progress)) progressCallback completeCallback:(void(^)(id resposeObject,NSError *error)) completeCallback {
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self resetPublicHeader];
    return  [_sessionManager POST:[self pathURLEncode:requestPath] parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *fileError;
        [formData appendPartWithFileURL:[NSURL URLWithString:fileUrl] name:@"file" error:&fileError];
      if(fileError) {
          WKLogError(@"fileError-> %@",fileError);
      }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if(progressCallback) {
            progressCallback(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(completeCallback) {
            completeCallback(responseObject,nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(completeCallback) {
            completeCallback(nil,error);
        }
    }];
    
}

-(void) uploadChatFile:(NSString*)serverPath localURL:(NSURL*)localURL progress:(void(^_Nullable)(NSProgress * _Nonnull progress)) progressCallback completeCallback:(void(^_Nullable)(id __nullable resposeObject,NSError * __nullable error)) completeCallback {
    [self getChatUploadURL:serverPath].then(^(NSDictionary*result){
        NSString *uploadUrl = result[@"url"];
        [self fileUpload:uploadUrl fileURL:localURL.absoluteString progress:progressCallback completeCallback:completeCallback];
    }).catch(^(NSError *error){
        if(completeCallback) {
            completeCallback(nil,error);
        }
    });
}

// 获取上传地址
-(AnyPromise*) getChatUploadURL:(NSString*)path{
    return  [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"%@file/upload?path=%@&type=chat",[WKApp shared].config.fileBaseUrl,path] parameters:nil];
}

-(NSURLSessionDownloadTask*) createDownloadTask:(NSString*)path storePath:(NSString*_Nonnull)storePath progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock completeCallback:(void(^)(NSError *error)) completeCallback{
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
     NSMutableURLRequest *request = [_sessionManager.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:[self pathURLEncode:requestPath] relativeToURL:_sessionManager.baseURL] absoluteString] parameters:nil error:nil];
   NSURLSessionDownloadTask *task = [_sessionManager downloadTaskWithRequest:request progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:storePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if(completeCallback) {
            completeCallback(error);
        }
    }];
    return task;
}

-(NSURLSessionDataTask*) createFileUploadTask:(NSString*)path fileURL:(NSString*)fileUrl  progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completeCallback:(void(^)(id responseObj,NSError *error)) completeCallback{
    
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [_sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:[self pathURLEncode:requestPath] relativeToURL:_sessionManager.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *fileError;
        [formData appendPartWithFileURL:[NSURL URLWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] name:@"file" error:&fileError];
        if(fileError) {
            WKLogError(@"file: %@ fileError-> %@",fileUrl,fileError);
            if (completeCallback) {
                completeCallback(nil, fileError);
            }
            
        }
    } error:&serializationError];
    if (serializationError) {
        if (completeCallback) {
            dispatch_async(_sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                completeCallback(nil,serializationError);
            });
        }
        
        return nil;
    }
    __block NSURLSessionDataTask *task = [_sessionManager uploadTaskWithStreamedRequest:request progress:uploadProgressBlock completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (completeCallback) {
                completeCallback(nil, error);
            }
        } else {
            if (completeCallback) {
                completeCallback(responseObject, nil);
            }
        }
    }];
    
    return task;
}

-(AnyPromise*) POST:(NSString*)path parameters:(nullable id)parameters{
    return [self POST:path parameters:parameters headers:nil];
}

-(AnyPromise*_Nonnull) POST:(NSString*_Nonnull)path parameters:(nullable id)parameters headers:(NSDictionary*)headers {
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self logRequestStart:requestPath params:parameters method:@"POST"];
    __weak typeof(self) weakSelf = self;
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [weakSelf performMethod:@"POST"
                    requestPath:[weakSelf pathURLEncode:requestPath]
                     parameters:parameters
                        headers:headers
                       resolver:resolve];
    }];
}

-(AnyPromise*) DELETE:(NSString*)path parameters:(nullable id)parameters{
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self logRequestStart:requestPath params:parameters method:@"DELETE"];
    __weak typeof(self) weakSelf = self;
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [weakSelf performMethod:@"DELETE"
                    requestPath:[weakSelf pathURLEncode:requestPath]
                     parameters:parameters
                        headers:nil
                       resolver:resolve];
    }];
}

-(AnyPromise*) PUT:(NSString*)path parameters:(nullable id)parameters{
    NSString *requestPath = path;
    if(_config.requestPathReplace) {
        requestPath = _config.requestPathReplace(path);
    }
    [self logRequestStart:requestPath params:parameters method:@"PUT"];
    __weak typeof(self) weakSelf = self;
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [weakSelf performMethod:@"PUT"
                    requestPath:[weakSelf pathURLEncode:requestPath]
                     parameters:parameters
                        headers:nil
                       resolver:resolve];
    }];
}

#pragma mark - 多域名故障切换

/**
 统一的"域名列表重试"执行器。
 按 WKApiHostPool.orderedHosts 顺序依次尝试；遇到网络级错误或 5xx 自动切到下一个 host。
 - 成功：把当前 host 记为首选（savePreferredHost），后续请求直接命中。
 - 全部失败：把最后一次错误 resolve 给上层，行为与原实现一致（不改变业务层错误处理）。
 */
- (void)performMethod:(NSString *)method
           requestPath:(NSString *)requestPath
            parameters:(id)parameters
               headers:(NSDictionary<NSString *, NSString *> *)headers
              resolver:(PMKResolver)resolve {
    NSArray<NSString *> *orderedHosts = [WKApiHostPool orderedHosts];
    [self attemptMethod:method
            requestPath:requestPath
             parameters:parameters
                headers:headers
                  hosts:orderedHosts
              hostIndex:0
               resolver:resolve];
}

- (void)attemptMethod:(NSString *)method
           requestPath:(NSString *)requestPath
            parameters:(id)parameters
               headers:(NSDictionary<NSString *, NSString *> *)headers
                 hosts:(NSArray<NSString *> *)hosts
             hostIndex:(NSUInteger)hostIndex
              resolver:(PMKResolver)resolve {
    if (hostIndex >= hosts.count) {
        NSError *err = [NSError errorWithDomain:@"WKAPIClient"
                                           code:-1001
                                       userInfo:@{NSLocalizedDescriptionKey:@"所有候选域名均不可用，请检查网络"}];
        resolve(err);
        return;
    }
    NSString *host = hosts[hostIndex];
    NSString *urlString = [WKApiHostPool urlStringForPath:requestPath
                                                targetHost:host
                                               currentBase:self.sessionManager.baseURL];

    [self resetPublicHeader];
    __weak typeof(self) weakSelf = self;

    void (^onSuccess)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf logRequestEnd:task response:responseObject];
        [WKApiHostPool savePreferredHost:host];
        resolve(PMKManifold(responseObject, task));
    };
    void (^onFailure)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
        if ([WKApiHostPool shouldFailoverForError:error task:task] && hostIndex + 1 < hosts.count) {
            WKLogDebug(@"[域名切换] %@ 失败(%ld)，尝试下一个 host", host, (long)error.code);
            [weakSelf attemptMethod:method
                        requestPath:requestPath
                         parameters:parameters
                            headers:headers
                              hosts:hosts
                          hostIndex:hostIndex + 1
                           resolver:resolve];
            return;
        }
        NSError *er;
        if (weakSelf.config.errorHandler) {
            er = weakSelf.config.errorHandler(nil, error);
        }
        if (!er) {
            er = error;
        }
        resolve(er);
    };

    if ([method isEqualToString:@"GET"]) {
        NSURLSessionDataTask *t = [self.sessionManager GET:urlString
                                                parameters:parameters
                                                   headers:headers
                                                  progress:nil
                                                   success:onSuccess
                                                   failure:onFailure];
        [t resume];
    } else if ([method isEqualToString:@"POST"]) {
        [self.sessionManager POST:urlString
                       parameters:parameters
                          headers:headers
                         progress:nil
                          success:onSuccess
                          failure:onFailure];
    } else if ([method isEqualToString:@"PUT"]) {
        [self.sessionManager PUT:urlString
                      parameters:parameters
                         headers:headers
                         success:onSuccess
                         failure:onFailure];
    } else if ([method isEqualToString:@"DELETE"]) {
        [self.sessionManager DELETE:urlString
                         parameters:parameters
                            headers:headers
                            success:onSuccess
                            failure:onFailure];
    } else {
        NSError *err = [NSError errorWithDomain:@"WKAPIClient" code:-1002
                                       userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"unsupported method: %@", method]}];
        resolve(err);
    }
}


// 重置公共header
-(void) resetPublicHeader{
    if (self.config.publicHeaderBLock){
        NSDictionary *headers = self.config.publicHeaderBLock();
        __weak typeof(self) weakSelf = self;
        if(headers){
            [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [weakSelf.sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
    }
}

- (BOOL)isURLHostTrustedForAPIAuth:(NSURL *)url {
    // 是否给 WebView/外部跳转的 URL 自动附带 token。
    //
    // 历史实现只对比 host：当服务端把二维码 URL 的 host 配成与 apiBaseUrl 不同的子域
    // （例如 apiBaseUrl=`http://www.tu2t0.com/v1/`，二维码=`http://web.tu2t0.com/api/v1/qrcode/<uuid>`）
    // 时，WebView 不会带 token，server 端 AuthMiddleware 直接 401，用户在 App 里只能
    // 看到一串 URL，无法走「确认登录」/ 加好友等业务。
    //
    // 这里与 Android `ScanUtils.handleScanResult` 保持一致的精神：除了 host 白名单之外，
    // 只要 URL 的 path 命中已知 API 段（当前仅放开 `/qrcode/`），也视为可信；
    // 这样跨子域的二维码也能附带 token，但不会给随便一个第三方网页加 token。
    if (!url.host.length) {
        return NO;
    }
    NSString *host = url.host.lowercaseString;
    NSString *apiBase = [WKApp shared].config.apiBaseUrl ?: @"";
    if (apiBase.length) {
        NSURL *apiURL = [NSURL URLWithString:apiBase];
        if (apiURL.host.length && [apiURL.host.lowercaseString isEqualToString:host]) {
            return YES;
        }
    }
    NSString *scan = [WKApp shared].config.scanURLPrefix ?: @"";
    if (scan.length) {
        NSURL *scanURL = [NSURL URLWithString:scan];
        if (scanURL.host.length && [scanURL.host.lowercaseString isEqualToString:host]) {
            return YES;
        }
    }
    // 跨 host 兜底：path 含 `/qrcode/` 视为业务二维码 URL（与 Android 仅按 path 判定的策略对齐）。
    if (url.path.length && [url.path containsString:@"/qrcode/"]) {
        return YES;
    }
    return NO;
}

- (void)attachPublicHTTPHeadersForWebViewIfNeeded:(NSMutableURLRequest *)request {
    if (!request.URL || ![self isURLHostTrustedForAPIAuth:request.URL]) {
        return;
    }
    if (!self.config.publicHeaderBLock) {
        return;
    }
    NSDictionary *headers = self.config.publicHeaderBLock();
    [headers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]] && [(NSString *)obj length] > 0) {
            [request setValue:obj forHTTPHeaderField:key];
        }
    }];
}

-(id) resultToModel:(id)responseObj model:(Class)modelClass{
    __weak typeof(self) weakSelf = self;
    id resultObj = responseObj;
    if(modelClass){
        if([responseObj isKindOfClass:[NSDictionary class]]){
            resultObj = [weakSelf dictToModel:responseObj modelClass:modelClass];
        }
        if([responseObj isKindOfClass:[NSArray class]]){
            NSMutableArray *modelList = [[NSMutableArray alloc] init];
            [(NSArray*)responseObj enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [modelList addObject:[weakSelf dictToModel:obj modelClass:modelClass]];
            }];
            
            resultObj =modelList;
        }
    }
    return resultObj;
}

-(WKModel*) dictToModel:(NSDictionary*)dic modelClass:(Class)modelClass{
    SEL sel = NSSelectorFromString(@"fromMap:type:");
    IMP imp = [modelClass methodForSelector:sel];
    WKModel* (*convertMap)(id, SEL,NSDictionary*,ModelMapType) = (void *)imp;
    WKModel *model = convertMap(modelClass,sel,dic,ModelMapTypeAPI);
    return model;
}

-(void) logRequestStart:(NSString*)path params:(id)params method:(NSString*)method{
    if([path hasPrefix:@"http"]) {
         WKLogDebug(@"请求：%@ %@",method,path);
    }else {
         WKLogDebug(@"请求：%@ %@%@",method,self.config.baseUrl,path);
    }
   
    WKLogDebug(@"请求参数：%@",params);
}


-(void) logRequestEnd:(NSURLSessionDataTask*)task response:(id)response{
    WKLogDebug(@"返回：%@",response);
}

@end
