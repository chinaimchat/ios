#import "WKTransferCell.h"
#import "WKTransferContent.h"
#import "WKTransferDetailVC.h"

@interface WKTransferCell ()

@property (nonatomic, strong) UIView *transferView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *remarkLabel;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *tagLabel;

@end

@implementation WKTransferCell

+ (BOOL)hiddenBubble {
    return YES;
}

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    return CGSizeMake(252, 118);
}

- (void)initUI {
    [super initUI];

    self.transferView = [[UIView alloc] init];
    self.transferView.layer.cornerRadius = 12;
    self.transferView.layer.masksToBounds = YES;
    self.transferView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContentView addSubview:self.transferView];

    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    [self.transferView.layer insertSublayer:self.gradientLayer atIndex:0];

    self.iconView = [[UIImageView alloc] init];
    self.iconView.image = [UIImage systemImageNamed:@"dollarsign.circle.fill"];
    self.iconView.tintColor = [UIColor whiteColor];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.iconView];

    self.amountLabel = [[UILabel alloc] init];
    self.amountLabel.font = [UIFont boldSystemFontOfSize:17];
    self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.amountLabel];

    self.remarkLabel = [[UILabel alloc] init];
    self.remarkLabel.font = [UIFont systemFontOfSize:13];
    self.remarkLabel.numberOfLines = 1;
    self.remarkLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.remarkLabel];

    self.dividerView = [[UIView alloc] init];
    self.dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.dividerView];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.statusLabel];

    self.tagLabel = [[UILabel alloc] init];
    self.tagLabel.text = @"转账";
    self.tagLabel.font = [UIFont systemFontOfSize:11];
    self.tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.transferView addSubview:self.tagLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.transferView.leadingAnchor constraintEqualToAnchor:self.messageContentView.leadingAnchor],
        [self.transferView.topAnchor constraintEqualToAnchor:self.messageContentView.topAnchor],
        [self.transferView.widthAnchor constraintEqualToConstant:252],
        [self.transferView.heightAnchor constraintEqualToConstant:118],

        // 与 WKRedPacketCell / chat_item_redpacket 一致：16 边距、46 图标、12 分隔间距
        [self.iconView.leadingAnchor constraintEqualToAnchor:self.transferView.leadingAnchor constant:16],
        [self.iconView.topAnchor constraintEqualToAnchor:self.transferView.topAnchor constant:16],
        [self.iconView.widthAnchor constraintEqualToConstant:46],
        [self.iconView.heightAnchor constraintEqualToConstant:46],

        [self.amountLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
        [self.amountLabel.topAnchor constraintEqualToAnchor:self.transferView.topAnchor constant:16],
        [self.amountLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.transferView.trailingAnchor constant:-16],

        [self.remarkLabel.leadingAnchor constraintEqualToAnchor:self.amountLabel.leadingAnchor],
        [self.remarkLabel.topAnchor constraintEqualToAnchor:self.amountLabel.bottomAnchor constant:2],
        [self.remarkLabel.trailingAnchor constraintEqualToAnchor:self.transferView.trailingAnchor constant:-16],

        [self.dividerView.leadingAnchor constraintEqualToAnchor:self.transferView.leadingAnchor constant:12],
        [self.dividerView.trailingAnchor constraintEqualToAnchor:self.transferView.trailingAnchor constant:-12],
        [self.dividerView.heightAnchor constraintEqualToConstant:1],
        [self.dividerView.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:12],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.transferView.leadingAnchor constant:16],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.dividerView.bottomAnchor constant:8],
        [self.statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.tagLabel.leadingAnchor constant:-8],

        [self.tagLabel.trailingAnchor constraintEqualToAnchor:self.transferView.trailingAnchor constant:-16],
        [self.tagLabel.topAnchor constraintEqualToAnchor:self.dividerView.bottomAnchor constant:8],
        [self.tagLabel.bottomAnchor constraintEqualToAnchor:self.transferView.bottomAnchor constant:-11],
    ]];

    [self.messageContentView bringSubviewToFront:self.trailingView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.messageContentView layoutIfNeeded];
    [self.transferView layoutIfNeeded];
    self.gradientLayer.frame = self.transferView.bounds;
}

- (void)onTap {
    [super onTap];
    [self onTapTransfer];
}

- (void)applyTransferGradientDone:(BOOL)done {
    if (done) {
        self.gradientLayer.colors = @[
            (id)[UIColor colorWithRed:0.871 green:0.710 blue:0.416 alpha:1].CGColor,
            (id)[UIColor colorWithRed:0.702 green:0.518 blue:0.220 alpha:1].CGColor,
        ];
        self.gradientLayer.locations = @[ @0, @1 ];
    } else {
        self.gradientLayer.colors = @[
            (id)[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1].CGColor,
            (id)[UIColor colorWithRed:0.941 green:0.549 blue:0 alpha:1].CGColor,
        ];
        self.gradientLayer.locations = @[ @0, @1 ];
    }
}

- (void)applyTransferTextSkinDone:(BOOL)done {
    if (done) {
        UIColor *main = [UIColor colorWithRed:1 green:0.984 blue:0.965 alpha:1];
        UIColor *sub = [UIColor colorWithRed:0.949 green:0.910 blue:0.847 alpha:1];
        self.amountLabel.textColor = main;
        self.remarkLabel.textColor = sub;
        self.remarkLabel.alpha = 0.9f;
        self.statusLabel.textColor = sub;
        self.statusLabel.alpha = 0.88f;
        self.tagLabel.textColor = sub;
        self.tagLabel.alpha = 0.88f;
        self.dividerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.27];
        self.dividerView.alpha = 1;
        self.iconView.tintColor = [UIColor colorWithRed:1 green:0.98 blue:0.94 alpha:0.9];
    } else {
        self.amountLabel.textColor = UIColor.whiteColor;
        self.remarkLabel.textColor = UIColor.whiteColor;
        self.remarkLabel.alpha = 0.8f;
        self.statusLabel.textColor = UIColor.whiteColor;
        self.statusLabel.alpha = 0.75f;
        self.tagLabel.textColor = UIColor.whiteColor;
        self.tagLabel.alpha = 0.75f;
        self.dividerView.backgroundColor = [UIColor whiteColor];
        self.dividerView.alpha = 0.2f;
        self.iconView.tintColor = UIColor.whiteColor;
    }
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];

    if (![model.content isKindOfClass:[WKTransferContent class]]) {
        return;
    }
    WKTransferContent *content = (WKTransferContent *)model.content;
    self.amountLabel.text = [NSString stringWithFormat:@"¥%.2f", content.amount];
    self.remarkLabel.text = content.remark.length > 0 ? content.remark : @"转账";

    BOOL done = (content.transferStatus == WKTransferMessageStatusAccepted
        || content.transferStatus == WKTransferMessageStatusRefunded);
    [self applyTransferGradientDone:done];
    [self applyTransferTextSkinDone:done];

    if (content.transferStatus == WKTransferMessageStatusAccepted) {
        self.statusLabel.text = @"已收款";
    } else if (content.transferStatus == WKTransferMessageStatusRefunded) {
        self.statusLabel.text = @"已退回";
    } else {
        self.statusLabel.text = @"待确认收款";
    }
}

- (void)onTapTransfer {
    if ([self.messageModel.content isKindOfClass:[WKTransferContent class]]) {
        WKTransferContent *content = (WKTransferContent *)self.messageModel.content;
        WKTransferDetailVC *vc = [[WKTransferDetailVC alloc] initWithTransferNo:content.transferNo
                                                                   clientMsgNo:self.messageModel.clientMsgNo];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }
}

@end
