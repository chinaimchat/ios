#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android {@code BuyUsdtOrderListActivity}：{@code GET /v1/wallet/recharge/applications} 卡片列表、下拉刷新、点进详情。
@interface WKBuyUsdtOrderListVC : WKBaseVC

/// YES：使用系统默认导航 push/pop（与 {@link WKWithdrawVC} 右上角「订单」一致）。NO：使用买币 Material 自底向上转场（充值成功后进订单等）。
@property (nonatomic, assign) BOOL useSystemNavigationTransition;

@end

NS_ASSUME_NONNULL_END
