//
//  WKStickerStoreContentCell.h
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import <WuKongBase/WuKongBase.h>
#import "WKStickerPackage.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreContentModel : WKFormItemModel

@property(nonatomic,strong) NSArray<WKSticker*> *list;

@end

@interface WKStickerStoreContentCell : WKFormItemCell


@end

NS_ASSUME_NONNULL_END
