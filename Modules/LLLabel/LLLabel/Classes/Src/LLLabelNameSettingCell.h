//
//  LLLabelNameSettingCell.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLLabelNameSettingModel : WKFormItemModel

@property(nonatomic,copy) NSString *value;

@end

@interface LLLabelNameSettingCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
