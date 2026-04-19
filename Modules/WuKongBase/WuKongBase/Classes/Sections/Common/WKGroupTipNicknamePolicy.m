#import "WKGroupTipNicknamePolicy.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKApp.h"

@implementation WKGroupTipNicknamePolicy

+ (int)forbiddenFlagFromMessageContentRoot:(NSDictionary *)contentRoot {
    if (![contentRoot isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    id v = contentRoot[@"forbidden_add_friend"];
    if ([v respondsToSelector:@selector(intValue)]) {
        return [v intValue] == 1 ? 1 : 0;
    }
    return 0;
}

+ (int)forbiddenFlagFromLocalGroupChannel:(WKChannel *)channel {
    if (!channel || channel.channelType != WK_GROUP) {
        return 0;
    }
    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfo:channel];
    if (!info || ![info.extra isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    id o = info.extra[WKChannelExtraKeyForbiddenAddFriend];
    if ([o respondsToSelector:@selector(boolValue)] && [o boolValue]) {
        return 1;
    }
    return 0;
}

+ (BOOL)shouldBlockNicknameProfileJumpWithChannelId:(NSString *)channelId channelType:(uint8_t)channelType forbiddenFlag:(int)forbiddenFlag {
    if (forbiddenFlag != 1) {
        return NO;
    }
    if (channelType != WK_GROUP || channelId.length == 0) {
        return NO;
    }
    NSString *me = [WKSDK shared].options.connectInfo.uid ?: @"";
    if (me.length == 0) {
        return YES;
    }
    WKChannel *ch = [WKChannel channelID:channelId channelType:WK_GROUP];
    WKChannelMember *selfMem = [[WKSDK shared].channelManager getMember:ch uid:me];
    if (!selfMem) {
        return YES;
    }
    return selfMem.role == WKMemberRoleCommon;
}

@end
