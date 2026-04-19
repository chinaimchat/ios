#import "WKTransferContent.h"

@implementation WKTransferContent

+ (NSNumber *)contentType {
    return @(10);
}

- (NSDictionary *)encodeWithJSON {
    return @{
        @"transfer_no": self.transferNo ?: @"",
        @"amount": @(self.amount),
        @"remark": self.remark ?: @"",
        @"from_uid": self.fromUid ?: @"",
        @"to_uid": self.toUid ?: @"",
        @"status": @(self.transferStatus),
    };
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.transferNo = contentDic[@"transfer_no"] ?: @"";
    self.amount = [contentDic[@"amount"] doubleValue];
    self.remark = contentDic[@"remark"] ?: @"";
    self.fromUid = contentDic[@"from_uid"] ?: @"";
    self.toUid = contentDic[@"to_uid"] ?: @"";

    if (contentDic[@"status"] != nil && contentDic[@"status"] != [NSNull null]) {
        self.transferStatus = [contentDic[@"status"] integerValue];
    } else if (contentDic[@"transfer_status"] != nil && contentDic[@"transfer_status"] != [NSNull null]) {
        self.transferStatus = [contentDic[@"transfer_status"] integerValue];
    } else {
        self.transferStatus = WKTransferMessageStatusPending;
    }

    if (self.transferStatus == WKTransferMessageStatusPending
        && ([contentDic[@"accepted"] intValue] == 1 || [contentDic[@"is_accepted"] boolValue])) {
        self.transferStatus = WKTransferMessageStatusAccepted;
    }
}

- (NSString *)conversationDigest {
    NSString *st = @"待确认收款";
    if (self.transferStatus == WKTransferMessageStatusAccepted) {
        st = @"已收款";
    } else if (self.transferStatus == WKTransferMessageStatusRefunded) {
        st = @"已退回";
    }
    return [NSString stringWithFormat:@"[转账] ¥%.2f · %@", self.amount, st];
}

@end
