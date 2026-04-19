#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android {@link com.chat.wallet.entity.RechargeApplicationRecord} / {@link WalletModel#parseRechargeApplicationListJson} 字段约定对齐。
@interface WKWalletRechargeApplicationUtil : NSObject

+ (NSArray<NSDictionary *> *)rechargeApplicationListFromAPIResult:(nullable id)result;

/// 从 {@code created_at} / {@code createdAt} 解析毫秒时间戳，用于排序；解析失败为 0（提现单等可复用）。
+ (long long)createdMillisForSort:(NSDictionary *)record;

/// 按 {@code created_at} 新→旧（与 Android 列表一致）。
+ (NSArray<NSDictionary *> *)sortedByCreatedDesc:(NSArray<NSDictionary *> *)list;

+ (NSInteger)resolveAuditStatus:(NSDictionary *)record;

/// 与 Android {@link WalletModel#formatRechargeApplicationTimeForDisplay} 一致：展示为 {@code yyyy/MM/dd HH:mm}（能解析时）。
+ (NSString *)formatTimeForDisplay:(nullable NSString *)createdAt;

+ (nullable NSString *)applicationNo:(NSDictionary *)record;

/// 列表「数量」列：优先 {@code amount_u}（与 Android {@code BuyUsdtOrderListActivity#formatQty} 一致）。
+ (NSString *)formatOrderQty:(NSDictionary *)record;

/// 列表「交易总额(CNY)」：{@code amount}（与 Android {@code formatCnyTotal} 一致）。
+ (NSString *)formatOrderCnyTotal:(NSDictionary *)record;

@end

NS_ASSUME_NONNULL_END
