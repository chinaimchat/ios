//
//  WKPanelDefaultFuncItem.m
//  WuKongBase
//
//  Created by tt on 2020/2/23.
//

#import "WKPanelDefaultFuncItem.h"
#import "WKResource.h"
#import "WKConstant.h"
#import "WKMoreItemClickEvent.h"
#import "WKFuncItemButton.h"
#import "WuKongBase.h"
#import "WKConversationContext.h"
#import "WKCardContent.h"
@interface WKPanelDefaultFuncItem ()



@end

@implementation WKPanelDefaultFuncItem

-(NSString*) sid {
    return @"";
}

- (nonnull WKFuncItemButton *)itemButton:(WKConversationInputPanel*)inputPanel {
    self.inputPanel = inputPanel;
    WKFuncItemButton *btn = [[WKFuncItemButton alloc] init];
    [btn setImage:[self itemIcon] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onPressed:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:[self title] forState:UIControlStateNormal];
    return btn;
}

-(void) onPressed:(WKFuncItemButton*)btn {
    [self.inputPanel switchPanel:[self panelID]];
}

-(NSString*) title {
    return @"";
}

-(UIImage*) itemIcon {
    
    return nil;
}

-(NSString*) panelID {
    return @"";
}

- (BOOL)support:(id<WKConversationContext>)context {
    return true;
}

-(BOOL) allowEdit {
    return true;
}

-(UIImage*) getImageNameForBase:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
    //    return [currentModule ImageForResource:name];
//    return  [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

@end

@implementation WKPanelEmojiFuncItem

-(BOOL) allowEdit {
    return false;
}
- (NSString *)sid {
    return @"apm.wukong.emoji";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/FaceNormal"];
}

- (NSString *)panelID {
    return WKPOINT_PANEL_EMOJI;
}

- (NSString *)title {
    return LLang(@"表情");
}

@end

@interface WKPanelMentionFuncItem ()


@end
@implementation WKPanelMentionFuncItem

- (NSString *)sid {
    return @"apm.wukong.mention";
}
- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/MentionNormal"];
}

- (BOOL)support:(id<WKConversationContext>)context {
    return context.channel.channelType != WK_PERSON;
}


-(void) onPressed:(UIButton*)btn {
    [self.inputPanel inputInsertText:@"@"];
    [self.inputPanel.conversationContext showMentionUsers];
   
}
- (NSString *)title {
    return LLang(@"@");
}

@end


@interface WKPanelVoiceFuncItem ()

@end
@implementation WKPanelVoiceFuncItem

-(BOOL) allowEdit {
    return false;
}


- (NSString *)sid {
    return @"apm.wukong.voice";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/VoiceNormal"];
}

- (NSString *)panelID {
    return WKPOINT_PANEL_VOICE;
}
- (NSString *)title {
    return LLang(@"语音");
}
@end



@interface WKPanelImageFuncItem ()

@end
@implementation WKPanelImageFuncItem

-(BOOL) allowEdit {
    return false;
}


- (NSString *)sid {
    return @"apm.wukong.image";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/ImageNormal"];
}

-(void) onPressed:(UIButton*)btn {
   
    // 图片点击
    [[WKMoreItemClickEvent shared] onPhotoItemPressed:self.inputPanel.conversationContext];
}
- (NSString *)title {
    return LLang(@"图片");
}

@end

@implementation WKPanelMoreFuncItem

- (NSString *)sid {
    return @"apm.wukong.more";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/MoreNormal"];
}

/// 与 Android 一致：点击工具栏末尾「更多」展开底部面板（转账、发红包、图片等，见 `WKPOINT_CATEGORY_PANELMORE_ITEMS`）。
- (NSString *)panelID {
    return WKPOINT_PANEL_MORE;
}

- (NSString *)title {
    return LLang(@"更多");
}

- (WKFuncGroupEditItemType)type {
    return WKFuncGroupEditItemTypeMore;
}
@end


@implementation WKPanelCardFuncItem

- (NSString *)sid {
    return @"apm.wukong.card";
}

- (UIImage *)itemIcon {
    return [self getImageNameForBase:@"Conversation/Toolbar/CardNormal"];
}

+ (void)presentCardPickerForConversationContext:(id<WKConversationContext>)conversationContext toolbarButton:(UIButton *)toolbarButton {
    void (^resetToolbar)(void) = ^{
        if (toolbarButton) {
            toolbarButton.selected = NO;
        }
    };
    NSMutableArray<NSString*> *hiddenUsers = [NSMutableArray array];
    if(conversationContext.channel.channelType == WK_PERSON) {
        [hiddenUsers addObject:conversationContext.channel.channelId];
    }
    __weak typeof(conversationContext) weakCtx = conversationContext;
    [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT param:@{@"mode":@"single",@"on_finished":^(NSArray<NSString*>*uids){
        if(uids && [uids count]<=0) {
            resetToolbar();
            return;
        }
        NSString *uid = uids[0];
        WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:[[WKChannel alloc] initWith:uid channelType:WK_PERSON]];
        if(!channelInfo) {
            WKLogDebug(@"没有查到频道信息！");
            resetToolbar();
            return;
        }
        id<WKConversationContext> context = weakCtx;
        [WKAlertUtil alert:[NSString stringWithFormat:LLang(@"发送%@的名片到当前聊天"), channelInfo.displayName] buttonsStatement:@[LLang(@"取消"), LLang(@"确定")] chooseBlock:^(NSInteger buttonIdx) {
            resetToolbar();
            if(buttonIdx == 1) {
                [[WKNavigationManager shared] popViewControllerAnimated:YES];
                [context sendMessage:[WKCardContent cardContent:[channelInfo extraValueForKey:WKChannelExtraKeyVercode] uid:uid name:channelInfo.name avatar:channelInfo.logo]];
            }
        }];
    },@"on_cancel":resetToolbar,@"hidden_users":hiddenUsers}];
}

- (void)onPressed:(UIButton *)btn {
    [WKPanelCardFuncItem presentCardPickerForConversationContext:self.inputPanel.conversationContext toolbarButton:btn];
}

- (NSString *)title {
    return LLang(@"名片");
}

@end

