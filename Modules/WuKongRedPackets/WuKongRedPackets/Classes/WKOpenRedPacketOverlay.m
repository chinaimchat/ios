#import "WKOpenRedPacketOverlay.h"
#import "WKRedPacketContent.h"
#import "WKRedPacketAPI.h"
#import "WKRedPacketLocalSync.h"
#import "WKRedPacketDetailVC.h"
#import <WuKongBase/WuKongBase.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface WKOpenRedPacketOverlay ()

@property (nonatomic, copy) NSString *packetNo;
@property (nonatomic, copy) NSString *senderLine;
@property (nonatomic, copy) NSString *remark;
@property (nonatomic, assign) uint32_t clientSeq;
@property (nonatomic, copy) NSString *clientMsgNo;
@property (nonatomic, strong) WKChannel *channel;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, weak) UIButton *openButton;

@end

@implementation WKOpenRedPacketOverlay

- (instancetype)initWithMessage:(WKMessage *)message {
    if (self = [super initWithFrame:CGRectZero]) {
        if ([message.content isKindOfClass:[WKRedPacketContent class]]) {
            WKRedPacketContent *c = (WKRedPacketContent *)message.content;
            self.packetNo = [c.packetNo copy] ?: @"";
            NSString *name = c.senderName.length > 0 ? c.senderName : @"";
            self.senderLine = name.length > 0 ? [NSString stringWithFormat:@"%@的红包", name] : @"红包";
            self.remark = c.remark.length > 0 ? c.remark : @"恭喜发财，大吉大利";
        } else {
            self.packetNo = @"";
            self.senderLine = @"红包";
            self.remark = @"恭喜发财，大吉大利";
        }
        self.clientSeq = message.clientSeq;
        self.clientMsgNo = [message.clientMsgNo copy] ?: @"";
        self.channel = message.channel;
    }
    return self;
}

- (UIWindow *)hostWindow {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) {
                    return w;
                }
            }
            return ws.windows.firstObject;
        }
    }
    UIApplication *app = [UIApplication sharedApplication];
    return app.keyWindow ?: app.windows.firstObject;
}

- (void)present {
    UIWindow *win = [self hostWindow];
    if (!win) {
        return;
    }
    self.frame = win.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    self.alpha = 0;
    [win addSubview:self];

    CGFloat cardW = MIN(320, win.bounds.size.width - 48);
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake((win.bounds.size.width - cardW) / 2, (win.bounds.size.height - 280) / 2, cardW, 260)];
    card.backgroundColor = [UIColor colorWithRed:0.93 green:0.25 blue:0.22 alpha:1.0];
    card.layer.cornerRadius = 16;
    card.layer.masksToBounds = YES;
    card.alpha = 0;
    card.transform = CGAffineTransformMakeScale(0.88, 0.88);
    self.cardView = card;
    [self addSubview:card];

    CAGradientLayer *topSheen = [CAGradientLayer layer];
    topSheen.frame = CGRectMake(0, 0, cardW, 72);
    topSheen.colors = @[ (id)[UIColor colorWithWhite:1 alpha:0.22].CGColor,
                         (id)[UIColor colorWithWhite:1 alpha:0].CGColor ];
    topSheen.startPoint = CGPointMake(0.5, 0);
    topSheen.endPoint = CGPointMake(0.5, 1);
    [card.layer addSublayer:topSheen];

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 28, cardW - 40, 24)];
    titleLbl.textColor = UIColor.whiteColor;
    titleLbl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.text = self.senderLine;
    [card addSubview:titleLbl];

    UILabel *remarkLbl = [[UILabel alloc] initWithFrame:CGRectMake(24, 64, cardW - 48, 72)];
    remarkLbl.textColor = [UIColor colorWithWhite:1 alpha:0.92];
    remarkLbl.font = [UIFont systemFontOfSize:15];
    remarkLbl.textAlignment = NSTextAlignmentCenter;
    remarkLbl.numberOfLines = 3;
    remarkLbl.text = self.remark;
    [card addSubview:remarkLbl];

    UIButton *openBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    openBtn.frame = CGRectMake((cardW - 88) / 2, 160, 88, 88);
    openBtn.layer.cornerRadius = 44;
    openBtn.layer.masksToBounds = YES;
    openBtn.backgroundColor = [UIColor colorWithRed:0.96 green:0.86 blue:0.55 alpha:1.0];
    [openBtn setTitle:@"开" forState:UIControlStateNormal];
    [openBtn setTitleColor:[UIColor colorWithRed:0.55 green:0.10 blue:0.08 alpha:1] forState:UIControlStateNormal];
    openBtn.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    [openBtn addTarget:self action:@selector(onOpen) forControlEvents:UIControlEventTouchUpInside];
    [openBtn addTarget:self action:@selector(onOpenTouchDown) forControlEvents:UIControlEventTouchDown];
    UIControlEvents upEvents = UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchUpInside;
    [openBtn addTarget:self action:@selector(onOpenTouchUp) forControlEvents:upEvents];
    [card addSubview:openBtn];
    self.openButton = openBtn;

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(cardW - 44, 8, 36, 36);
    [closeBtn setTitle:@"×" forState:UIControlStateNormal];
    [closeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    [closeBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:closeBtn];

    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
        card.alpha = 1;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)onOpenTouchDown {
    UIButton *btn = self.openButton;
    if (!btn) {
        return;
    }
    [UIView animateWithDuration:0.08 animations:^{
        btn.transform = CGAffineTransformMakeScale(0.92, 0.92);
    }];
}

- (void)onOpenTouchUp {
    UIButton *btn = self.openButton;
    if (!btn) {
        return;
    }
    [UIView animateWithDuration:0.12 animations:^{
        btn.transform = CGAffineTransformIdentity;
    }];
}

- (void)onClose {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)onOpen {
    if (self.packetNo.length == 0) {
        [self onClose];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[WKRedPacketAPI shared] openRedPacket:self.packetNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong) {
                return;
            }
            if (result && !error) {
                NSInteger st = [WKRedPacketLocalSync localMessageStatusAfterOpenSuccessFromResponse:result];
                [WKRedPacketLocalSync applyOpenedWithStatus:st
                                                   packetNo:selfStrong.packetNo
                                                    channel:selfStrong.channel
                                                  clientSeq:selfStrong.clientSeq
                                                clientMsgNo:selfStrong.clientMsgNo];
                double amt = [WKRedPacketLocalSync resolvedOpenAmountFromResponse:result];
                NSString *toast;
                if (!isnan(amt) && amt > 0) {
                    toast = [NSString stringWithFormat:@"¥%.2f\n已存入钱包", amt];
                } else {
                    toast = @"红包已领取，金额已存入钱包";
                }
                [selfStrong onClose];
                [WKAlertUtil showMsg:toast];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    WKChannel *ch = selfStrong.channel;
                    WKRedPacketDetailVC *vc = (ch.channelId.length > 0)
                        ? [[WKRedPacketDetailVC alloc] initWithPacketNo:selfStrong.packetNo channelId:ch.channelId channelType:ch.channelType]
                        : [[WKRedPacketDetailVC alloc] initWithPacketNo:selfStrong.packetNo];
                    [[WKNavigationManager shared] pushViewController:vc animated:YES];
                });
                [WKRedPacketLocalSync refineWithPacketNo:selfStrong.packetNo
                                                 channel:selfStrong.channel
                                               clientSeq:selfStrong.clientSeq
                                             clientMsgNo:selfStrong.clientMsgNo];
            } else {
                NSString *msg = error.localizedDescription ?: @"领取失败";
                BOOL alreadyClaimedOrFinished = (msg.length > 0 && [msg containsString:@"已领完"]);
                [selfStrong onClose];
                if (alreadyClaimedOrFinished && selfStrong.packetNo.length > 0) {
                    [WKRedPacketLocalSync applyOpenedWithStatus:1
                                                     packetNo:selfStrong.packetNo
                                                      channel:selfStrong.channel
                                                    clientSeq:selfStrong.clientSeq
                                                  clientMsgNo:selfStrong.clientMsgNo];
                    [WKRedPacketLocalSync refineWithPacketNo:selfStrong.packetNo
                                                     channel:selfStrong.channel
                                                   clientSeq:selfStrong.clientSeq
                                                 clientMsgNo:selfStrong.clientMsgNo];
                } else if (msg.length > 0) {
                    [WKAlertUtil showMsg:msg];
                }
                WKChannel *ch = selfStrong.channel;
                WKRedPacketDetailVC *vc = (ch.channelId.length > 0)
                    ? [[WKRedPacketDetailVC alloc] initWithPacketNo:selfStrong.packetNo channelId:ch.channelId channelType:ch.channelType]
                    : [[WKRedPacketDetailVC alloc] initWithPacketNo:selfStrong.packetNo];
                [[WKNavigationManager shared] pushViewController:vc animated:YES];
            }
        });
    }];
}

@end
