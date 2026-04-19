#import "WKWalletWithdrawalListUtil.h"
#import "WKWalletRechargeApplicationUtil.h"

@implementation WKWalletWithdrawalListUtil

+ (NSArray<NSString *> *)listKeys {
    return @[ @"data", @"list", @"items", @"rows", @"result", @"withdrawals", @"records" ];
}

+ (NSArray<NSDictionary *> *)dictArrayFrom:(NSArray *)arr {
    NSMutableArray *out = [NSMutableArray array];
    for (id o in arr) {
        if ([o isKindOfClass:[NSDictionary class]]) {
            [out addObject:o];
        }
    }
    return out;
}

+ (NSArray<NSDictionary *> *)withdrawalListFromAPIResult:(id)result {
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = (NSDictionary *)result;
        for (NSString *k in [self listKeys]) {
            id v = d[k];
            if ([v isKindOfClass:[NSArray class]]) {
                return [self dictArrayFrom:v];
            }
            if ([v isKindOfClass:[NSDictionary class]]) {
                NSDictionary *inner = (NSDictionary *)v;
                for (NSString *k2 in [self listKeys]) {
                    id v2 = inner[k2];
                    if ([v2 isKindOfClass:[NSArray class]]) {
                        return [self dictArrayFrom:v2];
                    }
                }
            }
        }
    }
    if ([result isKindOfClass:[NSArray class]]) {
        return [self dictArrayFrom:result];
    }
    return @[];
}

+ (NSArray<NSDictionary *> *)sortedByCreatedDesc:(NSArray<NSDictionary *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        long long ma = [WKWalletRechargeApplicationUtil createdMillisForSort:a];
        long long mb = [WKWalletRechargeApplicationUtil createdMillisForSort:b];
        if (ma > mb) {
            return NSOrderedAscending;
        }
        if (ma < mb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

+ (nullable NSString *)withdrawalNo:(NSDictionary *)record {
    id v = record[@"withdrawal_no"] ?: record[@"withdrawalNo"];
    if ([v isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return s.length ? s : nil;
    }
    if (v != nil && v != [NSNull null]) {
        NSString *s = [[NSString stringWithFormat:@"%@", v] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return s.length ? s : nil;
    }
    return nil;
}

+ (NSInteger)resolveAuditStatus:(NSDictionary *)record {
    id v = record[@"status"] ?: record[@"withdrawal_status"] ?: record[@"withdrawalStatus"];
    if ([v isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)v integerValue];
    }
    if ([v isKindOfClass:[NSString class]]) {
        return [(NSString *)v integerValue];
    }
    return 0;
}

+ (double)doubleForKey:(NSDictionary *)d key:(NSString *)key {
    id v = d[key];
    if ([v isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)v doubleValue];
    }
    if ([v isKindOfClass:[NSString class]]) {
        return [(NSString *)v doubleValue];
    }
    return NAN;
}

+ (NSString *)formatAmount4:(NSDictionary *)record key:(NSString *)key {
    double v = [self doubleForKey:record key:key];
    if (isnan(v) || v < 0) {
        return @"—";
    }
    return [NSString stringWithFormat:@"%.4f", v];
}

+ (NSString *)formatFeeCell:(NSDictionary *)record {
    double v = [self doubleForKey:record key:@"fee"];
    if (isnan(v) || v < 0) {
        return @"—";
    }
    if (v == 0) {
        return @"0";
    }
    if (fabs(v - floor(v)) < 1e-9) {
        return [NSString stringWithFormat:@"%.0f", v];
    }
    return [NSString stringWithFormat:@"%.4f", v];
}

@end
