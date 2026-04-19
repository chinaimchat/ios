#import "WKSystemNotifyDisplay.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "NSString+WKLocalized.h"

#define WKSysLoc(s) [(s) LocalizedWithClass:[WKSystemNotifyDisplay class]]

@implementation WKSystemNotifyTappableSuffix

- (BOOL)opensRedPacketDetail {
    if (self.packetNo.length == 0) {
        return NO;
    }
    if (self.action.length == 0) {
        return YES;
    }
    return [self.action caseInsensitiveCompare:@"redpacket_detail"] == NSOrderedSame;
}

- (BOOL)opensTransferDetail {
    if (self.transferNo.length == 0) {
        return NO;
    }
    if (self.action.length == 0) {
        return YES;
    }
    return [self.action caseInsensitiveCompare:@"transfer_detail"] == NSOrderedSame;
}

@end

@implementation WKSystemNotifyNickSpan
@end

@implementation WKSystemNotifyBuilt
@end

static NSRegularExpression *WKTemplatePlaceholderRegex(void) {
    static NSRegularExpression *rx;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        rx = [NSRegularExpression regularExpressionWithPattern:@"\\{(\\d+)\\}" options:0 error:nil];
    });
    return rx;
}

static BOOL WKIsRedPacketClaimYourEnvelopeTemplate(NSString *templateStr) {
    if (templateStr.length == 0) {
        return NO;
    }
    return [templateStr containsString:@"领取了你的红包"]
        || [templateStr containsString:@"领取了您的红包"]
        || [templateStr containsString:@"领取了你发送的红包"];
}

static BOOL WKIsTransferAcceptYourTransferTemplate(NSString *templateStr) {
    if (templateStr.length == 0) {
        return NO;
    }
    return [templateStr containsString:@"确认了你的转账"]
        || [templateStr containsString:@"确认了您的转账"]
        || [templateStr containsString:@"领取了你的转账"]
        || [templateStr containsString:@"领取了您的转账"];
}

static NSString *WKYouString(void) {
    return WKSysLoc(@"你");
}

static void WKFillTemplateExtraNamesAndUids(NSArray *list, NSString *loginUID, NSMutableArray<NSString *> *names, NSMutableArray<NSString *> *_Nullable uids) {
    [names removeAllObjects];
    if (uids) {
        [uids removeAllObjects];
    }
    if (![list isKindOfClass:[NSArray class]]) {
        return;
    }
    for (id item in list) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            [names addObject:@""];
            if (uids) {
                [uids addObject:@""];
            }
            continue;
        }
        NSDictionary *jo = (NSDictionary *)item;
        NSString *name = [jo[@"name"] isKindOfClass:[NSString class]] ? jo[@"name"] : @"";
        NSString *uid = @"";
        if (jo[@"uid"] != nil) {
            NSString *u = [NSString stringWithFormat:@"%@", jo[@"uid"]];
            if (u.length > 0 && loginUID.length > 0 && [u isEqualToString:loginUID]) {
                name = WKYouString();
            }
            uid = u;
        }
        [names addObject:name ?: @""];
        if (uids) {
            [uids addObject:uid ?: @""];
        }
    }
}

static NSString *_Nullable WKRedPacketSelfClaimTipIfMatch(NSString *templateStr, NSArray *extra, NSString *loginUID) {
    if (templateStr.length == 0 || loginUID.length == 0 || ![extra isKindOfClass:[NSArray class]] || extra.count != 1) {
        return nil;
    }
    if (![templateStr containsString:@"{0}"] || !WKIsRedPacketClaimYourEnvelopeTemplate(templateStr)) {
        return nil;
    }
    id first = extra.firstObject;
    if (![first isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *claimerUid = [NSString stringWithFormat:@"%@", ((NSDictionary *)first)[@"uid"] ?: @""];
    if (claimerUid.length == 0 || ![claimerUid isEqualToString:loginUID]) {
        return nil;
    }
    return WKSysLoc(@"你领取了自己的红包");
}

static NSString *_Nullable WKTransferSelfAcceptTipIfMatch(NSString *templateStr, NSArray *extra, NSString *loginUID) {
    if (templateStr.length == 0 || loginUID.length == 0 || ![extra isKindOfClass:[NSArray class]] || extra.count != 1) {
        return nil;
    }
    if (![templateStr containsString:@"{0}"] || !WKIsTransferAcceptYourTransferTemplate(templateStr)) {
        return nil;
    }
    id first = extra.firstObject;
    if (![first isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *uid = [NSString stringWithFormat:@"%@", ((NSDictionary *)first)[@"uid"] ?: @""];
    if (uid.length == 0 || ![uid isEqualToString:loginUID]) {
        return nil;
    }
    return WKSysLoc(@"你已确认收款");
}

static NSString *WKNormalizeSelfRedPacketClaimDisplay(NSString *formatted) {
    if (formatted.length == 0) {
        return formatted;
    }
    NSString *you = WKYouString();
    NSString *c = [formatted stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([c isEqualToString:[you stringByAppendingString:@"领取了你的红包"]]
        || [c isEqualToString:[you stringByAppendingString:@"领取了您的红包"]]) {
        return WKSysLoc(@"你领取了自己的红包");
    }
    return formatted;
}

static NSString *WKNormalizeSelfTransferAcceptDisplay(NSString *formatted) {
    if (formatted.length == 0) {
        return formatted;
    }
    NSString *you = WKYouString();
    NSString *c = [formatted stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([c isEqualToString:[you stringByAppendingString:@"确认了你的转账"]]
        || [c isEqualToString:[you stringByAppendingString:@"确认了您的转账"]]
        || [c isEqualToString:[you stringByAppendingString:@"领取了你的转账"]]
        || [c isEqualToString:[you stringByAppendingString:@"领取了您的转账"]]) {
        return WKSysLoc(@"你已确认收款");
    }
    return formatted;
}

static NSString *WKExpandTemplate(NSString *templateStr, NSArray<NSString *> *names, NSArray<NSString *> *uids) {
    NSRegularExpression *rx = WKTemplatePlaceholderRegex();
    NSUInteger n = [rx numberOfMatchesInString:templateStr options:0 range:NSMakeRange(0, templateStr.length)];
    if (n == 0) {
        if (names.count > 0) {
            NSMutableString *ms = [templateStr mutableCopy];
            for (NSUInteger i = 0; i < names.count; i++) {
                NSString *ph = [NSString stringWithFormat:@"{%lu}", (unsigned long)i];
                [ms replaceOccurrencesOfString:ph withString:names[i] ?: @"" options:0 range:NSMakeRange(0, ms.length)];
            }
            return ms;
        }
        return templateStr;
    }
    NSMutableString *sb = [NSMutableString string];
    __block NSUInteger last = 0;
    [rx enumerateMatchesInString:templateStr options:0 range:NSMakeRange(0, templateStr.length)
                      usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
                          NSRange full = result.range;
                          if (full.location > last) {
                              [sb appendString:[templateStr substringWithRange:NSMakeRange(last, full.location - last)]];
                          }
                          NSInteger idx = [[templateStr substringWithRange:[result rangeAtIndex:1]] integerValue];
                          last = NSMaxRange(full);
                          if (idx >= 0 && (NSUInteger)idx < names.count) {
                              [sb appendString:names[(NSUInteger)idx] ?: @""];
                          }
                      }];
    if (last < templateStr.length) {
        [sb appendString:[templateStr substringFromIndex:last]];
    }
    return sb;
}

static NSString *WKExpandTemplateCollectingSpans(NSString *templateStr, NSArray<NSString *> *names, NSArray<NSString *> *uids, NSMutableArray<WKSystemNotifyNickSpan *> *outSpans) {
    NSRegularExpression *rx = WKTemplatePlaceholderRegex();
    NSMutableString *sb = [NSMutableString string];
    __block NSUInteger last = 0;
    [rx enumerateMatchesInString:templateStr options:0 range:NSMakeRange(0, templateStr.length)
                      usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
                          NSRange full = result.range;
                          if (full.location > last) {
                              [sb appendString:[templateStr substringWithRange:NSMakeRange(last, full.location - last)]];
                          }
                          NSInteger idx = [[templateStr substringWithRange:[result rangeAtIndex:1]] integerValue];
                          last = NSMaxRange(full);
                          if (idx >= 0 && (NSUInteger)idx < names.count) {
                              NSString *nm = names[(NSUInteger)idx] ?: @"";
                              NSUInteger st = sb.length;
                              [sb appendString:nm];
                              NSUInteger en = sb.length;
                              if (uids && (NSUInteger)idx < uids.count) {
                                  NSString *u = uids[(NSUInteger)idx] ?: @"";
                                  if (u.length > 0) {
                                      WKSystemNotifyNickSpan *sp = [WKSystemNotifyNickSpan new];
                                      sp.start = (NSInteger)st;
                                      sp.end = (NSInteger)en;
                                      sp.uid = u;
                                      [outSpans addObject:sp];
                                  }
                              }
                          }
                      }];
    if (last < templateStr.length) {
        [sb appendString:[templateStr substringFromIndex:last]];
    }
    return sb;
}

static WKSystemNotifyTappableSuffix *_Nullable WKParseNotifyTappableSuffix(NSDictionary *jo, NSString *displayText, NSString *_Nullable fallbackLastSubstring) {
    if (jo.count == 0 || displayText.length == 0) {
        return nil;
    }
    NSDictionary *ts = nil;
    id tsRaw = jo[@"tappable_suffix"];
    if ([tsRaw isKindOfClass:[NSDictionary class]]) {
        ts = tsRaw;
    }
    NSString *needle = nil;
    if (ts) {
        NSString *t = ts[@"text"];
        if ([t isKindOfClass:[NSString class]] && t.length > 0) {
            needle = t;
        }
    }
    if (needle.length == 0 && fallbackLastSubstring.length > 0) {
        needle = fallbackLastSubstring;
    }
    if (needle.length == 0) {
        return nil;
    }
    NSRange r = [displayText rangeOfString:needle options:NSBackwardsSearch];
    if (r.location == NSNotFound) {
        return nil;
    }
    WKSystemNotifyTappableSuffix *info = [WKSystemNotifyTappableSuffix new];
    info.start = (NSInteger)r.location;
    info.end = (NSInteger)(NSMaxRange(r));
    info.action = [ts[@"action"] isKindOfClass:[NSString class]] ? ts[@"action"] : @"";
    NSString *packetNo = [ts[@"packet_no"] isKindOfClass:[NSString class]] ? ts[@"packet_no"] : @"";
    if (packetNo.length == 0) {
        id pn = jo[@"packet_no"];
        if (pn) {
            packetNo = [NSString stringWithFormat:@"%@", pn];
        }
    }
    NSString *transferNo = [ts[@"transfer_no"] isKindOfClass:[NSString class]] ? ts[@"transfer_no"] : @"";
    if (transferNo.length == 0) {
        id tn = jo[@"transfer_no"];
        if (tn) {
            transferNo = [NSString stringWithFormat:@"%@", tn];
        }
    }
    info.packetNo = packetNo ?: @"";
    info.transferNo = transferNo ?: @"";
    info.colorHint = [ts[@"color_hint"] isKindOfClass:[NSString class]] ? ts[@"color_hint"] : @"";
    return info;
}

/// 与 Android StringUtils.getShowContent 一致（展开模板 + 归一化），不含 emoji。
static NSString *WKPlainShowContentFromRoot(NSDictionary *contentRoot) {
    if (![contentRoot isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    id contentVal = contentRoot[@"content"];
    if (![contentVal isKindOfClass:[NSString class]] || ((NSString *)contentVal).length == 0) {
        return @"";
    }
    NSString *templateStr = (NSString *)contentVal;
    NSArray *extra = contentRoot[@"extra"];
    NSString *loginUID = [WKSDK shared].options.connectInfo.uid ?: @"";

    NSString *selfClaim = WKRedPacketSelfClaimTipIfMatch(templateStr, extra, loginUID);
    if (selfClaim) {
        return selfClaim;
    }
    NSString *selfTransfer = WKTransferSelfAcceptTipIfMatch(templateStr, extra, loginUID);
    if (selfTransfer) {
        return selfTransfer;
    }

    NSMutableArray<NSString *> *names = [NSMutableArray array];
    WKFillTemplateExtraNamesAndUids(extra, loginUID, names, nil);
    NSString *out = WKExpandTemplate(templateStr, names, nil);
    out = WKNormalizeSelfRedPacketClaimDisplay(out);
    out = WKNormalizeSelfTransferAcceptDisplay(out);
    if (out.length == 0) {
        out = WKSysLoc(@"未知");
    }
    return out;
}

static NSString *WKRedPacketClaimTipClaimerUid(NSDictionary *root) {
    NSArray *list = root[@"extra"];
    if (![list isKindOfClass:[NSArray class]] || list.count < 1) {
        return @"";
    }
    id first = list.firstObject;
    if (![first isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@", ((NSDictionary *)first)[@"uid"] ?: @""];
}

/// 与 Android 领取提示一致：extra 偶发不带 uid 时，若展示已是「你领取了…」则按当前用户进资料卡。
static NSString *WKRedPacketClaimTipEffectiveClaimerUid(NSDictionary *root, NSString *plain) {
    NSString *u = WKRedPacketClaimTipClaimerUid(root);
    if (u.length > 0) {
        return u;
    }
    NSString *login = [WKSDK shared].options.connectInfo.uid ?: @"";
    if (login.length == 0 || plain.length == 0) {
        return @"";
    }
    NSString *you = WKYouString();
    if (you.length == 0 || plain.length < you.length) {
        return @"";
    }
    if (![plain hasPrefix:you]) {
        return @"";
    }
    NSString *afterYou = [plain substringFromIndex:you.length];
    if (afterYou.length >= 3 && [afterYou hasPrefix:@"领取了"]) {
        return login;
    }
    return @"";
}

@implementation WKSystemNotifyDisplay

+ (BOOL)isTemplateNotifyJson:(NSDictionary *)contentRoot {
    if (![contentRoot isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    id t = contentRoot[@"content"];
    if (![t isKindOfClass:[NSString class]] || ((NSString *)t).length == 0) {
        return NO;
    }
    NSRegularExpression *rx = WKTemplatePlaceholderRegex();
    if ([rx numberOfMatchesInString:t options:0 range:NSMakeRange(0, ((NSString *)t).length)] == 0) {
        return NO;
    }
    return [contentRoot[@"extra"] isKindOfClass:[NSArray class]];
}

+ (nullable NSString *)plainShowTextFromNotifyContentRoot:(NSDictionary *)contentRoot {
    NSString *s = WKPlainShowContentFromRoot(contentRoot);
    return s.length > 0 ? s : nil;
}

+ (nullable WKSystemNotifyBuilt *)buildRedPacketOpenNotify:(NSDictionary *)contentRoot {
    if (![contentRoot isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *plain = WKPlainShowContentFromRoot(contentRoot);
    if (plain.length == 0) {
        return nil;
    }
    NSString *emoji = @"🧧";
    NSString *full = [emoji stringByAppendingString:plain];

    WKSystemNotifyBuilt *built = [WKSystemNotifyBuilt new];
    built.text = full;
    built.emojiPrefixLength = emoji.length;
    NSMutableArray<WKSystemNotifyNickSpan *> *nickSpans = [NSMutableArray array];
    NSString *claimer = WKRedPacketClaimTipEffectiveClaimerUid(contentRoot, plain);
    NSRange rTake = [full rangeOfString:@"领取了"];
    if (claimer.length > 0 && rTake.location != NSNotFound && rTake.location > emoji.length) {
        WKSystemNotifyNickSpan *sp = [WKSystemNotifyNickSpan new];
        sp.start = (NSInteger)emoji.length;
        sp.end = (NSInteger)rTake.location;
        sp.uid = claimer;
        [nickSpans addObject:sp];
    }
    built.nickSpans = nickSpans;

    WKSystemNotifyTappableSuffix *suf = WKParseNotifyTappableSuffix(contentRoot, plain, @"红包");
    if (suf) {
        suf.start += (NSInteger)emoji.length;
        suf.end += (NSInteger)emoji.length;
    }
    built.tappableSuffix = suf;
    return built;
}

+ (nullable WKSystemNotifyBuilt *)buildTradeSystemTemplateNotify:(NSDictionary *)contentRoot {
    if (![contentRoot isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id contentVal = contentRoot[@"content"];
    if (![contentVal isKindOfClass:[NSString class]] || ((NSString *)contentVal).length == 0) {
        return nil;
    }
    NSString *templateStr = (NSString *)contentVal;
    NSArray *extra = contentRoot[@"extra"];
    NSString *loginUID = [WKSDK shared].options.connectInfo.uid ?: @"";

    WKSystemNotifyBuilt *built = [WKSystemNotifyBuilt new];
    built.emojiPrefixLength = 0;
    built.nickSpans = @[];

    NSString *selfClaim = WKRedPacketSelfClaimTipIfMatch(templateStr, extra, loginUID);
    if (selfClaim) {
        built.text = selfClaim;
        built.tappableSuffix = WKParseNotifyTappableSuffix(contentRoot, selfClaim, @"红包");
        NSString *you = WKYouString();
        NSMutableArray<WKSystemNotifyNickSpan *> *selfNick = [NSMutableArray array];
        if (loginUID.length > 0 && you.length > 0 && selfClaim.length > you.length && [selfClaim hasPrefix:you]) {
            NSString *afterYou = [selfClaim substringFromIndex:you.length];
            if (afterYou.length >= 3 && [afterYou hasPrefix:@"领取了"]) {
                WKSystemNotifyNickSpan *sp = [WKSystemNotifyNickSpan new];
                sp.start = 0;
                sp.end = (NSInteger)you.length;
                sp.uid = loginUID;
                [selfNick addObject:sp];
            }
        }
        built.nickSpans = selfNick;
        return built;
    }
    NSString *selfTransfer = WKTransferSelfAcceptTipIfMatch(templateStr, extra, loginUID);
    if (selfTransfer) {
        built.text = selfTransfer;
        built.tappableSuffix = WKParseNotifyTappableSuffix(contentRoot, selfTransfer, @"转账");
        return built;
    }

    NSMutableArray<NSString *> *names = [NSMutableArray array];
    NSMutableArray<NSString *> *uids = [NSMutableArray array];
    WKFillTemplateExtraNamesAndUids(extra, loginUID, names, uids);

    NSRegularExpression *rx = WKTemplatePlaceholderRegex();
    NSUInteger phCount = [rx numberOfMatchesInString:templateStr options:0 range:NSMakeRange(0, templateStr.length)];
    NSString *out;
    NSMutableArray<WKSystemNotifyNickSpan *> *spans = [NSMutableArray array];
    if (phCount == 0) {
        out = WKExpandTemplate(templateStr, names, uids);
    } else {
        out = WKExpandTemplateCollectingSpans(templateStr, names, uids, spans);
    }
    out = WKNormalizeSelfRedPacketClaimDisplay(out);
    out = WKNormalizeSelfTransferAcceptDisplay(out);
    if (out.length == 0) {
        out = WKSysLoc(@"未知");
    }
    built.text = out;
    built.nickSpans = spans;
    built.tappableSuffix = WKParseNotifyTappableSuffix(contentRoot, out, @"转账");
    return built;
}

@end
