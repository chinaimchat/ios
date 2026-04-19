#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android {@code WithdrawalDetailActivity}：{@code GET /v1/wallet/withdrawal/detail/:withdrawal_no}。
@interface WKWithdrawalDetailVC : WKBaseVC

- (instancetype)initWithWithdrawalNo:(NSString *)withdrawalNo;

@end

NS_ASSUME_NONNULL_END
