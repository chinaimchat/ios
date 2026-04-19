#import "WKQQWalletColors.h"

@implementation WKQQWalletColors

+ (UIColor *)c:(NSUInteger)hex a:(CGFloat)a {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:a];
}

+ (UIColor *)rpQQCardShadow { return [UIColor colorWithWhite:0 alpha:0x38 / 255.0]; } /* #38000000 */
+ (UIColor *)rpQQCardStroke { return [UIColor colorWithWhite:1 alpha:0x66 / 255.0]; } /* #66FFFFFF */

+ (UIColor *)rpQQStart { return [self c:0xFF6A6A a:1]; }
+ (UIColor *)rpQQMid { return [self c:0xE53935 a:1]; }
+ (UIColor *)rpQQEnd { return [self c:0xB71C1C a:1]; }

+ (UIColor *)rpQQOpenedShadow { return [UIColor colorWithWhite:0 alpha:0x30 / 255.0]; } /* #30000000 */
+ (UIColor *)rpQQOpenedStroke { return [UIColor colorWithRed:1 green:245 / 255.0 blue:245 / 255.0 alpha:0x55 / 255.0]; }
+ (UIColor *)rpQQOpenedStart { return [self c:0xE5A3A3 a:1]; }
+ (UIColor *)rpQQOpenedMid { return [self c:0xC06B6B a:1]; }
+ (UIColor *)rpQQOpenedEnd { return [self c:0x965050 a:1]; }

+ (UIColor *)rpQQAmount { return [self c:0xFFD54F a:1]; }
+ (UIColor *)btnBarStart { return [self c:0xFF5E5E a:1]; }
+ (UIColor *)btnBarEnd { return [self c:0xC62828 a:1]; }

+ (UIColor *)pageBgWarm { return [UIColor colorWithRed:0.98 green:0.97 blue:0.95 alpha:1]; }

@end
