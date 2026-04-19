//
//  WKFavoriteCell.m
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import "WKFavoriteCell.h"
#import <M80AttributedLabel/M80AttributedLabel.h>
#import "M80AttributedLabel+WK.h"
#import "WKAvatarUtil.h"
#import "WKTimeTool.h"
#import "WKDefaultWebImageMediator.h"
#define authViewHeight 40.0f
#define operationViewHeight 30.0f
@implementation WKFavoriteModel

-(Class) cell {
    return WKFavoriteCell.class;
}
@end

@interface WKFavoriteCell ()

@property(nonatomic,strong) WKFavoriteModel *model;
@property(nonatomic,strong) UIView *authView;
@property(nonatomic,strong) UIView *favoriteContentView;

@property(nonatomic,strong) UIImageView *avatarImg;
@property(nonatomic,strong) UILabel *authNameLbl;
@property(nonatomic,strong) UILabel *createdAtLbl;

@property(nonatomic,strong) M80AttributedLabel *contentLbl; // 文本正文
@property(nonatomic,strong) UIImageView *oneImageView; // 单图image

@property(nonatomic,strong) UIView *operateContentView;
@property(nonatomic,strong) UIButton *moreBtn; // 更多

@end

@implementation WKFavoriteCell

+(CGSize) sizeForModel:(WKFavoriteModel*)model{
    CGFloat contentHeight = 100.0f;
    switch (model.type) {
        case WKFavoriteTypeText: { // 文本
            CGSize textSize = [self getTextLabelSize:model maxWidth:WKScreenWidth - 30.0f];
            contentHeight = textSize.height;
//            if(contentHeight>100.0f) {
//                contentHeight = 100.0f;
//            }
            break;
        }
        case WKFavoriteTypeSingleImage: // 单图
            contentHeight = 100.0f;
        break;
            
        default:
            break;
    }
    return  CGSizeMake(WKScreenWidth, contentHeight+authViewHeight + operationViewHeight);
}

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.operateContentView];
    [self.contentView addSubview:self.favoriteContentView];
    [self.contentView addSubview:self.authView];
    
    
    [self.authView addSubview:self.avatarImg];
    [self.authView addSubview:self.authNameLbl];
    [self.authView addSubview:self.createdAtLbl];
    
    [self.favoriteContentView addSubview:self.contentLbl];
    [self.favoriteContentView addSubview:self.oneImageView];
    
    [self.operateContentView addSubview:self.moreBtn];
    
}

- (void)refresh:(WKFavoriteModel*)model {
    [super refresh:model];
    self.model = model;
    self.authNameLbl.text = model.authorName;
    [self.authNameLbl sizeToFit];
    
    [self.avatarImg lim_setImageWithURL:[NSURL URLWithString:[WKAvatarUtil getAvatar:model.authorUID]] placeholderImage:[WKApp shared].config.defaultAvatar];
    

    self.createdAtLbl.text = [WKTimeTool getTimeStringAutoShort2:[WKTimeTool dateFromString:model.createdAt] mustIncludeTime:NO];
    [self.createdAtLbl sizeToFit];
    
    self.contentLbl.backgroundColor = [WKApp shared].config.cellBackgroundColor;
    
    self.contentLbl.hidden = YES;
    self.oneImageView.hidden = YES;
    if(model.type == WKFavoriteTypeText) {
        self.contentLbl.hidden = NO;
        [self.contentLbl lim_setText:model.payload[@"content"]];
    }else if(model.type == WKFavoriteTypeSingleImage) {
        self.oneImageView.hidden = NO;
        [self.oneImageView lim_setImageWithURL:[[WKApp shared] getImageFullUrl:model.payload[@"content"]] placeholderImage:[WKApp shared].config.defaultPlaceholder];
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.operateContentView.lim_top = 0.0f;
    self.operateContentView.lim_left = 0.0f;
    
    self.moreBtn.lim_left = self.operateContentView.lim_width - self.moreBtn.lim_width - 15.0f;
    self.moreBtn.lim_centerY_parent = self.operateContentView;
    
    self.authView.lim_top = self.lim_height - self.authView.lim_height;
    
    self.avatarImg.lim_left = 15.0f;
    self.avatarImg.lim_top = self.authView.lim_height/2.0f - self.avatarImg.lim_height/2.0f;
    
    self.authNameLbl.lim_top = self.authView.lim_height/2.0f - self.authNameLbl.lim_height/2.0f;
    self.authNameLbl.lim_left = self.avatarImg.lim_right+15.0f;
    
    self.createdAtLbl.lim_top = self.authView.lim_height/2.0f - self.createdAtLbl.lim_height/2.0f;
    self.createdAtLbl.lim_left = self.authNameLbl.lim_right+20.0f;
    
    self.favoriteContentView.lim_top = self.operateContentView.lim_bottom;
    self.favoriteContentView.lim_height = self.lim_height - self.authView.lim_height - self.operateContentView.lim_height;
    self.contentLbl.frame = CGRectMake(15.0f, 0.0f, self.favoriteContentView.lim_width - 30.0f, self.favoriteContentView.lim_height);
    
    self.oneImageView.lim_top = 0.0f;
    self.oneImageView.lim_left = 15.0f;
    self.oneImageView.lim_width = self.favoriteContentView.lim_height-15.0f;
    self.oneImageView.lim_height = self.favoriteContentView.lim_height;
}

- (UIButton *)moreBtn {
    if(!_moreBtn) {
        _moreBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24.0f, 24.0f)];
        [_moreBtn setImage:[self imageName:@"More"] forState:UIControlStateNormal];
        [_moreBtn setImage:[self imageName:@"More"] forState:UIControlStateHighlighted];
        [_moreBtn addTarget:self action:@selector(morePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreBtn;
}

-(void) morePressed {
    if(self.model.onMore) {
        __weak typeof(self) weakSelf = self;
        self.model.getOneImage = ^UIImage * _Nonnull{
            return weakSelf.oneImageView.image;
        };
        self.model.onMore(self.model);
    }
}

- (UIView *)authView {
    if(!_authView) {
        _authView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, authViewHeight)];
//        [_authView setBackgroundColor:[UIColor redColor]];
    }
    return _authView;
}

- (UIView *)operateContentView {
    if(!_operateContentView) {
        _operateContentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, operationViewHeight)];
    }
    return  _operateContentView;
}

- (UIImageView *)avatarImg {
    if(!_avatarImg) {
        _avatarImg = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
        _avatarImg.layer.masksToBounds = YES;
        _avatarImg.layer.cornerRadius =_avatarImg.lim_height/2.0f;
    }
    return _avatarImg;
}

- (UILabel *)authNameLbl {
    if(!_authNameLbl) {
        _authNameLbl = [[UILabel alloc] init];
        [_authNameLbl setFont:[[WKApp shared].config appFontOfSize:12.0f]];
        [_authNameLbl setTextColor:[[WKApp shared].config tipColor]];
    }
    return _authNameLbl;
}

- (UILabel *)createdAtLbl {
    if(!_createdAtLbl) {
        _createdAtLbl = [[UILabel alloc] init];
        [_createdAtLbl setFont:[[WKApp shared].config appFontOfSize:12.0f]];
        [_createdAtLbl setTextColor:[[WKApp shared].config tipColor]];
    }
    return _createdAtLbl;
}

-(UIView*) favoriteContentView {
    if(!_favoriteContentView) {
        _favoriteContentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 60.0f)];
    }
    return _favoriteContentView;
}

- (M80AttributedLabel *)contentLbl {
    if(!_contentLbl) {
        _contentLbl = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
//        _contentLbl.lineBreakMode = NSLineBreakByTruncatingTail;
//        _contentLbl.numberOfLines = 4.0f;
        [_contentLbl setTextColor:[WKApp shared].config.defaultTextColor];
        [_contentLbl setFont:[UIFont systemFontOfSize:[WKApp shared].config.messageTextFontSize]];
    }
    return _contentLbl;
}

- (UIImageView *)oneImageView {
    if(!_oneImageView) {
        _oneImageView = [[UIImageView alloc] init];
        _oneImageView.userInteractionEnabled = YES;
        _oneImageView.contentMode = UIViewContentModeScaleAspectFill;
        _oneImageView.clipsToBounds = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onOneImageTap)];
        [_oneImageView addGestureRecognizer:tap];
    }
    return _oneImageView;
}

-(void) onOneImageTap{
    YBImageBrowser *imageBrowser = [[YBImageBrowser alloc] init];
    
    WKBrowserToolbar *toolbar = WKBrowserToolbar.new;
    toolbar.browser = imageBrowser;
    
    imageBrowser.toolViewHandlers = @[toolbar];
    imageBrowser.webImageMediator = [WKDefaultWebImageMediator new];
    
    NSString *imgPath = self.model.payload[@"content"];
    WKImageContent *imageContent = [[WKImageContent alloc] init];
    imageContent.remoteUrl = imgPath;
    imageContent.width = self.oneImageView.image.size.width;
    imageContent.height = self.oneImageView.image.size.height;
    
    YBIBImageData *data = [YBIBImageData new];
    data.imageURL = [[WKApp shared] getImageFullUrl:imgPath];
    data.extraData = @{@"messageContent":imageContent};
    data.projectiveView = self.oneImageView;
     imageBrowser.dataSourceArray = @[data];
    [imageBrowser show];
    
}

+ (CGSize)getTextLabelSize:(WKFavoriteModel *)model maxWidth:(CGFloat)maxWidth {
    static WKMemoryCache *memoryCache;
    static NSLock *memoryLock;
    if(!memoryLock) {
        memoryLock = [[NSLock alloc] init];
    }
    if(!memoryCache) {
        memoryCache = [[WKMemoryCache alloc] init];
        memoryCache.maxCacheNum = 500;
    }
   NSString *cacheKey = model.no;
    [memoryLock lock];
   NSString *cacheSizeStr =   [memoryCache getCache:cacheKey];
    [memoryLock unlock];
    if(cacheSizeStr) {
        return CGSizeFromString(cacheSizeStr);
    }
    static M80AttributedLabel *textLbl;
    if(!textLbl) {
        textLbl = [[M80AttributedLabel alloc] init];
//        textLbl.lineBreakMode = NSLineBreakByTruncatingTail;
//        textLbl.numberOfLines = 4.0f;
        [textLbl setFont:[UIFont systemFontOfSize:[WKApp shared].config.messageTextFontSize]];
    }
    [textLbl lim_setText:model.payload[@"content"]];
    
    CGSize textSize = [textLbl sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
     [memoryLock lock];
    [memoryCache setCache:NSStringFromCGSize(textSize) forKey:cacheKey];
    [memoryLock unlock];
    return textSize;
}
-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongFavorite"];
}

@end
