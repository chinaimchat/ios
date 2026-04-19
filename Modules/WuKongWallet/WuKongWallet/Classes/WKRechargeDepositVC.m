#import "WKRechargeDepositVC.h"
#import "WKRechargeDepositSheetVC.h"

@interface WKRechargeDepositVC ()
@property (nonatomic, assign) BOOL didForwardToSheet;
@end

@implementation WKRechargeDepositVC

/// 旧入口已统一为 Material BottomSheet（与 Android {@code RechargeDepositBottomSheet} 一致）；若路由仍 push 本类，则自动弹出 Sheet。
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didForwardToSheet) {
        return;
    }
    self.didForwardToSheet = YES;

    UINavigationController *nav = self.navigationController;
    NSUInteger idx = nav ? [nav.viewControllers indexOfObject:self] : NSNotFound;
    UIViewController *host = (idx != NSNotFound && idx > 0) ? nav.viewControllers[idx - 1] : (nav ?: self);

    if (nav && idx != NSNotFound) {
        [nav popViewControllerAnimated:NO];
    }
    [WKRechargeDepositSheetVC presentFromViewController:host];
}

@end
