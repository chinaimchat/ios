//
//  WKPinnedMessageDataProvider.h
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPinnedMessageDataProvider : NSObject<WKMessageListDataProvider>

- (instancetype)initWithChannel:(WKChannel*)channel conversationContext:(nonnull id<WKConversationContext>)conversationContext;


@end

NS_ASSUME_NONNULL_END
