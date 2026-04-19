#import "WKWalletBuyUsdtNavTransition.h"
#import "WKBuyUsdtOrderListVC.h"
#import "WKRechargeApplyDetailVC.h"
#import <WuKongBase/WuKongBase.h>
#import <objc/runtime.h>

static const void *kWKWalletBuyUsdtNavProxyKey = &kWKWalletBuyUsdtNavProxyKey;

#pragma mark - Timing (Material fast-out-slow-in ≈ Android interpolator)

static UICubicTimingParameters *WKWalletBuyUsdtTimingOpen(void) {
    return [[UICubicTimingParameters alloc] initWithControlPoint1:CGPointMake(0.4, 0.0) controlPoint2:CGPointMake(0.2, 1.0)];
}

static UICubicTimingParameters *WKWalletBuyUsdtTimingClose(void) {
    return WKWalletBuyUsdtTimingOpen();
}

#pragma mark - Animators (match wallet_buy_usdt_*.xml durations)

@interface WKWalletBuyUsdtOpenEnterAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end

@implementation WKWalletBuyUsdtOpenEnterAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    (void)transitionContext;
    return 0.32;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;

    CGRect endTo = [transitionContext finalFrameForViewController:toVC];
    if (CGRectIsEmpty(endTo)) {
        endTo = container.bounds;
    }
    toView.frame = endTo;
    CGFloat lift = CGRectGetHeight(container.bounds);
    toView.transform = CGAffineTransformMakeTranslation(0, lift);
    toView.alpha = 0.92f;
    if (toView.superview != container) {
        [container addSubview:toView];
    }

    UIViewPropertyAnimator *anim = [[UIViewPropertyAnimator alloc] initWithDuration:[self transitionDuration:transitionContext]
                                                                    timingParameters:WKWalletBuyUsdtTimingOpen()];
    [anim addAnimations:^{
        toView.transform = CGAffineTransformIdentity;
        toView.alpha = 1.0;
        fromView.alpha = 0.96f;
    }];
    [anim addCompletion:^(UIViewAnimatingPosition position) {
        (void)position;
        BOOL cancelled = [transitionContext transitionWasCancelled];
        if (cancelled) {
            [toView removeFromSuperview];
        }
        fromView.alpha = 1.0;
        [transitionContext completeTransition:!cancelled];
    }];
    [anim startAnimation];
}

@end

@interface WKWalletBuyUsdtCloseExitAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end

@implementation WKWalletBuyUsdtCloseExitAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    (void)transitionContext;
    return 0.28;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;

    CGRect endTo = [transitionContext finalFrameForViewController:toVC];
    if (CGRectIsEmpty(endTo)) {
        endTo = container.bounds;
    }
    toView.frame = endTo;
    toView.alpha = 0.96f;
    [container insertSubview:toView belowSubview:fromView];

    CGFloat drop = CGRectGetHeight(container.bounds);
    UIViewPropertyAnimator *anim = [[UIViewPropertyAnimator alloc] initWithDuration:[self transitionDuration:transitionContext]
                                                                    timingParameters:WKWalletBuyUsdtTimingClose()];
    [anim addAnimations:^{
        fromView.transform = CGAffineTransformMakeTranslation(0, drop);
        fromView.alpha = 0.9f;
        toView.alpha = 1.0;
    }];
    [anim addCompletion:^(UIViewAnimatingPosition position) {
        (void)position;
        BOOL cancelled = [transitionContext transitionWasCancelled];
        fromView.transform = CGAffineTransformIdentity;
        fromView.alpha = 1.0;
        if (cancelled) {
            toView.alpha = 0.96f;
        }
        [transitionContext completeTransition:!cancelled];
    }];
    [anim startAnimation];
}

@end

#pragma mark - Delegate proxy

@interface WKWalletBuyUsdtNavDelegateProxy : NSObject <UINavigationControllerDelegate>
@property (nonatomic, weak) id<UINavigationControllerDelegate> innerDelegate;
@end

@implementation WKWalletBuyUsdtNavDelegateProxy

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    return [self.innerDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.innerDelegate respondsToSelector:aSelector]) {
        return self.innerDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPush && [toVC isKindOfClass:[WKBuyUsdtOrderListVC class]]) {
        WKBuyUsdtOrderListVC *buyTo = (WKBuyUsdtOrderListVC *)toVC;
        if (!buyTo.useSystemNavigationTransition) {
            return [WKWalletBuyUsdtOpenEnterAnimator new];
        }
    }
    if (operation == UINavigationControllerOperationPush && [fromVC isKindOfClass:[WKBuyUsdtOrderListVC class]] &&
        [toVC isKindOfClass:[WKRechargeApplyDetailVC class]]) {
        WKBuyUsdtOrderListVC *buyFrom = (WKBuyUsdtOrderListVC *)fromVC;
        if (!buyFrom.useSystemNavigationTransition) {
            return [WKWalletBuyUsdtOpenEnterAnimator new];
        }
    }
    if (operation == UINavigationControllerOperationPop && [fromVC isKindOfClass:[WKBuyUsdtOrderListVC class]]) {
        WKBuyUsdtOrderListVC *buyFrom = (WKBuyUsdtOrderListVC *)fromVC;
        if (!buyFrom.useSystemNavigationTransition) {
            return [WKWalletBuyUsdtCloseExitAnimator new];
        }
    }
    if (operation == UINavigationControllerOperationPop && [fromVC isKindOfClass:[WKRechargeApplyDetailVC class]] &&
        [toVC isKindOfClass:[WKBuyUsdtOrderListVC class]]) {
        WKBuyUsdtOrderListVC *buyTo = (WKBuyUsdtOrderListVC *)toVC;
        if (!buyTo.useSystemNavigationTransition) {
            return [WKWalletBuyUsdtCloseExitAnimator new];
        }
    }
    if ([self.innerDelegate respondsToSelector:_cmd]) {
        return [self.innerDelegate navigationController:navigationController
                          animationControllerForOperation:operation
                                       fromViewController:fromVC
                                         toViewController:toVC];
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animator {
    if ([self.innerDelegate respondsToSelector:_cmd]) {
        return [self.innerDelegate navigationController:navigationController interactionControllerForAnimationController:animator];
    }
    return nil;
}

/// 自定义 push/pop 未提供 `UIPercentDrivenInteractiveTransition` 时，系统全屏右滑仍会走默认交互转场，与 `WKWalletBuyUsdt*Animator` 叠在一起会错乱；在买币订单/充值详情页关闭侧滑，离开后由 inner（如 `WKRootNavigationController`）的 didShow 再设回。
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self.innerDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.innerDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
    if (![navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    BOOL buyUsdtStackPage = ([viewController isKindOfClass:[WKBuyUsdtOrderListVC class]] &&
                             ![(WKBuyUsdtOrderListVC *)viewController useSystemNavigationTransition]) ||
                            [viewController isKindOfClass:[WKRechargeApplyDetailVC class]];
    if (buyUsdtStackPage) {
        navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

@end

#pragma mark - Public

@implementation WKWalletBuyUsdtNavTransition

+ (WKWalletBuyUsdtNavDelegateProxy *)proxyForNavigationController:(UINavigationController *)nav {
    WKWalletBuyUsdtNavDelegateProxy *proxy = objc_getAssociatedObject(nav, kWKWalletBuyUsdtNavProxyKey);
    if (![proxy isKindOfClass:[WKWalletBuyUsdtNavDelegateProxy class]]) {
        proxy = [[WKWalletBuyUsdtNavDelegateProxy alloc] init];
        objc_setAssociatedObject(nav, kWKWalletBuyUsdtNavProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (nav.delegate != proxy) {
        proxy.innerDelegate = nav.delegate;
        nav.delegate = proxy;
    }
    return proxy;
}

+ (void)pushOrderListOnNavigationController:(UINavigationController *)nav {
    [self pushOrderListOnNavigationController:nav useBuyUsdtMaterialTransition:YES];
}

+ (void)pushOrderListOnNavigationController:(UINavigationController *)nav useBuyUsdtMaterialTransition:(BOOL)material {
    if (!nav) {
        return;
    }
    [self proxyForNavigationController:nav];
    WKBuyUsdtOrderListVC *vc = [[WKBuyUsdtOrderListVC alloc] init];
    vc.useSystemNavigationTransition = !material;
    [nav pushViewController:vc animated:YES];
}

+ (UINavigationController *)resolvedNavigationFromPresenter:(UIViewController *)presenter {
    UINavigationController *nav = presenter.navigationController;
    if (!nav && [presenter isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)presenter;
    }
    if (!nav) {
        UIViewController *top = [[WKNavigationManager shared] topViewController];
        nav = top.navigationController;
    }
    return nav;
}

+ (void)pushOrderListResolvingNavigationFromPresenter:(UIViewController *)presenter {
    [self pushOrderListResolvingNavigationFromPresenter:presenter useBuyUsdtMaterialTransition:YES];
}

+ (void)pushOrderListResolvingNavigationFromPresenter:(UIViewController *)presenter useBuyUsdtMaterialTransition:(BOOL)material {
    UINavigationController *nav = [self resolvedNavigationFromPresenter:presenter];
    [self pushOrderListOnNavigationController:nav useBuyUsdtMaterialTransition:material];
}

@end
