#import "WKWalletRechargeApplicationUtil.h"

@implementation WKWalletRechargeApplicationUtil

+ (NSArray<NSString *> *)listKeys {
    return @[ @"data", @"list", @"items", @"rows", @"records", @"result", @"applications" ];
}

+ (NSArray<NSDictionary *> *)rechargeApplicationListFromAPIResult:(id)result {
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

+ (NSArray<NSDictionary *> *)dictArrayFrom:(NSArray *)arr {
    NSMutableArray *out = [NSMutableArray array];
    for (id o in arr) {
        if ([o isKindOfClass:[NSDictionary class]]) {
            [out addObject:o];
        }
    }
    return out;
}

+ (nullable NSDate *)parseCreatedAt:(NSString *)raw {
    if (raw.length == 0) {
        return nil;
    }
    NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray<NSString *> *patterns = @[
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy/MM/dd HH:mm:ss",
        @"yyyy-MM-dd HH:mm",
        @"yyyy/MM/dd HH:mm",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd'T'HH:mm:ss"
    ];
    NSLocale *us = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for (NSString *p in patterns) {
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.locale = us;
        f.dateFormat = p;
        f.timeZone = [NSTimeZone localTimeZone];
        NSDate *d = [f dateFromString:t];
        if (d) {
            return d;
        }
    }
    return nil;
}

+ (long long)createdMillisForSort:(NSDictionary *)r {
    NSString *ca = r[@"created_at"] ?: r[@"createdAt"];
    if (![ca isKindOfClass:[NSString class]]) {
        return 0;
    }
    NSDate *d = [self parseCreatedAt:(NSString *)ca];
    if (!d) {
        return 0;
    }
    return (long long)([d timeIntervalSince1970] * 1000.0);
}

+ (NSArray<NSDictionary *> *)sortedByCreatedDesc:(NSArray<NSDictionary *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        long long ma = [self createdMillisForSort:a];
        long long mb = [self createdMillisForSort:b];
        if (ma > mb) {
            return NSOrderedAscending;
        }
        if (ma < mb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

+ (NSInteger)resolveAuditStatus:(NSDictionary *)record {
    id v = record[@"audit_status"] ?: record[@"recharge_status"] ?: record[@"status"];
    if ([v respondsToSelector:@selector(integerValue)]) {
        return (NSInteger)[v integerValue];
    }
    return 0;
}

+ (NSString *)formatTimeForDisplay:(NSString *)raw {
    if (raw.length == 0) {
        return @"—";
    }
    NSDate *d = [self parseCreatedAt:raw];
    if (!d) {
        return raw;
    }
    NSDateFormatter *out = [[NSDateFormatter alloc] init];
    out.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    out.dateFormat = @"yyyy/MM/dd HH:mm";
    return [out stringFromDate:d];
}

+ (NSString *)applicationNo:(NSDictionary *)record {
    id v = record[@"application_no"] ?: record[@"applicationNo"];
    return [v isKindOfClass:[NSString class]] ? (NSString *)v : @"";
}

+ (double)doubleValue:(id)obj {
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [obj doubleValue];
    }
    return NAN;
}

+ (NSString *)formatOrderQty:(NSDictionary *)record {
    double u = [self doubleValue:record[@"amount_u"] ?: record[@"amountU"]];
    if (!isnan(u) && u > 0) {
        return [NSString stringWithFormat:@"%.4f", u];
    }
    return @"—";
}

+ (NSString *)formatOrderCnyTotal:(NSDictionary *)record {
    double v = [self doubleValue:record[@"amount"]];
    if (isnan(v)) {
        return @"—";
    }
    if (fabs(v - floor(v)) < 1e-9) {
        return [NSString stringWithFormat:@"%.0f", v];
    }
    NSString *s = [NSString stringWithFormat:@"%.2f", v];
    return s;
}

@end
