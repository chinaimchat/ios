//
//  BuglyNetworkMonitor.h
//  Bugly
//
//  Created by Tianwu Wang on 2023/8/15.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(12.0), ios(15.0), watchos(8.0), tvos(15.0))
@interface BuglyNetworkMonitor : NSObject

// 设置当系统网络状态为不可达时（断网），是否记录网络监控日志。默认为 Yes。
// 需要在 SDK 初始化完成后调用
+ (void)setIsRecordWhenNetworkUnreachable:(BOOL)isRecord;

@end

NS_ASSUME_NONNULL_END
