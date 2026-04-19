//
//  LLLabelMemberGridCell.h
//  LLLabel
//
//  标签详情成员区：5 列网格（对齐 Android LabelDetail）。
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@class LLLabelAddVM;

@interface LLLabelMemberGridModel : WKFormItemModel

@property (nonatomic, weak) LLLabelAddVM *addVM;

+ (CGFloat)heightForMemberCount:(NSInteger)count tableWidth:(CGFloat)width;

@end

@interface LLLabelMemberGridCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
