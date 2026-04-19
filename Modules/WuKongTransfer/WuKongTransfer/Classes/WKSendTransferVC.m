#import "WKSendTransferVC.h"
#import "WKTransferAPI.h"
#import <WuKongBase/WKApp.h>
#import <WuKongBase/WKContactsSelectVC.h>
#import <WuKongBase/WKPayPasswordBottomSheet.h>
#import <WuKongIMSDK/WKChannelMemberDB.h>

@interface WKSendTransferVC () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *toUid;
@property (nonatomic, copy, nullable) NSString *channelId;
@property (nonatomic, assign) NSInteger channelType;
@property (nonatomic, copy, nullable) NSString *payScene;
@property (nonatomic, assign) BOOL isGroupTransfer;

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) WKUserAvatar *payeeAvatarView;
@property (nonatomic, strong) UILabel *toLabel;
@property (nonatomic, strong) UIButton *selectPayeeBtn;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UITextField *remarkField;
@property (nonatomic, strong) UIButton *sendBtn;

/// 与 Android {@link WalletPayPasswordHelper} + {@link PayPasswordDialog#setRemark} 一致。
@property (nonatomic, assign) BOOL resumeSendAfterWalletAuxiliary;
@property (nonatomic, assign) NSInteger payPasswordGateSeq;
@property (nonatomic, assign) double stashedTransferAmount;
@property (nonatomic, copy) NSString *stashedTransferRemark;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, strong) UIToolbar *numberInputToolbar;

@end

@implementation WKSendTransferVC

- (instancetype)initWithToUid:(NSString *)toUid {
    if (self = [super init]) {
        self.toUid = toUid ?: @"";
        self.channelType = WK_PERSON;
        self.isGroupTransfer = NO;
    }
    return self;
}

- (instancetype)initWithToUid:(NSString *)toUid
                    channelId:(NSString * _Nullable)channelId
                  channelType:(NSInteger)channelType
                     payScene:(NSString * _Nullable)payScene {
    if (self = [super init]) {
        self.toUid = toUid ?: @"";
        self.channelId = channelId;
        self.channelType = channelType > 0 ? channelType : WK_PERSON;
        self.payScene = payScene;
        self.isGroupTransfer = (self.channelType == WK_GROUP);
    }
    return self;
}

- (instancetype)initWithGroupTransferChannel:(WKChannel *)groupChannel {
    if (self = [super init]) {
        self.toUid = @"";
        self.channelId = groupChannel.channelId ?: @"";
        self.channelType = WK_GROUP;
        self.isGroupTransfer = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"转账";
    self.view.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];

    [self buildUI];
    [self refreshPayeeUI];
    [self refreshSendButtonState];
    [self setupDismissKeyboardGesture];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

- (void)buildUI {
    CGFloat width = self.view.bounds.size.width;
    CGFloat cardH = self.isGroupTransfer ? 276 : 240;

    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(16, 100, width - 32, cardH)];
    self.cardView.backgroundColor = UIColor.whiteColor;
    self.cardView.layer.cornerRadius = 14;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOpacity = 0.06;
    self.cardView.layer.shadowRadius = 12;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 4);
    [self.view addSubview:self.cardView];

    self.payeeAvatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(16, 14, 48, 48)];
    self.payeeAvatarView.hidden = YES;
    [self.cardView addSubview:self.payeeAvatarView];

    self.toLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.toLabel.font = [UIFont boldSystemFontOfSize:16];
    self.toLabel.textColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:1.0];
    self.toLabel.numberOfLines = 2;
    [self.cardView addSubview:self.toLabel];

    self.selectPayeeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.selectPayeeBtn.frame = CGRectMake(self.cardView.bounds.size.width - 88, 20, 72, 32);
    [self.selectPayeeBtn setTitle:@"选择" forState:UIControlStateNormal];
    self.selectPayeeBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self.selectPayeeBtn addTarget:self action:@selector(onSelectPayee) forControlEvents:UIControlEventTouchUpInside];
    self.selectPayeeBtn.hidden = !self.isGroupTransfer;
    [self.cardView addSubview:self.selectPayeeBtn];

    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(16, 70, self.cardView.bounds.size.width - 32, 0.5)];
    line1.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.cardView addSubview:line1];

    UILabel *amountTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 86, 90, 22)];
    amountTitle.text = @"转账金额";
    amountTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    amountTitle.textColor = [UIColor colorWithRed:0.35 green:0.38 blue:0.44 alpha:1.0];
    [self.cardView addSubview:amountTitle];

    UILabel *currency = [[UILabel alloc] initWithFrame:CGRectMake(16, 122, 24, 30)];
    currency.text = @"¥";
    currency.font = [UIFont boldSystemFontOfSize:28];
    currency.textColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:1.0];
    [self.cardView addSubview:currency];

    self.amountField = [[UITextField alloc] initWithFrame:CGRectMake(44, 118, self.cardView.bounds.size.width - 60, 36)];
    self.amountField.placeholder = @"请输入金额";
    self.amountField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountField.inputAccessoryView = self.numberInputToolbar;
    self.amountField.font = [UIFont boldSystemFontOfSize:30];
    self.amountField.textColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:1.0];
    self.amountField.delegate = self;
    [self.amountField addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
    [self.cardView addSubview:self.amountField];

    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(16, 166, self.cardView.bounds.size.width - 32, 0.5)];
    line2.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.cardView addSubview:line2];

    self.remarkField = [[UITextField alloc] initWithFrame:CGRectMake(16, 182, self.cardView.bounds.size.width - 32, 32)];
    self.remarkField.placeholder = @"转账说明（可选）";
    self.remarkField.font = [UIFont systemFontOfSize:15];
    self.remarkField.textColor = [UIColor colorWithRed:0.15 green:0.17 blue:0.22 alpha:1.0];
    self.remarkField.returnKeyType = UIReturnKeyDone;
    self.remarkField.delegate = self;
    [self.remarkField addTarget:self action:@selector(onTextChanged) forControlEvents:UIControlEventEditingChanged];
    [self.cardView addSubview:self.remarkField];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.cardView.frame) + 12, width - 40, 20)];
    hint.text = @"请输入正确金额，转账后不可撤销";
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = [UIColor colorWithRed:0.57 green:0.60 blue:0.67 alpha:1.0];
    [self.view addSubview:hint];

    self.sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendBtn.frame = CGRectMake(20, CGRectGetMaxY(self.cardView.frame) + 50, width - 40, 50);
    self.sendBtn.layer.cornerRadius = 25;
    self.sendBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.sendBtn setTitle:@"确认转账" forState:UIControlStateNormal];
    [self.sendBtn addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendBtn];

    [self layoutPayeeRow];
}

- (void)layoutPayeeRow {
    CGFloat cardW = self.cardView.bounds.size.width;
    CGFloat labelRightInset = self.isGroupTransfer ? 88.0f : 16.0f;
    BOOL showAvatar = self.toUid.length > 0;
    self.payeeAvatarView.hidden = !showAvatar;
    CGFloat labelX = showAvatar ? (16.0f + 48.0f + 12.0f) : 16.0f;
    CGFloat labelW = MAX(0.0f, cardW - labelX - labelRightInset);
    self.toLabel.frame = CGRectMake(labelX, 16.0f, labelW, 44.0f);
    if (showAvatar) {
        self.payeeAvatarView.frame = CGRectMake(16.0f, 14.0f, 48.0f, 48.0f);
    }
}

- (NSString *)wk_displayNameFromChannelInfo:(WKChannelInfo *)info {
    if (!info) {
        return @"";
    }
    if (info.displayName.length > 0) {
        return info.displayName;
    }
    if (info.name.length > 0) {
        return info.name;
    }
    return @"";
}

- (void)refreshPayeeUI {
    if (self.isGroupTransfer && self.toUid.length == 0) {
        self.toLabel.text = @"请选择收款人";
        [self layoutPayeeRow];
        return;
    }
    if (self.toUid.length == 0) {
        self.toLabel.text = @"转账给 ";
        [self layoutPayeeRow];
        return;
    }

    self.payeeAvatarView.url = [WKAvatarUtil getAvatar:self.toUid];
    [self layoutPayeeRow];

    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfoOfUser:self.toUid];
    NSString *display = [self wk_displayNameFromChannelInfo:info];
    if (display.length > 0) {
        self.toLabel.text = [NSString stringWithFormat:@"转账给 %@", display];
        return;
    }

    self.toLabel.text = [NSString stringWithFormat:@"转账给 %@", self.toUid];
    __weak typeof(self) weakSelf = self;
    WKChannel *personCh = [WKChannel personWithChannelID:self.toUid];
    [[WKSDK shared].channelManager fetchChannelInfo:personCh completion:^(WKChannelInfo *fetched) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf || weakSelf.toUid.length == 0 || ![weakSelf.toUid isEqualToString:personCh.channelId]) {
                return;
            }
            NSString *name = [weakSelf wk_displayNameFromChannelInfo:fetched];
            if (name.length > 0) {
                weakSelf.toLabel.text = [NSString stringWithFormat:@"转账给 %@", name];
            }
        });
    }];
}

- (void)onSelectPayee {
    if (!self.isGroupTransfer || self.channelId.length == 0) {
        return;
    }
    WKChannel *group = [[WKChannel alloc] initWith:self.channelId channelType:WK_GROUP];
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
        /// 与 Android {@link ChooseNormalMembersActivity#resortData} 一致：群转账收款人列表不包含当前用户。
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
    vc.title = @"选择收款人";
    vc.mode = WKContactsModeSingle;
    vc.maxSelectMembers = 1;
    vc.showBack = YES;
    vc.data = items;
    if (self.toUid.length > 0 && ![self.toUid isEqualToString:loginUid]) {
        vc.selecteds = @[self.toUid];
    }

    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> * _Nonnull uids) {
        NSString *uid = uids.firstObject;
        if (uid.length == 0 || [uid isEqualToString:@"all"]) {
            return;
        }
        weakSelf.toUid = uid;
        [weakSelf refreshPayeeUI];
        [weakSelf refreshSendButtonState];
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    };

    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

- (void)onTextChanged {
    [self refreshSendButtonState];
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
    CGRect sendBtnFrame = [self.view convertRect:self.sendBtn.frame fromView:self.sendBtn.superview];
    CGFloat overlap = CGRectGetMaxY(sendBtnFrame) + 12.0f - kbFrame.origin.y;
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

- (void)refreshSendButtonState {
    double amount = [self.amountField.text doubleValue];
    BOOL enabled = amount > 0;
    if (self.isGroupTransfer) {
        enabled = enabled && self.toUid.length > 0;
    }
    self.sendBtn.enabled = enabled;
    self.sendBtn.backgroundColor = enabled
        ? [UIColor colorWithRed:0.98 green:0.60 blue:0.16 alpha:1.0]
        : [UIColor colorWithRed:0.88 green:0.90 blue:0.94 alpha:1.0];
    [self.sendBtn setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0])
                       forState:UIControlStateNormal];
}

- (void)onSend {
    double amount = [self.amountField.text doubleValue];
    if (amount <= 0) {
        [WKAlertUtil showMsg:@"请输入转账金额"];
        return;
    }
    if (self.isGroupTransfer && self.toUid.length == 0) {
        [WKAlertUtil showMsg:@"请选择收款人"];
        return;
    }
    if (self.isGroupTransfer) {
        NSString *myUid = [WKApp shared].loginInfo.uid ?: @"";
        if (myUid.length > 0 && [self.toUid isEqualToString:myUid]) {
            [WKAlertUtil showMsg:@"不能转账给自己"];
            return;
        }
        WKChannel *group = [[WKChannel alloc] initWith:self.channelId channelType:WK_GROUP];
        if (![[WKChannelMemberDB shared] exist:group uid:self.toUid]) {
            self.toUid = @"";
            [self refreshPayeeUI];
            [self refreshSendButtonState];
            [WKAlertUtil showMsg:@"所选成员已不在群内，请重新选择"];
            return;
        }
    }

    NSString *apiChannelId = self.channelId.length > 0 ? self.channelId : self.toUid;
    if (apiChannelId.length == 0) {
        [WKAlertUtil showMsg:@"加载失败"];
        return;
    }

    NSString *remark = self.remarkField.text ?: @"";
    self.stashedTransferAmount = amount;
    self.stashedTransferRemark = remark;

    [[self.view window] endEditing:YES];
    self.payPasswordGateSeq += 1;
    NSInteger gateSeq = self.payPasswordGateSeq;
    __weak typeof(self) weakSelf = self;
    [[WKTransferAPI shared] getWalletBalanceSnapshotForPayPasswordGate:^(NSDictionary *result, NSError *error) {
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
            [weakSelf presentAndroidStylePayPasswordSheetForTransfer];
        });
    }];
}

- (void)retryPayPasswordGateWithRequestSeq:(NSInteger)gateSeq {
    __weak typeof(self) weakSelf = self;
    [[WKTransferAPI shared] getWalletBalanceSnapshotForPayPasswordGate:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf || gateSeq != weakSelf.payPasswordGateSeq) {
                return;
            }
            if (!result || error) {
                return;
            }
            if ([result[@"has_password"] boolValue]) {
                [weakSelf presentAndroidStylePayPasswordSheetForTransfer];
            }
        });
    }];
}

- (void)presentAndroidStylePayPasswordSheetForTransfer {
    UIWindow *win = [WKPayPasswordBottomSheet resolvedPresentationWindowFromHint:self.view.window];
    if (!win) {
        [WKAlertUtil showMsg:@"无法弹出支付密码"];
        return;
    }
    NSString *remarkLine = [NSString stringWithFormat:@"转账 ¥%.2f", self.stashedTransferAmount];
    __weak typeof(self) weakSelf = self;
    WKPayPasswordBottomSheet *sheet = [WKPayPasswordBottomSheet presentWithTitle:@"请输入支付密码"
                                                                        remark:remarkLine
                                                                    hostWindow:win
                                                                    completion:^(NSString *password) {
        [weakSelf doTransferWithAmount:weakSelf.stashedTransferAmount
                                remark:weakSelf.stashedTransferRemark
                              password:password];
    } cancelled:nil];
    if (!sheet) {
        [WKAlertUtil showMsg:@"无法弹出支付密码"];
    }
}

- (void)doTransferWithAmount:(double)amount remark:(NSString *)remark password:(NSString *)password {
    NSString *apiChannelId = self.channelId;
    if (apiChannelId.length == 0) {
        apiChannelId = self.toUid;
    }

    self.sendBtn.enabled = NO;

    [[WKTransferAPI shared] sendTransferTo:self.toUid
                                    amount:amount
                                    remark:remark
                                  password:password
                                 channelId:apiChannelId
                               channelType:self.channelType
                                  payScene:self.payScene
                                  callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sendBtn.enabled = YES;
            [self refreshSendButtonState];
            if (result && !error) {
                [WKAlertUtil showMsg:@"转账成功"];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [WKAlertUtil showMsg:error.localizedDescription ?: @"转账失败"];
            }
        });
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
