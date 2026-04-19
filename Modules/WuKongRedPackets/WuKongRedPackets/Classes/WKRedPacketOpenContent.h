#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRedPacketOpenContent : WKMessageContent

@property (nonatomic, copy) NSString *packetNo;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, assign) double amount;
@property (nonatomic, copy) NSString *content;

@end

NS_ASSUME_NONNULL_END
