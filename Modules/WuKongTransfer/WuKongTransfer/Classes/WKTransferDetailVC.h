#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKTransferDetailVC : WKBaseVC

- (instancetype)initWithTransferNo:(NSString *)transferNo;
- (instancetype)initWithTransferNo:(NSString *)transferNo clientMsgNo:(nullable NSString *)clientMsgNo;

@end

NS_ASSUME_NONNULL_END
