#import "WKSendRedPacketVC.h"
#import "WKRedPacketAPI.h"
#import "WKRedPacketContent.h"
#import "WKQQWalletColors.h"
#import <WuKongIMSDK/WKChannelMemberDB.h>
#import <WuKongBase/WKContactsSelectVC.h>
#import <WuKongBase/WKApp.h>
#import <WuKongBase/WKPayPasswordBottomSheet.h>

/// 只保留数字与一个小数点，避免粘贴「¥222」等导致 doubleValue 为 0。
static double WKSendRedPacketParseAmount(NSString *raw) {
    if (raw.length == 0) {
        return 0;
    }
    NSMutableString *out = [NSMutableString string];
    BOOL sawDot = NO;
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            [out appendFormat:@"%C", c];
        } else if (c == '.' && !sawDot) {
            sawDot = YES;
            [out appendString:@"."];
        }
    }
    return out.length > 0 ? out.doubleValue : 0;
}

@interface WKSendRedPacketVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) WKChannel *channel;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UITextField *countField;
@property (nonatomic, strong) UITextField *remarkField;
@property (nonatomic, strong) UISegmentedControl *typeSegment;
@property (nonatomic, strong) UILabel *amountTitleLabel;
@property (nonatomic, strong) UILabel *totalLabel;
@property (nonatomic, strong) UILabel *exclusiveMemberLabel;
@property (nonatomic, strong) UIButton *exclusiveMemberBtn;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) CAGradientLayer *sendBtnGradient;
@property (nonatomic, strong, nullable) UILabel *groupMemberHintLabel;
@property (nonatomic, strong, nullable) UIView *countSectionTopLine;
@property (nonatomic, strong, nullable) UILabel *countTitleLabel;

@property (nonatomic, copy, nullable) NSString *exclusiveToUid;
@property (nonatomic, copy, nullable) NSString *exclusiveToName;
@property (nonatomic, assign) BOOL isSending;

/// 对齐 Android {@link WalletPayPasswordHelper}：未设置密码时跳转设置，返回后再拉余额并弹出支付密码。
@property (nonatomic, assign) BOOL resumeSendAfterWalletAuxiliary;
/// 忽略乱序/过期的余额接口回调，避免关闭密码面板后再次点击无反应。
@property (nonatomic, assign) NSInteger payPasswordGateSeq;
@property (nonatomic, assign) int stashedPacketType;
@property (nonatomic, assign) double stashedApiTotalAmount;
@property (nonatomic, assign) int stashedCount;
@property (nonatomic, copy) NSString *stashedRemark;
@property (nonatomic, copy, nullable) NSString *stashedToUid;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, strong) UIToolbar *numberInputToolbar;

@end

@implementation WKSendRedPacketVC

- (instancetype)initWithChannel:(WKChannel *)channel {
    if (self = [super init]) {
        self.channel = channel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发红包";
    self.view.backgroundColor = [WKQQWalletColors pageBgWarm];

    [self buildUI];
    [self applyTypeUI];
    [self updateTotal];
    [self refreshSendButtonState];
    [self refreshGroupMemberHint];

    /// 部分机型/输入法下 UIControlEventEditingChanged 不总触发，总金额不刷新；用系统通知兜底。
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTextFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [self setupDismissKeyboardGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshGroupMemberHint];
    if (self.resumeSendAfterWalletAuxiliary
        && (self.navigationController == nil || self.navigationController.topViewController == self)) {
        self.resumeSendAfterWalletAuxiliary = NO;
        self.payPasswordGateSeq += 1;
        NSInteger gateSeq = self.payPasswordGateSeq;
        [self retryPayPasswordGateWithRequestSeq:gateSeq];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    self.view.transform = CGAffineTransformIdentity;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.sendBtnGradient.frame = self.sendBtn.bounds;
}

- (void)refreshGroupMemberHint {
    if (!self.groupMemberHintLabel || self.groupMemberHintLabel.hidden) {
        return;
    }
    WKChannel *group = [[WKChannel alloc] initWith:self.channel.channelId channelType:self.channel.channelType];
    NSArray<WKChannelMember *> *members = [[WKChannelMemberDB shared] getMembersWithChannel:group];
    if (members.count == 0) {
        self.groupMemberHintLabel.text = @"暂未获取到群成员，请返回群聊后再试";
    } else {
        self.groupMemberHintLabel.text = [NSString stringWithFormat:@"本群共%lu人", (unsigned long)members.count];
    }
}

- (void)buildUI {
    CGFloat width = self.view.bounds.size.width;
    CGFloat y = 100;

    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(16, y, width - 32, self.channel.channelType == WK_GROUP ? 354 : 250)];
    self.cardView.backgroundColor = UIColor.whiteColor;
    self.cardView.layer.cornerRadius = 14;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.06;
    self.cardView.layer.shadowRadius = 12;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 4);
    [self.view addSubview:self.cardView];

    CGFloat innerY = 18;

    if (self.channel.channelType == WK_GROUP) {
        self.typeSegment = [[UISegmentedControl alloc] initWithItems:@[@"拼手气", @"普通", @"专属"]];
        self.typeSegment.frame = CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 34);
        self.typeSegment.selectedSegmentIndex = 0;
        [self.typeSegment addTarget:self action:@selector(onTypeChanged) forControlEvents:UIControlEventValueChanged];
        [self.cardView addSubview:self.typeSegment];
        innerY += 50;
    }

    self.amountTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, innerY, 120, 20)];
    self.amountTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.amountTitleLabel.textColor = [UIColor colorWithRed:0.35 green:0.38 blue:0.44 alpha:1.0];
    [self.cardView addSubview:self.amountTitleLabel];
    innerY += 28;

    UILabel *currency = [[UILabel alloc] initWithFrame:CGRectMake(16, innerY + 2, 22, 28)];
    currency.text = @"¥";
    currency.font = [UIFont boldSystemFontOfSize:26];
    currency.textColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:1.0];
    [self.cardView addSubview:currency];

    self.amountField = [[UITextField alloc] initWithFrame:CGRectMake(42, innerY, self.cardView.bounds.size.width - 58, 34)];
    self.amountField.placeholder = @"请输入金额";
    self.amountField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountField.inputAccessoryView = self.numberInputToolbar;
    self.amountField.font = [UIFont boldSystemFontOfSize:28];
    self.amountField.delegate = self;
    [self.amountField addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
    [self.cardView addSubview:self.amountField];
    innerY += 46;

    if (self.channel.channelType == WK_GROUP) {
        self.countSectionTopLine = [[UIView alloc] initWithFrame:CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 0.5)];
        self.countSectionTopLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        [self.cardView addSubview:self.countSectionTopLine];
        innerY += 12;

        self.countTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, innerY, 100, 20)];
        self.countTitleLabel.text = @"红包个数";
        self.countTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.countTitleLabel.textColor = [UIColor colorWithRed:0.35 green:0.38 blue:0.44 alpha:1.0];
        [self.cardView addSubview:self.countTitleLabel];

        self.countField = [[UITextField alloc] initWithFrame:CGRectMake(self.cardView.bounds.size.width - 140, innerY - 6, 120, 32)];
        /// 对齐 Android {@code countEt}：无默认数字，hint 引导；{@code wallet_input_count} 文案为「请输入个数」。
        self.countField.placeholder = @"请输入个数";
        self.countField.text = @"";
        self.countField.textAlignment = NSTextAlignmentRight;
        self.countField.keyboardType = UIKeyboardTypeNumberPad;
        self.countField.inputAccessoryView = self.numberInputToolbar;
        self.countField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.countField.delegate = self;
        [self.countField addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
        [self.cardView addSubview:self.countField];
        innerY += 40;

        self.groupMemberHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 18)];
        self.groupMemberHintLabel.font = [UIFont systemFontOfSize:12];
        self.groupMemberHintLabel.textColor = [UIColor colorWithRed:0.57 green:0.60 blue:0.67 alpha:1.0];
        self.groupMemberHintLabel.numberOfLines = 2;
        [self.cardView addSubview:self.groupMemberHintLabel];
        innerY += 24;

        self.exclusiveMemberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.exclusiveMemberBtn.frame = CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 36);
        self.exclusiveMemberBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.exclusiveMemberBtn setTitleColor:[UIColor colorWithRed:0.93 green:0.30 blue:0.22 alpha:1.0] forState:UIControlStateNormal];
        self.exclusiveMemberBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self.exclusiveMemberBtn setTitle:@"选择专属领取人" forState:UIControlStateNormal];
        [self.exclusiveMemberBtn addTarget:self action:@selector(onSelectExclusiveMember) forControlEvents:UIControlEventTouchUpInside];
        [self.cardView addSubview:self.exclusiveMemberBtn];
        innerY += 42;
    }

    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 0.5)];
    line2.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.cardView addSubview:line2];
    innerY += 12;

    self.remarkField = [[UITextField alloc] initWithFrame:CGRectMake(16, innerY, self.cardView.bounds.size.width - 32, 32)];
    self.remarkField.placeholder = @"恭喜发财，大吉大利";
    self.remarkField.font = [UIFont systemFontOfSize:15];
    self.remarkField.returnKeyType = UIReturnKeyDone;
    self.remarkField.delegate = self;
    [self.remarkField addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
    [self.cardView addSubview:self.remarkField];

    self.totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.cardView.frame) + 14, width - 40, 24)];
    self.totalLabel.font = [UIFont boldSystemFontOfSize:20];
    self.totalLabel.textAlignment = NSTextAlignmentCenter;
    self.totalLabel.textColor = [WKQQWalletColors btnBarEnd];
    [self.view addSubview:self.totalLabel];

    self.sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendBtn.frame = CGRectMake(20, CGRectGetMaxY(self.totalLabel.frame) + 18, width - 40, 50);
    self.sendBtn.layer.cornerRadius = 25;
    self.sendBtn.layer.masksToBounds = YES;
    self.sendBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.sendBtn setTitle:@"塞钱进红包" forState:UIControlStateNormal];
    [self.sendBtn addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendBtn];

    self.sendBtnGradient = [CAGradientLayer layer];
    self.sendBtnGradient.cornerRadius = 25;
    self.sendBtnGradient.startPoint = CGPointMake(0, 0.5);
    self.sendBtnGradient.endPoint = CGPointMake(1, 0.5);
    self.sendBtnGradient.colors = @[ (id)[WKQQWalletColors btnBarStart].CGColor, (id)[WKQQWalletColors btnBarEnd].CGColor ];
    [self.sendBtn.layer insertSublayer:self.sendBtnGradient atIndex:0];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)setupDismissKeyboardGesture {
    self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDismissKeyboard)];
    self.dismissKeyboardTap.cancelsTouchesInView = NO;
    self.dismissKeyboardTap.delegate = self;
    [self.view addGestureRecognizer:self.dismissKeyboardTap];
}

- (void)onTapDismissKeyboard {
    [self.view endEditing:YES];
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

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    if (![info isKindOfClass:[NSDictionary class]]) {
        return;
    }
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    CGRect sendBtnFrame = [self.view convertRect:self.sendBtn.frame fromView:self.sendBtn.superview];
    CGFloat margin = 12.0f;
    CGFloat overlap = CGRectGetMaxY(sendBtnFrame) + margin - kbFrame.origin.y;
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

- (void)onTextFieldTextDidChange:(NSNotification *)note {
    id obj = note.object;
    if (obj != self.amountField && obj != self.countField && obj != self.remarkField) {
        return;
    }
    [self onTextChanged];
}

- (void)onTypeChanged {
    [self applyTypeUI];
    [self updateTotal];
    [self refreshSendButtonState];
}

- (void)applyTypeUI {
    if (self.channel.channelType != WK_GROUP) {
        self.amountTitleLabel.text = @"红包金额";
        return;
    }

    NSInteger seg = self.typeSegment.selectedSegmentIndex;
    BOOL isExclusive = seg == 2;

    if (seg == 0) {
        self.amountTitleLabel.text = @"总金额";
    } else if (seg == 1) {
        self.amountTitleLabel.text = @"单个金额";
    } else {
        self.amountTitleLabel.text = @"红包金额";
    }

    /// 对齐 Android SendRedPacketActivity.applyGroupPacketTypeUi：专属时隐藏个数行与「本群共 N 人」
    BOOL showCountBlock = !isExclusive;
    self.countSectionTopLine.hidden = !showCountBlock;
    self.countTitleLabel.hidden = !showCountBlock;
    self.countField.hidden = !showCountBlock;
    self.groupMemberHintLabel.hidden = isExclusive;
    self.exclusiveMemberBtn.hidden = !isExclusive;
    if (isExclusive) {
        self.countField.text = @"1";
        NSString *myUid = [WKApp shared].loginInfo.uid ?: @"";
        if (myUid.length > 0 && [self.exclusiveToUid isEqualToString:myUid]) {
            self.exclusiveToUid = nil;
            self.exclusiveToName = nil;
            [self.exclusiveMemberBtn setTitle:@"选择专属领取人" forState:UIControlStateNormal];
        }
    } else {
        self.countField.text = @"";
        [self refreshGroupMemberHint];
    }
}

- (void)onTextChanged {
    [self updateTotal];
    [self refreshSendButtonState];
}

- (void)refreshSendButtonState {
    double amount = WKSendRedPacketParseAmount(self.amountField.text);
    BOOL enabled = amount > 0;

    if (self.channel.channelType == WK_GROUP && self.typeSegment.selectedSegmentIndex != 2) {
        int c = [self.countField.text intValue];
        enabled = enabled && c > 0;
    }
    if (self.channel.channelType == WK_GROUP && self.typeSegment.selectedSegmentIndex == 2) {
        enabled = enabled && self.exclusiveToUid.length > 0;
    }

    self.sendBtn.enabled = enabled && !self.isSending;
    self.sendBtnGradient.hidden = !self.sendBtn.enabled;
    self.sendBtn.backgroundColor = self.sendBtn.enabled ? UIColor.clearColor : [UIColor colorWithRed:0.90 green:0.90 blue:0.93 alpha:1.0];
    [self.sendBtn setTitleColor:(self.sendBtn.enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0])
                       forState:UIControlStateNormal];
}

- (void)updateTotal {
    double amount = WKSendRedPacketParseAmount(self.amountField.text);
    double total = amount;

    if (self.channel.channelType == WK_GROUP) {
        NSInteger seg = self.typeSegment.selectedSegmentIndex;
        if (seg == 2) {
            total = amount;
        } else if (seg == 1) {
            /// 普通：底部合计 = 单个金额 × 个数（与 Android computePayTotalAmount TYPE_GROUP_NORMAL 一致）。
            NSString *cs = [self.countField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            int c = cs.length > 0 ? [cs intValue] : 0;
            total = (amount > 0 && c > 0) ? amount * (double)c : 0;
        } else {
            /// 拼手气（seg==0）：底部合计 = 上方「总金额」；个数只影响分包数量，不参与乘法（与 Android TYPE_GROUP_RANDOM 一致）。
            total = amount;
        }
    }

    self.totalLabel.text = [NSString stringWithFormat:@"¥ %.2f", total];
}

- (void)onSelectExclusiveMember {
    if (self.channel.channelType != WK_GROUP) {
        return;
    }

    WKChannel *group = [[WKChannel alloc] initWith:self.channel.channelId channelType:self.channel.channelType];
    NSArray<WKChannelMember *> *members = [[WKChannelMemberDB shared] getMembersWithChannel:group];
    if (members.count == 0) {
        [WKAlertUtil showMsg:@"暂无可选群成员"];
        return;
    }

    NSString *loginUid = [WKApp shared].loginInfo.uid ?: @"";
    NSMutableArray<WKContactsSelect *> *items = [NSMutableArray arrayWithCapacity:members.count];
    for (WKChannelMember *m in members) {
        if (m.memberUid.length == 0) {
            continue;
        }
        /// 与 Android {@link ChooseNormalMembersActivity#resortData} 一致：专属领取人列表不包含当前用户。
        if (loginUid.length > 0 && [m.memberUid isEqualToString:loginUid]) {
            continue;
        }
        WKContactsSelect *c = [WKContactsSelect new];
        c.uid = m.memberUid;
        c.avatar = m.memberAvatar ?: @"";
        NSString *name = m.displayName.length > 0 ? m.displayName : (m.memberName.length > 0 ? m.memberName : m.memberUid);
        c.name = name;
        c.displayName = name;
        c.mode = WKContactsModeSingle;
        [items addObject:c];
    }
    if (items.count == 0) {
        [WKAlertUtil showMsg:@"暂无可选群成员"];
        return;
    }

    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.title = @"选择专属领取人";
    vc.mode = WKContactsModeSingle;
    vc.maxSelectMembers = 1;
    vc.showBack = YES;
    vc.data = items;
    if (self.exclusiveToUid.length > 0 && ![self.exclusiveToUid isEqualToString:loginUid]) {
        vc.selecteds = @[self.exclusiveToUid];
    }

    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> * _Nonnull uids) {
        NSString *uid = uids.firstObject;
        if (uid.length == 0 || [uid isEqualToString:@"all"]) {
            return;
        }
        weakSelf.exclusiveToUid = uid;
        weakSelf.exclusiveToName = uid;
        for (WKContactsSelect *c in items) {
            if ([c.uid isEqualToString:uid]) {
                weakSelf.exclusiveToName = c.displayName.length > 0 ? c.displayName : (c.name.length > 0 ? c.name : uid);
                break;
            }
        }
        [weakSelf.exclusiveMemberBtn setTitle:[NSString stringWithFormat:@"专属领取人：%@", weakSelf.exclusiveToName] forState:UIControlStateNormal];
        [weakSelf refreshSendButtonState];
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    };

    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

- (int)selectedPacketType {
    if (self.channel.channelType != WK_GROUP) {
        return WKRedPacketTypeIndividual;
    }
    NSInteger seg = self.typeSegment.selectedSegmentIndex;
    if (seg == 0) return WKRedPacketTypeGroupRandom;
    if (seg == 1) return WKRedPacketTypeGroupNormal;
    return WKRedPacketTypeExclusive;
}

- (void)onSend {
    if (self.isSending) {
        return;
    }

    double amount = WKSendRedPacketParseAmount(self.amountField.text);
    if (amount <= 0) {
        [WKAlertUtil showMsg:@"请输入金额"];
        return;
    }

    int count = 1;
    if (self.channel.channelType == WK_GROUP) {
        if (self.typeSegment.selectedSegmentIndex != 2) {
            count = [self.countField.text intValue];
            if (count <= 0) {
                [WKAlertUtil showMsg:@"请输入红包个数"];
                return;
            }
        } else {
            if (self.exclusiveToUid.length == 0) {
                [WKAlertUtil showMsg:@"请选择专属领取人"];
                return;
            }
            NSString *myUid = [WKApp shared].loginInfo.uid ?: @"";
            if (myUid.length > 0 && [self.exclusiveToUid isEqualToString:myUid]) {
                [WKAlertUtil showMsg:@"专属红包不能发给自己"];
                return;
            }
            WKChannel *group = [[WKChannel alloc] initWith:self.channel.channelId channelType:self.channel.channelType];
            BOOL exist = [[WKChannelMemberDB shared] exist:group uid:self.exclusiveToUid];
            if (!exist) {
                self.exclusiveToUid = nil;
                self.exclusiveToName = nil;
                [self.exclusiveMemberBtn setTitle:@"选择专属领取人" forState:UIControlStateNormal];
                [self refreshSendButtonState];
                [WKAlertUtil showMsg:@"所选成员已不在群内，请重新选择"];
                return;
            }
            count = 1;
        }
    }

    int type = [self selectedPacketType];
    NSString *remark = self.remarkField.text.length > 0 ? self.remarkField.text : @"恭喜发财，大吉大利";

    double apiTotalAmount = amount;
    if (self.channel.channelType == WK_GROUP && type == WKRedPacketTypeGroupNormal) {
        apiTotalAmount = amount * count;
    }

    NSString *toUid = nil;
    if (self.channel.channelType == WK_GROUP && type == WKRedPacketTypeExclusive) {
        toUid = self.exclusiveToUid;
    }

    self.stashedPacketType = type;
    self.stashedApiTotalAmount = apiTotalAmount;
    self.stashedCount = count;
    self.stashedRemark = remark;
    self.stashedToUid = toUid;

    [[self.view window] endEditing:YES];
    self.payPasswordGateSeq += 1;
    NSInteger gateSeq = self.payPasswordGateSeq;
    __weak typeof(self) weakSelf = self;
    [[WKRedPacketAPI shared] getWalletBalanceSnapshotForPayPasswordGate:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf || gateSeq != weakSelf.payPasswordGateSeq) {
                return;
            }
            if (!result || error) {
                [WKAlertUtil showMsg:error.localizedDescription ?: @"加载失败"];
                return;
            }
            BOOL hasPwd = [result[@"has_password"] boolValue];
            if (!hasPwd) {
                [WKAlertUtil showMsg:@"请先设置支付密码"];
                weakSelf.resumeSendAfterWalletAuxiliary = YES;
                [[WKApp shared] invoke:@"wallet.present_set_pay_password" param:nil];
                return;
            }
            [weakSelf presentAndroidStylePayPasswordSheetAndSend];
        });
    }];
}

- (void)retryPayPasswordGateWithRequestSeq:(NSInteger)gateSeq {
    __weak typeof(self) weakSelf = self;
    [[WKRedPacketAPI shared] getWalletBalanceSnapshotForPayPasswordGate:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf || gateSeq != weakSelf.payPasswordGateSeq) {
                return;
            }
            if (!result || error) {
                return;
            }
            if ([result[@"has_password"] boolValue]) {
                [weakSelf presentAndroidStylePayPasswordSheetAndSend];
            }
        });
    }];
}

/// 与 Android {@link PayPasswordDialog}：仅在此步输入密码；必须先点「塞钱进红包」通过校验才会出现本面板。
- (void)presentAndroidStylePayPasswordSheetAndSend {
    UIWindow *win = [WKPayPasswordBottomSheet resolvedPresentationWindowFromHint:self.view.window];
    if (!win) {
        [WKAlertUtil showMsg:@"无法弹出支付密码"];
        return;
    }
    NSString *remarkLine = [NSString stringWithFormat:@"红包 ¥%.2f", self.stashedApiTotalAmount];
    __weak typeof(self) weakSelf = self;
    WKPayPasswordBottomSheet *sheet = [WKPayPasswordBottomSheet presentWithTitle:@"请输入支付密码"
                                                                        remark:remarkLine
                                                                    hostWindow:win
                                                                    completion:^(NSString *password) {
        [weakSelf doSendWithType:weakSelf.stashedPacketType
                          amount:weakSelf.stashedApiTotalAmount
                           count:weakSelf.stashedCount
                          remark:weakSelf.stashedRemark
                           toUid:weakSelf.stashedToUid
                        password:password];
    } cancelled:nil];
    if (!sheet) {
        [WKAlertUtil showMsg:@"无法弹出支付密码"];
    }
}

- (void)doSendWithType:(int)type
                amount:(double)amount
                 count:(int)count
                remark:(NSString *)remark
                 toUid:(NSString * _Nullable)toUid
              password:(NSString *)password {
    self.isSending = YES;
    [self refreshSendButtonState];

    [[WKRedPacketAPI shared] sendRedPacketType:type
                                     channelId:self.channel.channelId
                                   channelType:self.channel.channelType
                                   totalAmount:amount
                                    totalCount:count
                                         toUid:toUid
                                        remark:remark
                                      password:password
                                      callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isSending = NO;
            [self refreshSendButtonState];

            if (result && !error) {
                /// 与 Android SendRedPacketActivity 一致：仅调发红包接口，会话内红包气泡由服务端下行写入，本机不再 sendMessage。
                [WKAlertUtil showMsg:@"红包发送成功"];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [WKAlertUtil showMsg:error.localizedDescription ?: @"发送失败"];
            }
        });
    }];
}

@end
