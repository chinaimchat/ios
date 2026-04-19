//
//  WKStickerCollectedContentView.h
//  WuKongBase
//  收藏正文
//  Created by apple-2 on 2021/10/21.
//

#import <WuKongBase/WuKongBase.h>
#import "WKStickerContentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerCollectedContentView : WKStickerContentView

@property(nonatomic, copy) void (^stickerCollected)(NSArray *array);
@property(nonatomic, strong) NSArray *modelsArray;

@end

NS_ASSUME_NONNULL_END
