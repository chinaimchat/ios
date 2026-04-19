//
//  LLLabelListVC.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelListVC.h"
#import "LLLabelConst.h"
#import "LLLabelListCell.h"
#import "LLLabelAddVC.h"
#import "WKFormSection.h"
#import <WuKongBase/WKBaseTableVM.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface LLLabelListVC ()

@property (nonatomic, strong) UIView *emptyTipsContainer;
@property (nonatomic, strong) UILabel *emptyTitleLabel;
@property (nonatomic, strong) UILabel *emptySubtitleLabel;

@end

@implementation LLLabelListVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewModel = [LLLabelListVM new];
    }
    return self;
}

- (void)viewDidLoad {
    [self buildEmptyTipsIfNeeded];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshList) name:WK_NOTIFY_LABELLIST_REFRESH object:nil];

    UIButton *createBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [createBtn setTitle:LLang(@"新建") forState:UIControlStateNormal];
    [[createBtn titleLabel] setFont:[[WKApp shared].config appFontOfSize:16.0f]];
    createBtn.frame = CGRectMake(0.0f, 0.0f, 52.0f, 36.0f);
    [createBtn addTarget:self action:@selector(onNavCreateLabel) forControlEvents:UIControlEventTouchUpInside];
    [self setRightView:createBtn];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onListLongPress:)];
    lp.minimumPressDuration = 0.35;
    [self.tableView addGestureRecognizer:lp];
}

- (NSString *)langTitle {
    return LLang(@"标签");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WK_NOTIFY_LABELLIST_REFRESH object:nil];
}

- (void)buildEmptyTipsIfNeeded {
    if (self.emptyTipsContainer) {
        return;
    }
    self.emptyTipsContainer = [[UIView alloc] init];
    self.emptyTipsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyTipsContainer.backgroundColor = [WKApp shared].config.backgroundColor;
    self.emptyTipsContainer.hidden = YES;

    self.emptyTitleLabel = [[UILabel alloc] init];
    self.emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyTitleLabel.text = LLang(@"暂无标签");
    self.emptyTitleLabel.font = [[WKApp shared].config appFontOfSize:14.0f];
    self.emptyTitleLabel.textColor = [WKApp shared].config.defaultTextColor;
    self.emptyTitleLabel.textAlignment = NSTextAlignmentCenter;

    self.emptySubtitleLabel = [[UILabel alloc] init];
    self.emptySubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptySubtitleLabel.text = LLang(@"你可以通过给朋友添加标签来进行分类");
    self.emptySubtitleLabel.font = [[WKApp shared].config appFontOfSize:14.0f];
    self.emptySubtitleLabel.textColor = [WKApp shared].config.tipColor;
    self.emptySubtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.emptySubtitleLabel.numberOfLines = 0;

    [self.emptyTipsContainer addSubview:self.emptyTitleLabel];
    [self.emptyTipsContainer addSubview:self.emptySubtitleLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.emptyTipsContainer.superview != self.view) {
        [self.view addSubview:self.emptyTipsContainer];
        [NSLayoutConstraint activateConstraints:@[
            [self.emptyTipsContainer.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor],
            [self.emptyTipsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.emptyTipsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.emptyTipsContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [self.emptyTitleLabel.centerXAnchor constraintEqualToAnchor:self.emptyTipsContainer.centerXAnchor],
            [self.emptyTitleLabel.topAnchor constraintEqualToAnchor:self.emptyTipsContainer.topAnchor constant:30.0f],
            [self.emptyTitleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.emptyTipsContainer.leadingAnchor constant:24.0f],
            [self.emptySubtitleLabel.topAnchor constraintEqualToAnchor:self.emptyTitleLabel.bottomAnchor constant:10.0f],
            [self.emptySubtitleLabel.centerXAnchor constraintEqualToAnchor:self.emptyTipsContainer.centerXAnchor],
            [self.emptySubtitleLabel.leadingAnchor constraintEqualToAnchor:self.emptyTipsContainer.leadingAnchor constant:24.0f],
            [self.emptySubtitleLabel.trailingAnchor constraintEqualToAnchor:self.emptyTipsContainer.trailingAnchor constant:-24.0f],
        ]];
    }
}

/// 与 Android：不沿用 WKBaseTableVC 的「暂无数据」占位，按红包记录空态双行文案展示；加载完无行时隐藏列表。
- (void)reloadRemoteData {
    __weak typeof(self) weakSelf = self;
    [self.view showHUD];
    self.emptyTipsContainer.hidden = YES;
    self.tableView.hidden = NO;

    [(LLLabelListVM *)self.viewModel requestData:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view hideHud];
            if (error) {
                [weakSelf.view switchHUDError:error.domain];
                return;
            }
            weakSelf.items = [NSMutableArray arrayWithArray:[(WKBaseTableVM *)weakSelf.viewModel tableSections]];
            NSInteger rows = 0;
            for (WKFormSection *sec in weakSelf.items) {
                rows += (NSInteger)sec.items.count;
            }
            if (rows == 0) {
                weakSelf.tableView.hidden = YES;
                weakSelf.emptyTipsContainer.hidden = NO;
            } else {
                weakSelf.tableView.hidden = NO;
                weakSelf.emptyTipsContainer.hidden = YES;
            }
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)refreshList {
    [self reloadRemoteData];
}

- (void)onNavCreateLabel {
    __weak typeof(self) weakSelf = self;
    [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT param:@{
        @"on_finished": ^(NSArray<NSString *> *uids) {
            [[WKNavigationManager shared] popViewControllerAnimated:YES];
            if (uids.count == 0) {
                return;
            }
            LLLabelAddVC *vc = [[LLLabelAddVC alloc] init];
            vc.prefilledMemberUids = uids;
            [[WKNavigationManager shared] pushViewController:vc animated:YES];
        }
    }];
}

- (void)onListLongPress:(UILongPressGestureRecognizer *)g {
    __weak typeof(self) weakSelf = self;
    if (g.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint p = [g locationInView:self.tableView];
    NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:p];
    if (!ip || ip.section >= (NSInteger)self.items.count) {
        return;
    }
    WKFormSection *sec = self.items[ip.section];
    if (ip.row >= (NSInteger)sec.items.count) {
        return;
    }
    WKFormItemModel *m = sec.items[ip.row];
    if (![m isKindOfClass:[LLLabelListModel class]]) {
        return;
    }
    LLLabelListModel *lm = (LLLabelListModel *)m;
    if (!lm.labelResp) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"删除") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf showDeleteConfirmForLabel:lm.labelResp];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"编辑") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        LLLabelAddVC *vc = [[LLLabelAddVC alloc] init];
        vc.label = lm.labelResp;
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [[WKNavigationManager shared].topViewController presentViewController:sheet animated:YES completion:nil];
}

- (void)showDeleteConfirmForLabel:(LLLabelResp *)label {
    __weak typeof(self) weakSelf = self;
    [WKAlertUtil alert:LLang(@"标签中的联系人不会被删除，是否删除标签？") buttonsStatement:@[ LLang(@"取消"), LLang(@"确定") ] chooseBlock:^(NSInteger buttonIdx) {
        if (buttonIdx != 1) {
            return;
        }
        [weakSelf.view showHUD];
        [weakSelf.viewModel requestDeleteLabel:label._id].then(^{
            [weakSelf.view hideHud];
            [weakSelf reloadRemoteData];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"分组变动" object:nil];
        }).catch(^(NSError *error) {
            [weakSelf.view switchHUDError:error.domain];
        });
    }];
}

@end
