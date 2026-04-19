//
//  WKRichTextCell.m
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/28.
//

#import "WKRichTextCell.h"
#import "WKRichTextContent.h"
#import <WuKongBase/WuKongBase-Swift.h>
#import <ContactsUI/CNContactViewController.h>
#import <ContactsUI/CNContactPickerViewController.h>

#define italicValue 0.1f // 斜体强度
@interface WKRichTextCell ()<CNContactViewControllerDelegate,CNContactPickerDelegate>

@property(nonatomic,strong) UILabel *contentLbl;
@property(nonatomic,strong) id selectLinkData;

@end

@implementation WKRichTextCell

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    
    NSMutableAttributedString *attributedStr = [self parseAndCacheTextMessage:model];
    CGSize size =  [self textSize:attributedStr messageModel:model];
    
    CGSize trailingSize = [WKTrailingView size:model];

    CGFloat lastlineWidth = [[self class] textLastlineWidth:attributedStr messageModel:model];

    CGFloat lastLineWithTrailingWidth = lastlineWidth + trailingSize.width + WKTrailingLeft;
    if(lastLineWithTrailingWidth>[WKApp shared].config.messageContentMaxWidth) {
        size.height += WKTimeHeight;
    }else{
        size.width = MAX(size.width, lastLineWithTrailingWidth);
    }
    CGFloat nicknameWidth = 0.0f;
    if([self isShowName:model]) {
        CGSize nicknameSize =  [self getNicknameSize:model];
        nicknameWidth = nicknameSize.width;
    }
    
    return CGSizeMake(MAX(size.width, nicknameWidth), size.height);
    
}

- (void)initUI {
    [super initUI];
    
    [self.messageContentView addSubview:self.contentLbl];

    
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    
    NSMutableAttributedString *attrStr = [[self class] parseAndCacheTextMessage:model];
    if(model.isSend) {
        self.contentLbl.textColor =  [WKApp shared].config.messageSendTextColor;
    }else {
        self.contentLbl.textColor = [WKApp shared].config.messageRecvTextColor;
    }
    
    __weak typeof(self) weakSelf = self;
    [attrStr enumerateAttributesInRange:NSMakeRange(0, attrStr.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        [attrs enumerateKeysAndObjectsUsingBlock:^(NSAttributedStringKey  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if([key isEqualToString:NSAttachmentAttributeName]) {
                if([obj isKindOfClass:[WKRemoteImageAttachment class]]) {
                    WKRemoteImageAttachment *remoteImageAttachment = (WKRemoteImageAttachment*)obj;
                    [remoteImageAttachment startDownload:^(UIImage * _Nonnull img) {
//                        [strongSelf.contentLbl setNeedsDisplay];
//                        [strongSelf.contentLbl layoutSubviews];
                        if(img) {
                            [weakSelf.conversationContext refreshCell:model];
                        }
                        
                    }];
                    
                }
            }else if([key isEqualToString:NSForegroundColorAttributeName]) {
                UIColor *color = (UIColor*)obj;
                if(CGColorEqualToColor(color.CGColor, [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor) || CGColorEqualToColor(color.CGColor, [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f].CGColor) ) {
                    
                    UIColor *newColor;
                    if(model.isSend) {
                        newColor =  [WKApp shared].config.messageSendTextColor;
                    }else {
                        newColor = [WKApp shared].config.messageRecvTextColor;
                    }
                    [attrStr removeAttribute:NSForegroundColorAttributeName range:range];
                    [attrStr addAttribute:NSForegroundColorAttributeName value:newColor range:range];
                }
            }
        }];
    }];
    CGSize size =  [[self class] textSize:attrStr messageModel:model];
    self.contentLbl.attributedText = attrStr;
    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[[self class] getTokens:model]];
    if(attrStr.tokens && attrStr.tokens.count>0) {
        [tokens addObjectsFromArray:attrStr.tokens];
    }
    self.contentLbl.tokens = tokens;
    self.contentLbl.lim_size = size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}
-(void) layoutName {
    WKBubblePostion position = [[self class] bubblePosition:self.messageModel];
    if(!self.nameLbl.hidden) {
        if(position == WKBubblePostionLast || position == WKBubblePostionSingle) {
            self.nameLbl.lim_left =  WK_CONTENT_INSETS.left+WKLastBubbleOffsetSpace;
        }else{
            self.nameLbl.lim_left =  WK_CONTENT_INSETS.left;
        }
        
        self.nameLbl.lim_top =  WK_CONTENT_INSETS.top;
    }
    self.nameLbl.lim_width = self.messageContentView.lim_width;
}

-(void) tapLongTapOrDoubleTapGesture:(TapLongTapOrDoubleTapGestureRecognizerWrap*)recognizer {
    [super tapLongTapOrDoubleTapGesture:recognizer];
    if(recognizer.tapAction == WKTapLongTapOrDoubleTapGestureTap) {
        if([self contentLabelTapAtPoint:recognizer.tapPoint]) {
            CGPoint point = [self.contentLbl convertPoint:recognizer.tapPoint fromView:self.contentView];
//             CGPoint point = [self.textLbl convertPoint:gesture.tapPoint fromView:self.contentView];
            id<WKMatchToken> token = [self.contentLbl matchDidTapAttributedTextInLabelWithPoint:point];
             if(token) {
                 NSLog(@"token--->%@",token);
                 if(token.type == WKatchTokenTypeRemoteImage) {
                     [self didImageClick:token];
                 }else if(token.type == WKatchTokenTypeMetion) {
                     [self didMetionClick:token];
                 }else if(token.type == WKatchTokenTypeLink) {
                     [self didLinkClick:token.text];
                 }else if(token.type == WKatchTokenTypeLink2) {
                     WKLinkToken *linkToken = (WKLinkToken*)token;
                     [self didLinkClick:linkToken.linkText];
                 }
             }
        }
    }
}
-(void) didImageClick:(WKRemoteImageToken*)token {
    __weak typeof(self) weakSelf = self;
    WKImageBrowser *imageBrowser = [[WKImageBrowser alloc] init];
    imageBrowser.toolViewHandlers = @[];
    imageBrowser.webImageMediator = [WKDefaultWebImageMediator new];
    imageBrowser.conversationContext = self.conversationContext;
    imageBrowser.onEditFinish = ^(UIImage *img) {
        WKImageContent *content = [WKImageContent initWithImage:img];
        [weakSelf.conversationContext sendMessage:content];
    };
    
    YBIBImageData *data = [YBIBImageData new];
    data.extraData = @{@"message":self.messageModel};
    data.imageURL = [[WKApp shared] getImageFullUrl:token.url];
    
    imageBrowser.dataSourceArray = @[data];
    [imageBrowser showToView:[WKApp.shared findWindow]];
}

-(void) didMetionClick:(WKMetionToken*)token {
    NSString *atUID = token.uid;
    if(!atUID || [atUID isEqualToString:@""]) {
        return;
    }
    WKChannelMember *member = [[WKSDK shared].channelManager getMember:self.messageModel.channel uid:atUID];
    NSString *vercode = @"";
    if(member) {
        vercode = member.extra[WKChannelExtraKeyVercode];
    }
    [[WKApp shared] invoke:WKPOINT_USER_INFO param:@{
        @"channel": self.messageModel.channel,
        @"uid": atUID,
        @"vercode":vercode?:@"",
    }];
}

-(void) didLinkClick:(NSString*)link {
    if([link containsString:@"."]) { // 网站
        WKWebViewVC *vc = [[WKWebViewVC alloc] init];
        if(![link hasPrefix:@"http"]) {
            link = [NSString stringWithFormat:@"http://%@",link];
        }
        vc.url = [NSURL URLWithString:[link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
       
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    } else {  // 电话
        [self.conversationContext endEditing]; // 结束编辑
        __weak typeof(self) weakSelf = self;
        WKActionSheetView2 *sheetView = [WKActionSheetView2 initWithTip:[NSString stringWithFormat:LLang(@"%@可能是一个电话号码，你可以"),link]];
        [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"呼叫") onClick:^{
            NSMutableString *str = [[NSMutableString alloc]
                     initWithFormat:@"telprompt://%@", link];
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:str]]) {
                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
            } else {
                     [weakSelf showMsg:LLang(@"手机格式不正确！")];
            }
        }]];
        [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"复制号码") onClick:^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:link];
        }]];
        [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"添加到手机通讯录") onClick:^{
            [weakSelf toSaveContacts:link];
        }]];
        [sheetView show];
    }
}

-(void) toSaveContacts:(NSString*)phone {
    __weak typeof(self) weakSelf = self;
    WKActionSheetView2 *sheetView = [WKActionSheetView2 initWithTip:[NSString stringWithFormat:LLang(@"%@可能是一个电话号码，你可以"),phone]];
    [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"创建新联系人") onClick:^{
        [weakSelf saveNewContact:phone];
    }]];
    [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"添加到现有联系人") onClick:^{
        [weakSelf saveExistContact:phone];
    }]];
    [sheetView show];
}

-(void) saveNewContact:(NSString*)phone {
    if (@available(iOS 9.0, *)) {
        CNMutableContact *contact = [[CNMutableContact alloc] init];
        [self saveContacts:phone contact:contact isNew:YES];
        CNContactViewController *vc = [CNContactViewController viewControllerForNewContact:contact];
        vc.delegate = self;
        UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:vc];
        [[WKNavigationManager shared].topViewController presentViewController:navigation animated:YES completion:nil];
    }
}

-(void) saveExistContact:(NSString*)phone {
    if (@available(iOS 9.0, *)) {
        CNContactPickerViewController *controller =
        [[CNContactPickerViewController alloc] init];
        controller.delegate = self;
           [[WKNavigationManager shared].topViewController presentViewController:controller
             animated:YES
           completion:^{

           }];
    }
}

-(void) saveContacts:(NSString*)phone contact:(CNMutableContact*)contact isNew:(BOOL)isNew API_AVAILABLE(ios(9.0)){
    if (@available(iOS 9.0, *)) {
        CNLabeledValue *phoneNumber = [CNLabeledValue
                                              labeledValueWithLabel:CNLabelPhoneNumberMobile
                                              value:[CNPhoneNumber phoneNumberWithStringValue:
                                                     phone]];
        if(isNew) {
                contact.phoneNumbers = @[ phoneNumber ];
           }else{
               if ([contact.phoneNumbers count] > 0) {
                    NSMutableArray *phoneNumbers =
                        [[NSMutableArray alloc] initWithArray:contact.phoneNumbers];
                    [phoneNumbers addObject:phoneNumber];
                    contact.phoneNumbers = phoneNumbers;
                  } else {
                    contact.phoneNumbers = @[ phoneNumber ];
                  }
           }
    }
}

- (void)contactPicker:(CNContactPickerViewController *)picker
     didSelectContact:(CNContact *)contact  API_AVAILABLE(ios(9.0)){
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        CNMutableContact *c = [contact mutableCopy];
        [weakSelf saveContacts:weakSelf.selectLinkData contact:c isNew:YES];
        
        CNContactViewController *controller =
                                      [CNContactViewController
                                          viewControllerForNewContact:c];
        controller.delegate = weakSelf;
        UINavigationController *navigation =
                                      [[UINavigationController alloc]
                                          initWithRootViewController:controller];

                                  [[WKNavigationManager shared].topViewController presentViewController:navigation
                                                        animated:YES
                                                      completion:^{

                                                      }];
    }];
}
- (void)contactViewController:(CNContactViewController *)viewController
       didCompleteWithContact:(nullable CNContact *)contact  API_AVAILABLE(ios(9.0)){
  [viewController dismissViewControllerAnimated:YES completion:nil];
}



-(BOOL) contentLabelTapAtPoint:(CGPoint)point {
    CGRect rectInContentView = [self.contentView convertRect:self.contentLbl.frame fromView:self.contentLbl.superview];
    return CGRectContainsPoint(rectInContentView, point);
}

- (UILabel *)contentLbl {
    if(!_contentLbl) {
        _contentLbl = [[UILabel alloc] init];
        [_contentLbl setFont:[UIFont systemFontOfSize:[WKApp shared].config.messageTextFontSize]];
        _contentLbl.numberOfLines = 0;
        _contentLbl.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _contentLbl;
}



+(NSMutableAttributedString*) parseAndCacheTextMessage:(WKMessageModel*)message {
    static WKMemoryCache *memoryCache;
    if(!memoryCache) {
        memoryCache = [[WKMemoryCache alloc] init];
        memoryCache.maxCacheNum = 500; // TODO: 如果这里设置的过小 滑动会闪屏
    }
    NSString *key = message.clientMsgNo;

//    textContent.content = [NSString stringWithFormat:@"%@-%u",textContent.contentDict[@"content"],message.messageSeq];
    NSMutableAttributedString *attrStr =  [memoryCache getCache:key];
    if(attrStr) {
        return attrStr;
    }
    attrStr = [self getAttributedStr:message];
    if(key) {
        [memoryCache setCache:attrStr forKey:key];
    }
    
   
    return attrStr;
}

// 这里的token主要用于点击
+(NSArray<id<WKMatchToken>>*) getTokens:(WKMessageModel*)messageModel {
    NSMutableArray<id<WKMatchToken>> *tokens = [NSMutableArray array];
    WKRichTextContent *richTextContent =  [self getNewRichTextContent:messageModel];
    NSString *contentStr = richTextContent.content;
    if(richTextContent.entities) {
        @try {
            for (WKMessageEntity *textAttr in richTextContent.entities) {
                 if([textAttr.type isEqualToString:WKImageRichTextStyle]) {
                    WKRemoteImageToken *token = [WKRemoteImageToken new];
                    token.range = textAttr.range;
                    token.text = [contentStr substringWithRange:textAttr.range];
                    NSDictionary *imageDict =  textAttr.value;
                    token.url = [WKApp.shared getImageFullUrl:imageDict[@"url"]?:@""].absoluteString;
                    NSNumber *width = imageDict[@"width"]?:@(0);
                    NSNumber *height = imageDict[@"height"]?:@(0);
                    token.size = CGSizeMake(width.intValue, height.intValue);
                    [tokens addObject:token];
                 } else if([textAttr.type isEqualToString:WKMentionRichTextStyle]) {
                     WKMetionToken *token = [WKMetionToken new];
                     token.range = textAttr.range;
                     token.uid = textAttr.value?:@"";
                     [tokens addObject:token];
                 }else if([textAttr.type isEqualToString:WKLinkRichTextStyle]) {
                     WKLinkToken *token = [WKLinkToken new];
                     token.range = textAttr.range;
                     token.linkText = [contentStr substringWithRange:textAttr.range];
                     [tokens addObject:token];
                 }else if([textAttr.type isEqualToString:WKUnderlineRichTextStyle]) {
                     WKUnderlineToken *token = [WKUnderlineToken new];
                     token.range = textAttr.range;
                     token.text = [contentStr substringWithRange:textAttr.range];
                     [tokens addObject:token];
                 } else if([textAttr.type isEqualToString:WKItalicRichTextStyle]) {
                     WKItalicToken *token = [WKItalicToken new];
                     token.range = textAttr.range;
                     token.text = [contentStr substringWithRange:textAttr.range];
                     [tokens addObject:token];
                 }else if([textAttr.type isEqualToString:WKStrikethroughRichTextStyle]) {
                     WKStrikethroughToken *token = [WKStrikethroughToken new];
                     token.range = textAttr.range;
                     token.text = [contentStr substringWithRange:textAttr.range];
                     [tokens addObject:token];
                 }else if([textAttr.type isEqualToString:WKFontRichTextStyle]) {
                     WKFontToken *token = [WKFontToken new];
                     token.range = textAttr.range;
                     token.text = [contentStr substringWithRange:textAttr.range];
                     if(textAttr.value && [textAttr.value isKindOfClass:[NSString class]]) {
                         token.fontSize = [textAttr.value floatValue];
                     }else if(textAttr.value && [textAttr.value isKindOfClass:[NSNumber class]]) {
                         token.fontSize = [textAttr.value floatValue];
                     }
                     [tokens addObject:token];
                 }
            }
        } @catch (NSException *exception) {
            NSLog(@"解析tokens异常！->%@",exception);
        }
    }
    return tokens;
}

+(WKRichTextContent*) getNewRichTextContent:(WKMessageModel*)messageModel {
    
    return (WKRichTextContent*)messageModel.content;
    
//    NSString *key = @"richTextContent";
//    WKRichTextContent *cacheRichTextContent = messageModel.tmpObject[key];
//    if(cacheRichTextContent) {
//        return cacheRichTextContent;
//    }
//    WKRichTextContent *richTextContent =  (WKRichTextContent*)[messageModel.content copy];
//
//    NSString *content = richTextContent.content;
//
//
//    NSArray<WKRichTextAttr*> *attrs = [richTextContent.attrs sortedArrayUsingComparator:^NSComparisonResult(WKRichTextAttr  *obj1, WKRichTextAttr *obj2) {
//        if(obj2.range.location>obj1.range.location) {
//            return NSOrderedAscending;
//        }
//        if(obj2.range.location<obj1.range.location) {
//            return NSOrderedDescending;
//        }
//
//        return NSOrderedSame;
//    }];
//
//    for (NSInteger i=0; i<attrs.count; i++) {
//        WKRichTextAttr *textAttr = attrs[i];
//        if([textAttr.style isEqualToString:WKMentionRichTextStyle]) {
//            if(textAttr.range.location + textAttr.range.length>content.length) {
//                continue;
//            }
//            NSString *uid = textAttr.value;
//            NSString *oldDisplayName = [content substringWithRange:textAttr.range];
//            NSString *newDisplayName;
//            WKChannelInfo *channelInfo = [WKSDK.shared.channelManager getChannelInfoOfUser:uid];
//            if(channelInfo) {
//                newDisplayName = [NSString stringWithFormat:@"@%@",channelInfo.displayName];
//            }
//            if(newDisplayName && newDisplayName.length!=oldDisplayName.length) {
//                content = [content stringByReplacingCharactersInRange:textAttr.range withString:newDisplayName];
//
//                NSInteger changeLen = newDisplayName.length - textAttr.range.length;
//                textAttr.range = NSMakeRange(textAttr.range.location, newDisplayName.length);
//                for (NSInteger j=i+1; j<attrs.count; j++) {
//                    WKRichTextAttr *afterTextAttr =  attrs[j];
//                    afterTextAttr.range = NSMakeRange(afterTextAttr.range.location + changeLen, afterTextAttr.range.length);
//                }
//            }
//        }
//    }
//    richTextContent.content = content;
//    richTextContent.attrs = attrs;
//    messageModel.tmpObject[key] = richTextContent;
//    return richTextContent;
}

+(NSMutableAttributedString*) getAttributedStr:(WKMessageModel*)messageModel {
    
//    NSArray<id<WKMatchToken>> *tokens =  [self getTokens:messageModel];
//
    WKRichTextContent *richTextContent =  [self getNewRichTextContent:messageModel];
//
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:richTextContent.content];
//    attributedStr.font = [[WKApp shared].config appFontOfSize:[WKApp shared].config.messageTextFontSize];
//
//    [attributedStr lim_render:richTextContent.content tokens:tokens];
//
//    return attributedStr;
    

    UIFont *defaultFont = [UIFont systemFontOfSize:[WKApp shared].config.messageTextFontSize];
    
    [attributedStr addAttribute:NSFontAttributeName value:defaultFont range:NSMakeRange(0, attributedStr.length)];
    if(richTextContent.entities) {
        @try {
            NSMutableArray<NSString*> *mentionRanges = [NSMutableArray array];
            for (WKMessageEntity *textAttr in richTextContent.entities) {
                if(textAttr.range.location + textAttr.range.length > attributedStr.length) {
                    continue;
                }
                if([textAttr.type isEqualToString:WKBoldRichTextStyle]) {
                    [attributedStr addAttribute:NSFontAttributeName value:[WKApp.shared.config appFontOfSizeMedium:[WKApp shared].config.messageTextFontSize] range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKColorRichTextStyle]) {
                    [attributedStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:textAttr.value] range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKImageRichTextStyle]) {
                    id imageAttr = textAttr.value;
                    NSString *imgURL =@"";
                    NSNumber *width = @(0);
                    NSNumber *height = @(0);
                    if([imageAttr isKindOfClass:[NSDictionary class]]) {
                        width = imageAttr[@"width"]?:@(0);
                        height = imageAttr[@"height"]?:@(0);
                        imgURL =  imageAttr[@"url"];
                    } else if([imageAttr isKindOfClass:[NSString class]]){
                        NSDictionary *attrDict = [WKJsonUtil toDic:imageAttr];
                        width = attrDict[@"width"]?:@(0);
                        height = attrDict[@"height"]?:@(0);
                        imgURL =  attrDict[@"url"];
                    }
                   
                    CGSize size = [UIImage lim_sizeWithImageOriginSize:CGSizeMake(width.intValue, height.intValue) maxLength:250];
                    WKRemoteImageAttachment *remoteImageAttachment = [[WKRemoteImageAttachment alloc] initWithURL:[WKApp.shared getImageFullUrl:imgURL].absoluteString displaySize:size];

    //                remoteImageAttachment.image = [self imageName:@"richtext_font"];
                    [attributedStr addAttribute:NSAttachmentAttributeName value:remoteImageAttachment range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKLinkRichTextStyle] ){
                    [attributedStr addAttribute:NSUnderlineStyleAttributeName value:@1 range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKMentionRichTextStyle]) {
                    [mentionRanges addObject:NSStringFromRange(textAttr.range)];
                } else if([textAttr.type isEqualToString:WKUnderlineRichTextStyle]) {
                    [attributedStr addAttribute:NSUnderlineStyleAttributeName value:@1 range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKStrikethroughRichTextStyle]) {
                    [attributedStr addAttribute:NSStrikethroughStyleAttributeName value:@1 range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKItalicRichTextStyle]) {
                    [attributedStr addAttribute:NSObliquenessAttributeName value:@(italicValue) range:textAttr.range];
                }else if([textAttr.type isEqualToString:WKFontRichTextStyle]) {
                    if(textAttr.value) {
                        [attributedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[textAttr.value floatValue]] range:textAttr.range];
                    }
                    
                }
            }
            for (NSString *mentionRangeStr in mentionRanges) {
                NSRange mentionRange = NSRangeFromString(mentionRangeStr);
                [attributedStr removeAttribute:NSFontAttributeName range:mentionRange];
                [attributedStr removeAttribute:NSForegroundColorAttributeName range:mentionRange];
                [attributedStr removeAttribute:NSUnderlineStyleAttributeName range:mentionRange];
                [attributedStr removeAttribute:NSObliquenessAttributeName range:mentionRange];
                [attributedStr removeAttribute:NSStrikethroughStyleAttributeName range:mentionRange];
                
                UIColor *mentionColor;
                if(messageModel.isSend) {
                    mentionColor = WKApp.shared.config.messageSendTextColor;
                }else {
                    mentionColor = WKApp.shared.config.messageRecvTextColor;
                }
                
                [attributedStr addAttribute:NSFontAttributeName value:defaultFont range:mentionRange];
                [attributedStr addAttribute:NSUnderlineStyleAttributeName value:@1 range:mentionRange];
                [attributedStr addAttribute:NSForegroundColorAttributeName value:mentionColor range:mentionRange];
            }
        } @catch(NSException *exp) {
            NSLog(@"exp--->%@",exp);
        }
        
    }

    return attributedStr;
}


+(CGFloat) textLastlineWidth:(NSMutableAttributedString*)attrStr messageModel:(WKMessageModel*)model{
    NSString *key = [NSString stringWithFormat:@"%@-lastLine",model.clientMsgNo];
    if(model.remoteExtra.contentEdit) {
        key = [NSString stringWithFormat:@"%@-lastLine-edit-%lu",model.clientMsgNo,model.remoteExtra.editedAt];
    }
    static WKMemoryCache *memoryCache;
    if(!memoryCache) {
        memoryCache = [[WKMemoryCache alloc] init];
        memoryCache.maxCacheNum = 100;
    }
    NSNumber  *lastLineWidth =  [memoryCache getCache:key];
    if(lastLineWidth) {
        return lastLineWidth.floatValue;
    }
    CGFloat lastLineWidthF = [attrStr lastlineWidth:[WKApp shared].config.messageContentMaxWidth];
    [memoryCache setCache:@(lastLineWidthF) forKey:key];
    return lastLineWidthF;
}


+(CGSize) textSize:(NSMutableAttributedString*)attrStr messageModel:(WKMessageModel*)model{
    
    NSString *key = [NSString stringWithFormat:@"%@-size",model.clientMsgNo];
   
    static WKMemoryCache *memoryCache;
    if(!memoryCache) {
        memoryCache = [[WKMemoryCache alloc] init];
        memoryCache.maxCacheNum = 100;
    }
    NSString  *sizeStr =  [memoryCache getCache:key];
    if(sizeStr) {
        return CGSizeFromString(sizeStr);
    }
    CGSize size = [attrStr size:[WKApp shared].config.messageContentMaxWidth];
    [memoryCache setCache:NSStringFromCGSize(size) forKey:key];
    return size;
}


+(UIEdgeInsets) contentEdgeInsets:(WKMessageModel*)model {
    
    UIEdgeInsets edgeInsets = [super contentEdgeInsets:model];
    
   
    if([self isShowName:model]) {
        return UIEdgeInsetsMake(edgeInsets.top + WK_NICKNAME_HEIGHT, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
    }
    return UIEdgeInsetsMake(edgeInsets.top, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
    
}

// 气泡边距
+(UIEdgeInsets) bubbleEdgeInsets:(WKMessageModel*) model contentSize:(CGSize)contentSize{
    
    UIEdgeInsets bubbleInsets = [super bubbleEdgeInsets:model contentSize:contentSize];
   
    return UIEdgeInsetsMake(0.0f, bubbleInsets.left, bubbleInsets.bottom, bubbleInsets.right);
   // return WK_BUBBLE_INSETS;
}

+(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRichTextEditor"];
}
@end
