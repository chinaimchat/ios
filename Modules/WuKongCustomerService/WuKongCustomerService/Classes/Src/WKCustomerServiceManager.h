//
//  WKCustomerServiceManager.h
//  WuKongCustomerService
//
//  Created by tt on 2022/4/1.
//

#import <Foundation/Foundation.h>

#import <PromiseKit/PromiseKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKCustomerServiceManager : NSObject

+ (WKCustomerServiceManager *)shared;

@property(nonatomic,copy) NSString *appID;

/**
  访客登录或注册
 */
-(AnyPromise*) visitorLoginOrRegister;

/**
  访客频道获取或创建
 */
-(AnyPromise*) visitorTopicChannelGetOrCreate;


/**
 获取当前访客发消息的频道ID
 */
-(NSString*) visitorMsgChannelID:(NSString*)channelID channelType:(NSInteger)channelType;

@end

NS_ASSUME_NONNULL_END
