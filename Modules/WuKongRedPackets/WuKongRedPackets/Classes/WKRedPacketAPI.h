#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WKRedPacketCallback)(NSDictionary * _Nullable result, NSError * _Nullable error);

@interface WKRedPacketAPI : NSObject

+ (instancetype)shared;

- (void)sendRedPacketType:(int)type
               channelId:(NSString *)channelId
             channelType:(int)channelType
             totalAmount:(double)totalAmount
              totalCount:(int)totalCount
                   toUid:(nullable NSString *)toUid
                  remark:(NSString *)remark
                password:(NSString *)password
                callback:(WKRedPacketCallback)callback;

- (void)openRedPacket:(NSString *)packetNo callback:(WKRedPacketCallback)callback;

- (void)getRedPacketDetail:(NSString *)packetNo callback:(WKRedPacketCallback)callback;

/// 与 Android {@link WalletModel#getBalance}：发红包前校验 {@code has_password}（避免依赖 WuKongWallet 模块造成循环依赖）。
- (void)getWalletBalanceSnapshotForPayPasswordGate:(WKRedPacketCallback)callback;

@end

NS_ASSUME_NONNULL_END
