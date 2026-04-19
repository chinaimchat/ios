#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android {@code RechargeDepositBottomSheet}：Material 底栏、卡片、二维码区、金额卡、底部「联系客服」胶囊。
@interface WKRechargeDepositSheetVC : UIViewController

+ (void)presentFromViewController:(UIViewController *)host;

@end

NS_ASSUME_NONNULL_END
