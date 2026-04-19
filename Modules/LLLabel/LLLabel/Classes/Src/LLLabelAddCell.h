//
//  LLLabelAddCell.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLLabelAddModel : WKFormItemModel

@property(nonatomic,copy) NSString *title;
/// 为 YES 时居中红字、隐藏加号，用于「删除标签」等危险操作行。
@property(nonatomic,assign) BOOL dangerStyle;

@end

@interface LLLabelAddCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
