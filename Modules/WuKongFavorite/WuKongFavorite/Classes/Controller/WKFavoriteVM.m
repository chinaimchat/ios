//
//  WKFavoriteVM.m
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import "WKFavoriteVM.h"
#import "WKFavoriteCell.h"
@interface WKFavoriteVM ()

@property(nonatomic,strong) NSArray<WKFavoriteResp*> *data;
@end

@implementation WKFavoriteVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    
    __weak typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray array];
    for (WKFavoriteResp *resp in self.data) {
        [items addObject:@{
            @"height":@(10.0f),
             @"items":@[
                 @{
                     @"class":WKFavoriteModel.class,
                     @"no": resp.no,
                     @"type":@(resp.type),
                     @"authorUID":resp.authorUID,
                     @"authorName":resp.authorName,
                     @"createdAt": resp.createdAt,
                     @"payload": resp.payload,
                     @"onMore": ^(WKFavoriteModel *model){
                        if(weakSelf.onMore) {
                            weakSelf.onMore(model);
                        }
                     }
                 }
             ]
        }];
    }
   return items;
}

- (void)requestData:(void (^)(NSError *))complete {
    __weak typeof(self) weakSelf = self;
    [self favoriteList].then(^(NSArray *items){
        weakSelf.data = items;
        complete(nil);
    }).catch(^(NSError *error){
        complete(error);
    });
}

-(AnyPromise*) favoriteList {
    return [[WKAPIClient sharedClient] GET:@"favorite/my" parameters:@{@"page_size":@(300)} model:WKFavoriteResp.class];
}

-(AnyPromise*) favoriteDelete:(NSString*)no {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"favorites/%@",no] parameters:nil];
}

-(AnyPromise*) favoriteAdd:(WKFavoriteReq*)req {
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"favorites"] parameters:[req toMap:ModelMapTypeAPI]];
}

@end

@implementation WKFavoriteReq

- (NSDictionary *)toMap:(ModelMapType)type {
    return @{
        @"unique_key":self.uniqueKey?:@"",
        @"author_uid": self.authorUID?:@"",
        @"author_name":self.authorName?:@"",
        @"type": @(self.type),
        @"payload": self.payload?:@{},
    };
}

@end

@implementation WKFavoriteResp

+ (WKFavoriteResp *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKFavoriteResp *resp = [WKFavoriteResp new];
    resp.no = dictory[@"unique_key"]?:@"";
    
    resp.type = dictory[@"type"]?[dictory[@"type"] integerValue]:1;
    resp.authorUID = dictory[@"author_uid"]?:@"";
    resp.authorName = dictory[@"author_name"]?:@"";
    resp.createdAt = dictory[@"created_at"]?:@"";
    resp.payload = dictory[@"payload"];
    return resp;
}

@end
