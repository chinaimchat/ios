//
//  WKZSSToolbar.h
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/20.
//

#import <UIKit/UIKit.h>
#import "WKRichTextEditorContext.h"
#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN





@interface WKZSSToolbar : UIView

-(instancetype) initWithContext:(id<WKRichTextEditorContext>)context channel:(WKChannel*)channel;

- (void)updateToolBarTab;
@property(nonatomic,copy) void(^onSend)(void);

@property(nonatomic,assign) BOOL sendDisable;

@end

@interface WKZSSToolbarItem : UIView

@property(nonatomic,strong) UIImageView *iconImgView;

@property(nonatomic,assign) BOOL selected;

@property(nonatomic,copy) NSString *itemName;

-(instancetype) initWithIcon:(UIImage*)icon onClick:(void(^)(WKZSSToolbarItem *item))onClick;



@end

NS_ASSUME_NONNULL_END
