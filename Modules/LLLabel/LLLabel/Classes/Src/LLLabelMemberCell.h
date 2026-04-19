//
//  LLLabelMemberCell.h
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLLabelMemberModel : WKFormItemModel

@property(nonatomic,copy) NSString *firstPinYIn;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *avatarURL;

@end

@interface LLLabelMemberCell : WKFormItemCell

@end

NS_ASSUME_NONNULL_END
