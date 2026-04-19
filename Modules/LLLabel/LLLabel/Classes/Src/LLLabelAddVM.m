//
//  LLLabelAddVM.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelAddVM.h"
#import "LLLabelNameSettingCell.h"
#import "LLLabelAddCell.h"
#import "LLLabelNameSettingInputCell.h"
#import "LLLabelMemberGridCell.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface LLLabelAddVM ()

@property(nonatomic,strong) NSMutableArray *headerItems;

@end

@implementation LLLabelAddVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    [self.headerItems removeAllObjects];

    NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [self.headerItems addObject: @{
        @"height":@(0.1f),
        @"title": LLang(@"标签名字"),
        @"items": @[
                @{
                    @"class":LLLabelNameSettingInputModel.class,
                    @"value": self.labelName?:@"",
                    @"placeholder":LLang(@"未设置标签名字"),
                    @"showArrow":@(false),
                    @"onChange":^(NSString *value){
                        weakSelf.labelName = value;
                        if(weakSelf.onUpdateFinishBtn) {
                            weakSelf.onUpdateFinishBtn();
                        }
                    },
                    @"onClick":^(WKFormItemModel * _Nonnull m, NSIndexPath * _Nonnull ip){
                        (void)m;
                        (void)ip;
                        WKInputVC *vc = [WKInputVC new];
                        vc.maxLength = 36;
                        vc.placeholder = LLang(@"例如家人、朋友");
                        vc.defaultValue = weakSelf.labelName;
                        [vc setOnFinish:^(NSString * _Nonnull value) {
                            [[WKNavigationManager shared] popViewControllerAnimated:YES];
                            weakSelf.labelName = value;
                            [weakSelf reloadData];
                        }];
                        [[WKNavigationManager shared] pushViewController:vc animated:YES];
                    }
                }
        ],
    }];

    CGFloat gridH = [LLLabelMemberGridModel heightForMemberCount:(NSInteger)self.memberItems.count tableWidth:WKScreenWidth];
    [self.headerItems addObject:  @{
        @"height":@(0.1f),
        @"title": [NSString stringWithFormat:LLang(@"成员（%lu）"), (unsigned long)self.memberItems.count],
        @"items": @[
                @{
                    @"class": LLLabelMemberGridModel.class,
                    @"cellHeight": @(gridH),
                    @"addVM": self,
                    @"showArrow": @(NO),
                },
        ],
    }];

    [items addObjectsFromArray:self.headerItems];

    if (self.label) {
        [items addObject:@{
            @"height": @(16.0f),
            @"title": @"",
            @"items": @[
                    @{
                        @"class": LLLabelAddModel.class,
                        @"title": LLang(@"删除标签"),
                        @"dangerStyle": @(YES),
                        @"showArrow": @(NO),
                        @"onClick": ^(WKFormItemModel * _Nonnull m, NSIndexPath * _Nonnull ip) {
                            (void)m;
                            (void)ip;
                            [WKAlertUtil alert:LLang(@"标签中的联系人不会被删除，是否删除标签？") buttonsStatement:@[ LLang(@"取消"), LLang(@"确定") ] chooseBlock:^(NSInteger buttonIdx) {
                                if (buttonIdx != 1) {
                                    return;
                                }
                                UIView *v = [WKNavigationManager shared].topViewController.view;
                                [v showHUD];
                                [weakSelf deleteLabel].then(^{
                                    [v hideHud];
                                    [[WKNavigationManager shared] popViewControllerAnimated:YES];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_LABELLIST_REFRESH object:nil];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"分组变动" object:nil];
                                }).catch(^(NSError *error) {
                                    [v switchHUDError:error.domain];
                                });
                            }];
                        },
                    },
            ],
        }];
    }

    return items;
}

- (void)setLabel:(LLLabelResp *)label {
    _label = label;
    if(label) {
        self.labelName = label.name;
        NSMutableArray<WKChannelInfo*> *members = [NSMutableArray array];
        if(label.members) {
            for (NSString *uid in label.members) {
                WKChannelInfo *channelInfo =  [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:uid]];
                if(channelInfo) {
                    [members addObject:channelInfo];
                }
            }
        }
        self.memberItems = members;
        [self notifyMemberItemsChanged];
    }
}

- (void)notifyMemberItemsChanged {
    if (self.onUpdateFinishBtn) {
        self.onUpdateFinishBtn();
    }
    [self reloadData];
}

- (void)openMemberPicker {
    __weak typeof(self) weakSelf = self;
    NSMutableArray<NSString*> *selecteds = [NSMutableArray array];
    if (self.memberItems) {
        for (WKChannelInfo *channelInfo in self.memberItems) {
            if (channelInfo.channel.channelType == WK_PERSON) {
                [selecteds addObject:channelInfo.channel.channelId];
            }
        }
    }
    [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT param:@{
        @"selecteds": selecteds,
        @"on_finished":^(NSArray<NSString*> *uids){
            [[WKNavigationManager shared] popViewControllerAnimated:YES];
            NSMutableArray *items = [NSMutableArray array];
            if (uids) {
                for (NSString *uid in uids) {
                    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:uid]];
                    if (channelInfo) {
                        [items addObject:channelInfo];
                    }
                }
            }
            weakSelf.memberItems = items;
            [weakSelf notifyMemberItemsChanged];
        },
    }];
}

-(AnyPromise*) finishLabel {
    NSMutableArray *uids = [NSMutableArray array];
    if(self.memberItems) {
        for (WKChannelInfo *channelInfo in self.memberItems) {
            if (channelInfo.channel.channelType == WK_PERSON) {
                [uids addObject:channelInfo.channel.channelId];
            }
        }
    }
    NSArray *groupIds = @[];
    if(self.label) { // 更新 — 与 Android {@link LabelService#updateLabel}
        return [[WKAPIClient sharedClient] PUT:[NSString stringWithFormat:@"label/%@", self.label._id] parameters:@{
            @"name":self.labelName?:@"",
            @"member_uids": uids,
            @"group_ids": groupIds,
        }];
    } else { // 添加 — 与 Android {@link LabelService#addLabel}
        return [[WKAPIClient sharedClient] POST:@"label" parameters:@{
            @"name":self.labelName?:@"",
            @"member_uids": uids,
            @"group_ids": groupIds,
        }];
    }

}

- (AnyPromise *)deleteLabel {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"label/%@", self.label._id] parameters:nil];
}

-(void) removeMemberWithUID:(NSString *)uid {
    if(self.memberItems && self.memberItems.count>0) {
        NSInteger i= 0;
        for (WKChannelInfo *member in self.memberItems) {
            if ([member.channel.channelId isEqualToString:uid]) {
                [self removeMember:i];
                return;
            }
            i++;
        }
    }
}

-(void) removeMember:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.memberItems.count) {
        return;
    }
    [self.memberItems removeObjectAtIndex:(NSUInteger)index];
    [self notifyMemberItemsChanged];
}

- (NSMutableArray *)headerItems {
    if(!_headerItems) {
        _headerItems = [NSMutableArray array];
    }
    return _headerItems;
}

- (NSMutableArray<WKChannelInfo *> *)memberItems {
    if(!_memberItems) {
        _memberItems = [NSMutableArray array];
    }
    return _memberItems;
}

- (NSInteger)headerCount {
    return self.headerItems.count;
}

@end
