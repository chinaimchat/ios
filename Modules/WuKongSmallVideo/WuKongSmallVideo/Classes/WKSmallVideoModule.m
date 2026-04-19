//
//  WKSmallVideoModule.m
//  WuKongSmallVideo
//
//  Created by tt on 2020/4/29.
//

#import "WKSmallVideoModule.h"
#import "WKSmallVideoCell.h"
#import "WKSmallVideoContent.h"
#import "WKPanelCameraFuncItem.h"
#import "WKMergeForwardDetailVideoCell.h"
#import <WuKongBase/WKMoreItemModel.h>
@WKModule(WKSmallVideoModule)
@implementation WKSmallVideoModule

+(NSString*) gmoduleId {
    return @"WuKongSmallVideo";
}

-(NSString*) moduleId {
    return [WKSmallVideoModule gmoduleId];
}

- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongSmallVideo】模块初始化！");
    // 注册小视频消息
    [[WKApp shared] registerCellClass:WKSmallVideoCell.class forMessageContntClass:WKSmallVideoContent.class];
    
    [[WKApp shared] addMessageAllowForward:WK_SMALLVIDEO];
    
    // camera
    [self setMethod:WKPOINT_CATEGORY_PANELFUNCITEM_CAMERA handler:^id _Nullable(id  _Nonnull param) {
        WKPanelDefaultFuncItem *item = [[WKPanelCameraFuncItem alloc] init];
        item.sort = 4900;
        return item;
    } category:WKPOINT_CATEGORY_PANELFUNCITEM];

    // 对齐 Android WKVideoApplication chatFunction「拍摄」sort=99，进入「更多」宫格
    [self setMethod:@"chat_function_recording" handler:^id _Nullable(id  _Nonnull param) {
        NSDictionary *dict = param;
        id<WKConversationContext> ctx = dict[@"context"];
        if (!ctx) {
            return nil;
        }
        UIImage *img = [[WKApp shared] loadImage:@"Conversation/Toolbar/CameraNormal" moduleID:[WKSmallVideoModule gmoduleId]];
        return [WKMoreItemModel initWithImage:img title:LLang(@"拍摄") onClick:^(id<WKConversationContext> conversationContext) {
            [conversationContext endEditing];
            [WKPanelCameraFuncItem openCaptureForConversationContext:conversationContext finishUI:nil];
        }];
    } category:WKPOINT_CATEGORY_PANELMORE_ITEMS sort:99];
    
    // 发送视频消息
    [self setMethod:WKPOINT_SEND_VIDEO handler:^id _Nullable(id  _Nonnull param) {
        id<WKConversationContext> context = param[@"context"];
        NSData *coverData = param[@"cover_data"];
        NSString *videoURL = param[@"video_url"];
        NSData *videoData = param[@"video_data"];
        NSInteger second = param[@"second"] ? [param[@"second"] integerValue] : 0;
        if(!context || !coverData) {
            return nil;
        }
        if(videoURL) {
            [context sendMessage:[WKSmallVideoContent smallVideoContentWithVideoURL:videoURL coverData:coverData second:second]];
        } else if(videoData) {
            [context sendMessage:[WKSmallVideoContent smallVideoContent:videoData coverData:coverData second:second]];
        }
        return nil;
    }];
    
    [[WKApp shared].endpointManager registerMergeForwardItem:WK_SMALLVIDEO cls:WKMergeForwardDetailVideoModel.class];
}

-(void) sendVideoMessage:(NSURL*)videoURL context:(id<WKConversationContext>)context {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    if(!asset) {
        return;
    }
    long long second = asset.duration.value/asset.duration.timescale;
    UIImage *coverImg = [self getVideoPreViewImage:asset];
    NSData *coverData = UIImageJPEGRepresentation(coverImg, 0.8);
    NSString *filePath = videoURL.path;
    if(filePath) {
        [context sendMessage:[WKSmallVideoContent smallVideoContentWithVideoURL:filePath coverData:coverData second:second]];
    } else {
        [context sendMessage:[WKSmallVideoContent smallVideoContent:[NSData dataWithContentsOfURL:videoURL] coverData:coverData second:second]];
    }
}
//full 是否是原图
-(void) sendImageMessage:(UIImage*)image full:(BOOL)full context:(id<WKConversationContext>)context {
    WKImageContent *imageMessageContent = [WKImageContent initWithImage:image];
    [context sendMessage:imageMessageContent];
    
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:[WKSmallVideoModule gmoduleId]];
}

// 获取视频第一帧
- (UIImage*) getVideoPreViewImage:(AVURLAsset *)asset
{
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

@end
