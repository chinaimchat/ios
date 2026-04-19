#import "WKWalletChannelUtil.h"
#import <WuKongBase/WuKongBase.h>

@implementation WKWalletChannelUtil

+ (NSArray<NSDictionary *> *)customerServiceArrayFromAPIResult:(id)result {
    NSArray *arr = nil;
    NSArray<NSString *> *keys = @[
        @"data", @"list", @"items", @"rows", @"result",
        @"customer_services", @"services", @"records"
    ];
    if ([result isKindOfClass:[NSArray class]]) {
        arr = (NSArray *)result;
    } else if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = (NSDictionary *)result;
        for (NSString *k in keys) {
            id v = d[k];
            if ([v isKindOfClass:[NSArray class]]) {
                arr = v;
                break;
            }
            if ([v isKindOfClass:[NSDictionary class]]) {
                NSDictionary *inner = (NSDictionary *)v;
                for (NSString *ik in keys) {
                    id iv = inner[ik];
                    if ([iv isKindOfClass:[NSArray class]]) {
                        arr = iv;
                        break;
                    }
                }
                if (arr) {
                    break;
                }
            }
        }
    }
    NSMutableArray *out = [NSMutableArray array];
    for (id item in arr) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            [out addObject:(NSDictionary *)item];
        }
    }
    return out;
}

+ (NSArray<NSDictionary *> *)channelArrayFromAPIResult:(id)result {
    NSArray *arr = nil;
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = (NSDictionary *)result;
        if ([d[@"list"] isKindOfClass:[NSArray class]]) {
            arr = d[@"list"];
        } else if ([d[@"data"] isKindOfClass:[NSArray class]]) {
            arr = d[@"data"];
        } else if ([d[@"data"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *inner = d[@"data"];
            if ([inner[@"list"] isKindOfClass:[NSArray class]]) {
                arr = inner[@"list"];
            }
        }
    } else if ([result isKindOfClass:[NSArray class]]) {
        arr = (NSArray *)result;
    }
    NSMutableArray *out = [NSMutableArray array];
    for (id item in arr) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            [out addObject:(NSDictionary *)item];
        }
    }
    return out;
}

+ (NSInteger)channelPayType:(NSDictionary *)ch {
    id pt = ch[@"pay_type"] ?: ch[@"payType"];
    if ([pt isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)pt integerValue];
    }
    if ([pt isKindOfClass:[NSString class]]) {
        return [(NSString *)pt integerValue];
    }
    return 0;
}

+ (BOOL)channelIsEnabled:(NSDictionary *)ch {
    NSInteger st = [ch[@"status"] integerValue];
    return st != 2;
}

+ (long long)channelId:(NSDictionary *)ch {
    id v = ch[@"id"] ?: ch[@"channel_id"];
    if ([v isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)v longLongValue];
    }
    if ([v isKindOfClass:[NSString class]]) {
        return [(NSString *)v longLongValue];
    }
    return 0;
}

+ (NSString *)channelDisplayName:(NSDictionary *)ch {
    NSArray *keys = @[ @"title", @"name", @"channel_name" ];
    for (NSString *k in keys) {
        id v = ch[k];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
            return (NSString *)v;
        }
    }
    return LLangC(@"充值渠道", [WKWalletChannelUtil class]);
}

+ (NSString *)channelDepositAddress:(NSDictionary *)ch {
    NSArray *keys = @[
        @"pay_address", @"chain_address", @"on_chain_address", @"deposit_address",
        @"wallet_address", @"receive_address", @"recharge_deposit_address", @"remark"
    ];
    for (NSString *k in keys) {
        id v = ch[k];
        if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
            return (NSString *)v;
        }
    }
    return @"";
}

+ (NSString *)channelQrImageURL:(NSDictionary *)ch {
    NSArray *keys = @[
        @"qr_image_url", @"qrcode_image_url", @"qrcode_url", @"deposit_qr_url",
        @"qr_code_url", @"pay_qrcode_url", @"image", @"qrcode_image"
    ];
    for (NSString *k in keys) {
        id v = ch[k];
        if ([v isKindOfClass:[NSString class]]) {
            NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (s.length > 4 && ([s hasPrefix:@"http"] || [s hasPrefix:@"//"])) {
                return s;
            }
        }
    }
    return @"";
}

+ (double)channelMinAmount:(NSDictionary *)ch {
    id v = ch[@"min_amount"];
    if ([v respondsToSelector:@selector(doubleValue)]) {
        return [v doubleValue];
    }
    return 0;
}

+ (double)channelMaxAmount:(NSDictionary *)ch {
    id v = ch[@"max_amount"];
    if ([v respondsToSelector:@selector(doubleValue)]) {
        return [v doubleValue];
    }
    return 0;
}

+ (double)channelUcoinCnyPerU:(NSDictionary *)ch {
    id k = ch[@"install_key"] ?: ch[@"exchange_rate"];
    if ([k isKindOfClass:[NSString class]]) {
        return [(NSString *)k doubleValue];
    }
    if ([k isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)k doubleValue];
    }
    return 0;
}

+ (NSArray<NSDictionary *> *)channelsSortedForDeposit:(NSArray<NSDictionary *> *)all {
    NSMutableArray *uFirst = [NSMutableArray array];
    NSMutableArray *rest = [NSMutableArray array];
    for (NSDictionary *c in all) {
        if (![self channelIsEnabled:c]) {
            continue;
        }
        if ([self channelPayType:c] == 4) {
            [uFirst addObject:c];
        } else if ([[self channelDepositAddress:c] length] > 0) {
            [rest addObject:c];
        }
    }
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:uFirst.count + rest.count];
    [out addObjectsFromArray:uFirst];
    [out addObjectsFromArray:rest];
    return out;
}

+ (NSArray<NSDictionary *> *)channelsFilteredForWithdraw:(NSArray<NSDictionary *> *)all {
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *c in all) {
        if ([self channelIsEnabled:c] && [self channelPayType:c] == 4) {
            [out addObject:c];
        }
    }
    return out;
}

+ (void)partitionEnabledChannels:(NSArray<NSDictionary *> *)src
                          outCny:(NSMutableArray<NSDictionary *> *)outCny
                        outUCoin:(NSMutableArray<NSDictionary *> *)outUCoin {
    [outCny removeAllObjects];
    [outUCoin removeAllObjects];
    if (src.count == 0) {
        return;
    }
    for (NSDictionary *ch in src) {
        if (![self channelIsEnabled:ch]) {
            continue;
        }
        NSInteger pt = [self channelPayType:ch];
        if (pt == 4) {
            [outUCoin addObject:ch];
        } else if (pt == 2 || pt == 3) {
            [outCny addObject:ch];
        }
    }
    if (outCny.count == 0) {
        for (NSDictionary *ch in src) {
            if (![self channelIsEnabled:ch]) {
                continue;
            }
            if ([self channelPayType:ch] != 4) {
                [outCny addObject:ch];
            }
        }
    }
}

+ (double)cnyPerUsdtForBuyPageOrNaN:(NSDictionary *)ch {
    NSInteger pt = [self channelPayType:ch];
    if (pt == 4) {
        double u = [self channelUcoinCnyPerU:ch];
        return (u > 0 && !isnan(u) && !isinf(u)) ? u : NAN;
    }
    id er = ch[@"exchange_rate"] ?: ch[@"exchangeRate"];
    if ([er isKindOfClass:[NSString class]]) {
        double v = [(NSString *)er doubleValue];
        return (v > 0 && !isnan(v) && !isinf(v)) ? v : NAN;
    }
    if ([er isKindOfClass:[NSNumber class]]) {
        double v = [(NSNumber *)er doubleValue];
        return (v > 0 && !isnan(v) && !isinf(v)) ? v : NAN;
    }
    return NAN;
}

+ (double)resolveCnyPerUsdtFromRawChannelList:(NSArray<NSDictionary *> *)list selectedCnyIndex:(NSInteger)selectedCnyIndex {
    NSMutableArray<NSDictionary *> *cny = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *ucoin = [NSMutableArray array];
    [self partitionEnabledChannels:list outCny:cny outUCoin:ucoin];

    NSDictionary *sel = nil;
    if (cny.count > 0) {
        NSInteger i = MIN(MAX(selectedCnyIndex, 0), (NSInteger)cny.count - 1);
        sel = cny[(NSUInteger)i];
    }
    if (sel) {
        double r = [self cnyPerUsdtForBuyPageOrNaN:sel];
        if (!isnan(r) && r > 0) {
            return r;
        }
    }
    for (NSDictionary *ch in ucoin) {
        double r = [self cnyPerUsdtForBuyPageOrNaN:ch];
        if (!isnan(r) && r > 0) {
            return r;
        }
    }
    for (NSDictionary *ch in cny) {
        if (sel != nil && ch == sel) {
            continue;
        }
        double r = [self cnyPerUsdtForBuyPageOrNaN:ch];
        if (!isnan(r) && r > 0) {
            return r;
        }
    }
    return NAN;
}

@end
