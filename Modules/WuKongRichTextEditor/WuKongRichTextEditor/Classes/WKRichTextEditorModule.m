//
//  WKRichTextEditorModule.m
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/20.
//

#import "WKRichTextEditorModule.h"
#import "WKRichTextContent.h"
#import "WKRichTextCell.h"
#import "WKRichTextEditorVC.h"

@WKModule(WKRichTextEditorModule)

@interface WKRichTextEditorModule ()<WKConversationInputDelegate>

@end

@implementation WKRichTextEditorModule

-(NSString*) moduleId {
    return @"WuKongRichTextEditor";
}

// 模块初始化
- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongRichTextEditor】模块初始化！");
    
    __weak typeof(self) weakSelf = self;
    
    [[WKApp shared] registerCellClass:WKRichTextCell.class forMessageContntClass:WKRichTextContent.class]; // 注册消息
//    [[WKApp shared] addMessageAllowFavorite:WK_RICHTEXT]; // 富文本消息允许收藏
    // 富文本-输入框右边视图
    [self setMethod:@"conversationinput.textview.rightview.richtext" handler:^id _Nullable(id  _Nonnull param) {
        id<WKConversationContext> context = param[@"context"];
        [context removeInputDelegate:weakSelf];
        [context addInputDelegate:weakSelf];
        
        if(context.hasInputText) {
            return nil;
        }
        if(context.hasReply) {
            return nil;
        }
        if(context.hasEdit) {
            return nil;
        }
        WKChannelInfo *channelInfo = [context getChannelInfo];
        if(channelInfo && channelInfo.flame) { // 阅后即焚不允许发富文本消息
            return nil;
        }
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
        [btn setImage:[weakSelf imageName:@"RichtextFont"] forState:UIControlStateNormal];
       
        [btn lim_addEventHandler:^{
            WKRichTextEditorVC *vc = [WKRichTextEditorVC new];
            vc.channel = context.channel;
            vc.context = context;
            vc.modalPresentationStyle = UIModalPresentationFormSheet;
            [[WKNavigationManager shared].topViewController presentViewController:vc animated:YES completion:nil];
        } forControlEvents:UIControlEventTouchUpInside];
        return btn;
    } category:WKPOINT_CATEGORY_TEXTVIEW_RIGHTVIEW];
}

- (void)conversationInputChange:(nonnull id<WKConversationContext>)context {
    [context refreshInputView];
}



-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRichTextEditor"];
}


@end
