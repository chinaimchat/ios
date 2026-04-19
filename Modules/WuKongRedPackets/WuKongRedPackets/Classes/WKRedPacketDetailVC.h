#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRedPacketDetailVC : WKBaseVC

- (instancetype)initWithPacketNo:(NSString *)packetNo;
/// 对齐 Android RedPacketDetailActivity：携带会话用于群昵称解析与领取记录点头像进资料卡。
- (instancetype)initWithPacketNo:(NSString *)packetNo channelId:(nullable NSString *)channelId channelType:(uint8_t)channelType;
/// 从「红包记录」进入详情时为 YES，隐藏右上角「红包记录」，与 Android {@code EXTRA_HIDE_REDPACKET_RECORD_ENTRY} 一致。
- (instancetype)initWithPacketNo:(NSString *)packetNo channelId:(nullable NSString *)channelId channelType:(uint8_t)channelType hideRedPacketRecordEntry:(BOOL)hide;

@end

NS_ASSUME_NONNULL_END
