//
//  WKPinnedMessageListVC.m
//  WuKongPinned
//
//  Created by tt on 2024/5/23.
//

#import "WKPinnedMessageListVC.h"
#import "WKPinnedMessageDataProvider.h"
#import "WKPinnedMessageContext.h"
#import "WKPinnedService.h"
@interface WKPinnedMessageListVC ()


@property(nonatomic,strong) WKPinnedMessageContext *conversationContext;

@property(nonatomic,strong) UIImageView *backgroundView;

@property(nonatomic,strong) WKNavigationBar *navigationBarInner;
@property(nonatomic,strong) UILabel *titleLabelInner;

@property(nonatomic,strong) UIButton *closeBtn;

@property(nonatomic,strong) UIView *bottomView;
@property(nonatomic,strong) UIButton *cancelAllPinned; // 取消所有置顶

@end

@implementation WKPinnedMessageListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.backgroundView];
    
    [self.view addSubview:self.messageListView];
    
    [self.view addSubview:self.bottomView];
    
    [self.messageListView viewDidLoad];
    
    [self setupChatBackground];
    
    self.navigationBar.title = [NSString stringWithFormat:LLang(@"%ld 条置顶消息"),self.messageListView.dataProvider.messageCount];
    self.navigationBar.titleLabel.lim_centerY_parent = self.navigationBar;
    [self.view bringSubviewToFront:self.navigationBar]; // 将导航栏放到最顶层
    
    [self.navigationBar addSubview:self.closeBtn];
    
}

- (WKNavigationBar *)navigationBar {
    if(!_navigationBarInner) {
        _navigationBarInner = [[WKNavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f,WKScreenWidth, 60.0f)];
        [_navigationBarInner setBackgroundColor:[WKApp shared].config.navBackgroudColor];
        [WKApp.shared.config setThemeStyleNavigation:_navigationBarInner];
    }
    return _navigationBarInner;
}

- (UILabel *)titleLabel {
    if(!_titleLabelInner) {
        _titleLabelInner = [[UILabel alloc] init];
        _titleLabelInner.textAlignment = NSTextAlignmentCenter;
        _titleLabelInner.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [_titleLabelInner setTextColor:[WKApp shared].config.navBarTitleColor];
    
        _titleLabelInner.lim_top =0.0f;
        [_titleLabelInner setFont:[[WKApp shared].config appFontOfSizeMedium:17.0f]];
    }
    return _titleLabelInner;
}

- (UIButton *)closeBtn {
    if(!_closeBtn) {
        _closeBtn = [[UIButton alloc] init];
        [_closeBtn setTitle:LLang(@"关闭") forState:UIControlStateNormal];
        [_closeBtn setTitleColor:WKApp.shared.config.themeColor forState:UIControlStateNormal];
        [_closeBtn.titleLabel setFont:[WKApp.shared.config appFontOfSizeMedium:15.0f]];
        [_closeBtn sizeToFit];
        
        _closeBtn.lim_centerY_parent = self.navigationBar;
        _closeBtn.lim_left = 20.0f;
        
        [_closeBtn addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

-(void) closePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.messageListView viewWillDisappear];
}

- (WKPinnedMessageContext *)conversationContext {
    if(!_conversationContext) {
        _conversationContext = [[WKPinnedMessageContext alloc] initWithPinnedMessageListVC:self];
    }
    return _conversationContext;
}

- (WKMessageListView *)messageListView {
    if(!_messageListView) {
        CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
        CGFloat bottomSafe = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        CGFloat y = self.view.lim_height-self.navigationBar.lim_bottom - self.bottomView.lim_height - statusFrame.size.height;
        if(bottomSafe == 0) {
            y = self.view.lim_height-self.navigationBar.lim_bottom - self.bottomView.lim_height - statusFrame.size.height*2;
        }
        _messageListView = [[WKMessageListView alloc] initWithFrame:CGRectMake(0.0f,self.navigationBar.lim_bottom,self.view.lim_width, y)];
        _messageListView.channel = self.channel;
        _messageListView.showNavigateToMessage = true;
        _messageListView.dataProvider = [[WKPinnedMessageDataProvider alloc] initWithChannel:self.channel conversationContext:self.conversationContext];
    }
    return _messageListView;
}

- (UIImageView *)backgroundView {
    if(!_backgroundView) {
        _backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _backgroundView.clipsToBounds = YES;
        _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backgroundView;
}

- (UIView *)bottomView {
    if(!_bottomView) {
        CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
        CGFloat bottomSafe = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        CGFloat height = 50.0f + bottomSafe;
        CGFloat y  = 0;
        if(bottomSafe >0) {
            y = self.view.lim_height - height - statusFrame.size.height;
        }else {
            y = self.view.lim_height - height - statusFrame.size.height - 20.0f;
        }
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y, self.view.lim_width, height)];
        _bottomView.backgroundColor = WKApp.shared.config.navBackgroudColor;
        [_bottomView addSubview:self.cancelAllPinned];
        
        self.cancelAllPinned.lim_top = (height-bottomSafe)/2.0f - self.cancelAllPinned.lim_height/2.0f;
        self.cancelAllPinned.lim_centerX_parent = self.bottomView;
    }
    return _bottomView;
}


- (UIButton *)cancelAllPinned {
    if(!_cancelAllPinned) {
        _cancelAllPinned = [[UIButton alloc] init];
        [_cancelAllPinned setTitleColor:[WKApp shared].config.themeColor forState:UIControlStateNormal];
        [_cancelAllPinned.titleLabel setFont:[[WKApp shared].config appFontOfSizeMedium:15.0f]];
        [_cancelAllPinned setTitle:LLang(@"取消所有置顶消息") forState:UIControlStateNormal];
        [_cancelAllPinned sizeToFit];
        
        [_cancelAllPinned addTarget:self action:@selector(cancelAllPinnedPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelAllPinned;
}


-(void) cancelAllPinnedPressed {
    
    bool showAlert = false;
    if(self.channel.channelType == WK_GROUP) {
        showAlert = [[WKSDK shared].channelManager isManager:self.channel memberUID:[WKApp shared].loginInfo.uid];
    }else if(self.channel.channelType == WK_PERSON) {
        showAlert = true;
    }
   
    if(showAlert) {
        [WKAlertUtil alert:LLang(@"您确定要为所有人解除此消息的置顶吗？") targetVC:self buttonsStatement:@[LLang(@"取消"),LLang(@"确认")] chooseBlock:^(NSInteger buttonIdx) {
            if(buttonIdx == 1) {
                [WKPinnedService.shared requestCancelAllPinned:self.channel].then(^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }).catch(^(NSError *err){
                    [self.view showHUDWithHide:err.domain];
                });
            }
        }];
    }else {
        // 只取消本地的置顶
        [WKPinnedService.shared cancelLocalAllPinned:self.channel];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
   
}




-(void) setChatBackgroud:(UIImage*)img {
//    self.view.layer.contents = (id)img.CGImage;
    self.backgroundView.image = img;
}

-(BOOL) hasSetChatBackgroud {
    if(self.view.layer.contents) {
        return true;
    }
    return false;
}

-(void) setupChatBackground {
    if([self hasSetChatBackgroud]) {
        return;
    }
    [self updateChatBackground];
   
}

-(void) updateChatBackground {
    BOOL existChannelBg = [WKThemeUtil existChatBackground:self.channel];
    if(existChannelBg) {
       NSData *channelBgData = [WKThemeUtil getChatBackground:self.channel style:WKApp.shared.config.style];
        if(channelBgData) {
            [self setChatBackgroud:[UIImage imageWithData:channelBgData]];
            return;
        }
    }
    
    BOOL existDefaultBg = [WKThemeUtil existDefaultbackground];
    if(existDefaultBg) {
        NSData *defaultBgData = [WKThemeUtil getDefaultBackground:WKApp.shared.config.style];
         if(defaultBgData) {
             [self setChatBackgroud:[UIImage imageWithData:defaultBgData]];
             return;
         }
    }
    
    [self setChatBackgroud:[self imageName:@"Conversation/Index/ChatBg"]];
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongPinned"];
}

@end
