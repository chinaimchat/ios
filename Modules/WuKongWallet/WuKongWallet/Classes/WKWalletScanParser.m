#import "WKWalletScanParser.h"

@implementation WKWalletScanParser

+ (BOOL)isReceiveQrScene:(WKScanResult *)result {
    NSString *forward = [[result.forward ?: @"" lowercaseString] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *type = [[result.type ?: @"" lowercaseString] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    NSArray<NSString *> *keywords = @[@"receive_qr", @"wallet_receive_qr", @"wallet_transfer", @"transfer", @"wallet"];
    for (NSString *k in keywords) {
        if ((forward.length > 0 && [forward containsString:k]) || (type.length > 0 && [type containsString:k])) {
            return YES;
        }
    }

    // 无明确类型时，允许后续通过 data 自动识别。
    return (forward.length == 0 && type.length == 0);
}

+ (nullable NSString *)extractReceiveUidFromData:(id)data {
    return [self extractReceiveUidFromObject:data depth:0];
}

+ (nullable NSString *)extractReceiveUidFromObject:(id)obj depth:(NSInteger)depth {
    if (!obj || depth > 4) {
        return nil;
    }

    if ([obj isKindOfClass:NSString.class]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (s.length == 0) {
            return nil;
        }

        if (([s hasPrefix:@"{"] && [s hasSuffix:@"}"]) || ([s hasPrefix:@"["] && [s hasSuffix:@"]"])) {
            NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
            if (d) {
                id json = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
                NSString *uid = [self extractReceiveUidFromObject:json depth:depth + 1];
                if (uid.length > 0) {
                    return uid;
                }
            }
        }

        return s;
    }

    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)obj;
        NSArray<NSString *> *directKeys = @[
            @"uid", @"to_uid", @"receive_uid", @"receiver_uid", @"payee_uid",
            @"user_uid", @"target_uid", @"peer_uid"
        ];
        for (NSString *k in directKeys) {
            id v = dict[k];
            if ([v isKindOfClass:NSString.class]) {
                NSString *uid = [(NSString *)v stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                if (uid.length > 0) {
                    return uid;
                }
            }
        }

        NSArray<NSString *> *nestedKeys = @[@"data", @"payload", @"extra", @"user", @"target", @"receiver", @"qr", @"result"];
        for (NSString *k in nestedKeys) {
            NSString *uid = [self extractReceiveUidFromObject:dict[k] depth:depth + 1];
            if (uid.length > 0) {
                return uid;
            }
        }

        for (id key in dict) {
            NSString *uid = [self extractReceiveUidFromObject:dict[key] depth:depth + 1];
            if (uid.length > 0) {
                return uid;
            }
        }
    }

    if ([obj isKindOfClass:NSArray.class]) {
        for (id item in (NSArray *)obj) {
            NSString *uid = [self extractReceiveUidFromObject:item depth:depth + 1];
            if (uid.length > 0) {
                return uid;
            }
        }
    }

    return nil;
}

@end
