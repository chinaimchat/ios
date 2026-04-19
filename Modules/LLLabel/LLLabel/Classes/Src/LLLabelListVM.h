//
//  LLLabelListVM.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@class LLLabelResp;

@interface LLLabelListVM : WKBaseTableVM

@property(nonatomic,strong) NSMutableArray<LLLabelResp*> *labels;
/// 请求删除标签
/// @param _id <#_id description#>
-(AnyPromise*) requestDeleteLabel:(NSString*)_id;

@end

@interface LLLabelResp : WKModel

@property(nonatomic,copy) NSString *_id;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,assign) NSInteger count;
@property(nonatomic,strong) NSArray<NSString*> *members;
@property(nonatomic,strong) NSArray<NSString*> *groups;
@property(nonatomic,strong) NSArray<NSString*> *groupNames;

@end

NS_ASSUME_NONNULL_END
