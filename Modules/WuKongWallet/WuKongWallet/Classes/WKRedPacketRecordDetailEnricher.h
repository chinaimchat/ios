#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android {@code TransactionRecordDetailEnricher}：对含 {@code related_id} 的红包/转账流水并行拉详情并补全；每次调用都会全量请求（不按次缓存跳过）。
@interface WKRedPacketRecordDetailEnricher : NSObject

/// 红包记录页（仅红包类型行）。
+ (void)scheduleParallelEnrichRedPacketRecords:(NSArray<NSMutableDictionary *> *)records completion:(void (^)(void))completion;

/// 钱包「交易记录」列表：红包 {@code GET /v1/redpacket/:no} + 转账 {@code GET /v1/transfer/:no}，并补群名/对端昵称，与 Android {@link TransactionRecordDetailEnricher#scheduleParallelEnrichOnce} 一致。
+ (void)scheduleParallelEnrichWalletTransactionRecords:(NSArray<NSMutableDictionary *> *)records completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
