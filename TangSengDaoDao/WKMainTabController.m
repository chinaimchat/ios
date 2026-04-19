//
//  WKMainTabController.m
//  TangSengDaoDao
//
//  Created by tt on 2019/12/7.
//  Copyright © 2019 xinbida. All rights reserved.
//

#import "WKMainTabController.h"
@import WuKongBase;
#import <Lottie/Lottie.h>
#import "WKConversationListVC.h"
#import "WKContactsVC.h"
#import "WKMeVC.h"
#import <PromiseKit/AnyPromise.h>

@interface WKWorkplaceApp : NSObject
@property(nonatomic,copy) NSString *app_id;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *desc;
@property(nonatomic,copy) NSString *icon;
@property(nonatomic,copy) NSString *app_route;
@property(nonatomic,copy) NSString *web_route;
@property(nonatomic,assign) NSInteger jump_type;
@end

@implementation WKWorkplaceApp
@end

/**
 * 与 `WKWebViewVC.m` 内部的 `WKWorkplaceWebBubbleStore` 保持一致的接口声明：
 * - Workplace 打开 web 前写入 url/icon/pendingDismiss
 * - WebView 离开时（返回）会把 shouldShowBubble=YES
 * - Workplace viewWillAppear 消费 shouldShowBubble 并展示两段点击 bubble
 */
@interface WKWorkplaceWebBubbleStore : NSObject

@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, copy) NSString *icon;
@property(nonatomic, strong) WKWebViewVC *webViewVC;
@property(nonatomic, assign) BOOL pendingDismiss;
@property(nonatomic, assign) BOOL shouldShowBubble;

+ (instancetype)shared;
- (void)clear;

@end

/// 与 Android `WKApiConfig.getShowUrl` 一致：相对路径拼到 apiBaseUrl。
static NSURL *_Nullable WKWorkplaceAbsoluteIconURL(NSString *_Nullable path) {
    if (path.length == 0) {
        return nil;
    }
    NSString *t = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (t.length == 0) {
        return nil;
    }
    NSString *lower = t.lowercaseString;
    if ([lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"]) {
        return [NSURL URLWithString:t];
    }
    NSString *base = [WKApp shared].config.apiBaseUrl ?: @"";
    if (base.length == 0) {
        return nil;
    }
    NSString *p = t;
    while ([p hasPrefix:@"/"]) {
        p = [p substringFromIndex:1];
    }
    NSString *b = base;
    while ([b hasSuffix:@"/"]) {
        b = [b substringToIndex:b.length - 1];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", b, p]];
}

/// 对齐 Android `homeColor` #f6f6f6 / 深色模式 `homeColor` night。
static UIColor *WKWorkplaceListBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGroupedBackgroundColor];
    }
    return [UIColor colorWithRed:246.0f / 255.0f green:246.0f / 255.0f blue:246.0f / 255.0f alpha:1.0f];
}

static UIColor *WKWorkplaceWebBubbleBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:42.0f / 255.0f green:49.0f / 255.0f blue:60.0f / 255.0f alpha:0.72f];
            }
            return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.76f];
        }];
    }
    return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.76f];
}

static UIColor *WKWorkplaceWebBubbleBorderColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0f alpha:0.60f];
            }
            return [UIColor colorWithWhite:1.0f alpha:0.82f];
        }];
    }
    return [UIColor colorWithWhite:1.0f alpha:0.82f];
}

static UIColor *WKWorkplaceWebBubbleCloseTintColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0f alpha:0.92f];
            }
            return [UIColor colorWithRed:95.0f / 255.0f green:99.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
        }];
    }
    return [UIColor colorWithRed:95.0f / 255.0f green:99.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
}

static UIColor *WKWorkplaceWebBubbleCloseBorderColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0f alpha:0.68f];
            }
            return [UIColor colorWithWhite:1.0f alpha:0.92f];
        }];
    }
    return [UIColor colorWithWhite:1.0f alpha:0.92f];
}

static UIBlurEffectStyle WKWorkplaceWebBubbleBlurStyle(UITraitCollection *_Nullable traitCollection) {
    if (@available(iOS 13.0, *)) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIBlurEffectStyleDark;
        }
    }
    return UIBlurEffectStyleLight;
}

static UIWindow *_Nullable WKWorkplaceActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
            if (windowScene.windows.count > 0) {
                return windowScene.windows.firstObject;
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.windows.firstObject;
}

/// 主 Tab 选中态图标与文案色（与品牌主色一致）。
static UIColor *WKTabBarItemAccentColor(void) {
    return [UIColor colorWithRed:255.0f / 255.0f green:90.0f / 255.0f blue:51.0f / 255.0f alpha:1.0f];
}

/// 主 Tab 未选中态：浅橙色，与选中态形成层次。
static UIColor *WKTabBarItemNormalColor(void) {
    return [UIColor colorWithRed:255.0f / 255.0f green:188.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
}

/// 与 WKWebViewVC 里发现外链的规范化一致，用于判断「是否换了发现入口」。
static NSString *WKNormalizeWorkplaceOpenURLString(NSString *s) {
    if (!s.length) {
        return @"";
    }
    NSString *u = [s stringByRemovingPercentEncoding];
    if (!u.length) {
        u = s;
    }
    if (u && ![u hasPrefix:@"http"] && ![u hasPrefix:@"HTTP"]) {
        u = [NSString stringWithFormat:@"http://%@", u];
    }
    return u ?: @"";
}

static void WKResumeOrOpenWorkplaceWebSession(NSString *urlString) {
    WKWorkplaceWebBubbleStore *store = [WKWorkplaceWebBubbleStore shared];
    WKWebViewVC *vc = store.webViewVC;
    NSString *incoming = WKNormalizeWorkplaceOpenURLString(urlString);
    if (!vc) {
        vc = [WKWebViewVC new];
        store.webViewVC = vc;
        vc.url = [NSURL URLWithString:incoming.length ? incoming : urlString];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return;
    }

    NSString *entry = WKNormalizeWorkplaceOpenURLString(vc.url.absoluteString);
    BOOL sameDiscoverEntry = (entry.length > 0 && [incoming isEqualToString:entry]);

    if (vc.hasLoadedWebSession && sameDiscoverEntry) {
        // 同一发现入口：最小化再展开，不整页重载。
        vc.skipInitialReload = YES;
    } else {
        // 换了发现里的网站：必须加载新地址（不能只更新小圆球图标）。
        vc.skipInitialReload = NO;
        vc.url = [NSURL URLWithString:incoming.length ? incoming : urlString];
        if (!sameDiscoverEntry && vc.isViewLoaded) {
            [vc reloadFromWorkplaceDiscoverURLString:urlString];
        }
    }
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

static void WKApplyMainTabBarTitleStyle(UITabBar *tabBar) {
    UIFont *font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
    UIColor *accent = WKTabBarItemAccentColor();
    UIColor *normalTint = WKTabBarItemNormalColor();
    NSDictionary *normalTitleAttrs = @{ NSForegroundColorAttributeName: normalTint, NSFontAttributeName: font };
    NSDictionary *selectedTitleAttrs = @{ NSForegroundColorAttributeName: accent, NSFontAttributeName: font };

    /// 全局 Item 文案色：部分系统上仅靠 UITabBarAppearance 不生效，与 per-item 设置互为兜底。
    [[UITabBarItem appearance] setTitleTextAttributes:normalTitleAttrs forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:selectedTitleAttrs forState:UIControlStateSelected];

    if (@available(iOS 10.0, *)) {
        tabBar.unselectedItemTintColor = normalTint;
    }
    tabBar.tintColor = accent;

    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        if (@available(iOS 15.0, *)) {
            [appearance configureWithOpaqueBackground];
        } else {
            [appearance configureWithDefaultBackground];
        }
        appearance.backgroundColor = tabBar.backgroundColor;
        void (^applyItem)(UITabBarItemAppearance *) = ^(UITabBarItemAppearance *itemAppearance) {
            itemAppearance.normal.titleTextAttributes = normalTitleAttrs;
            itemAppearance.selected.titleTextAttributes = selectedTitleAttrs;
            itemAppearance.normal.iconColor = normalTint;
            itemAppearance.selected.iconColor = accent;
        };
        applyItem(appearance.stackedLayoutAppearance);
        applyItem(appearance.inlineLayoutAppearance);
        applyItem(appearance.compactInlineLayoutAppearance);
        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
        UITabBar *tabProxy = [UITabBar appearance];
        tabProxy.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabProxy.scrollEdgeAppearance = appearance;
        }
    }
}

@interface WKWorkplaceCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, assign) BOOL descHidden;
@end

@implementation WKWorkplaceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [UIView new];
        _cardView.layer.cornerRadius = 8.0f;
        _cardView.clipsToBounds = YES;
        if (@available(iOS 13.0, *)) {
            _cardView.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        } else {
            _cardView.backgroundColor = UIColor.whiteColor;
        }
        [self.contentView addSubview:_cardView];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        _iconView.clipsToBounds = YES;
        _iconView.layer.cornerRadius = 4.0f;
        _iconView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
        [_cardView addSubview:_iconView];

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
        if (@available(iOS 13.0, *)) {
            _nameLabel.textColor = [UIColor labelColor];
        } else {
            _nameLabel.textColor = [UIColor colorWithRed:49.0f / 255.0f green:49.0f / 255.0f blue:49.0f / 255.0f alpha:1.0f];
        }
        _nameLabel.numberOfLines = 1;
        [_cardView addSubview:_nameLabel];

        _descLabel = [UILabel new];
        _descLabel.font = [UIFont systemFontOfSize:12.0f];
        if (@available(iOS 13.0, *)) {
            _descLabel.textColor = [UIColor secondaryLabelColor];
        } else {
            _descLabel.textColor = [UIColor colorWithRed:153.0f / 255.0f green:153.0f / 255.0f blue:153.0f / 255.0f alpha:1.0f];
        }
        _descLabel.numberOfLines = 1;
        [_cardView addSubview:_descLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.contentView.bounds.size.width;
    CGFloat H = self.contentView.bounds.size.height;
    CGFloat side = 12.0f;
    CGFloat cardTop = 8.0f;
    CGFloat cardH = H - 16.0f;
    self.cardView.frame = CGRectMake(side, cardTop, W - 2.0f * side, cardH);

    CGFloat innerX = 12.0f;
    CGFloat iconSide = 40.0f;
    CGFloat iy = (cardH - iconSide) / 2.0f;
    self.iconView.frame = CGRectMake(innerX, iy, iconSide, iconSide);

    CGFloat textX = innerX + iconSide + 10.0f;
    CGFloat textW = self.cardView.bounds.size.width - textX - innerX;
    if (self.descHidden) {
        CGFloat nameH = 22.0f;
        CGFloat ny = (cardH - nameH) / 2.0f;
        self.nameLabel.frame = CGRectMake(textX, ny, textW, nameH);
    } else {
        self.nameLabel.frame = CGRectMake(textX, 10.0f, textW, 20.0f);
        self.descLabel.frame = CGRectMake(textX, 32.0f, textW, 16.0f);
    }
}

- (void)configureWithApp:(WKWorkplaceApp *)app {
    self.nameLabel.text = app.name.length ? app.name : @"";
    self.descLabel.text = app.desc.length ? app.desc : @" ";
    self.descHidden = app.desc.length == 0;
    self.descLabel.hidden = self.descHidden;

    NSURL *iconURL = WKWorkplaceAbsoluteIconURL(app.icon);
    UIImage *ph = [WKApp shared].config.defaultPlaceholder;
    if (iconURL) {
        [self.iconView lim_setImageWithURL:iconURL placeholderImage:ph];
    } else {
        self.iconView.image = ph;
    }
}

@end

@interface WKWorkplaceVC : WKBaseVC<UITableViewDelegate, UITableViewDataSource>
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSArray<WKWorkplaceApp*> *apps;
@end

@implementation WKWorkplaceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"发现");
    self.apps = @[];
    self.view.backgroundColor = WKWorkplaceListBackgroundColor();
    [self.view addSubview:self.tableView];
    [self requestWorkplaceApps];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.navigationBar.lim_bottom, self.view.lim_width, self.view.lim_height - self.navigationBar.lim_bottom) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = WKWorkplaceListBackgroundColor();
        _tableView.showsVerticalScrollIndicator = YES;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        }
        // 对齐 Android RecyclerView：paddingTop/Bottom 8，左右由 cell 内边距 12 承担
        _tableView.contentInset = UIEdgeInsetsMake(8.0f, 0.0f, 8.0f, 0.0f);
        _tableView.scrollIndicatorInsets = _tableView.contentInset;
        // 单条：上 8 + 白卡片 min 62 + 下 8（与 item_workplace_app_layout margin 一致）
        _tableView.rowHeight = 78.0f;
    }
    return _tableView;
}

- (void)requestWorkplaceApps {
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] GET:@"workplace/category" parameters:nil].then(^(id result){
        NSArray *categories = [result isKindOfClass:NSArray.class] ? (NSArray *)result : @[];
        if (categories.count == 0) {
            weakSelf.apps = @[];
            [weakSelf.tableView reloadData];
            return [AnyPromise promiseWithValue:@[]];
        }
        NSDictionary *first = [categories.firstObject isKindOfClass:NSDictionary.class] ? categories.firstObject : nil;
        NSString *categoryNo = first[@"category_no"];
        if (!categoryNo || categoryNo.length == 0) {
            weakSelf.apps = @[];
            [weakSelf.tableView reloadData];
            return [AnyPromise promiseWithValue:@[]];
        }
        return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"workplace/categorys/%@/app", categoryNo] parameters:nil];
    }).then(^(id result){
        if (![result isKindOfClass:NSArray.class]) {
            weakSelf.apps = @[];
            [weakSelf.tableView reloadData];
            return;
        }
        NSArray *rows = (NSArray *)result;
        NSMutableArray *temp = [NSMutableArray array];
        for (id item in rows) {
            if (![item isKindOfClass:NSDictionary.class]) {
                continue;
            }
            NSDictionary *dict = (NSDictionary *)item;
            WKWorkplaceApp *app = [WKWorkplaceApp new];
            app.app_id = dict[@"app_id"] ?: @"";
            app.name = dict[@"name"] ?: @"";
            app.desc = dict[@"description"] ?: @"";
            app.icon = dict[@"icon"] ?: @"";
            app.app_route = dict[@"app_route"] ?: @"";
            app.web_route = dict[@"web_route"] ?: @"";
            app.jump_type = [dict[@"jump_type"] integerValue];
            [temp addObject:app];
        }
        weakSelf.apps = temp;
        [weakSelf.tableView reloadData];
    }).catch(^(NSError *error){
        weakSelf.apps = @[];
        [weakSelf.tableView reloadData];
        WKLogError(@"workplace load error -> %@", error);
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.apps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"wk.workplace.card.cell";
    WKWorkplaceCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[WKWorkplaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    [cell configureWithApp:self.apps[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WKWorkplaceApp *app = self.apps[indexPath.row];

    if (app.app_id.length > 0) {
        [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"workplace/apps/%@/record", app.app_id] parameters:nil].catch(^(NSError *error){
            WKLogError(@"workplace add record error -> %@", error);
        });
    }

    if (app.jump_type == 0) {
        [self openWeb:app.web_route icon:app.icon];
        return;
    }

    if (app.app_route.length == 0) {
        [self openWeb:app.web_route icon:app.icon];
        return;
    }

    if ([app.app_route hasPrefix:@"http://"] || [app.app_route hasPrefix:@"https://"]) {
        [self openWeb:app.app_route icon:app.icon];
        return;
    }

    if ([app.app_route containsString:@"://"]) {
        NSURL *url = [NSURL URLWithString:app.app_route];
        if (url) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            return;
        }
    }

    if ([[WKApp shared] hasMethod:app.app_route]) {
        [[WKApp shared] invoke:app.app_route param:app];
    } else {
        [self openWeb:app.web_route icon:app.icon];
    }
}

- (void)openWeb:(NSString *)urlString icon:(NSString *)iconString {
    if (!urlString || urlString.length == 0) {
        return;
    }

    WKWorkplaceWebBubbleStore *store = [WKWorkplaceWebBubbleStore shared];
    store.urlString = urlString;
    store.icon = iconString;
    store.pendingDismiss = YES;
    store.shouldShowBubble = NO;
    WKResumeOrOpenWorkplaceWebSession(urlString);
}

@end

@interface WKMainTabController ()<UITabBarControllerDelegate>

@property(nonatomic,strong) LOTAnimationView *currentLOTAnimationView;
@property(nonatomic,strong) UIView *workplaceWebBubbleView;
@property(nonatomic,strong) UIVisualEffectView *workplaceWebBubbleBlurView;
@property(nonatomic,strong) UIView *workplaceWebBubbleTintView;
@property(nonatomic,strong) UIImageView *workplaceWebBubbleIconView;
@property(nonatomic,strong) UIButton *workplaceWebBubbleCloseButton;
@property(nonatomic,assign) BOOL workplaceWebBubbleXVisible;
@property(nonatomic,assign) BOOL workplaceWebBubbleHasManualPosition;
@property(nonatomic,assign) CGPoint workplaceWebBubbleManualOrigin;
@property(nonatomic,assign) CGPoint workplaceWebBubblePanStartOrigin;

@end

@implementation WKMainTabController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    // Do any additional setup after loading the view.
    [self.tabBar setBarTintColor:[UIColor whiteColor]];

    [[UITabBar appearance] setShadowImage:[[UIImage alloc]init]];
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc]init]];
    if (@available(iOS 13.0, *)) {
        [self.tabBar setBarTintColor:[UIColor systemBackgroundColor]];
        [self.tabBar setBackgroundColor:[UIColor systemBackgroundColor]];
    } else {
        [self.tabBar setBarTintColor:[UIColor whiteColor]];
        [self.tabBar setBackgroundColor:[UIColor whiteColor]];
    }

    [self setupChildVC:WKConversationListVC.class title:@"聊天" andImage:@"HomeTab" andSelectImage:@"HomeTabSelected"];
    [self setupChildVC:WKContactsVC.class title:@"联系人" andImage:@"ContactsTab" andSelectImage:@"ContactsTabSelected"];
    [self setupChildVC:WKWorkplaceVC.class title:@"发现" andImage:@"WorkplaceTab" andSelectImage:@"WorkplaceTabSelected"];
    [self setupChildVC:WKMeVC.class title:@"我的" andImage:@"MeTab" andSelectImage:@"MeTabSelected"];

    WKApplyMainTabBarTitleStyle(self.tabBar);
    [self setupWorkplaceWebBubbleUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self consumePendingWorkplaceWebBubbleIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self ensureWorkplaceWebBubbleAttached];
    [self consumePendingWorkplaceWebBubbleIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateWorkplaceWebBubbleLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection &&
            [self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateWorkplaceWebBubbleAppearance];
        }
    }
}

- (void)setupChildVC:(Class)vc title:(NSString *)title andImage:(NSString * )image andSelectImage:(NSString *)selectImage{

    UIViewController * vcInstall = [[vc alloc] init];
    //VC.view.backgroundColor = UIColor.whiteColor;
    vcInstall.tabBarItem.title = title;
    UIFont *tabFont = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
    [vcInstall.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: WKTabBarItemNormalColor(), NSFontAttributeName: tabFont } forState:UIControlStateNormal];
    [vcInstall.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: WKTabBarItemAccentColor(), NSFontAttributeName: tabFont } forState:UIControlStateSelected];
    // 未选中：直接着色为浅橙再 AlwaysOriginal，避免系统未应用 unselectedItemTintColor/iconColor 时仍显示资源黑线稿。
    UIImage *raw = [UIImage imageNamed:image];
    if (raw) {
        vcInstall.tabBarItem.image = [raw imageWithTintColor:WKTabBarItemNormalColor() renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else {
        vcInstall.tabBarItem.image = nil;
    }
    vcInstall.tabBarItem.selectedImage = [[UIImage imageNamed:selectImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self addChildViewController:vcInstall];
}


-(void) dealloc {
    WKLogDebug(@"WKMainTabController dealloc");
}

#pragma mark - UITabBarControllerDelegate

static UIImpactFeedbackGenerator *impactFeedBack;
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {

    if(!impactFeedBack) {
        impactFeedBack = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    }
    [impactFeedBack prepare];
    [impactFeedBack impactOccurred];
    [self bringWorkplaceWebBubbleToFront];
    [self updateWorkplaceWebBubbleLayout];
}

- (UIView *)workplaceWebBubbleHostView {
    UIView *hostView = WKWorkplaceActiveWindow();
    return hostView ?: self.view;
}

- (void)setupWorkplaceWebBubbleUI {
    if (self.workplaceWebBubbleView) {
        [self ensureWorkplaceWebBubbleAttached];
        return;
    }

    CGFloat bubbleSize = 56.0f;
    self.workplaceWebBubbleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, bubbleSize, bubbleSize)];
    self.workplaceWebBubbleView.layer.cornerRadius = bubbleSize / 2.0f;
    self.workplaceWebBubbleView.layer.borderWidth = 1.0f;
    self.workplaceWebBubbleView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.workplaceWebBubbleView.layer.shadowOpacity = 0.14f;
    self.workplaceWebBubbleView.layer.shadowRadius = 14.0f;
    self.workplaceWebBubbleView.layer.shadowOffset = CGSizeMake(0.0f, 6.0f);
    self.workplaceWebBubbleView.clipsToBounds = NO;
    self.workplaceWebBubbleView.userInteractionEnabled = YES;

    self.workplaceWebBubbleBlurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:WKWorkplaceWebBubbleBlurStyle(self.traitCollection)]];
    self.workplaceWebBubbleBlurView.frame = self.workplaceWebBubbleView.bounds;
    self.workplaceWebBubbleBlurView.layer.cornerRadius = bubbleSize / 2.0f;
    self.workplaceWebBubbleBlurView.clipsToBounds = YES;
    [self.workplaceWebBubbleView addSubview:self.workplaceWebBubbleBlurView];

    self.workplaceWebBubbleTintView = [[UIView alloc] initWithFrame:self.workplaceWebBubbleBlurView.contentView.bounds];
    [self.workplaceWebBubbleBlurView.contentView addSubview:self.workplaceWebBubbleTintView];

    self.workplaceWebBubbleIconView = [[UIImageView alloc] initWithFrame:CGRectInset(self.workplaceWebBubbleView.bounds, 11.0f, 11.0f)];
    self.workplaceWebBubbleIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.workplaceWebBubbleIconView.clipsToBounds = YES;
    [self.workplaceWebBubbleBlurView.contentView addSubview:self.workplaceWebBubbleIconView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onWorkplaceWebBubbleTapped)];
    [self.workplaceWebBubbleView addGestureRecognizer:tapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleWorkplaceWebBubblePan:)];
    [self.workplaceWebBubbleView addGestureRecognizer:panGesture];

    CGFloat closeSize = 18.0f;
    self.workplaceWebBubbleCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.workplaceWebBubbleCloseButton.frame = CGRectMake(0.0f, 0.0f, closeSize, closeSize);
    [self.workplaceWebBubbleCloseButton setTitle:@"×" forState:UIControlStateNormal];
    self.workplaceWebBubbleCloseButton.backgroundColor = [UIColor clearColor];
    self.workplaceWebBubbleCloseButton.layer.cornerRadius = closeSize / 2.0f;
    self.workplaceWebBubbleCloseButton.layer.borderWidth = 1.0f;
    self.workplaceWebBubbleCloseButton.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightSemibold];
    [self.workplaceWebBubbleCloseButton addTarget:self action:@selector(onWorkplaceWebBubbleCloseTapped) forControlEvents:UIControlEventTouchUpInside];
    self.workplaceWebBubbleCloseButton.hidden = YES;

    self.workplaceWebBubbleXVisible = NO;
    self.workplaceWebBubbleView.hidden = YES;
    [self ensureWorkplaceWebBubbleAttached];
    [self updateWorkplaceWebBubbleAppearance];
    [self updateWorkplaceWebBubbleLayout];
}

- (void)ensureWorkplaceWebBubbleAttached {
    UIView *hostView = [self workplaceWebBubbleHostView];
    if (!hostView || !self.workplaceWebBubbleView || !self.workplaceWebBubbleCloseButton) return;
    if (self.workplaceWebBubbleView.superview != hostView) {
        [self.workplaceWebBubbleView removeFromSuperview];
        [hostView addSubview:self.workplaceWebBubbleView];
    }
    if (self.workplaceWebBubbleCloseButton.superview != hostView) {
        [self.workplaceWebBubbleCloseButton removeFromSuperview];
        [hostView addSubview:self.workplaceWebBubbleCloseButton];
    }
    [self bringWorkplaceWebBubbleToFront];
}

- (void)consumePendingWorkplaceWebBubbleIfNeeded {
    WKWorkplaceWebBubbleStore *store = [WKWorkplaceWebBubbleStore shared];
    if (store.shouldShowBubble) {
        store.shouldShowBubble = NO;
        [self showWorkplaceWebBubble];
    }
}

- (void)showWorkplaceWebBubble {
    WKWorkplaceWebBubbleStore *store = [WKWorkplaceWebBubbleStore shared];
    if (store.urlString.length == 0) return;

    [self ensureWorkplaceWebBubbleAttached];
    self.workplaceWebBubbleXVisible = NO;
    self.workplaceWebBubbleCloseButton.hidden = YES;
    self.workplaceWebBubbleView.hidden = NO;
    [self updateWorkplaceWebBubbleAppearance];
    [self updateWorkplaceWebBubbleLayout];

    NSURL *iconURL = WKWorkplaceAbsoluteIconURL(store.icon);
    UIImage *ph = [WKApp shared].config.defaultPlaceholder;
    if (iconURL) {
        [self.workplaceWebBubbleIconView lim_setImageWithURL:iconURL placeholderImage:ph];
    } else {
        self.workplaceWebBubbleIconView.image = ph;
    }
    [self bringWorkplaceWebBubbleToFront];
}

- (void)hideWorkplaceWebBubble {
    self.workplaceWebBubbleView.hidden = YES;
    self.workplaceWebBubbleCloseButton.hidden = YES;
    self.workplaceWebBubbleXVisible = NO;
}

- (void)bringWorkplaceWebBubbleToFront {
    if (self.workplaceWebBubbleView.superview) {
        [self.workplaceWebBubbleView.superview bringSubviewToFront:self.workplaceWebBubbleView];
    }
    if (self.workplaceWebBubbleCloseButton.superview) {
        [self.workplaceWebBubbleCloseButton.superview bringSubviewToFront:self.workplaceWebBubbleCloseButton];
    }
}

- (void)onWorkplaceWebBubbleTapped {
    if (self.workplaceWebBubbleView.hidden) return;

    if (!self.workplaceWebBubbleXVisible) {
        self.workplaceWebBubbleXVisible = YES;
        self.workplaceWebBubbleCloseButton.hidden = NO;
        [self updateWorkplaceWebBubbleLayout];
        [self bringWorkplaceWebBubbleToFront];
        return;
    }

    WKWorkplaceWebBubbleStore *store = [WKWorkplaceWebBubbleStore shared];
    if (store.urlString.length == 0) return;

    NSString *urlString = store.urlString;
    NSString *iconString = store.icon;
    [self hideWorkplaceWebBubble];
    store.pendingDismiss = YES;
    store.shouldShowBubble = NO;
    WKResumeOrOpenWorkplaceWebSession(urlString);
    store.icon = iconString;
}

- (void)onWorkplaceWebBubbleCloseTapped {
    [[WKWorkplaceWebBubbleStore shared] clear];
    [self hideWorkplaceWebBubble];
}

- (void)handleWorkplaceWebBubblePan:(UIPanGestureRecognizer *)gesture {
    if (!self.workplaceWebBubbleView || self.workplaceWebBubbleView.hidden) return;
    UIView *hostView = [self workplaceWebBubbleHostView];
    if (!hostView) return;

    CGPoint translation = [gesture translationInView:hostView];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.workplaceWebBubblePanStartOrigin = self.workplaceWebBubbleView.frame.origin;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint targetOrigin = CGPointMake(self.workplaceWebBubblePanStartOrigin.x + translation.x,
                                               self.workplaceWebBubblePanStartOrigin.y + translation.y);
            self.workplaceWebBubbleHasManualPosition = YES;
            self.workplaceWebBubbleManualOrigin = [self clampedWorkplaceWebBubbleOrigin:targetOrigin inHostView:hostView];
            [self updateWorkplaceWebBubbleLayout];
            [self bringWorkplaceWebBubbleToFront];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            if (self.workplaceWebBubbleHasManualPosition) {
                [self snapWorkplaceWebBubbleToNearestEdge];
            }
            break;
        default:
            break;
    }
}

- (CGPoint)clampedWorkplaceWebBubbleOrigin:(CGPoint)origin inHostView:(UIView *)hostView {
    CGFloat edgeInset = 8.0f;
    UIEdgeInsets safeInsets = hostView.safeAreaInsets;
    CGFloat bubbleSize = self.workplaceWebBubbleView.bounds.size.width;
    CGFloat minX = safeInsets.left + edgeInset;
    CGFloat maxX = MAX(minX, hostView.bounds.size.width - safeInsets.right - bubbleSize - edgeInset);
    CGFloat minY = safeInsets.top + edgeInset;
    CGFloat maxY = MAX(minY, hostView.bounds.size.height - safeInsets.bottom - bubbleSize - edgeInset);
    return CGPointMake(MIN(MAX(origin.x, minX), maxX), MIN(MAX(origin.y, minY), maxY));
}

- (void)snapWorkplaceWebBubbleToNearestEdge {
    UIView *hostView = [self workplaceWebBubbleHostView];
    if (!hostView || !self.workplaceWebBubbleView) return;

    CGFloat edgeInset = 8.0f;
    CGFloat bubbleSize = self.workplaceWebBubbleView.bounds.size.width;
    UIEdgeInsets safeInsets = hostView.safeAreaInsets;
    CGPoint clampedOrigin = [self clampedWorkplaceWebBubbleOrigin:self.workplaceWebBubbleManualOrigin inHostView:hostView];
    CGFloat leftX = safeInsets.left + edgeInset;
    CGFloat rightX = MAX(leftX, hostView.bounds.size.width - safeInsets.right - bubbleSize - edgeInset);
    CGFloat targetX = fabs(clampedOrigin.x - leftX) <= fabs(clampedOrigin.x - rightX) ? leftX : rightX;
    self.workplaceWebBubbleManualOrigin = CGPointMake(targetX, clampedOrigin.y);

    [UIView animateWithDuration:0.18 animations:^{
        [self updateWorkplaceWebBubbleLayout];
    }];
}

- (void)updateWorkplaceWebBubbleAppearance {
    if (!self.workplaceWebBubbleView || !self.workplaceWebBubbleCloseButton) return;
    self.workplaceWebBubbleView.layer.borderColor = WKWorkplaceWebBubbleBorderColor().CGColor;
    self.workplaceWebBubbleBlurView.effect = [UIBlurEffect effectWithStyle:WKWorkplaceWebBubbleBlurStyle(self.traitCollection)];
    self.workplaceWebBubbleTintView.backgroundColor = WKWorkplaceWebBubbleBackgroundColor();
    self.workplaceWebBubbleTintView.alpha = 0.55f;
    self.workplaceWebBubbleCloseButton.layer.borderColor = WKWorkplaceWebBubbleCloseBorderColor().CGColor;
    [self.workplaceWebBubbleCloseButton setTitleColor:WKWorkplaceWebBubbleCloseTintColor() forState:UIControlStateNormal];
}

- (void)updateWorkplaceWebBubbleLayout {
    if (!self.workplaceWebBubbleView) return;
    [self ensureWorkplaceWebBubbleAttached];
    UIView *hostView = [self workplaceWebBubbleHostView];
    if (!hostView) return;

    CGFloat bubbleSize = self.workplaceWebBubbleView.bounds.size.width;
    CGFloat edgeInset = 16.0f;
    UIEdgeInsets safeInsets = hostView.safeAreaInsets;
    CGPoint targetOrigin;
    if (self.workplaceWebBubbleHasManualPosition) {
        targetOrigin = [self clampedWorkplaceWebBubbleOrigin:self.workplaceWebBubbleManualOrigin inHostView:hostView];
    } else {
        CGFloat x = hostView.bounds.size.width - safeInsets.right - bubbleSize - edgeInset;
        CGFloat y = (hostView.bounds.size.height - bubbleSize) / 2.0f;
        targetOrigin = [self clampedWorkplaceWebBubbleOrigin:CGPointMake(x, y) inHostView:hostView];
    }
    self.workplaceWebBubbleManualOrigin = targetOrigin;
    self.workplaceWebBubbleView.frame = CGRectMake(targetOrigin.x, targetOrigin.y, bubbleSize, bubbleSize);
    self.workplaceWebBubbleView.layer.cornerRadius = bubbleSize / 2.0f;
    self.workplaceWebBubbleView.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.workplaceWebBubbleView.bounds].CGPath;

    self.workplaceWebBubbleBlurView.frame = self.workplaceWebBubbleView.bounds;
    self.workplaceWebBubbleBlurView.layer.cornerRadius = bubbleSize / 2.0f;
    self.workplaceWebBubbleTintView.frame = self.workplaceWebBubbleBlurView.contentView.bounds;
    self.workplaceWebBubbleIconView.frame = CGRectInset(self.workplaceWebBubbleView.bounds, 11.0f, 11.0f);
    self.workplaceWebBubbleIconView.layer.cornerRadius = self.workplaceWebBubbleIconView.bounds.size.width / 2.0f;

    CGFloat closeSize = self.workplaceWebBubbleCloseButton.bounds.size.width;
    CGFloat closeX = CGRectGetMinX(self.workplaceWebBubbleView.frame) - closeSize + 12.0f;
    CGFloat closeY = CGRectGetMinY(self.workplaceWebBubbleView.frame) + 2.0f;
    CGFloat minCloseY = safeInsets.top + 8.0f;
    CGFloat maxCloseY = MAX(minCloseY, hostView.bounds.size.height - safeInsets.bottom - closeSize - 8.0f);
    self.workplaceWebBubbleCloseButton.frame = CGRectMake(closeX, MIN(MAX(closeY, minCloseY), maxCloseY), closeSize, closeSize);
}

@end
