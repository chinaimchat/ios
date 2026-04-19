//
//  LLLabelAddVC.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>
#import "LLLabelAddVM.h"
#import "LLLabelListVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface LLLabelAddVC : WKBaseTableVC<LLLabelAddVM*>

@property(nonatomic,strong) LLLabelResp *label;
/// 新建标签时，由列表「新建 → 选人」带入的初始成员 uid（仅好友，与 Android 一致）。
@property(nonatomic,copy,nullable) NSArray<NSString *> *prefilledMemberUids;

@end

NS_ASSUME_NONNULL_END
