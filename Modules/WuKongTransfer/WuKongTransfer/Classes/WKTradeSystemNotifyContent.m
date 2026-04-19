#import "WKTradeSystemNotifyContent.h"
#import "WKSystemNotifyDisplay.h"

@implementation WKTradeSystemNotifyContent

+ (NSNumber *)contentType {
    return @(1012);
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.transferNo = contentDic[@"transfer_no"] ?: @"";
    self.fromUid = contentDic[@"from_uid"] ?: @"";
    self.toUid = contentDic[@"to_uid"] ?: @"";
    self.amount = [contentDic[@"amount"] doubleValue];
    id rawContent = contentDic[@"content"];
    if ([rawContent isKindOfClass:[NSString class]]) {
        self.content = (NSString *)rawContent;
    } else if (rawContent != nil && rawContent != [NSNull null]) {
        self.content = [NSString stringWithFormat:@"%@", rawContent];
    } else {
        self.content = @"";
    }
}

- (NSDictionary *)encodeWithJSON {
    return @{
        @"transfer_no": self.transferNo ?: @"",
        @"from_uid": self.fromUid ?: @"",
        @"to_uid": self.toUid ?: @"",
        @"amount": @(self.amount),
        @"content": self.content ?: @"",
    };
}

- (NSString *)conversationDigest {
    NSDictionary *root = self.contentDict;
    if ([root isKindOfClass:[NSDictionary class]] && root.count > 0) {
        NSString *plain = [WKSystemNotifyDisplay plainShowTextFromNotifyContentRoot:root];
        if (plain.length > 0) {
            return [plain stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        }
    }
    return self.content.length > 0 ? self.content : @"[交易通知]";
}

@end
