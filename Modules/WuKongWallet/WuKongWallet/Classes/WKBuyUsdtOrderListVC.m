#import "WKBuyUsdtOrderListVC.h"
#import "WKRechargeApplyDetailVC.h"
#import "WKWalletAPI.h"
#import "WKWalletMaterialTheme.h"
#import "WKWalletRechargeApplicationUtil.h"

static NSString *const kCellId = @"WKBuyUsdtOrderCell";

@interface WKBuyUsdtOrderCell : UITableViewCell
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *chevron;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UILabel *capTime;
@property (nonatomic, strong) UILabel *capQty;
@property (nonatomic, strong) UILabel *capCny;
@property (nonatomic, strong) UILabel *valTime;
@property (nonatomic, strong) UILabel *valQty;
@property (nonatomic, strong) UILabel *valCny;
@end

@implementation WKBuyUsdtOrderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.card = [[UIView alloc] init];
        self.card.backgroundColor = [WKWalletMaterialTheme buyUsdtCard];
        self.card.layer.cornerRadius = 12;
        self.card.layer.borderWidth = 0.5;
        self.card.layer.borderColor = [WKWalletMaterialTheme buyUsdtCardStroke].CGColor;
        [self.contentView addSubview:self.card];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = LLangC(@"买币 USDT-TRC20", [WKBuyUsdtOrderListVC class]);
        self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        self.titleLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
        [self.card addSubview:self.titleLabel];

        self.statusLabel = [[UILabel alloc] init];
        self.statusLabel.font = [UIFont systemFontOfSize:14];
        [self.card addSubview:self.statusLabel];

        self.chevron = [[UILabel alloc] init];
        self.chevron.text = @"›";
        self.chevron.font = [UIFont systemFontOfSize:18];
        self.chevron.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
        [self.card addSubview:self.chevron];

        self.divider = [[UIView alloc] init];
        self.divider.backgroundColor = [WKWalletMaterialTheme buyUsdtDivider];
        [self.card addSubview:self.divider];

        UIColor *cap = [UIColor colorWithRed:0.46 green:0.46 blue:0.46 alpha:1];
        self.capTime = [self caption:LLangC(@"时间", [WKBuyUsdtOrderListVC class]) color:cap];
        self.capQty = [self caption:LLangC(@"数量", [WKBuyUsdtOrderListVC class]) color:cap];
        self.capCny = [self caption:LLangC(@"交易总额(CNY)", [WKBuyUsdtOrderListVC class]) color:cap];
        self.capQty.textAlignment = NSTextAlignmentCenter;
        self.capCny.textAlignment = NSTextAlignmentRight;

        self.valTime = [self valueLabel];
        self.valQty = [self valueLabel];
        self.valQty.textAlignment = NSTextAlignmentCenter;
        self.valCny = [self valueLabel];
        self.valCny.textAlignment = NSTextAlignmentRight;
    }
    return self;
}

- (UILabel *)caption:(NSString *)t color:(UIColor *)c {
    UILabel *l = [[UILabel alloc] init];
    l.text = t;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = c;
    [self.card addSubview:l];
    return l;
}

- (UILabel *)valueLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:14];
    l.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    [self.card addSubview:l];
    return l;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat cardW = w - 28;
    self.card.frame = CGRectMake(14, 6, cardW, self.contentView.bounds.size.height - 12);

    CGFloat iw = cardW - 28;
    self.titleLabel.frame = CGRectMake(14, 12, iw - 100, 22);
    self.statusLabel.frame = CGRectMake(cardW - 14 - 120, 12, 100, 22);
    self.chevron.frame = CGRectMake(cardW - 28, 12, 18, 22);
    self.divider.frame = CGRectMake(14, 44, iw, 1);

    CGFloat colW = iw / 3.0;
    self.capTime.frame = CGRectMake(14, 52, colW, 16);
    self.capQty.frame = CGRectMake(14 + colW, 52, colW, 16);
    self.capCny.frame = CGRectMake(14 + colW * 2, 52, colW, 16);
    self.valTime.frame = CGRectMake(14, 72, colW, 20);
    self.valQty.frame = CGRectMake(14 + colW, 72, colW, 20);
    self.valCny.frame = CGRectMake(14 + colW * 2, 72, colW, 20);
}

@end

@interface WKBuyUsdtOrderListVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshCtl;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<NSDictionary *> *orders;
/// 与 Android 买币系页面底部悬浮「联系客服」一致（{@code buy_usdt_cs_fab_*} / {@code buy_usdt_scroll_bottom_pad}）。
@property (nonatomic, strong) UIButton *contactFab;

@end

@implementation WKBuyUsdtOrderListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"订单");
    self.navigationBar.style = WKNavigationBarStyleWhite;
    self.view.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];

    self.orders = @[];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];
    self.tableView.rowHeight = 130;
    [self.tableView registerClass:[WKBuyUsdtOrderCell class] forCellReuseIdentifier:kCellId];
    [self.view addSubview:self.tableView];

    self.refreshCtl = [[UIRefreshControl alloc] init];
    [self.refreshCtl addTarget:self action:@selector(loadOrders) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshCtl;

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = LLang(@"暂无订单");
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    self.contactFab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.contactFab.layer.cornerRadius = 18;
    self.contactFab.layer.borderWidth = 1;
    self.contactFab.layer.borderColor = [WKWalletMaterialTheme buyUsdtCsFabStroke].CGColor;
    self.contactFab.backgroundColor = [WKWalletMaterialTheme buyUsdtCsFabGlass];
    [self.contactFab setTitle:LLang(@"联系客服") forState:UIControlStateNormal];
    [self.contactFab setTitleColor:[WKWalletMaterialTheme buyUsdtCsFabText] forState:UIControlStateNormal];
    self.contactFab.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.contactFab.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [self.contactFab addTarget:self action:@selector(onContactCs) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.contactFab];

    [self loadOrders];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = [self getNavBottom];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.tableView.frame = CGRectMake(0, top, w, h - top);
    self.emptyLabel.frame = CGRectMake(24, top + 120, w - 48, 40);

    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    const CGFloat kFabH = 40.0f;
    const CGFloat kFabBottom = 12.0f;
    CGFloat insetBottom = kFabH + kFabBottom + safeBottom;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, insetBottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;

    const CGFloat fabW = 104.0f;
    self.contactFab.frame = CGRectMake((w - fabW) / 2.0, h - safeBottom - kFabBottom - kFabH, fabW, kFabH);
    [self.view bringSubviewToFront:self.contactFab];
}

- (void)onContactCs {
    UIViewController *host = self.presentingViewController ?: self;
    [[WKApp shared] invoke:@"show_customer_service" param:host];
}

- (void)loadOrders {
    [[WKWalletAPI shared] getRechargeApplicationsPage:1 size:50 callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshCtl endRefreshing];
            if (error) {
                if (self.orders.count == 0) {
                    self.emptyLabel.hidden = NO;
                    self.tableView.hidden = YES;
                }
                return;
            }
            NSArray *raw = [WKWalletRechargeApplicationUtil rechargeApplicationListFromAPIResult:result];
            self.orders = [WKWalletRechargeApplicationUtil sortedByCreatedDesc:raw];
            BOOL empty = self.orders.count == 0;
            self.emptyLabel.hidden = !empty;
            self.tableView.hidden = empty;
            [self.tableView reloadData];
        });
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)section;
    return (NSInteger)self.orders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKBuyUsdtOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    NSDictionary *r = self.orders[(NSUInteger)indexPath.row];

    cell.valTime.text = [WKWalletRechargeApplicationUtil formatTimeForDisplay:r[@"created_at"] ?: r[@"createdAt"]];
    cell.valQty.text = [WKWalletRechargeApplicationUtil formatOrderQty:r];
    cell.valCny.text = [WKWalletRechargeApplicationUtil formatOrderCnyTotal:r];

    NSInteger st = [WKWalletRechargeApplicationUtil resolveAuditStatus:r];
    UIColor *processing = [UIColor colorWithRed:0.9 green:0.32 blue:0.0 alpha:1];
    UIColor *ok = [UIColor colorWithRed:0.3 green:0.69 blue:0.31 alpha:1];
    UIColor *rej = [UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1];
    UIColor *def = [WKWalletMaterialTheme buyUsdtTextSecondary];
    switch (st) {
        case 0:
            cell.statusLabel.text = LLang(@"处理中");
            cell.statusLabel.textColor = processing;
            break;
        case 1:
            cell.statusLabel.text = LLang(@"已通过");
            cell.statusLabel.textColor = ok;
            break;
        case 2:
            cell.statusLabel.text = LLang(@"已拒绝");
            cell.statusLabel.textColor = rej;
            break;
        default:
            cell.statusLabel.text = [NSString stringWithFormat:@"%ld", (long)st];
            cell.statusLabel.textColor = def;
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSDictionary *r = self.orders[(NSUInteger)indexPath.row];
    NSString *no = [WKWalletRechargeApplicationUtil applicationNo:r];
    if (no.length == 0) {
        return;
    }
    WKRechargeApplyDetailVC *vc = [[WKRechargeApplyDetailVC alloc] initWithApplicationNo:no];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
