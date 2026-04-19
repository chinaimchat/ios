//
//  WKStickerStoreDetailHeaderCell.h
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreDetailHeaderModel : WKFormItemModel

@property(nonatomic,copy) NSString *title;

@property(nonatomic,copy) NSString *remark;

@property(nonatomic,assign) BOOL added;

@property(nonatomic,copy) void(^onAdd)(void);


@end

@interface WKStickerStoreDetailHeaderCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
