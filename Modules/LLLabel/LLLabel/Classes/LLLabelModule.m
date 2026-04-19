//
//  LLLabelModule.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelModule.h"
#import "LLLabelListVC.h"
#import "LLLabelAddVC.h"
#import "LLLabelQuickAddVC.h"
@WKModule(LLLabelModule)
@implementation LLLabelModule

/// 与 Android {@code WKLabelApplication#addListener} 通讯录项 {@code ContactsMenu(..., R.string.str_label)} 一致，模块 sid 为 {@code label}。
- (NSString *)moduleId {
    return @"LLLabel";
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【LLLabel】模块初始化！");
    __weak typeof(self) weakSelf = self;
    // 标签
    [self setMethod:@"contacts.header.labels" handler:^id _Nullable(id  _Nonnull param) {
        WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:@"labels" title:LLangW(@"标签",weakSelf) icon:@"IconLabel" moduleID:[weakSelf moduleId] onClick:^{
            LLLabelListVC *vc = [[LLLabelListVC alloc] init];
            [[WKNavigationManager shared] pushViewController:vc animated:YES];
        }];
        return item;
    } category:WKPOINT_CATEGORY_CONTACTSITEM sort:7000];
    
    // 标签数据源
    [self setMethod:WKPOINT_LABEL_DATA_LIST handler:^id _Nullable(id  _Nonnull param) {
        return [[WKAPIClient sharedClient] GET:@"label" parameters:nil];
    }];
    
    // 标签UI详情页
    [self setMethod:WKPOINT_LABEL_UI_DETAIL handler:^id _Nullable(id  _Nonnull param) {
        LLLabelResp *labelResp = (LLLabelResp *)[LLLabelResp fromMap:param type:ModelMapTypeAPI];
        LLLabelAddVC *addvc = [LLLabelAddVC new];
        addvc.label = labelResp;
        [WKNavigationManager.shared pushViewController:addvc animated:YES];
        return nil;
    }];
    
    // 存为标签
    [self setMethod:WKPOINT_LABEL_UI_SAVE handler:^id _Nullable(id  _Nonnull param) {
        
        NSArray<NSString*> *uids = param[@"uids"];
        void(^onFinish)(NSDictionary*resultDict)  = param[@"onFinish"];
        
        if(uids && uids.count>0) {
            LLLabelQuickAddVC *addVC = [LLLabelQuickAddVC new];
            addVC.uids = uids;
            addVC.onFinish = ^(NSDictionary *resultDict){
                if(onFinish) {
                    onFinish(resultDict);
                }
            };
            [WKNavigationManager.shared pushViewController:addVC animated:YES];
        }
        
        return nil;
    }];
    
}

- (UIImage *)imageName:(NSString *)name {
    return [[WKApp shared] loadImage:name moduleID:@"LLLabel"];
}

@end
