//
//  UIView+BuglyViewCapture.h
//  RaftMonitor
//
//  Created by Tianwu on 2025/6/16.
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BuglyViewCapture)

/**
 * 是否让 Bugly View Capture 忽略对该 View 进行模糊处理
 * 默认为 NO，将会对该 View 进行模糊处理
 * 若设置为 YES，该 View 及其子 View 都不进行模糊处理
 */
@property (nonatomic, assign) BOOL buglyViewCaptureIgnoreMask;

@end

NS_ASSUME_NONNULL_END
