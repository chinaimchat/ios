//
//  WKPanelCameraFuncItem.m
//  WuKongSmallVideo
//
//  Created by tt on 2022/5/4.
//

#import "WKPanelCameraFuncItem.h"
#import "WKSmallVideoModule.h"
#import "WKSmallVideoContent.h"
@implementation WKPanelCameraFuncItem

- (NSString *)sid {
    return @"apm.wukong.camera";
}

- (UIImage *)itemIcon {
    return [self imageName:@"Conversation/Toolbar/CameraNormal"];
}

+ (void)openCaptureForConversationContext:(id<WKConversationContext>)context finishUI:(void (^)(void))finishUI {
    WKPermissionShowAlertView *showAlertView = [[WKPermissionShowAlertView alloc] init];
    showAlertView.currentPresentVC = [context targetVC];
    WKPanelCameraFuncItem *sender = [[WKPanelCameraFuncItem alloc] init];
    if (![showAlertView requesetRecordPermission]) {
        if (finishUI) {
            finishUI();
        }
        return;
    }
    [showAlertView requesetVideoPermissionCompletion:^(BOOL permission) {
        if (!permission) {
            if (finishUI) {
                finishUI();
            }
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WKPhotoBrowser shared] takePhoto:[context targetVC] doneBlock:^(UIImage * _Nonnull img, NSURL * _Nonnull url) {
                if (finishUI) {
                    finishUI();
                }
                if (img) {
                    [sender sendImageMessage:img full:NO context:context];
                } else if (url) {
                    [sender sendVideoMessage:url context:context];
                }
            } cancelBlock:^{
                if (finishUI) {
                    finishUI();
                }
            }];
        });
    }];
}

-(void) onPressed:(UIButton*)btn {
    id<WKConversationContext> context = self.inputPanel.conversationContext;
    __weak typeof(btn) weakBtn = btn;
    [WKPanelCameraFuncItem openCaptureForConversationContext:context finishUI:^{
        weakBtn.selected = NO;
    }];
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
- (NSString *)title {
    return LLang(@"拍摄");
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:[WKSmallVideoModule gmoduleId]];
}
@end
