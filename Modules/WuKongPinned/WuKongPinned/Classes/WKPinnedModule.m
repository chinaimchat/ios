//
//  WKPinnedModule.m
//  25519
//
//  Created by tt on 2024/5/20.
//

#import "WKPinnedModule.h"
#import <WuKongBase/WuKongBase.h>
#import "WKPinnedView.h"
#import "WKPinnedService.h"
@WKModule(WKPinnedModule)

@interface WKPinnedModule ()<WKCMDManagerDelegate>

@end

@implementation WKPinnedModule

// 模块全局唯一ID 一般建议 WuKong + 模块名
-(NSString*) moduleId {
    return @"WuKongPinned";
}

// 模块启动时调用
- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongPinned】模块初始化！");
    
    [[WKSDK shared].cmdManager addDelegate:self];
    
    // 会话顶部的置顶视图
    [WKApp.shared setMethod:WKPOINT_CONVERSATION_TOP_PANEL handler:^id _Nullable(id  _Nonnull param) {
        id<WKConversationContext> context = param[@"context"];
        return [[WKPinnedView alloc] initContext:context];
    }];
    
    // 长按消息的置顶item
    __weak typeof(self) weakSelf = self;
    [self setMethod:WKPOINT_LONGMENUS_PIN handler:^id _Nullable(id  _Nonnull param) {
        WKMessageModel *message = param[@"message"];
        
        BOOL hasPinned = [WKSDK.shared.pinnedMessageManager hasPinned:message.messageId];
        NSString *iconName = @"Conversation/ContextMenu/Pin";
        NSString *title = @"置顶";
        if(hasPinned) {
            title = @"取消置顶";
            iconName = @"Conversation/ContextMenu/Unpin";
        }
        if(message.channel.channelType == WK_GROUP) {
           BOOL isManager = [[WKSDK shared].channelManager isManager:message.channel memberUID:[WKApp shared].loginInfo.uid];
            if(!isManager) { // 如果是群聊，非管理员不允许置顶
                return nil;
            }
        }
        
        UIImage *icon = [WKGenerateImageUtils generateTintedImgWithImage:[weakSelf imageName:iconName] color:[WKApp shared].config.contextMenu.primaryColor backgroundColor:nil];
        return [WKMessageLongMenusItem initWithTitle:LLangW(title, weakSelf) icon:icon onTap:^(id<WKConversationContext>  _Nonnull context) {
            [weakSelf requestPin:message];
        }];
    } category:WKPOINT_CATEGORY_MESSAGE_LONGMENUS sort:1910];
    
    
}

// 请求置顶
-(void) requestPin:(WKMessageModel*)message {
    [WKAPIClient.sharedClient POST:@"message/pinned" parameters:@{
        @"channel_id": message.channel.channelId?:@"",
        @"channel_type": @(message.channel.channelType),
        @"message_id": [NSString stringWithFormat:@"%lld",message.messageId],
        @"message_seq": @(message.messageSeq),
    }].catch(^(NSError *err){
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:err.domain];
    });
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongPinned"];
}

-(void) cmdManager:(WKCMDManager*)manager onCMD:(WKCMDModel*)model {
    if(!model.cmd || [model.cmd isEqualToString:@""]) {
        return;
    }
    NSString *channelId = model.param[@"channel_id"];
    NSNumber *channelType = model.param[@"channel_type"];
    WKChannel *channel = [WKChannel channelID:channelId channelType:channelType.intValue];
    if([model.cmd isEqualToString:@"syncPinnedMessage"]) { // 同步置顶消息
        [WKPinnedService.shared requestSyncPinnedMessages:channel];
    }
}


@end
