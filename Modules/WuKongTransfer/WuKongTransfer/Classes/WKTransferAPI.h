#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WKTransferCallback)(NSDictionary * _Nullable result, NSError * _Nullable error);

@interface WKTransferAPI : NSObject

+ (instancetype)shared;

- (void)sendTransferTo:(NSString *)toUid
                amount:(double)amount
                remark:(NSString *)remark
              password:(NSString *)password
              callback:(WKTransferCallback)callback;

/// 与 Android 二开对齐：支持 channel_id/channel_type/pay_scene（收款码场景可传 pay_scene=receive_qr）。
- (void)sendTransferTo:(NSString *)toUid
                amount:(double)amount
                remark:(NSString *)remark
              password:(NSString *)password
             channelId:(nullable NSString *)channelId
           channelType:(NSInteger)channelType
              payScene:(nullable NSString *)payScene
              callback:(WKTransferCallback)callback;

- (void)acceptTransfer:(NSString *)transferNo callback:(WKTransferCallback)callback;

- (void)getTransferDetail:(NSString *)transferNo callback:(WKTransferCallback)callback;

/// 与 Android {@link WalletModel#getBalance} / 发红包侧一致：转账前校验 {@code has_password}（模块不依赖 WuKongRedPackets）。
- (void)getWalletBalanceSnapshotForPayPasswordGate:(WKTransferCallback)callback;

@end

NS_ASSUME_NONNULL_END
