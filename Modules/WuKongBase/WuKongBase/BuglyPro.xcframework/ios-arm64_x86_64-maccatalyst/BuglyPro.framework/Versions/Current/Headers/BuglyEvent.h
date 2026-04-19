//
//  BuglyEvent.h
//  RaftMonitor
//
//  Created by Tianwu on 2025/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuglyEvent : NSObject

@property (nonatomic, assign) NSUInteger eventTime;
@property (nonatomic, copy) NSString* eventName;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *metrics;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *dimension;

+ (BOOL)captureEvent:(NSString *)eventName
             metrics:(NSDictionary<NSString *, NSNumber *> *)metrics
           dimension:(NSDictionary<NSString *, NSString *> *)dimension;

+ (BOOL)captureEvent:(BuglyEvent *)event;

@end

NS_ASSUME_NONNULL_END
