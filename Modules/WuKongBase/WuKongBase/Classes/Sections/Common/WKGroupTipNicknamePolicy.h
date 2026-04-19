#import <Foundation/Foundation.h>

@class WKChannel;

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android GroupTipNicknamePolicy：群「禁止互加」时限制普通成员通过系统提示昵称等入口进资料卡。
@interface WKGroupTipNicknamePolicy : NSObject

/// 从系统消息 JSON 根读取 forbidden_add_friend（与 Android parseForbiddenAddFriendFlag 一致）。
+ (int)forbiddenFlagFromMessageContentRoot:(nullable NSDictionary *)contentRoot;

/// 从本地已缓存的群频道信息读取（对齐 forbiddenAddFriendFlagFromLocalGroupChannel）。
+ (int)forbiddenFlagFromLocalGroupChannel:(nullable WKChannel *)channel;

/// 是否禁止点昵称进资料卡：群 + forbidden==1 + 当前用户为普通成员。
+ (BOOL)shouldBlockNicknameProfileJumpWithChannelId:(nullable NSString *)channelId
                                        channelType:(uint8_t)channelType
                                      forbiddenFlag:(int)forbiddenFlag;

@end

NS_ASSUME_NONNULL_END
