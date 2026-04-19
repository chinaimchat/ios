//
//  WKStickerStoreDetailVM.h
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import <WuKongBase/WuKongBase.h>
#import "WKStickerPackage.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreDetailVM : WKBaseTableVM

-(instancetype) initWithCategory:(NSString*)category;

@property(nonatomic,strong) WKStickerPackage *stickerPackage;

@property(nonatomic,copy) void(^onRequestFinished)(void);

@end

NS_ASSUME_NONNULL_END
