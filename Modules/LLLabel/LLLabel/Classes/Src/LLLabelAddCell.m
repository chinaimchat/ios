//
//  LLLabelAddCell.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelAddCell.h"
#import "LLLabelModule.h"

@implementation LLLabelAddModel

- (Class)cell {
    return LLLabelAddCell.class;
}

@end

@interface LLLabelAddCell ()

@property(nonatomic,strong) UIImageView *iconImgView;
@property(nonatomic,strong) UILabel *titleLbl;

@end

@implementation LLLabelAddCell

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.titleLbl];
    [self.contentView addSubview:self.iconImgView];
}

- (void)refresh:(LLLabelAddModel *)model {
    [super refresh:model];
    if(model.title && ![model.title isEqualToString:@""]) {
        self.titleLbl.text = model.title;
    }
    self.iconImgView.hidden = model.dangerStyle;
    self.titleLbl.textColor = model.dangerStyle ? [UIColor colorWithRed:0.96f green:0.26f blue:0.21f alpha:1.0f] : [WKApp shared].config.themeColor;
    self.titleLbl.textAlignment = model.dangerStyle ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    [self.titleLbl sizeToFit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.iconImgView.hidden) {
        self.titleLbl.lim_left = 15.0f;
        self.titleLbl.lim_width = self.contentView.lim_width - 30.0f;
    } else {
        self.iconImgView.lim_left = 15.0f;
        self.iconImgView.lim_centerY_parent = self.contentView;
        self.titleLbl.lim_left = self.iconImgView.lim_right + 10.0f;
    }
    self.titleLbl.lim_centerY_parent = self.contentView;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.text = LLang(@"新建分组");
        [_titleLbl sizeToFit];
        _titleLbl.font = [[WKApp shared].config appFontOfSize:15.0f];
        _titleLbl.textColor = [WKApp shared].config.themeColor;
    }
    return _titleLbl;
}

- (UIImageView *)iconImgView {
    if(!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 18.0f, 18.0f)];
        _iconImgView.image = [self imageName:@"Add"];
    }
    return _iconImgView;
}
- (UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"LLLabel"];
}

@end
