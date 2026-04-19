#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WKWalletCallback)(NSDictionary * _Nullable result, NSError * _Nullable error);

@interface WKWalletAPI : NSObject

+ (instancetype)shared;

- (void)getBalanceWithCallback:(WKWalletCallback)callback;
- (void)setPayPassword:(NSString *)password callback:(WKWalletCallback)callback;
- (void)changePayPasswordOld:(NSString *)oldPwd new:(NSString *)newPwd callback:(WKWalletCallback)callback;
- (void)getTransactionsPage:(int)page size:(int)size callback:(WKWalletCallback)callback;

/// 与 Android {@link WalletModel#getTransactions(int, int, String, String)}：{@code GET /v1/wallet/transactions}，可选 {@code start_date}、{@code end_date}。
- (void)getTransactionsPage:(int)page size:(int)size startDate:(nullable NSString *)startDate endDate:(nullable NSString *)endDate callback:(WKWalletCallback)callback;

/// 对齐 Android：用于估算余额 USDT 展示（CNY / cny_per_usdt）。
- (void)getRechargeChannelsWithCallback:(WKWalletCallback)callback;

/// 与 Android {@code WalletService#rechargeApply} 一致：{@code POST /v1/wallet/recharge/apply}。
- (void)rechargeApplyWithBody:(NSDictionary *)body callback:(WKWalletCallback)callback;

/// 与 Android {@code WalletService#withdrawalApply} 一致：{@code POST /v1/wallet/withdrawal/apply}。
- (void)withdrawalApplyWithBody:(NSDictionary *)body callback:(WKWalletCallback)callback;

/// {@code GET /v1/wallet/withdrawal/fee-config}，{@code channelId<=0} 时不传 query。
- (void)getWithdrawalFeeConfigWithChannelId:(long long)channelId callback:(WKWalletCallback)callback;

/// {@code GET /v1/wallet/withdrawal/fee-preview}，金额用字符串避免精度问题。
- (void)getWithdrawalFeePreviewWithAmount:(NSString *)amount channelId:(long long)channelId callback:(WKWalletCallback)callback;

/// 与 Android {@code GET /v1/wallet/recharge/applications} 一致。
- (void)getRechargeApplicationsPage:(int)page size:(int)size callback:(WKWalletCallback)callback;

/// 与 Android {@code WalletModel#getWithdrawalList}：{@code GET /v1/wallet/withdrawal/list}。
- (void)getWithdrawalListPage:(int)page size:(int)size callback:(WKWalletCallback)callback;

/// 与 Android {@code WalletModel#getWithdrawalDetail}：{@code GET /v1/wallet/withdrawal/detail/:withdrawal_no}。
- (void)getWithdrawalDetailWithWithdrawalNo:(NSString *)withdrawalNo callback:(WKWalletCallback)callback;

/// 与 Android {@code WalletService#getCustomerServices}：{@code GET /v1/manager/wallet/customer_service/list}。
- (void)getCustomerServicesWithCallback:(WKWalletCallback)callback;

@end

NS_ASSUME_NONNULL_END
