#import "WKTransferLocalSync.h"
#import "WKTransferContent.h"
#import <WuKongIMSDK/WKMessageDB.h>
#import <WuKongIMSDK/WKSDK.h>

@implementation WKTransferLocalSync

+ (WKTransferMessageStatus)transferStatusFromApiStatusCode:(int)apiCode {
    if (apiCode == 1) {
        return WKTransferMessageStatusAccepted;
    }
    if (apiCode == 2) {
        return WKTransferMessageStatusRefunded;
    }
    return WKTransferMessageStatusPending;
}

+ (void)applyTransferStatus:(WKTransferMessageStatus)status toTransferMessage:(WKMessage *)message {
    if (![message.content isKindOfClass:[WKTransferContent class]]) {
        return;
    }
    WKTransferContent *c = (WKTransferContent *)message.content;
    c.transferStatus = status;
    NSData *data = [c encode];
    message.contentData = data;
    [[WKMessageDB shared] updateMessageContent:data status:message.status extra:message.extra clientSeq:message.clientSeq];
    [[WKSDK shared].chatManager callMessageUpdateDelegate:message];
}

@end
