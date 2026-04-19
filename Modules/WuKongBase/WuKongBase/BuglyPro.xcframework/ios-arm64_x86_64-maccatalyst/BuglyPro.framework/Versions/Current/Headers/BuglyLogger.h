//
//  BuglyLogger.h
//  RaftMonitor
//
//  Created by Tianwu Wang on 2024/11/14.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BuglyLogLevel) {
    BuglyLogLevelAll = 0,
    BuglyLogLevelVerbose = 0,
    BuglyLogLevelDebug,
    BuglyLogLevelInfo,
    BuglyLogLevelWarn,
    BuglyLogLevelError,
    BuglyLogLevelFatal,
    BuglyLogLevelNone,
};


@interface BuglyLogger : NSObject


+ (BuglyLogger *)defaultLogger;

@property (atomic, assign) BuglyLogLevel logLevel;

/// 刷新日志及其缓存
/// 为确保日志性能，BuglyLogger 在实现上采用了一个小缓存，
/// 同时异步进行日志缓存的刷新，因此在必要时可以调用次方法刷新日志
- (void)flush;

/// 打日志接口（不带格式化字符串）
- (void)log:(BuglyLogLevel)level tag:(const char *)tag
       file:(const char *)file func:(const char *)func line:(int)line
        msg:(NSString *)msg;

/// 打日志接口（带格式化字符串）
- (void)log:(BuglyLogLevel)level tag:(const char *)tag
       file:(const char *)file func:(const char *)func line:(int)line
     format:(NSString *)format, ... __attribute__((format(__NSString__, 6, 7))) NS_REQUIRES_NIL_TERMINATION;

// 使用 NSString 对象，方便业务对接日志接口使用（swift）
- (void)bridgeLog:(BuglyLogLevel)level tag:(NSString *)tag
       file:(NSString *)file func:(NSString *)func line:(int)line
        msg:(NSString *)msg;

@end

/**
 * Bugly 日志，允许业务调用此方法输出一部分日志，
 * 该日志会随 Bugly 的 Crash 数据上报，因此对日志内容大小进行了严格限制，非必要情况下，不要依赖此
 * 接口输出过多的日志。
 */

#define BuglyLog(level, tag_name, formatStr, ...) \
do { \
    [[BuglyLogger defaultLogger] log:level tag:tag_name file:__FILE_NAME__ func:__func__ line:__LINE__ format:formatStr, ##__VA_ARGS__, nil]; \
} while (0)

#define BuglyLogDebug(tag, format, ...) BuglyLog(BuglyLogLevelDebug, tag, format, ##__VA_ARGS__)
#define BuglyLogInfo(tag, format, ...)  BuglyLog(BuglyLogLevelInfo, tag, format, ##__VA_ARGS__)
#define BuglyLogWarn(tag, format, ...)  BuglyLog(BuglyLogLevelWarn, tag, format, ##__VA_ARGS__)
#define BuglyLogError(tag, format, ...) BuglyLog(BuglyLogLevelError, tag, format, ##__VA_ARGS__)
#define BuglyLogFatal(tag, format, ...) BuglyLog(BuglyLogLevelFatal, tag, format, ##__VA_ARGS__)

NS_ASSUME_NONNULL_END
