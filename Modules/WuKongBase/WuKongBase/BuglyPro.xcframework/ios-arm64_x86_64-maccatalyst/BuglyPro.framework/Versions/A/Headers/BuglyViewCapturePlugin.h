//
//  BuglyViewCapturePlugin.h
//  RaftMonitor
//
//  Created by Tianwu on 2025/6/17.
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuglyViewCapturePlugin : NSObject

+ (void)addIgnoreMaskViewClass:(Class)viewCls;

@end

NS_ASSUME_NONNULL_END
