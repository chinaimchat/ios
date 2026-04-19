#import "WKRedPacketRecordDetailEnricher.h"
#import <WuKongRedPackets/WKRedPacketAPI.h>
#import <WuKongTransfer/WKTransferAPI.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

static NSString *WKEnrichStr(id o) {
    if (!o || o == (id)kCFNull) {
        return @"";
    }
    if ([o isKindOfClass:[NSString class]]) {
        return (NSString *)o;
    }
    return [NSString stringWithFormat:@"%@", o];
}

static NSMutableDictionary *WKMutableContextForRecord(NSMutableDictionary *r) {
    id ctx = r[@"context"];
    if ([ctx isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)ctx;
    }
    if ([ctx isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)ctx];
        r[@"context"] = m;
        return m;
    }
    NSMutableDictionary *m = [NSMutableDictionary dictionary];
    r[@"context"] = m;
    return m;
}

@implementation WKRedPacketRecordDetailEnricher

/// 与 Android {@code TransactionRecordDetailEnricher#needsEnrich}：含 {@code related_id} 的红包/转账流水。
+ (BOOL)needsWalletTransactionEnrich:(NSMutableDictionary *)r {
    NSString *rid = WKEnrichStr(r[@"related_id"] ?: r[@"relatedId"]);
    if (rid.length == 0) {
        return NO;
    }
    NSString *t = WKEnrichStr(r[@"type"]);
    if ([t isEqualToString:@"redpacket_receive"] || [t isEqualToString:@"redpacket_send"]) {
        return YES;
    }
    if ([t isEqualToString:@"transfer_in"] || [t isEqualToString:@"transfer_out"]) {
        return YES;
    }
    return NO;
}

/// 仅红包 Tab 记录（与改前行为一致）。
+ (BOOL)needsEnrich:(NSMutableDictionary *)r {
    NSString *rid = WKEnrichStr(r[@"related_id"] ?: r[@"relatedId"]);
    if (rid.length == 0) {
        return NO;
    }
    NSString *t = WKEnrichStr(r[@"type"]);
    if (![t isEqualToString:@"redpacket_receive"] && ![t isEqualToString:@"redpacket_send"]) {
        return NO;
    }
    return YES;
}

+ (void)applyDetailResponse:(NSDictionary *)d toRecord:(NSMutableDictionary *)r type:(NSString *)type {
    NSMutableDictionary *ctx = WKMutableContextForRecord(r);
    NSString *ch = WKEnrichStr(d[@"channel_id"]);
    if (ch.length > 0) {
        ctx[@"channel_id"] = ch;
    }
    id cty = d[@"channel_type"];
    if (cty != nil) {
        ctx[@"channel_type"] = cty;
    }
    long ptype = (long)[d[@"packet_type"] longValue];
    if (ptype <= 0) {
        ptype = (long)[d[@"type"] longValue];
    }
    if (ptype > 0) {
        ctx[@"packet_type"] = @(ptype);
    }
    id tc = d[@"total_count"];
    if (tc != nil) {
        ctx[@"redpacket_total_count"] = tc;
    }
    id rc = d[@"remaining_count"];
    if (rc != nil) {
        ctx[@"redpacket_remaining_count"] = rc;
    }
    id st = d[@"redpacket_status"];
    if (st != nil) {
        ctx[@"redpacket_status"] = st;
    }
    if ([type isEqualToString:@"redpacket_receive"]) {
        double my = [d[@"my_amount"] doubleValue];
        if (my > 0) {
            r[@"amount"] = @(my);
        }
    }
}

+ (void)loadGroupThenUserForRecord:(NSMutableDictionary *)r
                         channelId:(NSString *)channelId
                      channelType:(uint8_t)cty
                         senderUid:(NSString *)senderUid
                        isReceive:(BOOL)isReceive
                              done:(void (^)(void))done {
    void (^finish)(void) = ^{
        if (done) {
            done();
        }
    };
    void (^fetchSender)(void) = ^{
        if (!isReceive || senderUid.length == 0) {
            finish();
            return;
        }
        if (cty == WK_GROUP && channelId.length > 0) {
            WKChannel *grp = [WKChannel channelID:channelId channelType:WK_GROUP];
            WKChannelMember *mem = [[WKSDK shared].channelManager getMember:grp uid:senderUid];
            NSString *mn = mem.displayName.length ? mem.displayName : (mem.memberName.length ? mem.memberName : @"");
            if (mn.length > 0) {
                r[@"from_user_name"] = mn;
                finish();
                return;
            }
        }
        WKChannel *pch = [WKChannel personWithChannelID:senderUid];
        [[WKSDK shared].channelManager fetchChannelInfo:pch completion:^(WKChannelInfo *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (info.name.length > 0) {
                    r[@"from_user_name"] = info.name;
                }
                finish();
            });
        }];
    };
    if (cty == WK_GROUP && channelId.length > 0) {
        WKChannel *gch = [WKChannel channelID:channelId channelType:WK_GROUP];
        [[WKSDK shared].channelManager fetchChannelInfo:gch completion:^(WKChannelInfo *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (info.name.length > 0) {
                    r[@"group_name"] = info.name;
                }
                fetchSender();
            });
        }];
    } else {
        fetchSender();
    }
}

/// 与 Android {@link TransactionRecordDetailEnricher#enrichTransfer} + {@link #loadGroupThenPeer}。
+ (void)loadGroupThenPeerForTransferRecord:(NSMutableDictionary *)r
                                 channelId:(NSString *)channelId
                              channelType:(uint8_t)cty
                             transferType:(NSString *)txType
                               counterUid:(NSString *)counterUid
                                     done:(void (^)(void))done {
    void (^applyPeer)(void) = ^{
        if (counterUid.length == 0) {
            if (done) {
                done();
            }
            return;
        }
        if (cty == WK_GROUP && channelId.length > 0) {
            WKChannel *grp = [WKChannel channelID:channelId channelType:WK_GROUP];
            WKChannelMember *mem = [[WKSDK shared].channelManager getMember:grp uid:counterUid];
            NSString *mn = mem.displayName.length ? mem.displayName : (mem.memberName.length ? mem.memberName : @"");
            if (mn.length > 0) {
                if ([txType isEqualToString:@"transfer_in"]) {
                    r[@"from_user_name"] = mn;
                } else {
                    r[@"to_user_name"] = mn;
                }
                if (done) {
                    done();
                }
                return;
            }
        }
        WKChannel *pch = [WKChannel personWithChannelID:counterUid];
        [[WKSDK shared].channelManager fetchChannelInfo:pch completion:^(WKChannelInfo *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (info.name.length > 0) {
                    if ([txType isEqualToString:@"transfer_in"]) {
                        r[@"from_user_name"] = info.name;
                    } else {
                        r[@"to_user_name"] = info.name;
                    }
                }
                if (done) {
                    done();
                }
            });
        }];
    };

    if (cty == WK_GROUP && channelId.length > 0) {
        WKChannel *gch = [WKChannel channelID:channelId channelType:WK_GROUP];
        [[WKSDK shared].channelManager fetchChannelInfo:gch completion:^(WKChannelInfo *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (info.name.length > 0) {
                    r[@"group_name"] = info.name;
                }
                applyPeer();
            });
        }];
    } else {
        applyPeer();
    }
}

+ (void)enrichOneTransferRecord:(NSMutableDictionary *)r done:(void (^)(void))done {
    NSString *tno = WKEnrichStr(r[@"related_id"] ?: r[@"relatedId"]);
    if (tno.length == 0) {
        if (done) {
            done();
        }
        return;
    }
    NSString *type = WKEnrichStr(r[@"type"]);
    [[WKTransferAPI shared] getTransferDetail:tno callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!result || error) {
                if (done) {
                    done();
                }
                return;
            }
            NSString *channelId = WKEnrichStr(result[@"channel_id"]);
            id ctObj = result[@"channel_type"];
            uint8_t cty = WK_PERSON;
            if ([ctObj respondsToSelector:@selector(unsignedIntValue)]) {
                cty = (uint8_t)[ctObj unsignedIntValue];
            }
            NSString *fromUid = WKEnrichStr(result[@"from_uid"]);
            NSString *toUid = WKEnrichStr(result[@"to_uid"]);
            NSString *counter = [type isEqualToString:@"transfer_in"] ? fromUid : toUid;
            [self loadGroupThenPeerForTransferRecord:r channelId:channelId channelType:cty transferType:type counterUid:counter done:done];
        });
    }];
}

+ (void)enrichOneRecord:(NSMutableDictionary *)r done:(void (^)(void))done {
    NSString *t = WKEnrichStr(r[@"type"]);
    if ([t isEqualToString:@"redpacket_send"] || [t isEqualToString:@"redpacket_receive"]) {
        [self enrichOneRedPacketRecord:r done:done];
    } else if ([t isEqualToString:@"transfer_in"] || [t isEqualToString:@"transfer_out"]) {
        [self enrichOneTransferRecord:r done:done];
    } else {
        if (done) {
            done();
        }
    }
}

+ (void)enrichOneRedPacketRecord:(NSMutableDictionary *)r done:(void (^)(void))done {
    NSString *packetNo = WKEnrichStr(r[@"related_id"] ?: r[@"relatedId"]);
    if (packetNo.length == 0) {
        if (done) {
            done();
        }
        return;
    }
    NSString *type = WKEnrichStr(r[@"type"]);
    [[WKRedPacketAPI shared] getRedPacketDetail:packetNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!result || error) {
                if (done) {
                    done();
                }
                return;
            }
            [self applyDetailResponse:result toRecord:r type:type];
            NSString *channelId = WKEnrichStr(result[@"channel_id"]);
            id ctObj = result[@"channel_type"];
            uint8_t cty = WK_PERSON;
            if ([ctObj respondsToSelector:@selector(unsignedIntValue)]) {
                cty = (uint8_t)[ctObj unsignedIntValue];
            }
            NSString *senderUid = WKEnrichStr(result[@"sender_uid"]);
            [self loadGroupThenUserForRecord:r channelId:channelId channelType:cty senderUid:senderUid isReceive:[type isEqualToString:@"redpacket_receive"] done:done];
        });
    }];
}

+ (void)scheduleParallelEnrichWithPredicate:(BOOL (^)(NSMutableDictionary *r))pred
                                    records:(NSArray<NSMutableDictionary *> *)records
                                 completion:(void (^)(void))completion {
    if (records.count == 0) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
        return;
    }
    NSMutableArray<NSMutableDictionary *> *work = [NSMutableArray array];
    for (NSMutableDictionary *r in records) {
        if (pred && pred(r)) {
            [work addObject:r];
        }
    }
    if (work.count == 0) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
        return;
    }
    dispatch_group_t g = dispatch_group_create();
    for (NSMutableDictionary *r in work) {
        dispatch_group_enter(g);
        [self enrichOneRecord:r done:^{
            dispatch_group_leave(g);
        }];
    }
    dispatch_group_notify(g, dispatch_get_main_queue(), ^{
        if (completion) {
            completion();
        }
    });
}

+ (void)scheduleParallelEnrichRedPacketRecords:(NSArray<NSMutableDictionary *> *)records completion:(void (^)(void))completion {
    [self scheduleParallelEnrichWithPredicate:^BOOL(NSMutableDictionary *r) {
        return [self needsEnrich:r];
    } records:records completion:completion];
}

+ (void)scheduleParallelEnrichWalletTransactionRecords:(NSArray<NSMutableDictionary *> *)records completion:(void (^)(void))completion {
    [self scheduleParallelEnrichWithPredicate:^BOOL(NSMutableDictionary *r) {
        return [self needsWalletTransactionEnrich:r];
    } records:records completion:completion];
}

@end
