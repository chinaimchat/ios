#import <UIKit/UIKit.h>

@class WKMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WKOpenRedPacketOverlay : UIView

- (instancetype)initWithMessage:(WKMessage *)message;

- (void)present;

@end

NS_ASSUME_NONNULL_END
