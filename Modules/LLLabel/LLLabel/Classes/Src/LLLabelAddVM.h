//
//  LLLabelAddVM.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>
#import "LLLabelListVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface LLLabelAddVM : WKBaseTableVM

@property(nonatomic,assign) NSInteger headerCount;

@property(nonatomic,strong) NSMutableArray<WKChannelInfo*> *memberItems; // 成员列表（网格展示顺序）

@property(nonatomic,strong) LLLabelResp *label; // 默认

@property(nonatomic,copy) NSString *labelName; // 分组名称
@property(nonatomic,copy) void(^onUpdateFinishBtn)(void);


// 移除成员
-(void) removeMember:(NSInteger)index;

-(void) removeMemberWithUID:(NSString *)uid ;


/// 完成标签
-(AnyPromise*) finishLabel;

/// 删除当前标签（编辑态），与 Android {@code DELETE label/{id}} 一致。
- (AnyPromise *)deleteLabel;

/// 打开好友多选（与网格「+」一致）。
- (void)openMemberPicker;

/// 成员增删后刷新表格与保存按钮状态。
- (void)notifyMemberItemsChanged;

@end

NS_ASSUME_NONNULL_END
