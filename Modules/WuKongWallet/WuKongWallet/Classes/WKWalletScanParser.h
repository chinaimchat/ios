#import <Foundation/Foundation.h>
#import <WuKongBase/WKScanHandler.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWalletScanParser : NSObject

/// 是否属于收款码/转账扫码场景。
+ (BOOL)isReceiveQrScene:(WKScanResult *)result;

/// 从扫码 data 中解析收款 uid（兼容多层嵌套、数组和 JSON 字符串）。
+ (nullable NSString *)extractReceiveUidFromData:(id)data;

@end

NS_ASSUME_NONNULL_END
