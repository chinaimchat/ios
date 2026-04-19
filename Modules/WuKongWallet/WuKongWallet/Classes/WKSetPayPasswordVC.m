#import "WKSetPayPasswordVC.h"
#import "WKWalletAPI.h"

/// 与 Android {@code activity_set_pay_password.xml} / {@link SetPayPasswordActivity} 布局与流程一致。
static CGFloat const kWKPayPwdKeyH = 56.0f;   // TypedValue 56dp
static CGFloat const kWKPayPwdKeyText = 22.0f; // 22sp
static CGFloat const kWKPayPwdHintTop = 60.0f; // hint marginTop 60dp（相对导航栏下缘）
static CGFloat const kWKPayPwdHintToDots = 30.0f; // hint → 密码框 30dp
static CGFloat const kWKPayPwdDotSize = 12.0f; // 圆点 12dp
static CGFloat const kWKPayPwdDotRowSpacing = 20.0f; // 相邻圆点间距（与 margin 10+10 一致）
static CGFloat const kWKPayPwdDotsRowWidth = (6.0f * 12.0f + 5.0f * 20.0f); // 172：6 圆点 + 5 段间距 20（对齐安卓子 View 可视区域）
static CGFloat const kWKPayPwdBoxPadding = 8.0f; // 白框 padding 8dp
static CGFloat const kWKPayPwdBoxOuterLead = 18.0f; // 8dp padding + 10dp 首点左边距（= kWKPayPwdBoxPadding + 10）
static CGFloat const kWKPayPwdBoxW = (kWKPayPwdDotsRowWidth + kWKPayPwdBoxOuterLead * 2.0f); // 208dp
static CGFloat const kWKPayPwdBoxInnerRowH = 32.0f; // 10+12+10 垂直占位
static CGFloat const kWKPayPwdBoxH = (kWKPayPwdBoxPadding * 2.0f + kWKPayPwdBoxInnerRowH); // 48dp
static CGFloat const kWKPayPwdBoxCorner = 6.0f; // bg_pay_password_box corners 6dp
static CGFloat const kWKPayPwdHintFont = 16.0f; // hint 16sp

static inline UIColor *WKPayPwdColorHomeBG(void) {
    return [UIColor colorWithRed:246.0f / 255.0f green:246.0f / 255.0f blue:246.0f / 255.0f alpha:1.0f]; // homeColor #f6f6f6
}
static inline UIColor *WKPayPwdColorHint(void) {
    return [UIColor colorWithRed:49.0f / 255.0f green:49.0f / 255.0f blue:49.0f / 255.0f alpha:1.0f]; // colorDark #313131
}
static inline UIColor *WKPayPwdColorKeyText(void) {
    return [UIColor colorWithRed:51.0f / 255.0f green:51.0f / 255.0f blue:51.0f / 255.0f alpha:1.0f]; // #333333
}
static inline UIColor *WKPayPwdColorDotFill(void) {
    return [UIColor colorWithRed:51.0f / 255.0f green:51.0f / 255.0f blue:51.0f / 255.0f alpha:1.0f];
}
static inline UIColor *WKPayPwdColorBoxStroke(void) {
    return [UIColor colorWithRed:221.0f / 255.0f green:221.0f / 255.0f blue:221.0f / 255.0f alpha:1.0f]; // #DDDDDD
}
static inline UIColor *WKPayPwdColorKeyEmpty(void) {
    return [UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]; // #F5F5F5
}

@interface WKSetPayPasswordVC ()

@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIView *dotsBox;
@property (nonatomic, copy) NSArray<UIView *> *dotViews;
@property (nonatomic, strong) UIStackView *keyboardStack;

@property (nonatomic, strong) NSMutableString *pwdBuffer;

@property (nonatomic, copy, nullable) NSString *firstPassword;
@property (nonatomic, copy, nullable) NSString *oldPasswordForChange;

/// 修改密码：0 原 →1 新 →2 确认；设置密码：1 新 →2 确认（与 Android {@code step} 一致）。
@property (nonatomic, assign) NSInteger flowStep;

@end

@implementation WKSetPayPasswordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = WKPayPwdColorHomeBG();
    self.pwdBuffer = [NSMutableString string];

    self.title = self.changePasswordMode ? LLang(@"修改支付密码") : LLang(@"设置支付密码");

    if (self.changePasswordMode) {
        self.flowStep = 0;
    } else {
        self.flowStep = 1;
    }
    [self buildChrome];
    [self applyHintForCurrentStep];
}

#pragma mark - UI（对齐 Android layout）

- (void)buildChrome {
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.font = [UIFont systemFontOfSize:kWKPayPwdHintFont weight:UIFontWeightRegular];
    self.hintLabel.textColor = WKPayPwdColorHint();
    self.hintLabel.numberOfLines = 0;
    [self.view addSubview:self.hintLabel];

    self.dotsBox = [[UIView alloc] init];
    self.dotsBox.translatesAutoresizingMaskIntoConstraints = NO;
    self.dotsBox.backgroundColor = UIColor.whiteColor;
    self.dotsBox.layer.cornerRadius = kWKPayPwdBoxCorner;
    self.dotsBox.layer.masksToBounds = YES;
    self.dotsBox.layer.borderWidth = 1.0f;
    self.dotsBox.layer.borderColor = WKPayPwdColorBoxStroke().CGColor;
    self.dotsBox.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    [self.view addSubview:self.dotsBox];

    NSMutableArray<UIView *> *dots = [NSMutableArray array];
    UIStackView *row = [[UIStackView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = kWKPayPwdDotRowSpacing;
    row.alignment = UIStackViewAlignmentCenter;
    row.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    // 6 槽位始终占位：从左到右第 1～n 位实心，其余空心（勿用 hidden，否则剩余圆点会挤在一起/不贴左）。
    row.distribution = UIStackViewDistributionEqualSpacing;
    for (NSInteger i = 0; i < 6; i++) {
        UIView *d = [[UIView alloc] init];
        d.translatesAutoresizingMaskIntoConstraints = NO;
        d.layer.masksToBounds = YES;
        [d.widthAnchor constraintEqualToConstant:kWKPayPwdDotSize].active = YES;
        [d.heightAnchor constraintEqualToConstant:kWKPayPwdDotSize].active = YES;
        [dots addObject:d];
        [row addArrangedSubview:d];
    }
    self.dotViews = [dots copy];
    [self.dotsBox addSubview:row];

    NSArray<NSString *> *keys = @[ @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"", @"0", @"\u2190" ];
    self.keyboardStack = [[UIStackView alloc] init];
    self.keyboardStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.keyboardStack.axis = UILayoutConstraintAxisVertical;
    self.keyboardStack.spacing = 0;
    self.keyboardStack.distribution = UIStackViewDistributionFillEqually;
    self.keyboardStack.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.keyboardStack];

    for (NSInteger r = 0; r < 4; r++) {
        UIStackView *line = [[UIStackView alloc] init];
        line.axis = UILayoutConstraintAxisHorizontal;
        line.distribution = UIStackViewDistributionFillEqually;
        line.spacing = 0;
        for (NSInteger c = 0; c < 3; c++) {
            NSInteger idx = r * 3 + c;
            NSString *k = keys[(NSUInteger)idx];
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = idx;
            if (k.length == 0) {
                btn.enabled = NO;
                btn.backgroundColor = WKPayPwdColorKeyEmpty();
            } else if ([k isEqualToString:@"\u2190"]) {
                [btn setTitle:@"\u2190" forState:UIControlStateNormal];
                [btn setTitleColor:WKPayPwdColorKeyText() forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:kWKPayPwdKeyText weight:UIFontWeightRegular];
                [btn addTarget:self action:@selector(onDelete) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [btn setTitle:k forState:UIControlStateNormal];
                [btn setTitleColor:WKPayPwdColorKeyText() forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:kWKPayPwdKeyText weight:UIFontWeightRegular];
                [btn addTarget:self action:@selector(onDigit:) forControlEvents:UIControlEventTouchUpInside];
            }
            [line addArrangedSubview:btn];
            [btn.heightAnchor constraintEqualToConstant:kWKPayPwdKeyH].active = YES;
        }
        [self.keyboardStack addArrangedSubview:line];
    }

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.hintLabel.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor constant:kWKPayPwdHintTop],
        [self.hintLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0f],
        [self.hintLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0f],

        [self.dotsBox.topAnchor constraintEqualToAnchor:self.hintLabel.bottomAnchor constant:kWKPayPwdHintToDots],
        [self.dotsBox.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.dotsBox.widthAnchor constraintEqualToConstant:kWKPayPwdBoxW],
        [self.dotsBox.heightAnchor constraintEqualToConstant:kWKPayPwdBoxH],

        [row.centerXAnchor constraintEqualToAnchor:self.dotsBox.centerXAnchor],
        [row.widthAnchor constraintEqualToConstant:kWKPayPwdDotsRowWidth],
        [row.centerYAnchor constraintEqualToAnchor:self.dotsBox.centerYAnchor],
        [row.heightAnchor constraintEqualToConstant:kWKPayPwdBoxInnerRowH],

        [self.keyboardStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.keyboardStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.keyboardStack.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
    [self updateDots];
}

- (void)wk_applyPayPasswordDot:(UIView *)d filled:(BOOL)filled {
    d.layer.cornerRadius = kWKPayPwdDotSize / 2.0f;
    if (filled) {
        d.backgroundColor = WKPayPwdColorDotFill();
        d.layer.borderWidth = 0;
        d.layer.borderColor = nil;
    } else {
        d.backgroundColor = UIColor.clearColor;
        d.layer.borderWidth = 1.0f;
        d.layer.borderColor = WKPayPwdColorBoxStroke().CGColor;
    }
}

- (void)applyHintForCurrentStep {
    if (self.changePasswordMode) {
        switch (self.flowStep) {
            case 0:
                self.hintLabel.text = LLang(@"请输入原支付密码");
                break;
            case 1:
                self.hintLabel.text = LLang(@"请输入新支付密码");
                break;
            case 2:
                self.hintLabel.text = LLang(@"请确认支付密码");
                break;
            default:
                break;
        }
    } else {
        self.hintLabel.text = self.flowStep == 1 ? LLang(@"请输入新支付密码") : LLang(@"请确认支付密码");
    }
}

- (void)updateDots {
    NSUInteger n = self.pwdBuffer.length;
    [self.dotViews enumerateObjectsUsingBlock:^(UIView *d, NSUInteger idx, BOOL *stop) {
        (void)stop;
        [self wk_applyPayPasswordDot:d filled:(idx < n)];
    }];
}

- (void)clearPasswordInput {
    [self.pwdBuffer setString:@""];
    [self updateDots];
}

#pragma mark - 输入

- (void)onDigit:(UIButton *)btn {
    if (self.pwdBuffer.length >= 6) {
        return;
    }
    NSString *t = [btn titleForState:UIControlStateNormal];
    if (t.length != 1) {
        return;
    }
    [self.pwdBuffer appendString:t];
    [self updateDots];
    if (self.pwdBuffer.length == 6) {
        NSString *p = [self.pwdBuffer copy];
        [self onSixDigits:p];
    }
}

- (void)onDelete {
    if (self.pwdBuffer.length == 0) {
        return;
    }
    [self.pwdBuffer deleteCharactersInRange:NSMakeRange(self.pwdBuffer.length - 1, 1)];
    [self updateDots];
}

- (void)onSixDigits:(NSString *)p {
    if (self.changePasswordMode) {
        [self onPasswordCompleteChange:p];
    } else {
        [self onPasswordCompleteSet:p];
    }
}

/// 与 Android {@code SetPayPasswordActivity} 非 {@code isChange} 分支。
- (void)onPasswordCompleteSet:(NSString *)password {
    if (self.flowStep == 1) {
        self.firstPassword = password;
        self.flowStep = 2;
        [self clearPasswordInput];
        [self applyHintForCurrentStep];
        return;
    }
    if (![self.firstPassword isEqualToString:password]) {
        [WKAlertUtil showMsg:LLang(@"两次密码不一致")];
        self.flowStep = 1;
        self.firstPassword = nil;
        [self clearPasswordInput];
        [self applyHintForCurrentStep];
        return;
    }
    [self submitSetPassword:self.firstPassword];
}

/// 与 Android {@code isChange} 三分支。
- (void)onPasswordCompleteChange:(NSString *)password {
    if (self.flowStep == 0) {
        self.oldPasswordForChange = password;
        self.flowStep = 1;
        [self clearPasswordInput];
        [self applyHintForCurrentStep];
        return;
    }
    if (self.flowStep == 1) {
        self.firstPassword = password;
        self.flowStep = 2;
        [self clearPasswordInput];
        [self applyHintForCurrentStep];
        return;
    }
    if (![self.firstPassword isEqualToString:password]) {
        [WKAlertUtil showMsg:LLang(@"两次密码不一致")];
        self.flowStep = 1;
        self.firstPassword = nil;
        [self clearPasswordInput];
        [self applyHintForCurrentStep];
        return;
    }
    [self submitChangePassword:self.oldPasswordForChange newPassword:self.firstPassword];
}

#pragma mark - 网络

- (void)submitSetPassword:(NSString *)password {
    __weak typeof(self) weakSelf = self;
    [[WKWalletAPI shared] setPayPassword:password callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [WKAlertUtil showMsg:LLang(@"支付密码设置成功")];
                [weakSelf wkPopSelf];
            } else {
                [WKAlertUtil showMsg:error.localizedDescription ?: LLang(@"设置失败")];
                [weakSelf resetSetFlowAfterFailure];
            }
        });
    }];
}

- (void)submitChangePassword:(NSString *)oldP newPassword:(NSString *)newP {
    __weak typeof(self) weakSelf = self;
    [[WKWalletAPI shared] changePayPasswordOld:oldP new:newP callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [WKAlertUtil showMsg:LLang(@"支付密码修改成功")];
                [weakSelf wkPopSelf];
            } else {
                [WKAlertUtil showMsg:error.localizedDescription ?: LLang(@"支付密码错误")];
                [weakSelf resetChangeFlow];
            }
        });
    }];
}

- (void)wkPopSelf {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    }
}

/// 与 Android {@code resetAll} 设置分支。
- (void)resetSetFlowAfterFailure {
    self.firstPassword = nil;
    self.flowStep = 1;
    [self clearPasswordInput];
    [self applyHintForCurrentStep];
}

/// 与 Android {@code resetAll} 修改分支。
- (void)resetChangeFlow {
    self.oldPasswordForChange = nil;
    self.firstPassword = nil;
    self.flowStep = 0;
    [self clearPasswordInput];
    [self applyHintForCurrentStep];
}

@end
