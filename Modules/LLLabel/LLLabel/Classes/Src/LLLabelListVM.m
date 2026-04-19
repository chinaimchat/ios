//
//  LLLabelListVM.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelListVM.h"
#import "LLLabelListCell.h"
#import "LLLabelAddVC.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface LLLabelListVM ()



@end

@implementation LLLabelListVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    if (!self.labels) {
        return nil;
    }
    NSMutableArray *items = [NSMutableArray array];
    for (LLLabelResp *label in self.labels) {
        [items addObject:@{
            @"class": LLLabelListModel.class,
            @"title": label.name ?: @"",
            @"num": @(label.count),
            @"labelResp": label,
            @"onClick": ^{
                LLLabelAddVC *vc = [[LLLabelAddVC alloc] init];
                vc.label = label;
                [[WKNavigationManager shared] pushViewController:vc animated:YES];
            }
        }];
    }
    return @[
        @{
            @"height": @(0.01f),
            @"items": items,
        }
    ];
}

- (AnyPromise *)requestDeleteLabel:(NSString *)_id {
    /// 与 Android {@link LabelService#deleteLabel}：{@code DELETE label/{id}}
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"label/%@", _id] parameters:nil];
}

- (void)requestData:(void (^)(NSError * _Nullable))complete {
    __weak typeof(self) weakSelf = self;
    /// 与 Android {@link LabelService#getLabels}：{@code GET label}
    [[WKAPIClient sharedClient] GET:@"label" parameters:nil model:LLLabelResp.class].then(^(NSArray<LLLabelResp *> *resps) {
        weakSelf.labels = [NSMutableArray arrayWithArray:resps];
        complete(nil);
    }).catch(^(NSError *err) {
        complete(err);
    });
}

@end

@implementation LLLabelResp

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    LLLabelResp *resp = [LLLabelResp new];
    resp._id = dictory[@"id"];
    resp.name = dictory[@"name"]?:@"";
    resp.count = [dictory[@"count"] integerValue];
    
    NSArray<NSDictionary*> *members = dictory[@"members"];
    if(members && members.count>0) {
        NSMutableArray *memberUIDs = [NSMutableArray array];
        for (NSDictionary *memberDict in members) {
            [memberUIDs addObject:memberDict[@"uid"]];
        }
        resp.members = memberUIDs;
    }
    NSArray<NSDictionary*> *groups = dictory[@"groups"];
    if(groups && groups.count>0) {
        NSMutableArray *memberUIDs = [NSMutableArray array];
        NSMutableArray *names = [NSMutableArray array];
        for (NSDictionary *memberDict in groups) {
            [memberUIDs addObject:memberDict[@"group_no"]];
            [names addObject:memberDict[@"group_name"]];
        }
        resp.groups = memberUIDs;
        resp.groupNames = names;
    }
    return resp;
}

@end
