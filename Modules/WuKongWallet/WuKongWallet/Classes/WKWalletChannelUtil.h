#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android `RechargeChannel` / `WalletModel` 解析约定对齐（用户端 {@code GET /v1/wallet/recharge/channels}）。
@interface WKWalletChannelUtil : NSObject

+ (NSArray<NSDictionary *> *)channelArrayFromAPIResult:(nullable id)result;

/// 与 Android {@code WalletModel#parseCustomerServiceListJson} 键名兼容。
+ (NSArray<NSDictionary *> *)customerServiceArrayFromAPIResult:(nullable id)result;

/// 充值入口：U 盾（pay_type=4）优先，其余需有展示地址（与 {@code RechargeDepositBottomSheet#loadChannels} 一致）。
+ (NSArray<NSDictionary *> *)channelsSortedForDeposit:(NSArray<NSDictionary *> *)all;

/// 提币：仅 pay_type==4 且已启用（与 {@code WithdrawActivity#loadUsdtChannels} 一致）。
+ (NSArray<NSDictionary *> *)channelsFilteredForWithdraw:(NSArray<NSDictionary *> *)all;

+ (long long)channelId:(NSDictionary *)ch;
+ (NSInteger)channelPayType:(NSDictionary *)ch;
+ (BOOL)channelIsEnabled:(NSDictionary *)ch;
+ (NSString *)channelDisplayName:(NSDictionary *)ch;
+ (NSString *)channelDepositAddress:(NSDictionary *)ch;

/// 与 Android {@code RechargeChannel#getDepositQrImageUrlOrEmpty} 常见字段对齐。
+ (NSString *)channelQrImageURL:(NSDictionary *)ch;

+ (double)channelMinAmount:(NSDictionary *)ch;
+ (double)channelMaxAmount:(NSDictionary *)ch;

/// U 盾汇率（元/U），来自 {@code install_key} / {@code exchange_rate}。
+ (double)channelUcoinCnyPerU:(NSDictionary *)ch;

/// 与 Android {@code RechargeChannel#getCnyPerUsdtForBuyPageOrNaN}：U 盾用 {@link #channelUcoinCnyPerU}；其它类型仅解析 {@code exchange_rate} 为「元/USDT」。
+ (double)cnyPerUsdtForBuyPageOrNaN:(NSDictionary *)ch;

/// 与 Android {@code WalletCnyPerUsdtRates#resolveCnyPerUsdtFromRawList}；{@code selectedCnyIndex} 钱包首页传 0。
+ (double)resolveCnyPerUsdtFromRawChannelList:(NSArray<NSDictionary *> *)list selectedCnyIndex:(NSInteger)selectedCnyIndex;

@end

NS_ASSUME_NONNULL_END
