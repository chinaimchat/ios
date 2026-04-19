#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android {@link com.chat.wallet.api.WalletModel#parseWithdrawalListJson} 与列表项展示字段。
@interface WKWalletWithdrawalListUtil : NSObject

+ (NSArray<NSString *> *)listKeys;

+ (NSArray<NSDictionary *> *)withdrawalListFromAPIResult:(id)result;

+ (NSArray<NSDictionary *> *)sortedByCreatedDesc:(NSArray<NSDictionary *> *)list;

+ (nullable NSString *)withdrawalNo:(NSDictionary *)record;

/// 审核态：0 待审 1 通过 2 拒绝（与 Android {@code WithdrawalListItem#resolveAuditStatus} 一致）。
+ (NSInteger)resolveAuditStatus:(NSDictionary *)record;

+ (NSString *)formatAmount4:(NSDictionary *)record key:(NSString *)key;

+ (NSString *)formatFeeCell:(NSDictionary *)record;

@end

NS_ASSUME_NONNULL_END
