//
//  WKProhibitwordsService.h
//  WuKongBase
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 敏感词 / 违禁词相关能力（本地仓库缺失文件时的占位实现，可按业务接入服务端策略）。
@interface WKProhibitwordsService : NSObject

+ (instancetype)shared;

/// 是否包含违禁内容。当前占位实现恒为 NO，避免阻塞编译；接入真实词库或接口后在此实现。
- (BOOL)containsProhibitedContent:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
