//
//  WKFontColorPicker.h
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKFontColorPicker : UIView

@property(nonatomic,copy) void(^onSelected)(UIColor * __nullable color);

@end

@interface WKFontColorItem : UIView

@property (nonatomic, strong) UIColor *color;

-(instancetype) initWithColor:(UIColor*)color onClick:(void(^)(void))onClick;



@end

NS_ASSUME_NONNULL_END
