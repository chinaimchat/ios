#import "WKRedPacketCell.h"
#import "WKRedPacketContent.h"
#import "WKRedPacketDetailVC.h"
#import "WKOpenRedPacketOverlay.h"
#import "WKQQWalletColors.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

@interface WKRedPacketCell ()

@property (nonatomic, strong) UIView *faceView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *remarkLabel;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic, strong) UILabel *typeLabel;

@end

@implementation WKRedPacketCell

+ (BOOL)hiddenBubble {
    return YES;
}

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    return CGSizeMake(252, 118);
}

- (void)initUI {
    [super initUI];

    // 与 WKTransferCell 一致：单卡片根视图 + Auto Layout 锚定到 messageContentView（避免双层仅宽高约束在 lim_ 父视图下歧义，导致渐变 bounds 为 0、首屏近乎透明）。
    self.faceView = [[UIView alloc] init];
    self.faceView.backgroundColor = UIColor.clearColor;
    self.faceView.layer.cornerRadius = 12;
    self.faceView.layer.masksToBounds = YES;
    self.faceView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContentView addSubview:self.faceView];

    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    [self.faceView.layer insertSublayer:self.gradientLayer atIndex:0];

    self.iconView = [[UIImageView alloc] init];
    self.iconView.image = [UIImage systemImageNamed:@"giftcard.fill"];
    self.iconView.tintColor = [UIColor whiteColor];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.faceView addSubview:self.iconView];

    self.remarkLabel = [[UILabel alloc] init];
    self.remarkLabel.font = [UIFont systemFontOfSize:15];
    self.remarkLabel.numberOfLines = 2;
    self.remarkLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.faceView addSubview:self.remarkLabel];

    self.dividerView = [[UIView alloc] init];
    self.dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.faceView addSubview:self.dividerView];

    self.typeLabel = [[UILabel alloc] init];
    self.typeLabel.font = [UIFont systemFontOfSize:12];
    self.typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.faceView addSubview:self.typeLabel];

    CGFloat hair = 1.0 / MAX([UIScreen mainScreen].scale, 1.0);
    self.faceView.layer.borderWidth = hair;

    [NSLayoutConstraint activateConstraints:@[
        [self.faceView.leadingAnchor constraintEqualToAnchor:self.messageContentView.leadingAnchor],
        [self.faceView.topAnchor constraintEqualToAnchor:self.messageContentView.topAnchor],
        [self.faceView.widthAnchor constraintEqualToConstant:252],
        [self.faceView.heightAnchor constraintEqualToConstant:118],

        [self.iconView.leadingAnchor constraintEqualToAnchor:self.faceView.leadingAnchor constant:16],
        [self.iconView.topAnchor constraintEqualToAnchor:self.faceView.topAnchor constant:16],
        [self.iconView.widthAnchor constraintEqualToConstant:46],
        [self.iconView.heightAnchor constraintEqualToConstant:46],

        [self.remarkLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
        [self.remarkLabel.trailingAnchor constraintEqualToAnchor:self.faceView.trailingAnchor constant:-16],
        [self.remarkLabel.topAnchor constraintEqualToAnchor:self.faceView.topAnchor constant:16],
        [self.remarkLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.dividerView.topAnchor constant:-8],

        [self.dividerView.leadingAnchor constraintEqualToAnchor:self.faceView.leadingAnchor constant:12],
        [self.dividerView.trailingAnchor constraintEqualToAnchor:self.faceView.trailingAnchor constant:-12],
        [self.dividerView.heightAnchor constraintEqualToConstant:hair],
        [self.dividerView.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:12],

        [self.typeLabel.leadingAnchor constraintEqualToAnchor:self.faceView.leadingAnchor constant:16],
        [self.typeLabel.trailingAnchor constraintEqualToAnchor:self.faceView.trailingAnchor constant:-16],
        [self.typeLabel.bottomAnchor constraintEqualToAnchor:self.faceView.bottomAnchor constant:-11],
    ]];

    [self.messageContentView bringSubviewToFront:self.trailingView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // messageContentView 用 lim_ 布局；子视图为 Auto Layout，须在本轮布局完成后再设 gradient frame。
    [self.messageContentView layoutIfNeeded];
    [self.faceView layoutIfNeeded];
    self.gradientLayer.frame = self.faceView.bounds;
}

- (void)onTap {
    [super onTap];
    [self onTapRedPacket];
}

- (void)applyRedPacketGradientOpened:(BOOL)opened {
    if (opened) {
        self.faceView.layer.borderColor = [WKQQWalletColors rpQQOpenedStroke].CGColor;
        self.gradientLayer.colors = @[
            (id)[WKQQWalletColors rpQQOpenedStart].CGColor,
            (id)[WKQQWalletColors rpQQOpenedMid].CGColor,
            (id)[WKQQWalletColors rpQQOpenedEnd].CGColor,
        ];
        self.gradientLayer.locations = @[ @0, @0.5, @1 ];
    } else {
        self.faceView.layer.borderColor = [WKQQWalletColors rpQQCardStroke].CGColor;
        self.gradientLayer.colors = @[
            (id)[WKQQWalletColors rpQQStart].CGColor,
            (id)[WKQQWalletColors rpQQMid].CGColor,
            (id)[WKQQWalletColors rpQQEnd].CGColor,
        ];
        self.gradientLayer.locations = @[ @0, @0.5, @1 ];
    }
}

- (void)applyRedPacketTextSkinOpened:(BOOL)opened {
    if (opened) {
        self.remarkLabel.textColor = [UIColor colorWithRed:1.0 green:0.973 blue:0.969 alpha:1.0];
        self.typeLabel.textColor = [UIColor colorWithRed:0.941 green:0.871 blue:0.871 alpha:1.0];
        self.typeLabel.alpha = 0.88f;
        self.dividerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:68.0 / 255.0];
        self.dividerView.alpha = 1;
        self.iconView.tintColor = [UIColor colorWithRed:1 green:0.95 blue:0.95 alpha:0.85];
    } else {
        self.remarkLabel.textColor = UIColor.whiteColor;
        self.typeLabel.textColor = UIColor.whiteColor;
        self.typeLabel.alpha = 0.75f;
        self.dividerView.backgroundColor = [UIColor whiteColor];
        self.dividerView.alpha = 0.2f;
        self.iconView.tintColor = UIColor.whiteColor;
    }
}

- (NSString *)typeTextForContent:(WKRedPacketContent *)content openedFooter:(BOOL)openedFooter {
    if (openedFooter) {
        if (content.status == 1) {
            return @"红包已领完";
        }
        if (content.status == 2) {
            return @"红包已过期";
        }
        return @"已领取";
    }
    switch (content.packetType) {
        case WKRedPacketTypeGroupRandom:
            return @"拼手气红包";
        case WKRedPacketTypeGroupNormal:
            return @"普通红包";
        case WKRedPacketTypeExclusive:
            return @"专属红包";
        default:
            return @"红包";
    }
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];

    if (![model.content isKindOfClass:[WKRedPacketContent class]]) {
        return;
    }
    WKRedPacketContent *content = (WKRedPacketContent *)model.content;
    self.remarkLabel.text = content.remark.length > 0 ? content.remark : @"恭喜发财，大吉大利";

    BOOL openedSkin;
    if (content.status == 1 || content.status == 2) {
        openedSkin = YES;
    } else if (content.status != 0) {
        openedSkin = YES;
    } else {
        openedSkin = NO;
    }

    [self applyRedPacketGradientOpened:openedSkin];
    [self applyRedPacketTextSkinOpened:openedSkin];
    self.typeLabel.text = [self typeTextForContent:content openedFooter:openedSkin];
}

- (void)onTapRedPacket {
    if (![self.messageModel.content isKindOfClass:[WKRedPacketContent class]]) {
        return;
    }
    WKRedPacketContent *content = (WKRedPacketContent *)self.messageModel.content;
    if (content.status == 0) {
        WKOpenRedPacketOverlay *overlay = [[WKOpenRedPacketOverlay alloc] initWithMessage:self.messageModel.message];
        [overlay present];
    } else {
        WKChannel *ch = self.messageModel.channel;
        WKRedPacketDetailVC *vc = (ch.channelId.length > 0)
            ? [[WKRedPacketDetailVC alloc] initWithPacketNo:content.packetNo channelId:ch.channelId channelType:ch.channelType]
            : [[WKRedPacketDetailVC alloc] initWithPacketNo:content.packetNo];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }
}

@end
