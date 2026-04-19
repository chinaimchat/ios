#import "WKTransferModule.h"
#import "WKTransferContent.h"
#import "WKTransferCell.h"
#import "WKTradeSystemNotifyContent.h"
#import "WKSendTransferVC.h"
#import <WuKongBase/WKMoreItemModel.h>
#import <WuKongBase/WKConversationContext.h>

static UIImage *WKTransferPanelIcon(void) {
    UIColor *tint = [UIColor colorWithRed:0.98 green:0.60 blue:0.16 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        UIImage *s = [UIImage systemImageNamed:@"arrow.left.arrow.right.circle.fill"];
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

@WKModule(WKTransferModule)

@implementation WKTransferModule

- (NSString *)moduleId {
    return @"WuKongTransfer";
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongTransfer】模块初始化！");

    [[WKSDK shared] registerMessageContent:[WKTransferContent class]];
    [[WKSDK shared] registerMessageContent:[WKTradeSystemNotifyContent class]];

    [[WKApp shared] registerCellClass:[WKTransferCell class] contentType:WK_TRANSFER];

    [self setMethod:@"wallet_chat_transfer" handler:^id _Nullable(id _Nonnull param) {
        static const BOOL kWKHideTransferPanelEntry = NO;
        if (!kWKHideTransferPanelEntry) {
            NSDictionary *dict = param;
            id<WKConversationContext> ctx = dict[@"context"];
            WKChannel *ch = ctx.channel;
            if (ctx && ch && (ch.channelType == WK_PERSON || ch.channelType == WK_GROUP)) {
                UIImage *img = WKTransferPanelIcon();
                return [WKMoreItemModel initWithImage:img title:@"转账" onClick:^(id<WKConversationContext> conversationContext) {
                    WKChannel *c = conversationContext.channel;
                    if (c.channelType == WK_PERSON) {
                        WKSendTransferVC *vc = [[WKSendTransferVC alloc] initWithToUid:c.channelId
                                                                             channelId:c.channelId
                                                                           channelType:c.channelType
                                                                              payScene:nil];
                        [[WKNavigationManager shared] pushViewController:vc animated:YES];
                    } else if (c.channelType == WK_GROUP) {
                        WKSendTransferVC *vc = [[WKSendTransferVC alloc] initWithGroupTransferChannel:c];
                        [[WKNavigationManager shared] pushViewController:vc animated:YES];
                    }
                }];
            }
        }
        return nil;
    } category:WKPOINT_CATEGORY_PANELMORE_ITEMS sort:111];
}

- (BOOL)moduleDidFinishLaunching:(WKModuleContext *)context {
    return YES;
}

@end
