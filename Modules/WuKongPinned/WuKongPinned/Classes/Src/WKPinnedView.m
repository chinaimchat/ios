//
//  WKPinnedView.m
//  WuKongPinned
//
//  Created by tt on 2024/5/20.
//

#import "WKPinnedView.h"
#import <WuKongBase/WuKongBase-Swift.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKPinnedService.h"
#import "WKPinnedMessageListVC.h"
@interface WKPinnedView ()<WKPinnedMessageManagerDelegate,WKChatManagerDelegate>

@property(nonatomic,strong) id<WKConversationContext> context;



@property(nonatomic,strong) AnimatedCountLabelNode *titleNode;

@property(nonatomic,strong) AnimatedNavigationStripeNode *lineNode;


@property(nonatomic,strong) UILabel *textNode;

@property(nonatomic,assign) NSInteger currentIndex;

@property(nonatomic,strong) UIButton *pinnedListBtn;

@property(nonatomic,strong) UIButton *closeBtn;

@property(nonatomic,strong) NSMutableArray<WKMessage*> *pinnedMessages;

@end

@implementation WKPinnedView



-(instancetype) initContext:(id<WKConversationContext>)context {
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 50.0f)];
    if (self) {
        self.context = context;
        self.backgroundColor = WKApp.shared.config.backgroundColor;
        [self setupUI];
        
        
    }
    return self;
}

-(void) setupUI {
    [self addSubnode:self.lineNode];
    [self addSubnode:self.titleNode];
    [self addSubview:self.textNode];
    [self addSubview:self.pinnedListBtn];
    [self addSubview:self.closeBtn];
    
    [self refreshTitle];
    
    self.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressed)];
    [self addGestureRecognizer:tap];
    
    
   
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [weakSelf loadPinnedMessages];
    });
   
    WKChannel *channel = self.context.channel;
    
    [WKSDK.shared.pinnedMessageManager addDelegate:self];
    
    [WKPinnedService.shared requestSyncPinnedMessages:channel]; // 增量同步置顶消息
    
    [WKSDK.shared.chatManager addDelegate:self];
  
}

- (void)dealloc
{
    [WKSDK.shared.pinnedMessageManager removeDelegate:self];
    [WKSDK.shared.chatManager removeDelegate:self];
}

-(void) loadPinnedMessages {
    self.currentIndex = 0;
    WKChannel *channel = self.context.channel;
    // 获取置顶消息
    NSArray *pinnedMessages = [WKSDK.shared.pinnedMessageManager getPinnedMessagesByChannel:channel];
   
    self.pinnedMessages = [NSMutableArray arrayWithArray:pinnedMessages];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 现在最近会话的顶部视图
        [weakSelf changeCurrentIndex];
        [weakSelf.context showConversationTopView:weakSelf.pinnedMessages.count>0 animated:false];
        [weakSelf refreshUI:false];
       
    });
    
}

-(void) pressed {
    if(self.pinnedMessages.count > 1) {
        [self changeCurrentIndex];
        
        [self refreshUI:true];
    }
    
    WKMessage *pinnedMessage = self.pinnedMessages[self.currentIndex];
    [self.context locateMessageCell:pinnedMessage.messageSeq];
    
   
}

-(void) refreshUI:(BOOL)animated {
    if(self.currentIndex >= self.pinnedMessages.count) {
        return;
    }
    
    if(self.pinnedMessages.count>1) {
        self.pinnedListBtn.hidden = NO;
        self.closeBtn.hidden = YES;
    }else {
        self.pinnedListBtn.hidden = YES;
        self.closeBtn.hidden = NO;
    }
    
    [self enqueueTransition:animated];
    
    WKMessage *pinnedMessage = self.pinnedMessages[self.currentIndex];
    
   
    if(pinnedMessage.remoteExtra.isEdit) {
        self.textNode.text = [[pinnedMessage.remoteExtra contentEdit] conversationDigest];
    }else {
        self.textNode.text = [[pinnedMessage content] conversationDigest];
    }
}

-(void) changeCurrentIndex {
    self.currentIndex++;
    if(self.currentIndex>=self.pinnedMessages.count) {
        self.currentIndex = 0;
    }
    
}

-(void) enqueueTransition:(BOOL)animated {
    if(self.pinnedMessages.count == 0) {
        return;
    }
    [self.lineNode updateWithPinnedWithIndex:self.currentIndex count:self.pinnedMessages.count panelHeight:self.lim_height];
    
    
    [self refreshTitle];
    
    // ContainedViewLayoutTransition

    CGFloat textOrgiY = self.titleNode.view.lim_bottom + 2;
    
    self.textNode.lim_top = textOrgiY;
    self.textNode.lim_left = self.titleNode.view.lim_left;
    
    if(animated) {
        UIView *copyView = [self.textNode snapshotViewAfterScreenUpdates:false];
        copyView.frame = self.textNode.frame;
        [self.textNode.superview addSubview:copyView];
        
        CGFloat offset = -10.0f;
        self.textNode.lim_top = textOrgiY -offset;
        self.textNode.alpha = 0.0f;
        copyView.alpha = 1.0f;
        [UIView animateWithDuration:0.2f animations:^{
            copyView.lim_top = textOrgiY + offset ;
            copyView.alpha = 0.0f;
            self.textNode.lim_top = textOrgiY;
            self.textNode.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [copyView removeFromSuperview];
        }];
    }
}

-(void) scrollTo:(uint64_t)messageId {
    for (NSInteger i=0; i<self.pinnedMessages.count; i++) {
        WKMessage *pinnedMessage = self.pinnedMessages[i];
        if(pinnedMessage.messageId == messageId) {
            [self scrllToIndex:i];
            return;
        }
    }
}

-(void) scrllToIndex:(NSInteger)index {
    self.currentIndex = index;
    [self enqueueTransition:YES];
}

-(void) refreshTitle {
   
    [self.titleNode setPinnedTitleWithLeft:30.0f width:self.lim_width - 30.0f title:LLang(@"消息置顶") index:self.currentIndex showNum:self.pinnedMessages.count>1];
}

- (void)layoutSubviews {
    [super layoutSubviews];

}


- (AnimatedNavigationStripeNode *)lineNode {
    if(!_lineNode) {
        _lineNode = [[AnimatedNavigationStripeNode alloc] init];
    }
    return _lineNode;
}

- (AnimatedCountLabelNode *)titleNode {
    if(!_titleNode) {
        _titleNode = [[AnimatedCountLabelNode alloc] init];
        _titleNode.reverseAnimationDirection = true;
    }
    return _titleNode;
}

- (UILabel *)textNode {
    if(!_textNode) {
        _textNode = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.lim_width - 30.0f -60.0f, 24.0f)];
        _textNode.userInteractionEnabled = NO;
        _textNode.font = [WKApp.shared.config appFontOfSize:15.0f];
    }
    return _textNode;
}

- (UIButton *)pinnedListBtn {
    if(!_pinnedListBtn) {
        CGFloat height = 40.0f;
        CGFloat width = 40.0f;
        _pinnedListBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.lim_width - width - 10.0f, self.lim_height/2.0f - height/2.0f, width, height)];
        UIImage *icon = [WKGenerateImageUtils generateTintedImgWithImage:[self imageName:@"Conversation/Index/Pinnedlist"] color:WKApp.shared.config.themeColor backgroundColor:nil];
        [_pinnedListBtn setImage:icon forState:UIControlStateNormal];
        [_pinnedListBtn addTarget:self action:@selector(pinnedListPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pinnedListBtn;
}

-(UIButton*) closeBtn {
    if(!_closeBtn) {
        CGFloat height = 40.0f;
        CGFloat width = 40.0f;
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.lim_width - width - 10.0f, self.lim_height/2.0f - height/2.0f, width, height)];
        UIImage *icon = [WKGenerateImageUtils generateTintedImgWithImage:[self imageName:@"Common/Index/Closelarge"] color:WKApp.shared.config.themeColor backgroundColor:nil];
        [_closeBtn setImage:icon forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

-(void) pinnedListPressed {
    WKPinnedMessageListVC *vc = [WKPinnedMessageListVC new];
    vc.channel = self.context.channel;
    vc.mainConversationContext = self.context;
//    [WKNavigationManager.shared pushViewController:vc animated:YES];
    [WKNavigationManager.shared.topViewController presentViewController:vc animated:YES completion:^{}];
}

-(void) closePressed {
    bool showAlert = false;
    if(self.context.channel.channelType == WK_GROUP) {
        showAlert = [[WKSDK shared].channelManager isManager:self.context.channel memberUID:[WKApp shared].loginInfo.uid];
    }else if(self.context.channel.channelType == WK_PERSON) {
        showAlert = true;
    }
    if(showAlert) {
        [WKAlertUtil alert:LLang(@"您确定要为所有人解除此消息的置顶吗？") buttonsStatement:@[LLang(@"取消"),LLang(@"确认")] chooseBlock:^(NSInteger buttonIdx) {
            if(buttonIdx == 1) {
                [WKPinnedService.shared requestCancelAllPinned:self.context.channel];
            }
        }];
    }else {
        // 只取消本地的置顶
        [WKPinnedService.shared cancelLocalAllPinned:self.context.channel];
    }
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongPinned"];
}

#pragma mark ---- WKPinnedMessageManagerDelegate

- (void)pinnedMessageChange:(WKChannel *)channel {
    if(![channel isEqual:self.context.channel]) {
        return;
    }
    [self loadPinnedMessages];
}

#pragma mark -- WKChatManagerDelegate

- (void)onMessageUpdate:(WKMessage *)message left:(NSInteger)left {
    if(message.channel && [message.channel isEqual:self.context.channel]) {
        BOOL changed = false;
        NSInteger index = -1;
        for (NSInteger i=0; i<self.pinnedMessages.count; i++) {
            WKMessage *pinnedMessage = self.pinnedMessages[i];
            if(message.messageId == pinnedMessage.messageId) {
                if(message.isDeleted || message.remoteExtra.revoke) {
                    [self.pinnedMessages removeObjectAtIndex:i];
                    changed = true;
                    index = i;
                    break;
                }
                [self.pinnedMessages replaceObjectAtIndex:i withObject:message];
                changed = true;
                index = i;
                break;
            }
        }
        if(index!=-1) {
            if(self.currentIndex == index) {
                WKMessage *pinnedMessage = self.pinnedMessages[self.currentIndex];
                if(pinnedMessage.remoteExtra.isEdit) {
                    self.textNode.text = [[pinnedMessage.remoteExtra contentEdit] conversationDigest];
                }else {
                    self.textNode.text = [[pinnedMessage content] conversationDigest];
                }
            }
            
        }
    }
}

@end
