#import "WKPayPasswordBottomSheet.h"

@interface WKPayPasswordBottomSheet ()

@property (nonatomic, copy) void (^completionBlock)(NSString *);
@property (nonatomic, copy, nullable) void (^cancelledBlock)(void);
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *remarkLabel;
@property (nonatomic, strong) UIStackView *dotsRow;
@property (nonatomic, strong) NSMutableArray<UIView *> *dotViews;
@property (nonatomic, strong) NSMutableString *passwordBuffer;
@property (nonatomic, weak) UIWindow *hostWindow;
@property (nonatomic, assign) BOOL teardownStarted;

@end

@implementation WKPayPasswordBottomSheet

+ (void)removeAllFromWindow:(UIWindow *)window {
    if (!window) {
        return;
    }
    NSArray<UIView *> *snapshot = [window.subviews copy];
    for (UIView *v in snapshot) {
        if ([v isKindOfClass:[WKPayPasswordBottomSheet class]]) {
            [v removeFromSuperview];
        }
    }
}

+ (UIWindow *)resolvedPresentationWindowFromHint:(UIWindow *)hint {
    if (hint && !hint.hidden && CGRectGetWidth(hint.bounds) > 0 && CGRectGetHeight(hint.bounds) > 0) {
        return hint;
    }
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateUnattached) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow && !w.hidden && CGRectGetWidth(w.bounds) > 0) {
                    return w;
                }
            }
            for (UIWindow *w in ws.windows) {
                if (w.windowLevel == UIWindowLevelNormal && !w.hidden && CGRectGetWidth(w.bounds) > 0) {
                    return w;
                }
            }
        }
    }
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow && !w.hidden) {
            return w;
        }
    }
    return hint;
}

+ (instancetype)presentWithTitle:(NSString *)title
                            remark:(NSString *)remark
                        hostWindow:(UIWindow *)hostWindow
                        completion:(void (^)(NSString *password))completion
                         cancelled:(void (^)(void))cancelled {
    UIWindow *win = [self resolvedPresentationWindowFromHint:hostWindow];
    if (!win) {
        return nil;
    }
    [self removeAllFromWindow:win];
    WKPayPasswordBottomSheet *sheet = [[WKPayPasswordBottomSheet alloc] initWithFrame:win.bounds];
    sheet.hostWindow = win;
    sheet.completionBlock = completion;
    sheet.cancelledBlock = cancelled;
    sheet.passwordBuffer = [NSMutableString string];
    [win addSubview:sheet];
    [sheet buildWithTitle:title remark:remark];
    [sheet animateIn];
    return sheet;
}

- (void)buildWithTitle:(NSString *)title remark:(NSString *)remark {
    self.backgroundColor = UIColor.clearColor;

    self.dimView = [[UIView alloc] init];
    self.dimView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDimTap)];
    [self.dimView addGestureRecognizer:tap];
    [self addSubview:self.dimView];

    self.panel = [[UIView alloc] init];
    self.panel.translatesAutoresizingMaskIntoConstraints = NO;
    self.panel.backgroundColor = UIColor.whiteColor;
    self.panel.layer.cornerRadius = 12.0;
    self.panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.panel.layer.masksToBounds = YES;
    [self addSubview:self.panel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [closeBtn setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    } else {
        [closeBtn setTitle:@"×" forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
    }
    [closeBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setTintColor:[UIColor colorWithWhite:0.2 alpha:1.0]];
    [self.panel addSubview:closeBtn];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.panel addSubview:self.titleLabel];

    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.06];
    [self.panel addSubview:topLine];

    self.remarkLabel = [[UILabel alloc] init];
    self.remarkLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.remarkLabel.text = remark;
    self.remarkLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.remarkLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.remarkLabel.textAlignment = NSTextAlignmentCenter;
    BOOL hasRemark = remark.length > 0;
    self.remarkLabel.hidden = !hasRemark;
    [self.panel addSubview:self.remarkLabel];

    UIView *dotsBox = [[UIView alloc] init];
    dotsBox.translatesAutoresizingMaskIntoConstraints = NO;
    dotsBox.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.0];
    dotsBox.layer.cornerRadius = 8.0;
    dotsBox.layer.borderWidth = 0.5;
    dotsBox.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.08].CGColor;
    dotsBox.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    [self.panel addSubview:dotsBox];

    self.dotsRow = [[UIStackView alloc] init];
    self.dotsRow.translatesAutoresizingMaskIntoConstraints = NO;
    self.dotsRow.axis = UILayoutConstraintAxisHorizontal;
    self.dotsRow.alignment = UIStackViewAlignmentCenter;
    self.dotsRow.distribution = UIStackViewDistributionEqualSpacing;
    self.dotsRow.spacing = 18.0;
    self.dotsRow.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    self.dotViews = [NSMutableArray arrayWithCapacity:6];
    for (NSInteger i = 0; i < 6; i++) {
        UIView *d = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        d.translatesAutoresizingMaskIntoConstraints = NO;
        d.layer.masksToBounds = YES;
        [self.dotsRow addArrangedSubview:d];
        [d.widthAnchor constraintEqualToConstant:12].active = YES;
        [d.heightAnchor constraintEqualToConstant:12].active = YES;
        [self.dotViews addObject:d];
    }
    [dotsBox addSubview:self.dotsRow];

    UIView *sep = [[UIView alloc] init];
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    sep.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.06];
    [self.panel addSubview:sep];

    UIStackView *grid = [[UIStackView alloc] init];
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = 0;
    grid.distribution = UIStackViewDistributionFillEqually;
    grid.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];

    NSArray<NSArray<NSString *> *> *rows = @[
        @[ @"1", @"2", @"3" ],
        @[ @"4", @"5", @"6" ],
        @[ @"7", @"8", @"9" ],
        @[ @"", @"0", @"⌫" ],
    ];
    CGFloat keyH = 56.0;
    for (NSArray<NSString *> *row in rows) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.distribution = UIStackViewDistributionFillEqually;
        rowStack.spacing = 0;
        for (NSString *k in row) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
            b.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
            [b setTitleColor:[UIColor colorWithWhite:0.2 alpha:1.0] forState:UIControlStateNormal];
            b.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
            if (k.length == 0) {
                b.enabled = NO;
                b.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:1.0];
            } else if ([k isEqualToString:@"⌫"]) {
                [b setTitle:@"⌫" forState:UIControlStateNormal];
                [b addTarget:self action:@selector(onDelete) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [b setTitle:k forState:UIControlStateNormal];
                [b addTarget:self action:@selector(onDigit:) forControlEvents:UIControlEventTouchUpInside];
            }
            UIView *cell = [[UIView alloc] init];
            cell.backgroundColor = UIColor.clearColor;
            [cell addSubview:b];
            b.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [b.topAnchor constraintEqualToAnchor:cell.topAnchor],
                [b.bottomAnchor constraintEqualToAnchor:cell.bottomAnchor],
                [b.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor],
                [b.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor],
            ]];
            [rowStack addArrangedSubview:cell];
        }
        [grid addArrangedSubview:rowStack];
        [rowStack.heightAnchor constraintEqualToConstant:keyH].active = YES;
    }
    [self.panel addSubview:grid];

    UILayoutGuide *safe = self.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.dimView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.dimView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.dimView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.dimView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.panel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.panel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.panel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    UILayoutGuide *panelSafe = self.panel.safeAreaLayoutGuide;
    NSMutableArray<NSLayoutConstraint *> *c = [NSMutableArray array];
    [c addObjectsFromArray:@[
        [closeBtn.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:12],
        [closeBtn.topAnchor constraintEqualToAnchor:self.panel.topAnchor constant:14],
        [closeBtn.widthAnchor constraintEqualToConstant:36],
        [closeBtn.heightAnchor constraintEqualToConstant:36],

        [self.titleLabel.centerYAnchor constraintEqualToAnchor:closeBtn.centerYAnchor],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.panel.centerXAnchor],

        [topLine.topAnchor constraintEqualToAnchor:closeBtn.bottomAnchor constant:10],
        [topLine.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [topLine.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [topLine.heightAnchor constraintEqualToConstant:0.5],

        [self.remarkLabel.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:20],
        [self.remarkLabel.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-20],

        [dotsBox.centerXAnchor constraintEqualToAnchor:self.panel.centerXAnchor],
        [dotsBox.heightAnchor constraintEqualToConstant:52],
        [dotsBox.widthAnchor constraintGreaterThanOrEqualToConstant:260],

        [self.dotsRow.leadingAnchor constraintEqualToAnchor:dotsBox.leadingAnchor constant:16],
        [self.dotsRow.trailingAnchor constraintEqualToAnchor:dotsBox.trailingAnchor constant:-16],
        [self.dotsRow.centerYAnchor constraintEqualToAnchor:dotsBox.centerYAnchor],

        [sep.topAnchor constraintEqualToAnchor:dotsBox.bottomAnchor constant:20],
        [sep.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [sep.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [sep.heightAnchor constraintEqualToConstant:0.5],

        [grid.topAnchor constraintEqualToAnchor:sep.bottomAnchor],
        [grid.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [grid.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [grid.bottomAnchor constraintEqualToAnchor:panelSafe.bottomAnchor],
    ]];
    if (hasRemark) {
        [c addObject:[self.remarkLabel.topAnchor constraintEqualToAnchor:topLine.bottomAnchor constant:20]];
        [c addObject:[dotsBox.topAnchor constraintEqualToAnchor:self.remarkLabel.bottomAnchor constant:16]];
    } else {
        [c addObject:[dotsBox.topAnchor constraintEqualToAnchor:topLine.bottomAnchor constant:20]];
    }
    [NSLayoutConstraint activateConstraints:c];
    [self refreshDots];
}

- (void)wk_applyPayPasswordDotView:(UIView *)d filled:(BOOL)filled {
    d.layer.cornerRadius = 6.0;
    if (filled) {
        d.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        d.layer.borderWidth = 0;
        d.layer.borderColor = nil;
    } else {
        d.backgroundColor = UIColor.clearColor;
        d.layer.borderWidth = 1.0;
        d.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.12].CGColor;
    }
}

- (void)animateIn {
    self.dimView.alpha = 0;
    self.panel.transform = CGAffineTransformMakeTranslation(0, 400);
    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dimView.alpha = 1;
        self.panel.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissAnimated:(BOOL)animated {
    if (self.teardownStarted) {
        return;
    }
    self.teardownStarted = YES;
    self.userInteractionEnabled = NO;
    void (^remove)(void) = ^{
        [self removeFromSuperview];
    };
    if (!animated) {
        remove();
        return;
    }
    [UIView animateWithDuration:0.22 animations:^{
        self.dimView.alpha = 0;
        self.panel.transform = CGAffineTransformMakeTranslation(0, 360);
    } completion:^(BOOL f) {
        remove();
    }];
}

- (void)onDimTap {
    if (self.cancelledBlock) {
        self.cancelledBlock();
    }
    [self dismissAnimated:YES];
}

- (void)onClose {
    if (self.cancelledBlock) {
        self.cancelledBlock();
    }
    [self dismissAnimated:YES];
}

- (void)onDelete {
    if (self.passwordBuffer.length > 0) {
        [self.passwordBuffer deleteCharactersInRange:NSMakeRange(self.passwordBuffer.length - 1, 1)];
        [self refreshDots];
    }
}

- (void)onDigit:(UIButton *)sender {
    if (self.passwordBuffer.length >= 6) {
        return;
    }
    NSString *t = sender.currentTitle ?: @"";
    if (t.length != 1) {
        return;
    }
    [self.passwordBuffer appendString:t];
    [self refreshDots];
    if (self.passwordBuffer.length == 6) {
        NSString *pwd = [self.passwordBuffer copy];
        void (^cb)(NSString *) = [self.completionBlock copy];
        [self dismissAnimated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (cb) {
                cb(pwd);
            }
        });
    }
}

- (void)refreshDots {
    NSInteger n = (NSInteger)self.passwordBuffer.length;
    for (NSInteger i = 0; i < 6; i++) {
        [self wk_applyPayPasswordDotView:self.dotViews[i] filled:(i < n)];
    }
}

@end
