#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android {@link SetPayPasswordActivity}：{@code mode=set} / {@code mode=change}。
@interface WKSetPayPasswordVC : WKBaseVC

/** YES：原密码 → 新密码 → 确认后 {@link WKWalletAPI#changePayPasswordOld:new:callback:} */
@property (nonatomic, assign) BOOL changePasswordMode;

@end

NS_ASSUME_NONNULL_END
