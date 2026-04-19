#import "WKTransferAPI.h"

@implementation WKTransferAPI

+ (instancetype)shared {
    static WKTransferAPI *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WKTransferAPI alloc] init];
    });
    return instance;
}

- (void)sendTransferTo:(NSString *)toUid
                amount:(double)amount
                remark:(NSString *)remark
              password:(NSString *)password
              callback:(WKTransferCallback)callback {
    [self sendTransferTo:toUid
                  amount:amount
                  remark:remark
                password:password
               channelId:nil
             channelType:0
                payScene:nil
                callback:callback];
}

- (void)sendTransferTo:(NSString *)toUid
                amount:(double)amount
                remark:(NSString *)remark
              password:(NSString *)password
             channelId:(NSString * _Nullable)channelId
           channelType:(NSInteger)channelType
              payScene:(NSString * _Nullable)payScene
              callback:(WKTransferCallback)callback {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"to_uid"] = toUid ?: @"";
    params[@"amount"] = @(amount);
    params[@"remark"] = remark ?: @"";
    params[@"password"] = password ?: @"";

    // 与 Android 二开接口保持一致：channel_id 必填，channel_type 由上层按会话传入。
    if (channelId.length > 0) {
        params[@"channel_id"] = channelId;
    }
    if (channelType > 0) {
        params[@"channel_type"] = @(channelType);
    }
    if (payScene.length > 0) {
        params[@"pay_scene"] = payScene;
    }

    [[WKAPIClient sharedClient] POST:@"/v1/transfer/send" parameters:params].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)acceptTransfer:(NSString *)transferNo callback:(WKTransferCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/transfer/%@/accept", transferNo];
    [[WKAPIClient sharedClient] POST:path parameters:@{}].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getTransferDetail:(NSString *)transferNo callback:(WKTransferCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/transfer/%@", transferNo];
    [[WKAPIClient sharedClient] GET:path parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getWalletBalanceSnapshotForPayPasswordGate:(WKTransferCallback)callback {
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/balance" parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

@end
