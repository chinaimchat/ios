#import "WKWalletAPI.h"

@implementation WKWalletAPI

+ (instancetype)shared {
    static WKWalletAPI *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WKWalletAPI alloc] init];
    });
    return instance;
}

- (void)getBalanceWithCallback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/balance" parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)setPayPassword:(NSString *)password callback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] POST:@"/v1/wallet/password" parameters:@{@"password": password}].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)changePayPasswordOld:(NSString *)oldPwd new:(NSString *)newPwd callback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] PUT:@"/v1/wallet/password" parameters:@{@"old_password": oldPwd, @"new_password": newPwd}].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getTransactionsPage:(int)page size:(int)size callback:(WKWalletCallback)callback {
    [self getTransactionsPage:page size:size startDate:nil endDate:nil callback:callback];
}

- (void)getTransactionsPage:(int)page size:(int)size startDate:(NSString *)startDate endDate:(NSString *)endDate callback:(WKWalletCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/wallet/transactions?page=%d&size=%d", page, size];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *s = [startDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *e = [endDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length > 0) {
        params[@"start_date"] = s;
    }
    if (e.length > 0) {
        params[@"end_date"] = e;
    }
    id p = params.count > 0 ? params : nil;
    [[WKAPIClient sharedClient] GET:path parameters:p].then(^(id result) {
        if (callback) {
            callback(result, nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)getRechargeChannelsWithCallback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/recharge/channels" parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)rechargeApplyWithBody:(NSDictionary *)body callback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] POST:@"/v1/wallet/recharge/apply" parameters:body ?: @{}].then(^(id result) {
        if (callback) callback([self dictionaryIfNeeded:result], nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)withdrawalApplyWithBody:(NSDictionary *)body callback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] POST:@"/v1/wallet/withdrawal/apply" parameters:body ?: @{}].then(^(id result) {
        if (callback) callback([self dictionaryIfNeeded:result], nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getWithdrawalFeeConfigWithChannelId:(long long)channelId callback:(WKWalletCallback)callback {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (channelId > 0) {
        params[@"channel_id"] = @(channelId);
    }
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/withdrawal/fee-config" parameters:params.count ? params : @{}].then(^(id result) {
        if (callback) callback([self dictionaryIfNeeded:result], nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getRechargeApplicationsPage:(int)page size:(int)size callback:(WKWalletCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/wallet/recharge/applications?page=%d&size=%d", page, size];
    [[WKAPIClient sharedClient] GET:path parameters:nil].then(^(id result) {
        if (callback) {
            callback([self dictionaryIfNeeded:result], nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)getWithdrawalListPage:(int)page size:(int)size callback:(WKWalletCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/wallet/withdrawal/list?page=%d&size=%d", page, size];
    [[WKAPIClient sharedClient] GET:path parameters:nil].then(^(id result) {
        if (callback) {
            callback([self dictionaryIfNeeded:result], nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)getCustomerServicesWithCallback:(WKWalletCallback)callback {
    [[WKAPIClient sharedClient] GET:@"/v1/manager/wallet/customer_service/list" parameters:nil].then(^(id result) {
        if (callback) {
            callback([self dictionaryIfNeeded:result], nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)getWithdrawalDetailWithWithdrawalNo:(NSString *)withdrawalNo callback:(WKWalletCallback)callback {
    NSString *no = [withdrawalNo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (no.length == 0) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:@"WKWalletAPI" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"withdrawal_no empty" }]);
        }
        return;
    }
    NSString *enc = [no stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    if (!enc.length) {
        enc = no;
    }
    NSString *path = [NSString stringWithFormat:@"/v1/wallet/withdrawal/detail/%@", enc];
    [[WKAPIClient sharedClient] GET:path parameters:nil].then(^(id result) {
        if (callback) {
            callback([self dictionaryIfNeeded:result], nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)getWithdrawalFeePreviewWithAmount:(NSString *)amount channelId:(long long)channelId callback:(WKWalletCallback)callback {
    if (amount.length == 0) {
        if (callback) callback(nil, [NSError errorWithDomain:@"WKWalletAPI" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"amount empty" }]);
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:amount forKey:@"amount"];
    if (channelId > 0) {
        params[@"channel_id"] = @(channelId);
    }
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/withdrawal/fee-preview" parameters:params].then(^(id result) {
        if (callback) callback([self dictionaryIfNeeded:result], nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (NSDictionary *)dictionaryIfNeeded:(id)result {
    if ([result isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)result;
    }
    return @{ @"raw": result ?: [NSNull null] };
}

@end
