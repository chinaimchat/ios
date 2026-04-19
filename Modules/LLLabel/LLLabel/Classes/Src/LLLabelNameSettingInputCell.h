//
//  LLLabelNameSettingInputCell.h
//  LLBase
//
//  Created by LQ on 2022/11/21.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLLabelNameSettingInputModel:WKFormItemModel

@property(nonatomic,copy) NSString *placeholder;
@property(nonatomic,copy) NSString *value;
@property(nonatomic,copy) void(^onChange)(NSString*text);

@end

@interface LLLabelNameSettingInputCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
