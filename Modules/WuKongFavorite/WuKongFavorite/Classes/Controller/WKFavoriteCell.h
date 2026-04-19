//
//  WKFavoriteCell.h
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import <WuKongBase/WuKongBase.h>



NS_ASSUME_NONNULL_BEGIN

 
typedef enum : NSUInteger {
    WKFavoriteTypeUnknown, // 未知
    WKFavoriteTypeText, // 文本
    WKFavoriteTypeSingleImage // 单图
} WKFavoriteType;


@interface WKFavoriteModel : WKFormItemModel

@property(nonatomic,copy) NSString *no; // 收藏唯一编号
@property(nonatomic,assign) WKFavoriteType type; // 收藏类型 1.纯文本 2.单图
@property(nonatomic,copy) NSString *authorUID; // 作者UID
@property(nonatomic,copy) NSString *authorName; // 作者名称
@property(nonatomic,copy) NSString *createdAt; // 收藏时间
@property(nonatomic,strong) NSDictionary *payload; // 具体数据

@property(nonatomic,copy) void(^onMore)(WKFavoriteModel *model);

@property(nonatomic,strong) UIImage*(^getOneImage)(void); // 如果是单图消息获取这个图片内容

@end



@interface WKFavoriteCell : WKCell



@end

NS_ASSUME_NONNULL_END
