#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WKTransferMessageStatus) {
    WKTransferMessageStatusPending = 0,
    WKTransferMessageStatusAccepted = 1,
    WKTransferMessageStatusRefunded = 2,
};

@interface WKTransferContent : WKMessageContent

@property (nonatomic, copy) NSString *transferNo;
@property (nonatomic, assign) double amount;
@property (nonatomic, copy) NSString *remark;
@property (nonatomic, copy) NSString *fromUid;
@property (nonatomic, copy) NSString *toUid;
@property (nonatomic, assign) WKTransferMessageStatus transferStatus;

@end

NS_ASSUME_NONNULL_END
