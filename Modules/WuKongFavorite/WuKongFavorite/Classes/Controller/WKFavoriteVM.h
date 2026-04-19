//
//  WKFavoriteVM.h
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import <WuKongBase/WuKongBase.h>
#import "WKFavoriteCell.h"
@class WKFavoriteReq;
@class WKFavoriteVM;
NS_ASSUME_NONNULL_BEGIN


@interface WKFavoriteVM : WKBaseTableVM

@property(nonatomic,copy) void(^onMore)(WKFavoriteModel *model);

/// 删除收藏
/// @param no 收藏编号
-(AnyPromise*) favoriteDelete:(NSString*)no;

/// 添加收藏
/// @param req <#req description#>
-(AnyPromise*) favoriteAdd:(WKFavoriteReq*)req;


@end

@interface WKFavoriteReq : WKModel
@property(nonatomic,assign) NSInteger type; // 收藏类型 1.纯文本 2.单图
@property(nonatomic,copy) NSString *uniqueKey; // 唯一标记（一般为消息id）
@property(nonatomic,copy) NSString *authorUID; // 作者UID
@property(nonatomic,copy) NSString *authorName; // 作者名称
@property(nonatomic,strong) NSDictionary *payload; // 具体数据
@end

@interface WKFavoriteResp : WKModel
@property(nonatomic,copy) NSString *no; // 收藏唯一编号
@property(nonatomic,assign) NSInteger type; // 收藏类型 1.纯文本 2.单图
@property(nonatomic,copy) NSString *authorUID; // 作者UID
@property(nonatomic,copy) NSString *authorName; // 作者名称
@property(nonatomic,copy) NSString *createdAt; // 收藏时间
@property(nonatomic,strong) NSDictionary *payload; // 具体数据
@end


NS_ASSUME_NONNULL_END
