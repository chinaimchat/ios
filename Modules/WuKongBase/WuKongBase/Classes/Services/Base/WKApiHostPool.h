//
//  WKApiHostPool.h
//  WuKongBase
//
//  多域名入口池：与 Web / Manager / Android 侧保持一致。
//  11 个候选域名全部指向同一后端；任一域名均可作为主入口。
//  与 Nginx 的 302 分流 + 客户端列表重试方案配套：
//  - 冷启动随机挑一个 host 作为初始首选（等价入口分流）；
//  - 每次请求失败由 WKAPIClient 顺序尝试下一个；
//  - 成功后把 host 回写为下一次首选，减少试错开销。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKApiHostPool : NSObject

/// 候选域名列表（固定 11 个）。
+ (NSArray<NSString *> *)hosts;

/// 当前首选 host；无缓存时随机挑一个（并写回缓存）。
+ (NSString *)preferredHost;

/// 把最近一次成功的 host 记为首选。
+ (void)savePreferredHost:(NSString *)host;

/// 以 preferredHost 为首的候选序列（去重），用于 WKAPIClient 的顺序故障切换。
+ (NSArray<NSString *> *)orderedHosts;

/// 判断 host 是否属于池内。池外（CDN/IP/第三方）一律不改写 URL。
+ (BOOL)isPoolHost:(nullable NSString *)host;

/// 默认 API base URL（含 scheme + 当前首选 host + /v1/）。
/// 用于 AppDelegate 初始化 WKAppConfig.apiBaseUrl / WKAPIClientConfig.baseUrl。
+ (NSString *)defaultApiBaseURL;

/// 默认 WS 连接 URL（wss + 当前首选 host + /ws）。
+ (NSString *)defaultConnectURL;

/// 根据错误 / 响应判断是否应该切换下一个 host：
/// - NSURLErrorDomain 的网络级错误（超时 / DNS / 连不上 / TLS）→ YES
/// - HTTP 5xx → YES
/// - 4xx / 业务错误 → NO
+ (BOOL)shouldFailoverForError:(nullable NSError *)error task:(nullable NSURLSessionTask *)task;

/// 把带业务路径的 URL 的 host 换成目标 host。
/// requestPath 可以是：
/// - 相对路径（如 "user/login"）→ 以 currentBase 为基拼接后再换 host；
/// - 绝对 URL（http(s)://...）→ 仅当当前 host 属于池内时换 host；否则原样返回。
+ (NSString *)urlStringForPath:(NSString *)requestPath
                     targetHost:(NSString *)targetHost
                    currentBase:(nullable NSURL *)currentBase;

@end

NS_ASSUME_NONNULL_END
