#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android {@link com.chat.wallet.widget.PayPasswordDialog}：底部白面板、标题、金额说明、6 位圆点、自定义数字键盘（不弹系统键盘）。
@interface WKPayPasswordBottomSheet : UIView

/// 展示前先移除该 window 上尚未卸下的同类面板，避免关闭动画未完成时挡住第二次点击。
+ (void)removeAllFromWindow:(UIWindow *)window;

/// 从 `hint`（一般为 `controller.view.window`）解析可用 keyWindow，兼容多 Scene。
+ (nullable UIWindow *)resolvedPresentationWindowFromHint:(nullable UIWindow *)hint;

/// @param title 通常为「请输入支付密码」
/// @param remark 如「红包 ¥1.00」，可为 nil
+ (nullable instancetype)presentWithTitle:(NSString *)title
                            remark:(nullable NSString *)remark
                        hostWindow:(UIWindow *)hostWindow
                        completion:(void (^)(NSString *password))completion
                         cancelled:(nullable void (^)(void))cancelled;

- (void)dismissAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
