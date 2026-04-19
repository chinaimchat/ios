//
//  WKPinnedMessageContext.h
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>
#import "WKPinnedMessageListVC.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKPinnedMessageContext : NSObject<WKConversationContext>

- (instancetype)initWithPinnedMessageListVC:(WKPinnedMessageListVC*) pinnedMessageListVC;

@end

NS_ASSUME_NONNULL_END
