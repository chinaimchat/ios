//
//  WKSystemMessageCell.m
//  WuKongBase
//
//  Created by tt on 2020/1/19.
//

#import "WKSystemMessageCell.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKResource.h"
#import "WKAPIClient.h"
#import "WKNavigationManager.h"
#import "UIView+WKCommon.h"
#import "WKWebViewVC.h"
#import "WuKongBase.h"
#import "WKTipLabel.h"
#import "WKConstant.h"
#import "WKSystemNotifyDisplay.h"
#import "WKGroupTipNicknamePolicy.h"

@interface WKSystemMessageCell () <UITextViewDelegate>
@property(nonatomic,strong) UIView *tipTextBoxView;
@property(nonatomic,strong) WKTipLabel *tipTextLbl;
@property(nonatomic,strong) UITextView *tipTextView;
@property(nonatomic,strong) WKMessageModel *messageModel;

@property(nonatomic,strong) UIImageView *inviteIconImgView; // 进群邀请的icon
@property(nonatomic,strong) UIButton *inviteWaitSureBtn; // 邀请待确认
@end

@implementation WKSystemMessageCell

#define WK_SYSTEM_TEXT_SPACE 60.0f

#define WK_INVITE_LEFT_SPACE 15.0f // 群聊邀请确认左边距离
#define WK_INVITE_RIGHT_SPACE 20.0f // 群聊邀请确认右边距离

/// 1011 等系统提示在红包模块里可能解码为 {@link WKRedPacketOpenContent}（无 {@link WKSystemContent#displayContent}），
/// 与 {@link WKSystemContent} 一致需用 {@link WKMessageContent#contentDict} 取模板根（content/extra）。
+ (NSDictionary *)wk_notifyTemplateRootFromMessageContent:(WKMessageContent *)msgContent {
    if (!msgContent) {
        return nil;
    }
    if ([msgContent isKindOfClass:[WKSystemContent class]]) {
        NSDictionary *c = [(WKSystemContent *)msgContent content];
        if ([c isKindOfClass:[NSDictionary class]]) {
            return c;
        }
    }
    NSDictionary *d = msgContent.contentDict;
    if ([d isKindOfClass:[NSDictionary class]] && d.count > 0) {
        return d;
    }
    return nil;
}

+ (CGSize)sizeForMessage:(WKMessageModel *)model {
    NSString *text = [[self class] displayTextForSizeWithContent:model.content contentType:model.contentType];
    CGSize contentSize = CGSizeMake(0.0f, 0.0f);
    if(text.length > 0) {
        contentSize =  [[self class] getTextSize:text maxWidth:WKScreenWidth - WK_SYSTEM_TEXT_SPACE];
    }
   
    if(model.contentType == WK_GROUP_MEMBERINVITE) { // 群聊邀请确认
        return CGSizeMake(contentSize.width+20.0f + (WK_INVITE_LEFT_SPACE + WK_INVITE_RIGHT_SPACE), contentSize.height+20.0f);
    }else {
        return CGSizeMake(contentSize.width+20.0f, contentSize.height+20.0f);
    }
    
}

-(void) initUI {
    [super initUI];
    /// 父类在 contentView 上加了点击手势用于收起键盘；默认 cancelsTouchesInView=YES 会吞掉子视图触摸，
    /// 导致红包领取提示等 UITextView 内的 NSLink（「你」、句末红包）无法响应。与群是否禁止互加无关。
    for (UIGestureRecognizer *gr in self.contentView.gestureRecognizers) {
        if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
            ((UITapGestureRecognizer *)gr).cancelsTouchesInView = NO;
        }
    }

    [self.contentView addSubview:self.tipTextBoxView];
    [self.tipTextBoxView addSubview:self.tipTextLbl];
    [self.tipTextBoxView addSubview:self.tipTextView];
    // 进群邀请的icon
    [self.contentView addSubview:self.inviteIconImgView];
    // 进群确认
    [self.contentView addSubview:self.inviteWaitSureBtn];
    
//    [self.contentView setBackgroundColor:[UIColor redColor]];
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    self.messageModel = model;
    WKMessageContent *msgContent = model.content;
    NSDictionary *contentRoot = [[self class] wk_notifyTemplateRootFromMessageContent:msgContent];
    WKSystemNotifyBuilt *richBuilt = nil;
    if (model.contentType == WK_REDPACKET_OPEN) {
        richBuilt = [WKSystemNotifyDisplay buildRedPacketOpenNotify:contentRoot];
    } else if (model.contentType == WK_TRADE_SYSTEM_NOTIFY && [WKSystemNotifyDisplay isTemplateNotifyJson:contentRoot]) {
        richBuilt = [WKSystemNotifyDisplay buildTradeSystemTemplateNotify:contentRoot];
    }
    if (richBuilt.text.length > 0) {
        if ([[self class] systemNotifyBuiltNeedsInteractiveTextView:richBuilt]) {
            self.tipTextLbl.hidden = YES;
            self.tipTextView.hidden = NO;
            self.tipTextView.attributedText = [[self class] attributedSystemNotifyBuilt:richBuilt channel:model.channel contentRoot:contentRoot];
            self.tipTextView.userInteractionEnabled = YES;
            self.tipTextView.selectable = YES;
        } else {
            self.tipTextLbl.hidden = NO;
            self.tipTextView.hidden = YES;
            self.tipTextLbl.text = richBuilt.text;
        }
    } else if (model.contentType == WK_TRADE_SYSTEM_NOTIFY) {
        self.tipTextLbl.hidden = NO;
        self.tipTextView.hidden = YES;
        NSString *plain = [WKSystemNotifyDisplay plainShowTextFromNotifyContentRoot:contentRoot];
        self.tipTextLbl.text = plain.length > 0 ? plain : [self getDisplayContent:contentRoot];
    } else {
        self.tipTextLbl.hidden = NO;
        self.tipTextView.hidden = YES;
        self.tipTextLbl.text = [self getDisplayContent:contentRoot];
    }
    if(model.contentType == WK_GROUP_MEMBERINVITE) {
        self.inviteIconImgView.hidden = NO;
        self.inviteWaitSureBtn.hidden = NO;
    }else {
        self.inviteIconImgView.hidden = YES;
        self.inviteWaitSureBtn.hidden = YES;
    }
    [self.tipTextBoxView setBackgroundColor:[WKApp shared].config.cellBackgroundColor];
}


-(NSString*) getDisplayContent:(NSDictionary*)contentDic {
    return [[self class] getDisplayContentForDictionary:contentDic];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    if(!self.messageModel) {
        return;
    }
    CGSize contentSize = [[self class] sizeForMessage:self.messageModel];
     if(self.messageModel.contentType == WK_GROUP_MEMBERINVITE) {
          self.tipTextBoxView.lim_size = CGSizeMake(contentSize.width-10.0f- WK_INVITE_LEFT_SPACE - WK_INVITE_RIGHT_SPACE, contentSize.height-10.0f);
     }else {
          self.tipTextBoxView.lim_size = CGSizeMake(contentSize.width-10.0f, contentSize.height-10.0f);
     }
   
    self.tipTextBoxView.lim_left = self.lim_width/2.0f - self.tipTextBoxView.lim_width/2.0f;
    
    self.tipTextLbl.lim_size = self.tipTextBoxView.lim_size;
    self.tipTextView.lim_size = self.tipTextBoxView.lim_size;
    
    if(self.messageModel.contentType == WK_GROUP_MEMBERINVITE) {
        self.inviteIconImgView.lim_top = self.tipTextBoxView.lim_height/2.0f - self.inviteIconImgView.lim_height/2.0f;
        self.inviteIconImgView.lim_left = self.tipTextBoxView.lim_left - self.inviteIconImgView.lim_width - 5.0f;
        
        self.inviteWaitSureBtn.lim_left = self.tipTextBoxView.lim_right + 5.0f;
        self.inviteWaitSureBtn.lim_top = self.tipTextBoxView.lim_height/2.0f - self.inviteWaitSureBtn.lim_height/2.0f;
    }
    
    
}

- (UITextView *)tipTextView {
    if (!_tipTextView) {
        _tipTextView = [[UITextView alloc] init];
        _tipTextView.backgroundColor = UIColor.clearColor;
        _tipTextView.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5);
        _tipTextView.textContainer.lineFragmentPadding = 0;
        _tipTextView.scrollEnabled = NO;
        _tipTextView.editable = NO;
        _tipTextView.selectable = NO;
        _tipTextView.userInteractionEnabled = NO;
        _tipTextView.delegate = self;
        _tipTextView.font = [UIFont systemFontOfSize:[WKApp shared].config.messageTipTimeFontSize];
        _tipTextView.textColor = [UIColor grayColor];
        _tipTextView.textAlignment = NSTextAlignmentCenter;
        _tipTextView.linkTextAttributes = @{ NSForegroundColorAttributeName: [UIColor systemBlueColor] };
    }
    return _tipTextView;
}

- (WKTipLabel *)tipTextLbl {
    if(!_tipTextLbl) {
        _tipTextLbl = [[WKTipLabel alloc] init];
        [_tipTextLbl setTextAlignment:NSTextAlignmentCenter];
        [_tipTextLbl setFont:[UIFont systemFontOfSize:[WKApp shared].config.messageTipTimeFontSize]];
        [_tipTextLbl setTextColor:[UIColor grayColor]];
        [_tipTextLbl setNumberOfLines:0];
        _tipTextLbl.lineBreakMode = NSLineBreakByWordWrapping;

    }
    return _tipTextLbl;
}
- (UIView *)tipTextBoxView {
    if(!_tipTextBoxView) {
        _tipTextBoxView = [[UIView alloc] init];
        _tipTextBoxView.layer.masksToBounds = YES;
        _tipTextBoxView.layer.cornerRadius = 10.0f;
    }
    return _tipTextBoxView;
}

- (UIImageView *)inviteIconImgView {
    if(!_inviteIconImgView) {
        _inviteIconImgView = [[UIImageView alloc] initWithImage:[self imageName:@"Conversation/Messages/IconInvite"]];
    }
    return _inviteIconImgView;
}
- (UIButton *)inviteWaitSureBtn {
    if(!_inviteWaitSureBtn) {
        _inviteWaitSureBtn = [[UIButton alloc] init];
        [_inviteWaitSureBtn setTitle:LLang(@"去确认") forState:UIControlStateNormal];
        [[_inviteWaitSureBtn titleLabel] setFont:[UIFont systemFontOfSize:[WKApp shared].config.messageTipTimeFontSize]];
        [_inviteWaitSureBtn setTitleColor:[WKApp shared].config.themeColor forState:UIControlStateNormal];
        [_inviteWaitSureBtn sizeToFit];
        [_inviteWaitSureBtn addTarget:self action:@selector(onInvite) forControlEvents:UIControlEventTouchUpInside];
    }
    return _inviteWaitSureBtn;
}

-(void) onInvite {
    WKSystemContent *systemContent = (WKSystemContent*)[self.messageModel content];
      if(!systemContent.content  || !systemContent.content[@"invite_no"]) {
          [[[WKNavigationManager shared] topViewController].view showMsg:LLang(@"数据错误！")];
          return;
      }
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"groups/%@/member/h5confirm?invite_no=%@",self.messageModel.channel.channelId,systemContent.content[@"invite_no"]] parameters:nil].then(^(NSDictionary *resultDic){
        if(resultDic && resultDic[@"url"]) {
            WKWebViewVC *vc = [[WKWebViewVC alloc] init];
            vc.url = [NSURL URLWithString:resultDic[@"url"]];
            [[WKNavigationManager shared] pushViewController:vc animated:YES];
            return;
        }
    }).catch(^(NSError *error){
        [[[WKNavigationManager shared] topViewController].view showMsg:error.domain];
    });
}



+ (NSString *)displayTextForSizeWithContent:(WKMessageContent *)messageContent contentType:(NSInteger)contentType {
    NSDictionary *root = [self wk_notifyTemplateRootFromMessageContent:messageContent];

    if (contentType == WK_REDPACKET_OPEN) {
        WKSystemNotifyBuilt *built = [WKSystemNotifyDisplay buildRedPacketOpenNotify:root];
        if (built.text.length > 0) {
            return built.text;
        }
    } else if (contentType == WK_TRADE_SYSTEM_NOTIFY) {
        if ([WKSystemNotifyDisplay isTemplateNotifyJson:root]) {
            WKSystemNotifyBuilt *built = [WKSystemNotifyDisplay buildTradeSystemTemplateNotify:root];
            if (built.text.length > 0) {
                return built.text;
            }
        } else {
            NSString *plain = [WKSystemNotifyDisplay plainShowTextFromNotifyContentRoot:root];
            if (plain.length > 0) {
                return plain;
            }
        }
    }
    if ([messageContent isKindOfClass:[WKSystemContent class]]) {
        WKSystemContent *sys = (WKSystemContent *)messageContent;
        if (sys.displayContent.length > 0) {
            return sys.displayContent;
        }
        return [self getDisplayContentForDictionary:sys.content];
    }
    if ([messageContent respondsToSelector:@selector(conversationDigest)]) {
        NSString *dig = [messageContent conversationDigest];
        if (dig.length > 0) {
            return dig;
        }
    }
    return [self getDisplayContentForDictionary:root];
}

+ (BOOL)walletSuffixIsClickable:(WKSystemNotifyTappableSuffix *_Nullable)suf {
    if (!suf) {
        return NO;
    }
    return [suf opensRedPacketDetail] || [suf opensTransferDetail];
}

+ (BOOL)systemNotifyBuiltNeedsInteractiveTextView:(WKSystemNotifyBuilt *)built {
    if (!built) {
        return NO;
    }
    if (built.nickSpans.count > 0) {
        return YES;
    }
    return [self walletSuffixIsClickable:built.tappableSuffix];
}

+ (UIColor *)walletSuffixColorFromHint:(NSString *)hint {
    NSString *h = hint.lowercaseString;
    if ([h isEqualToString:@"blue"]) {
        return [UIColor systemBlueColor];
    }
    if ([h isEqualToString:@"red"]) {
        return [UIColor systemRedColor];
    }
    return [WKApp shared].config.themeColor;
}

+ (NSAttributedString *)attributedSystemNotifyBuilt:(WKSystemNotifyBuilt *)built channel:(WKChannel *)channel contentRoot:(NSDictionary *)contentRoot {
    UIFont *font = [UIFont systemFontOfSize:[WKApp shared].config.messageTipTimeFontSize];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    NSUInteger len = built.text.length;
    NSDictionary *baseAttrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor grayColor],
        NSParagraphStyleAttributeName: style
    };
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:built.text attributes:baseAttrs];

    NSUInteger el = built.emojiPrefixLength;
    if (el > 0 && len >= el) {
        [mas addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:NSMakeRange(0, el)];
    }
    if (len > el) {
        [mas addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(el, len - el)];
    }

    int ff = [WKGroupTipNicknamePolicy forbiddenFlagFromMessageContentRoot:contentRoot];
    BOOL blockNick = [WKGroupTipNicknamePolicy shouldBlockNicknameProfileJumpWithChannelId:channel.channelId channelType:channel.channelType forbiddenFlag:ff];
    NSString *groupNo = (channel.channelType == WK_GROUP) ? (channel.channelId ?: @"") : @"";
    NSString *loginUid = [WKSDK shared].options.connectInfo.uid ?: @"";

    for (WKSystemNotifyNickSpan *sp in built.nickSpans) {
        if (sp.start < 0 || sp.end > (NSInteger)len || sp.start >= sp.end || sp.uid.length == 0) {
            continue;
        }
        NSRange nr = NSMakeRange((NSUInteger)sp.start, (NSUInteger)(sp.end - sp.start));
        UIColor *nameBlue = [UIColor systemBlueColor];
        [mas addAttribute:NSForegroundColorAttributeName value:nameBlue range:nr];
        NSURL *u;
        /// 与群成员列表一致：禁止互加时仍允许点「你」看自己资料；仅拦截点他人昵称绕 vercode。
        BOOL blockThisSpan = blockNick && !(loginUid.length > 0 && [sp.uid isEqualToString:loginUid]);
        if (blockThisSpan) {
            u = [NSURL URLWithString:@"wk-user-tip://blocked"];
        } else {
            NSString *encUid = [sp.uid stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
            NSString *encGid = [groupNo stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
            NSString *urlStr = [NSString stringWithFormat:@"wk-user-tip://profile?uid=%@&group_id=%@", encUid, encGid];
            u = [NSURL URLWithString:urlStr];
        }
        if (u) {
            [mas addAttribute:NSLinkAttributeName value:u range:nr];
        }
    }

    WKSystemNotifyTappableSuffix *suf = built.tappableSuffix;
    if (suf && suf.start >= 0 && suf.end <= (NSInteger)len && suf.start < suf.end) {
        NSRange r = NSMakeRange((NSUInteger)suf.start, (NSUInteger)(suf.end - suf.start));
        BOOL rp = [suf opensRedPacketDetail];
        BOOL tr = [suf opensTransferDetail];
        UIColor *accent = [self walletSuffixColorFromHint:suf.colorHint];
        if (rp) {
            NSString *pnEnc = [suf.packetNo stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
            NSString *cid = channel.channelId ?: @"";
            NSString *cidEnc = [cid stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
            NSString *urlStr = [NSString stringWithFormat:@"wk-wallet-tip://redpacket?packet_no=%@&channel_id=%@&channel_type=%u", pnEnc, cidEnc, (unsigned int)channel.channelType];
            NSURL *url = [NSURL URLWithString:urlStr];
            if (url) {
                [mas addAttribute:NSLinkAttributeName value:url range:r];
            }
            [mas addAttribute:NSForegroundColorAttributeName value:accent range:r];
        } else if (tr) {
            NSString *tnEnc = [suf.transferNo stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
            NSString *urlStr = [NSString stringWithFormat:@"wk-wallet-tip://transfer?transfer_no=%@", tnEnc];
            NSURL *url = [NSURL URLWithString:urlStr];
            if (url) {
                [mas addAttribute:NSLinkAttributeName value:url range:r];
            }
            [mas addAttribute:NSForegroundColorAttributeName value:accent range:r];
        } else {
            [mas addAttribute:NSForegroundColorAttributeName value:accent range:r];
        }
    }
    return mas;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.scheme isEqualToString:@"wk-user-tip"]) {
        if ([URL.host isEqualToString:@"blocked"]) {
            [[[WKNavigationManager shared] topViewController].view showMsg:LLang(@"群内已禁止互加好友，无法通过此处查看成员资料")];
            return NO;
        }
        if ([URL.host isEqualToString:@"profile"]) {
            NSURLComponents *comp = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
            NSMutableDictionary *q = [NSMutableDictionary dictionary];
            for (NSURLQueryItem *it in comp.queryItems) {
                if (it.name.length) {
                    q[it.name] = it.value ?: @"";
                }
            }
            NSString *uid = q[@"uid"];
            if (uid.length == 0) {
                return NO;
            }
            NSString *groupId = q[@"group_id"] ?: @"";
            WKChannel *from = nil;
            if (groupId.length > 0) {
                from = [WKChannel channelID:groupId channelType:WK_GROUP];
            }
            WKChannelMember *member = from ? [[WKSDK shared].channelManager getMember:from uid:uid] : nil;
            NSString *vercode = member.extra[WKChannelExtraKeyVercode] ?: @"";
            NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:@{ @"uid": uid, @"vercode": vercode }];
            if (from) {
                param[@"channel"] = from;
            }
            [[WKApp shared] invoke:WKPOINT_USER_INFO param:param];
            return NO;
        }
        return NO;
    }
    if ([URL.scheme isEqualToString:@"wk-wallet-tip"]) {
        NSURLComponents *comp = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in comp.queryItems) {
            if (item.name.length) {
                param[item.name] = item.value ?: @"";
            }
        }
        [[WKApp shared] invoke:@"wallet_tip_open_detail" param:param];
        return NO;
    }
    return YES;
}

+ (NSString *)getDisplayContentForDictionary:(NSDictionary *)contentDic {
    if (!contentDic) {
        return LLang(@"未知");
    }
    NSString *content = LLang(contentDic[@"content"] ?: @"");
    id extra = contentDic[@"extra"];
    if (extra && [extra isKindOfClass:[NSArray class]]) {
        NSArray *extraArray = (NSArray *)extra;
        if (extraArray.count > 0) {
            for (int i = 0; i <= (int)extraArray.count - 1; i++) {
                NSDictionary *extrDict = extraArray[i];
                NSString *name = extrDict[@"name"] ?: @"";
                if ([[WKSDK shared].options.connectInfo.uid isEqualToString:extrDict[@"uid"]]) {
                    name = LLang(@"你");
                }
                content = [content stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%d}", i] withString:name];
            }
        }
    }
    return content;
}

+ (CGSize) getTextSize:(NSString*) text maxWidth:(CGFloat)maxWidth{
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
   NSAttributedString *string = [[NSAttributedString alloc]initWithString:text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[WKApp shared].config.messageTipTimeFontSize], NSParagraphStyleAttributeName:style}];
    CGSize size =  [string boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    return size;
}

-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
//    return [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

@end
