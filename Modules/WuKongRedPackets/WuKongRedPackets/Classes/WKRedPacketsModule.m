#import "WKRedPacketsModule.h"
#import "WKRedPacketContent.h"
#import "WKRedPacketCell.h"
#import "WKRedPacketOpenContent.h"
#import "WKRedPacketLocalSync.h"
#import "WKSendRedPacketVC.h"
#import "WKQQWalletColors.h"
#import <WuKongBase/WKMoreItemModel.h>
#import <WuKongBase/WKConversationContext.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

static UIImage *WKRedPacketPanelIcon(void) {
    UIColor *tint = [WKQQWalletColors btnBarEnd];
    if (@available(iOS 13.0, *)) {
        UIImage *s = [UIImage systemImageNamed:@"gift.fill"];
        if (s) {
            return [s imageWithTintColor:tint renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
    }
    CGSize sz = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0);
    [tint setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(4, 4, 32, 32) cornerRadius:8] fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@WKModule(WKRedPacketsModule)

@implementation WKRedPacketsModule

- (NSString *)moduleId {
    return @"WuKongRedPackets";
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongRedPackets】模块初始化！");

    [[WKSDK shared] registerMessageContent:[WKRedPacketContent class]];
    [[WKSDK shared] registerMessageContent:[WKRedPacketOpenContent class]];

    [[WKApp shared] registerCellClass:[WKRedPacketCell class] contentType:WK_REDPACKET];

    [[WKSDK shared].chatManager addMessageStoreBeforeIntercept:@"redpacket.dedupe.packet_no" intercept:^BOOL(WKMessage *message) {
        return [WKRedPacketLocalSync shouldStoreIncomingRedPacketMessage:message];
    }];

    [self setMethod:@"wallet_chat_redpacket" handler:^id _Nullable(id _Nonnull param) {
        static const BOOL kWKHideRedPacketPanelEntry = NO;
        if (!kWKHideRedPacketPanelEntry) {
            NSDictionary *dict = param;
            id<WKConversationContext> ctx = dict[@"context"];
            if (ctx) {
                UIImage *img = WKRedPacketPanelIcon();
                return [WKMoreItemModel initWithImage:img title:@"发红包" onClick:^(id<WKConversationContext> conversationContext) {
                    WKSendRedPacketVC *vc = [[WKSendRedPacketVC alloc] initWithChannel:conversationContext.channel];
                    [[WKNavigationManager shared] pushViewController:vc animated:YES];
                }];
            }
        }
        return nil;
    } category:WKPOINT_CATEGORY_PANELMORE_ITEMS sort:110];
}

- (BOOL)moduleDidFinishLaunching:(WKModuleContext *)context {
    return YES;
}

@end
