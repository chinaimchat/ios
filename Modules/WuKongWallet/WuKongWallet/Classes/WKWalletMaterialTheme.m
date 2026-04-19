#import "WKWalletMaterialTheme.h"

@implementation WKWalletMaterialTheme

#define WKHEX(s) [UIColor colorWithRed:((s>>16)&0xFF)/255.0 green:((s>>8)&0xFF)/255.0 blue:(s&0xFF)/255.0 alpha:1.0]
#define WKHEXA(s,a) [UIColor colorWithRed:((s>>16)&0xFF)/255.0 green:((s>>8)&0xFF)/255.0 blue:(s&0xFF)/255.0 alpha:(a)]

+ (UIColor *)rechargeSheetPageBg { return WKHEX(0xF5F5F5); }
+ (UIColor *)rechargeSheetBarBg { return UIColor.whiteColor; }
+ (UIColor *)rechargeSheetCard { return UIColor.whiteColor; }
+ (UIColor *)rechargeSheetCardStroke { return WKHEXA(0x000000, 0.08); }
+ (UIColor *)rechargeSheetTitle { return WKHEX(0x212121); }
+ (UIColor *)rechargeSheetActionBlue { return WKHEX(0x1976D2); }
+ (UIColor *)rechargeSheetChainBlue { return WKHEX(0x1976D2); }
+ (UIColor *)rechargeSheetAddressBg { return WKHEX(0xF0F0F0); }
+ (UIColor *)rechargeSheetAddressText { return WKHEX(0x333333); }
+ (UIColor *)rechargeSheetMinLabel { return WKHEX(0x616161); }
+ (UIColor *)rechargeSheetMinValue { return WKHEX(0x757575); }
+ (UIColor *)rechargeSheetFooter { return WKHEX(0x9E9E9E); }
+ (UIColor *)rechargeSheetUsdtGreen { return WKHEX(0x26A17B); }
+ (UIColor *)rechargeSheetPickDivider { return WKHEX(0xE8E8E8); }

+ (UIColor *)rechargePageBg { return WKHEX(0xF5F5F7); }
+ (UIColor *)rechargeTextSub { return WKHEX(0x888888); }
+ (UIColor *)rechargeTextMain { return WKHEX(0x191919); }
+ (UIColor *)rechargeHint { return WKHEX(0xBBBBBB); }
+ (UIColor *)rechargeDivider { return WKHEX(0xE8E8E8); }

+ (UIColor *)buyUsdtPageBg { return WKHEX(0xF5F5F5); }
+ (UIColor *)buyUsdtAppbarBg { return UIColor.whiteColor; }
+ (UIColor *)buyUsdtCard { return UIColor.whiteColor; }
+ (UIColor *)buyUsdtCardStroke { return WKHEXA(0x000000, 0.08); }
+ (UIColor *)buyUsdtTextPrimary { return WKHEX(0x212121); }
+ (UIColor *)buyUsdtTextSecondary { return WKHEX(0x757575); }
+ (UIColor *)buyUsdtHint { return WKHEX(0x9E9E9E); }
+ (UIColor *)buyUsdtPrimary { return WKHEX(0x1976D2); }
+ (UIColor *)buyUsdtDivider { return WKHEX(0xE8E8E8); }
+ (UIColor *)buyUsdtConfirmBtnTint { return WKHEX(0x1976D2); }
+ (UIColor *)buyUsdtConfirmDisabled { return WKHEX(0xBDBDBD); }
+ (UIColor *)buyUsdtCsFabGlass { return [UIColor colorWithRed:0.965 green:0.345 blue:0.208 alpha:0.80]; }
+ (UIColor *)buyUsdtCsFabStroke { return [UIColor colorWithWhite:1 alpha:0.70]; }
+ (UIColor *)buyUsdtCsFabText { return UIColor.whiteColor; }

+ (void)applyMaterialCardStyleToView:(UIView *)view cornerRadius:(CGFloat)r {
    view.backgroundColor = [self buyUsdtCard];
    view.layer.cornerRadius = r;
    view.layer.masksToBounds = NO;
    view.layer.borderWidth = 0.5;
    view.layer.borderColor = [self buyUsdtCardStroke].CGColor;
    view.layer.shadowColor = UIColor.blackColor.CGColor;
    view.layer.shadowOpacity = 0.06;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.layer.shadowRadius = 3;
}

@end
