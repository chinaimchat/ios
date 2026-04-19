#import "WKWalletModule.h"
#import "WKWalletVC.h"
#import "WKWalletBalanceSyncContent.h"
#import "WKSetPayPasswordVC.h"
#import "WKWalletScanParser.h"
#import <WuKongBase/WKMeItem.h>
#import <UIKit/UIKit.h>
#import <WuKongBase/WKScanHandler.h>
#import <WuKongTransfer/WKSendTransferVC.h>
#import <WuKongTransfer/WKTransferDetailVC.h>
#import <WuKongRedPackets/WKRedPacketDetailVC.h>
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKRedPacketRecordHistoryVC.h"

/// 与 Android RedPacketDetailActivity / TransferDetailActivity 的 Intent extras 一致：packet_no、transfer_no、可选 channel_id、channel_type。
/// 「我的钱包」个人中心图标：对齐 wkwallet `ic_wallet_menu.xml`（24dp 矢量，色值 #FF6B4A）。
static UIImage *WKMeWalletEntryIcon(void) {
    static UIImage *cached;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const CGFloat dp = 24.0f;
        CGSize sz = CGSizeMake(30.0f, 30.0f);
        CGFloat s = sz.width / dp;
        UIColor *fill = [UIColor colorWithRed:255.0f / 255.0f green:107.0f / 255.0f blue:74.0f / 255.0f alpha:1.0f];
        UIGraphicsBeginImageContextWithOptions(sz, NO, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ctx, s, s);
        [fill setFill];
        UIBezierPath *outer = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1.0f, 7.0f, 22.0f, 14.0f) cornerRadius:2.0f];
        UIBezierPath *inner = [UIBezierPath bezierPathWithRect:CGRectMake(3.0f, 9.0f, 18.0f, 10.0f)];
        UIBezierPath *wallet = [UIBezierPath bezierPath];
        [wallet appendPath:outer];
        [wallet appendPath:inner];
        wallet.usesEvenOddFillRule = YES;
        [wallet fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(5.0f, 5.0f, 14.0f, 2.0f)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(7.0f, 3.0f, 10.0f, 2.0f)] fill];
        [[UIBezierPath bezierPathWithArcCenter:CGPointMake(18.0f, 14.0f) radius:1.5f startAngle:0.0 endAngle:(CGFloat)(M_PI * 2.0) clockwise:YES] fill];
        cached = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return cached;
}

static void WKWalletPushDetailFromFlatParams(NSDictionary *d) {
    if (![d isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *packetNo = d[@"packet_no"];
    NSString *transferNo = d[@"transfer_no"];
    NSString *cid = [d[@"channel_id"] isKindOfClass:[NSString class]] ? d[@"channel_id"] : nil;
    if (!cid && d[@"channel_id"]) {
        cid = [NSString stringWithFormat:@"%@", d[@"channel_id"]];
    }
    NSNumber *ct = [d[@"channel_type"] isKindOfClass:[NSNumber class]] ? d[@"channel_type"] : nil;
    uint8_t cty = ct ? (uint8_t)[ct unsignedIntValue] : WK_PERSON;
    if (packetNo.length > 0) {
        WKRedPacketDetailVC *vc = cid.length > 0
            ? [[WKRedPacketDetailVC alloc] initWithPacketNo:packetNo channelId:cid channelType:cty hideRedPacketRecordEntry:NO]
            : [[WKRedPacketDetailVC alloc] initWithPacketNo:packetNo];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    } else if (transferNo.length > 0) {
        WKTransferDetailVC *vc = [[WKTransferDetailVC alloc] initWithTransferNo:transferNo];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }
}

@WKModule(WKWalletModule)

@implementation WKWalletModule

- (NSString *)moduleId {
    return @"WuKongWallet";
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongWallet】模块初始化！");
    __weak typeof(self) weakSelf = self;

    /// 与 Android WKWalletApplication 注册 WK_WALLET_BALANCE_SYNC 一致；否则 1020 会按系统消息解码为 WKSystemContent，正文无 content 时会话列表显示 (null)。
    [[WKSDK shared] registerMessageContent:[WKWalletBalanceSyncContent class]];

    /// 与 Android RedPacketDetailActivity 右上角进入 {@link RedPacketRecordHistoryActivity} 一致。
    [self setMethod:@"wallet.present_redpacket_record_history" handler:^id _Nullable(id _Nonnull param) {
        WKRedPacketRecordHistoryVC *vc = [[WKRedPacketRecordHistoryVC alloc] init];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return nil;
    }];

    /// 对齐 Android WalletTipTappableRoute.ENDPOINT_SID = "wallet_tip_open_detail"
    [self setMethod:@"wallet_tip_open_detail" handler:^id _Nullable(id _Nonnull param) {
        if (![param isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        NSDictionary *d = (NSDictionary *)param;
        WKWalletPushDetailFromFlatParams(d);
        return nil;
    }];

    /// 与 Android {@link WalletPayPasswordHelper#runIfPayPasswordReady} 跳转设置页一致；由发红包等模块 invoke，避免 WuKongRedPackets 依赖 WuKongWallet 产生循环引用。
    [self setMethod:@"wallet.present_set_pay_password" handler:^id _Nullable(id _Nonnull param) {
        WKSetPayPasswordVC *vc = [[WKSetPayPasswordVC alloc] init];
        vc.changePasswordMode = NO;
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return nil;
    }];

    /// 与产品稿一致：「我的钱包」独占菜单首行（sort 最高），`sectionHeight`≈安卓列表区 `marginTop` 10dp，其下 `nextSectionHeight`≈粗分隔 15dp，其余入口在下。
    [self setMethod:@"me.wallet" handler:^id _Nullable(id _Nonnull param) {
        WKMeItem *item = [WKMeItem initWithTitle:LLangW(@"我的钱包", weakSelf) icon:WKMeWalletEntryIcon() sectionHeight:10.0f onClick:^{
            [[WKNavigationManager shared] pushViewController:[WKWalletVC new] animated:YES];
        }];
        item.nextSectionHeight = 15.0f;
        return item;
    } category:WKPOINT_CATEGORY_ME sort:20000];

    // 扫码进入钱包收款码场景转账：对齐 Android pay_scene=receive_qr。
    [self setMethod:@"wallet.scan.receive_qr.transfer" handler:^id _Nullable(id _Nonnull param) {
        return [WKScanHandler handle:^BOOL(WKScanResult * _Nonnull result, void (^ _Nonnull reScanBlock)(void)) {
            if (!result) {
                return NO;
            }
            if (![WKWalletScanParser isReceiveQrScene:result]) {
                return NO;
            }

            NSString *toUid = [WKWalletScanParser extractReceiveUidFromData:result.data];
            if (toUid.length == 0) {
                return NO;
            }

            WKSendTransferVC *vc = [[WKSendTransferVC alloc] initWithToUid:toUid
                                                                 channelId:toUid
                                                               channelType:WK_PERSON
                                                                  payScene:@"receive_qr"];
            [[WKNavigationManager shared] pushViewController:vc animated:YES];
            return YES;
        }];
    } category:WKPOINT_CATEGORY_SCAN_HANDLER sort:7100];
}

- (BOOL)moduleDidFinishLaunching:(WKModuleContext *)context {
    return YES;
}

/// Android wkwallet 未在模块内解析远程推送；与之一致，本模块不实现 moduleDidReceiveRemoteNotification。
/// 以下为 iOS 可选深度链接（botgate + wallet 路径 + packet_no/transfer_no），便于运营配置；与 Java 端无对等代码时可忽略。
- (BOOL)moduleOpenURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (!url) {
        return NO;
    }
    if ([url.scheme caseInsensitiveCompare:@"botgate"] != NSOrderedSame) {
        return NO;
    }
    NSString *host = (url.host ?: @"").lowercaseString;
    NSString *path = (url.path ?: @"").lowercaseString;
    if (![host isEqualToString:@"wallet"] && ![path hasPrefix:@"/wallet"]) {
        return NO;
    }
    NSURLComponents *comp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableDictionary *q = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *it in comp.queryItems) {
        if (it.name.length) {
            q[it.name] = it.value ?: @"";
        }
    }
    NSString *qpn = q[@"packet_no"] ? [NSString stringWithFormat:@"%@", q[@"packet_no"]] : @"";
    NSString *qtn = q[@"transfer_no"] ? [NSString stringWithFormat:@"%@", q[@"transfer_no"]] : @"";
    if (qpn.length == 0 && qtn.length == 0) {
        return NO;
    }
    WKWalletPushDetailFromFlatParams(q);
    return YES;
}

@end
