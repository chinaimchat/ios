//
//  BuglySafeException.h
//  RaftMonitor
//
//  Created by Tianwu on 2025/9/26.
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Bugly OC 异常/ signal 兜底实现
 *  按照要求保护部分未处理异常导致程序崩溃
 */
@interface BuglySafeException : NSObject

@end

NS_ASSUME_NONNULL_END
