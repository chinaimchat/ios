//
//  WKCustomerServiceSettingVM.m
//  WuKongCustomerService
//
//  Created by tt on 2022/4/8.
//

#import "WKCustomerServiceSettingVM.h"

@implementation WKCustomerServiceSettingVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:self.channel];
    NSString *logo = @"";
    NSString *name = @"";
    if(channelInfo) {
        if(![channelInfo.logo isEqualToString:@""]) {
            logo = [[WKApp shared] getImageFullUrl:channelInfo.logo].absoluteString;
        }
        name = channelInfo.displayName;
        
    }
    NSString *desc = [NSString stringWithFormat:@"%@官方客户，有什么问题可以联系我。",[WKApp shared].config.appName];
    __weak typeof(self) weakSelf = self;
    return @[
        @{
            @"height":@(0.0f),
            @"items": @[
                @{
                    @"class": WKUserHeaderModel.class,
                    @"avatar":logo,
                    @"name": name,
                }
            ]
        },
        @{
            @"height":@(0.0f),
            @"items": @[
                @{
                    @"class": WKMultiLabelItemModel.class,
                    @"label":LLang(@"功能介绍"),
                    @"value": LLang(desc),
                    @"mode": @(WKMultiLabelItemModeLeftRight),
                }
            ]
        },
        @{
            @"height":@(20.0f),
            @"items": @[
                @{
                    @"class": WKButtonItemModel.class,
                    @"title":LLang(@"发消息"),
                    @"color": [WKApp shared].config.themeColor,
                    @"onClick": ^{
                        [[WKNavigationManager shared] popToRootViewControllerAnimated:NO];
                        [[WKApp shared] pushConversation:weakSelf.channel];
                    }
                }
            ]
        }
    ];
}

@end
