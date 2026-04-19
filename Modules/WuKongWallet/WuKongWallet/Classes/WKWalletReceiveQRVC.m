#import "WKWalletReceiveQRVC.h"
#import "LBXScanNative.h"
#import "WKWalletMaterialTheme.h"
#import <Photos/Photos.h>
#import <WuKongBase/WuKongBase.h>

/// 与 Android {@code activity_wallet_receive_qr.xml} / {@code WalletReceiveQrActivity} 对齐。
static const CGFloat kPagePadH = 10.0;
static const CGFloat kPagePadTop = 6.0;
static const CGFloat kCardInnerPadH = 10.0;
static const CGFloat kCardInnerTop = 10.0;
static const CGFloat kCardInnerBottom = 12.0;
static const CGFloat kQrSidePt = 240.0;
static const CGFloat kQrInnerMargin = 12.0;

@interface WKWalletReceiveQRVC ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContent;

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) WKUserAvatar *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *qrFrameView;
@property (nonatomic, strong) UIImageView *qrImageView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@property (nonatomic, strong) UIButton *saveNavButton;

@property (nonatomic, copy) NSString *qrPayload;
@property (nonatomic, assign) BOOL needsQrRedrawAfterLayout;

@end

@implementation WKWalletReceiveQRVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"收款码");
    self.navigationBar.style = WKNavigationBarStyleWhite;
    [self.navigationBar setBackgroundColor:[WKWalletMaterialTheme buyUsdtAppbarBg]];
    self.view.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];

    UIButton *save = [UIButton buttonWithType:UIButtonTypeSystem];
    [save setTitle:LLang(@"保存图片") forState:UIControlStateNormal];
    save.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [save setTitleColor:[WKWalletMaterialTheme buyUsdtPrimary] forState:UIControlStateNormal];
    [save addTarget:self action:@selector(onSave) forControlEvents:UIControlEventTouchUpInside];
    [save sizeToFit];
    CGFloat sw = MAX(CGRectGetWidth(save.bounds) + 20.0, 72.0);
    save.frame = CGRectMake(0, 0, sw, 44.0);
    self.saveNavButton = save;
    self.rightView = save;

    [self buildContentHierarchy];
    [self loadQR];
}

- (void)buildContentHierarchy {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.scrollView];

    self.scrollContent = [[UIView alloc] init];
    [self.scrollView addSubview:self.scrollContent];

    self.cardView = [[UIView alloc] init];
    [WKWalletMaterialTheme applyMaterialCardStyleToView:self.cardView cornerRadius:10.0];
    [self.scrollContent addSubview:self.cardView];

    self.avatarView = [[WKUserAvatar alloc] init];
    [self.cardView addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.nameLabel.textColor = [WKWalletMaterialTheme buyUsdtTextPrimary];
    [self.cardView addSubview:self.nameLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.font = [UIFont systemFontOfSize:14];
    self.subtitleLabel.textColor = [WKWalletMaterialTheme buyUsdtPrimary];
    self.subtitleLabel.text = LLang(@"向我的钱包付款");
    [self.cardView addSubview:self.subtitleLabel];

    self.qrFrameView = [[UIView alloc] init];
    self.qrFrameView.backgroundColor = [WKWalletMaterialTheme buyUsdtPageBg];
    self.qrFrameView.layer.cornerRadius = 8.0;
    self.qrFrameView.layer.borderWidth = 0.5;
    self.qrFrameView.layer.borderColor = [WKWalletMaterialTheme buyUsdtDivider].CGColor;
    self.qrFrameView.layer.masksToBounds = YES;
    [self.cardView addSubview:self.qrFrameView];

    self.qrImageView = [[UIImageView alloc] init];
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.backgroundColor = UIColor.clearColor;
    [self.qrFrameView addSubview:self.qrImageView];

    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingView.hidesWhenStopped = YES;
    [self.qrFrameView addSubview:self.loadingView];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.font = [UIFont systemFontOfSize:13];
    self.hintLabel.textColor = [WKWalletMaterialTheme buyUsdtTextSecondary];
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.text = LLang(@"请对方使用本 App「扫一扫」扫描上方二维码，输入金额并完成支付。\n款项将进入您的钱包余额。");
    [self.cardView addSubview:self.hintLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect vis = [self visibleRect];
    self.scrollView.frame = vis;

    CGFloat w = vis.size.width;
    CGFloat cardW = w - kPagePadH * 2.0;
    CGFloat innerW = cardW - kCardInnerPadH * 2.0;

    CGFloat y = kPagePadTop;
    CGFloat avatarSize = 56.0;
    CGFloat nameH = 22.0;
    CGFloat subH = 20.0;
    CGFloat qrSide = MIN(kQrSidePt, innerW - kQrInnerMargin * 2.0);
    CGFloat qrFrameW = qrSide + kQrInnerMargin * 2.0;
    CGFloat qrFrameH = qrFrameW;

    CGFloat hintW = innerW;
    CGSize hintSize = [self.hintLabel.text boundingRectWithSize:CGSizeMake(hintW, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{ NSFontAttributeName: self.hintLabel.font }
                                                         context:nil].size;
    CGFloat hintH = ceil(hintSize.height) + 2.0;

    CGFloat cardH = kCardInnerTop + avatarSize + 10.0 + nameH + 6.0 + subH + 16.0 + qrFrameH + 14.0 + hintH + kCardInnerBottom;

    self.scrollContent.frame = CGRectMake(0, 0, w, y + cardH + 24.0);
    self.scrollView.contentSize = self.scrollContent.bounds.size;

    self.cardView.frame = CGRectMake(kPagePadH, y, cardW, cardH);

    CGFloat cx = kCardInnerPadH + (innerW - avatarSize) / 2.0;
    self.avatarView.frame = CGRectMake(cx, kCardInnerTop, avatarSize, avatarSize);

    CGFloat textY = CGRectGetMaxY(self.avatarView.frame) + 10.0;
    self.nameLabel.frame = CGRectMake(kCardInnerPadH, textY, innerW, nameH);
    textY = CGRectGetMaxY(self.nameLabel.frame) + 6.0;
    self.subtitleLabel.frame = CGRectMake(kCardInnerPadH, textY, innerW, subH);

    CGFloat qfX = kCardInnerPadH + (innerW - qrFrameW) / 2.0;
    CGFloat qfY = CGRectGetMaxY(self.subtitleLabel.frame) + 16.0;
    self.qrFrameView.frame = CGRectMake(qfX, qfY, qrFrameW, qrFrameH);

    CGFloat qx = kQrInnerMargin;
    CGFloat qy = kQrInnerMargin;
    CGFloat qside = qrSide;
    self.qrImageView.frame = CGRectMake(qx, qy, qside, qside);
    self.loadingView.center = CGPointMake(CGRectGetMidX(self.qrFrameView.bounds), CGRectGetMidY(self.qrFrameView.bounds));

    CGFloat hy = CGRectGetMaxY(self.qrFrameView.frame) + 14.0;
    self.hintLabel.frame = CGRectMake(kCardInnerPadH, hy, hintW, hintH);

    if (self.needsQrRedrawAfterLayout && self.qrPayload.length > 0) {
        self.needsQrRedrawAfterLayout = NO;
        [self renderQRCodeWithPayload:self.qrPayload];
    }
}

- (void)loadQR {
    NSString *uid = [WKApp shared].loginInfo.uid ?: @"";
    if (uid.length == 0) {
        [WKAlertUtil showMsg:LLang(@"未登录，无法展示收款码")];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WKNavigationManager shared] popViewControllerAnimated:YES];
        });
        return;
    }

    NSString *name = [WKApp shared].loginInfo.extra[@"name"];
    self.nameLabel.text = ([name isKindOfClass:[NSString class]] && [(NSString *)name length] > 0) ? (NSString *)name : uid;
    self.avatarView.url = [WKAvatarUtil getAvatar:uid];

    [self.loadingView startAnimating];
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/receive/qrcode" parameters:nil].then(^(id result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingView stopAnimating];
            NSString *payload = [weakSelf extractPayloadFromResult:result];
            if (payload.length == 0) {
                payload = [weakSelf buildReceiveURIWithUid:uid];
            }
            [weakSelf setQrPayloadAndRender:payload];
        });
    }).catch(^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingView stopAnimating];
            NSString *payload = [weakSelf buildReceiveURIWithUid:uid];
            [weakSelf setQrPayloadAndRender:payload];
            if (error) {
                WKLogInfo(@"钱包收款码接口失败，已使用本地兜底 payload: %@", error.localizedDescription ?: @"");
            }
        });
    });
}

- (void)setQrPayloadAndRender:(NSString *)payload {
    self.qrPayload = payload ?: @"";
    if (CGRectGetWidth(self.qrImageView.bounds) > 10.0 && CGRectGetHeight(self.qrImageView.bounds) > 10.0) {
        [self renderQRCodeWithPayload:self.qrPayload];
    } else {
        self.needsQrRedrawAfterLayout = YES;
        [self.view setNeedsLayout];
    }
}

- (NSString *)extractPayloadFromResult:(id)result {
    if (![result isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dict = (NSDictionary *)result;
    NSString *payload = [self extractPayloadFromObject:dict];
    if (payload.length > 0) {
        return payload;
    }
    id data = dict[@"data"];
    payload = [self extractPayloadFromObject:data];
    return payload.length > 0 ? payload : nil;
}

- (NSString *)extractPayloadFromObject:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        return s.length > 0 ? s : nil;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)obj;
        NSArray<NSString *> *keys = @[ @"qrcode", @"qr_code", @"qr", @"content", @"url", @"data", @"payload" ];
        for (NSString *k in keys) {
            NSString *v = [self extractPayloadFromObject:dict[k]];
            if (v.length > 0) {
                return v;
            }
        }
    }
    return nil;
}

- (void)renderQRCodeWithPayload:(NSString *)payload {
    self.qrPayload = payload ?: @"";
    CGSize sz = self.qrImageView.bounds.size;
    if (sz.width < 8.0 || sz.height < 8.0) {
        sz = CGSizeMake(kQrSidePt, kQrSidePt);
    }
    UIImage *qr = [LBXScanNative createQRWithString:self.qrPayload QRSize:sz];
    self.qrImageView.image = qr;
}

/// 与 Android {@code WalletReceiveQrContract#buildReceiveUri} 一致：{@code mtp://wallet/receive?uid=…}
- (NSString *)buildReceiveURIWithUid:(NSString *)uid {
    NSString *u = [uid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (u.length == 0) {
        return @"";
    }
    NSString *escaped = [u stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: u;
    return [NSString stringWithFormat:@"mtp://wallet/receive?uid=%@", escaped];
}

- (void)onSave {
    [self.view layoutIfNeeded];
    CGSize sz = self.cardView.bounds.size;
    if (sz.width < 1.0 || sz.height < 1.0) {
        [WKAlertUtil showMsg:LLang(@"保存失败")];
        return;
    }

    __weak typeof(self) weakSelf = self;
    void (^doRenderAndSave)(void) = ^{
        UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat];
        fmt.scale = UIScreen.mainScreen.scale;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:sz format:fmt];
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            [weakSelf.cardView.layer renderInContext:ctx.CGContext];
        }];
        if (!image) {
            [WKAlertUtil showMsg:LLang(@"保存失败")];
            return;
        }
        UIImageWriteToSavedPhotosAlbum(image, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    };

    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    doRenderAndSave();
                } else {
                    [WKAlertUtil showMsg:LLang(@"请在设置中允许访问相册以保存图片")];
                }
            });
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    doRenderAndSave();
                } else {
                    [WKAlertUtil showMsg:LLang(@"请在设置中允许访问相册以保存图片")];
                }
            });
        }];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    (void)image;
    (void)contextInfo;
    if (error) {
        [WKAlertUtil showMsg:LLang(@"保存失败，请检查相册权限")];
    } else {
        [WKAlertUtil showMsg:LLang(@"已保存到相册")];
    }
}

@end
