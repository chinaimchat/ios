#import "WKRechargeFullVC.h"
#import "WKWalletBuyUsdtNavTransition.h"
#import "WKWalletAPI.h"
#import "WKWalletChannelUtil.h"
#import "WKWalletMaterialTheme.h"

@interface WKRechargeFullVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSArray<NSDictionary *> *uCoinChannels;
@property (nonatomic, copy) NSArray<NSDictionary *> *wxAliChannels;
@property (nonatomic, assign) NSInteger selectedWxIndex;
@property (nonatomic, assign) NSInteger selectedUCoinIndex;
@property (nonatomic, assign) BOOL lastChannelsLoadFailed;
@property (nonatomic, copy) NSString *lastChannelsFailMsg;

@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *emptyContainer;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *retryBtn;

@property (nonatomic, strong) UIView *blockU;
@property (nonatomic, strong) UILabel *blockUTitle;
@property (nonatomic, strong) UIView *uMethodCard;
@property (nonatomic, strong) UIControl *uMethodBar;
@property (nonatomic, strong) UILabel *uMethodLabel;
@property (nonatomic, strong) UILabel *uMethodValue;
@property (nonatomic, strong) UILabel *uMethodChevron;
@property (nonatomic, strong) UIView *uAddrCard;
@property (nonatomic, strong) UILabel *uAddrTitle;
@property (nonatomic, strong) UILabel *uAddrLabel;
@property (nonatomic, strong) UIView *uAmtCard;
@property (nonatomic, strong) UILabel *uAmtTitle;
@property (nonatomic, strong) UILabel *uSym;
@property (nonatomic, strong) UITextField *uAmtField;
@property (nonatomic, strong) UIView *uDivider;
@property (nonatomic, strong) UILabel *uEstimate;

@property (nonatomic, strong) UIView *blockWx;
@property (nonatomic, strong) UILabel *blockWxTitle;
@property (nonatomic, strong) UIView *wxMethodCard;
@property (nonatomic, strong) UIControl *wxMethodBar;
@property (nonatomic, strong) UILabel *wxMethodLabel;
@property (nonatomic, strong) UILabel *wxMethodValue;
@property (nonatomic, strong) UILabel *wxMethodChevron;
@property (nonatomic, strong) UIView *wxAmtCard;
@property (nonatomic, strong) UILabel *wxAmtTitle;
@property (nonatomic, strong) UILabel *wxSym;
@property (nonatomic, strong) UITextField *wxAmtField;
@property (nonatomic, strong) UIView *wxDivider;

@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, strong) UIToolbar *numberInputToolbar;

@end

@implementation WKRechargeFullVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"充值");
    self.view.backgroundColor = [WKWalletMaterialTheme rechargePageBg];
    self.selectedWxIndex = 0;
    self.selectedUCoinIndex = 0;
    self.uCoinChannels = @[];
    self.wxAliChannels = @[];

    self.scroll = [[UIScrollView alloc] init];
    self.scroll.alwaysBounceVertical = YES;
    [self.view addSubview:self.scroll];

    [self buildEmpty];
    [self buildBlockU];
    [self buildBlockWx];
    [self buildConfirm];

    [self showLoadingEmpty];
    [self loadChannels];
    self.uAmtField.delegate = self;
    self.wxAmtField.delegate = self;
    self.uAmtField.inputAccessoryView = self.numberInputToolbar;
    self.wxAmtField.inputAccessoryView = self.numberInputToolbar;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = [self getNavBottom];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat pad = 16;
    CGFloat bottomInset = self.view.safeAreaInsets.bottom + 64;
    self.scroll.frame = CGRectMake(0, top, w, h - top);

    CGFloat y = 12;
    CGFloat inner = w - pad * 2;

    BOOL hasWx = self.wxAliChannels.count > 0;
    BOOL hasU = self.uCoinChannels.count > 0;
    BOOL showEmpty = !hasWx && !hasU;

    self.emptyContainer.hidden = !showEmpty;
    self.blockU.hidden = !hasU;
    self.blockWx.hidden = !hasWx;
    self.confirmBtn.hidden = showEmpty;

    if (showEmpty) {
        self.emptyContainer.frame = CGRectMake(pad, y, inner, 160);
        self.emptyLabel.frame = CGRectMake(8, 24, inner - 16, 72);
        self.retryBtn.frame = CGRectMake((inner - 120) / 2.0, 110, 120, 40);
        y += 180;
    }

    if (hasU) {
        self.blockU.frame = CGRectMake(0, y, w, 400);
        CGFloat by = 0;
        self.blockUTitle.frame = CGRectMake(pad + 4, by, inner - 8, 18);
        by += 26;
        if (!self.uMethodCard.hidden) {
            self.uMethodCard.frame = CGRectMake(pad, by, inner, 52);
            self.uMethodBar.frame = self.uMethodCard.bounds;
            self.uMethodLabel.frame = CGRectMake(14, 0, 80, 52);
            self.uMethodValue.frame = CGRectMake(100, 0, inner - 130, 52);
            self.uMethodChevron.frame = CGRectMake(inner - 28, 16, 18, 20);
            by += 60;
        }
        CGFloat addrH = [self textHeight:self.uAddrLabel.text width:inner - 28 font:self.uAddrLabel.font] + 36;
        self.uAddrCard.frame = CGRectMake(pad, by, inner, MAX(addrH, 72));
        self.uAddrTitle.frame = CGRectMake(14, 12, inner - 28, 16);
        self.uAddrLabel.frame = CGRectMake(14, 32, inner - 28, MAX(addrH - 36, 36));
        by += CGRectGetHeight(self.uAddrCard.frame) + 8;

        self.uAmtCard.frame = CGRectMake(pad, by, inner, 120);
        self.uAmtTitle.frame = CGRectMake(14, 12, inner - 28, 16);
        self.uSym.frame = CGRectMake(14, 44, 20, 28);
        self.uAmtField.frame = CGRectMake(38, 40, inner - 52, 36);
        self.uDivider.frame = CGRectMake(14, 86, inner - 28, 1);
        self.uEstimate.frame = CGRectMake(14, 94, inner - 28, 22);
        by += 128;

        CGRect bf = self.blockU.frame;
        bf.size.height = by + 8;
        self.blockU.frame = bf;
        y += by + 16;
    }

    if (hasWx) {
        self.blockWx.frame = CGRectMake(0, y, w, 280);
        CGFloat by = 0;
        self.blockWxTitle.frame = CGRectMake(pad + 4, by, inner - 8, 18);
        by += 26;
        self.wxMethodCard.frame = CGRectMake(pad, by, inner, 52);
        self.wxMethodBar.frame = self.wxMethodCard.bounds;
        self.wxMethodLabel.frame = CGRectMake(14, 0, 80, 52);
        self.wxMethodValue.frame = CGRectMake(100, 0, inner - 130, 52);
        self.wxMethodChevron.frame = CGRectMake(inner - 28, 16, 18, 20);
        by += 60;
        self.wxAmtCard.frame = CGRectMake(pad, by, inner, 100);
        self.wxAmtTitle.frame = CGRectMake(14, 12, inner - 28, 16);
        self.wxSym.frame = CGRectMake(14, 44, 20, 28);
        self.wxAmtField.frame = CGRectMake(38, 40, inner - 52, 36);
        self.wxDivider.frame = CGRectMake(14, 86, inner - 28, 1);
        by += 108;
        CGRect bf = self.blockWx.frame;
        bf.size.height = by + 8;
        self.blockWx.frame = bf;
        y += by + 8;
    }

    self.scroll.contentSize = CGSizeMake(w, y + bottomInset);
    self.confirmBtn.frame = CGRectMake(pad, h - bottomInset + 8, inner, 48);
}

- (CGFloat)textHeight:(NSString *)text width:(CGFloat)width font:(UIFont *)font {
    if (text.length == 0) {
        return 0;
    }
    CGSize s = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{ NSFontAttributeName: font }
                                  context:nil].size;
    return ceil(s.height);
}

- (void)styleMaterialCard:(UIView *)v {
    v.backgroundColor = UIColor.whiteColor;
    v.layer.cornerRadius = 12;
    v.layer.borderWidth = 0.5;
    v.layer.borderColor = [WKWalletMaterialTheme rechargeDivider].CGColor;
    v.layer.shadowColor = UIColor.blackColor.CGColor;
    v.layer.shadowOpacity = 0.06;
    v.layer.shadowOffset = CGSizeMake(0, 1);
    v.layer.shadowRadius = 3;
}

- (void)buildEmpty {
    self.emptyContainer = [[UIView alloc] init];
    [self.scroll addSubview:self.emptyContainer];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:13];
    self.emptyLabel.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.emptyContainer addSubview:self.emptyLabel];

    self.retryBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.retryBtn setTitle:LLang(@"点击重试") forState:UIControlStateNormal];
    [self.retryBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.retryBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.48 blue:0.95 alpha:1];
    self.retryBtn.layer.cornerRadius = 8;
    [self.retryBtn addTarget:self action:@selector(loadChannels) forControlEvents:UIControlEventTouchUpInside];
    [self.emptyContainer addSubview:self.retryBtn];
}

- (void)buildBlockU {
    self.blockU = [[UIView alloc] init];
    [self.scroll addSubview:self.blockU];

    self.blockUTitle = [self sectionTitle:LLang(@"U 币（链上）")];
    [self.blockU addSubview:self.blockUTitle];

    self.uMethodCard = [[UIView alloc] init];
    [self styleMaterialCard:self.uMethodCard];
    [self.blockU addSubview:self.uMethodCard];

    self.uMethodBar = [[UIControl alloc] init];
    [self.uMethodBar addTarget:self action:@selector(onPickUCoin) forControlEvents:UIControlEventTouchUpInside];
    [self.uMethodCard addSubview:self.uMethodBar];

    self.uMethodLabel = [[UILabel alloc] init];
    self.uMethodLabel.text = LLang(@"充值方式");
    self.uMethodLabel.font = [UIFont systemFontOfSize:13];
    self.uMethodLabel.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.uMethodBar addSubview:self.uMethodLabel];

    self.uMethodValue = [[UILabel alloc] init];
    self.uMethodValue.font = [UIFont systemFontOfSize:15];
    self.uMethodValue.textColor = [WKWalletMaterialTheme rechargeTextMain];
    self.uMethodValue.textAlignment = NSTextAlignmentRight;
    self.uMethodValue.numberOfLines = 2;
    [self.uMethodBar addSubview:self.uMethodValue];

    self.uMethodChevron = [[UILabel alloc] init];
    self.uMethodChevron.text = @"›";
    self.uMethodChevron.font = [UIFont systemFontOfSize:20];
    self.uMethodChevron.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.uMethodBar addSubview:self.uMethodChevron];

    self.uAddrCard = [[UIView alloc] init];
    [self styleMaterialCard:self.uAddrCard];
    [self.blockU addSubview:self.uAddrCard];

    self.uAddrTitle = [[UILabel alloc] init];
    self.uAddrTitle.font = [UIFont systemFontOfSize:12];
    self.uAddrTitle.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.uAddrCard addSubview:self.uAddrTitle];

    self.uAddrLabel = [[UILabel alloc] init];
    self.uAddrLabel.numberOfLines = 0;
    self.uAddrLabel.font = [UIFont systemFontOfSize:14];
    self.uAddrLabel.textColor = [WKWalletMaterialTheme rechargeTextMain];
    [self.uAddrCard addSubview:self.uAddrLabel];

    self.uAmtCard = [[UIView alloc] init];
    [self styleMaterialCard:self.uAmtCard];
    [self.blockU addSubview:self.uAmtCard];

    self.uAmtTitle = [[UILabel alloc] init];
    self.uAmtTitle.text = LLang(@"充值数量（U）");
    self.uAmtTitle.font = [UIFont systemFontOfSize:12];
    self.uAmtTitle.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.uAmtCard addSubview:self.uAmtTitle];

    self.uSym = [[UILabel alloc] init];
    self.uSym.text = @"$";
    self.uSym.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.uSym.textColor = [WKWalletMaterialTheme rechargeTextMain];
    [self.uAmtCard addSubview:self.uSym];

    self.uAmtField = [[UITextField alloc] init];
    self.uAmtField.placeholder = @"0.00";
    self.uAmtField.keyboardType = UIKeyboardTypeDecimalPad;
    self.uAmtField.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.uAmtField.textColor = [WKWalletMaterialTheme rechargeTextMain];
    [self.uAmtField addTarget:self action:@selector(onUCoinAmountEdit) forControlEvents:UIControlEventEditingChanged];
    [self.uAmtCard addSubview:self.uAmtField];

    self.uDivider = [[UIView alloc] init];
    self.uDivider.backgroundColor = [WKWalletMaterialTheme rechargeDivider];
    [self.uAmtCard addSubview:self.uDivider];

    self.uEstimate = [[UILabel alloc] init];
    self.uEstimate.font = [UIFont systemFontOfSize:11];
    self.uEstimate.textColor = [WKWalletMaterialTheme rechargeTextSub];
    self.uEstimate.numberOfLines = 0;
    self.uEstimate.hidden = YES;
    [self.uAmtCard addSubview:self.uEstimate];
}

- (void)buildBlockWx {
    self.blockWx = [[UIView alloc] init];
    [self.scroll addSubview:self.blockWx];

    self.blockWxTitle = [self sectionTitle:LLang(@"微信 / 支付宝")];
    [self.blockWx addSubview:self.blockWxTitle];

    self.wxMethodCard = [[UIView alloc] init];
    [self styleMaterialCard:self.wxMethodCard];
    [self.blockWx addSubview:self.wxMethodCard];

    self.wxMethodBar = [[UIControl alloc] init];
    [self.wxMethodBar addTarget:self action:@selector(onPickWx) forControlEvents:UIControlEventTouchUpInside];
    [self.wxMethodCard addSubview:self.wxMethodBar];

    self.wxMethodLabel = [[UILabel alloc] init];
    self.wxMethodLabel.text = LLang(@"充值方式");
    self.wxMethodLabel.font = [UIFont systemFontOfSize:13];
    self.wxMethodLabel.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.wxMethodBar addSubview:self.wxMethodLabel];

    self.wxMethodValue = [[UILabel alloc] init];
    self.wxMethodValue.font = [UIFont systemFontOfSize:15];
    self.wxMethodValue.textColor = [WKWalletMaterialTheme rechargeTextMain];
    self.wxMethodValue.textAlignment = NSTextAlignmentRight;
    self.wxMethodValue.numberOfLines = 2;
    [self.wxMethodBar addSubview:self.wxMethodValue];

    self.wxMethodChevron = [[UILabel alloc] init];
    self.wxMethodChevron.text = @"›";
    self.wxMethodChevron.font = [UIFont systemFontOfSize:20];
    self.wxMethodChevron.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.wxMethodBar addSubview:self.wxMethodChevron];

    self.wxAmtCard = [[UIView alloc] init];
    [self styleMaterialCard:self.wxAmtCard];
    [self.blockWx addSubview:self.wxAmtCard];

    self.wxAmtTitle = [[UILabel alloc] init];
    self.wxAmtTitle.text = LLang(@"充值金额（元）");
    self.wxAmtTitle.font = [UIFont systemFontOfSize:12];
    self.wxAmtTitle.textColor = [WKWalletMaterialTheme rechargeTextSub];
    [self.wxAmtCard addSubview:self.wxAmtTitle];

    self.wxSym = [[UILabel alloc] init];
    self.wxSym.text = @"¥";
    self.wxSym.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.wxSym.textColor = [WKWalletMaterialTheme rechargeTextMain];
    [self.wxAmtCard addSubview:self.wxSym];

    self.wxAmtField = [[UITextField alloc] init];
    self.wxAmtField.placeholder = @"0.00";
    self.wxAmtField.keyboardType = UIKeyboardTypeDecimalPad;
    self.wxAmtField.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.wxAmtField.textColor = [WKWalletMaterialTheme rechargeTextMain];
    [self.wxAmtCard addSubview:self.wxAmtField];

    self.wxDivider = [[UIView alloc] init];
    self.wxDivider.backgroundColor = [WKWalletMaterialTheme rechargeDivider];
    [self.wxAmtCard addSubview:self.wxDivider];
}

- (UILabel *)sectionTitle:(NSString *)t {
    UILabel *l = [[UILabel alloc] init];
    l.text = t;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = [WKWalletMaterialTheme rechargeTextSub];
    return l;
}

- (void)buildConfirm {
    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmBtn setTitle:LLang(@"确认充值") forState:UIControlStateNormal];
    [self.confirmBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.confirmBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.48 blue:0.95 alpha:1];
    self.confirmBtn.layer.cornerRadius = 10;
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.confirmBtn addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmBtn];
}

- (void)showLoadingEmpty {
    self.emptyContainer.hidden = NO;
    self.emptyLabel.text = LLang(@"正在加载充值配置…");
    self.retryBtn.hidden = YES;
    self.blockU.hidden = YES;
    self.blockWx.hidden = YES;
    self.confirmBtn.hidden = YES;
}

- (void)loadChannels {
    self.lastChannelsLoadFailed = NO;
    self.lastChannelsFailMsg = nil;
    [[WKWalletAPI shared] getRechargeChannelsWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *u = [NSMutableArray array];
            NSMutableArray *wx = [NSMutableArray array];
            if (error) {
                self.lastChannelsLoadFailed = YES;
                self.lastChannelsFailMsg = error.localizedDescription;
            } else {
                NSArray *raw = [WKWalletChannelUtil channelArrayFromAPIResult:result];
                for (NSDictionary *c in raw) {
                    if (![WKWalletChannelUtil channelIsEnabled:c]) {
                        continue;
                    }
                    if ([WKWalletChannelUtil channelPayType:c] == 4) {
                        [u addObject:c];
                    } else {
                        [wx addObject:c];
                    }
                }
            }
            self.uCoinChannels = u;
            self.wxAliChannels = wx;
            [self applyChannelDataToUi];
        });
    }];
}

- (void)applyChannelDataToUi {
    BOOL hasWx = self.wxAliChannels.count > 0;
    BOOL hasU = self.uCoinChannels.count > 0;

    if (!hasWx && !hasU) {
        self.emptyContainer.hidden = NO;
        self.retryBtn.hidden = NO;
        self.blockU.hidden = YES;
        self.blockWx.hidden = YES;
        self.confirmBtn.hidden = YES;
        if (self.lastChannelsLoadFailed) {
            NSString *d = self.lastChannelsFailMsg.length ? self.lastChannelsFailMsg : LLang(@"加载失败");
            self.emptyLabel.text = [NSString stringWithFormat:@"%@\n\n%@", d, LLang(@"请检查网络或稍后重试")];
        } else {
            self.emptyLabel.text = LLang(@"暂无可用的充值渠道，请联系客服或稍后再试");
        }
        [self.view setNeedsLayout];
        return;
    }

    self.emptyContainer.hidden = YES;
    self.confirmBtn.hidden = NO;

    if (hasU) {
        self.selectedUCoinIndex = MAX(0, MIN(self.selectedUCoinIndex, (NSInteger)self.uCoinChannels.count - 1));
        BOOL uMulti = self.uCoinChannels.count > 1;
        self.uMethodCard.hidden = !uMulti;
        self.uMethodChevron.hidden = !uMulti;
        self.uMethodBar.userInteractionEnabled = uMulti;
        [self updateUCoinAddressAndMethod];
        [self onUCoinAmountEdit];
    }

    if (hasWx) {
        self.selectedWxIndex = MAX(0, MIN(self.selectedWxIndex, (NSInteger)self.wxAliChannels.count - 1));
        BOOL wxMulti = self.wxAliChannels.count > 1;
        self.wxMethodChevron.hidden = !wxMulti;
        self.wxMethodBar.userInteractionEnabled = wxMulti;
        [self updateWxMethodSummary];
    }

    [self.view setNeedsLayout];
}

- (NSDictionary *)currentUCoin {
    if (self.uCoinChannels.count == 0) {
        return nil;
    }
    return self.uCoinChannels[(NSUInteger)self.selectedUCoinIndex];
}

- (NSDictionary *)currentWx {
    if (self.wxAliChannels.count == 0) {
        return nil;
    }
    return self.wxAliChannels[(NSUInteger)self.selectedWxIndex];
}

- (void)updateUCoinAddressAndMethod {
    NSDictionary *ch = [self currentUCoin];
    self.uMethodValue.text = ch ? [self formatChannelLine:ch] : @"";
    NSString *addr = ch ? [WKWalletChannelUtil channelDepositAddress:ch] : @"";
    self.uAddrTitle.text = LLang(@"收款地址（请仔细核对网络）");
    self.uAddrLabel.text = addr.length ? addr : LLang(@"（暂无地址，请更换方式或联系客服）");
}

- (void)updateWxMethodSummary {
    NSDictionary *ch = [self currentWx];
    self.wxMethodValue.text = ch ? [self formatChannelLine:ch] : @"";
}

- (NSString *)formatChannelLine:(NSDictionary *)ch {
    NSString *display = [WKWalletChannelUtil channelDisplayName:ch];
    NSString *payType = @"";
    id pt = ch[@"pay_type_name"] ?: ch[@"payTypeName"];
    if ([pt isKindOfClass:[NSString class]] && [(NSString *)pt length]) {
        payType = (NSString *)pt;
    }
    if (payType.length) {
        return [NSString stringWithFormat:@"%@（%@）", display, payType];
    }
    return display;
}

- (void)onPickUCoin {
    if (self.uCoinChannels.count <= 1) {
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:LLang(@"选择 U 币渠道") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self.uCoinChannels enumerateObjectsUsingBlock:^(NSDictionary *ch, NSUInteger idx, BOOL *stop) {
        [ac addAction:[UIAlertAction actionWithTitle:[WKWalletChannelUtil channelDisplayName:ch] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            self.selectedUCoinIndex = (NSInteger)idx;
            [self updateUCoinAddressAndMethod];
            [self onUCoinAmountEdit];
        }]];
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onPickWx {
    if (self.wxAliChannels.count <= 1) {
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:LLang(@"选择充值方式") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [self.wxAliChannels enumerateObjectsUsingBlock:^(NSDictionary *ch, NSUInteger idx, BOOL *stop) {
        [ac addAction:[UIAlertAction actionWithTitle:[WKWalletChannelUtil channelDisplayName:ch] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            self.selectedWxIndex = (NSInteger)idx;
            [self updateWxMethodSummary];
        }]];
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onUCoinAmountEdit {
    NSDictionary *ch = [self currentUCoin];
    double rate = ch ? [WKWalletChannelUtil channelUcoinCnyPerU:ch] : 0;
    NSString *raw = [[self.uAmtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    double u = [raw doubleValue];
    if (rate > 0 && !isnan(rate) && u > 0 && !isnan(u)) {
        self.uEstimate.text = [NSString stringWithFormat:LLang(@"预计到账约 ¥%.2f（仅供参考）"), u * rate];
        self.uEstimate.hidden = NO;
    } else {
        self.uEstimate.hidden = YES;
    }
    [self.view setNeedsLayout];
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

- (void)onConfirm {
    BOOL hasWx = self.wxAliChannels.count > 0;
    BOOL hasU = self.uCoinChannels.count > 0;
    NSString *wxRaw = [[self.wxAmtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    NSString *uRaw = [[self.uAmtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
    BOOL wxFilled = wxRaw.length > 0;
    BOOL uFilled = uRaw.length > 0;

    if (hasWx && !hasU) {
        if (!wxFilled) {
            [self alert:LLang(@"请输入金额")];
            return;
        }
        [self submitAmountStr:wxRaw channel:[self currentWx]];
        return;
    }
    if (!hasWx && hasU) {
        if (!uFilled) {
            [self alert:LLang(@"请输入金额")];
            return;
        }
        [self submitAmountStr:uRaw channel:[self currentUCoin]];
        return;
    }
    if (wxFilled && uFilled) {
        [self alert:LLang(@"请只填写一种方式的金额")];
        return;
    }
    if (wxFilled) {
        [self submitAmountStr:wxRaw channel:[self currentWx]];
    } else if (uFilled) {
        [self submitAmountStr:uRaw channel:[self currentUCoin]];
    } else {
        [self alert:LLang(@"请输入金额")];
    }
}

- (void)submitAmountStr:(NSString *)amountStr channel:(NSDictionary *)ch {
    if (!ch) {
        [self alert:LLang(@"未选择有效渠道")];
        return;
    }
    double a = [amountStr doubleValue];
    if (a <= 0 || isnan(a)) {
        [self alert:LLang(@"请输入有效金额")];
        return;
    }
    long long cid = [WKWalletChannelUtil channelId:ch];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"channel_id"] = @(cid);
    BOOL uShield = [WKWalletChannelUtil channelPayType:ch] == 4;
    if (uShield) {
        body[@"amount_u"] = @(a);
        body[@"remark"] = @"";
        body[@"proof_url"] = @"";
    } else {
        body[@"amount"] = @(a);
        body[@"remark"] = @"";
    }

    self.confirmBtn.enabled = NO;
    [[WKWalletAPI shared] rechargeApplyWithBody:body callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.confirmBtn.enabled = YES;
            if (error) {
                [self alert:error.localizedDescription ?: LLang(@"网络错误")];
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
                [self alert:msg.length ? msg : LLang(@"提交失败")];
                return;
            }
            UIAlertController *ok = [UIAlertController alertControllerWithTitle:LLang(@"提交成功") message:msg preferredStyle:UIAlertControllerStyleAlert];
            [ok addAction:[UIAlertAction actionWithTitle:LLang(@"好的") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
                self.wxAmtField.text = @"";
                self.uAmtField.text = @"";
                [WKWalletBuyUsdtNavTransition pushOrderListOnNavigationController:self.navigationController];
            }]];
            [self presentViewController:ok animated:YES completion:nil];
        });
    }];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
