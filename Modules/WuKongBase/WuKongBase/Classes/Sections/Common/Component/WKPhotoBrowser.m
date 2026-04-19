//
//  WKPhotoBrowser.m
//  WuKongBase
//
//  Created by tt on 2022/3/21.
//

#import "WKPhotoBrowser.h"
#import "NSData+ImageFormat.h"
#import "UIImage+Compression.h"
#import "WKApp.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHAsset.h>
#import "WKFileLocationHelper.h"
#import "WKNavigationManager.h"
#import "WuKongBase.h"
#import <ZLPhotoBrowser/ZLPhotoBrowser-Swift.h>

@implementation WKPhotoBrowser

static WKPhotoBrowser *_instance;


+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKPhotoBrowser *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

-(void) showPreviewWithSender:(UIViewController*)vc selectImageBlock:(void(^)(NSArray<UIImage *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock{
    ZLPhotoPicker *picker = [[ZLPhotoPicker alloc] initWithSelectedAssets:@[]];
    picker.selectImageBlock = ^(NSArray<ZLResultModel *> * _Nonnull results, BOOL isOriginal) {
        NSMutableArray<UIImage*> *images = [NSMutableArray array];
        NSMutableArray<PHAsset*> *assets = [NSMutableArray array];
        if(results && results.count>0) {
            for (ZLResultModel *result in results) {
                [images addObject:result.image];
                [assets addObject:result.asset];
            }
        }
        if(selectImageBlock) {
            selectImageBlock(images,assets,isOriginal);
        }
    };
    [picker showPreviewWithAnimate:YES sender:vc];
}

-(void) showPreviewWithSender:(UIViewController*)vc  selectCompressImageBlock:(void(^)(NSArray<NSData *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock allowSelectVideo:(BOOL)allowSelectVideo{
    [ZLPhotoConfiguration default].saveNewImageAfterEdit = NO;
    [ZLPhotoConfiguration default].maxSelectCount = 9;
    [self showWithSender:vc selectCompressImageBlock:selectImageBlock allowSelectVideo:allowSelectVideo preview:YES];
    
}

-(void) showPhotoLibraryWithSender:(UIViewController*)vc  selectCompressImageBlock:(void(^)(NSArray<NSData *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock allowSelectVideo:(BOOL)allowSelectVideo {
    [self showPhotoLibraryWithSender:vc selectCompressImageBlock:selectImageBlock maxSelectCount:1 allowSelectVideo:allowSelectVideo];
}

-(void) showPhotoLibraryWithSender:(UIViewController*)vc  selectCompressImageBlock:(void(^)(NSArray<NSData *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock maxSelectCount:(NSInteger)maxCount allowSelectVideo:(BOOL)allowSelectVideo {
    [ZLPhotoConfiguration default].saveNewImageAfterEdit = NO;
    [ZLPhotoConfiguration default].maxSelectCount = maxCount;
    [self showWithSender:vc selectCompressImageBlock:selectImageBlock allowSelectVideo:allowSelectVideo preview:NO];
}


-(void) showWithSender:(UIViewController*)vc  selectCompressImageBlock:(void(^)(NSArray<NSData *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock allowSelectVideo:(BOOL)allowSelectVideo preview:(BOOL)preview{
    [ZLPhotoConfiguration default].allowSelectVideo = allowSelectVideo;
    ZLPhotoPicker *picker = [[ZLPhotoPicker alloc] initWithSelectedAssets:@[]];
    picker.selectImageBlock = ^(NSArray<ZLResultModel *> *results, BOOL isOriginal) {
        NSMutableArray<UIImage*> *images = [NSMutableArray array];
        NSMutableArray<PHAsset*> *assets = [NSMutableArray array];
        if(results && results.count>0) {
            for (ZLResultModel *result in results) {
                [images addObject:result.image];
                [assets addObject:result.asset];
            }
        }
        if(selectImageBlock) {
            NSMutableArray<NSData*> *imageDatas = [NSMutableArray array];
            __block NSInteger selectRetain = 0;
            if(images && images.count>0) {
                selectRetain = images.count;
                for (UIImage *img in images) {
                    SDImageFormat sdimageFormat = [img sd_imageFormat];
                    
                    NSData *imgData = [img sd_imageDataAsFormat:sdimageFormat compressionQuality:1.0f];
//                    NSData *imgData = UIImagePNGRepresentation(img);
                    JLImageFormat format = [NSData jl_imageFormatWithImageData: imgData];
                    if(format == JLImageFormatGIF) {
                        [UIImage jl_compressWithImageGIF:imgData targetSize:img.size targetByte:[WKApp shared].config.imageMaxLimitBytes handler:^(NSData * _Nullable compressedData, CGSize gifImageSize, NSError * _Nullable error) {
                            selectRetain--;
                            if(compressedData) {
                                [imageDatas addObject:compressedData];
                            } else { // 压缩失败 只能将原图发出去
                                WKLogWarn(@"压缩失败，将原图发出去！");
                                [imageDatas addObject:imgData];
                            }
                            if(selectRetain <= 0) {
                                selectImageBlock(imageDatas,assets,isOriginal);
                                return;
                            }
                        }];
                    }else {
                        selectRetain--;
                        NSData *imgCompressData  = [UIImage jl_compressImageSize:img toByte:[WKApp shared].config.imageMaxLimitBytes];
                        if(imgCompressData) {
                            [imageDatas addObject:imgCompressData];
                        }
                        if(selectRetain <= 0) {
                            selectImageBlock(imageDatas,assets,isOriginal);
                            return;
                        }
                    }
                }
            }
            if(selectRetain <= 0) {
                selectImageBlock(imageDatas,assets,isOriginal);
            }
           
        }
    };
    if(preview) {
        [picker showPreviewWithAnimate:YES sender:vc];
    }else{
        [picker showPhotoLibraryWithSender:vc];
    }
    
}

+(void) fetchAssetFilePathWithAsset:(PHAsset*)asset completion:(void(^)(NSString* filePath))completion {
    if(asset.mediaType == PHAssetMediaTypeVideo) {
        [ZLPhotoManager fetchAVAssetForVideo:asset completion:^(AVAsset * avasset, NSDictionary * infoDict) {
            if(!avasset) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
                return;
            }
            [WKPhotoBrowser exportAsset:avasset presetName:AVAssetExportPreset1280x720 completion:^(NSString *filePath) {
                if(filePath && [WKPhotoBrowser validateExportedVideo:filePath sourceDuration:avasset.duration]) {
                    completion(filePath);
                } else {
                    if(filePath) {
                        [[NSFileManager defaultManager] removeItemAtPath:[[NSURL URLWithString:filePath] path] error:nil];
                    }
                    [WKPhotoBrowser exportAsset:avasset presetName:AVAssetExportPresetPassthrough completion:^(NSString *fallbackPath) {
                        completion(fallbackPath);
                    }];
                }
            }];
        }];
    }else {
        [ZLPhotoManager fetchAssetFilePathFor:asset completion:^(NSString * _Nullable filepath) {
            completion(filepath);
        }];
    }
}

+(void) exportAsset:(AVAsset*)avasset presetName:(NSString*)presetName completion:(void(^)(NSString* filePath))completion {
    NSString *outputFileName = [WKFileLocationHelper genFilenameWithExt:@"mp4"];
    NSString *outputPath = [WKFileLocationHelper filepathForTempDir:@"video_temp" filename:outputFileName];
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avasset
                                                                     presetName:presetName];
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    session.outputFileType = AVFileTypeMPEG4;
    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (session.status == AVAssetExportSessionStatusCompleted) {
                completion(session.outputURL.absoluteString);
            } else {
                [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
                completion(nil);
            }
        });
    }];
}

/// 校验导出的视频码率是否正常，防止 HDR→SDR 转码失败产出全黑帧但状态为"成功"的情况。
/// 全黑帧视频的典型特征：码率极低（实测 ~9KB/s），正常视频即使画面简单也远高于 20KB/s。
+(BOOL) validateExportedVideo:(NSString*)fileURLString sourceDuration:(CMTime)duration {
    float seconds = CMTimeGetSeconds(duration);
    if(seconds <= 0) return YES;
    NSString *filePath = [[NSURL URLWithString:fileURLString] path];
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long fileSize = [attrs fileSize];
    float bytesPerSecond = fileSize / seconds;
    return bytesPerSecond > 20000;
}

-(void) exportVideo:(NSURL*)videoURL completion:(void(^)(NSString* filePath))completion {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    [WKPhotoBrowser exportAsset:avAsset presetName:AVAssetExportPreset1280x720 completion:^(NSString *filePath) {
        if(filePath && [WKPhotoBrowser validateExportedVideo:filePath sourceDuration:avAsset.duration]) {
            completion(filePath);
        } else {
            if(filePath) {
                [[NSFileManager defaultManager] removeItemAtPath:[[NSURL URLWithString:filePath] path] error:nil];
            }
            [WKPhotoBrowser exportAsset:avAsset presetName:AVAssetExportPresetPassthrough completion:^(NSString *fallbackPath) {
                completion(fallbackPath);
            }];
        }
    }];
}


-(void) showPreviewWithSender:(UIViewController*)vc  selectCompressImageBlock:(void(^)(NSArray<NSData *>* _Nonnull images,NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal))selectImageBlock {
    [self showPreviewWithSender:vc selectCompressImageBlock:selectImageBlock allowSelectVideo:YES];
    
}

-(void) takePhoto:(UIViewController*)vc doneBlock:(void(^)(UIImage *img,NSURL *url))doneBlock cancelBlock:(void(^)(void))cancelBlock{
//    [ZLPhotoConfiguration default].allowRecordVideo = YES;
    [ZLPhotoConfiguration default].allowSelectVideo = YES;
    ZLCustomCamera *customCamera = [[ZLCustomCamera alloc] init];
    [customCamera setTakeDoneBlock:^(UIImage * _Nullable image, NSURL * _Nullable url) {
        if(doneBlock) {
            if(url) {
                UIView *topView = [WKNavigationManager shared].topViewController.view;
                [topView showHUD:LLang(@"压缩中")];
                [self exportVideo:url completion:^(NSString * _Nonnull filePath) {
                    [topView hideHud];
                    doneBlock(image,[NSURL URLWithString:filePath]);
                }];
            }else {
                doneBlock(image,nil);
            }
           
        }
    }];
    [customCamera setCancelBlock:^{
        if(cancelBlock) {
            cancelBlock();
        }
    }];
    [vc showDetailViewController:customCamera sender:nil];
}


@end
