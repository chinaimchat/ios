//
//  WKPinnedService.h
//  WuKongPinned
//
//  Created by tt on 2024/5/22.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKPinnedService : NSObject

+ (instancetype _Nonnull )shared;

-(void) requestSyncPinnedMessages:(WKChannel*)channel;

// 取消所有置顶
-(AnyPromise*) requestCancelAllPinned:(WKChannel*)channel;

// 取消本地所有置顶
-(void) cancelLocalAllPinned:(WKChannel*)channel;

@end

NS_ASSUME_NONNULL_END
