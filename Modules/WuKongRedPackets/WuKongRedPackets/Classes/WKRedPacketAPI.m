#import "WKRedPacketAPI.h"

@implementation WKRedPacketAPI

+ (instancetype)shared {
    static WKRedPacketAPI *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WKRedPacketAPI alloc] init];
    });
    return instance;
}

- (void)sendRedPacketType:(int)type
               channelId:(NSString *)channelId
             channelType:(int)channelType
             totalAmount:(double)totalAmount
              totalCount:(int)totalCount
                   toUid:(NSString *)toUid
                  remark:(NSString *)remark
                password:(NSString *)password
                callback:(WKRedPacketCallback)callback {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"type"] = @(type);
    params[@"channel_id"] = channelId;
    params[@"channel_type"] = @(channelType);
    params[@"total_amount"] = @(totalAmount);
    params[@"total_count"] = @(totalCount);
    params[@"remark"] = remark ?: @"恭喜发财，大吉大利";
    params[@"password"] = password;
    if (toUid) params[@"to_uid"] = toUid;

    [[WKAPIClient sharedClient] POST:@"/v1/redpacket/send" parameters:params].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)openRedPacket:(NSString *)packetNo callback:(WKRedPacketCallback)callback {
    [[WKAPIClient sharedClient] POST:@"/v1/redpacket/open" parameters:@{@"packet_no": packetNo}].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getRedPacketDetail:(NSString *)packetNo callback:(WKRedPacketCallback)callback {
    NSString *path = [NSString stringWithFormat:@"/v1/redpacket/%@", packetNo];
    [[WKAPIClient sharedClient] GET:path parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

- (void)getWalletBalanceSnapshotForPayPasswordGate:(WKRedPacketCallback)callback {
    [[WKAPIClient sharedClient] GET:@"/v1/wallet/balance" parameters:nil].then(^(id result) {
        if (callback) callback(result, nil);
    }).catch(^(NSError *error) {
        if (callback) callback(nil, error);
    });
}

@end
