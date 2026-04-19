//
//  WKStickerDataProvider.m
//  WuKongStickerStore
//
//  Created by tt on 2022/6/28.
//

#import "WKStickerDataProvider.h"
#import "WKStickerAPIPayloadUtil.h"
#import <WuKongBase/WKModel.h>

@implementation WKStickerDataProvider

- (void)requestUserCategory:(void (^)(NSArray<WKStickerUserCategoryResp *> *, NSError *))callback {
    [[WKAPIClient sharedClient] GET:@"sticker/user/category" parameters:nil].then(^(id responseObj) {
        NSArray<NSDictionary *> *dicts = [WKStickerAPIPayloadUtil dictionaryArrayFromAPIResponse:responseObj];
        NSMutableArray<WKStickerUserCategoryResp *> *resps = [NSMutableArray array];
        for (NSDictionary *dic in dicts) {
            WKStickerUserCategoryResp *r = (WKStickerUserCategoryResp *)[WKStickerUserCategoryResp fromMap:dic type:ModelMapTypeAPI];
            if (r) {
                [resps addObject:r];
            }
        }
        if (callback) {
            callback(resps, nil);
        }
    }).catch(^(NSError *error) {
        if (callback) {
            callback(nil, error);
        }
    });
}

- (void)requestAddStickerCategory:(NSString *)category callback:(void (^)(NSError *))callback {
    [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"sticker/user/%@",category] parameters:nil].then(^{
        if(callback) {
            callback(nil);
        }
    }).catch(^(NSError *error){
        if(callback) {
            callback(error);
        }
    });
}

- (void)requestRemoveStickerCategory:(NSString *)category callback:(void (^)(NSError *))callback {
    [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"sticker/remove?category=%@",category] parameters:nil].then(^{
        if(callback) {
            callback(nil);
        }
    }).catch(^(NSError *error){
        if(callback) {
            callback(error);
        }
    });
}

@end
