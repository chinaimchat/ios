//
//  WKStickerAPIPayloadUtil.m
//  WuKongStickerStore
//

#import "WKStickerAPIPayloadUtil.h"

@implementation WKStickerAPIPayloadUtil

+ (NSArray<NSDictionary *> *)dictionaryArrayFromAPIResponse:(id)responseObject {
    if ([responseObject isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
        for (id obj in (NSArray *)responseObject) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                [out addObject:obj];
            }
        }
        return out;
    }
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *root = (NSDictionary *)responseObject;
        for (NSString *key in @[ @"data", @"list", @"rows", @"items" ]) {
            id inner = root[key];
            if ([inner isKindOfClass:[NSArray class]]) {
                return [self dictionaryArrayFromAPIResponse:inner];
            }
        }
    }
    return @[];
}

+ (NSDictionary *)dictionaryFromAPIResponse:(id)responseObject {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *root = (NSDictionary *)responseObject;
    id data = root[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        return data;
    }
    return root;
}

@end
