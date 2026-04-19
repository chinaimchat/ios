//
//  WKStickerInfoVC.h
//  WuKongBase
//
//  Created by tt on 2021/9/29.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerInfoVC : WKBaseVC

@property(nonatomic,copy) NSString *category;

@property(nonatomic,copy) NSString *stickerURL;

@property(nonatomic,copy) NSString *placeholderSvg;

@end


@interface WKStickerInfoResp : WKModel

@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *desc;
@property(nonatomic,copy) NSString *cover;
@property(nonatomic,assign) BOOL added;

@end

NS_ASSUME_NONNULL_END
