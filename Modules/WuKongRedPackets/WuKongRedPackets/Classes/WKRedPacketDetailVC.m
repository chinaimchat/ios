#import "WKRedPacketDetailVC.h"
#import "WKRedPacketAPI.h"
#import "WKQQWalletColors.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

/// 对齐 Android WalletDisplayNameHelper：群成员备注/群名片 → 单聊频道名 → uid。
static NSString *WKRedPacketDisplayNameForUid(NSString *uid, NSString *chatChannelId, uint8_t chatChannelType) {
    if (uid.length == 0) {
        return @"";
    }
    if (chatChannelType == WK_GROUP && chatChannelId.length > 0) {
        WKChannel *ch = [WKChannel channelID:chatChannelId channelType:WK_GROUP];
        WKChannelMember *m = [[WKSDK shared].channelManager getMember:ch uid:uid];
        if (m.displayName.length > 0) {
            return m.displayName;
        }
        if (m.memberName.length > 0) {
            return m.memberName;
        }
    }
    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfoOfUser:uid];
    if (info.name.length > 0) {
        return info.name;
    }
    return uid;
}

@interface WKRedPacketDetailVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSString *packetNo;
@property (nonatomic, copy) NSString *detailChannelId;
@property (nonatomic, assign) uint8_t detailChannelType;
@property (nonatomic, assign) NSInteger redPacketTotalCount;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) CAGradientLayer *headerGradient;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *remarkLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *records;
@property (nonatomic, assign) BOOL hideRedPacketRecordEntry;

@end

@implementation WKRedPacketDetailVC

- (instancetype)initWithPacketNo:(NSString *)packetNo {
    return [self initWithPacketNo:packetNo channelId:nil channelType:WK_PERSON hideRedPacketRecordEntry:NO];
}

- (instancetype)initWithPacketNo:(NSString *)packetNo channelId:(NSString *)channelId channelType:(uint8_t)channelType {
    return [self initWithPacketNo:packetNo channelId:channelId channelType:channelType hideRedPacketRecordEntry:NO];
}

- (instancetype)initWithPacketNo:(NSString *)packetNo channelId:(NSString *)channelId channelType:(uint8_t)channelType hideRedPacketRecordEntry:(BOOL)hide {
    if (self = [super init]) {
        self.packetNo = packetNo;
        self.detailChannelId = [channelId copy] ?: @"";
        self.detailChannelType = (self.detailChannelId.length > 0) ? channelType : WK_PERSON;
        self.records = @[];
        self.redPacketTotalCount = 0;
        self.hideRedPacketRecordEntry = hide;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"红包详情");
    self.view.backgroundColor = UIColor.whiteColor;

    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 180)];
    self.headerView.clipsToBounds = YES;

    self.headerGradient = [CAGradientLayer layer];
    self.headerGradient.startPoint = CGPointMake(0, 0);
    self.headerGradient.endPoint = CGPointMake(1, 1);
    self.headerGradient.colors = @[
        (id)[WKQQWalletColors rpQQStart].CGColor,
        (id)[WKQQWalletColors rpQQMid].CGColor,
        (id)[WKQQWalletColors rpQQEnd].CGColor,
    ];
    self.headerGradient.locations = @[ @0, @0.5, @1 ];
    [self.headerView.layer insertSublayer:self.headerGradient atIndex:0];

    self.remarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.headerView.bounds.size.width - 40, 30)];
    self.remarkLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.remarkLabel.textColor = UIColor.whiteColor;
    self.remarkLabel.font = [UIFont systemFontOfSize:16];
    self.remarkLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.remarkLabel];

    self.amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, self.headerView.bounds.size.width - 40, 50)];
    self.amountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.amountLabel.textColor = [WKQQWalletColors rpQQAmount];
    self.amountLabel.font = [UIFont boldSystemFontOfSize:36];
    self.amountLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.amountLabel];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, self.headerView.bounds.size.width - 40, 30)];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.statusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.statusLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 180, self.view.bounds.size.width, self.view.bounds.size.height - 180) style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 50;
    self.tableView.allowsSelection = YES;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.tableView];

    if (!self.hideRedPacketRecordEntry) {
        UIButton *recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [recordBtn setTitle:LLang(@"红包记录") forState:UIControlStateNormal];
        [recordBtn.titleLabel setFont:[[WKApp shared].config appFontOfSize:15.0f]];
        UIColor *tint = [WKApp shared].config.themeColor;
        if (tint) {
            [recordBtn setTitleColor:tint forState:UIControlStateNormal];
        }
        [recordBtn addTarget:self action:@selector(onRedPacketRecord) forControlEvents:UIControlEventTouchUpInside];
        recordBtn.frame = CGRectMake(0.0f, 0.0f, 88.0f, 36.0f);
        [self setRightView:recordBtn];
    }

    [self loadDetail];
}

- (void)onRedPacketRecord {
    [[WKApp shared] invoke:@"wallet.present_redpacket_record_history" param:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat headerH = 180.0f;
    CGFloat top = self.navigationBar.lim_bottom;
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.headerView.autoresizingMask = UIViewAutoresizingNone;
    self.headerView.frame = CGRectMake(0.0f, top, w, headerH);
    self.headerGradient.frame = self.headerView.bounds;
    self.tableView.frame = CGRectMake(0.0f, top + headerH, w, h - top - headerH);
}

- (void)prefetchDisplayNamesForRecordsIfNeeded {
    NSMutableOrderedSet<NSString *> *pending = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *record in self.records) {
        NSString *uid = record[@"uid"];
        if (![uid isKindOfClass:[NSString class]] || uid.length == 0) {
            continue;
        }
        NSString *resolved = WKRedPacketDisplayNameForUid(uid, self.detailChannelId, self.detailChannelType);
        if ([resolved isEqualToString:uid]) {
            [pending addObject:uid];
        }
    }
    if (pending.count == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    for (NSString *uid in pending) {
        WKChannel *pc = [WKChannel personWithChannelID:uid];
        [[WKSDK shared].channelManager fetchChannelInfo:pc completion:^(WKChannelInfo *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
    }
}

- (void)loadDetail {
    [[WKRedPacketAPI shared] getRedPacketDetail:self.packetNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && !error) {
                if (self.detailChannelId.length == 0) {
                    NSString *rcid = result[@"channel_id"];
                    id rct = result[@"channel_type"];
                    if ([rcid isKindOfClass:[NSString class]] && [(NSString *)rcid length] > 0) {
                        self.detailChannelId = (NSString *)rcid;
                        if ([rct respondsToSelector:@selector(unsignedIntValue)]) {
                            self.detailChannelType = (uint8_t)[rct unsignedIntValue];
                        } else {
                            self.detailChannelType = WK_GROUP;
                        }
                    }
                }
                double myAmount = [result[@"my_amount"] doubleValue];
                self.remarkLabel.text = result[@"remark"] ?: @"恭喜发财，大吉大利";

                if (myAmount > 0) {
                    self.amountLabel.text = [NSString stringWithFormat:@"¥%.2f", myAmount];
                } else {
                    self.amountLabel.text = @"";
                }

                int remainingCount = [result[@"remaining_count"] intValue];
                int totalCount = [result[@"total_count"] intValue];
                self.redPacketTotalCount = totalCount;
                int status = [result[@"redpacket_status"] intValue];
                double totalAmount = [result[@"total_amount"] doubleValue];

                NSString *statusText;
                if (status == 2) {
                    statusText = @"红包已过期";
                } else if (remainingCount == 0) {
                    statusText = @"红包已领完";
                } else {
                    statusText = [NSString stringWithFormat:@"已领取 %d/%d 个, 共 %.2f 元", totalCount - remainingCount, totalCount, totalAmount];
                }
                self.statusLabel.text = statusText;

                self.records = result[@"records"] ?: @[];
                [self.tableView reloadData];
                [self prefetchDisplayNamesForRecordsIfNeeded];
            }
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"RecordCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = UIColor.whiteColor;
    }

    NSDictionary *record = self.records[indexPath.row];
    NSString *uid = record[@"uid"] ?: @"";
    double amount = [record[@"amount"] doubleValue];
    BOOL isBest = [record[@"is_best"] boolValue];

    NSString *showName = WKRedPacketDisplayNameForUid(uid, self.detailChannelId, self.detailChannelType);
    BOOL showBestLuck = isBest && self.redPacketTotalCount > 1;

    cell.textLabel.text = showBestLuck ? [NSString stringWithFormat:@"%@ 🏆", showName] : showName;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"¥%.2f", amount];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];

    NSString *avatarUrl = [WKAvatarUtil getAvatar:uid];
    if (avatarUrl.length > 0) {
        [cell.imageView lim_setImageWithURL:[NSURL URLWithString:avatarUrl] placeholderImage:[WKApp shared].config.defaultPlaceholder];
    } else {
        cell.imageView.image = [WKApp shared].config.defaultPlaceholder;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.imageView.layer.cornerRadius = CGRectGetWidth(cell.imageView.bounds) > 0 ? CGRectGetWidth(cell.imageView.bounds) * 0.5f : 18.0f;
    cell.imageView.clipsToBounds = YES;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ((NSUInteger)indexPath.row >= self.records.count) {
        return;
    }
    NSDictionary *record = self.records[indexPath.row];
    NSString *uid = record[@"uid"];
    if (uid.length == 0) {
        return;
    }
    int ff = [WKGroupTipNicknamePolicy forbiddenFlagFromLocalGroupChannel:self.detailChannelId.length ? [WKChannel channelID:self.detailChannelId channelType:self.detailChannelType] : nil];
    if ([WKGroupTipNicknamePolicy shouldBlockNicknameProfileJumpWithChannelId:self.detailChannelId channelType:self.detailChannelType forbiddenFlag:ff]) {
        [[[WKNavigationManager shared] topViewController].view showMsg:LLang(@"群内已禁止互加好友，无法通过此处查看成员资料")];
        return;
    }
    WKChannel *from = nil;
    if (self.detailChannelType == WK_GROUP && self.detailChannelId.length > 0) {
        from = [WKChannel channelID:self.detailChannelId channelType:WK_GROUP];
    }
    WKChannelMember *member = from ? [[WKSDK shared].channelManager getMember:from uid:uid] : nil;
    NSString *vercode = member.extra[WKChannelExtraKeyVercode] ?: @"";
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:@{ @"uid": uid, @"vercode": vercode }];
    if (from) {
        param[@"channel"] = from;
    }
    [[WKApp shared] invoke:WKPOINT_USER_INFO param:param];
}

@end
