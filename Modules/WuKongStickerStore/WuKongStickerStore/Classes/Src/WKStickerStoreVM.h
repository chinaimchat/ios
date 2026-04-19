//
//  WKStickerStoreVM.h
//  WuKongBase
//
//  Created by tt on 2021/9/27.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreVM : WKBaseTableVM

@end

@interface WKStickerStoreResp : WKModel

@property(nonatomic,strong) NSNumber *status;
@property(nonatomic,copy) NSString *category;
@property(nonatomic,copy) NSString *cover;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *desc;

@end

NS_ASSUME_NONNULL_END
