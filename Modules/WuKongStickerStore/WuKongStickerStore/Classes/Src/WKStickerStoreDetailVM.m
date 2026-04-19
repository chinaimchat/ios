//
//  WKStickerStoreDetailVM.m
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import "WKStickerStoreDetailVM.h"
#import "WKStickerStoreDetailHeaderCell.h"
#import "WKStickerManager.h"

#import "WKStickerStoreDetailHeaderCell.h"
#import "WKStickerStoreContentCell.h"
#import "WKStickerManager.h"
#import "WKStickerAPIPayloadUtil.h"
#import <WuKongBase/WKModel.h>
@interface WKStickerStoreDetailVM ()


@property(nonatomic,copy) NSString *category;
@end

@implementation WKStickerStoreDetailVM

- (instancetype)initWithCategory:(NSString*)category
{
    self = [super init];
    if (self) {
        self.category = category;
    }
    return self;
}

- (NSArray<NSDictionary *> *)tableSectionMaps {
    if(!self.stickerPackage) {
        return nil;
    }
    __weak typeof(self) weakSelf =self;
    return @[
            @{
                 @"height":@(0.0f),
                 @"items":@[
                         @{
                             @"class": WKStickerStoreDetailHeaderModel.class,
                             @"title": self.stickerPackage.title,
                             @"remark": self.stickerPackage.desc,
                             @"added": @(self.stickerPackage.added),
                             @"onAdd":^{
                                 if(!weakSelf.stickerPackage.added) {
                                     [[WKStickerManager shared] addStickerWithCategory:self.stickerPackage.category callback:^(NSError * _Nullable error) {
                                         if(!error) {
                                             weakSelf.stickerPackage.added = true;
                                             [[WKStickerManager shared] loadUserCategory];
                                             [weakSelf reloadData];
                                         }
                                     }];
                                 }
                             }
                         },
                 ],
             },
            @{
                 @"height":@(20.0f),
                 @"items":@[
                         @{
                             @"class": WKStickerStoreContentModel.class,
                             @"list": self.stickerPackage.list,
                         },
                 ],
             }
    ];
}

- (void)requestData:(void (^)(NSError * _Nullable))complete {
    
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] GET:@"sticker/user/sticker" parameters:@{@"category":self.category?:@""}].then(^(id responseObj) {
        NSDictionary *dic = [WKStickerAPIPayloadUtil dictionaryFromAPIResponse:responseObj];
        if (!dic) {
            complete([NSError errorWithDomain:@"sticker" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"invalid response"}]);
            return;
        }
        weakSelf.stickerPackage = (WKStickerPackage *)[WKStickerPackage fromMap:dic type:ModelMapTypeAPI];
        complete(nil);
        if (weakSelf.onRequestFinished) {
            weakSelf.onRequestFinished();
        }
    }).catch(^(NSError *error) {
        complete(error);
    });
}

@end
