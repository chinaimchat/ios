//
//  WKPinnedMessageListVC.h
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPinnedMessageListVC : WKBaseVC

@property(nonatomic,strong) WKChannel *channel;

@property(nonatomic,strong) WKMessageListView *messageListView;

@property(nonatomic,weak) id<WKConversationContext> mainConversationContext;


@end

NS_ASSUME_NONNULL_END
