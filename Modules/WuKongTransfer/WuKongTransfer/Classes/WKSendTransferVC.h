#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKSendTransferVC : WKBaseVC

- (instancetype)initWithToUid:(NSString *)toUid;

/// 与 Android 二开对齐：可显式传入 channel_id/channel_type/pay_scene。
- (instancetype)initWithToUid:(NSString *)toUid
                    channelId:(nullable NSString *)channelId
                  channelType:(NSInteger)channelType
                     payScene:(nullable NSString *)payScene;

/// 群聊会话内发起转账：对齐 Android TransferActivity（channel 为群，收款人在页内选择）。
- (instancetype)initWithGroupTransferChannel:(WKChannel *)groupChannel;

@end

NS_ASSUME_NONNULL_END
