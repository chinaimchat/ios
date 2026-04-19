//
//  WKZSSToolbar.m
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/20.
//

#import "WKZSSToolbar.h"
#import "WKFontColorPicker.h"
#import "WKPhotoBrowser.h"

#define toolbarHeight 44.0f

@interface WKZSSToolbar ()

@property(nonatomic,weak) id<WKRichTextEditorContext> context;

@property(nonatomic,strong) WKChannel *channel;
 
@property(nonatomic,strong) UIView *toolbarHolder;
@property(nonatomic,strong) UIScrollView *toolbarScroll;
@property(nonatomic,strong) UIView *toolbarScrollContainer;

@property(nonatomic,strong) UIView *hideKeyboardItem;

@property(nonatomic,strong) UIButton *sendBtn;

@property(nonatomic,strong) UIView *panelView;

@property(nonatomic,assign) BOOL showEmojiPanel; // 是否显示emoji面板

@property(nonatomic,assign) BOOL keyboardShow; // 键盘是否显示
@property(nonatomic,assign) CGFloat keyboardHeight; // 键盘高度

@property(nonatomic,strong) WKEmojiContentView *emojiContentView;

@property(nonatomic,strong) WKFontColorPicker *fontColorPicker;

@property(nonatomic,strong) WKZSSToolbarItem *fontColorToolbarItem;


@end

@implementation WKZSSToolbar

-(instancetype) initWithContext:(id<WKRichTextEditorContext>)context channel:(WKChannel*)channel{
    self = [super init];
    if (self) {
        self.context = context;
        self.channel = channel;
        CGFloat bottomSafe = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        self.frame = CGRectMake(0.0f, WKScreenHeight - bottomSafe, WKScreenWidth, 300.0f);
        self.backgroundColor = [WKApp.shared.config cellBackgroundColor];
        [self addSubview:self.toolbarHolder];
        
        [self.toolbarHolder addSubview:self.hideKeyboardItem];
        [self.toolbarHolder addSubview:self.toolbarScroll];
        [self.toolbarHolder addSubview:self.sendBtn];
        
        [self.toolbarScroll addSubview:self.toolbarScrollContainer];
        
        [self setupItems];
        
        [self addSubview:self.panelView];
        [self.panelView addSubview:self.emojiContentView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillChangeFrameNotification object:nil];
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
    self.sendBtn.lim_left = self.lim_width - self.sendBtn.lim_width - 10.0f;
    self.sendBtn.lim_centerY_parent = self.toolbarHolder;
    
    self.toolbarScroll.lim_left = self.hideKeyboardItem.lim_right;
    self.toolbarScroll.lim_width = self.sendBtn.lim_left - self.hideKeyboardItem.lim_right;
    self.toolbarScroll.lim_height = toolbarHeight;
    
    self.toolbarScrollContainer.lim_height = toolbarHeight;
    
    NSArray<UIView*> *subviews = self.toolbarScrollContainer.subviews;
    UIView *preView;
    for (UIView *v in subviews) {
        v.lim_left = 0.0f;
        if(preView) {
            v.lim_centerY_parent = self.toolbarHolder;
            v.lim_left = preView.lim_right;
        }
        preView = v;
    }
    if(preView) {
        self.toolbarScrollContainer.lim_width = preView.lim_right;
        [self.toolbarScroll setContentSize:CGSizeMake(self.toolbarScrollContainer.lim_width, toolbarHeight)];
    }
    
    self.panelView.lim_width = self.lim_width;
    self.panelView.lim_height = self.lim_height - self.toolbarHolder.lim_height;
    self.panelView.lim_top = self.toolbarHolder.lim_bottom;
    
    self.emojiContentView.lim_size = self.panelView.lim_size;
   
    if(self.keyboardHeight>0) {
        self.lim_top = self.superview.lim_height - self.keyboardHeight - toolbarHeight;
    }else {
        if(self.showEmojiPanel) {
            self.lim_top = self.superview.lim_height - self.lim_height - self.keyboardHeight - toolbarHeight;
        }else {
            CGFloat bottomSafe = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
            self.lim_top = self.superview.lim_height - self.keyboardHeight - toolbarHeight - bottomSafe;
        }
    }
    [self.context setEditorContentHeight:self.lim_top];
}


-(void) keyboardWillShowOrHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIViewAnimationOptions animationOptions = curve << 16;
    
    self.keyboardHeight = keyboardEnd.size.height;
    
    if (keyboardEnd.origin.y < [[UIScreen mainScreen] bounds].size.height) {
        self.keyboardShow = true;
        self.showEmojiPanel = false;
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            [self layoutSubviews];
            
        } completion:nil];
    }else {
        self.keyboardShow = false;
        self.keyboardHeight = 0.0f;
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            [self layoutSubviews];
        } completion:nil];
    }
}


-(void) setupItems {
    
    WKZSSToolbarItem *item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarEmoji"] onClick:^(WKZSSToolbarItem *item){
        self.showEmojiPanel = !self.showEmojiPanel;
        if(self.keyboardHeight>0) {
            [self.context dismissKeyboard];
        }else {
            [UIView animateWithDuration:0.12f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self layoutSubviews];
            } completion:nil];
        }
        
    }];
    item.itemName = @"emoji";
    [self.toolbarScrollContainer addSubview:item];
    
    if(self.channel.channelType == WK_GROUP) {
        item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarAt"] onClick:^(WKZSSToolbarItem *item){
            [self.context insertText:@"@"];
        }];
        item.itemName = @"@";
        [self.toolbarScrollContainer addSubview:item];
    }
   
    
    
    item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarBold"] onClick:^(WKZSSToolbarItem *item){
        [self.context setBold];
    }];
    item.itemName = @"bold";
    [self.toolbarScrollContainer addSubview:item];
    
    self.fontColorToolbarItem = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarFontcolor"] onClick:^(WKZSSToolbarItem *item){
        [self showFontColorPicker:true inView:item];
    }];
    [self.toolbarScrollContainer addSubview:self.fontColorToolbarItem];

    
    __weak typeof(self) weakSelf = self;
    item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarImage"] onClick:^(WKZSSToolbarItem *item){
//        [weakSelf.context insertImageFromDevice];
        [WKPhotoBrowser.shared showPhotoLibraryWithSender:self.lim_viewController selectCompressImageBlock:^(NSArray<NSData *> * _Nonnull images, NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal) {
            NSString *tmpDirectory = NSTemporaryDirectory();
            NSString *filePath = [tmpDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[[NSUUID UUID] UUIDString]]];
            NSData *imgData = images.firstObject;
            if([imgData writeToFile:filePath atomically:YES]) {
               
//                [weakSelf.context insertImage:[NSString stringWithFormat:@"localimages://%@",filePath] alt:@""];
                UIImage *img = [UIImage imageWithData:imgData];
                CGSize size = [UIImage lim_sizeWithImageOriginSize:CGSizeMake(img.size.width, img.size.height) maxLength:250.0f];
                
                [weakSelf uploadImage:filePath complete:^(NSString *path) {
                    [weakSelf.context insertImage:path fileURL:[NSURL fileURLWithPath:filePath] width:size.width height:size.height];
                    
//                    [weakSelf.context focusTextEditor];
                }];
                
              
            }
            
        } allowSelectVideo:NO];
    }];
    [self.toolbarScrollContainer addSubview:item];
    
    item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarUnderline"] onClick:^(WKZSSToolbarItem *item){
        [self.context setUnderline];
    }];
    item.itemName = @"underline";
    [self.toolbarScrollContainer addSubview:item];
    
    item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarItalic"] onClick:^(WKZSSToolbarItem *item){
        [self.context setItalic];
    }];
    item.itemName = @"italic";
    [self.toolbarScrollContainer addSubview:item];
    
    item = [[WKZSSToolbarItem alloc] initWithIcon:[self imageName:@"ToolbarStrikethrough"] onClick:^(WKZSSToolbarItem *item){
        [self.context setStrikethrough];
    }];
    item.itemName = @"strikethrough";
    [self.toolbarScrollContainer addSubview:item];
}

-(void) uploadImage:(NSString*)filePath complete:(void(^)(NSString *path))complete{
    [self.lim_viewController.view showHUD:LLang(@"上传中")];
    __weak typeof(self) weakSelf = self;
    NSString *randomFileName = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
   NSString *path = [NSString stringWithFormat:@"/%d/%@/%@",self.channel.channelType,self.channel.channelId,[NSString stringWithFormat:@"richtext_%@.png",randomFileName]];
    [[WKAPIClient sharedClient] uploadChatFile:path localURL:[NSURL fileURLWithPath:filePath] progress:nil completeCallback:^(id  _Nullable resposeObject, NSError * _Nullable error) {
        [weakSelf.lim_viewController.view hideHud];
        if(error) {
            WKLogError(@"上传失败！->%@",error);
            [weakSelf.lim_viewController.view showHUDWithHide:LLang(@"上传失败！")];
            return;
        }
        
        complete(resposeObject[@"path"]);
    }];
    
}

- (void)setShowEmojiPanel:(BOOL)showEmojiPanel {
    _showEmojiPanel = showEmojiPanel;
    
    [self.emojiContentView removeFromSuperview];
    if(showEmojiPanel) {
        [self.panelView addSubview:self.emojiContentView];
    }
}

-(void) showFontColorPicker:(BOOL) show inView:(UIView*)inView{
    UIView *mainView = self.lim_viewController.view;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, mainView.lim_width, mainView.lim_height)];
    view.tag = 9909;
    [view setBackgroundColor:[UIColor clearColor]];
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFontColorPicker)]];
    [view addSubview:self.fontColorPicker];
    [mainView addSubview:view];
    
    self.fontColorPicker.alpha = 0.0f;
    self.fontColorPicker.layer.transform = CATransform3DMakeScale(0.0f, 0.0f,0.0f);
    [UIView animateWithDuration:0.2f animations:^{
        self.fontColorPicker.alpha = 1.0f;
        self.fontColorPicker.layer.transform = CATransform3DMakeScale(1.0f, 1.0f,1.0f);
    }];

    CGRect destRect = [mainView convertRect:inView.frame fromView:inView.superview];
    
    self.fontColorPicker.lim_top = destRect.origin.y - self.fontColorPicker.lim_height;
    
    self.fontColorPicker.lim_left = destRect.origin.x - (self.fontColorPicker.lim_width/2.0f - inView.lim_width/2.0f);
}

-(void) dismissFontColorPicker {
    UIView *mainView = self.lim_viewController.view;
    UIView *maskView =  [mainView viewWithTag:9909];
    if(maskView) {
        self.fontColorPicker.alpha = 1.0f;
        self.fontColorPicker.layer.transform = CATransform3DMakeScale(1.0f, 1.0f,1.0f);
        [UIView animateWithDuration:0.2f animations:^{
            self.fontColorPicker.alpha = 0.0f;
            self.fontColorPicker.layer.transform = CATransform3DMakeScale(0.0f, 0.0f,0.0f);
        } completion:^(BOOL finished) {
            if(finished) {
                [maskView removeFromSuperview];
            }
        }];
    }
}

- (WKFontColorPicker *)fontColorPicker {
    if(!_fontColorPicker) {
        _fontColorPicker = [[WKFontColorPicker alloc] init];
        
        _fontColorPicker.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _fontColorPicker.layer.cornerRadius = 4.0f;
        _fontColorPicker.layer.shadowOffset = CGSizeMake(-1.0f, 1.0f);
        _fontColorPicker.layer.shadowColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.5f].CGColor;
        _fontColorPicker.layer.shadowOpacity = 0.5f;
        __weak typeof(self) weakSelf = self;
        _fontColorPicker.onSelected = ^(UIColor *  color) {
            weakSelf.fontColorToolbarItem.iconImgView.image = [weakSelf.fontColorToolbarItem.iconImgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if(color) {
                weakSelf.fontColorToolbarItem.iconImgView.tintColor = color;
            }else {
                if(WKApp.shared.config.style == WKSystemStyleDark) {
                    weakSelf.fontColorToolbarItem.iconImgView.tintColor = [UIColor whiteColor];
                }else {
                    weakSelf.fontColorToolbarItem.iconImgView.tintColor = [UIColor blackColor];
                }
            }
            
            [weakSelf dismissFontColorPicker];
            [weakSelf.context setTextColor:color];
        };
    }
    return _fontColorPicker;
}

- (void)updateToolBarTab {
    NSArray *subviews = self.toolbarScrollContainer.subviews;
    if(subviews && subviews.count>0) {
        for (WKZSSToolbarItem *item in subviews) {
            item.selected = false;
            if([[self.context editorItemsEnabled] containsObject:item.itemName]) {
                item.selected = true;
            }
        }
    }
}

- (UIView *)toolbarHolder {
    if(!_toolbarHolder) {
        _toolbarHolder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.lim_width, toolbarHeight)];
    }
    return _toolbarHolder;
}

- (UIScrollView *)toolbarScroll {
    if(!_toolbarScroll) {
        _toolbarScroll = [[UIScrollView alloc] init];
    }
    return _toolbarScroll;
}

- (UIView *)toolbarScrollContainer {
    if(!_toolbarScrollContainer) {
        _toolbarScrollContainer = [[UIView alloc] init];
    }
    return _toolbarScrollContainer;
}

- (UIView *)hideKeyboardItem {
    if(!_hideKeyboardItem) {
        _hideKeyboardItem = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, toolbarHeight)];
        [_hideKeyboardItem addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
        [icon setImage:[self imageName:@"KeyboardDown"]];
        [_hideKeyboardItem addSubview:icon];
        
        icon.lim_centerY_parent = _hideKeyboardItem;
        icon.lim_centerX_parent = _hideKeyboardItem;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 24.0f)];
        lineView.backgroundColor = [WKApp shared].config.lineColor;
        [_hideKeyboardItem addSubview:lineView];
        
        lineView.lim_left = _hideKeyboardItem.lim_width - lineView.lim_width;
        lineView.lim_centerY_parent = _hideKeyboardItem;
        
    }
    return _hideKeyboardItem;
}

- (UIView *)panelView {
    if(!_panelView) {
        _panelView = [[UIView alloc] init];
    }
    return _panelView;
}

-(void) dismissKeyboard {
    self.showEmojiPanel = false;
    if(self.keyboardHeight>0) {
        [self.context dismissKeyboard];
    }else {
        [UIView animateWithDuration:0.12f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutSubviews];
        } completion:nil];
        
    }
   
}

- (UIButton *)sendBtn {
    if(!_sendBtn) {
        _sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 36.0f)];
        [_sendBtn setTitle:LLang(@"发送") forState:UIControlStateNormal];
        [self setSendDisable:YES];
        [[_sendBtn titleLabel] setFont:[[WKApp shared].config appFontOfSize:14.0f]];
        _sendBtn.layer.masksToBounds = YES;
        _sendBtn.layer.cornerRadius = 5.0f;
        __weak typeof(self) weakSelf = self;
        [_sendBtn lim_addEventHandler:^{
            if(weakSelf.onSend) {
                weakSelf.onSend();
            }
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendBtn;
}


- (void)setSendDisable:(BOOL)sendDisable {
    _sendDisable = sendDisable;
    if(sendDisable) {
        [_sendBtn setBackgroundColor:[UIColor grayColor]];
        [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendBtn setEnabled:NO];
    }else {
        _sendBtn.backgroundColor = [WKApp shared].config.themeColor;
        [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendBtn setEnabled:YES];
    }
}

- (WKEmojiContentView *)emojiContentView {
    if(!_emojiContentView) {
        __weak typeof(self) weakSelf = self;
        _emojiContentView = [[WKEmojiContentView alloc] init];
        [_emojiContentView setBackgroundColor:[WKApp shared].config.backgroundColor];
        [_emojiContentView setOnEmoji:^(WKEmotion * _Nonnull emoji) {
            [weakSelf.context insertText:emoji.faceName];
        }];
    }
    return _emojiContentView;
}


-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRichTextEditor"];
}


@end

@interface WKZSSToolbarItem ()

/// 选中态半透明底，不可用 `maskView` 命名（会与 `UIView.maskView` 冲突导致始终为 nil、addSubview 崩溃）。
@property(nonatomic,strong) UIView *selectionOverlayView;

@property(nonatomic,copy) void(^onClick)(WKZSSToolbarItem *item);

@end

@implementation WKZSSToolbarItem

-(instancetype) initWithIcon:(UIImage*)icon onClick:(void(^)(WKZSSToolbarItem *item))onClick{
    self = [super init];
    if(self) {
        
        self.frame = CGRectMake(0.0f, 0.0f, toolbarHeight, toolbarHeight);
        self.onClick = onClick;
        [self.iconImgView setImage:icon];
        
        [self addSubview:self.selectionOverlayView];
        [self addSubview:self.iconImgView];
       
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)]];
    }
    return self;
}

-(void) onTap {
    if(self.onClick) {
        self.onClick(self);
    }
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    self.selectionOverlayView.hidden = !selected;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImgView.lim_centerY_parent = self;
    self.iconImgView.lim_centerX_parent = self;
    
    self.selectionOverlayView.lim_centerY_parent = self;
    self.selectionOverlayView.lim_centerX_parent = self;
}

- (UIImageView *)iconImgView {
    if(!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
    }
    return _iconImgView;
}

- (UIView *)selectionOverlayView {
    if(!_selectionOverlayView) {
        _selectionOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 28.0f, 28.0f)];
        _selectionOverlayView.layer.masksToBounds = YES;
        _selectionOverlayView.layer.cornerRadius = 4.0f;
        _selectionOverlayView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f];
        _selectionOverlayView.hidden = YES;
    }
    return _selectionOverlayView;
}

@end
