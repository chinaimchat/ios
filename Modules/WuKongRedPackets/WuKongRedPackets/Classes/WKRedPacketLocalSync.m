#import "WKRedPacketLocalSync.h"
#import "WKRedPacketContent.h"
#import "WKRedPacketAPI.h"
#import <WuKongBase/WKApp.h>
#import <WuKongIMSDK/WKConst.h>
#import <WuKongIMSDK/WKMessageDB.h>
#import <WuKongIMSDK/WKSDK.h>

@implementation WKRedPacketLocalSync

+ (NSInteger)redPacketContentType {
    return [[WKRedPacketContent contentType] integerValue];
}

+ (NSDictionary *)dataSectionFromAPIResult:(NSDictionary *)result {
    if (![result isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    id data = result[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        return data;
    }
    return result;
}

+ (NSInteger)resolvedRedPacketStatusFromData:(NSDictionary *)data {
    if (!data.count) {
        return 1;
    }
    NSArray<NSString *> *keys = @[ @"redpacket_status", @"packet_status", @"status" ];
    for (NSString *k in keys) {
        id v = data[k];
        if (v != nil && v != [NSNull null]) {
            return [v intValue];
        }
    }
    return 1;
}

+ (NSInteger)localMessageStatusAfterOpenSuccessFromResponse:(NSDictionary *)response {
    NSDictionary *data = [self dataSectionFromAPIResult:response];
    int s = (int)[self resolvedRedPacketStatusFromData:data];
    return s == 0 ? 3 : s;
}

+ (double)resolvedOpenAmountFromResponse:(NSDictionary *)response {
    NSDictionary *data = [self dataSectionFromAPIResult:response];
    NSArray<NSString *> *keys = @[ @"my_amount", @"amount", @"received_amount", @"money", @"receive_amount", @"lucky_amount" ];
    for (NSString *k in keys) {
        id v = data[k];
        if ([v respondsToSelector:@selector(doubleValue)]) {
            double dv = [v doubleValue];
            if (!isnan(dv) && dv > 0) {
                return dv;
            }
        }
    }
    id root = response[@"amount"];
    if ([root respondsToSelector:@selector(doubleValue)]) {
        double dv = [root doubleValue];
        if (!isnan(dv) && dv > 0) {
            return dv;
        }
    }
    return NAN;
}

+ (BOOL)detailClaimsUser:(NSDictionary *)d uid:(NSString *)uid {
    double myAmt = [d[@"my_amount"] doubleValue];
    if (myAmt > 0) {
        return YES;
    }
    if (uid.length == 0) {
        return NO;
    }
    id records = d[@"records"];
    if (![records isKindOfClass:[NSArray class]]) {
        return NO;
    }
    for (id r in (NSArray *)records) {
        if (![r isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *ru = [NSString stringWithFormat:@"%@", ((NSDictionary *)r)[@"uid"] ?: @""];
        if (ru.length && [ru isEqualToString:uid]) {
            return YES;
        }
    }
    return NO;
}

+ (NSInteger)statusFromDetailDict:(NSDictionary *)d currentUid:(NSString *)uid {
    if (![d isKindOfClass:[NSDictionary class]]) {
        return 1;
    }
    int s = [d[@"redpacket_status"] intValue];
    BOOL meClaimed = [self detailClaimsUser:d uid:uid ?: @""];
    if (s == 0 && meClaimed) {
        int total = [d[@"total_count"] intValue];
        int rem = [d[@"remaining_count"] intValue];
        if (total > 0 && rem <= 0) {
            return 1;
        }
        return 3;
    }
    if (s >= 0 && s <= 2) {
        return s;
    }
    int total = [d[@"total_count"] intValue];
    int rem = [d[@"remaining_count"] intValue];
    if (total > 0 && rem <= 0) {
        return 1;
    }
    return 1;
}

+ (WKMessage *)messageMatchingPacketNo:(NSString *)packetNo inList:(NSArray<WKMessage *> *)messages {
    NSInteger ct = [self redPacketContentType];
    for (WKMessage *m in messages) {
        if (m.contentType != ct) {
            continue;
        }
        if (![m.content isKindOfClass:[WKRedPacketContent class]]) {
            continue;
        }
        NSString *pn = ((WKRedPacketContent *)m.content).packetNo ?: @"";
        if (pn.length && [pn isEqualToString:packetNo]) {
            return m;
        }
    }
    return nil;
}

+ (NSArray<WKMessage *> *)messagesMatchingPacketNo:(NSString *)packetNo inList:(NSArray<WKMessage *> *)messages {
    NSInteger ct = [self redPacketContentType];
    NSMutableArray<WKMessage *> *out = [NSMutableArray array];
    for (WKMessage *m in messages) {
        if (m.contentType != ct) {
            continue;
        }
        if (![m.content isKindOfClass:[WKRedPacketContent class]]) {
            continue;
        }
        NSString *pn = ((WKRedPacketContent *)m.content).packetNo ?: @"";
        if (pn.length && [pn isEqualToString:packetNo]) {
            [out addObject:m];
        }
    }
    return out;
}

+ (nullable WKMessage *)findRedPacketInChannel:(WKChannel *)channel packetNo:(NSString *)packetNo {
    if (!channel.channelId.length || !packetNo.length) {
        return nil;
    }
    uint32_t cursor = 0;
    for (int round = 0; round < 50; round++) {
        NSArray<WKMessage *> *batch = [[WKMessageDB shared] getMessages:channel
                                                         startOrderSeq:cursor
                                                           endOrderSeq:0
                                                                 limit:100
                                                            pullMode:WKPullModeDown];
        if (batch.count == 0) {
            break;
        }
        WKMessage *hit = [self messageMatchingPacketNo:packetNo inList:batch];
        if (hit) {
            return hit;
        }
        WKMessage *oldest = batch.lastObject;
        if (!oldest) {
            break;
        }
        if (oldest.orderSeq == cursor) {
            break;
        }
        cursor = oldest.orderSeq;
    }
    return nil;
}

+ (NSArray<WKMessage *> *)findAllRedPacketMessagesInChannel:(WKChannel *)channel packetNo:(NSString *)packetNo {
    if (!channel.channelId.length || !packetNo.length) {
        return @[];
    }
    NSMutableArray<WKMessage *> *out = [NSMutableArray array];
    uint32_t cursor = 0;
    for (int round = 0; round < 50; round++) {
        NSArray<WKMessage *> *batch = [[WKMessageDB shared] getMessages:channel
                                                         startOrderSeq:cursor
                                                           endOrderSeq:0
                                                                 limit:100
                                                            pullMode:WKPullModeDown];
        if (batch.count == 0) {
            break;
        }
        [out addObjectsFromArray:[self messagesMatchingPacketNo:packetNo inList:batch]];
        WKMessage *oldest = batch.lastObject;
        if (!oldest) {
            break;
        }
        if (oldest.orderSeq == cursor) {
            break;
        }
        cursor = oldest.orderSeq;
    }
    return out;
}

+ (NSArray<WKMessage *> *)findAllRedPacketMessagesGlobally:(NSString *)packetNo {
    if (!packetNo.length) {
        return @[];
    }
    NSArray<WKMessage *> *batch = [[WKMessageDB shared] getMessages:0 limit:400];
    return [self messagesMatchingPacketNo:packetNo inList:batch];
}

+ (nullable WKMessage *)findRedPacketGlobally:(NSString *)packetNo {
    if (!packetNo.length) {
        return nil;
    }
    NSArray<WKMessage *> *batch = [[WKMessageDB shared] getMessages:0 limit:400];
    return [self messageMatchingPacketNo:packetNo inList:batch];
}

+ (nullable WKMessage *)resolveMessageForPacketNo:(NSString *)packetNo
                                            channel:(nullable WKChannel *)channel
                                          clientSeq:(uint32_t)clientSeq
                                        clientMsgNo:(nullable NSString *)clientMsgNo {
    WKMessage *m = nil;
    if (clientSeq != 0) {
        m = [[WKMessageDB shared] getMessage:clientSeq];
        if (m && [m.content isKindOfClass:[WKRedPacketContent class]]) {
            NSString *pn = ((WKRedPacketContent *)m.content).packetNo ?: @"";
            if (packetNo.length && ![pn isEqualToString:packetNo]) {
                m = nil;
            }
        } else if (m) {
            m = nil;
        }
    }
    if (!m && clientMsgNo.length > 0) {
        m = [[WKMessageDB shared] getMessageWithClientMsgNo:clientMsgNo];
        if (m && [m.content isKindOfClass:[WKRedPacketContent class]]) {
            NSString *pn = ((WKRedPacketContent *)m.content).packetNo ?: @"";
            if (packetNo.length && ![pn isEqualToString:packetNo]) {
                m = nil;
            }
        } else if (m) {
            m = nil;
        }
    }
    if (!m && channel != nil) {
        m = [self findRedPacketInChannel:channel packetNo:packetNo];
    }
    if (!m) {
        m = [self findRedPacketGlobally:packetNo];
    }
    return m;
}

+ (void)applyStatus:(NSInteger)status toRedPacketMessage:(WKMessage *)message {
    if (![message.content isKindOfClass:[WKRedPacketContent class]]) {
        return;
    }
    WKRedPacketContent *c = (WKRedPacketContent *)message.content;
    c.status = status;
    NSData *data = [c encode];
    message.contentData = data;
    [[WKMessageDB shared] updateMessageContent:data status:message.status extra:message.extra clientSeq:message.clientSeq];
    [[WKSDK shared].chatManager callMessageUpdateDelegate:message];
}

+ (void)applyOpenedWithStatus:(NSInteger)status
                     packetNo:(NSString *)packetNo
                      channel:(WKChannel *)channel
                    clientSeq:(uint32_t)clientSeq
                  clientMsgNo:(NSString *)clientMsgNo {
    if (packetNo.length == 0) {
        return;
    }
    NSMutableDictionary<NSNumber *, WKMessage *> *bySeq = [NSMutableDictionary dictionary];
    void (^add)(WKMessage *) = ^(WKMessage *m) {
        if (!m || ![m.content isKindOfClass:[WKRedPacketContent class]]) {
            return;
        }
        NSString *pn = ((WKRedPacketContent *)m.content).packetNo ?: @"";
        if (packetNo.length && ![pn isEqualToString:packetNo]) {
            return;
        }
        bySeq[@(m.clientSeq)] = m;
    };
    if (clientSeq != 0) {
        add([[WKMessageDB shared] getMessage:clientSeq]);
    }
    if (clientMsgNo.length > 0) {
        add([[WKMessageDB shared] getMessageWithClientMsgNo:clientMsgNo]);
    }
    add([self resolveMessageForPacketNo:packetNo channel:channel clientSeq:clientSeq clientMsgNo:clientMsgNo]);
    if (channel != nil) {
        for (WKMessage *m in [self findAllRedPacketMessagesInChannel:channel packetNo:packetNo]) {
            add(m);
        }
    }
    for (WKMessage *m in [self findAllRedPacketMessagesGlobally:packetNo]) {
        add(m);
    }
    for (WKMessage *m in bySeq.allValues) {
        [self applyStatus:status toRedPacketMessage:m];
    }
}

+ (void)refineWithPacketNo:(NSString *)packetNo
                   channel:(WKChannel *)channel
                 clientSeq:(uint32_t)clientSeq
               clientMsgNo:(NSString *)clientMsgNo {
    if (packetNo.length == 0) {
        return;
    }
    [[WKRedPacketAPI shared] getRedPacketDetail:packetNo callback:^(NSDictionary *result, NSError *error) {
        if (!result || error) {
            return;
        }
        NSInteger st = [self statusFromDetailDict:result currentUid:[WKApp shared].loginInfo.uid];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyOpenedWithStatus:st
                               packetNo:packetNo
                                channel:channel
                              clientSeq:clientSeq
                            clientMsgNo:clientMsgNo];
        });
    }];
}

+ (BOOL)shouldStoreIncomingRedPacketMessage:(WKMessage *)incoming {
    if (!incoming) {
        return YES;
    }
    if (incoming.contentType != [self redPacketContentType]) {
        return YES;
    }
    if (![incoming.content isKindOfClass:[WKRedPacketContent class]]) {
        return YES;
    }
    NSString *pn = ((WKRedPacketContent *)incoming.content).packetNo ?: @"";
    if (pn.length == 0) {
        return YES;
    }
    WKChannel *ch = incoming.channel;
    if (!ch.channelId.length) {
        return YES;
    }
    WKMessage *existing = [self findRedPacketInChannel:ch packetNo:pn];
    if (!existing) {
        return YES;
    }
    if (existing.clientSeq != 0 && incoming.clientSeq != 0 && existing.clientSeq == incoming.clientSeq) {
        return YES;
    }
    if (existing.messageId != 0 && incoming.messageId != 0 && existing.messageId == incoming.messageId) {
        return YES;
    }
    NSString *incCM = incoming.clientMsgNo ?: @"";
    NSString *exCM = existing.clientMsgNo ?: @"";
    if (incCM.length > 0 && [incCM isEqualToString:exCM]) {
        return YES;
    }
    BOOL incNoServerId = (incoming.messageId == 0 && incoming.messageSeq == 0);
    BOOL exHasServerId = (existing.messageId > 0 || existing.messageSeq > 0);
    /// 同步/下行已有一条带 message_id 或 message_seq 的记录时，丢弃后到的一条无 server id 的副本（本机待发与下行顺序颠倒时）。
    if (incNoServerId && exHasServerId) {
        return NO;
    }
    BOOL incHasServerId = (incoming.messageId > 0 || incoming.messageSeq > 0);
    /// 常见：本机先发（尚无 server id），随后下行再存一条 → 丢弃带 server id 的重复。
    if (incHasServerId && exHasServerId) {
        return NO;
    }
    if (incHasServerId && !exHasServerId) {
        return NO;
    }
    return YES;
}

@end
