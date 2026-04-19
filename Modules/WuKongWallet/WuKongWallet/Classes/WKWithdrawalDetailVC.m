#import "WKWithdrawalDetailVC.h"
#import "WKWalletAPI.h"
#import "WKWalletMaterialTheme.h"

@interface WKWithdrawalDetailVC ()

@property (nonatomic, copy) NSString *withdrawalNo;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *feeLabel;
@property (nonatomic, strong) UILabel *actualLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *remarkLabel;

@end

@implementation WKWithdrawalDetailVC

- (instancetype)initWithWithdrawalNo:(NSString *)withdrawalNo {
    self = [super init];
    if (self) {
        _withdrawalNo = [withdrawalNo copy] ?: @"";
    }
    return self;
}

+ (NSDictionary *)detailPayload:(NSDictionary *)root {
    NSDictionary *d = root[@"data"];
    if ([d isKindOfClass:[NSDictionary class]]) {
        return d;
    }
    return root;
}

+ (double)doubleVal:(NSDictionary *)d key:(NSString *)key {
    id v = d[key];
    if ([v isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)v doubleValue];
    }
    if ([v isKindOfClass:[NSString class]]) {
        return [(NSString *)v doubleValue];
    }
    return NAN;
}

+ (NSString *)formatUsdtAmount:(double)v {
    if (isnan(v) || v < 0) {
        return @"0";
    }
    NSString *s = [NSString stringWithFormat:@"%.6f", v];
    NSInteger dot = (NSInteger)[s rangeOfString:@"."].location;
    if (dot == NSNotFound) {
        return s;
    }
    NSInteger end = (NSInteger)s.length;
    while (end > dot + 1 && [s characterAtIndex:(NSUInteger)end - 1] == '0') {
        end--;
    }
    if (end > dot && [s characterAtIndex:(NSUInteger)end - 1] == '.') {
        end--;
    }
    return [s substringToIndex:(NSUInteger)end];
}

+ (NSInteger)resolveWithdrawalStatus:(NSDictionary *)r {
    id v = r[@"withdrawal_status"] ?: r[@"withdrawalStatus"] ?: r[@"status"];
    if ([v isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)v integerValue];
    }
    if ([v isKindOfClass:[NSString class]]) {
        return [(NSString *)v integerValue];
    }
    return 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"提现详情");
    self.navigationBar.style = WKNavigationBarStyleWhite;
    self.view.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];

    self.scroll = [[UIScrollView alloc] init];
    [self.view addSubview:self.scroll];

    self.amountLabel = [self bigAmountLabel];
    self.feeLabel = [self secondaryLabel];
    self.actualLabel = [self secondaryLabel];
    self.statusLabel = [self secondaryLabel];
    self.timeLabel = [self secondaryLabel];
    self.remarkLabel = [self secondaryLabel];
    self.remarkLabel.numberOfLines = 0;

    [self.scroll addSubview:self.amountLabel];
    [self.scroll addSubview:self.feeLabel];
    [self.scroll addSubview:self.actualLabel];
    [self.scroll addSubview:self.statusLabel];
    [self.scroll addSubview:self.timeLabel];
    [self.scroll addSubview:self.remarkLabel];

    self.feeLabel.hidden = YES;
    self.actualLabel.hidden = YES;
    self.remarkLabel.hidden = YES;

    if (self.withdrawalNo.length == 0) {
        [self showFailAndPop:LLang(@"单号无效")];
        return;
    }
    [self loadDetail];
}

- (UILabel *)bigAmountLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
    l.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 1;
    return l;
}

- (UILabel *)secondaryLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:15];
    l.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 0;
    return l;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = [self getNavBottom];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.scroll.frame = CGRectMake(0, top, w, h - top);
    CGFloat pad = 20;
    CGFloat y = 24;
    CGFloat iw = w - pad * 2;

    for (UILabel *lab in @[ self.amountLabel, self.feeLabel, self.actualLabel, self.statusLabel, self.timeLabel ]) {
        if (lab.hidden) {
            continue;
        }
        CGSize s = [lab sizeThatFits:CGSizeMake(iw, CGFLOAT_MAX)];
        lab.frame = CGRectMake(pad, y, iw, MAX(s.height, 22));
        y += CGRectGetHeight(lab.frame) + (lab == self.amountLabel ? 16 : 10);
    }
    if (!self.remarkLabel.hidden) {
        CGSize rs = [self.remarkLabel sizeThatFits:CGSizeMake(iw, CGFLOAT_MAX)];
        self.remarkLabel.frame = CGRectMake(pad, y, iw, MAX(rs.height, 20));
        y += CGRectGetHeight(self.remarkLabel.frame) + 16;
    } else {
        y += 8;
    }
    self.scroll.contentSize = CGSizeMake(w, y + 24);
}

- (void)loadDetail {
    [[WKWalletAPI shared] getWithdrawalDetailWithWithdrawalNo:self.withdrawalNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self showFailAndPop:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSDictionary *r = [[self class] detailPayload:result ?: @{}];
            NSString *no = r[@"withdrawal_no"] ?: r[@"withdrawalNo"];
            if (![no isKindOfClass:[NSString class]] || [(NSString *)no length] == 0) {
                [self showFailAndPop:LLang(@"无法解析提现详情")];
                return;
            }
            [self bindDetail:r];
        });
    }];
}

- (void)bindDetail:(NSDictionary *)r {
    double amt = [[self class] doubleVal:r key:@"amount"];
    self.amountLabel.text = [NSString stringWithFormat:@"%@ USDT", [[self class] formatUsdtAmount:amt]];

    double fee = [[self class] doubleVal:r key:@"fee"];
    if (!isnan(fee) && fee >= 0) {
        self.feeLabel.hidden = NO;
        self.feeLabel.text = [NSString stringWithFormat:LLang(@"手续费：%@ USDT"), [[self class] formatUsdtAmount:fee]];
    } else {
        self.feeLabel.hidden = YES;
    }

    double act = [[self class] doubleVal:r key:@"actual_amount"];
    if (isnan(act)) {
        act = [[self class] doubleVal:r key:@"actualAmount"];
    }
    if (isnan(act)) {
        act = [[self class] doubleVal:r key:@"total_freeze"];
    }
    if (!isnan(act) && act >= 0) {
        self.actualLabel.hidden = NO;
        self.actualLabel.text = [NSString stringWithFormat:LLang(@"到账金额：%@ USDT"), [[self class] formatUsdtAmount:act]];
    } else {
        self.actualLabel.hidden = YES;
    }

    NSInteger st = [[self class] resolveWithdrawalStatus:r];
    UIColor *pending = [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1];
    UIColor *ok = [UIColor colorWithRed:0.3 green:0.69 blue:0.31 alpha:1];
    UIColor *rej = [UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1];
    UIColor *def = [WKWalletMaterialTheme buyUsdtTextSecondary];
    switch (st) {
        case 0:
            self.statusLabel.text = LLang(@"审核中");
            self.statusLabel.textColor = pending;
            break;
        case 1:
            self.statusLabel.text = LLang(@"已通过");
            self.statusLabel.textColor = ok;
            break;
        case 2:
            self.statusLabel.text = LLang(@"已拒绝");
            self.statusLabel.textColor = rej;
            break;
        default: {
            NSString *tx = r[@"status_text"] ?: r[@"statusText"];
            if ([tx isKindOfClass:[NSString class]] && [(NSString *)tx length] > 0) {
                self.statusLabel.text = (NSString *)tx;
            } else {
                self.statusLabel.text = [NSString stringWithFormat:@"%ld", (long)st];
            }
            self.statusLabel.textColor = def;
            break;
        }
    }

    NSString *ca = r[@"created_at"] ?: r[@"createdAt"];
    self.timeLabel.text = ca.length ? ca : @"—";

    NSString *rm = r[@"admin_remark"] ?: r[@"adminRemark"];
    if (![rm isKindOfClass:[NSString class]] || ![(NSString *)rm length]) {
        rm = r[@"remark"];
    }
    if ([rm isKindOfClass:[NSString class]] && [(NSString *)rm length] > 0) {
        self.remarkLabel.hidden = NO;
        self.remarkLabel.text = (NSString *)rm;
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
