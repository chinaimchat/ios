#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android `wallet_buy_usdt_open_enter` / `wallet_buy_usdt_close_exit`：订单列表、充值详情自底部滑入，返回时下滑退出。
@interface WKWalletBuyUsdtNavTransition : NSObject

+ (void)pushOrderListOnNavigationController:(nullable UINavigationController *)nav;

/// @param material YES 时使用买币 Material 转场；NO 时与提现页「订单」相同，为系统默认 push。
+ (void)pushOrderListOnNavigationController:(nullable UINavigationController *)nav useBuyUsdtMaterialTransition:(BOOL)material;

/// 从钱包充值流程中的 presenting VC 解析导航栈并 push 订单列表（nav 为空时尝试 `WKNavigationManager`）。
+ (void)pushOrderListResolvingNavigationFromPresenter:(nullable UIViewController *)presenter;

/// @param material 含义同 {@link #pushOrderListOnNavigationController:useBuyUsdtMaterialTransition:}。
+ (void)pushOrderListResolvingNavigationFromPresenter:(nullable UIViewController *)presenter useBuyUsdtMaterialTransition:(BOOL)material;

@end

NS_ASSUME_NONNULL_END
