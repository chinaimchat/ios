//
//  WKFavoriteModule.m
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import "WKFavoriteModule.h"
#import "WKFavoriteVC.h"
#import "WKFavoriteVM.h"

@WKModule(WKFavoriteModule)
@implementation WKFavoriteModule

-(NSString*) moduleId {
    return @"WuKongFavorite";
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongFavorite】模块初始化！");
    
    // 我的收藏
    __weak typeof(self) weakSelf = self;
    [self setMethod:WKPOINT_ME_FAVORITE handler:^id _Nullable(id  _Nonnull param) {
        return [WKMeItem initWithTitle:LLangW(@"收藏",weakSelf) icon:[weakSelf imageName:@"Me/Index/IconFavorite"] onClick:^{
             [[WKNavigationManager shared] pushViewController:[WKFavoriteVC new] animated:YES];
        }];
    } category:WKPOINT_CATEGORY_ME sort:19880];
    
    // 允许收藏
    [[WKApp shared] addMessageAllowFavorite:WK_TEXT];
    [[WKApp shared] addMessageAllowFavorite:WK_IMAGE];
    
    
    // 收藏
    [self setMethod:WKPOINT_LONGMENUS_FAVORITE handler:^id _Nullable(id  _Nonnull param) {
        WKMessageModel *message = param[@"message"];
       
        if(![[WKApp shared] allowMessageFavorite:message.contentType]) {
            return nil;
        }
        if(message.messageId == 0) {
            return nil;
        }
        UIImage *icon = [WKGenerateImageUtils generateTintedImgWithImage:[weakSelf imageName:@"Conversation/ContextMenu/Favorites"] color:[WKApp shared].config.contextMenu.primaryColor backgroundColor:nil];
        return [WKMessageLongMenusItem initWithTitle:LLangW(@"收藏",weakSelf) icon:icon onTap:^(id<WKConversationContext> context){
            WKFavoriteReq *req = [WKFavoriteReq new];
            req.uniqueKey = [NSString stringWithFormat:@"%llu",message.messageId];
            req.type = message.contentType;
            req.authorUID = message.fromUid;
            if(message.from) {
                req.authorName = message.from.name;
            }
            if(message.contentType == WK_TEXT) {
                WKTextContent *textContent =  (WKTextContent*)message.content;
                if(message.remoteExtra.contentEdit) {
                    textContent = (WKTextContent*)message.remoteExtra.contentEdit;
                    req.uniqueKey = [NSString stringWithFormat:@"%@-edit",req.uniqueKey];
                }
                req.payload = @{
                    @"content": textContent.content,
                };
            }else if (message.contentType == WK_IMAGE) {
                WKImageContent *imageContent =  (WKImageContent*)message.content;
                req.payload = @{
                    @"content": [[WKApp shared] getImageFullUrl:imageContent.remoteUrl].absoluteString,
                };
            }
            [[WKFavoriteVM new] favoriteAdd:req].then(^{
                [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLangW(@"收藏成功！",weakSelf)];
            }).catch(^(NSError *error){
                [[WKNavigationManager shared].topViewController.view showHUDWithHide:error.domain];
            });
        }];
    } category:WKPOINT_CATEGORY_MESSAGE_LONGMENUS sort:1900];
}
-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongFavorite"];
}
@end
