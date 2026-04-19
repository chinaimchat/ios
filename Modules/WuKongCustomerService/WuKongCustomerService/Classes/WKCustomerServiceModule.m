//
//  WKCustomerService.m
//  WuKongCustomerService
//
//  Created by tt on 2022/4/1.
//

#import "WKCustomerServiceModule.h"
#import "WKCustomerServiceManager.h"
#import <WuKongBase/WKConversationGroupSettingVC.h>
#import <WuKongBase/WKConversationPersonSettingVC.h>
#import "WKCustomerServiceSettingVC.h"

@WKModule(WKCustomerServiceModule)

@interface WKCustomerServiceModule ()<WKAppDelegate>

@end

@implementation WKCustomerServiceModule

+(NSString*) gmoduleId {
    return @"WuKongCustomerService";
}

-(NSString*) moduleId {
    return [WKCustomerServiceModule gmoduleId];
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongCustomerService】模块初始化！");
    
    // 与 Android TSApplication：{@code WKCustomerServiceApplication.instance.init(appID)} 对齐，便于宿主覆盖。
    WKCustomerServiceManager *mgr = [WKCustomerServiceManager shared];
    if (!mgr.appID.length) {
        NSString *cid = [WKApp shared].config.customerServiceAppId;
        if (cid.length) {
            mgr.appID = cid;
        } else {
            NSString *bid = [WKApp shared].config.bundleID;
            if (!bid.length) {
                bid = [[NSBundle mainBundle] bundleIdentifier];
            }
            mgr.appID = bid.length ? bid : @"wukongchat";
        }
    }
    
    [[WKApp shared] addDelegate:self];
    
    __weak typeof(self) weakSelf = self;

    [self setMethod:@"contacts.header.customerservice" handler:^id _Nullable(id  _Nonnull param) {
        
        WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:WK_CONTACTS_HEADER_ITEM_NEWFRIEND title:LLangW(@"专属客服",weakSelf) icon:@"CustomerService" moduleID:[weakSelf moduleId] onClick:^{
            UIView *topView = [WKNavigationManager shared].topViewController.view;
            [topView showHUD];
            [[WKCustomerServiceManager shared] visitorTopicChannelGetOrCreate].then(^(NSDictionary *resultDict){
                [topView hideHud];
                NSString *channelID = [resultDict objectForKey:@"channel_id"];
                NSInteger channelType = [[resultDict objectForKey:@"channel_type"] integerValue];
                NSString *msgChannelID = channelID;
                [[WKApp shared] pushConversation:[[WKChannel alloc] initWith:msgChannelID channelType:channelType]];
            }).catch(^(NSError *error){
                [topView hideHud];
                [topView showHUDWithHide:error.domain];
            });
            
            // 跳转
           // [[WKNavigationManager shared] pushViewController:[WKMyGroupListVC new] animated:YES];
        }];
        return item;
    } category:WKPOINT_CATEGORY_CONTACTSITEM sort:6000];
    
    [self setMethod:@"conversation.list.show.customerService" handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = (WKChannel*)param[@"channel"];
        if(channel.channelType == WK_CustomerService ) {
            WKConversationVC *conversationVC =  [WKConversationVC new];
           conversationVC.channel = channel;
           [[WKNavigationManager shared] pushViewController:conversationVC animated:YES];
            return @(true);
        }
        return @(false);
    } category:WKPOINT_CATEGORY_CONVERSATION_SHOW];
    
    
   
}

- (BOOL)moduleDidFinishLaunching:(WKModuleContext *)context {
    __weak typeof(self) weakSelf = self;
    if( [WKApp shared].isLogined) {
        [[WKCustomerServiceManager shared] visitorLoginOrRegister]; //访客登录或注册
    }
    
    WKEndpoint *oldEndpoint = [[WKApp shared] getEndpoint:WKPOINT_CONVERSATION_SETTING];
    // 聊天页面设置
    [self setMethod:WKPOINT_CONVERSATION_SETTING handler:^id _Nullable(id  _Nonnull param) {
        WKChannel *channel = param[@"channel"];
        if(channel.channelType == WK_CustomerService) {
            NSString *visitorUID = [weakSelf customerServiceVisitorUID:channel.channelId];
            if(visitorUID && [visitorUID isEqualToString:WKApp.shared.loginInfo.uid]) { // 客服
                WKCustomerServiceSettingVC *vc = [WKCustomerServiceSettingVC new];
                vc.channel = channel;
                [[WKNavigationManager shared] pushViewController:vc animated:YES];
            }else { // 访客
                
            }
            return nil;
        }
        if(oldEndpoint) {
            oldEndpoint.handler(param);
        }
        return nil;
    }];
    
    
    return YES;
}

// 通过客户频道id获取访客uid
-(NSString*) customerServiceVisitorUID:(NSString*)channelID {
    NSArray *channelIDs =  [channelID componentsSeparatedByString:@"|"];
    if(channelIDs && channelIDs.count == 2) {
        return channelIDs[0];
    }
    return nil;
}

// app登录成功
-(void) appLoginSuccess {
    [[WKCustomerServiceManager shared] visitorLoginOrRegister]; //访客登录或注册
}
@end
