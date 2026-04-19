#import <Foundation/Foundation.h>
#import "WKTransferContent.h"

@class WKMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WKTransferLocalSync : NSObject

+ (WKTransferMessageStatus)transferStatusFromApiStatusCode:(int)apiCode;

+ (void)applyTransferStatus:(WKTransferMessageStatus)status toTransferMessage:(WKMessage *)message;

@end

NS_ASSUME_NONNULL_END
