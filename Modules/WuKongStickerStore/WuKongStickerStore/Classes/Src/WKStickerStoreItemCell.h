//
//  WKStickerStoreItemCell.h
//  WuKongBase
//
//  Created by tt on 2021/9/27.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreItemModel : WKFormItemModel

@property(nonatomic,strong) NSURL *stickerCover;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *remark;
@property(nonatomic,assign) BOOL added;

@property(nonatomic,copy) void(^onAdd)(void);

@end

@interface WKStickerStoreItemCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
