//
//  BuglyTraceContextInjector.h
//  RaftMonitor
//
//  Created by lolouyang on 2025/12/23.
//  Copyright © 2025 Tencent. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuglyTraceContextInjector : NSObject

/// 向task的request的header添加W3C协议字段，实现全链路跟踪
+ (NSURLSessionTask *)addTraceContextToTask:(NSURLSessionTask *)task withEnable:(BOOL)enable enableURLRequest:(BOOL)enableURLRequest;

/// 向request的header添加W3C协议字段，实现全链路跟踪
+ (NSURLRequest *)addTraceContextToRequest:(NSURLRequest *)request withEnable:(BOOL)enable enableURLRequest:(BOOL)enableURLRequest;


@end

NS_ASSUME_NONNULL_END
