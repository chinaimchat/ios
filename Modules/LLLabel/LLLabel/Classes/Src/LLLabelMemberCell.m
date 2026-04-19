//
//  LLLabelMemberCell.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelMemberCell.h"

@implementation LLLabelMemberModel

- (Class)cell {
    return LLLabelMemberCell.class;
}

- (NSNumber *)showArrow {
    return @(false);
}

@end

@interface LLLabelMemberCell ()

@property(nonatomic,strong) UIImageView *avatarImgView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *firstPinYinLbl;

@end

@implementation LLLabelMemberCell

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.firstPinYinLbl];
    [self.contentView addSubview:self.avatarImgView];
    [self.contentView addSubview:self.nameLbl];
}

- (void)refresh:(LLLabelMemberModel *)model {
    [super refresh:model];
    
    self.firstPinYinLbl.text = model.firstPinYIn;
    self.nameLbl.text = model.name;
    [self.avatarImgView setImageWithURL:[NSURL URLWithString:model.avatarURL] placeholderImage:[WKApp shared].config.defaultAvatar];
    
    if([WKApp shared].config.style == WKSystemStyleDark) {
        [self.firstPinYinLbl setTextColor:[UIColor whiteColor]];
    }else{
        [self.firstPinYinLbl setTextColor:[UIColor colorWithRed:49.0f/255.0f green:49.0f/255.0f blue:49.0f/255.0f alpha:1.0f]];
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.firstPinYinLbl.lim_size = CGSizeMake(18.0f, 18.0f);
    self.firstPinYinLbl.lim_centerY_parent = self.contentView;
    self.firstPinYinLbl.lim_left = 15.0f;
   
    
    self.avatarImgView.lim_centerY_parent = self.contentView;
    self.avatarImgView.lim_left = self.firstPinYinLbl.lim_right + 13.0f;
    
    self.nameLbl.lim_left = self.avatarImgView.lim_right + 15.0f;
    self.nameLbl.lim_height = self.contentView.lim_height;
    self.nameLbl.lim_width = self.contentView.lim_width - self.nameLbl.lim_left - 15.0f;
    
}

- (UIImageView *)avatarImgView {
    if(!_avatarImgView) {
        _avatarImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKApp.shared.config.messageAvatarSize.width, WKApp.shared.config.messageAvatarSize.height)];
        _avatarImgView.layer.masksToBounds = YES;
        _avatarImgView.layer.cornerRadius = _avatarImgView.lim_height/2.0f;
    }
    return _avatarImgView;
}

- (UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] init];
        _nameLbl.font = [[WKApp shared].config appFontOfSize:15.0f];
        _nameLbl.textColor = [WKApp shared].config.defaultTextColor;
        _nameLbl.numberOfLines = 1;
    }
    return _nameLbl;
}

- (UILabel *)firstPinYinLbl {
    if(!_firstPinYinLbl) {
        _firstPinYinLbl = [[UILabel alloc] init];
        [_firstPinYinLbl setFont:[[WKApp shared].config appFontOfSizeSemibold:18.0f]];
        
    }
    return _firstPinYinLbl;
}

@end
