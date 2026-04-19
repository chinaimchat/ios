//
//  LLLabelQuickAddVM.h
//  LLLabel
//
//  Created by LQ on 2023/2/21.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLLabelQuickAddVM : WKBaseTableVM

@property(nonatomic,copy) NSString *labelName;

/// 完成标签
-(AnyPromise*) finishLabel:(NSArray<NSString*>*)uids;

@property(nonatomic,copy) void(^onUpdateFinishBtn)(void);

@end

NS_ASSUME_NONNULL_END
