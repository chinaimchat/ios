//
//  BuglyFullTraceTracingConfig.h
//  RaftMonitor
//
//  Created by lolouyang on 2025/12/26.
//

#import <Foundation/Foundation.h>

@class RMServerConfig;
NS_ASSUME_NONNULL_BEGIN

@interface BuglyFullTraceTracingConfig : NSObject

/// 全链路跟踪开启
@property (nonatomic, assign) BOOL enable;

/// 更改NSURLRequest开启
@property (nonatomic, assign) BOOL enableNSURLRequest;

+ (BuglyFullTraceTracingConfig *)configWithServerConfig:(RMServerConfig *)serverConfig;

@end

NS_ASSUME_NONNULL_END
