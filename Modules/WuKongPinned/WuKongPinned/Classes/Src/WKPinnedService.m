//
//  WKPinnedService.m
//  WuKongPinned
//
//  Created by tt on 2024/5/22.
//

#import "WKPinnedService.h"

@implementation WKPinnedService


+ (instancetype)shared{
    static WKPinnedService *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[WKPinnedService alloc] init];
    });
    
    return _shared;
}


-(void) requestSyncPinnedMessages:(WKChannel*)channel {
    
    uint64_t version = [WKSDK.shared.pinnedMessageManager getMaxVersion:channel];
    __weak typeof(self) weakSelf = self;
    [WKAPIClient.sharedClient POST:@"message/pinned/sync" parameters:@{
        @"channel_id": channel.channelId?:@"",
        @"channel_type": @(channel.channelType),
        @"version": @(version),
    }].then(^(NSDictionary *resultDict){
        NSArray<NSDictionary*> *messageDicts = resultDict[@"messages"];
        if(messageDicts && messageDicts.count>0) {
            NSMutableArray<WKMessage*> *messages = [NSMutableArray array];
            for (NSDictionary *messageDict in messageDicts) {
               WKMessage *message =  [WKMessageUtil toMessage:messageDict];
                [messages addObject:message];
            }
            [WKSDK.shared.chatManager addOrUpdateMessages:messages notify:true];
        }
        NSArray<NSDictionary*> *pinnedMessageDicts = resultDict[@"pinned_messages"];
        if(pinnedMessageDicts && pinnedMessageDicts.count>0) {
            NSMutableArray<WKPinnedMessage*> *pinnedMessages = [NSMutableArray array];
            for (NSDictionary *pinnedMessageDict in pinnedMessageDicts) {
                [pinnedMessages addObject:[weakSelf toPinnedMessage:pinnedMessageDict]];
            }
            [WKSDK.shared.pinnedMessageManager addOrUpdatePinnedMessages:pinnedMessages];
            
        }
        
    });
}

-(AnyPromise*) requestCancelAllPinned:(WKChannel*)channel {
   return [WKAPIClient.sharedClient POST:@"message/pinned/clear" parameters:@{
        @"channel_id": channel.channelId?:@"",
        @"channel_type": @(channel.channelType),
   }];
}

-(void) cancelLocalAllPinned:(WKChannel*)channel {
    NSArray<WKMessage*> *messages = [WKSDK.shared.pinnedMessageManager getPinnedMessagesByChannel:channel];
    
    [WKSDK.shared.pinnedMessageManager deletePinnedByChannel:channel];
    
    for (WKMessage *message in messages) {
        message.remoteExtra.isPinned = false;
    }
    [WKSDK.shared.chatManager addOrUpdateMessages:messages notify:true];
}

-(WKPinnedMessage*) toPinnedMessage:(NSDictionary*)resultDict {
    WKPinnedMessage *pinnedMessage = [WKPinnedMessage new];
    pinnedMessage.messageId = [resultDict[@"message_id"] longLongValue];
    pinnedMessage.messageSeq = (uint32_t)[resultDict[@"message_seq"] longLongValue];
    pinnedMessage.isDeleted = [resultDict[@"is_deleted"] boolValue];
    pinnedMessage.version = [resultDict[@"version"] longLongValue];
    NSString *channelId = resultDict[@"channel_id"];
    NSNumber *channelType =   resultDict[@"channel_type"];
    WKChannel *channel = [WKChannel channelID:channelId channelType:channelType.integerValue];
    pinnedMessage.channel = channel;
    return pinnedMessage;
}

@end
