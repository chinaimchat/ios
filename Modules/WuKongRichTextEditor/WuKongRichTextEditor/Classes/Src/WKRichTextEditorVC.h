//
//  WKRichTextEditorVC.h
//  WuKongAdvanced
//
//  Created by tt on 2022/7/20.
//

#import <WuKongBase/WuKongBase.h>
#import "WKRichTextEditorContext.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRichTextEditorVC : UIViewController<WKRichTextEditorContext>

@property(nonatomic,strong) WKChannel *channel;

@property(nonatomic,weak) id<WKConversationContext> context;

@end


NS_ASSUME_NONNULL_END
