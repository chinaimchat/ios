#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWalletQrImageLoader : NSObject

/// 由地址本地生成二维码（对齐 Android {@code WalletQrEncodeUtil.encodeQrBitmap}）。
+ (nullable UIImage *)qrImageFromString:(NSString *)string side:(CGFloat)side;

/// 异步拉取图片 URL（无业务 Header；仅适用于可匿名访问的地址）。
+ (void)loadImageFromURL:(NSURL *)url completion:(void (^)(UIImage *_Nullable image))completion;

/**
 * 充值渠道收款码：与 Android {@code OkHttpUtils#fetchGatewayThenBareRedirect} 一致——
 * {@code /v1/file/preview} 首跳带业务 Header 且不自动跟随重定向，后续跳使用裸 GET 并允许跟随至 OSS。
 * {@code raw} 为接口返回的原始字符串（可为相对路径），内部按 WKWalletRechargeQrURL 拼绝对 URL。
 */
+ (void)loadRechargeChannelQrImageWithRawString:(NSString *)raw completion:(void (^)(UIImage *_Nullable image))completion;

@end

NS_ASSUME_NONNULL_END
