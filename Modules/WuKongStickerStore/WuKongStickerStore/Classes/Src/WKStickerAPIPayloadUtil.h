//
//  WKStickerAPIPayloadUtil.h
//  WuKongStickerStore
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与钱包等模块一致：后端常见 `{ "data": [ ... ] }` / `{ "list": ... }` 包裹，而 {@code WKAPIClient resultToModel} 对字典根只会映射成单条模型。
@interface WKStickerAPIPayloadUtil : NSObject

+ (NSArray<NSDictionary *> *)dictionaryArrayFromAPIResponse:(nullable id)responseObject;

/// 单对象接口（如 {@code sticker/user/sticker}）常见 {@code data} 内层字典。
+ (nullable NSDictionary *)dictionaryFromAPIResponse:(nullable id)responseObject;

@end

NS_ASSUME_NONNULL_END
