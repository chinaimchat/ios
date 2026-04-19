#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// IM 下行 type=1020 钱包余额同步；与 Android {@code WKWalletBalanceSyncContent} 一致。不在会话内展示气泡，仅会话列表摘要。
@interface WKWalletBalanceSyncContent : WKMessageContent

@property (nonatomic, assign) int walletSyncVersion;
@property (nonatomic, assign) double balance;
@property (nonatomic, assign) double usdtAvailable;

@end

NS_ASSUME_NONNULL_END
