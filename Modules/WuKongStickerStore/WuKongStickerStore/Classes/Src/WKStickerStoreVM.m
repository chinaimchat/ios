//
//  WKStickerStoreVM.m
//  WuKongBase
//
//  Created by tt on 2021/9/27.
//

#import "WKStickerStoreVM.h"
#import "WKStickerStoreItemCell.h"
#import "WKStickerStoreDetailVC.h"
#import "WKStickerManager.h"
#import "WKStickerAPIPayloadUtil.h"
#import <WuKongBase/WKModel.h>
@interface WKStickerStoreVM ()

@property(nonatomic,assign) NSInteger pageSize;
@property(nonatomic,assign) NSInteger currentPage;
@property(nonatomic,assign) BOOL hasMore;
@property(nonatomic,strong) NSMutableArray<WKStickerStoreResp*> *items;

@end

@implementation WKStickerStoreVM


- (NSInteger)currentPage {
    if(!_currentPage) {
        _currentPage = 1;
    }
    return _currentPage;
}

- (NSInteger)pageSize {
    if(!_pageSize) {
        _pageSize = 15.0f;
    }
    return _pageSize;
}

- (NSMutableArray<WKStickerStoreResp *> *)items {
    if(!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

- (NSArray<NSDictionary *> *)tableSectionMaps {
    
    if(self.items.count==0) {
        return nil;
    }
    __weak typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray array];
    for (WKStickerStoreResp *resp in self.items) {
        [items addObject: @{
            @"class": WKStickerStoreItemModel.class,
            @"title":resp.title?:@"",
            @"remark": resp.desc?:@"",
            @"stickerCover":[[WKApp shared] getFileFullUrl:resp.cover],
            @"added": resp.status,
            @"onAdd":^{
           
                if(resp.status.intValue == 1) {
                   
                    [[WKStickerManager shared] removeStickerWithCategory:resp.category callback:^(NSError * _Nonnull error) {
                        if(!error) {
                            resp.status = @(0);
                            [[WKStickerManager shared] loadUserCategory];
                            [weakSelf reloadData];
                        }
                        
                    }];
                }else{
                    [[WKStickerManager shared] addStickerWithCategory:resp.category callback:^(NSError * _Nullable error) {
                        if(!error) {
                            resp.status = @(1);
                            [[WKStickerManager shared] loadUserCategory];
                            [weakSelf reloadData];
                        }
                    }];
                }
            },
            @"showArrow": @(false),
            @"onClick":^{
                WKStickerStoreDetailVC *vc = [[WKStickerStoreDetailVC alloc] initWithCategory:resp.category];
                vc.stickerName = resp.title;
                [[WKNavigationManager shared] pushViewController:vc animated:YES];
            }
        }];
    }
    return @[@{
                 @"height":@(0.01f),
                 @"items":items,
             }
    ];
}


- (void)requestData:(void (^)(NSError * _Nullable))complete {
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] GET:@"sticker/store" parameters:@{@"page_index":@(self.currentPage),@"page_size":@(self.pageSize)}].then(^(id responseObj) {
        NSArray<NSDictionary *> *dicts = [WKStickerAPIPayloadUtil dictionaryArrayFromAPIResponse:responseObj];
        NSMutableArray<WKStickerStoreResp *> *results = [NSMutableArray array];
        for (NSDictionary *dic in dicts) {
            WKStickerStoreResp *r = (WKStickerStoreResp *)[WKStickerStoreResp fromMap:dic type:ModelMapTypeAPI];
            if (r) {
                [results addObject:r];
            }
        }
        [weakSelf.items addObjectsFromArray:results];
        weakSelf.currentPage++;

        if (results.count >= weakSelf.pageSize) {
            weakSelf.hasMore = YES;
        } else {
            weakSelf.hasMore = NO;
        }
        complete(nil);
    }).catch(^(NSError *error) {
        complete(error);
    });
}

- (void)pullup:(void (^)(BOOL))complete {
    
    if(!self.hasMore) {
        complete(self.hasMore);
        return;
    }
    self.currentPage ++;
    __weak typeof(self) weakSelf = self;
    [self requestData:^(NSError * _Nullable error) {
        complete(weakSelf.hasMore);
    }];
   
}

- (BOOL)enablePullup {
    return YES;
}

@end


@implementation WKStickerStoreResp

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKStickerStoreResp *resp = [WKStickerStoreResp new];
    resp.status = dictory[@"status"];
    resp.category = dictory[@"category"];
    resp.cover = dictory[@"cover"];
    resp.title = dictory[@"title"];
    resp.desc = dictory[@"desc"];
    return resp;
}

@end
