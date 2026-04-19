#import "WKRechargeApplyDetailVC.h"
#import "WKWalletAPI.h"
#import "WKWalletMaterialTheme.h"
#import "WKWalletRechargeApplicationUtil.h"

@interface WKRechargeApplyDetailVC ()

@property (nonatomic, copy) NSString *applicationNo;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UILabel *noLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *remarkLabel;

@end

@implementation WKRechargeApplyDetailVC

- (instancetype)initWithApplicationNo:(NSString *)applicationNo {
    self = [super init];
    if (self) {
        _applicationNo = [applicationNo copy] ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"充值详情");
    self.view.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];

    self.scroll = [[UIScrollView alloc] init];
    [self.view addSubview:self.scroll];

    self.noLabel = [self buildLabel:15 secondary:NO];
    self.amountLabel = [self buildLabel:20 secondary:NO];
    self.statusLabel = [self buildLabel:16 secondary:NO];
    self.timeLabel = [self buildLabel:14 secondary:YES];
    self.remarkLabel = [self buildLabel:14 secondary:YES];
    self.remarkLabel.numberOfLines = 0;

    [self.scroll addSubview:self.noLabel];
    [self.scroll addSubview:self.amountLabel];
    [self.scroll addSubview:self.statusLabel];
    [self.scroll addSubview:self.timeLabel];
    [self.scroll addSubview:self.remarkLabel];

    if (self.applicationNo.length == 0) {
        [self showFailAndPop:LLang(@"单号无效")];
        return;
    }
    self.noLabel.text = [NSString stringWithFormat:LLang(@"申请单号：%@"), self.applicationNo];
    [self fetchStartingPage:1 maxPages:10];
}

- (UILabel *)buildLabel:(CGFloat)size secondary:(BOOL)sec {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:size weight:sec ? UIFontWeightRegular : UIFontWeightMedium];
    l.textColor = sec ? [WKWalletMaterialTheme buyUsdtTextSecondary] : [WKWalletMaterialTheme buyUsdtTextPrimary];
    l.numberOfLines = sec ? 0 : 1;
    return l;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = [self getNavBottom];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.scroll.frame = CGRectMake(0, top, w, h - top);
    CGFloat pad = 20;
    CGFloat y = 16;
    CGFloat iw = w - pad * 2;
    for (UILabel *lab in @[ self.noLabel, self.amountLabel, self.statusLabel, self.timeLabel ]) {
        CGSize s = [lab sizeThatFits:CGSizeMake(iw, CGFLOAT_MAX)];
        lab.frame = CGRectMake(pad, y, iw, MAX(s.height, 22));
        y += CGRectGetHeight(lab.frame) + 12;
    }
    CGSize rs = [self.remarkLabel sizeThatFits:CGSizeMake(iw, CGFLOAT_MAX)];
    self.remarkLabel.frame = CGRectMake(pad, y, iw, MAX(rs.height, 20));
    y += CGRectGetHeight(self.remarkLabel.frame) + 24;
    self.scroll.contentSize = CGSizeMake(w, y);
}

- (void)fetchStartingPage:(int)page maxPages:(int)maxPages {
    if (page > maxPages) {
        [self showFailAndPop:LLang(@"未找到该订单")];
        return;
    }
    [[WKWalletAPI shared] getRechargeApplicationsPage:page size:50 callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self showFailAndPop:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSArray *list = [WKWalletRechargeApplicationUtil rechargeApplicationListFromAPIResult:result];
            for (NSDictionary *item in list) {
                if ([[WKWalletRechargeApplicationUtil applicationNo:item] isEqualToString:self.applicationNo]) {
                    [self bindRecord:item];
                    return;
                }
            }
            if (list.count == 0) {
                [self showFailAndPop:LLang(@"未找到该订单")];
                return;
            }
            [self fetchStartingPage:page + 1 maxPages:maxPages];
        });
    }];
}

- (void)bindRecord:(NSDictionary *)r {
    id au = r[@"amount_u"] ?: r[@"amountU"];
    double amountU = [au respondsToSelector:@selector(doubleValue)] ? [au doubleValue] : NAN;
    id am = r[@"amount"];
    double amount = [am respondsToSelector:@selector(doubleValue)] ? [am doubleValue] : NAN;

    if (!isnan(amountU) && amountU > 0) {
        self.amountLabel.text = [NSString stringWithFormat:LLang(@"金额：$%.2f"), amountU];
    } else if (!isnan(amount)) {
        self.amountLabel.text = [NSString stringWithFormat:LLang(@"金额：¥%.2f"), amount];
    } else {
        self.amountLabel.text = LLang(@"金额：—");
    }

    NSInteger st = [WKWalletRechargeApplicationUtil resolveAuditStatus:r];
    switch (st) {
        case 0:
            self.statusLabel.text = LLang(@"状态：待审核");
            self.statusLabel.textColor = [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1];
            break;
        case 1:
            self.statusLabel.text = LLang(@"状态：已通过");
            self.statusLabel.textColor = [UIColor colorWithRed:0.3 green:0.69 blue:0.31 alpha:1];
            break;
        case 2:
            self.statusLabel.text = LLang(@"状态：已拒绝");
            self.statusLabel.textColor = [UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1];
            break;
        default:
            self.statusLabel.text = [NSString stringWithFormat:LLang(@"状态：%ld"), (long)st];
            self.statusLabel.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
            break;
    }

    NSString *ca = r[@"created_at"] ?: r[@"createdAt"];
    self.timeLabel.text = ca.length ? [NSString stringWithFormat:LLang(@"时间：%@"), ca] : LLang(@"时间：—");

    NSString *rm = r[@"admin_remark"];
    if ([rm isKindOfClass:[NSString class]] && [(NSString *)rm length] > 0) {
        self.remarkLabel.text = [NSString stringWithFormat:LLang(@"备注：%@"), rm];
        self.remarkLabel.hidden = NO;
    } else {
        self.remarkLabel.hidden = YES;
    }
    [self.view setNeedsLayout];
}

- (void)showFailAndPop:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"好的") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *act) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
