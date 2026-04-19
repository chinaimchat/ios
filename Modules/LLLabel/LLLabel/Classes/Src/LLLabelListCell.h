//
//  LLLabelListCell.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@class LLLabelResp;

@interface LLLabelListModel : WKFormItemModel

@property(nonatomic,copy) NSString *title;
@property(nonatomic,strong) NSNumber *num;
@property(nonatomic,copy) NSString *desc;
@property(nonatomic,strong,nullable) LLLabelResp *labelResp;

@end

@interface LLLabelListCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
