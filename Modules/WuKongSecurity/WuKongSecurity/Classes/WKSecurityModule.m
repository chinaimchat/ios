//
//  WKSecurityModule.m
//  WuKongSecurity
//
//  Created by tt on 2023/10/8.
//

#import "WKSecurityModule.h"
#import "WKSecuritySettingVC.h"
#import "WKConversationPasswordVC.h"


@WKModule(WKSecurityModule)
@implementation WKSecurityModule

-(NSString*) moduleId {
    return @"WuKongSecurity";
}

// 模块初始化
- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongSecurity】模块初始化！");
    __weak typeof(self) weakSelf = self;
    // 安全与隐私
    [self setMethod:WKPOINT_ME_SECURITY handler:^id _Nullable(id  _Nonnull param) {
        return [WKMeItem initWithTitle:LLangW(@"安全与隐私",weakSelf) icon:[weakSelf imageName:@"Me/Index/IconSecurity"] onClick:^{
             [[WKNavigationManager shared] pushViewController:[WKSecuritySettingVC new] animated:YES];
        }];
    } category:WKPOINT_CATEGORY_ME sort:19860];
    
    
    
    [[WKApp shared] setMethod:@"channelsetting.chatpwd" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        WKChannelInfo *channelInfo = [WKSDK.shared.channelManager getChannelInfo:channel];
        if(!channelInfo) {
            return nil;
        }
        // 聊天密码
        BOOL chatPwdOn = channelInfo && [channelInfo settingForKey:WKChannelExtraKeyChatPwd defaultValue:false];
        
        return @{
            @"height":@(0.0f),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"聊天密码"),
                    @"on":@(chatPwdOn),
                    @"showBottomLine":@(NO),
                    @"bottomLeftSpace":@(0.0f),
                    @"onSwitch":^(BOOL on){
                        NSString *chatPwd = [WKApp shared].loginInfo.extra[@"chat_pwd"];
                        if(!chatPwd || [chatPwd isEqualToString:@""]) {
//                                     __weak typeof(self) weakSelf = self;
                            WKConversationPasswordVC *vc = [WKConversationPasswordVC new];
                            [vc setOnFinish:^{
                                [[WKChannelSettingManager shared] channel:channel chatPwdOn:on];
                            }];
                            [[WKNavigationManager shared] pushViewController:vc animated:YES];
                            return;
                        }
                        [[WKChannelSettingManager shared] channel:channel chatPwdOn:on];
                    }
                }
            ]
        };
    } category:WKPOINT_CATEGORY_CHANNELSETTING sort:89200];
}


-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongSecurity"];
}


@end
