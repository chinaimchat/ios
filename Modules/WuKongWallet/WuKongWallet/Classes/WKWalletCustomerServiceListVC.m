#import "WKWalletCustomerServiceListVC.h"
#import "WKWalletAPI.h"
#import "WKWalletChannelUtil.h"
#import <WuKongBase/WuKongBase.h>

@interface WKWalletCustomerServiceListVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation WKWalletCustomerServiceListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"联系客服");
    self.view.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.98 alpha:1.0];
    self.items = @[];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 72.0;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text = LLang(@"暂无钱包客服\n你可返回钱包首页点击「快捷购买 USDT」联系官方客服");
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.emptyLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],
    ]];

    [self loadList];
}

- (void)loadList {
    __weak typeof(self) weakSelf = self;
    [[WKWalletAPI shared] getCustomerServicesWithCallback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [WKAlertUtil showMsg:error.localizedDescription ?: LLang(@"加载失败")];
                return;
            }
            NSArray *list = [WKWalletChannelUtil customerServiceArrayFromAPIResult:result];
            weakSelf.items = list ?: @[];
            weakSelf.emptyLabel.hidden = weakSelf.items.count > 0;
            [weakSelf.tableView reloadData];
        });
    }];
}

#pragma mark - Row model

static NSString *WKWCSUid(NSDictionary *d) {
    NSArray *keys = @[ @"uid", @"user_uid", @"user_id", @"userId" ];
    for (NSString *k in keys) {
        id v = d[k];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length]) {
            return [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    return @"";
}

static NSString *WKWCSName(NSDictionary *d) {
    NSArray *keys = @[ @"name", @"nickname", @"user_name", @"userName" ];
    for (NSString *k in keys) {
        id v = d[k];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length]) {
            return (NSString *)v;
        }
    }
    return LLangC(@"客服", [WKWalletCustomerServiceListVC class]);
}

static NSString *WKWCSDesc(NSDictionary *d) {
    NSArray *keys = @[ @"description", @"desc", @"remark" ];
    for (NSString *k in keys) {
        id v = d[k];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length]) {
            return (NSString *)v;
        }
    }
    return @"";
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"wk_wallet_cs";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
        cell.backgroundColor = UIColor.whiteColor;
        cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        cell.textLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        cell.detailTextLabel.numberOfLines = 2;

        UIButton *chatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        chatBtn.tag = 88001;
        chatBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [chatBtn setTitle:LLang(@"联系") forState:UIControlStateNormal];
        [chatBtn setContentEdgeInsets:UIEdgeInsetsMake(6, 16, 6, 16)];
        chatBtn.backgroundColor = [UIColor colorWithRed:0.26 green:0.52 blue:0.96 alpha:1.0];
        [chatBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        chatBtn.layer.cornerRadius = 4.0;
        chatBtn.layer.masksToBounds = YES;
        [chatBtn addTarget:self action:@selector(onChatButton:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:chatBtn];
    }

    NSDictionary *item = self.items[(NSUInteger)indexPath.row];
    cell.textLabel.text = WKWCSName(item);
    cell.detailTextLabel.text = WKWCSDesc(item);

    UIImageView *iv = cell.imageView;
    iv.layer.cornerRadius = 22.0;
    iv.clipsToBounds = YES;
    iv.contentMode = UIViewContentModeScaleAspectFill;
    NSString *uid = WKWCSUid(item);
    NSURL *url = nil;
    id avatar = item[@"avatar"] ?: item[@"avatar_url"] ?: item[@"avatarUrl"];
    if ([avatar isKindOfClass:[NSString class]] && [(NSString *)avatar length]) {
        NSString *s = (NSString *)avatar;
        if ([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"]) {
            url = [NSURL URLWithString:s];
        } else {
            url = [NSURL URLWithString:[WKAvatarUtil getFullAvatarWIthPath:s]];
        }
    } else if (uid.length) {
        url = [NSURL URLWithString:[WKAvatarUtil getAvatar:uid]];
    }
    [iv lim_setImageWithURL:url placeholderImage:[WKApp shared].config.defaultAvatar];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIButton *chatBtn = [cell.contentView viewWithTag:88001];
    if (!chatBtn) {
        return;
    }
    CGFloat w = CGRectGetWidth(tableView.bounds);
    CGFloat btnW = 68.0;
    chatBtn.frame = CGRectMake(w - 16.0 - btnW, 20.0, btnW, 32.0);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)onChatButton:(UIButton *)sender {
    UIView *v = sender.superview;
    UITableViewCell *cell = nil;
    while (v) {
        if ([v isKindOfClass:[UITableViewCell class]]) {
            cell = (UITableViewCell *)v;
            break;
        }
        v = v.superview;
    }
    if (!cell) {
        return;
    }
    NSIndexPath *ip = [self.tableView indexPathForCell:cell];
    if (!ip) {
        return;
    }
    NSDictionary *item = self.items[(NSUInteger)ip.row];
    NSString *uid = WKWCSUid(item);
    if (uid.length == 0) {
        [WKAlertUtil showMsg:LLang(@"无效客服账号")];
        return;
    }
    WKChannel *ch = [[WKChannel alloc] initWith:uid channelType:WK_PERSON];
    [[WKApp shared] pushConversation:ch];
}

@end
