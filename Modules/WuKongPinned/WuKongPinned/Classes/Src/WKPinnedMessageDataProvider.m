//
//  WKPinnedMessageDataProvider.m
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import "WKPinnedMessageDataProvider.h"

@interface WKPinnedMessageDataProvider ()

@property(nonatomic,strong) WKChannel *channel;
@property(nonatomic,strong) WKMessageList *messageList;
@property(nonatomic,strong) id<WKConversationContext> conversationContextInner;

@end

@implementation WKPinnedMessageDataProvider

- (instancetype)initWithChannel:(WKChannel*)channel conversationContext:(nonnull id<WKConversationContext>)conversationContext
{
    self = [super init];
    if (self) {
        self.channel = channel;
        self.conversationContextInner = conversationContext;
    }
    return self;
}

-(void) pullup:(void(^)(bool more))complete {
    complete(false);
}

// 下拉加载
-(void) pulldown:(void(^)(bool more))complete {
    complete(false);
}

- (void)pullFirst:(WKConversationPosition *)position complete:(void(^)(bool more))complete  {
    
   NSArray<WKMessage*> *messages =  [WKSDK.shared.pinnedMessageManager getPinnedMessagesByChannel:self.channel];
    
    [self.messageList addMessages:[self messagesToMessageModels:messages]];
    
    complete(false);
}

- (NSInteger)messageCount {
    
    return [self.messageList messageCount];
}


- (NSInteger)dateCount {
    return self.messageList.dates.count;
}

- (NSString *)dateWithSection:(NSInteger)section {
    return self.messageList.dates[section];
}

- (nonnull NSArray<NSString *> *)dates { 
    return self.messageList.dates;
}


- (WKMessageModel *)messageAtIndexPath:(NSIndexPath *)indexPath {
    NSString *date = self.messageList.dates[indexPath.section];
    return [self.messageList messagesAtDate:date][indexPath.row];
}

- (NSArray<WKMessageModel *> *)messagesAtDate:(NSString *)date {
    return [self.messageList messagesAtDate:date];
}

- (NSArray<WKMessageModel *> *)messagesAtSection:(NSInteger)section {
    NSString *date = self.messageList.dates[section];
    return [self.messageList messagesAtDate:date];
}


- (WKMessageList *)messageList {
    if(!_messageList) {
        _messageList = [[WKMessageList alloc] init];
    }
    return _messageList;
}

-(id<WKConversationContext>) conversationContext {
    
    return self.conversationContextInner;
}

-(NSArray<WKMessageModel*>*) messagesToMessageModels:(NSArray<WKMessage*>*) messages {
    NSMutableArray<WKMessageModel*> *messageModels = [NSMutableArray array];
    for (WKMessage *message in messages) {
        WKMessageModel *messageModel = [[WKMessageModel alloc] initWithMessage:message];
        [messageModels addObject:messageModel];
    }
    return messageModels;
}


- (void)clearMessages {
    [self.messageList clearMessages];
}
-(NSIndexPath*) replaceMessage:(WKMessageModel*)newMessage atClientMsgNo:(NSString*)clientMsgNo {
    
    return [self.messageList replaceMessage:newMessage atClientMsgNo:clientMsgNo];
}
-(NSArray<WKMessageModel*>*) getMessagesWithContentType:(NSInteger)contentType {
    return [self.messageList getMessagesWithContentType:contentType];
}

- (NSArray<WKMessageModel *> *)getSelectedMessages {
    return [self.messageList getSelectedMessages];
}


- (void)cancelSelectedMessages {
    [self.messageList cancelSelectedMessages];
}


-(void) addMessage:(WKMessageModel*)message {
    [self.messageList addMessage:message];
}

- (BOOL)hasTyping {
    return false;
}
// 置顶消息列表不需要显示typing所以这里啥也不做
-(void) addTypingMessageIfNeed:(WKMessageModel*)messageModel {
    
}

- (NSIndexPath *)replaceTyping:(WKMessageModel *)message {
    return [self.messageList replaceTyping:message];
}

-(NSIndexPath*) removeMessage:(WKMessageModel*) message {
    
    return [self.messageList removeMessage:message];
}
- (NSIndexPath *)removeMessage:(WKMessageModel *)message sectionRemove:(BOOL *)sectionRemove {
    return [self.messageList removeMessage:message sectionRemove:sectionRemove];
}

-(NSIndexPath*) indexPathAtMessageID:(uint64_t)messageID {
    return [self.messageList indexPathAtMessageID:messageID];
}

-(NSIndexPath*) indexPathAtStreamNo:(NSString*)streamNo {
    return [self.messageList indexPathAtStreamNo:streamNo];
}

-(NSArray<NSIndexPath*>*) indexPathAtMessageReply:(uint64_t)messageID {
    return [self.messageList indexPathAtMessageReply:messageID];
}

-(NSArray<WKMessageModel*>*) messagesAtMessageReply:(uint64_t)messageID {
    return [self.messageList messagesAtMessageReply:messageID];
}

-(NSIndexPath*) indexPathAtClientMsgNo:(NSString*) clientMsgNo {
    return [self.messageList indexPathAtClientMsgNo:clientMsgNo];
}

-(void) insertMessage:(WKMessageModel*)message atIndex:(NSIndexPath*)indexPath {
    [self.messageList insertMessage:message atIndex:indexPath];
}
- (WKMessageModel *)lastMessage {
    return [self.messageList lastMessage];
}

- (WKMessageModel *)firstMessage {
    return [self.messageList firstMessage];
}

-(NSIndexPath*) indexPathAtOrderSeq:(uint32_t)orderSeq {
    return [self.messageList indexPathAtOrderSeq:orderSeq];
}


- (void)didReaded:(NSArray<WKMessageModel *> *)messageModels {
    if(![WKSDK shared].receiptManager.messageReadedProvider) {
        return;
    }
    NSMutableArray<WKMessage*> *messages = [NSMutableArray array];
    for (WKMessageModel *messageModel in messageModels) {
        [messages addObject:messageModel.message];
    }
    [[WKSDK shared].receiptManager addReceiptMessages:self.channel messages:messages];
}



-(WKMessageModel* __nullable) messageAtClientMsgNo:(NSString*)clientMsgNo {
   NSIndexPath *indexPath = [self indexPathAtClientMsgNo:clientMsgNo];
    if(!indexPath) {
        return nil;
    }
    return [self messageAtIndexPath:indexPath];
}

-(WKMessageModel*__nullable) messageAtStreamNo:(NSString*)streamNo {
    NSIndexPath *indexPath = [self indexPathAtStreamNo:streamNo];
     if(!indexPath) {
         return nil;
     }
    return [self messageAtIndexPath:indexPath];
}

@end
