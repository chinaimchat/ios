//
//  LLLabelAddVC.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelAddVC.h"
#import "LLLabelConst.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface LLLabelAddVC ()

@end

@implementation LLLabelAddVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [LLLabelAddVM new];
    }
    return self;
}

- (void)viewDidLoad {
    self.viewModel.label = self.label;
    if (!self.label && self.prefilledMemberUids.count > 0) {
        NSMutableArray<WKChannelInfo *> *items = [NSMutableArray array];
        for (NSString *uid in self.prefilledMemberUids) {
            WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:uid]];
            if (info) {
                [items addObject:info];
            }
        }
        self.viewModel.memberItems = items;
        [self.viewModel notifyMemberItemsChanged];
    }
    __weak typeof(self) weakSelf = self;
    self.viewModel.onUpdateFinishBtn = ^{
        [weakSelf updateFinishBtn];
    };

    [super viewDidLoad];
    [self.finishBtn setTitle:LLang(@"保存") forState:UIControlStateNormal];
    self.finishBtn.enabled = NO;
    self.rightView = self.finishBtn;

    [self.finishBtn addTarget:self action:@selector(finishedPressed) forControlEvents:UIControlEventTouchUpInside];
}
- (NSString *)langTitle {
    if (self.label) {
        NSString *n = self.label.name;
        return (n.length > 0) ? n : LLang(@"保存为标签");
    }
    return LLang(@"保存为标签");
}

-(void) finishedPressed {
    __weak typeof(self) weakSelf = self;
    [weakSelf.view showHUD];
    [self.viewModel finishLabel].then(^{
        [weakSelf.view hideHud];
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_LABELLIST_REFRESH object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"分组变动" object:nil];
    }).catch(^(NSError *error){
        [weakSelf.view switchHUDError:error.domain];
    });
}

- (void)reloadData {
    [super reloadData];
    [self updateFinishBtn];
}

-(void) updateFinishBtn {
    self.finishBtn.enabled = YES;
    if(!self.viewModel.labelName || [[self.viewModel.labelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        self.finishBtn.enabled = NO;
        return;
    }
    if(!self.viewModel.memberItems || self.viewModel.memberItems.count<=0) {
        self.finishBtn.enabled = NO;
        return;
    }
}

@end
