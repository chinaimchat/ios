//
//  WKPinnedMessageContext.m
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import "WKPinnedMessageContext.h"
#import <WuKongBase/WuKongBase-Swift.h>
#import "WKPinnedMessageListVC.h"

@interface WKPinnedMessageContext ()

@property(nonatomic,strong) WKPinnedMessageListVC *pinnedMessageListVC;

@end

@implementation WKPinnedMessageContext

- (instancetype)initWithPinnedMessageListVC:(WKPinnedMessageListVC*) pinnedMessageListVC
{
    self = [super init];
    if (self) {
        self.pinnedMessageListVC = pinnedMessageListVC;
    }
    return self;
}

- (void)longPressMessageCell:(WKMessageCell *)messageCell gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    
    //    WKMessageModel *contextMessage = messageCell.messageModel;
    //
    //    NSArray<WKMessageLongMenusItem*> *toolbarMenus;
    //    if(contextMessage.content.flame) {
    //        WKMessageLongMenusItem *revokeToolbarMenus = [[WKApp shared] invoke:WKPOINT_LONGMENUS_REVOKE param:@{@"message":contextMessage}];
    //        if(revokeToolbarMenus) {
    //            toolbarMenus = @[revokeToolbarMenus];
    //        }
    //    }else{
    //        toolbarMenus = [[WKApp shared] invokes:WKPOINT_CATEGORY_MESSAGE_LONGMENUS param:@{@"message":contextMessage}];
    //    }
    //
    //    WKMessageContextController *messageContextController = [[WKMessageContextController alloc] initWithMessage:messageCell.messageModel context:self menusItems:toolbarMenus gesture:(ContextGesture*)gestureRecognizer];
    //    messageContextController.onDismissed = ^{
    //        NSLog(@"messageContextController.....");
    //    };
    //    __weak typeof(messageContextController) weakController = messageContextController;
    //    messageContextController.reactionSelected = ^(WKReactionContextItem * item, BOOL isLarge) {
    //        [[WKSDK shared].reactionManager addOrCancelReaction:item.reaction messageID:messageCell.messageModel.messageId complete:^(NSError * _Nullable error) {
    //            [weakController dismiss];
    //        }];
    //    };
    //    [messageContextController setup];
    //    [messageContextController show];
}

- (NSArray<UITableViewCell *> *)visibleCells {
    return [self.pinnedMessageListVC.messageListView visibleCells];
}
- (void)refreshCell:(WKMessageModel *)messageModel {
    [self.pinnedMessageListVC.messageListView refreshCell:messageModel];
}
/// 定位到指定的消息
/// @param messageSeq 通过消息messageSeq定位消息
-(void) locateMessageCell:(uint32_t)messageSeq {
    [self.pinnedMessageListVC.messageListView locateMessageCell:messageSeq];
}


-(UITableViewCell*) cellForRowAtIndex:(NSIndexPath*)indexPath {
    return [self.pinnedMessageListVC.messageListView cellForRowAtIndex:indexPath];
}

- (WKChannelInfo *)getChannelInfo {
    return [WKSDK.shared.channelManager getChannelInfo:self.channel];
}


-(UIViewController*) targetVC {
    return self.pinnedMessageListVC;
}

- (BOOL)isFuncGroupZooming {
    return false;
}

-(void) endEditing {
    
}

-(void) navigateToMessage:(WKMessageModel*)message {
    [self.pinnedMessageListVC dismissViewControllerAnimated:YES completion:nil];
    [self.pinnedMessageListVC.mainConversationContext locateMessageCell:message.messageSeq];
}

@end
