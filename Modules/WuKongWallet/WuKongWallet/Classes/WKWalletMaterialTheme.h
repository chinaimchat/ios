#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android `colors_recharge_sheet.xml` / `colors_buy_usdt.xml` / `colors_recharge.xml` 对齐，供钱包 Material 风 UI 使用。
@interface WKWalletMaterialTheme : NSObject

+ (UIColor *)rechargeSheetPageBg;
+ (UIColor *)rechargeSheetBarBg;
+ (UIColor *)rechargeSheetCard;
+ (UIColor *)rechargeSheetCardStroke;
+ (UIColor *)rechargeSheetTitle;
+ (UIColor *)rechargeSheetActionBlue;
+ (UIColor *)rechargeSheetChainBlue;
+ (UIColor *)rechargeSheetAddressBg;
+ (UIColor *)rechargeSheetAddressText;
+ (UIColor *)rechargeSheetMinLabel;
+ (UIColor *)rechargeSheetMinValue;
+ (UIColor *)rechargeSheetFooter;
+ (UIColor *)rechargeSheetUsdtGreen;
+ (UIColor *)rechargeSheetPickDivider;

+ (UIColor *)rechargePageBg;
+ (UIColor *)rechargeTextSub;
+ (UIColor *)rechargeTextMain;
+ (UIColor *)rechargeHint;
+ (UIColor *)rechargeDivider;

+ (UIColor *)buyUsdtPageBg;
+ (UIColor *)buyUsdtAppbarBg;
+ (UIColor *)buyUsdtCard;
+ (UIColor *)buyUsdtCardStroke;
+ (UIColor *)buyUsdtTextPrimary;
+ (UIColor *)buyUsdtTextSecondary;
+ (UIColor *)buyUsdtHint;
+ (UIColor *)buyUsdtPrimary;
+ (UIColor *)buyUsdtDivider;
+ (UIColor *)buyUsdtConfirmBtnTint;
+ (UIColor *)buyUsdtConfirmDisabled;
+ (UIColor *)buyUsdtCsFabGlass;
+ (UIColor *)buyUsdtCsFabStroke;
+ (UIColor *)buyUsdtCsFabText;

+ (void)applyMaterialCardStyleToView:(UIView *)view cornerRadius:(CGFloat)r;

@end

NS_ASSUME_NONNULL_END
