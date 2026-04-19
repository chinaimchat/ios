//
//  WKStickerStoreDetailVC.h
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import <WuKongBase/WuKongBase.h>
#import "WKStickerStoreDetailVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreDetailVC : WKBaseTableVC<WKStickerStoreDetailVM*>

-(instancetype) initWithCategory:(NSString*)category;

@property(nonatomic,copy) NSString *stickerName;

@end

NS_ASSUME_NONNULL_END
