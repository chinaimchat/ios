#import "WKRechargeDepositSheetVC.h"
#import "WKRechargeFullVC.h"
#import "WKWalletBuyUsdtNavTransition.h"
#import "WKWalletAPI.h"
#import "WKWalletChannelUtil.h"
#import "WKWalletMaterialTheme.h"
#import "WKWalletQrImageLoader.h"
#import <Photos/Photos.h>
#import <WuKongBase/WuKongBase.h>

static const CGFloat kSheetQR = 128.0;
static const CGFloat kSheetHPad = 14.0;
static const CGFloat kPanelTopRatio = 0.20;

@interface WKRechargeDepositSheetVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *dimButton;
@property (nonatomic, strong) UIView *barBackgroundView;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *grabber;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *scrollContent;

@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *ordersBtn;

@property (nonatomic, strong) UIView *chainCard;
@property (nonatomic, strong) UIControl *chainRow;
@property (nonatomic, strong) UILabel *usdtBadge;
@property (nonatomic, strong) UILabel *chainNameLabel;
@property (nonatomic, strong) UILabel *chainChevron;

@property (nonatomic, strong) UIView *qrCard;
@property (nonatomic, strong) UIImageView *qrImageView;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UIControl *saveQrControl;
@property (nonatomic, strong) UIControl *addressCopyControl;

@property (nonatomic, strong) UIView *amountCard;
@property (nonatomic, strong) UILabel *amountTitleLabel;
@property (nonatomic, strong) UILabel *amountSymbolLabel;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UILabel *rangeLabel;
@property (nonatomic, strong) UIView *amountDivider;
@property (nonatomic, strong) UILabel *estimateLabel;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, strong) UIButton *openFullBtn;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UIButton *contactFab;

@property (nonatomic, copy) NSArray<NSDictionary *> *channels;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) NSInteger qrGeneration;
@property (nonatomic, copy) NSString *lastAddress;
@property (nonatomic, strong) UIImage *lastQrImage;
/// 避免从系统 Alert / ActionSheet 返回时再次执行入场动画，导致关闭/「完成」观感异常（对齐 Android BottomSheet 仅首次滑入）。
@property (nonatomic, assign) BOOL didRunEntranceAnimation;

@end

/// 对齐 Android {@link com.chat.wallet.entity.RechargeApplyResp#getResolvedCreditedAmount()}。
static double WKResolvedRechargeCreditedFromDict(NSDictionary *d) {
    if (![d isKindOfClass:[NSDictionary class]]) {
        return NAN;
    }
    id amt = d[@"amount"];
    double v = NAN;
    if ([amt isKindOfClass:[NSNumber class]]) {
        v = [(NSNumber *)amt doubleValue];
    } else if ([amt isKindOfClass:[NSString class]] && [(NSString *)amt length]) {
        v = [(NSString *)amt doubleValue];
    }
    if (!isnan(v) && !isinf(v)) {
        return v;
    }
    NSDictionary *data = d[@"data"];
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NAN;
    }
    id a2 = data[@"amount"] ?: data[@"credited_amount"];
    if ([a2 isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)a2 doubleValue];
    }
    if ([a2 isKindOfClass:[NSString class]] && [(NSString *)a2 length]) {
        return [(NSString *)a2 doubleValue];
    }
    return NAN;
}

@implementation WKRechargeDepositSheetVC

+ (void)presentFromViewController:(UIViewController *)host {
    WKRechargeDepositSheetVC *vc = [[WKRechargeDepositSheetVC alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [host presentViewController:vc animated:NO completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.selectedIndex = 0;
    self.channels = @[];

    self.dimButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.dimButton.backgroundColor = UIColor.blackColor;
    self.dimButton.alpha = 0;
    [self.dimButton addTarget:self action:@selector(onDimTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dimButton];

    self.panel = [[UIView alloc] init];
    self.panel.backgroundColor = [WKWalletMaterialTheme rechargeSheetPageBg];
    if (@available(iOS 11.0, *)) {
        self.panel.layer.cornerRadius = 16;
        self.panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        self.panel.layer.masksToBounds = YES;
    } else {
        self.panel.layer.cornerRadius = 16;
        self.panel.layer.masksToBounds = YES;
    }
    [self.view addSubview:self.panel];

    self.grabber = [[UIView alloc] init];
    self.grabber.backgroundColor = [UIColor colorWithWhite:0.78 alpha:1];
    self.grabber.layer.cornerRadius = 2.5;
    [self.panel addSubview:self.grabber];

    self.scroll = [[UIScrollView alloc] init];
    self.scroll.alwaysBounceVertical = YES;
    self.scroll.showsVerticalScrollIndicator = YES;
    /// 与 Android BottomSheet 内可点击区域一致：避免滚动手势延迟/取消子控件触摸，否则「保存二维码」「复制地址」等易表现为点不动。
    self.scroll.delaysContentTouches = NO;
    self.scroll.canCancelContentTouches = NO;
    [self.panel addSubview:self.scroll];

    /// DecimalPad 无「完成」键：点空白收起键盘；键盘遮挡时增加底部 inset 以便滚到「确认充值」。
    UITapGestureRecognizer *dismissKbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onScrollTapDismissKeyboard)];
    dismissKbTap.cancelsTouchesInView = NO;
    dismissKbTap.delegate = self;
    [self.scroll addGestureRecognizer:dismissKbTap];

    self.scrollContent = [[UIView alloc] init];
    [self.scroll addSubview:self.scrollContent];

    [self buildBar];
    [self buildChainCard];
    [self buildQrCard];
    [self buildAmountCard];
    [self buildFooterRow];

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

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf loadChannels];
    });
    [self.scrollContent sendSubviewToBack:self.barBackgroundView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    CGFloat H = self.view.bounds.size.height;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    self.dimButton.frame = self.view.bounds;

    CGFloat panelTop = H * kPanelTopRatio;
    CGFloat panelH = H - panelTop;
    self.panel.frame = CGRectMake(0, panelTop, W, panelH);

    self.grabber.frame = CGRectMake((W - 36) / 2.0, 8, 36, 5);

    CGFloat y = 20;
    CGFloat barH = 48;
    self.doneBtn.frame = CGRectMake(8, y, 72, barH);
    self.titleLabel.frame = CGRectMake(88, y, W - 176, barH);
    self.ordersBtn.frame = CGRectMake(W - 80, y, 72, barH);
    y += barH + 4;

    CGFloat innerW = W - kSheetHPad * 2;
    CGFloat cardX = kSheetHPad;

    CGFloat chainH = 52;
    self.barBackgroundView.frame = CGRectMake(0, 20, W, 48);
    self.chainCard.frame = CGRectMake(cardX, y, innerW, chainH);
    self.chainRow.frame = self.chainCard.bounds;
    self.usdtBadge.frame = CGRectMake(12, (chainH - 32) / 2.0, 32, 32);
    self.chainNameLabel.frame = CGRectMake(56, 0, innerW - 56 - 28, chainH);
    self.chainChevron.frame = CGRectMake(innerW - 24, (chainH - 20) / 2.0, 20, 20);
    y += chainH + 8;

    CGFloat qrInnerW = innerW - 24;
    CGFloat addrH = [self heightForAddress:self.addressLabel.text width:qrInnerW font:self.addressLabel.font];
    CGFloat qrCardH = 12 + kSheetQR + 10 + MAX(addrH, 40) + 10 + 44 + 12;
    self.qrCard.frame = CGRectMake(cardX, y, innerW, qrCardH);
    self.qrImageView.frame = CGRectMake((innerW - kSheetQR) / 2.0, 12, kSheetQR, kSheetQR);
    self.addressLabel.frame = CGRectMake(12, CGRectGetMaxY(self.qrImageView.frame) + 10, qrInnerW, MAX(addrH, 40));
    CGFloat btnY = CGRectGetMaxY(self.addressLabel.frame) + 10;
    CGFloat btnW = (qrInnerW - 12) / 2.0;
    self.saveQrControl.frame = CGRectMake(12, btnY, btnW, 44);
    self.addressCopyControl.frame = CGRectMake(12 + btnW + 12, btnY, btnW, 44);
    [self layoutChip:self.saveQrControl];
    [self layoutChip:self.addressCopyControl];
    y += qrCardH + 8;

    BOOL showAmount = !self.amountCard.hidden;
    if (showAmount) {
        CGFloat estH = 0;
        if (!self.estimateLabel.hidden && self.estimateLabel.text.length) {
            estH = [self heightForText:self.estimateLabel.text width:innerW - 24 font:self.estimateLabel.font] + 6;
        }
        CGFloat rangeH = self.rangeLabel.hidden ? 0 : 18;
        CGFloat amountCardH = 10 + 20 + 6 + 36 + (rangeH > 0 ? rangeH + 4 : 0) + 8 + 1 + (estH > 0 ? estH + 6 : 0) + 10 + 46 + 12;
        self.amountCard.frame = CGRectMake(cardX, y, innerW, amountCardH);
        self.amountTitleLabel.frame = CGRectMake(12, 10, innerW - 24, 20);
        self.amountSymbolLabel.frame = CGRectMake(12, CGRectGetMaxY(self.amountTitleLabel.frame) + 6, 24, 36);
        self.amountField.frame = CGRectMake(40, CGRectGetMaxY(self.amountTitleLabel.frame) + 4, innerW - 52, 36);
        self.rangeLabel.frame = CGRectMake(12, CGRectGetMaxY(self.amountField.frame) + 4, innerW - 24, rangeH);
        CGFloat divY = CGRectGetMaxY(self.rangeLabel.hidden ? self.amountField.frame : self.rangeLabel.frame) + 8;
        self.amountDivider.frame = CGRectMake(12, divY, innerW - 24, 1);
        self.estimateLabel.frame = CGRectMake(12, CGRectGetMaxY(self.amountDivider.frame) + 6, innerW - 24, estH);
        self.confirmBtn.frame = CGRectMake(12, amountCardH - 12 - 46, innerW - 24, 46);
        y += amountCardH + 8;
    }

    self.openFullBtn.frame = CGRectMake((W - 220) / 2.0, y, 220, 36);
    if (!self.openFullBtn.hidden) {
        y += 36 + 4;
    }

    CGFloat footH = [self heightForText:self.footerLabel.text width:W - 32 font:self.footerLabel.font];
    self.footerLabel.frame = CGRectMake(16, y, W - 32, footH);
    y += footH + 24 + safeBottom + 56;

    self.scroll.frame = CGRectMake(0, 0, W, panelH);
    self.scroll.contentSize = CGSizeMake(W, y);
    // scrollContent 默认 frame 为 CGRectZero 时，系统 hitTest 无法命中其子视图，导致「完成」「订单」等按钮点击无反应
    self.scrollContent.frame = CGRectMake(0, 0, W, y);

    CGFloat fabW = 100;
    CGFloat fabH = 40;
    self.contactFab.frame = CGRectMake((W - fabW) / 2.0, H - safeBottom - fabH - 12, fabW, fabH);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didRunEntranceAnimation) {
        return;
    }
    self.didRunEntranceAnimation = YES;
    CGFloat H = self.view.bounds.size.height;
    CGFloat panelTop = H * kPanelTopRatio;
    CGFloat slide = H - panelTop;
    self.panel.transform = CGAffineTransformMakeTranslation(0, slide);
    self.contactFab.transform = CGAffineTransformMakeTranslation(0, slide);
    self.contactFab.alpha = 0;
    self.dimButton.alpha = 0;
    [UIView animateWithDuration:0.36 delay:0 usingSpringWithDamping:0.94 initialSpringVelocity:0.55 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.dimButton.alpha = 0.45;
        self.panel.transform = CGAffineTransformIdentity;
        self.contactFab.transform = CGAffineTransformIdentity;
        self.contactFab.alpha = 1;
    } completion:nil];
}

- (CGFloat)heightForText:(NSString *)text width:(CGFloat)w font:(UIFont *)font {
    if (text.length == 0) {
        return 0;
    }
    CGSize s = [text boundingRectWithSize:CGSizeMake(w, CGFLOAT_MAX)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{ NSFontAttributeName: font }
                                   context:nil].size;
    return ceil(s.height);
}

- (CGFloat)heightForAddress:(NSString *)text width:(CGFloat)w font:(UIFont *)font {
    return [self heightForText:text width:w font:font];
}

#pragma mark - UI builders

- (void)applyCardChrome:(UIView *)card {
    card.backgroundColor = [WKWalletMaterialTheme rechargeSheetCard];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.5;
    card.layer.borderColor = [WKWalletMaterialTheme rechargeSheetCardStroke].CGColor;
    card.layer.shadowColor = UIColor.blackColor.CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 1);
    card.layer.shadowRadius = 3;
}

- (void)buildBar {
    self.barBackgroundView = [[UIView alloc] init];
    self.barBackgroundView.backgroundColor = [WKWalletMaterialTheme rechargeSheetBarBg];
    [self.scrollContent addSubview:self.barBackgroundView];

    self.doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.doneBtn setTitle:LLang(@"完成") forState:UIControlStateNormal];
    [self.doneBtn setTitleColor:[WKWalletMaterialTheme rechargeSheetActionBlue] forState:UIControlStateNormal];
    self.doneBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.doneBtn addTarget:self action:@selector(onDone) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollContent addSubview:self.doneBtn];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LLang(@"充值");
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [WKWalletMaterialTheme rechargeSheetTitle];
    [self.scrollContent addSubview:self.titleLabel];

    self.ordersBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.ordersBtn setTitle:LLang(@"订单") forState:UIControlStateNormal];
    [self.ordersBtn setTitleColor:[WKWalletMaterialTheme rechargeSheetActionBlue] forState:UIControlStateNormal];
    self.ordersBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.ordersBtn addTarget:self action:@selector(onOrders) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollContent addSubview:self.ordersBtn];
}

- (void)buildChainCard {
    self.chainCard = [[UIView alloc] init];
    [self applyCardChrome:self.chainCard];
    [self.scrollContent addSubview:self.chainCard];

    self.chainRow = [[UIControl alloc] init];
    [self.chainRow addTarget:self action:@selector(onPickChain) forControlEvents:UIControlEventTouchUpInside];
    [self.chainCard addSubview:self.chainRow];

    self.usdtBadge = [[UILabel alloc] init];
    self.usdtBadge.text = @"₮";
    self.usdtBadge.textAlignment = NSTextAlignmentCenter;
    self.usdtBadge.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.usdtBadge.textColor = UIColor.whiteColor;
    self.usdtBadge.backgroundColor = [WKWalletMaterialTheme rechargeSheetUsdtGreen];
    self.usdtBadge.layer.cornerRadius = 16;
    self.usdtBadge.layer.masksToBounds = YES;
    [self.chainRow addSubview:self.usdtBadge];

    self.chainNameLabel = [[UILabel alloc] init];
    self.chainNameLabel.font = [UIFont systemFontOfSize:15];
    self.chainNameLabel.textColor = [WKWalletMaterialTheme rechargeSheetChainBlue];
    self.chainNameLabel.text = LLang(@"正在加载充值方式…");
    [self.chainRow addSubview:self.chainNameLabel];

    self.chainChevron = [[UILabel alloc] init];
    self.chainChevron.text = @"›";
    self.chainChevron.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    self.chainChevron.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    self.chainChevron.hidden = YES;
    [self.chainRow addSubview:self.chainChevron];
}

- (UIControl *)buildActionChipWithTitle:(NSString *)title symbol:(NSString *)sym {
    (void)sym;
    UIButton *c = [UIButton buttonWithType:UIButtonTypeCustom];
    c.backgroundColor = [WKWalletMaterialTheme rechargeSheetAddressBg];
    c.layer.cornerRadius = 8;
    [c setTitle:title forState:UIControlStateNormal];
    [c setTitleColor:[WKWalletMaterialTheme rechargeSheetTitle] forState:UIControlStateNormal];
    c.titleLabel.font = [UIFont systemFontOfSize:13];
    return c;
}

- (void)layoutChip:(UIView *)chip {
    if ([chip isKindOfClass:[UIButton class]]) {
        [(UIButton *)chip layoutIfNeeded];
    }
}

- (void)buildQrCard {
    self.qrCard = [[UIView alloc] init];
    [self applyCardChrome:self.qrCard];
    [self.scrollContent addSubview:self.qrCard];

    self.qrImageView = [[UIImageView alloc] init];
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.backgroundColor = UIColor.whiteColor;
    self.qrImageView.layer.borderColor = [WKWalletMaterialTheme rechargeSheetCardStroke].CGColor;
    self.qrImageView.layer.borderWidth = 0.5;
    [self.qrCard addSubview:self.qrImageView];

    self.addressLabel = [[UILabel alloc] init];
    if (@available(iOS 13.0, *)) {
        self.addressLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    } else {
        self.addressLabel.font = [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont systemFontOfSize:12];
    }
    self.addressLabel.textColor = [WKWalletMaterialTheme rechargeSheetAddressText];
    self.addressLabel.backgroundColor = [WKWalletMaterialTheme rechargeSheetAddressBg];
    self.addressLabel.layer.cornerRadius = 6;
    self.addressLabel.layer.masksToBounds = YES;
    self.addressLabel.numberOfLines = 0;
    self.addressLabel.textAlignment = NSTextAlignmentLeft;
    self.addressLabel.text = LLang(@"加载中…");
    [self.qrCard addSubview:self.addressLabel];

    self.saveQrControl = [self buildActionChipWithTitle:LLang(@"保存二维码") symbol:@"⬇"];
    [self.saveQrControl addTarget:self action:@selector(onSaveQr) forControlEvents:UIControlEventTouchUpInside];
    [self.qrCard addSubview:self.saveQrControl];

    self.addressCopyControl = [self buildActionChipWithTitle:LLang(@"复制地址") symbol:@"⎘"];
    [self.addressCopyControl addTarget:self action:@selector(onCopyAddress) forControlEvents:UIControlEventTouchUpInside];
    [self.qrCard addSubview:self.addressCopyControl];
}

- (void)buildAmountCard {
    self.amountCard = [[UIView alloc] init];
    [self applyCardChrome:self.amountCard];
    self.amountCard.hidden = YES;
    [self.scrollContent addSubview:self.amountCard];

    self.amountTitleLabel = [[UILabel alloc] init];
    self.amountTitleLabel.text = LLang(@"充值金额");
    self.amountTitleLabel.font = [UIFont systemFontOfSize:14];
    self.amountTitleLabel.textColor = [WKWalletMaterialTheme rechargeSheetMinLabel];
    [self.amountCard addSubview:self.amountTitleLabel];

    self.amountSymbolLabel = [[UILabel alloc] init];
    self.amountSymbolLabel.text = @"$";
    self.amountSymbolLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.amountSymbolLabel.textColor = [WKWalletMaterialTheme rechargeSheetTitle];
    [self.amountCard addSubview:self.amountSymbolLabel];

    self.amountField = [[UITextField alloc] init];
    self.amountField.placeholder = @"0.00";
    self.amountField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.amountField.textColor = [WKWalletMaterialTheme rechargeSheetTitle];
    self.amountField.delegate = self;
    [self.amountField addTarget:self action:@selector(onAmountEdit) forControlEvents:UIControlEventEditingChanged];
    [self.amountCard addSubview:self.amountField];

    self.rangeLabel = [[UILabel alloc] init];
    self.rangeLabel.font = [UIFont systemFontOfSize:12];
    self.rangeLabel.textColor = [WKWalletMaterialTheme rechargeSheetMinValue];
    self.rangeLabel.hidden = YES;
    [self.amountCard addSubview:self.rangeLabel];

    self.amountDivider = [[UIView alloc] init];
    self.amountDivider.backgroundColor = [WKWalletMaterialTheme rechargeSheetPickDivider];
    [self.amountCard addSubview:self.amountDivider];

    self.estimateLabel = [[UILabel alloc] init];
    self.estimateLabel.font = [UIFont systemFontOfSize:12];
    self.estimateLabel.textColor = [WKWalletMaterialTheme rechargeSheetMinValue];
    self.estimateLabel.numberOfLines = 0;
    self.estimateLabel.hidden = YES;
    [self.amountCard addSubview:self.estimateLabel];

    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmBtn setTitle:LLang(@"确认充值") forState:UIControlStateNormal];
    [self.confirmBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.confirmBtn.backgroundColor = [WKWalletMaterialTheme rechargeSheetActionBlue];
    self.confirmBtn.layer.cornerRadius = 12;
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.confirmBtn addTarget:self action:@selector(onConfirmRecharge) forControlEvents:UIControlEventTouchUpInside];
    [self.amountCard addSubview:self.confirmBtn];
}

- (void)buildFooterRow {
    self.openFullBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.openFullBtn setTitle:LLang(@"更多充值方式") forState:UIControlStateNormal];
    [self.openFullBtn setTitleColor:[WKWalletMaterialTheme rechargeSheetActionBlue] forState:UIControlStateNormal];
    self.openFullBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    self.openFullBtn.hidden = YES;
    [self.openFullBtn addTarget:self action:@selector(onOpenFull) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollContent addSubview:self.openFullBtn];

    self.footerLabel = [[UILabel alloc] init];
    self.footerLabel.numberOfLines = 0;
    self.footerLabel.font = [UIFont systemFontOfSize:11];
    self.footerLabel.textColor = [WKWalletMaterialTheme rechargeSheetFooter];
    self.footerLabel.text = LLang(@"请确认网络与地址无误后再转账；到账时间以审核为准。若二维码无法展示，可复制地址或联系客服。");
    [self.scrollContent addSubview:self.footerLabel];
}

#pragma mark - Data

- (nullable NSDictionary *)currentChannel {
    if (self.channels.count == 0) {
        return nil;
    }
    NSInteger i = MAX(0, MIN(self.selectedIndex, (NSInteger)self.channels.count - 1));
    return self.channels[(NSUInteger)i];
}

- (void)loadChannels {
    [[WKWalletAPI shared] getRechargeChannelsWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self applyEmptyOrError:YES message:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSArray *raw = [WKWalletChannelUtil channelArrayFromAPIResult:result];
            self.channels = [WKWalletChannelUtil channelsSortedForDeposit:raw];
            if (self.channels.count == 0) {
                [self applyEmptyOrError:NO message:nil];
            } else {
                self.selectedIndex = 0;
                self.openFullBtn.hidden = YES;
                [self applySelectorChrome];
                [self applySelectedChannel];
            }
            [self.view setNeedsLayout];
        });
    }];
}

- (void)applyEmptyOrError:(BOOL)isError message:(nullable NSString *)msg {
    self.amountCard.hidden = YES;
    self.chainChevron.hidden = YES;
    self.chainRow.enabled = NO;
    self.openFullBtn.hidden = NO;
    self.chainNameLabel.text = isError ? LLang(@"加载失败") : LLang(@"暂无可用的充值方式");
    self.addressLabel.text = isError ? (msg ?: LLang(@"请检查网络后重试")) : LLang(@"请尝试更多充值方式或联系客服");
    self.qrImageView.image = nil;
    self.lastQrImage = nil;
    self.lastAddress = @"";
}

- (void)applySelectorChrome {
    BOOL multi = self.channels.count > 1;
    self.chainChevron.hidden = !multi;
    self.chainRow.enabled = multi;
}

- (void)applySelectedChannel {
    NSDictionary *ch = [self currentChannel];
    if (!ch) {
        return;
    }
    NSString *name = [WKWalletChannelUtil channelDisplayName:ch];
    if (name.length == 0) {
        name = LLang(@"充值网络");
    }
    self.chainNameLabel.text = name;

    NSString *addr = [WKWalletChannelUtil channelDepositAddress:ch];
    self.lastAddress = addr ?: @"";
    if (self.lastAddress.length) {
        self.addressLabel.text = self.lastAddress;
    } else {
        self.addressLabel.text = LLang(@"暂无收款地址");
    }

    self.qrGeneration += 1;
    NSInteger gen = self.qrGeneration;
    self.qrImageView.image = nil;
    self.lastQrImage = nil;

    NSString *qrRaw = [WKWalletChannelUtil channelQrImageURL:ch];

    if (qrRaw.length > 0) {
        __weak typeof(self) weakSelf = self;
        [WKWalletQrImageLoader loadRechargeChannelQrImageWithRawString:qrRaw completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (gen != weakSelf.qrGeneration) {
                    return;
                }
                if (image) {
                    weakSelf.lastQrImage = image;
                    weakSelf.qrImageView.image = image;
                } else if (weakSelf.lastAddress.length > 0) {
                    [weakSelf showGeneratedQr:gen address:weakSelf.lastAddress];
                } else {
                    [weakSelf toast:LLang(@"收款码加载失败")];
                }
            });
        }];
    } else if (self.lastAddress.length > 0) {
        [self showGeneratedQr:gen address:self.lastAddress];
    }

    self.amountField.text = @"";
    [self updateAmountSectionForChannel:ch];
    [self.view setNeedsLayout];
}

- (void)showGeneratedQr:(NSInteger)gen address:(NSString *)addr {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *img = [WKWalletQrImageLoader qrImageFromString:addr side:kSheetQR * UIScreen.mainScreen.scale];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (gen != self.qrGeneration) {
                return;
            }
            self.lastQrImage = img;
            self.qrImageView.image = img;
        });
    });
}

- (void)updateAmountSectionForChannel:(NSDictionary *)ch {
    self.amountCard.hidden = NO;
    BOOL isU = [WKWalletChannelUtil channelPayType:ch] == 4;
    self.amountSymbolLabel.text = isU ? @"$" : @"¥";

    double mn = [WKWalletChannelUtil channelMinAmount:ch];
    double mx = [WKWalletChannelUtil channelMaxAmount:ch];
    BOOL hasMin = mn > 0;
    BOOL hasMax = mx > 0;
    if (!hasMin && !hasMax) {
        self.rangeLabel.hidden = YES;
    } else {
        self.rangeLabel.hidden = NO;
        if (hasMin && hasMax) {
            self.rangeLabel.text = [NSString stringWithFormat:LLang(@"单笔最低 %@，最高 %@"), [self formatChannelAmount:mn], [self formatChannelAmount:mx]];
        } else if (hasMin) {
            self.rangeLabel.text = [NSString stringWithFormat:LLang(@"单笔最低 %@"), [self formatChannelAmount:mn]];
        } else {
            self.rangeLabel.text = [NSString stringWithFormat:LLang(@"单笔最高 %@"), [self formatChannelAmount:mx]];
        }
    }
    [self updateEstimate];
}

- (NSString *)formatChannelAmount:(double)v {
    if (fabs(v - floor(v)) < 1e-9) {
        return [NSString stringWithFormat:@"%.0f", v];
    }
    NSString *s = [NSString stringWithFormat:@"%.8f", v];
    while ([s containsString:@"."] && ([s hasSuffix:@"0"] || [s hasSuffix:@"."])) {
        s = [s substringToIndex:s.length - 1];
    }
    return s;
}

- (void)updateEstimate {
    NSDictionary *ch = [self currentChannel];
    if (!ch || [WKWalletChannelUtil channelPayType:ch] != 4) {
        self.estimateLabel.hidden = YES;
        return;
    }
    double rate = [WKWalletChannelUtil channelUcoinCnyPerU:ch];
    if (rate <= 0 || isnan(rate)) {
        self.estimateLabel.hidden = YES;
        return;
    }
    NSString *raw = [[self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (raw.length == 0) {
        self.estimateLabel.hidden = YES;
        return;
    }
    double u = [raw doubleValue];
    if (u <= 0 || isnan(u)) {
        self.estimateLabel.hidden = YES;
        return;
    }
    double est = u * rate;
    self.estimateLabel.text = [NSString stringWithFormat:LLang(@"预计到账约 ¥%.2f（仅供参考，以审核结果为准）"), est];
    self.estimateLabel.hidden = NO;
}

- (void)onAmountEdit {
    [self updateEstimate];
}

#pragma mark - Keyboard

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    if (![info isKindOfClass:[NSDictionary class]]) {
        return;
    }
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    CGRect scrollInView = [self.view convertRect:self.scroll.bounds fromView:self.scroll];
    CGFloat bottomInset = 0;
    if (CGRectIntersectsRect(scrollInView, kbFrame)) {
        bottomInset = CGRectIntersection(scrollInView, kbFrame).size.height;
    }
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    NSUInteger options = (NSUInteger)curve << 16 | UIViewAnimationOptionBeginFromCurrentState;
    UIEdgeInsets inset = UIEdgeInsetsMake(0, 0, bottomInset, 0);
    [UIView animateWithDuration:duration > 0 ? duration : 0.25 delay:0 options:options animations:^{
        self.scroll.contentInset = inset;
        if (@available(iOS 11.0, *)) {
            self.scroll.verticalScrollIndicatorInsets = inset;
        } else {
            self.scroll.scrollIndicatorInsets = inset;
        }
    } completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (void)onScrollTapDismissKeyboard {
    [self.view endEditing:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *v = touch.view;
    while (v && v != self.scroll) {
        if ([v isKindOfClass:[UITextField class]] || [v isKindOfClass:[UITextView class]]) {
            return NO;
        }
        v = v.superview;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return otherGestureRecognizer == self.scroll.panGestureRecognizer;
}

#pragma mark - Actions

- (void)onDimTap {
    [self.view endEditing:YES];
    [self dismissAnimated];
}

- (void)onDone {
    [self.view endEditing:YES];
    [self dismissAnimated];
}

- (void)dismissAnimatedWithCompletion:(void (^ _Nullable)(void))completion {
    CGFloat H = CGRectGetHeight(self.view.bounds);
    if (H < 1) {
        H = (CGFloat)CGRectGetHeight(UIScreen.mainScreen.bounds);
    }
    CGFloat panelTop = H * kPanelTopRatio;
    CGFloat slide = H - panelTop;
    /// 与入场对称：半屏自下方滑入、自下方滑出；不用弹簧退场，避免先向上回弹造成「从顶部收起」的错觉。
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.dimButton.alpha = 0;
        self.panel.transform = CGAffineTransformMakeTranslation(0, slide);
        self.contactFab.transform = CGAffineTransformMakeTranslation(0, slide);
        self.contactFab.alpha = 0;
    } completion:^(__unused BOOL finished) {
        self.panel.transform = CGAffineTransformIdentity;
        self.contactFab.transform = CGAffineTransformIdentity;
        [self dismissViewControllerAnimated:NO completion:^{
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        }];
    }];
}

- (void)dismissAnimated {
    [self dismissAnimatedWithCompletion:nil];
}

- (void)onOrders {
    // 先关 Sheet；进订单页使用系统导航 push，与 {@link WKWithdrawVC#onWithdrawOrdersNav} 一致（非 Material 自底向上）。
    UIViewController *presenter = self.presentingViewController;
    [self dismissAnimatedWithCompletion:^{
        [WKWalletBuyUsdtNavTransition pushOrderListResolvingNavigationFromPresenter:presenter useBuyUsdtMaterialTransition:NO];
    }];
}

- (void)onOpenFull {
    UIViewController *presenter = self.presentingViewController;
    [self dismissAnimatedWithCompletion:^{
        WKRechargeFullVC *vc = [[WKRechargeFullVC alloc] init];
        UINavigationController *nav = presenter.navigationController;
        if (!nav && [presenter isKindOfClass:[UINavigationController class]]) {
            nav = (UINavigationController *)presenter;
        }
        if (nav) {
            [nav pushViewController:vc animated:NO];
        } else {
            [[WKNavigationManager shared] pushViewController:vc animated:NO];
        }
    }];
}

- (void)onPickChain {
    if (self.channels.count <= 1) {
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:LLang(@"选择充值网络") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self.channels enumerateObjectsUsingBlock:^(NSDictionary *ch, NSUInteger idx, BOOL *stop) {
        NSString *title = [WKWalletChannelUtil channelDisplayName:ch];
        [ac addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            self.selectedIndex = (NSInteger)idx;
            [self applySelectedChannel];
        }]];
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onCopyAddress {
    if (self.lastAddress.length == 0) {
        [self toast:LLang(@"暂无地址")];
        return;
    }
    UIPasteboard.generalPasteboard.string = self.lastAddress;
    [self toast:LLang(@"已复制")];
}

- (void)onSaveQr {
    if (!self.lastQrImage) {
        [self toast:LLang(@"暂无可保存的二维码")];
        return;
    }
    UIImage *img = self.lastQrImage;
    void (^save)(void) = ^{
        UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    };
    void (^afterAuth)(PHAuthorizationStatus) = ^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                save();
            } else {
                [self toast:LLang(@"请在设置中允许访问相册以保存图片")];
            }
        });
    };
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:afterAuth];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            afterAuth(status);
        }];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    (void)image;
    (void)contextInfo;
    if (error) {
        [self toast:LLang(@"保存失败")];
    } else {
        [self toast:LLang(@"已保存到相册")];
    }
}

- (void)onContactCs {
    UIViewController *presenter = self.presentingViewController;
    if (!presenter) {
        [[WKApp shared] invoke:@"show_customer_service" param:self];
        return;
    }
    [self dismissAnimatedWithCompletion:^{
        [[WKApp shared] invoke:@"show_customer_service" param:presenter];
    }];
}

- (void)onConfirmRecharge {
    NSDictionary *ch = [self currentChannel];
    if (!ch) {
        [self toast:LLang(@"暂无可选渠道")];
        return;
    }
    NSString *raw = [[self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    double amount = [raw doubleValue];
    if (raw.length == 0 || amount <= 0 || isnan(amount)) {
        [self toast:LLang(@"请输入有效金额")];
        return;
    }
    double mn = [WKWalletChannelUtil channelMinAmount:ch];
    double mx = [WKWalletChannelUtil channelMaxAmount:ch];
    if (mn > 0 && amount < mn - 1e-9) {
        [self toast:LLang(@"低于单笔最低限额")];
        return;
    }
    if (mx > 0 && amount > mx + 1e-9) {
        [self toast:LLang(@"超过单笔最高限额")];
        return;
    }

    long long cid = [WKWalletChannelUtil channelId:ch];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"channel_id"] = @(cid);
    BOOL uShield = [WKWalletChannelUtil channelPayType:ch] == 4;
    if (uShield) {
        body[@"amount_u"] = @(amount);
        body[@"remark"] = @"";
        body[@"proof_url"] = @"";
    } else {
        body[@"amount"] = @(amount);
        body[@"remark"] = @"";
    }

    self.confirmBtn.enabled = NO;
    [[WKWalletAPI shared] rechargeApplyWithBody:body callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.confirmBtn.enabled = YES;
            if (error) {
                [self toast:error.localizedDescription ?: LLang(@"网络错误")];
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
                msg = LLang(@"提交成功");
            }
            if (st >= 400 && st < 600) {
                [self toast:msg.length ? msg : LLang(@"提交失败")];
                return;
            }
            double credited = WKResolvedRechargeCreditedFromDict(d);
            NSString *successToast;
            if (!isnan(credited) && !isinf(credited)) {
                NSString *amtStr = [NSString stringWithFormat:@"%.2f", credited];
                successToast = [NSString stringWithFormat:LLang(@"申请已提交，预计到账 %@（以实际到账为准）"), amtStr];
            } else {
                successToast = LLang(@"充值成功");
            }
            self.amountField.text = @"";
            self.estimateLabel.hidden = YES;
            [self.view endEditing:YES];
            UIViewController *presenter = self.presentingViewController;
            NSString *toastCopy = [successToast copy];
            /// 先 push 订单页到钱包导航栈（半屏仍盖住界面），再收起半屏；收起后直接进入订单，无需用户先点「完成」再等跳转。
            [WKWalletBuyUsdtNavTransition pushOrderListResolvingNavigationFromPresenter:presenter useBuyUsdtMaterialTransition:NO];
            [self dismissAnimatedWithCompletion:^{
                UIView *v = [[WKNavigationManager shared] topViewController].view;
                if (v) {
                    [v showHUDWithHide:toastCopy];
                }
            }];
        });
    }];
}

- (void)toast:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"好的") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
