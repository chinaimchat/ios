#import "WKRedPacketContent.h"

@implementation WKRedPacketContent

+ (NSNumber *)contentType {
    return @(9);
}

- (NSDictionary *)encodeWithJSON {
    return @{
        @"packet_no": self.packetNo ?: @"",
        @"packet_type": @(self.packetType),
        @"remark": self.remark ?: @"恭喜发财，大吉大利",
        @"sender_name": self.senderName ?: @"",
        @"status": @(self.status),
    };
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.packetNo = contentDic[@"packet_no"] ?: @"";
    id typeVal = contentDic[@"packet_type"];
    if (typeVal == nil || typeVal == [NSNull null]) {
        typeVal = contentDic[@"type"];
    }
    self.packetType = [typeVal integerValue];
    self.remark = contentDic[@"remark"] ?: @"恭喜发财，大吉大利";
    self.senderName = contentDic[@"sender_name"] ?: @"";

    if (contentDic[@"status"] != nil && contentDic[@"status"] != [NSNull null]) {
        self.status = [contentDic[@"status"] integerValue];
    } else if (contentDic[@"packet_status"] != nil && contentDic[@"packet_status"] != [NSNull null]) {
        self.status = [contentDic[@"packet_status"] integerValue];
    } else if (contentDic[@"redpacket_status"] != nil && contentDic[@"redpacket_status"] != [NSNull null]) {
        self.status = [contentDic[@"redpacket_status"] integerValue];
    } else {
        self.status = 0;
    }

    // 业务全局可能仍为进行中（他人还可领），但本人已领时本地必须用 3：浅色「已领取」皮肤；若误写成 1 会显示「红包已领完」。
    if (self.status == 0 && [self wk_decodeImpliesCurrentUserClaimed:contentDic]) {
        self.status = 3;
    }
}

/// 会话消息 JSON 里表示「当前用户已领过」的常见字段（与详情/开红包接口字段对齐，便于同步下发）。
- (BOOL)wk_decodeImpliesCurrentUserClaimed:(NSDictionary *)contentDic {
    if ([contentDic[@"received"] intValue] == 1) {
        return YES;
    }
    if ([contentDic[@"is_received"] intValue] == 1) {
        return YES;
    }
    if ([contentDic[@"opened"] boolValue] || [contentDic[@"opened"] intValue] == 1) {
        return YES;
    }
    if ([contentDic[@"is_claimed"] intValue] == 1 || [contentDic[@"claimed"] intValue] == 1) {
        return YES;
    }
    NSArray<NSString *> *amountKeys = @[ @"my_amount", @"received_amount", @"receive_amount", @"lucky_amount" ];
    for (NSString *k in amountKeys) {
        id v = contentDic[k];
        if (v != nil && v != [NSNull null] && [v respondsToSelector:@selector(doubleValue)]) {
            double dv = [v doubleValue];
            if (!isnan(dv) && dv > 0) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSString *)conversationDigest {
    NSString *remarkPart = self.remark.length > 0 ? self.remark : @"恭喜发财，大吉大利";
    if (self.status == 0) {
        return [NSString stringWithFormat:@"[红包] %@", remarkPart];
    }
    NSString *statusLabel = @"已领取";
    if (self.status == 1) {
        statusLabel = @"红包已领完";
    } else if (self.status == 2) {
        statusLabel = @"已过期";
    }
    return [NSString stringWithFormat:@"[红包] %@ · %@", remarkPart, statusLabel];
}

@end
