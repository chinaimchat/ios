//
//  LBXPermissionPhotos.m
//  LBXKits
//
//  Created by lbxia on 2017/9/10.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "LBXPermissionPhotos.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>


@implementation LBXPermissionPhotos

+ (BOOL)authorized
{
    NSInteger s = [self authorizationStatus];
    if (s == PHAuthorizationStatusAuthorized) {
        return YES;
    }
    if (@available(iOS 14.0, *)) {
        return s == PHAuthorizationStatusLimited;
    }
    return NO;
}


/**
 photo permission status

 @return
 0 :NotDetermined
 1 :Restricted
 2 :Denied
 3 :Authorized
 */
+ (NSInteger)authorizationStatus
{
    if (@available(iOS 8,*))
    {
        return  [PHPhotoLibrary authorizationStatus];
    }
    else
    {
        return  [ALAssetsLibrary authorizationStatus];
    }
}

+ (void)authorizeWithCompletion:(void(^)(BOOL granted,BOOL firstTime))completion
{
    if (@available(iOS 8.0, *)) {
        
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        
        switch (status) {
            case PHAuthorizationStatusAuthorized:
            {
                if (completion) {
                    completion(YES,NO);
                }
            }
                break;
            case PHAuthorizationStatusRestricted:
            case PHAuthorizationStatusDenied:
            {
                if (completion) {
                    completion(NO,NO);
                }
            }
                break;
            case PHAuthorizationStatusNotDetermined:
            {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BOOL ok = (status == PHAuthorizationStatusAuthorized);
                            if (@available(iOS 14.0, *)) {
                                ok = ok || (status == PHAuthorizationStatusLimited);
                            }
                            completion(ok, YES);
                        });
                    }
                }];
            }
                break;
            default:
            {
                if (@available(iOS 14.0, *)) {
                    if (status == PHAuthorizationStatusLimited) {
                        if (completion) {
                            completion(YES, NO);
                        }
                        break;
                    }
                }
                if (completion) {
                    completion(NO,NO);
                }
            }
                break;
        }
        
    }else{
        
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        switch (status) {
            case ALAuthorizationStatusAuthorized:
            {
                if (completion) {
                    completion(YES, NO);
                }
            }
                break;
            case ALAuthorizationStatusNotDetermined:
            {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                [library enumerateGroupsWithTypes:ALAssetsGroupAll
                                       usingBlock:^(ALAssetsGroup *assetGroup, BOOL *stop) {
                                           if (*stop) {
                                               if (completion) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       completion(YES, NO);
                                                   });
                                                   
                                               }
                                           } else {
                                               *stop = YES;
                                           }
                                       }
                                     failureBlock:^(NSError *error) {
                                         if (completion) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 completion(NO, YES);
                                             });
                                         }
                                     }];
            } break;
            case ALAuthorizationStatusRestricted:
            case ALAuthorizationStatusDenied:
            {
                if (completion) {
                    completion(NO, NO);
                }
            }
                break;
        }
    }
  
}

@end
