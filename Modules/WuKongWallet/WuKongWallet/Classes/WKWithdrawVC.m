#import "WKWithdrawVC.h"
#import "WKWithdrawalOrderListVC.h"
#import "WKWalletAPI.h"
#import "WKWalletChannelUtil.h"
#import "WKWalletMaterialTheme.h"
#import <WuKongBase/WKScanVC.h>
#import <WuKongBase/WuKongBase.h>

@interface WKWithdrawVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSArray<NSDictionary *> *chains;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) double availableUsdt;

@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *chainCard;
@property (nonatomic, strong) UIControl *chainRow;
@property (nonatomic, strong) UILabel *chainIcon;
@property (nonatomic, strong) UILabel *chainNameLabel;
@property (nonatomic, strong) UILabel *chainChevron;

@property (nonatomic, strong) UILabel *addressSectionLabel;
@property (nonatomic, strong) UIView *addressCard;
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UIButton *pasteBtn;
@property (nonatomic, strong) UIButton *scanBtn;

@property (nonatomic, strong) UILabel *amountSectionLabel;
@property (nonatomic, strong) UIView *amountCard;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UIButton *withdrawAllBtn;
@property (nonatomic, strong) UILabel *balanceLabel;

@property (nonatomic, strong) UIView *feeCard;
@property (nonatomic, strong) UILabel *feeTitleLabel;
@property (nonatomic, strong) UIButton *feeHelpBtn;
@property (nonatomic, strong) UILabel *serviceFeeLabel;
@property (nonatomic, strong) UIView *feeDivider;
@property (nonatomic, strong) UILabel *arrivalTitleLabel;
@property (nonatomic, strong) UILabel *arrivalLabel;

@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UIButton *contactFab;

@property (nonatomic, strong) NSTimer *feeDebounceTimer;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, strong) UIToolbar *numberInputToolbar;

@end

@implementation WKWithdrawVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"提币");
    self.navigationBar.style = WKNavigationBarStyleWhite;
    self.view.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];
    self.selectedIndex = 0;
    self.availableUsdt = 0;

    /// 与 Android {@code WithdrawActivity} {@code R.menu.menu_withdraw} {@code withdraw_menu_orders} 一致：打开 {@link WithdrawalOrderListActivity}。
    UIButton *ordersBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [ordersBtn setTitle:LLang(@"订单") forState:UIControlStateNormal];
    ordersBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [ordersBtn setTitleColor:[WKWalletMaterialTheme buyUsdtPrimary] forState:UIControlStateNormal];
    [ordersBtn addTarget:self action:@selector(onWithdrawOrdersNav) forControlEvents:UIControlEventTouchUpInside];
    [ordersBtn sizeToFit];
    CGFloat ow = MAX(CGRectGetWidth(ordersBtn.bounds) + 16.0, 44.0);
    ordersBtn.frame = CGRectMake(0, 0, ow, 44.0);
    self.rightView = ordersBtn;

    self.scroll = [[UIScrollView alloc] init];
    self.scroll.alwaysBounceVertical = YES;
    self.scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scroll];

    [self buildChainCard];
    [self buildAddressSection];
    [self buildAmountSection];
    [self buildFeeCard];
    [self buildConfirm];
    [self buildFab];

    [self reloadData];
    [self updateConfirmEnabled];

    self.addressField.delegate = self;
    self.amountField.delegate = self;
    self.addressField.returnKeyType = UIReturnKeyDone;
    self.amountField.inputAccessoryView = self.numberInputToolbar;
    [self setupDismissKeyboardGesture];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    self.view.transform = CGAffineTransformIdentity;
}

- (void)styleCard:(UIView *)v {
    v.backgroundColor = [WKWalletMaterialTheme buyUsdtCard];
    v.layer.cornerRadius = 12;
    v.layer.borderWidth = 0.5;
    v.layer.borderColor = [WKWalletMaterialTheme buyUsdtCardStroke].CGColor;
    v.layer.shadowColor = UIColor.blackColor.CGColor;
    v.layer.shadowOpacity = 0.05;
    v.layer.shadowOffset = CGSizeMake(0, 1);
    v.layer.shadowRadius = 2;
}

- (void)buildChainCard {
    self.chainCard = [[UIView alloc] init];
    [self styleCard:self.chainCard];
    [self.scroll addSubview:self.chainCard];

    self.chainRow = [[UIControl alloc] init];
    [self.chainRow addTarget:self action:@selector(onPickChain) forControlEvents:UIControlEventTouchUpInside];
    [self.chainCard addSubview:self.chainRow];

    self.chainIcon = [[UILabel alloc] init];
    self.chainIcon.text = @"₮";
    self.chainIcon.textAlignment = NSTextAlignmentCenter;
    self.chainIcon.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.chainIcon.textColor = UIColor.whiteColor;
    self.chainIcon.backgroundColor = [WKWalletMaterialTheme rechargeSheetUsdtGreen];
    self.chainIcon.layer.cornerRadius = 18;
    self.chainIcon.layer.masksToBounds = YES;
    [self.chainRow addSubview:self.chainIcon];

    self.chainNameLabel = [[UILabel alloc] init];
    self.chainNameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.chainNameLabel.textColor = [WKWalletMaterialTheme buyUsdtPrimary];
    self.chainNameLabel.textAlignment = NSTextAlignmentRight;
    [self.chainRow addSubview:self.chainNameLabel];

    self.chainChevron = [[UILabel alloc] init];
    self.chainChevron.text = @"›";
    self.chainChevron.font = [UIFont systemFontOfSize:18];
    self.chainChevron.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    [self.chainRow addSubview:self.chainChevron];
}

- (UILabel *)secondarySectionLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    return l;
}

- (void)buildAddressSection {
    self.addressSectionLabel = [self secondarySectionLabel:LLang(@"提币地址")];
    [self.scroll addSubview:self.addressSectionLabel];

    self.addressCard = [[UIView alloc] init];
    [self styleCard:self.addressCard];
    [self.scroll addSubview:self.addressCard];

    self.addressField = [[UITextField alloc] init];
    self.addressField.placeholder = LLang(@"长按粘贴或输入提币地址");
    self.addressField.font = [UIFont systemFontOfSize:15];
    self.addressField.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    self.addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.addressField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.addressField addTarget:self action:@selector(onAddressEdit) forControlEvents:UIControlEventEditingChanged];
    [self.addressCard addSubview:self.addressField];

    self.pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pasteBtn setTitle:LLang(@"粘贴") forState:UIControlStateNormal];
    [self.pasteBtn setTitleColor:[WKWalletMaterialTheme buyUsdtPrimary] forState:UIControlStateNormal];
    self.pasteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.pasteBtn addTarget:self action:@selector(onPaste) forControlEvents:UIControlEventTouchUpInside];
    [self.addressCard addSubview:self.pasteBtn];

    self.scanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.scanBtn setTitle:LLang(@"扫") forState:UIControlStateNormal];
    [self.scanBtn setTitleColor:[WKWalletMaterialTheme buyUsdtPrimary] forState:UIControlStateNormal];
    self.scanBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self.scanBtn addTarget:self action:@selector(onScan) forControlEvents:UIControlEventTouchUpInside];
    [self.addressCard addSubview:self.scanBtn];
}

- (void)buildAmountSection {
    self.amountSectionLabel = [self secondarySectionLabel:LLang(@"提币数量")];
    [self.scroll addSubview:self.amountSectionLabel];

    self.amountCard = [[UIView alloc] init];
    [self styleCard:self.amountCard];
    [self.scroll addSubview:self.amountCard];

    self.amountField = [[UITextField alloc] init];
    self.amountField.placeholder = @"0.00";
    self.amountField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.amountField.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    [self.amountField addTarget:self action:@selector(onAmountChanged) forControlEvents:UIControlEventEditingChanged];
    [self.amountCard addSubview:self.amountField];

    self.withdrawAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.withdrawAllBtn setTitle:LLang(@"全部") forState:UIControlStateNormal];
    [self.withdrawAllBtn setTitleColor:[WKWalletMaterialTheme buyUsdtPrimary] forState:UIControlStateNormal];
    self.withdrawAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.withdrawAllBtn addTarget:self action:@selector(onWithdrawAll) forControlEvents:UIControlEventTouchUpInside];
    [self.amountCard addSubview:self.withdrawAllBtn];

    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.font = [UIFont systemFontOfSize:13];
    self.balanceLabel.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    [self.amountCard addSubview:self.balanceLabel];
}

- (void)buildFeeCard {
    self.feeCard = [[UIView alloc] init];
    [self styleCard:self.feeCard];
    [self.scroll addSubview:self.feeCard];

    self.feeTitleLabel = [[UILabel alloc] init];
    self.feeTitleLabel.text = LLang(@"手续费");
    self.feeTitleLabel.font = [UIFont systemFontOfSize:14];
    self.feeTitleLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    [self.feeCard addSubview:self.feeTitleLabel];

    self.feeHelpBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.feeHelpBtn setTitle:@"?" forState:UIControlStateNormal];
    [self.feeHelpBtn setTitleColor:[WKWalletMaterialTheme buyUsdtTextSecondary] forState:UIControlStateNormal];
    self.feeHelpBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.feeHelpBtn addTarget:self action:@selector(onFeeHelp) forControlEvents:UIControlEventTouchUpInside];
    [self.feeCard addSubview:self.feeHelpBtn];

    self.serviceFeeLabel = [[UILabel alloc] init];
    self.serviceFeeLabel.font = [UIFont systemFontOfSize:14];
    self.serviceFeeLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    self.serviceFeeLabel.textAlignment = NSTextAlignmentRight;
    self.serviceFeeLabel.text = @"—";
    [self.feeCard addSubview:self.serviceFeeLabel];

    self.feeDivider = [[UIView alloc] init];
    self.feeDivider.backgroundColor = [WKWalletMaterialTheme buyUsdtDivider];
    [self.feeCard addSubview:self.feeDivider];

    self.arrivalTitleLabel = [[UILabel alloc] init];
    self.arrivalTitleLabel.text = LLang(@"到账数量");
    self.arrivalTitleLabel.font = [UIFont systemFontOfSize:14];
    self.arrivalTitleLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    [self.feeCard addSubview:self.arrivalTitleLabel];

    self.arrivalLabel = [[UILabel alloc] init];
    self.arrivalLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.arrivalLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    self.arrivalLabel.textAlignment = NSTextAlignmentRight;
    self.arrivalLabel.text = @"—";
    [self.feeCard addSubview:self.arrivalLabel];
}

- (void)buildConfirm {
    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmBtn setTitle:LLang(@"确认提币") forState:UIControlStateNormal];
    [self.confirmBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.confirmBtn.backgroundColor = [WKWalletMaterialTheme buyUsdtConfirmBtnTint];
    self.confirmBtn.layer.cornerRadius = 12;
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.confirmBtn addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmBtn];
}

- (void)buildFab {
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = [self getNavBottom];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat pad = 16;
    CGFloat inner = w - pad * 2;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat bottomBar = 56 + safeBottom;

    self.scroll.frame = CGRectMake(0, top, w, h - top - bottomBar);

    CGFloat y = 12;
    self.chainCard.frame = CGRectMake(pad, y, inner, 56);
    self.chainRow.frame = self.chainCard.bounds;
    self.chainIcon.frame = CGRectMake(14, (56 - 36) / 2.0, 36, 36);
    self.chainChevron.frame = CGRectMake(inner - 22, 18, 18, 22);
    self.chainNameLabel.frame = CGRectMake(60, 0, inner - 90, 56);
    y += 64;

    self.addressSectionLabel.frame = CGRectMake(pad + 4, y, inner - 8, 18);
    y += 24;
    self.addressCard.frame = CGRectMake(pad, y, inner, 52);
    self.addressField.frame = CGRectMake(14, 0, inner - 100, 52);
    self.pasteBtn.frame = CGRectMake(inner - 88, 8, 44, 36);
    self.scanBtn.frame = CGRectMake(inner - 44, 8, 40, 36);
    y += 60;

    self.amountSectionLabel.frame = CGRectMake(pad + 4, y, inner - 8, 18);
    y += 24;
    self.amountCard.frame = CGRectMake(pad, y, inner, 88);
    self.amountField.frame = CGRectMake(14, 10, inner - 70, 36);
    self.withdrawAllBtn.frame = CGRectMake(inner - 56, 12, 48, 32);
    self.balanceLabel.frame = CGRectMake(14, 52, inner - 28, 20);
    y += 96;

    self.feeCard.frame = CGRectMake(pad, y, inner, 100);
    self.feeTitleLabel.frame = CGRectMake(14, 14, 100, 22);
    self.feeHelpBtn.frame = CGRectMake(78, 10, 32, 32);
    self.serviceFeeLabel.frame = CGRectMake(inner / 2.0, 14, inner / 2.0 - 14, 22);
    self.feeDivider.frame = CGRectMake(14, 48, inner - 28, 0.5);
    self.arrivalTitleLabel.frame = CGRectMake(14, 58, inner / 2.0 - 14, 22);
    self.arrivalLabel.frame = CGRectMake(inner / 2.0, 58, inner / 2.0 - 14, 22);
    y += 108;

    self.scroll.contentSize = CGSizeMake(w, y + 100);

    self.confirmBtn.frame = CGRectMake(pad, h - bottomBar + 6, inner, 48);
    CGFloat fabW = 104;
    self.contactFab.frame = CGRectMake((w - fabW) / 2.0, h - bottomBar - 52, fabW, 40);
}

- (nullable NSDictionary *)currentChain {
    if (self.chains.count == 0) {
        return nil;
    }
    NSInteger idx = MAX(0, MIN(self.selectedIndex, (NSInteger)self.chains.count - 1));
    return self.chains[(NSUInteger)idx];
}

- (void)reloadData {
    [[WKWalletAPI shared] getBalanceWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && result) {
                NSDictionary *data = [result[@"data"] isKindOfClass:[NSDictionary class]] ? result[@"data"] : result;
                double avail = NAN;
                id ua = data[@"usdt_available"] ?: data[@"available_usdt"];
                id ub = data[@"usdt_balance"];
                if ([ua respondsToSelector:@selector(doubleValue)]) {
                    avail = [ua doubleValue];
                } else if ([ub respondsToSelector:@selector(doubleValue)]) {
                    avail = [ub doubleValue];
                } else {
                    avail = [data[@"balance"] doubleValue];
                }
                if (!isnan(avail)) {
                    self.availableUsdt = avail;
                }
            }
            [self updateBalanceLabel];
        });
    }];

    [[WKWalletAPI shared] getRechargeChannelsWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.chainNameLabel.text = LLang(@"加载失败");
                return;
            }
            NSArray *raw = [WKWalletChannelUtil channelArrayFromAPIResult:result];
            self.chains = [WKWalletChannelUtil channelsFilteredForWithdraw:raw];
            if (self.chains.count == 0) {
                self.chainNameLabel.text = LLang(@"暂无链上渠道");
            } else {
                self.selectedIndex = [self indexOfPreferredTrcChain:self.chains];
                [self applyChainTitle];
                [self requestFeeConfig];
                [self updateConfirmEnabled];
            }
        });
    }];
}

- (void)updateBalanceLabel {
    self.balanceLabel.text = [NSString stringWithFormat:LLang(@"可提余额  %.6f  USDT"), self.availableUsdt];
}

- (NSInteger)indexOfPreferredTrcChain:(NSArray<NSDictionary *> *)list {
    NSUInteger idx = 0;
    for (NSDictionary *ch in list) {
        NSString *blob = [[NSString stringWithFormat:@"%@ %@ %@",
                             [WKWalletChannelUtil channelDisplayName:ch],
                             ch[@"type"] ?: @"", ch[@"name"] ?: @""] uppercaseString];
        if ([blob containsString:@"TRC"]) {
            return (NSInteger)idx;
        }
        idx++;
    }
    return 0;
}

- (void)applyChainTitle {
    NSDictionary *ch = [self currentChain];
    NSString *t = ch ? [WKWalletChannelUtil channelDisplayName:ch] : @"";
    self.chainNameLabel.text = t.length ? t : @"—";
}

- (void)requestFeeConfig {
    NSDictionary *ch = [self currentChain];
    long long cid = ch ? [WKWalletChannelUtil channelId:ch] : 0;
    [[WKWalletAPI shared] getWithdrawalFeeConfigWithChannelId:cid callback:^(__unused NSDictionary *result, __unused NSError *error) {
    }];
}

- (void)onPickChain {
    if (self.chains.count == 0) {
        [self reloadData];
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:LLang(@"选择网络") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self.chains enumerateObjectsUsingBlock:^(NSDictionary *ch, NSUInteger idx, BOOL *stop) {
        [ac addAction:[UIAlertAction actionWithTitle:[WKWalletChannelUtil channelDisplayName:ch] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            self.selectedIndex = (NSInteger)idx;
            [self applyChainTitle];
            [self requestFeeConfig];
            [self scheduleFeePreview];
        }]];
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onPaste {
    NSString *s = UIPasteboard.generalPasteboard.string;
    if (s.length) {
        self.addressField.text = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (void)onWithdrawAll {
    if (self.availableUsdt > 0) {
        self.amountField.text = [NSString stringWithFormat:@"%.6f", self.availableUsdt];
        [self onAmountChanged];
    }
}

- (void)onScan {
    WKScanVC *vc = [WKScanVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onFeeHelp {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:LLang(@"手续费说明") message:LLang(@"手续费与到账数量由服务端根据当前网络与金额实时计算，以下为预览结果，以实际成交为准。") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"好的") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)onContactCs {
    UIViewController *host = self.presentingViewController ?: self;
    [[WKApp shared] invoke:@"show_customer_service" param:host];
}

- (void)onAddressEdit {
    [self updateConfirmEnabled];
}

- (void)onAmountChanged {
    [self scheduleFeePreview];
    [self updateConfirmEnabled];
}

- (void)setupDismissKeyboardGesture {
    self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDismissKeyboard)];
    self.dismissKeyboardTap.cancelsTouchesInView = NO;
    self.dismissKeyboardTap.delegate = self;
    [self.view addGestureRecognizer:self.dismissKeyboardTap];
}

- (UIToolbar *)numberInputToolbar {
    if (_numberInputToolbar) {
        return _numberInputToolbar;
    }
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                              style:UIBarButtonItemStyleDone
                                                             target:self
                                                             action:@selector(onTapDismissKeyboard)];
    toolbar.items = @[flex, done];
    _numberInputToolbar = toolbar;
    return _numberInputToolbar;
}

- (void)onTapDismissKeyboard {
    [self.view endEditing:YES];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    if (![info isKindOfClass:[NSDictionary class]]) {
        return;
    }
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    CGRect confirmFrame = [self.view convertRect:self.confirmBtn.frame fromView:self.confirmBtn.superview];
    CGFloat overlap = CGRectGetMaxY(confirmFrame) + 12.0f - kbFrame.origin.y;
    CGFloat targetOffset = MAX(0, overlap);
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    NSUInteger options = ((NSUInteger)curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration > 0 ? duration : 0.25
                          delay:0
                        options:options
                     animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -targetOffset);
    } completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = touch.view;
    while (view && view != self.view) {
        if ([view isKindOfClass:[UITextField class]] ||
            [view isKindOfClass:[UITextView class]] ||
            [view isKindOfClass:[UIControl class]]) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)scheduleFeePreview {
    [self.feeDebounceTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.feeDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 repeats:NO block:^(__unused NSTimer *t) {
        [weakSelf runFeePreview];
    }];
}

- (void)updateConfirmEnabled {
    NSString *addr = [self.addressField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *amt = [[self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    double v = [amt doubleValue];
    BOOL ok = addr.length > 0 && v > 0 && !isnan(v) && [self currentChain] != nil;
    self.confirmBtn.enabled = ok;
    self.confirmBtn.alpha = ok ? 1.0 : 0.45;
}

- (void)runFeePreview {
    NSDictionary *ch = [self currentChain];
    if (!ch) {
        return;
    }
    NSString *amt = [[self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (amt.length == 0) {
        self.serviceFeeLabel.text = @"—";
        self.arrivalLabel.text = @"—";
        return;
    }
    long long cid = [WKWalletChannelUtil channelId:ch];
    [[WKWalletAPI shared] getWithdrawalFeePreviewWithAmount:amt channelId:cid callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.serviceFeeLabel.text = LLang(@"预览失败");
                self.arrivalLabel.text = @"—";
                return;
            }
            NSDictionary *d = result[@"data"];
            if (![d isKindOfClass:[NSDictionary class]]) {
                d = result;
            }
            id fee = d[@"fee"];
            id arrival = d[@"arrival_amount"] ?: d[@"actual_amount"];
            self.serviceFeeLabel.text = fee ? [NSString stringWithFormat:@"%@", fee] : @"—";
            self.arrivalLabel.text = arrival ? [NSString stringWithFormat:@"%@ USDT", arrival] : @"—";
        });
    }];
}

- (void)onSubmit {
    NSDictionary *ch = [self currentChain];
    if (!ch) {
        [self alert:LLang(@"未配置可提币链上渠道")];
        return;
    }
    NSString *addr = [self.addressField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (addr.length == 0) {
        [self alert:LLang(@"请填写提币地址")];
        return;
    }
    NSString *amtStr = [[self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    double amt = [amtStr doubleValue];
    if (amt <= 0 || isnan(amt)) {
        [self alert:LLang(@"请输入有效提币数量")];
        return;
    }

    UIAlertController *pwd = [UIAlertController alertControllerWithTitle:LLang(@"支付密码") message:LLang(@"请输入支付密码以提交提币申请") preferredStyle:UIAlertControllerStyleAlert];
    [pwd addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.secureTextEntry = YES;
        tf.placeholder = LLang(@"支付密码");
    }];
    __weak typeof(self) weakSelf = self;
    [pwd addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [pwd addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        NSString *pw = pwd.textFields.firstObject.text ?: @"";
        if (pw.length == 0) {
            [weakSelf alert:LLang(@"密码不能为空")];
            return;
        }
        long long cid = [WKWalletChannelUtil channelId:ch];
        NSMutableDictionary *body = [@{
            @"amount": @(amt),
            @"password": pw,
            @"address": addr
        } mutableCopy];
        if (cid > 0) {
            body[@"channel_id"] = @(cid);
        }
        weakSelf.confirmBtn.enabled = NO;
        [[WKWalletAPI shared] withdrawalApplyWithBody:body callback:^(NSDictionary *result, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.confirmBtn.enabled = YES;
                [weakSelf updateConfirmEnabled];
                if (error) {
                    [weakSelf alert:error.localizedDescription ?: LLang(@"网络错误")];
                    return;
                }
                NSDictionary *d = result;
                NSDictionary *inner = result[@"data"];
                if ([inner isKindOfClass:[NSDictionary class]]) {
                    d = inner;
                }
                NSInteger st = [d[@"status"] integerValue];
                NSString *msg = d[@"msg"] ?: d[@"message"];
                if (![msg isKindOfClass:[NSString class]]) {
                    msg = LLang(@"已提交");
                }
                if (st >= 400 && st < 600) {
                    [weakSelf alert:msg];
                    return;
                }
                /// 与 Android {@code WithdrawActivity#submitWithdraw} 成功分支一致：Toast → 打开提币订单列表 → 结束提币页。
                NSString *toast = LLang(@"提币申请已提交。相应 USDT 已进入冻结；审核拒绝或超时将退回可用余额，通过后完成扣款。");
                UIView *hudHost = weakSelf.navigationController.view ?: weakSelf.view;
                [hudHost showHUDWithHide:toast];

                WKWithdrawalOrderListVC *listVC = [[WKWithdrawalOrderListVC alloc] init];
                UINavigationController *nav = weakSelf.navigationController;
                if (nav) {
                    NSMutableArray<UIViewController *> *vcs = [nav.viewControllers mutableCopy];
                    NSUInteger idx = [vcs indexOfObject:weakSelf];
                    if (idx != NSNotFound) {
                        [vcs replaceObjectAtIndex:idx withObject:listVC];
                        [nav setViewControllers:vcs animated:YES];
                    } else {
                        [nav pushViewController:listVC animated:YES];
                    }
                }
            });
        }];
    }]];
    [self presentViewController:pwd animated:YES completion:nil];
}

- (void)onWithdrawOrdersNav {
    WKWithdrawalOrderListVC *vc = [[WKWithdrawalOrderListVC alloc] init];
    UINavigationController *nav = self.navigationController;
    if (nav) {
        [nav pushViewController:vc animated:YES];
    } else {
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)dealloc {
    [self.feeDebounceTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
