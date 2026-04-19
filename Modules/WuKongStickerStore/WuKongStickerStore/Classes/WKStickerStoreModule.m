//
//  WKStickerStoreModule.m
//  WuKongStickerStore
//
//  Created by tt on 2022/6/28.
//

#import "WKStickerStoreModule.h"
#import "WKStickerStoreVC.h"
#import "WKStickerInfoVC.h"
#import "WKStickerDataProvider.h"
#import "WKStickerCollectionVC.h"
#import "WKStickerCollectedContentView.h"
#import "WKStickerStoreModule.h"
#import <WuKongBase/WuKongBase-Swift.h>

@WKModule(WKStickerStoreModule)

@interface WKStickerStoreModule () <WKStickerManagerDelegate>

@end
@implementation WKStickerStoreModule

+(NSString*) gModuleID {
    return @"WuKongStickerStore";
}

-(NSString*) moduleId {
    return [[self class] gModuleID];
}

// 模块初始化
- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongStickerStore】模块初始化！");
    
    // 跳到表情商店
    [self setMethod:WKPOINT_TO_STICKER_STORE handler:^id _Nullable(id  _Nonnull param) {
        WKStickerStoreVC *vc = [WKStickerStoreVC new];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return nil;
    }];
    
    // 跳到表情详情
    [self setMethod:WKPOINT_TO_STICKER_INFO handler:^id _Nullable(id  _Nonnull param) {
        WKStickerInfoVC *vc = [WKStickerInfoVC new];
        vc.category = param[@"category"];
        vc.stickerURL = param[@"sticker_url"];
        vc.placeholderSvg = param[@"placeholder_svg"];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return nil;
    }];
    
    // emoji收藏
    [self setMethod:WKPOINT_PANELCONTENT_COLLECTION handler:^id _Nullable(id  _Nonnull param) {
        WKStickerCollectedContentView *view = [[WKStickerCollectedContentView alloc] initWithFrame:CGRectZero];
        view.stickerCollected = ^(NSArray * _Nonnull array) {
            [[WKApp shared] invoke:WKPOINT_TO_STICKER_COLLECTION param:@{
                @"data":array.mutableCopy,
            }];
        };
        return view;
    } category:WKPOINT_CATEGORY_PANELCONTENT sort:3900];
  
    
    [WKStickerManager.shared setStickerProvider:[WKStickerDataProvider new]];
    
    [WKStickerManager.shared addDelegate:self];

    
}

-(void) stickerUserCategoryLoadFinished:(WKStickerManager*)manager {
    
    NSArray<WKEndpoint*> *endpoints = [WKApp.shared getEndpointsWithCategory:WKPOINT_CATEGORY_PANELCONTENT];
    if(endpoints && endpoints.count>0) {
        for (WKEndpoint *endpoint in endpoints) {
            if([endpoint.sid hasPrefix:@"panelcontent.sticker."]) {
                [WKApp.shared.endpointManager unregisterEndpoint:endpoint];
            }
        }
    }
    
    NSArray<WKStickerUserCategoryResp*> *stickerUserCategoryResps =  [manager stickerUserCategoryResps];
    
    __weak typeof(self) weakSelf = self;
    if(stickerUserCategoryResps && stickerUserCategoryResps.count>0) {
        
        for (WKStickerUserCategoryResp *resp in stickerUserCategoryResps) {
            WKBaseModule *module = [WKSwiftModuleManager.shared getModuleWithId:[WKStickerStoreModule gModuleID]];
            [module setMethod:[NSString stringWithFormat:@"panelcontent.sticker.%@",resp.category] handler:^id _Nullable(id  _Nonnull param) {
                WKStickerGIFContentView *gifContentView = [[WKStickerGIFContentView alloc] initWithKeyword:LLangW(resp.category, weakSelf) tabIconURL:[[WKApp shared] getFileFullUrl:resp.cover]];
                return gifContentView;
            } category:WKPOINT_CATEGORY_PANELCONTENT sort:resp.sortNum?resp.sortNum.intValue:0];
//            break;
        }
    }
}

@end
