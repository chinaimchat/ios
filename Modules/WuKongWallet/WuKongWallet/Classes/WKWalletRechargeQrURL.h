#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android {@code WKApiConfig#getRechargeChannelQrImageLoadUrl} 一致：相对路径、预览路径、绝对 URL 的拼接与规范化。
@interface WKWalletRechargeQrURL : NSObject

+ (NSString *)absoluteURLStringForChannelQrRaw:(NSString *)raw;

@end

NS_ASSUME_NONNULL_END
