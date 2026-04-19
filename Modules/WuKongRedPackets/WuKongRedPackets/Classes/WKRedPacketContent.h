#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WKRedPacketType) {
    WKRedPacketTypeIndividual = 1,
    WKRedPacketTypeGroupRandom = 2,
    WKRedPacketTypeGroupNormal = 3,
    WKRedPacketTypeExclusive = 4,
};

@interface WKRedPacketContent : WKMessageContent

@property (nonatomic, copy) NSString *packetNo;
@property (nonatomic, assign) WKRedPacketType packetType;
@property (nonatomic, copy) NSString *remark;
/** 发送方展示名，拆红包弹层用 */
@property (nonatomic, copy) NSString *senderName;
/**
 * 0：当前用户仍可点开抢；1：红包已全部领完；2：过期；
 * 3：对当前用户而言已领取（含「只领了一部分、群里仍有余额」、领自己发的、领他人的），显示「已领取」浅色皮肤，勿与 1 混淆。
 */
@property (nonatomic, assign) NSInteger status;

@end

NS_ASSUME_NONNULL_END
