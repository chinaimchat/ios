#import "WKRedPacketOpenContent.h"
#import "WKSystemNotifyDisplay.h"

@implementation WKRedPacketOpenContent

+ (NSNumber *)contentType {
    return @(1011);
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.packetNo = contentDic[@"packet_no"] ?: @"";
    self.uid = contentDic[@"uid"] ?: @"";
    self.amount = [contentDic[@"amount"] doubleValue];
    self.content = contentDic[@"content"] ?: @"";
}

- (NSDictionary *)encodeWithJSON {
    return @{
        @"packet_no": self.packetNo ?: @"",
        @"uid": self.uid ?: @"",
        @"amount": @(self.amount),
        @"content": self.content ?: @"",
    };
}

- (NSString *)conversationDigest {
    NSDictionary *root = self.contentDict;
    if ([root isKindOfClass:[NSDictionary class]] && root.count > 0) {
        NSString *plain = [WKSystemNotifyDisplay plainShowTextFromNotifyContentRoot:root];
        if (plain.length > 0) {
            return plain;
        }
    }
    return self.content.length > 0 ? self.content : @"[红包领取通知]";
}

@end
