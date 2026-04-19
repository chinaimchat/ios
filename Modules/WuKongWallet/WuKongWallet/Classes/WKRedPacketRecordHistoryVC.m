#import "WKRedPacketRecordHistoryVC.h"
#import "WKWalletAPI.h"
#import "WKRedPacketRecordDetailEnricher.h"
#import <WuKongRedPackets/WKRedPacketAPI.h>
#import <WuKongRedPackets/WKRedPacketDetailVC.h>
#import <WuKongRedPackets/WKRedPacketContent.h>

static const NSInteger kWKRedPacketHistoryPageSize = 20;

static NSString *WKRPStr(id o) {
    if (!o || o == (id)kCFNull) {
        return @"";
    }
    if ([o isKindOfClass:[NSString class]]) {
        return (NSString *)o;
    }
    return [NSString stringWithFormat:@"%@", o];
}

static NSArray *WKWalletTransactionArrayFromAPIResult(id result) {
    if ([result isKindOfClass:[NSArray class]]) {
        return (NSArray *)result;
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
        return @[];
    }
    NSDictionary *d = (NSDictionary *)result;
    NSArray *keys = @[ @"data", @"list", @"items", @"rows", @"result", @"transactions", @"records" ];
    for (NSString *k in keys) {
        id v = d[k];
        if ([v isKindOfClass:[NSArray class]]) {
            return v;
        }
    }
    return @[];
}

static BOOL WKIsRedPacketTransaction(NSDictionary *r) {
    NSString *t = WKRPStr(r[@"type"]);
    return [t isEqualToString:@"redpacket_receive"] || [t isEqualToString:@"redpacket_send"];
}

static long long WKParseCreatedMillis(NSString *createdAt) {
    if (createdAt.length == 0) {
        return 0;
    }
    NSString *s = [createdAt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([s hasSuffix:@"Z"]) {
        s = [s substringToIndex:s.length - 1];
    }
    NSArray<NSString *> *patterns = @[
        @"yyyy-MM-dd HH:mm:ss.SSS",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS",
        @"yyyy-MM-dd'T'HH:mm:ss",
        @"MM-dd HH:mm",
    ];
    NSLocale *us = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for (NSString *p in patterns) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.locale = us;
        fmt.dateFormat = p;
        NSDate *d = [fmt dateFromString:s];
        if (d) {
            return (long long)([d timeIntervalSince1970] * 1000.0);
        }
    }
    NSDateFormatter *fallback = [[NSDateFormatter alloc] init];
    fallback.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *d = [fallback dateFromString:s];
    return d ? (long long)([d timeIntervalSince1970] * 1000.0) : 0;
}

static NSString *WKFormatRowTime(NSString *createdAt) {
    long long ms = WKParseCreatedMillis(createdAt);
    if (ms <= 0) {
        return createdAt.length ? createdAt : @"";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ms / 1000.0];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM-dd HH:mm";
    return [fmt stringFromDate:date];
}

static int WKIntFromDict(NSDictionary *d, NSString *key, int def) {
    id o = d[key];
    if ([o respondsToSelector:@selector(intValue)]) {
        return (int)[o intValue];
    }
    return def;
}

static NSString *WKRedPacketTypeTitleForPacketType(int packetType) {
    switch (packetType) {
        case WKRedPacketTypeIndividual:
            return LLangC(@"个人红包", [WKRedPacketRecordHistoryVC class]);
        case WKRedPacketTypeGroupRandom:
            return LLangC(@"拼手气红包", [WKRedPacketRecordHistoryVC class]);
        case WKRedPacketTypeGroupNormal:
            return LLangC(@"普通红包", [WKRedPacketRecordHistoryVC class]);
        case WKRedPacketTypeExclusive:
            return LLangC(@"专属红包", [WKRedPacketRecordHistoryVC class]);
        default:
            return @"";
    }
}

@interface WKRedPacketRecordHistoryVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) NSInteger selectedYear;
@property (nonatomic, assign) BOOL tabReceived;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *yearBuffer;
@property (nonatomic, assign) BOOL loadingYear;
@property (nonatomic, assign) int loadPage;
@property (nonatomic, assign) int displayGeneration;

@property (nonatomic, strong) UIButton *tabReceivedBtn;
@property (nonatomic, strong) UIButton *tabSentBtn;
@property (nonatomic, strong) UIView *indicatorReceived;
@property (nonatomic, strong) UIView *indicatorSent;
@property (nonatomic, strong) UIButton *yearButton;
@property (nonatomic, strong) UILabel *summaryCountLabel;
@property (nonatomic, strong) UILabel *summaryAmountLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
/// 与 Android {@code activity_redpacket_record_history.xml#pageLoadingBar}：标题栏下 4pt 横向不确定进度。
@property (nonatomic, strong) UIProgressView *pageProgressBar;
@property (nonatomic, strong) NSLayoutConstraint *pageBarHeightConstraint;

/// 元素为 {@link NSMutableDictionary}，便于与 {@link WKRedPacketRecordDetailEnricher} 原地补全。
@property (nonatomic, copy) NSArray *displayList;

@end

@implementation WKRedPacketRecordHistoryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"红包记录");
    self.view.backgroundColor = UIColor.whiteColor;
    self.tabReceived = YES;
    self.yearBuffer = [NSMutableArray array];
    self.displayList = @[];
    NSCalendar *cal = [NSCalendar currentCalendar];
    self.selectedYear = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64.0;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onPullRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;

    self.pageProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.pageProgressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageProgressBar.trackTintColor = [UIColor colorWithWhite:0.90 alpha:1];
    UIColor *barTint = [WKApp shared].config.themeColor ?: [UIColor colorWithRed:0.12 green:0.68 blue:0.36 alpha:1];
    self.pageProgressBar.progressTintColor = barTint;
    self.pageProgressBar.hidden = YES;
    [self.view addSubview:self.pageProgressBar];

    [self buildHeader];

    self.pageBarHeightConstraint = [self.pageProgressBar.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.pageProgressBar.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor],
        [self.pageProgressBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pageProgressBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.pageBarHeightConstraint,
        [self.tableView.topAnchor constraintEqualToAnchor:self.pageProgressBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self applyTabStyle];
    [self startLoadYear];
}

/// 与 Android {@code RedPacketRecordHistoryActivity#setPageLoadingUi}。
- (void)setPageLoadingUi:(BOOL)show {
    if (show) {
        self.pageProgressBar.layer.speed = 0.0f;
        [UIView performWithoutAnimation:^{
            [self.pageProgressBar setProgress:0.0f animated:NO];
        }];
        self.pageProgressBar.layer.speed = 1.0f;
        self.pageBarHeightConstraint.constant = 4.0;
        self.pageProgressBar.hidden = NO;
        [self.view layoutIfNeeded];
        [self.pageProgressBar.layer removeAllAnimations];
        [self.pageProgressBar setProgress:0.0f animated:NO];
        [UIView animateWithDuration:0.65f
                              delay:0
                            options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self.pageProgressBar setProgress:0.92f animated:YES];
                         }
                         completion:nil];
    } else {
        self.pageProgressBar.layer.speed = 0.0f;
        [UIView performWithoutAnimation:^{
            [self.pageProgressBar setProgress:0.0f animated:NO];
        }];
        self.pageBarHeightConstraint.constant = 0.0;
        self.pageProgressBar.hidden = YES;
        self.pageProgressBar.layer.speed = 1.0f;
        [self.view layoutIfNeeded];
    }
}

- (void)buildHeader {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 132)];
    header.backgroundColor = UIColor.whiteColor;

    CGFloat w = self.view.bounds.size.width > 0 ? self.view.bounds.size.width : [UIScreen mainScreen].bounds.size.width;
    self.tabReceivedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.tabReceivedBtn setTitle:LLang(@"我收到的") forState:UIControlStateNormal];
    self.tabReceivedBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.tabReceivedBtn addTarget:self action:@selector(onTabReceived) forControlEvents:UIControlEventTouchUpInside];
    self.tabReceivedBtn.frame = CGRectMake(0, 8, w / 2.0, 36);

    self.tabSentBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.tabSentBtn setTitle:LLang(@"我发出的") forState:UIControlStateNormal];
    self.tabSentBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.tabSentBtn addTarget:self action:@selector(onTabSent) forControlEvents:UIControlEventTouchUpInside];
    self.tabSentBtn.frame = CGRectMake(w / 2.0, 8, w / 2.0, 36);

    self.indicatorReceived = [[UIView alloc] initWithFrame:CGRectMake(w / 4.0 - 30, 44, 60, 3)];
    UIColor *tabTint = [WKApp shared].config.themeColor ?: [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
    self.indicatorReceived.backgroundColor = tabTint;
    self.indicatorSent = [[UIView alloc] initWithFrame:CGRectMake(w * 3.0 / 4.0 - 30, 44, 60, 3)];
    self.indicatorSent.backgroundColor = tabTint;
    self.indicatorSent.hidden = YES;

    self.yearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.yearButton addTarget:self action:@selector(onPickYear) forControlEvents:UIControlEventTouchUpInside];
    self.yearButton.frame = CGRectMake(16, 52, w - 32, 32);
    [self refreshYearLabel];

    self.summaryCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 88, w / 2.0 - 24, 20)];
    self.summaryCountLabel.font = [UIFont systemFontOfSize:13];
    self.summaryCountLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];

    self.summaryAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(w / 2.0 + 8, 88, w / 2.0 - 24, 20)];
    self.summaryAmountLabel.font = [UIFont systemFontOfSize:13];
    self.summaryAmountLabel.textAlignment = NSTextAlignmentRight;
    self.summaryAmountLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];

    [header addSubview:self.tabReceivedBtn];
    [header addSubview:self.tabSentBtn];
    [header addSubview:self.indicatorReceived];
    [header addSubview:self.indicatorSent];
    [header addSubview:self.yearButton];
    [header addSubview:self.summaryCountLabel];
    [header addSubview:self.summaryAmountLabel];

    self.tableView.tableHeaderView = header;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header = self.tableView.tableHeaderView;
    if (header) {
        CGFloat w = self.view.bounds.size.width;
        header.frame = CGRectMake(0, 0, w, 132);
        self.tabReceivedBtn.frame = CGRectMake(0, 8, w / 2.0, 36);
        self.tabSentBtn.frame = CGRectMake(w / 2.0, 8, w / 2.0, 36);
        self.indicatorReceived.frame = CGRectMake(w / 4.0 - 30, 44, 60, 3);
        self.indicatorSent.frame = CGRectMake(w * 3.0 / 4.0 - 30, 44, 60, 3);
        self.yearButton.frame = CGRectMake(16, 52, w - 32, 32);
        self.summaryCountLabel.frame = CGRectMake(16, 88, w / 2.0 - 24, 20);
        self.summaryAmountLabel.frame = CGRectMake(w / 2.0 + 8, 88, w / 2.0 - 24, 20);
        self.tableView.tableHeaderView = header;
    }
}

- (void)refreshYearLabel {
    [self.yearButton setTitle:[NSString stringWithFormat:LLang(@"%ld 年 ▼"), (long)self.selectedYear] forState:UIControlStateNormal];
}

- (void)applyTabStyle {
    UIColor *active = [WKApp shared].config.themeColor ?: [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
    UIColor *idle = [UIColor colorWithWhite:0.55 alpha:1];
    [self.tabReceivedBtn setTitleColor:self.tabReceived ? active : idle forState:UIControlStateNormal];
    [self.tabSentBtn setTitleColor:self.tabReceived ? idle : active forState:UIControlStateNormal];
    self.tabReceivedBtn.titleLabel.font = self.tabReceived ? [UIFont boldSystemFontOfSize:16] : [UIFont systemFontOfSize:16];
    self.tabSentBtn.titleLabel.font = self.tabReceived ? [UIFont systemFontOfSize:16] : [UIFont boldSystemFontOfSize:16];
    self.indicatorReceived.hidden = !self.tabReceived;
    self.indicatorSent.hidden = self.tabReceived;
}

- (void)onTabReceived {
    if (!self.tabReceived) {
        self.tabReceived = YES;
        [self applyTabStyle];
        [self applyTabFromBuffer];
    }
}

- (void)onTabSent {
    if (self.tabReceived) {
        self.tabReceived = NO;
        [self applyTabStyle];
        [self applyTabFromBuffer];
    }
}

- (void)onPullRefresh {
    if (!self.loadingYear) {
        [self startLoadYear];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (void)onPickYear {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger yNow = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:LLang(@"选择年份") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSInteger i = 0; i < 11; i++) {
        NSInteger y = yNow - i;
        [ac addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:LLang(@"%ld 年"), (long)y] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.selectedYear = y;
            [weakSelf refreshYearLabel];
            [weakSelf startLoadYear];
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [[WKNavigationManager shared].topViewController presentViewController:ac animated:YES completion:nil];
}

- (NSString *)yearStartString {
    return [NSString stringWithFormat:@"%ld-01-01 00:00:00", (long)self.selectedYear];
}

- (NSString *)yearEndString {
    return [NSString stringWithFormat:@"%ld-12-31 23:59:59", (long)self.selectedYear];
}

- (void)startLoadYear {
    if (self.loadingYear) {
        return;
    }
    self.displayGeneration++;
    self.loadingYear = YES;
    [self.yearBuffer removeAllObjects];
    self.loadPage = 1;
    [self.refreshControl endRefreshing];
    [self setPageLoadingUi:YES];
    [self fetchNextPage];
}

- (void)fetchNextPage {
    NSString *start = [self yearStartString];
    NSString *end = [self yearEndString];
    __weak typeof(self) weakSelf = self;
    int page = self.loadPage;
    [[WKWalletAPI shared] getTransactionsPage:page size:(int)kWKRedPacketHistoryPageSize startDate:start endDate:end callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (error) {
                strongSelf.loadingYear = NO;
                [strongSelf setPageLoadingUi:NO];
                [strongSelf.refreshControl endRefreshing];
                NSString *msg = error.localizedDescription.length ? error.localizedDescription : LLang(@"加载失败");
                [strongSelf.view showMsg:msg];
                strongSelf.displayList = @[];
                [strongSelf.tableView reloadData];
                [strongSelf updateSummaryWithList:@[]];
                return;
            }
            NSArray *raw = WKWalletTransactionArrayFromAPIResult((id)result);
            for (id item in raw) {
                if (![item isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                NSDictionary *row = (NSDictionary *)item;
                if (WKIsRedPacketTransaction(row)) {
                    [strongSelf.yearBuffer addObject:[row mutableCopy]];
                }
            }
            if (raw.count >= (NSUInteger)kWKRedPacketHistoryPageSize) {
                strongSelf.loadPage = page + 1;
                [strongSelf fetchNextPage];
            } else {
                strongSelf.loadingYear = NO;
                [strongSelf refreshControlEndIfNeeded];
                [strongSelf sortBufferByTimeDesc];
                [strongSelf applyTabFromBuffer];
            }
        });
    }];
}

- (void)refreshControlEndIfNeeded {
    if (self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)sortBufferByTimeDesc {
    [self.yearBuffer sortUsingComparator:^NSComparisonResult(NSMutableDictionary *a, NSMutableDictionary *b) {
        NSString *ca = WKRPStr(a[@"created_at"] ?: a[@"createdAt"]);
        NSString *cb = WKRPStr(b[@"created_at"] ?: b[@"createdAt"]);
        long long ma = WKParseCreatedMillis(ca);
        long long mb = WKParseCreatedMillis(cb);
        if (ma > mb) {
            return NSOrderedAscending;
        }
        if (ma < mb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (void)applyTabFromBuffer {
    self.displayGeneration++;
    NSInteger gen = self.displayGeneration;
    NSMutableArray<NSMutableDictionary *> *show = [NSMutableArray array];
    for (NSMutableDictionary *r in self.yearBuffer) {
        NSString *t = WKRPStr(r[@"type"]);
        if (self.tabReceived && [t isEqualToString:@"redpacket_receive"]) {
            [show addObject:r];
        } else if (!self.tabReceived && [t isEqualToString:@"redpacket_send"]) {
            [show addObject:r];
        }
    }
    [self sortShowListByTimeDesc:show];

    // 与 Android applyTabFromBuffer：进度条保持显示，列表与汇总先清空，并行 enrich 完成后再展示。
    [self setPageLoadingUi:YES];
    self.displayList = @[];
    [self.tableView reloadData];
    [self updateSummaryWithList:@[]];

    __weak typeof(self) weakSelf = self;
    [WKRedPacketRecordDetailEnricher scheduleParallelEnrichRedPacketRecords:show completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.displayGeneration != gen) {
            return;
        }
        strongSelf.displayList = show;
        [strongSelf.tableView reloadData];
        [strongSelf updateSummaryWithList:strongSelf.displayList];
        [strongSelf setPageLoadingUi:NO];
    }];
}

- (void)sortShowListByTimeDesc:(NSMutableArray<NSMutableDictionary *> *)show {
    [show sortUsingComparator:^NSComparisonResult(NSMutableDictionary *a, NSMutableDictionary *b) {
        NSString *ca = WKRPStr(a[@"created_at"] ?: a[@"createdAt"]);
        NSString *cb = WKRPStr(b[@"created_at"] ?: b[@"createdAt"]);
        long long ma = WKParseCreatedMillis(ca);
        long long mb = WKParseCreatedMillis(cb);
        if (ma > mb) {
            return NSOrderedAscending;
        }
        if (ma < mb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (void)updateSummaryWithList:(NSArray<NSDictionary *> *)list {
    double sum = 0;
    for (NSDictionary *r in list) {
        double amt = [r[@"amount"] doubleValue];
        NSString *t = WKRPStr(r[@"type"]);
        if ([t isEqualToString:@"redpacket_receive"]) {
            sum += amt;
        } else {
            sum += fabs(amt);
        }
    }
    NSUInteger n = list.count;
    if (self.tabReceived) {
        self.summaryCountLabel.text = [NSString stringWithFormat:LLang(@"共收到 %lu 个红包"), (unsigned long)n];
    } else {
        self.summaryCountLabel.text = [NSString stringWithFormat:LLang(@"共发出 %lu 个红包"), (unsigned long)n];
    }
    self.summaryAmountLabel.text = [NSString stringWithFormat:LLang(@"合计 ¥%.2f"), sum];
}

#pragma mark - Row text

- (NSDictionary *)contextDictForRecord:(NSDictionary *)r {
    id ctx = r[@"context"];
    if ([ctx isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)ctx;
    }
    return nil;
}

- (NSString *)titleForRecord:(NSDictionary *)r {
    NSString *t = WKRPStr(r[@"type"]);
    NSDictionary *ctx = [self contextDictForRecord:r];
    BOOL received = [t isEqualToString:@"redpacket_receive"];
    if (received) {
        NSString *from = WKRPStr(r[@"from_user_name"] ?: r[@"fromName"]);
        if (from.length == 0) {
            from = WKRPStr(r[@"peer_name"] ?: r[@"peerName"]);
        }
        if (from.length == 0 && ctx) {
            from = WKRPStr(ctx[@"from_user_name"] ?: ctx[@"fromName"]);
        }
        if (from.length == 0) {
            from = WKRPStr(ctx[@"peer_name"]);
        }
        return from.length > 0 ? from : LLang(@"红包");
    }
    int packetType = 0;
    if (ctx) {
        id pt = ctx[@"packet_type"] ?: ctx[@"packetType"];
        if ([pt respondsToSelector:@selector(intValue)]) {
            packetType = (int)[pt intValue];
        }
    }
    NSString *typeLine = WKRedPacketTypeTitleForPacketType(packetType);
    if (typeLine.length > 0) {
        return typeLine;
    }
    NSString *g = WKRPStr(r[@"group_name"] ?: r[@"groupName"]);
    if (g.length == 0 && ctx) {
        g = WKRPStr(ctx[@"group_name"] ?: ctx[@"channel_name"]);
    }
    return g.length > 0 ? g : LLang(@"红包");
}

- (NSString *)subtitleForRecord:(NSDictionary *)r {
    NSMutableString *sub = [NSMutableString string];
    NSString *time = WKFormatRowTime(WKRPStr(r[@"created_at"] ?: r[@"createdAt"]));
    [sub appendString:time];
    NSString *t = WKRPStr(r[@"type"]);
    if ([t isEqualToString:@"redpacket_send"]) {
        NSDictionary *ctx = [self contextDictForRecord:r];
        int total = ctx ? WKIntFromDict(ctx, @"redpacket_total_count", -1) : -1;
        int remaining = ctx ? WKIntFromDict(ctx, @"redpacket_remaining_count", -1) : -1;
        if (total > 0 && remaining >= 0) {
            int st = ctx ? WKIntFromDict(ctx, @"redpacket_status", 0) : 0;
            if (st == 2) {
                [sub appendString:LLang(@" · 已过期")];
            } else if (remaining == 0) {
                [sub appendString:LLang(@" · 已领完")];
            } else {
                int claimed = total - remaining;
                if (claimed < 0) {
                    claimed = 0;
                }
                [sub appendString:[NSString stringWithFormat:LLang(@" · 已领 %d/%d"), claimed, total]];
            }
        }
    }
    return [sub copy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"rp_hist";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    }
    NSDictionary *r = self.displayList[(NSUInteger)indexPath.row];
    cell.textLabel.text = [self titleForRecord:r];
    cell.detailTextLabel.text = [self subtitleForRecord:r];
    NSString *t = WKRPStr(r[@"type"]);
    double amt = [r[@"amount"] doubleValue];
    if (![t isEqualToString:@"redpacket_receive"]) {
        amt = fabs(amt);
    }
    UILabel *acc = [[UILabel alloc] init];
    acc.font = [UIFont boldSystemFontOfSize:16];
    acc.text = [NSString stringWithFormat:@"¥%.2f", amt];
    acc.textColor = [t isEqualToString:@"redpacket_receive"]
        ? [UIColor colorWithRed:0.20 green:0.72 blue:0.32 alpha:1]
        : [UIColor colorWithRed:0.96 green:0.35 blue:0.25 alpha:1];
    [acc sizeToFit];
    cell.accessoryView = acc;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ((NSUInteger)indexPath.row >= self.displayList.count) {
        return;
    }
    NSDictionary *r = self.displayList[(NSUInteger)indexPath.row];
    [self openRedPacketDetailFromRecord:r];
}

- (void)openRedPacketDetailFromRecord:(NSDictionary *)r {
    NSString *packetNo = WKRPStr(r[@"related_id"] ?: r[@"relatedId"]);
    if (packetNo.length == 0) {
        return;
    }
    NSDictionary *ctx = [self contextDictForRecord:r];
    NSString *cid = WKRPStr(ctx[@"channel_id"] ?: ctx[@"channelId"]);
    id ctObj = ctx[@"channel_type"] ?: ctx[@"channelType"];
    if (cid.length > 0 && ctObj != nil && [ctObj respondsToSelector:@selector(unsignedIntValue)]) {
        uint8_t cty = (uint8_t)[ctObj unsignedIntValue];
        WKRedPacketDetailVC *vc = [[WKRedPacketDetailVC alloc] initWithPacketNo:packetNo channelId:cid channelType:cty hideRedPacketRecordEntry:YES];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return;
    }
    [[WKRedPacketAPI shared] getRedPacketDetail:packetNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && !error) {
                NSString *ch = WKRPStr(result[@"channel_id"]);
                id rct = result[@"channel_type"];
                if (ch.length > 0 && rct != nil && [rct respondsToSelector:@selector(unsignedIntValue)]) {
                    WKRedPacketDetailVC *vc = [[WKRedPacketDetailVC alloc] initWithPacketNo:packetNo channelId:ch channelType:(uint8_t)[rct unsignedIntValue] hideRedPacketRecordEntry:YES];
                    [[WKNavigationManager shared] pushViewController:vc animated:YES];
                    return;
                }
            }
            WKRedPacketDetailVC *vc = [[WKRedPacketDetailVC alloc] initWithPacketNo:packetNo channelId:nil channelType:WK_PERSON hideRedPacketRecordEntry:YES];
            [[WKNavigationManager shared] pushViewController:vc animated:YES];
        });
    }];
}

@end
