//
//  WKFileModule.m
//  WuKongFile
//
//  Created by tt on 2020/5/5.
//

#import "WKFileModule.h"
#import "WKFileContent.h"
#import "WKFileCell.h"
#import "WKFileChooseUtil.h"
#import "WKPanelFileFuncItem.h"
#import <WuKongBase/WKMoreItemModel.h>
@WKModule(WKFileModule)
@implementation WKFileModule

+(NSString*) gmoduleId {
    return @"WuKongFile";
}

-(NSString*) moduleId {
    return [WKFileModule gmoduleId];
}

- (void)moduleInit:(WKModuleContext *)context {
    NSLog(@"【WuKongFile】模块初始化！");
     // 注册消息
    [[WKApp shared] registerCellClass:WKFileCell.class forMessageContntClass:WKFileContent.class];
    
    // file
    [self setMethod:WKPOINT_CATEGORY_PANELFUNCITEM_FILE handler:^id _Nullable(id  _Nonnull param) {
        WKPanelDefaultFuncItem *item = [[WKPanelFileFuncItem alloc] init];
        item.sort = 8000;
        return item;
    } category:WKPOINT_CATEGORY_PANELFUNCITEM];

    // 对齐 Android WKFileApplication chatFunction「文件」sort=94
    [self setMethod:@"chat_function_chooseFile" handler:^id _Nullable(id  _Nonnull param) {
        NSDictionary *dict = param;
        id<WKConversationContext> ctx = dict[@"context"];
        if (!ctx) {
            return nil;
        }
        UIImage *img = [[WKApp shared] loadImage:@"Conversation/Toolbar/FileNormal" moduleID:[WKFileModule gmoduleId]];
        return [WKMoreItemModel initWithImage:img title:LLang(@"文件") onClick:^(id<WKConversationContext> conversationContext) {
            [conversationContext endEditing];
            [WKPanelFileFuncItem chooseFileForConversationContext:conversationContext finishUI:nil];
        }];
    } category:WKPOINT_CATEGORY_PANELMORE_ITEMS sort:94];
}


// 数据库加载完成
-(void) moduleDidDatabaseLoad:(WKModuleContext*_Nonnull) context {
    WKLogDebug(@"【WuKongFile】数据库加载完成....");
//    WKChannel *fileHelperChannel = [[WKChannel alloc] initWith:[WKApp shared].loginInfo.uid channelType:WK_PERSON];
//    WKConversation *fileHeplerConversation = [[WKSDK shared].conversationManager getConversation:fileHelperChannel];
//    if(!fileHeplerConversation) {
//        WKConversation *fileHeplerConversation = [WKConversation new];
//        fileHeplerConversation.channel = fileHelperChannel;
//        fileHeplerConversation.version = 1;
//        fileHeplerConversation.lastMsgTimestamp = [[NSDate date] timeIntervalSince1970];
//        [[WKSDK shared].conversationManager addConversation:fileHeplerConversation];
//    }
    
}
-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongFile"];
}

@end
