#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKTradeSystemNotifyContent : WKMessageContent

@property (nonatomic, copy) NSString *transferNo;
@property (nonatomic, copy) NSString *fromUid;
@property (nonatomic, copy) NSString *toUid;
@property (nonatomic, assign) double amount;
@property (nonatomic, copy) NSString *content;

@end

NS_ASSUME_NONNULL_END
