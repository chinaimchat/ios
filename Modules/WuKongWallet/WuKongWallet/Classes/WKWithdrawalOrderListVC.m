#import "WKWithdrawalOrderListVC.h"
#import "WKWithdrawalDetailVC.h"
#import "WKWalletAPI.h"
#import "WKWalletMaterialTheme.h"
#import "WKWalletRechargeApplicationUtil.h"
#import "WKWalletWithdrawalListUtil.h"
#import <WuKongBase/WuKongBase.h>

static NSString *const kCellId = @"WKWithdrawalOrderCell";

@interface WKWithdrawalOrderCell : UITableViewCell
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *chevron;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UILabel *capTime;
@property (nonatomic, strong) UILabel *capQty;
@property (nonatomic, strong) UILabel *capFee;
@property (nonatomic, strong) UILabel *capActual;
@property (nonatomic, strong) UILabel *valTime;
@property (nonatomic, strong) UILabel *valQty;
@property (nonatomic, strong) UILabel *valFee;
@property (nonatomic, strong) UILabel *valActual;
@end

@implementation WKWithdrawalOrderCell

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
        self.titleLabel.text = LLangC(@"USDT 提币", [WKWithdrawalOrderListVC class]);
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
        self.capTime = [self caption:LLangC(@"时间", [WKWithdrawalOrderListVC class]) color:cap];
        self.capQty = [self caption:LLangC(@"数量(USDT)", [WKWithdrawalOrderListVC class]) color:cap];
        self.capFee = [self caption:LLangC(@"手续费(USDT)", [WKWithdrawalOrderListVC class]) color:cap];
        self.capActual = [self caption:LLangC(@"到账(USDT)", [WKWithdrawalOrderListVC class]) color:cap];
        self.capQty.textAlignment = NSTextAlignmentCenter;
        self.capFee.textAlignment = NSTextAlignmentCenter;
        self.capActual.textAlignment = NSTextAlignmentRight;

        self.valTime = [self valueLabel];
        self.valQty = [self valueLabel];
        self.valFee = [self valueLabel];
        self.valActual = [self valueLabel];
        self.valQty.textAlignment = NSTextAlignmentCenter;
        self.valFee.textAlignment = NSTextAlignmentCenter;
        self.valActual.textAlignment = NSTextAlignmentRight;
    }
    return self;
}

- (UILabel *)caption:(NSString *)t color:(UIColor *)c {
    UILabel *l = [[UILabel alloc] init];
    l.text = t;
    l.font = [UIFont systemFontOfSize:11];
    l.textColor = c;
    [self.card addSubview:l];
    return l;
}

- (UILabel *)valueLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:13];
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

    CGFloat w1 = floor(iw * (1.15 / 4.15));
    CGFloat w234 = floor((iw - w1) / 3.0);
    CGFloat x0 = 14;
    self.capTime.frame = CGRectMake(x0, 52, w1, 16);
    self.capQty.frame = CGRectMake(x0 + w1, 52, w234, 16);
    self.capFee.frame = CGRectMake(x0 + w1 + w234, 52, w234, 16);
    self.capActual.frame = CGRectMake(x0 + w1 + w234 * 2, 52, w234, 16);

    self.valTime.frame = CGRectMake(x0, 72, w1, 20);
    self.valQty.frame = CGRectMake(x0 + w1, 72, w234, 20);
    self.valFee.frame = CGRectMake(x0 + w1 + w234, 72, w234, 20);
    self.valActual.frame = CGRectMake(x0 + w1 + w234 * 2, 72, w234, 20);
}

@end

@interface WKWithdrawalOrderListVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshCtl;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<NSDictionary *> *orders;
/// 与 {@link WKBuyUsdtOrderListVC}、提币主界面底部「联系客服」一致。
@property (nonatomic, strong) UIButton *contactFab;

@end

@implementation WKWithdrawalOrderListVC

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
    self.tableView.rowHeight = 140;
    [self.tableView registerClass:[WKWithdrawalOrderCell class] forCellReuseIdentifier:kCellId];
    [self.view addSubview:self.tableView];

    self.refreshCtl = [[UIRefreshControl alloc] init];
    [self.refreshCtl addTarget:self action:@selector(loadOrders) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshCtl;

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = LLang(@"暂无提币订单");
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
    [[WKWalletAPI shared] getWithdrawalListPage:1 size:50 callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshCtl endRefreshing];
            if (error) {
                if (self.orders.count == 0) {
                    self.emptyLabel.hidden = NO;
                    self.tableView.hidden = YES;
                }
                [self.view showHUDWithHide:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSArray *raw = [WKWalletWithdrawalListUtil withdrawalListFromAPIResult:result];
            self.orders = [WKWalletWithdrawalListUtil sortedByCreatedDesc:raw];
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
    WKWithdrawalOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    NSDictionary *r = self.orders[(NSUInteger)indexPath.row];

    cell.valTime.text = [WKWalletRechargeApplicationUtil formatTimeForDisplay:r[@"created_at"] ?: r[@"createdAt"]];
    cell.valQty.text = [WKWalletWithdrawalListUtil formatAmount4:r key:@"amount"];
    cell.valFee.text = [WKWalletWithdrawalListUtil formatFeeCell:r];
    cell.valActual.text = [WKWalletWithdrawalListUtil formatAmount4:r key:@"actual_amount"];
    if ([cell.valActual.text isEqualToString:@"—"]) {
        cell.valActual.text = [WKWalletWithdrawalListUtil formatAmount4:r key:@"actualAmount"];
    }
    if ([cell.valActual.text isEqualToString:@"—"]) {
        cell.valActual.text = [WKWalletWithdrawalListUtil formatAmount4:r key:@"total_freeze"];
    }

    NSInteger st = [WKWalletWithdrawalListUtil resolveAuditStatus:r];
    UIColor *processing = [UIColor colorWithRed:0.9 green:0.32 blue:0.0 alpha:1];
    UIColor *ok = [UIColor colorWithRed:0.3 green:0.69 blue:0.31 alpha:1];
    UIColor *rej = [UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1];
    UIColor *def = [WKWalletMaterialTheme buyUsdtTextSecondary];
    switch (st) {
        case 0:
            cell.statusLabel.text = LLang(@"审核中");
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
        default: {
            id tx = r[@"status_text"] ?: r[@"statusText"];
            if ([tx isKindOfClass:[NSString class]] && [(NSString *)tx length] > 0) {
                cell.statusLabel.text = (NSString *)tx;
            } else {
                cell.statusLabel.text = [NSString stringWithFormat:@"%ld", (long)st];
            }
            cell.statusLabel.textColor = def;
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSDictionary *r = self.orders[(NSUInteger)indexPath.row];
    NSString *no = [WKWalletWithdrawalListUtil withdrawalNo:r];
    if (no.length == 0) {
        return;
    }
    WKWithdrawalDetailVC *vc = [[WKWithdrawalDetailVC alloc] initWithWithdrawalNo:no];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
