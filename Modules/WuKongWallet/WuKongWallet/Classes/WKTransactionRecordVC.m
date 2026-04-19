#import "WKTransactionRecordVC.h"
#import "WKWalletAPI.h"
#import "WKRedPacketRecordDetailEnricher.h"
static const int kWKTxPageSize = 20;

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

static NSString *WKTxStr(id o) {
    if (!o || o == (id)kCFNull) {
        return @"";
    }
    if ([o isKindOfClass:[NSString class]]) {
        return (NSString *)o;
    }
    return [NSString stringWithFormat:@"%@", o];
}

static NSString *WKTxFirstString(NSDictionary *d, NSArray<NSString *> *keys) {
    for (NSString *k in keys) {
        NSString *s = WKTxStr(d[k]);
        if (s.length) {
            return s;
        }
    }
    return @"";
}

static NSDictionary *WKTxContextDict(NSDictionary *item) {
    id ctx = item[@"context"] ?: item[@"extra"] ?: item[@"meta"] ?: item[@"detail_info"] ?: item[@"extend"] ?: item[@"payload"];
    if ([ctx isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)ctx;
    }
    return nil;
}

static NSString *WKTxStrFromContext(NSDictionary *item, NSArray<NSString *> *keys) {
    NSDictionary *ctx = WKTxContextDict(item);
    if (!ctx) {
        return @"";
    }
    return WKTxFirstString(ctx, keys);
}

static NSString *WKTxResolveGroupName(NSDictionary *item) {
    NSString *g = WKTxFirstString(item, @[ @"group_name", @"groupName", @"channel_name", @"channelName", @"room_name", @"roomName", @"group_title", @"groupTitle" ]);
    if (g.length) {
        return g;
    }
    return WKTxStrFromContext(item, @[ @"group_name", @"groupName", @"channel_name", @"channelName", @"room_name", @"room_title", @"channel_title" ]);
}

static NSString *WKTxResolveFromName(NSDictionary *item) {
    NSString *n = WKTxFirstString(item, @[ @"from_user_name", @"fromName", @"from_name", @"sender_name", @"senderName", @"from_nickname", @"fromNickname", @"from_user", @"fromUser", @"payer_name", @"payerName" ]);
    if (n.length) {
        return n;
    }
    return WKTxStrFromContext(item, @[ @"from_user_name", @"fromName", @"from_name", @"sender_name", @"senderName", @"from_nickname", @"from_user", @"payer_name" ]);
}

static NSString *WKTxResolveToName(NSDictionary *item) {
    NSString *n = WKTxFirstString(item, @[ @"to_user_name", @"toName", @"to_name", @"receiver_name", @"receiverName", @"to_nickname", @"toNickname", @"to_user", @"toUser", @"payee_name", @"payeeName" ]);
    if (n.length) {
        return n;
    }
    return WKTxStrFromContext(item, @[ @"to_user_name", @"toName", @"to_name", @"receiver_name", @"receiverName", @"to_nickname", @"to_user", @"payee_name" ]);
}

static NSString *WKTxResolvePeerName(NSDictionary *item) {
    NSString *n = WKTxFirstString(item, @[ @"peer_name", @"peerName", @"counterparty_name", @"counterpartyName", @"opposite_name", @"oppositeName", @"target_name" ]);
    if (n.length) {
        return n;
    }
    return WKTxStrFromContext(item, @[ @"peer_name", @"peerName", @"counterparty_name", @"target_name" ]);
}

/// 与 Android {@link TransactionRecordAdapter#buildDetail} 一致。
static NSString *WKTxBuildDetail(NSDictionary *item) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSString *group = WKTxResolveGroupName(item);
    if (group.length) {
        [parts addObject:[NSString stringWithFormat:LLangC(@"群：%@", [WKTransactionRecordVC class]), group]];
    }
    NSString *type = WKTxStr(item[@"type"]);
    if ([type isEqualToString:@"redpacket_receive"] || [type isEqualToString:@"transfer_in"]) {
        NSString *from = WKTxResolveFromName(item);
        if (!from.length) {
            from = WKTxResolvePeerName(item);
        }
        if (from.length) {
            [parts addObject:[NSString stringWithFormat:LLangC(@"来自：%@", [WKTransactionRecordVC class]), from]];
        }
    } else if ([type isEqualToString:@"redpacket_send"] || [type isEqualToString:@"transfer_out"]) {
        NSString *to = WKTxResolveToName(item);
        if (!to.length) {
            to = WKTxResolvePeerName(item);
        }
        if (to.length) {
            [parts addObject:[NSString stringWithFormat:LLangC(@"转给：%@", [WKTransactionRecordVC class]), to]];
        }
    }
    if (parts.count == 0) {
        NSString *peer = WKTxResolvePeerName(item);
        if (peer.length) {
            [parts addObject:[NSString stringWithFormat:LLangC(@"对方：%@", [WKTransactionRecordVC class]), peer]];
        }
    }
    double amount = [item[@"amount"] doubleValue];
    if ([type isEqualToString:@"redpacket_receive"]) {
        [parts addObject:[NSString stringWithFormat:LLangC(@"领取 ¥%.2f", [WKTransactionRecordVC class]), amount]];
    } else if ([type isEqualToString:@"transfer_in"]) {
        [parts addObject:[NSString stringWithFormat:LLangC(@"到账 ¥%.2f", [WKTransactionRecordVC class]), amount]];
    } else if ([type isEqualToString:@"redpacket_send"]) {
        [parts addObject:[NSString stringWithFormat:LLangC(@"发出 ¥%.2f", [WKTransactionRecordVC class]), fabs(amount)]];
    } else if ([type isEqualToString:@"transfer_out"]) {
        [parts addObject:[NSString stringWithFormat:LLangC(@"转出 ¥%.2f", [WKTransactionRecordVC class]), fabs(amount)]];
    }
    return parts.count ? [parts componentsJoinedByString:@" · "] : @"";
}

static NSString *WKTxApiDateString(NSDate *date) {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [fmt stringFromDate:date];
}

@interface WKTransactionRecordVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *dataList;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, copy, nullable) NSString *filterStartApi;
@property (nonatomic, copy, nullable) NSString *filterEndApi;

@end

@implementation WKTransactionRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"交易记录");
    self.view.backgroundColor = UIColor.whiteColor;
    self.dataList = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    self.loading = NO;

    UIButton *filterBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [filterBtn setTitle:LLang(@"筛选") forState:UIControlStateNormal];
    filterBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    [filterBtn addTarget:self action:@selector(onFilterTap) forControlEvents:UIControlEventTouchUpInside];
    filterBtn.frame = CGRectMake(0, 0, 52, 36);
    [self setRightView:filterBtn];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 72.0;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [self.view addSubview:self.tableView];

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refresh;

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text = LLang(@"暂无交易记录");
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],
    ]];

    [self loadPage:1 replace:YES];
}

- (void)refreshData {
    self.hasMore = YES;
    [self loadPage:1 replace:YES];
}

/// @param page 从 1 开始；replace=YES 时清空列表（下拉刷新 / 筛选）。
- (void)loadPage:(int)page replace:(BOOL)replace {
    if (self.loading) {
        return;
    }
    self.loading = YES;
    NSString *start = self.filterStartApi;
    NSString *end = self.filterEndApi;
    __weak typeof(self) weakSelf = self;
    [[WKWalletAPI shared] getTransactionsPage:page size:kWKTxPageSize startDate:start endDate:end callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self.tableView.refreshControl endRefreshing];
            self.loading = NO;
            if (error) {
                [WKAlertUtil showMsg:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSArray *list = WKWalletTransactionArrayFromAPIResult((id)result);
            NSMutableArray<NSMutableDictionary *> *batch = [NSMutableArray array];
            for (id o in list) {
                if ([o isKindOfClass:[NSDictionary class]]) {
                    [batch addObject:[(NSDictionary *)o mutableCopy]];
                }
            }
            if (replace) {
                [self.dataList removeAllObjects];
            }
            [self.dataList addObjectsFromArray:batch];
            self.hasMore = (int)batch.count >= kWKTxPageSize;
            self.currentPage = page;
            self.emptyLabel.hidden = self.dataList.count > 0;
            [self.tableView reloadData];

            /// 与 Android {@link TransactionRecordDetailEnricher#scheduleParallelEnrichOnce}：仅对本页批次并行补全，避免重复打详情接口。
            if (batch.count == 0) {
                return;
            }
            __weak typeof(self) weakSelf = self;
            [WKRedPacketRecordDetailEnricher scheduleParallelEnrichWalletTransactionRecords:batch completion:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                [strongSelf.tableView reloadData];
            }];
        });
    }];
}

#pragma mark - Filter（对齐 Android {@link TransactionRecordActivity#showTimeFilterDialog}）

- (void)onFilterTap {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLang(@"筛选") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"自定义时间范围") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        [weakSelf beginCustomTimeFilter];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"清除筛选") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        weakSelf.filterStartApi = nil;
        weakSelf.filterEndApi = nil;
        weakSelf.hasMore = YES;
        [weakSelf loadPage:1 replace:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.navigationBar.rightView;
    sheet.popoverPresentationController.sourceRect = self.navigationBar.rightView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)beginCustomTimeFilter {
    __weak typeof(self) weakSelf = self;
    [self presentPickerWithTitle:LLang(@"选择开始时间") initial:[NSDate date] completion:^(NSDate *d) {
        NSDate *start = d;
        [weakSelf presentPickerWithTitle:LLang(@"选择结束时间") initial:start completion:^(NSDate *end) {
            if ([start compare:end] == NSOrderedDescending) {
                [WKAlertUtil showMsg:LLang(@"开始时间不能晚于结束时间")];
                return;
            }
            weakSelf.filterStartApi = WKTxApiDateString(start);
            weakSelf.filterEndApi = WKTxApiDateString(end);
            [weakSelf refreshData];
        }];
    }];
}

- (void)presentPickerWithTitle:(NSString *)title initial:(NSDate *)initial completion:(void (^)(NSDate *date))completion {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:@"\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    UIDatePicker *dp = [[UIDatePicker alloc] init];
    dp.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.4, *)) {
        dp.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    dp.datePickerMode = UIDatePickerModeDateAndTime;
    dp.minuteInterval = 1;
    dp.date = initial ?: [NSDate date];
    [ac.view addSubview:dp];
    __weak UIAlertController *weakAc = ac;
    [NSLayoutConstraint activateConstraints:@[
        [dp.centerXAnchor constraintEqualToAnchor:ac.view.centerXAnchor],
        [dp.topAnchor constraintEqualToAnchor:ac.view.topAnchor constant:52],
        [dp.heightAnchor constraintEqualToConstant:180],
    ]];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        if (completion) {
            completion(dp.date);
        }
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:^{
        (void)weakAc;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"TransactionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.numberOfLines = 0;

        UILabel *amountLbl = [[UILabel alloc] init];
        amountLbl.tag = 100;
        amountLbl.font = [UIFont boldSystemFontOfSize:16];
        amountLbl.textAlignment = NSTextAlignmentRight;
        amountLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:amountLbl];
        [NSLayoutConstraint activateConstraints:@[
            [amountLbl.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [amountLbl.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
            [amountLbl.widthAnchor constraintLessThanOrEqualToConstant:110],
        ]];
    }

    NSDictionary *item = self.dataList[(NSUInteger)indexPath.row];
    NSString *remark = WKTxStr(item[@"remark"]);
    NSString *type = WKTxStr(item[@"type"]);
    double amount = [item[@"amount"] doubleValue];
    NSString *time = WKTxStr(item[@"created_at"]);
    if (!time.length) {
        time = WKTxStr(item[@"createdAt"]);
    }

    NSString *titleText = remark.length ? remark : [self typeLabelForType:type];
    NSString *detailBody = WKTxBuildDetail(item);
    NSString *detailText;
    if (detailBody.length && time.length) {
        detailText = [NSString stringWithFormat:@"%@\n%@", detailBody, time];
    } else if (time.length) {
        detailText = time;
    } else {
        detailText = detailBody;
    }

    cell.textLabel.text = titleText;
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    cell.detailTextLabel.text = detailText;
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    UILabel *amountLbl = [cell.contentView viewWithTag:100];
    if (amount >= 0) {
        amountLbl.text = [NSString stringWithFormat:@"+%.2f", amount];
        amountLbl.textColor = [UIColor colorWithRed:0.30 green:0.69 blue:0.31 alpha:1.0];
    } else {
        amountLbl.text = [NSString stringWithFormat:@"%.2f", amount];
        amountLbl.textColor = [UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1.0];
    }

    return cell;
}

/// 与 Android {@link TransactionRecordAdapter#typeLabel} 文案对齐。
- (NSString *)typeLabelForType:(NSString *)type {
    if ([type isEqualToString:@"recharge"]) {
        return LLang(@"充值");
    }
    if ([type isEqualToString:@"admin_recharge"]) {
        return LLang(@"管理员充值");
    }
    if ([type isEqualToString:@"admin_adjust"]) {
        return LLang(@"管理员调整");
    }
    if ([type isEqualToString:@"redpacket_send"]) {
        return LLang(@"红包发出");
    }
    if ([type isEqualToString:@"redpacket_receive"]) {
        return LLang(@"红包收入");
    }
    if ([type isEqualToString:@"transfer_out"]) {
        return LLang(@"转账发出");
    }
    if ([type isEqualToString:@"transfer_in"]) {
        return LLang(@"转账收入");
    }
    if ([type isEqualToString:@"refund"]) {
        return LLang(@"退款");
    }
    if ([type isEqualToString:@"withdrawal"]) {
        return LLang(@"提现");
    }
    if ([type isEqualToString:@"withdrawal_refund"]) {
        return LLang(@"提现退款");
    }
    if ([type isEqualToString:@"fee"]) {
        return LLang(@"手续费");
    }
    if ([type isEqualToString:@"transfer_refund"]) {
        return LLang(@"转账退回");
    }
    if ([type isEqualToString:@"redpacket_refund"]) {
        return LLang(@"红包退回");
    }
    return type ?: @"";
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.hasMore || self.loading || self.dataList.count == 0) {
        return;
    }
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat height = scrollView.bounds.size.height;
    if (contentHeight < height) {
        return;
    }
    if (offsetY <= 0) {
        return;
    }
    /// 接近底部再请求下一页（与 Android RecyclerView lastVisibleItem 逻辑类似）。
    if (offsetY > contentHeight - height - 120.0) {
        [self loadPage:self.currentPage + 1 replace:NO];
    }
}

@end
