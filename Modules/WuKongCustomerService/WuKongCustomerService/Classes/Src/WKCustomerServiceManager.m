//
//  WKCustomerServiceManager.m
//  WuKongCustomerService
//
//  Created by tt on 2022/4/1.
//

#import "WKCustomerServiceManager.h"
#import <WuKongBase/WuKongBase.h>
#import <WuKongBase/UIDevice+Utils.h>




@implementation WKCustomerServiceManager

static WKCustomerServiceManager *_instance;

/// 与 Android {@code WKCustomerServiceApplication#customerServiceAppId} / {@code WKBaseApplication#appID} 一致：热线路径、{@code site_title}、{@code getChatInfo} 的 {@code appid} 使用同一标识。
- (NSString *)effectiveCustomerServiceAppId {
    if (self.appID.length) {
        return self.appID;
    }
    NSString *configured = [WKApp shared].config.customerServiceAppId;
    if (configured.length) {
        return configured;
    }
    NSString *b = [WKApp shared].config.bundleID;
    if (b.length) {
        return b;
    }
    b = [[NSBundle mainBundle] bundleIdentifier];
    return b.length ? b : @"wukongchat";
}

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKCustomerServiceManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

-(AnyPromise*) visitorLoginOrRegister {
    NSString *vid = [WKApp shared].loginInfo.uid ?: @"";
    NSString *hotlineAppId = [self effectiveCustomerServiceAppId];
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceName = [device model];
    NSString *systemName = [device systemName];
    NSString *deviceModel =  [UIDevice getDeviceModel];
    NSString *systemVersion = [device systemVersion];
    
    NSTimeZone *zone = [NSTimeZone localTimeZone];
    
    
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"hotline/widget/%@/visitor", hotlineAppId] parameters:@{
        @"vid":vid,
        @"site_title": hotlineAppId,
        @"not_register_token": @(1),
        @"device": @{
            @"device":deviceName,
            @"os":systemName,
            @"model":deviceModel,
            @"version": systemVersion,
        },
        @"timezone": zone.name,
        @"local":@(1)
    }];
}

-(AnyPromise*) visitorTopicChannelGetOrCreate {
    NSString *hotlineAppId = [self effectiveCustomerServiceAppId];
    return [[WKAPIClient sharedClient] POST:@"hotline/visitor/topic/channel" parameters:@{
        @"topic_id": @(0),
        @"appid": hotlineAppId,
    } headers:@{
        @"appid": hotlineAppId,
    }];
}

-(NSString*) visitorMsgChannelID:(NSString*)channelID channelType:(NSInteger)channelType{
    if(channelType == WK_CustomerService) {
        return [NSString stringWithFormat:@"%@|%@",[WKApp shared].loginInfo.uid,channelID];
    }
    return channelID;
}

@end
