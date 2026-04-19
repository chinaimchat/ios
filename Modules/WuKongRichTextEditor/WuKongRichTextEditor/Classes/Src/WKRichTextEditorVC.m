//
//  WKRichTextEditorVC.m
//  WuKongAdvanced
//
//  Created by tt on 2022/7/20.
//

#import "WKRichTextEditorVC.h"
#import "WKZSSToolbar.h"
#import "WKImageAttachment.h"
#import "WKRichTextContent.h"

#define ItemBold @"bold"
#define ItemItalic @"italic"
#define ItemUnderline @"underline"
#define ItemStrikethrough @"strikethrough"

#define italicValue 0.1f // 斜体强度

@interface WKRichTextEditorVC ()<UITextViewDelegate>

@property(nonatomic,strong) WKInputMentionCache *mentionCache;
@property(nonatomic,strong) WKZSSToolbar *zsstoolbar;

@property(nonatomic,strong) UIView *headerView;

@property(nonatomic,strong) UIButton *closeBtn;

@property(nonatomic,strong) UITextView *editorView;

@property(nonatomic,strong) NSMutableArray *editorItemsEnabled;

@property(nonatomic,assign) BOOL mentionStart; // 是否开始@

@end

@implementation WKRichTextEditorVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.editorView];
    
    self.view.backgroundColor = [WKApp shared].config.backgroundColor;
//
    self.zsstoolbar = [[WKZSSToolbar alloc] initWithContext:self channel:self.channel];
//    [self setToolbar:self.zsstoolbar];
    [self.view addSubview:self.zsstoolbar];
    __weak typeof(self) weakSelf = self;
    self.zsstoolbar.onSend = ^{
        [weakSelf send];
    };
    
    [self.editorView becomeFirstResponder];
}

-(void) send {
    NSAttributedString *content = self.editorView.attributedText;
    
    NSMutableArray<WKMessageEntity*> *items = [NSMutableArray array];
    [content enumerateAttributesInRange:NSMakeRange(0, content.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {

        
        [attrs enumerateKeysAndObjectsUsingBlock:^(NSAttributedStringKey  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            WKMessageEntity *attr = [WKMessageEntity new];
            attr.range = range;
            BOOL exist = false;
            if([key isEqualToString:NSFontAttributeName]) {
                UIFont *font = (UIFont*)obj;
                
                if([font.fontName isEqualToString:[self fontBold].fontName]) {
                    attr.type = WKBoldRichTextStyle;
                    exist = true;
                }
            }else if([key isEqualToString:NSForegroundColorAttributeName]) {
                UIColor *color = (UIColor*)obj;
                if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelRGB) {
                    attr.type = WKColorRichTextStyle;
                    attr.value = [color toHexRGB];
                    exist = true;
                }
            }else if([key isEqualToString:NSAttachmentAttributeName]) {
                exist = true;
                WKImageAttachment *imgAttachment = (WKImageAttachment*)obj;
                attr.type = WKImageRichTextStyle;
                attr.value = @{
                    @"url": imgAttachment.url?:@"",
                    @"width": @([NSString stringWithFormat:@"%0.0f",imgAttachment.image.size.width].intValue),
                    @"height": @([NSString stringWithFormat:@"%0.0f",imgAttachment.image.size.height].intValue),
                };
            }else if([key isEqualToString:NSUnderlineStyleAttributeName]) {
                attr.type = WKUnderlineRichTextStyle;
                exist = true;
            }else if([key isEqualToString:NSObliquenessAttributeName]) {
                attr.type = WKItalicRichTextStyle;
                exist = true;
            }else if([key isEqualToString:NSStrikethroughStyleAttributeName]) {
                attr.type = WKStrikethroughRichTextStyle;
                exist = true;
            }
            if(exist) {
                [items addObject:attr];
            }
            
        }];
    }];
    
    NSArray<WKMessageEntity*> *baseEntities = [self.context entities:self.editorView.text mentionCache:self.mentionCache];
    
    if(baseEntities && baseEntities.count>0) {
        [items addObjectsFromArray:baseEntities];
    }
   
    [self dismissViewControllerAnimated:YES completion:^{
        WKRichTextContent *richTextContent = [[WKRichTextContent alloc] initWithContent:self.editorView.text entities:items];
        richTextContent.mentionedInfo = [self.context mentionedInfo:self.editorView.text mentionCache:self.mentionCache];
        [self.mentionCache clean];

        [self.context sendMessage:richTextContent];
    }]; // 需要放在sendMessage前面
    
    
    
   
}

-(void) setEditorContentHeight:(CGFloat)height {
    CGRect editorFrame = self.editorView.frame;
    editorFrame.size.height = height - self.headerView.lim_height;
    self.editorView.frame = editorFrame;
    
}



- (UITextView *)editorView {
    if(!_editorView) {
        _editorView = [[UITextView alloc] initWithFrame:CGRectMake(0.0f, self.headerView.lim_bottom, self.view.lim_width, 0.0f)];
        [_editorView setFont:[WKApp.shared.config appFontOfSize:15.0f]];
        _editorView.delegate = self;
    }
    return _editorView;
}


-(void) showMentionUsers {
    NSMutableArray<WKContactsSelect*> *contactsSelects = [NSMutableArray array];
    NSArray *members =  [WKSDK.shared.channelManager getMembersWithChannel:self.channel];
    for (WKChannelMember *member in members) {
        if([member.memberUid isEqualToString:[WKApp shared].loginInfo.uid]) { // 排除自己
            continue;
        }
        [contactsSelects addObject:[WKModelConvert toContactsSelect:member]];
    }
    __weak typeof(self) weakSelf = self;
   UIViewController *ctrl = [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT param:@{@"mention_all":@(true),@"no_push":@(true),@"on_finished":^(NSArray<NSString*>*uids){
        NSMutableArray *newUIDs = [NSMutableArray array];
        for (NSString *uid in uids) {
            if(![uid isEqualToString:@"all"]) {
                [newUIDs addObject:uid];
            }
        }
       
       [weakSelf dismissViewControllerAnimated:YES completion:nil];
        
        NSArray<WKChannelMember*> *mentionMembers = [[WKChannelMemberDB shared] getMembersWithChannel:weakSelf.channel uids:newUIDs];
        NSMutableDictionary *memberDict = [NSMutableDictionary dictionary];
        if(mentionMembers) {
            for (WKChannelMember *mentionMember in mentionMembers) {
                memberDict[mentionMember.memberUid] = mentionMember;
            }
        }
       NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
//       [self deleteData]; // 删除@
        for (NSString *uid in uids) {
            NSString *displayName = @"";
            if(uid && [uid isEqualToString:@"all"]) {
                displayName = LLangW(@"所有人", weakSelf);
            }else{
                WKChannelMember *mentionMember  = memberDict[uid];
                if(mentionMember) {
                    displayName = mentionMember.memberName;
                }
            }
            WKInputMentionItem *item = [[WKInputMentionItem alloc] init];
            item.uid  = uid;
            item.name = displayName;
            
            [weakSelf.mentionCache addMentionItem:item];
            
            [str appendString:item.name];
            [str appendString:WKInputAtEndChar];
            if (![uids.lastObject isEqualToString:item.uid]) {
                [str appendString:WKInputAtStartChar];
            }
        }
       [weakSelf insertText:str];
//       [weakSelf insertHTML:str];
//        [weakSelf.input inputInsertText:str];
       
      //  [weakSelf.input becomeFirstResponder];
        
    },@"data":contactsSelects,@"mode":@"single",@"title":LLang(@"选择提醒的人")}];
    
    [self presentViewController:ctrl animated:YES completion:nil];
}

- (WKInputMentionCache *)mentionCache {
    if(!_mentionCache) {
        _mentionCache = [WKInputMentionCache new];
    }
    return _mentionCache;
}

- (UIView *)headerView {
    if(!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.lim_width, 40.0f)];
        _headerView.backgroundColor = [UIColor clearColor];
        
        [_headerView addSubview:self.closeBtn];
        self.closeBtn.lim_left = _headerView.lim_width - self.closeBtn.lim_width - 15.0f;
        self.closeBtn.lim_centerY_parent = _headerView;
    }
    return _headerView;
}

- (UIButton *)closeBtn {
    if(!_closeBtn) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24.0f, 24.0f)];
        [_closeBtn setImage:[self imageName:@"Close"] forState:UIControlStateNormal];
        [_closeBtn lim_addEventHandler:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}
- (NSMutableArray *)editorItemsEnabled {
    if(!_editorItemsEnabled) {
        _editorItemsEnabled = [NSMutableArray array];
    }
    return _editorItemsEnabled;
}


- (void)updateToolBar {
//    [super updateToolBarWithButtonName:name];
    [self.zsstoolbar updateToolBarTab];
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRichTextEditor"];
}

-(UIFont*) fontBold {
    return [WKApp.shared.config appFontOfSizeMedium:15.0f];
}

-(UIFont*) fontNormal {
    return [WKApp.shared.config appFontOfSize:15.0f];
}

// 是否提及
-(BOOL) isMention:(NSString*)text {
    return [text isEqualToString:WKInputAtStartChar];
}

-(void) triggerMentionStartIfNeed {
    if(self.mentionStart) {
        return;
    }
    self.mentionStart = true;
    [self showMentionUsers];
    
}
-(void) triggerMentionEndIfNeed {
    if(!self.mentionStart) {
        return;
    }
    self.mentionStart = false;
    
    
   
}

// 是否删除提及
- (NSRange)delRangeForMention {
    NSRange range = [self rangeForPrefix:WKInputAtStartChar suffix:WKInputAtEndChar];
    return range;
}

- (NSRange)rangeForPrefix:(NSString *)prefix suffix:(NSString *)suffix
{
    NSString *text = self.editorView.text;
    NSRange range = [self inputSelectedRange];
    NSString *selectedText = range.length ? [text substringWithRange:range] : text;
    NSInteger endLocation = range.location;
    if (endLocation <= 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger index = -1;
    if ([selectedText hasSuffix:suffix]) {
        //往前搜最多20个字符，一般来讲是够了...
        NSInteger p = 20;
        for (NSInteger i = endLocation; i >= endLocation - p && i-1 >= 0 ; i--)
        {
            NSRange subRange = NSMakeRange(i - 1, 1);
            NSString *subString = [text substringWithRange:subRange];
            if ([subString compare:prefix] == NSOrderedSame)
            {
                index = i - 1;
                break;
            }
        }
    }
    return index == -1? NSMakeRange(endLocation - 1, 1) : NSMakeRange(index, endLocation - index);
}

-(NSRange) inputSelectedRange{
    
    return self.editorView.selectedRange;
}
-(void) inputDeleteText:(NSRange)range{
    
    [self deleteText:range];
    [self handleTextViewContentDidChange];
}


-(void) handleTextViewContentDidChange {
    NSString *text = self.editorView.text;
//    if([text isEqualToString:@""]) {
//        self.sendButton.show = false;
//    }else {
//        self.sendButton.show = true;
//    }
    
    if([text hasSuffix:WKInputAtStartChar]) {
        [self triggerMentionStartIfNeed];
    }
   
    if(![text containsString:WKInputAtStartChar]) {
        [self triggerMentionEndIfNeed];
    }else if(text.length>0){
        if([text hasSuffix:WKInputAtEndChar]) {
            [self triggerMentionEndIfNeed];
        }
    }

    
}
-(void) deleteText:(NSRange)range{
    NSString *text = self.editorView.text;
    if (range.location + range.length <= [text length]
        && range.location != NSNotFound && range.length != 0)
    {
        NSString *newText = [text stringByReplacingCharactersInRange:range withString:@""];
        NSRange newSelectRange = NSMakeRange(range.location, 0);
        [self.editorView setText:newText];
        self.editorView.selectedRange = newSelectRange;
    }
}


#pragma mark -- RichTextEditorContext

-(void) insertImage:(NSString *)path fileURL:(NSURL*)fileURL width:(CGFloat)width height:(CGFloat)height {
    
    [self.editorView insertText:@"\n"];
    
    WKImageAttachment *attachment = [[WKImageAttachment alloc] init];
    attachment.bounds = CGRectMake(0.0f, 0.0f, width, height);
    attachment.image = [UIImage imageWithContentsOfFile:fileURL.path];
    attachment.url = path;
    
    [self.editorView insertText:@"\U0000fffc"]; // 图片占位
    NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
    
    [newAttrStr addAttribute:NSAttachmentAttributeName value:attachment range:NSMakeRange(newAttrStr.length-1, 1)];
    
    self.editorView.attributedText = newAttrStr;
    [self.editorView insertText:@"\n"];
    [self.editorView becomeFirstResponder];
}

- (void)setBold {
    
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
        
        NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
        
        if([self.editorItemsEnabled containsObject:ItemBold]) {
            [newAttrStr addAttributes:@{NSFontAttributeName:[self fontNormal]} range:selectedRange];
            [self.editorItemsEnabled removeObject:ItemBold];
        }else {
            [newAttrStr removeAttribute:NSFontAttributeName range:selectedRange];
            [newAttrStr addAttributes:@{NSFontAttributeName:[self fontBold]} range:selectedRange];
            if(![self.editorItemsEnabled containsObject:ItemBold]) {
                [self.editorItemsEnabled addObject:ItemBold];
            }
        }
        self.editorView.attributedText = newAttrStr;
        self.editorView.selectedRange = selectedRange;
        [self updateToolBar];
        return;
    }
    
    NSDictionary *typingAttributes =  self.editorView.typingAttributes;
    NSMutableDictionary *newTypingAttributes = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
    UIFont *existFont = typingAttributes[NSFontAttributeName];
     if(existFont && [existFont.fontName isEqualToString:[self fontBold].fontName]) { // 取消加粗
         newTypingAttributes[NSFontAttributeName] = [self fontNormal];
         [self.editorItemsEnabled removeObject:ItemBold];
     }else { // 加粗
         newTypingAttributes[NSFontAttributeName] = [self fontBold];
         if(![self.editorItemsEnabled containsObject:ItemBold]) {
             [self.editorItemsEnabled addObject:ItemBold];
         }
         
     }
    self.editorView.typingAttributes = newTypingAttributes;
    
    [self updateToolBar];
}

- (void)setItalic {
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
        
        NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
        
        if([self.editorItemsEnabled containsObject:ItemItalic]) {
            [newAttrStr removeAttribute:NSObliquenessAttributeName range:selectedRange];
            [self.editorItemsEnabled removeObject:ItemItalic];
        }else {
            [newAttrStr removeAttribute:NSObliquenessAttributeName range:selectedRange];
            [newAttrStr addAttributes:@{NSObliquenessAttributeName:@(italicValue)} range:selectedRange];
            if(![self.editorItemsEnabled containsObject:ItemItalic]) {
                [self.editorItemsEnabled addObject:ItemItalic];
            }
        }
        self.editorView.attributedText = newAttrStr;
        self.editorView.selectedRange = selectedRange;
        [self updateToolBar];
        return;
    }
    
    NSDictionary *typingAttributes =  self.editorView.typingAttributes;
    NSMutableDictionary *newTypingAttributes = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
    NSNumber *existItalic = typingAttributes[NSObliquenessAttributeName];
     if(existItalic) { // 取消
         [newTypingAttributes removeObjectForKey:NSObliquenessAttributeName];
         [self.editorItemsEnabled removeObject:ItemItalic];
     }else { // 增加
         newTypingAttributes[NSObliquenessAttributeName] = @(italicValue);
         if(![self.editorItemsEnabled containsObject:ItemItalic]) {
             [self.editorItemsEnabled addObject:ItemItalic];
         }
         
     }
    self.editorView.typingAttributes = newTypingAttributes;
    
    [self updateToolBar];
}

- (void)setUnderline {
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
        
        NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
        
        if([self.editorItemsEnabled containsObject:ItemUnderline]) {
            [newAttrStr removeAttribute:NSUnderlineStyleAttributeName range:selectedRange];
            [self.editorItemsEnabled removeObject:ItemUnderline];
        }else {
            [newAttrStr removeAttribute:NSUnderlineStyleAttributeName range:selectedRange];
            [newAttrStr addAttributes:@{NSUnderlineStyleAttributeName:@1} range:selectedRange];
            if(![self.editorItemsEnabled containsObject:ItemUnderline]) {
                [self.editorItemsEnabled addObject:ItemUnderline];
            }
        }
        self.editorView.attributedText = newAttrStr;
        self.editorView.selectedRange = selectedRange;
        [self updateToolBar];
        return;
    }
    
    NSDictionary *typingAttributes =  self.editorView.typingAttributes;
    NSMutableDictionary *newTypingAttributes = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
    NSNumber *exist = typingAttributes[NSUnderlineStyleAttributeName];
     if(exist) { // 取消
         [newTypingAttributes removeObjectForKey:NSUnderlineStyleAttributeName];
         [self.editorItemsEnabled removeObject:ItemUnderline];
     }else { // 增加
         newTypingAttributes[NSUnderlineStyleAttributeName] = @1;
         if(![self.editorItemsEnabled containsObject:ItemUnderline]) {
             [self.editorItemsEnabled addObject:ItemUnderline];
         }
         
     }
    self.editorView.typingAttributes = newTypingAttributes;
    
    [self updateToolBar];
}

- (void)setStrikethrough {
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
        
        NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
        
        if([self.editorItemsEnabled containsObject:ItemStrikethrough]) {
            [newAttrStr removeAttribute:NSStrikethroughStyleAttributeName range:selectedRange];
            [self.editorItemsEnabled removeObject:ItemStrikethrough];
        }else {
            [newAttrStr removeAttribute:NSStrikethroughStyleAttributeName range:selectedRange];
            [newAttrStr addAttributes:@{NSStrikethroughStyleAttributeName:@1} range:selectedRange];
            if(![self.editorItemsEnabled containsObject:ItemStrikethrough]) {
                [self.editorItemsEnabled addObject:ItemStrikethrough];
            }
        }
        self.editorView.attributedText = newAttrStr;
        self.editorView.selectedRange = selectedRange;
        [self updateToolBar];
        return;
    }
    
    NSDictionary *typingAttributes =  self.editorView.typingAttributes;
    NSMutableDictionary *newTypingAttributes = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
    NSNumber *exist = typingAttributes[NSStrikethroughStyleAttributeName];
     if(exist) { // 取消
         [newTypingAttributes removeObjectForKey:NSStrikethroughStyleAttributeName];
         [self.editorItemsEnabled removeObject:ItemStrikethrough];
     }else { // 增加
         newTypingAttributes[NSStrikethroughStyleAttributeName] = @1;
         if(![self.editorItemsEnabled containsObject:ItemStrikethrough]) {
             [self.editorItemsEnabled addObject:ItemStrikethrough];
         }
         
     }
    self.editorView.typingAttributes = newTypingAttributes;
    
    [self updateToolBar];
}

- (void)insertText:(NSString *)text {
    [self.editorView insertText:text];
}

- (void)dismissKeyboard {
    [self.editorView endEditing:YES];
    
    NSAttributedString *attrStr = self.editorView.attributedText;
    NSLog(@"attrStr---->%@",attrStr);
}

-(void) setTextColor:(UIColor * __nullable)color {
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
        NSMutableAttributedString *newAttrStr  = [[NSMutableAttributedString alloc] initWithAttributedString:self.editorView.attributedText];
        [newAttrStr removeAttribute:NSForegroundColorAttributeName range:selectedRange];
        if(color) {
            [newAttrStr addAttribute:NSForegroundColorAttributeName value:color range:selectedRange];
        }else {
            [newAttrStr removeAttribute:NSForegroundColorAttributeName range:selectedRange];
        }
        
        self.editorView.attributedText = newAttrStr;
        self.editorView.selectedRange = selectedRange;
        return;
    }
    
    NSDictionary *typingAttributes =  self.editorView.typingAttributes;
    NSMutableDictionary *newTypingAttributes = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
    if(color) {
        newTypingAttributes[NSForegroundColorAttributeName] = color;
    }else {
        [newTypingAttributes removeObjectForKey:NSForegroundColorAttributeName];
    }
    
    self.editorView.typingAttributes = newTypingAttributes;
}

#pragma mark -- UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView {
    NSLog(@"textViewDidChangeSelection--->%@",NSStringFromRange(textView.selectedRange));
    
    NSRange selectedRange = self.editorView.selectedRange;
    if(selectedRange.length > 0) {
    
        UIFont *existFont = [self.editorView.attributedText attribute:NSFontAttributeName atIndex:selectedRange.location longestEffectiveRange:nil inRange:selectedRange];
        if(existFont && [existFont.fontName isEqualToString:[self fontBold].fontName]) { // 加粗
            if(![self.editorItemsEnabled containsObject:ItemBold]) {
                [self.editorItemsEnabled addObject:ItemBold];
            }
        }else { // 取消加粗
            [self.editorItemsEnabled removeObject:ItemBold];
        }
        [self updateToolBar];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([self isMention:text]) { // @功能
        [self triggerMentionStartIfNeed];
        return YES;
    } else  if ([text isEqualToString:@""] && range.length == 1 ) { // 删除
        NSString *willDeleteStr =  [self.editorView.text substringWithRange:range];
        if([willDeleteStr isEqualToString:WKInputAtStartChar]) { /// @被删除了 说明@结束了
            [self triggerMentionEndIfNeed];
            return YES;
        }
        NSRange rangeForMention = [self delRangeForMention];
        if(rangeForMention.length>1) {
            [self triggerMentionEndIfNeed];
        
            [self inputDeleteText:rangeForMention];
            return NO;
        }
    }
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView {
    NSString *text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
     if([text isEqualToString:@""]) {
         self.zsstoolbar.sendDisable = true;
     }else {
         self.zsstoolbar.sendDisable = false;
     }
    [self handleTextViewContentDidChange];
   
}


@end

