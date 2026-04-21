#import "WKWalletVC.h"
#import "WKWalletAPI.h"
#import "WKWalletChannelUtil.h"
#import "WKSetPayPasswordVC.h"
#import "WKTransactionRecordVC.h"
#import "WKWalletReceiveQRVC.h"
#import "WKRechargeDepositSheetVC.h"
#import "WKRechargeFullVC.h"
#import "WKWithdrawVC.h"
#import <WuKongBase/WKScanVC.h>

static NSString *WKWalletMarketRowTitle(NSUInteger i) {
    NSArray *titles = @[ @"USDT-TRC20", @"USDT-ERC20", @"USDT-BSC", @"BNB" ];
    return i < titles.count ? titles[i] : @"";
}

/// 与 Android {@code colors_wallet_ui.xml} 一致。
static UIColor *WKWalletUIColorRGB(unsigned rgb, CGFloat a) {
    return [UIColor colorWithRed:((rgb >> 16) & 0xff) / 255.0 green:((rgb >> 8) & 0xff) / 255.0 blue:(rgb & 0xff) / 255.0 alpha:a];
}

@interface WKWalletVC ()

/// 与 Android 一致从钱包进子页；`navigationController` 为空时走根导航（避免菜单点了无反应）。
- (void)wkWalletPush:(UIViewController *)vc;

@property (nonatomic, assign) double cnyBalance;
@property (nonatomic, assign) BOOL hasPassword;
@property (nonatomic, assign) BOOL balanceVisible;
@property (nonatomic, assign) BOOL balanceShowUsdt;
@property (nonatomic, assign) double cnyPerUsdtRate;

@property (nonatomic, strong) UIView *gradientHeader;
@property (nonatomic, strong) CAGradientLayer *headerGradient;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UIButton *settingsBtn;
@property (nonatomic, strong) UILabel *balanceLineLabel;
@property (nonatomic, strong) UIButton *eyeBtn;

@property (nonatomic, strong) UIScrollView *contentScroll;
@property (nonatomic, strong) UIView *quickPanel;
@property (nonatomic, strong) UIButton *scanBtn;
@property (nonatomic, strong) UIButton *receiveBtn;
@property (nonatomic, strong) UIButton *rechargeBtn;
@property (nonatomic, strong) UIButton *withdrawBtn;

@property (nonatomic, strong) UIView *usdtBanner;
@property (nonatomic, strong) UIView *marketHeaderRow;
@property (nonatomic, strong) UILabel *marketSectionTitleLabel;
@property (nonatomic, strong) UIView *marketSection;
@property (nonatomic, strong) UIButton *marketMoreBtn;
@property (nonatomic, strong) UIControl *balanceTapControl;
@property (nonatomic, assign) BOOL balanceEyeUsesLoginAssets;

@end

@implementation WKWalletVC

- (UIImage *)walletScanPayIconImage {
    const CGFloat size = 24.0f;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextRef ctx = rendererContext.CGContext;
        UIColor *stroke = WKWalletUIColorRGB(0xFB8C00, 1.0f);
        CGContextSetStrokeColorWithColor(ctx, stroke.CGColor);
        CGContextSetLineWidth(ctx, 2.2f);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineJoin(ctx, kCGLineJoinRound);

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(7.0f, 4.5f)];
        [path addLineToPoint:CGPointMake(5.5f, 4.5f)];
        [path addQuadCurveToPoint:CGPointMake(3.5f, 6.5f) controlPoint:CGPointMake(3.5f, 4.5f)];
        [path addLineToPoint:CGPointMake(3.5f, 8.0f)];

        [path moveToPoint:CGPointMake(16.5f, 4.5f)];
        [path addLineToPoint:CGPointMake(18.5f, 4.5f)];
        [path addQuadCurveToPoint:CGPointMake(20.5f, 6.5f) controlPoint:CGPointMake(20.5f, 4.5f)];
        [path addLineToPoint:CGPointMake(20.5f, 8.0f)];

        [path moveToPoint:CGPointMake(20.5f, 16.0f)];
        [path addLineToPoint:CGPointMake(20.5f, 18.0f)];
        [path addQuadCurveToPoint:CGPointMake(18.5f, 20.0f) controlPoint:CGPointMake(20.5f, 20.0f)];
        [path addLineToPoint:CGPointMake(16.5f, 20.0f)];

        [path moveToPoint:CGPointMake(7.0f, 20.0f)];
        [path addLineToPoint:CGPointMake(5.5f, 20.0f)];
        [path addQuadCurveToPoint:CGPointMake(3.5f, 18.0f) controlPoint:CGPointMake(3.5f, 20.0f)];
        [path addLineToPoint:CGPointMake(3.5f, 16.0f)];

        [path moveToPoint:CGPointMake(9.0f, 12.0f)];
        [path addLineToPoint:CGPointMake(15.0f, 12.0f)];
        [path moveToPoint:CGPointMake(12.0f, 9.0f)];
        [path addLineToPoint:CGPointMake(12.0f, 15.0f)];
        CGContextAddPath(ctx, path.CGPath);
        CGContextStrokePath(ctx);
    }];
}

- (void)wkWalletPush:(UIViewController *)vc {
    if (!vc) {
        return;
    }
    if (self.navigationController) {
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"钱包");
    self.navigationBar.hidden = YES;
    self.cnyPerUsdtRate = NAN;
    self.balanceVisible = YES;
    self.balanceShowUsdt = NO;
    self.view.backgroundColor = WKWalletUIColorRGB(0xF5F6FA, 1.0);

    [self setupUI];
    [self applyBalanceText];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadBalance];
    [self loadRechargeChannelsRate];
    if (@available(iOS 14.0, *)) {
        self.settingsBtn.menu = [self buildWalletSettingsMenu];
    }
}

- (void)setupUI {
    self.gradientHeader = [[UIView alloc] init];
    self.gradientHeader.layer.masksToBounds = YES;
    [self.view addSubview:self.gradientHeader];

    /// 与 Android {@code wallet_header_gradient.xml} 一致：angle=0 即左→右 {@code #3949AB} → {@code #7C4DFF}。
    self.headerGradient = [CAGradientLayer layer];
    self.headerGradient.colors = @[
        (__bridge id)WKWalletUIColorRGB(0x3949AB, 1.0).CGColor,
        (__bridge id)WKWalletUIColorRGB(0x7C4DFF, 1.0).CGColor
    ];
    self.headerGradient.startPoint = CGPointMake(0.0, 0.5);
    self.headerGradient.endPoint = CGPointMake(1.0, 0.5);
    [self.gradientHeader.layer addSublayer:self.headerGradient];

    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImg = [[WKApp shared] loadImage:@"ic_wallet_back_white" moduleID:@"WuKongWallet"];
    if (backImg) {
        backImg = [backImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.backBtn setImage:backImg forState:UIControlStateNormal];
        [self.backBtn setTitle:nil forState:UIControlStateNormal];
        self.backBtn.tintColor = UIColor.whiteColor;
        self.backBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        /// 与 Android {@code padding="12dp"} on 48dp 按钮一致，图标可视区域约 24dp。
        self.backBtn.imageEdgeInsets = UIEdgeInsetsMake(12.0f, 12.0f, 12.0f, 12.0f);
    } else {
        [self.backBtn setTitle:@"‹" forState:UIControlStateNormal];
        self.backBtn.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        [self.backBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    [self.backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.gradientHeader addSubview:self.backBtn];

    self.navTitleLabel = [[UILabel alloc] init];
    self.navTitleLabel.text = LLang(@"钱包");
    self.navTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.navTitleLabel.textColor = UIColor.whiteColor;
    self.navTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.gradientHeader addSubview:self.navTitleLabel];

    self.settingsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *gearImg = [[WKApp shared] loadImage:@"ic_wallet_settings_white" moduleID:@"WuKongWallet"];
    if (gearImg) {
        gearImg = [gearImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.settingsBtn setImage:gearImg forState:UIControlStateNormal];
        [self.settingsBtn setTitle:nil forState:UIControlStateNormal];
        self.settingsBtn.tintColor = UIColor.whiteColor;
        self.settingsBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.settingsBtn.imageEdgeInsets = UIEdgeInsetsMake(12.0f, 12.0f, 12.0f, 12.0f);
    } else {
        [self.settingsBtn setTitle:@"⚙︎" forState:UIControlStateNormal];
        self.settingsBtn.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
        [self.settingsBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    /// 与 Android {@link WalletActivity#walletSettingsBtn}：{@link PopupMenu} 锚在右上角；iOS 14+ 用 {@link UIMenu} 同类交互。
    if (@available(iOS 14.0, *)) {
        self.settingsBtn.showsMenuAsPrimaryAction = YES;
    } else {
        [self.settingsBtn addTarget:self action:@selector(onWalletSettingsLegacyMenu) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.gradientHeader addSubview:self.settingsBtn];

    self.balanceLineLabel = [[UILabel alloc] init];
    self.balanceLineLabel.numberOfLines = 1;
    [self.gradientHeader addSubview:self.balanceLineLabel];

    self.eyeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.eyeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *eyeOff = [[WKApp shared] loadImage:@"BtnEyeOff" moduleID:@"WuKongLogin"];
    UIImage *eyeOn = [[WKApp shared] loadImage:@"BtnEyeOn" moduleID:@"WuKongLogin"];
    if (eyeOff && eyeOn) {
        [self.eyeBtn setImage:[eyeOff imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.eyeBtn setImage:[eyeOn imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
        self.eyeBtn.tintColor = UIColor.whiteColor;
        [self.eyeBtn setTitle:nil forState:UIControlStateNormal];
        self.balanceEyeUsesLoginAssets = YES;
    } else {
        [self.eyeBtn setTitle:@"👁" forState:UIControlStateNormal];
        self.balanceEyeUsesLoginAssets = NO;
    }
    self.eyeBtn.selected = self.balanceVisible;
    [self.eyeBtn addTarget:self action:@selector(toggleBalanceVisible) forControlEvents:UIControlEventTouchUpInside];
    [self.gradientHeader addSubview:self.eyeBtn];

    self.balanceTapControl = [[UIControl alloc] init];
    [self.balanceTapControl addTarget:self action:@selector(toggleBalanceCurrency) forControlEvents:UIControlEventTouchUpInside];
    [self.gradientHeader insertSubview:self.balanceTapControl belowSubview:self.balanceLineLabel];
}

- (void)layoutWalletSubviews {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat safeTop = self.view.safeAreaInsets.top;
    /// 接近 Android {@code walletHeader}：{@code minHeight="200dp"} + 底部留白区，便于叠卡。
    CGFloat headerH = 200.0f;
    CGFloat headerTotal = safeTop + headerH;

    self.gradientHeader.frame = CGRectMake(0, 0, w, headerTotal);
    self.headerGradient.frame = self.gradientHeader.bounds;

    CGFloat pad = 16.0f;
    /// 与 Android {@code walletBackBtn} / {@code walletSettingsBtn} 一致：48×48dp 点击区。
    const CGFloat kNavIcon = 48.0f;
    self.backBtn.frame = CGRectMake(8, safeTop + 2, kNavIcon, kNavIcon);
    self.settingsBtn.frame = CGRectMake(w - kNavIcon - 8, safeTop + 2, kNavIcon, kNavIcon);
    self.navTitleLabel.frame = CGRectMake(8 + kNavIcon + 4, safeTop + 10, w - (8 + kNavIcon + 4) * 2, 28);

    /// 与 Android 头部 {@code paddingStart/End 12dp} + 余额行左侧 5% 留白一致。
    const CGFloat kHeaderPadH = 12.0f;
    CGFloat balanceLead = kHeaderPadH + (w - kHeaderPadH * 2.0f) * 0.05f;
    CGFloat balanceY = safeTop + 56;
    self.eyeBtn.frame = CGRectMake(w - kHeaderPadH - 48.0f, balanceY, 48.0f, 48.0f);
    CGFloat balanceW = self.eyeBtn.frame.origin.x - balanceLead - 8.0f;
    self.balanceLineLabel.frame = CGRectMake(balanceLead, balanceY + 4, balanceW, 44);

    if (self.balanceTapControl) {
        self.balanceTapControl.frame = CGRectMake(balanceLead, balanceY, balanceW, 48);
    }

    if (!self.contentScroll) {
        return;
    }

    /// 与 Android {@code wallet_scroll_overlap}（-40dp）一致：内容上滑叠入紫色头图。
    const CGFloat kScrollOverlap = 40.0f;
    CGFloat scrollY = headerTotal - kScrollOverlap;
    self.contentScroll.frame = CGRectMake(0, scrollY, w, h - scrollY);
    if (@available(iOS 11.0, *)) {
        self.contentScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    /// 首卡片顶对齐滚动内容原点：叠入量仅由 {@code scrollY = headerTotal - 40} 体现，与 Android {@code layout_marginTop="@dimen/wallet_scroll_overlap"}（-40dp）一致。
    CGFloat y = 0.0f;
    CGFloat panelW = w - 32.0f;
    /// 单行四列 + 上下各 20pt，与 {@code activity_wallet.xml} 快捷卡片一致。
    const CGFloat kQuickPadV = 20.0f;
    const CGFloat kQuickIcon = 44.0f;
    const CGFloat kQuickLabelH = 16.0f;
    CGFloat quickH = kQuickPadV * 2.0f + kQuickIcon + 8.0f + kQuickLabelH;
    self.quickPanel.frame = CGRectMake(16, y, panelW, quickH);

    CGFloat colW = panelW / 4.0f;
    CGFloat rowTop = kQuickPadV;
    self.scanBtn.frame = CGRectMake(0, rowTop, colW, quickH - kQuickPadV);
    self.receiveBtn.frame = CGRectMake(colW, rowTop, colW, quickH - kQuickPadV);
    self.rechargeBtn.frame = CGRectMake(colW * 2.0f, rowTop, colW, quickH - kQuickPadV);
    self.withdrawBtn.frame = CGRectMake(colW * 3.0f, rowTop, colW, quickH - kQuickPadV);

    y = CGRectGetMaxY(self.quickPanel.frame) + 14.0f;
    CGFloat bannerH = [self walletQuickBuyBannerHeightForWidth:panelW];
    self.usdtBanner.frame = CGRectMake(16, y, panelW, bannerH);
    y = CGRectGetMaxY(self.usdtBanner.frame) + 20.0f;

    CGFloat headerRowH = 32.0f;
    self.marketHeaderRow.frame = CGRectMake(16, y, panelW, headerRowH);
    y = CGRectGetMaxY(self.marketHeaderRow.frame) + 10.0f;

    const CGFloat kMarketRowH = 68.0f;
    NSUInteger rows = 4;
    /// 行情列表卡片内无额外顶底留白，与 Android {@code RecyclerView} 直接铺满卡片一致。
    CGFloat listCardH = kMarketRowH * (CGFloat)rows;
    self.marketSection.frame = CGRectMake(16, y, panelW, listCardH);
    /// 与 Android 外层 {@code paddingBottom="24dp"} 一致。
    y = CGRectGetMaxY(self.marketSection.frame) + 24.0f;

    self.contentScroll.contentSize = CGSizeMake(w, y);
    [self layoutMarketHeaderRow];
    [self layoutMarketRows];
}

/// 与 Android {@code quickBuyBanner} {@code paddingVertical="14dp"}、副标题 {@code layout_marginTop="4dp"} 的 wrap 高度一致。
- (CGFloat)walletQuickBuyBannerHeightForWidth:(CGFloat)panelW {
    NSString *subText = LLang(@"支持支付宝、银行转账、汇旺等多种方式支付");
    UIFont *subFont = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    const CGFloat kPadH = 16.0f;
    const CGFloat kPadV = 14.0f;
    const CGFloat kBadge = 44.0f;
    const CGFloat kTitleH = 22.0f;
    const CGFloat kGapTitleSub = 4.0f;
    CGFloat textW = panelW - kPadH * 2.0f - kBadge - 12.0f;
    if (textW < 40.0f) {
        textW = 40.0f;
    }
    CGRect subRect = [subText boundingRectWithSize:CGSizeMake(textW, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:@{ NSFontAttributeName: subFont }
                                             context:nil];
    CGFloat subH = ceil(subRect.size.height);
    CGFloat contentH = kPadV + kTitleH + kGapTitleSub + subH + kPadV;
    CGFloat minIconStack = kPadV + kBadge + kPadV;
    return MAX(contentH, minIconStack);
}

- (void)layoutMarketHeaderRow {
    if (!self.marketHeaderRow) {
        return;
    }
    CGFloat w = self.marketHeaderRow.bounds.size.width;
    CGFloat h = self.marketHeaderRow.bounds.size.height;
    if (w < 1) {
        return;
    }
    self.marketSectionTitleLabel.frame = CGRectMake(0, (h - 22.0f) / 2.0f, w - 88.0f, 22.0f);
    self.marketMoreBtn.frame = CGRectMake(w - 72.0f, (h - 32.0f) / 2.0f, 68.0f, 32.0f);
}

- (void)setupScrollContent {
    if (self.contentScroll) {
        return;
    }
    self.contentScroll = [[UIScrollView alloc] init];
    self.contentScroll.backgroundColor = UIColor.clearColor;
    self.contentScroll.showsVerticalScrollIndicator = YES;
    self.contentScroll.alwaysBounceVertical = YES;
    self.contentScroll.delaysContentTouches = NO;
    self.contentScroll.canCancelContentTouches = NO;
    if (@available(iOS 11.0, *)) {
        self.contentScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.contentScroll];

    self.quickPanel = [[UIView alloc] init];
    self.quickPanel.backgroundColor = WKWalletUIColorRGB(0xFFFFFF, 1.0);
    self.quickPanel.layer.cornerRadius = 16.0f;
    self.quickPanel.layer.masksToBounds = NO;
    self.quickPanel.layer.borderWidth = 0.5f;
    self.quickPanel.layer.borderColor = WKWalletUIColorRGB(0x000000, 0.08f).CGColor;
    self.quickPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.quickPanel.layer.shadowOpacity = 0.12f;
    self.quickPanel.layer.shadowOffset = CGSizeMake(0, 3);
    self.quickPanel.layer.shadowRadius = 8.0f;
    [self.contentScroll addSubview:self.quickPanel];

    self.scanBtn = [self buildQuickItemWithTitle:LLang(@"扫码付") emoji:@"" circleColor:WKWalletUIColorRGB(0xFFF8E1, 1.0) action:@selector(onScan)];
    self.receiveBtn = [self buildQuickItemWithTitle:LLang(@"收款码") emoji:@"▦" circleColor:WKWalletUIColorRGB(0xF3E5F5, 1.0) action:@selector(onReceive)];
    self.rechargeBtn = [self buildQuickItemWithTitle:LLang(@"充值") emoji:@"＄" circleColor:WKWalletUIColorRGB(0xFFEBEE, 1.0) action:@selector(onRecharge)];
    self.withdrawBtn = [self buildQuickItemWithTitle:LLang(@"提币") emoji:@"⇪" circleColor:WKWalletUIColorRGB(0xE3F2FD, 1.0) action:@selector(onWithdraw)];

    UILabel *scanEmoji = [self.scanBtn viewWithTag:502];
    UIImageView *scanIcon = [self.scanBtn viewWithTag:504];
    scanEmoji.hidden = YES;
    scanIcon.hidden = NO;
    scanIcon.image = [self walletScanPayIconImage];

    [self.quickPanel addSubview:self.scanBtn];
    [self.quickPanel addSubview:self.receiveBtn];
    [self.quickPanel addSubview:self.rechargeBtn];
    [self.quickPanel addSubview:self.withdrawBtn];

    self.usdtBanner = [[UIView alloc] init];
    /// 与 Android {@code colors_wallet_ui.xml} {@code wallet_banner_bg} 完全一致：{@code #CCFDDED6}（ARGB）。
    self.usdtBanner.backgroundColor = WKWalletUIColorRGB(0xFDDED6, (CGFloat)0xCC / 255.0f);
    self.usdtBanner.layer.cornerRadius = 14.0f;
    self.usdtBanner.layer.masksToBounds = YES;
    UITapGestureRecognizer *tapBanner = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onQuickBuyBanner)];
    [self.usdtBanner addGestureRecognizer:tapBanner];
    [self.contentScroll addSubview:self.usdtBanner];

    UILabel *bannerTitle = [[UILabel alloc] init];
    bannerTitle.tag = 8001;
    bannerTitle.text = LLang(@"快捷购买 USDT");
    bannerTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    bannerTitle.textColor = WKWalletUIColorRGB(0x333333, 1.0);
    [self.usdtBanner addSubview:bannerTitle];

    UILabel *bannerSub = [[UILabel alloc] init];
    bannerSub.tag = 8002;
    bannerSub.text = LLang(@"支持支付宝、银行转账、汇旺等多种方式支付");
    bannerSub.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    bannerSub.textColor = WKWalletUIColorRGB(0x888888, 1.0);
    bannerSub.numberOfLines = 0;
    [self.usdtBanner addSubview:bannerSub];

    UILabel *usdtIcon = [[UILabel alloc] init];
    usdtIcon.text = @"₮";
    usdtIcon.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    usdtIcon.textAlignment = NSTextAlignmentCenter;
    usdtIcon.backgroundColor = WKWalletUIColorRGB(0x26A17B, 1.0);
    usdtIcon.textColor = UIColor.whiteColor;
    usdtIcon.layer.cornerRadius = 22.0f;
    usdtIcon.layer.masksToBounds = YES;
    usdtIcon.tag = 8003;
    [self.usdtBanner addSubview:usdtIcon];

    self.marketHeaderRow = [[UIView alloc] init];
    self.marketHeaderRow.backgroundColor = UIColor.clearColor;
    [self.contentScroll addSubview:self.marketHeaderRow];

    self.marketSectionTitleLabel = [[UILabel alloc] init];
    self.marketSectionTitleLabel.text = LLang(@"行情");
    self.marketSectionTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.marketSectionTitleLabel.textColor = WKWalletUIColorRGB(0x222222, 1.0);
    [self.marketHeaderRow addSubview:self.marketSectionTitleLabel];

    self.marketMoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.marketMoreBtn setTitle:LLang(@"更多 >") forState:UIControlStateNormal];
    [self.marketMoreBtn setTitleColor:WKWalletUIColorRGB(0x888888, 1.0) forState:UIControlStateNormal];
    self.marketMoreBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.marketMoreBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.marketMoreBtn addTarget:self action:@selector(onMarketMore) forControlEvents:UIControlEventTouchUpInside];
    [self.marketHeaderRow addSubview:self.marketMoreBtn];

    self.marketSection = [[UIView alloc] init];
    self.marketSection.backgroundColor = WKWalletUIColorRGB(0xFFFFFF, 1.0);
    self.marketSection.layer.cornerRadius = 16.0f;
    self.marketSection.layer.masksToBounds = NO;
    self.marketSection.layer.borderWidth = 0.5f;
    self.marketSection.layer.borderColor = WKWalletUIColorRGB(0x000000, 0.08f).CGColor;
    self.marketSection.layer.shadowColor = [UIColor blackColor].CGColor;
    self.marketSection.layer.shadowOpacity = 0.08f;
    self.marketSection.layer.shadowOffset = CGSizeMake(0, 2);
    self.marketSection.layer.shadowRadius = 4.0f;
    [self.contentScroll addSubview:self.marketSection];

    NSArray *changes = @[ @"+0.02%", @"-0.06%", @"-1.92%", @"+0.35%" ];
    NSArray *symbols = @[ @"₮", @"₮", @"₮", @"B" ];
    NSArray *symColors = @[
        WKWalletUIColorRGB(0x26A17B, 1.0),
        WKWalletUIColorRGB(0x26A17B, 1.0),
        WKWalletUIColorRGB(0x26A17B, 1.0),
        WKWalletUIColorRGB(0xF3BA2F, 1.0)
    ];
    for (NSUInteger i = 0; i < 4; i++) {
        UIView *row = [self buildMarketRowWithTitle:WKWalletMarketRowTitle(i) price:@"$1" change:changes[i] badge:symbols[i] badgeColor:symColors[i]];
        row.tag = 9100 + i;
        [self.marketSection addSubview:row];
    }

    [self layoutUsdtBannerSubviews];
}

- (void)layoutUsdtBannerSubviews {
    CGFloat bw = self.usdtBanner.bounds.size.width;
    CGFloat bh = self.usdtBanner.bounds.size.height;
    if (bw < 1) {
        return;
    }
    const CGFloat kPadH = 16.0f;
    const CGFloat kPadV = 14.0f;
    const CGFloat kBadge = 44.0f;
    const CGFloat kTitleH = 22.0f;
    const CGFloat kGapTitleSub = 4.0f;
    UIView *icon = [self.usdtBanner viewWithTag:8003];
    icon.frame = CGRectMake(bw - kPadH - kBadge, (bh - kBadge) / 2.0f, kBadge, kBadge);
    icon.layer.cornerRadius = kBadge / 2.0f;

    CGFloat textW = bw - kPadH * 2.0f - kBadge - 12.0f;
    UILabel *t = [self.usdtBanner viewWithTag:8001];
    t.frame = CGRectMake(kPadH, kPadV, textW, kTitleH);
    UILabel *s = [self.usdtBanner viewWithTag:8002];
    CGFloat subY = CGRectGetMaxY(t.frame) + kGapTitleSub;
    s.frame = CGRectMake(kPadH, subY, textW, bh - subY - kPadV);
}

/// 对齐 {@code item_wallet_market.xml}：左 40dp 徽章、名称 15sp 粗体、价格 12sp、右侧涨跌幅 14sp 粗体。
- (UIView *)buildMarketRowWithTitle:(NSString *)title
                              price:(NSString *)price
                             change:(NSString *)change
                              badge:(NSString *)badgeText
                         badgeColor:(UIColor *)badgeColor {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = WKWalletUIColorRGB(0xFFFFFF, 1.0);
    row.clipsToBounds = YES;

    UIView *badge = [[UIView alloc] init];
    badge.backgroundColor = badgeColor;
    badge.layer.cornerRadius = 20.0f;
    badge.layer.masksToBounds = YES;
    badge.tag = 10;
    [row addSubview:badge];

    UILabel *badgeLabel = [[UILabel alloc] init];
    badgeLabel.text = badgeText;
    badgeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    badgeLabel.textColor = UIColor.whiteColor;
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.tag = 11;
    [row addSubview:badgeLabel];

    UILabel *name = [[UILabel alloc] init];
    name.text = title;
    name.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    name.textColor = WKWalletUIColorRGB(0x222222, 1.0);
    name.tag = 1;
    [row addSubview:name];

    UILabel *p = [[UILabel alloc] init];
    p.text = price;
    p.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    p.textColor = WKWalletUIColorRGB(0x888888, 1.0);
    p.tag = 2;
    [row addSubview:p];

    UILabel *c = [[UILabel alloc] init];
    c.text = change;
    c.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    BOOL up = [change hasPrefix:@"+"];
    c.textColor = up ? WKWalletUIColorRGB(0xE53935, 1.0) : WKWalletUIColorRGB(0x43A047, 1.0);
    c.textAlignment = NSTextAlignmentRight;
    c.tag = 3;
    [row addSubview:c];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = WKWalletUIColorRGB(0xE8E8E8, 1.0);
    line.tag = 4;
    [row addSubview:line];

    return row;
}

- (void)layoutMarketRows {
    CGFloat W = self.marketSection.bounds.size.width;
    if (W < 1 || !self.marketSection) {
        return;
    }
    const CGFloat kRowH = 68.0f;
    const CGFloat kTopPad = 0.0f;
    const CGFloat kPadH = 16.0f;
    const CGFloat kIcon = 40.0f;
    const CGFloat kGap = 12.0f;
    const CGFloat textX = kPadH + kIcon + kGap;

    for (NSUInteger i = 0; i < 4; i++) {
        UIView *row = [self.marketSection viewWithTag:9100 + i];
        if (!row) {
            continue;
        }
        row.frame = CGRectMake(0, kTopPad + (CGFloat)i * kRowH, W, kRowH);

        UIView *badge = [row viewWithTag:10];
        UILabel *badgeLabel = [row viewWithTag:11];
        UILabel *name = [row viewWithTag:1];
        UILabel *p = [row viewWithTag:2];
        UILabel *c = [row viewWithTag:3];
        UIView *line = [row viewWithTag:4];

        CGFloat iconY = (kRowH - kIcon) / 2.0f;
        badge.frame = CGRectMake(kPadH, iconY, kIcon, kIcon);
        badgeLabel.frame = badge.frame;

        [c sizeToFit];
        CGFloat changeW = MAX(c.bounds.size.width, 44.0f);
        CGFloat changeX = W - kPadH - changeW;
        c.frame = CGRectMake(changeX, (kRowH - 22.0f) / 2.0f, changeW, 22.0f);

        CGFloat textW = MAX(60.0f, changeX - textX - 8.0f);
        name.frame = CGRectMake(textX, 14.0f, textW, 20.0f);
        p.frame = CGRectMake(textX, 36.0f, textW, 16.0f);

        BOOL isLast = (i == 3);
        line.hidden = isLast;
        line.frame = CGRectMake(kPadH, kRowH - 0.5f, W - kPadH * 2.0f, 0.5f);
    }
}

/// 对齐 {@code activity_wallet.xml} 快捷入口：44dp 圆形底 + 12sp 标签 {@code wallet_action_label}。
- (UIButton *)buildQuickItemWithTitle:(NSString *)title emoji:(NSString *)emoji circleColor:(UIColor *)circleColor action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.clearColor;

    UIView *iconBg = [[UIView alloc] init];
    iconBg.userInteractionEnabled = NO;
    iconBg.backgroundColor = circleColor;
    iconBg.layer.cornerRadius = 22.0f;
    iconBg.layer.masksToBounds = YES;
    iconBg.tag = 501;
    [btn addSubview:iconBg];

    UILabel *emojiL = [[UILabel alloc] init];
    emojiL.text = emoji;
    emojiL.font = [UIFont systemFontOfSize:22];
    emojiL.textAlignment = NSTextAlignmentCenter;
    emojiL.tag = 502;
    [btn addSubview:emojiL];

    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.hidden = YES;
    iconView.tag = 504;
    [btn addSubview:iconView];

    UILabel *t = [[UILabel alloc] init];
    t.text = title;
    t.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    t.textColor = WKWalletUIColorRGB(0x333333, 1.0);
    t.textAlignment = NSTextAlignmentCenter;
    t.tag = 503;
    [btn addSubview:t];

    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    return btn;
}

- (void)layoutQuickItemButtons {
    for (UIButton *btn in @[ self.scanBtn, self.receiveBtn, self.rechargeBtn, self.withdrawBtn ]) {
        UIView *iconBg = [btn viewWithTag:501];
        UILabel *em = [btn viewWithTag:502];
        UIImageView *iconView = [btn viewWithTag:504];
        UILabel *t = [btn viewWithTag:503];
        CGFloat w = btn.bounds.size.width;
        CGFloat h = btn.bounds.size.height;
        if (w < 1) {
            continue;
        }
        const CGFloat kIcon = 44.0f;
        const CGFloat kLabelH = 16.0f;
        const CGFloat kGap = 8.0f;
        CGFloat iconY = 0;
        if (h > kIcon + kGap + kLabelH) {
            iconY = (h - kIcon - kGap - kLabelH) / 2.0f;
        }
        iconBg.frame = CGRectMake((w - kIcon) / 2.0f, iconY, kIcon, kIcon);
        em.frame = iconBg.frame;
        iconView.frame = CGRectInset(iconBg.frame, 10.0f, 10.0f);
        CGFloat labelY = iconY + kIcon + kGap;
        t.frame = CGRectMake(2.0f, labelY, w - 4.0f, kLabelH);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.contentScroll) {
        [self setupScrollContent];
    }
    [self layoutWalletSubviews];
    [self layoutQuickItemButtons];
    [self layoutUsdtBannerSubviews];

    /// 勿将整块 {@code gradientHeader} 提到最前：其高度含与列表叠入区（{@code scrollY = headerTotal - 40}），
    /// 会盖住白色快捷卡片上半截，导致「扫码付 / 收款码 / 充值 / 提币」无法点击。
    /// 返回、标题、设置、余额、小眼睛均在 {@code safeTop + 160} 之上，低于 {@code contentScroll.frame.origin.y}，不会被 scroll 挡住。
}

- (void)onBack {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    UINavigationController *nav = self.navigationController;
    if (nav && nav.viewControllers.count > 1) {
        [nav popViewControllerAnimated:YES];
        return;
    }
    [[WKNavigationManager shared] popViewControllerAnimated:YES];
}

/// 与 Android WalletActivity#showWalletMenu：交易记录、设置/修改支付密码、联系客服（与 onQuickBuyBanner 一致走热线会话，非客服 UID 列表页）。
- (void)onWalletSettingsLegacyMenu {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"交易记录") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self onTransactionRecord];
    }]];

    NSString *pwdTitle = self.hasPassword ? LLang(@"修改支付密码") : LLang(@"设置支付密码");
    [sheet addAction:[UIAlertAction actionWithTitle:pwdTitle style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self onSetPayPassword];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"联系客服") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self onWalletCustomerServiceList];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (UIMenu *)buildWalletSettingsMenu API_AVAILABLE(ios(14.0)) {
    __weak typeof(self) weakSelf = self;
    UIAction *records = [UIAction actionWithTitle:LLang(@"交易记录") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf onTransactionRecord];
    }];
    NSString *pwdTitle = self.hasPassword ? LLang(@"修改支付密码") : LLang(@"设置支付密码");
    UIAction *pwd = [UIAction actionWithTitle:pwdTitle image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf onSetPayPassword];
    }];
    UIAction *cs = [UIAction actionWithTitle:LLang(@"联系客服") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf onWalletCustomerServiceList];
    }];
    return [UIMenu menuWithTitle:@"" children:@[ records, pwd, cs ]];
}

/// 与 Android WalletChatRouter.openOfficialCustomerService / onQuickBuyBanner 一致：POST hotline/visitor/topic/channel 后打开会话。
- (void)onWalletCustomerServiceList {
    [[WKApp shared] invoke:@"show_customer_service" param:self];
}

- (void)toggleBalanceVisible {
    self.balanceVisible = !self.balanceVisible;
    if (self.balanceEyeUsesLoginAssets) {
        self.eyeBtn.selected = self.balanceVisible;
    } else {
        [self.eyeBtn setTitle:(self.balanceVisible ? @"👁" : @"🙈") forState:UIControlStateNormal];
    }
    [self applyBalanceText];
}

- (void)toggleBalanceCurrency {
    if (!self.balanceVisible) {
        return;
    }
    self.balanceShowUsdt = !self.balanceShowUsdt;
    [self applyBalanceText];
}

- (double)computeUsdtEquivalentFromCny {
    if (!isnan(self.cnyPerUsdtRate) && self.cnyPerUsdtRate > 0 && self.cnyBalance >= 0) {
        return self.cnyBalance / self.cnyPerUsdtRate;
    }
    return NAN;
}

- (NSString *)formatUsdt:(double)value {
    if (isnan(value) || isinf(value)) {
        return @"0";
    }
    NSString *s = [NSString stringWithFormat:@"%.6f", value];
    while ([s containsString:@"."] && [s hasSuffix:@"0"]) {
        s = [s substringToIndex:s.length - 1];
    }
    if ([s hasSuffix:@"."]) {
        s = [s substringToIndex:s.length - 1];
    }
    return s;
}

- (void)applyBalanceText {
    if (!self.balanceVisible) {
        self.balanceLineLabel.attributedText = [[NSAttributedString alloc] initWithString:@"******" attributes:@{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:32],
            NSForegroundColorAttributeName: UIColor.whiteColor
        }];
        return;
    }

    NSMutableAttributedString *attr;
    if (self.balanceShowUsdt) {
        double usdt = [self computeUsdtEquivalentFromCny];
        NSString *amount = (isnan(usdt) || isinf(usdt)) ? @"—" : [self formatUsdt:usdt];
        attr = [[NSMutableAttributedString alloc] initWithString:amount attributes:@{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:32],
            NSForegroundColorAttributeName: UIColor.whiteColor
        }];
        /// 与 Android {@code balanceCurrencyTv}：{@code marginStart="10dp"}、{@code marginTop="8dp"}（用空格 + baseline 近似）。
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"  USDT" attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: WKWalletUIColorRGB(0xE8E8FF, 1.0),
            NSBaselineOffsetAttributeName: @6
        }]];
    } else {
        NSString *num = [NSString stringWithFormat:@"¥%.2f", self.cnyBalance];
        attr = [[NSMutableAttributedString alloc] initWithString:num attributes:@{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:32],
            NSForegroundColorAttributeName: UIColor.whiteColor
        }];
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"  CNY" attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: WKWalletUIColorRGB(0xE8E8FF, 1.0),
            NSBaselineOffsetAttributeName: @6
        }]];
    }
    self.balanceLineLabel.attributedText = attr;
}

- (void)loadBalance {
    [[WKWalletAPI shared] getBalanceWithCallback:^(NSDictionary *result, NSError *error) {
        if (result && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *data = [result[@"data"] isKindOfClass:NSDictionary.class] ? result[@"data"] : result;
                self.cnyBalance = [data[@"balance"] doubleValue];
                self.hasPassword = [data[@"has_password"] boolValue];
                [self applyBalanceText];
            });
        }
    }];
}

- (void)loadRechargeChannelsRate {
    [[WKWalletAPI shared] getRechargeChannelsWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !result) {
                self.cnyPerUsdtRate = NAN;
                [self applyBalanceText];
                return;
            }
            NSArray<NSDictionary *> *channels = [WKWalletChannelUtil channelArrayFromAPIResult:result];
            /// 与 Android {@code WalletCnyPerUsdtRates.resolveCnyPerUsdtFromRawList(list, 0)} 一致（CNY 渠道优先、再 U 盾、再其它 CNY）。
            self.cnyPerUsdtRate = [WKWalletChannelUtil resolveCnyPerUsdtFromRawChannelList:channels selectedCnyIndex:0];
            [self applyBalanceText];
        });
    }];
}

- (void)onScan {
    WKScanVC *vc = [WKScanVC new];
    [self wkWalletPush:vc];
}

- (void)onReceive {
    WKWalletReceiveQRVC *vc = [WKWalletReceiveQRVC new];
    [self wkWalletPush:vc];
}

- (void)onRecharge {
    WKRechargeFullVC *vc = [[WKRechargeFullVC alloc] init];
    [self wkWalletPush:vc];
}

/// 与 Android {@code WalletActivity#onQuickBuyBannerClick} 一致：{@code WalletChatRouter.openOfficialCustomerService} → {@code show_customer_service}。
- (void)onQuickBuyBanner {
    [[WKApp shared] invoke:@"show_customer_service" param:self];
}

- (void)onWithdraw {
    WKWithdrawVC *vc = [[WKWithdrawVC alloc] init];
    [self wkWalletPush:vc];
}

- (void)onMarketMore {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:LLang(@"行情") message:LLang(@"更多行情数据由服务端接入后可替换此展示。") preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"好的") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)onSetPayPassword {
    WKSetPayPasswordVC *vc = [[WKSetPayPasswordVC alloc] init];
    vc.changePasswordMode = self.hasPassword;
    [self wkWalletPush:vc];
}

- (void)onTransactionRecord {
    WKTransactionRecordVC *vc = [[WKTransactionRecordVC alloc] init];
    [self wkWalletPush:vc];
}

@end
