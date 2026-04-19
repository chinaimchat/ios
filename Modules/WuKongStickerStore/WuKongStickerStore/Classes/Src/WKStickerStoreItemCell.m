//
//  WKStickerStoreItemCell.m
//  WuKongBase
//
//  Created by tt on 2021/9/27.
//

#import "WKStickerStoreItemCell.h"
//#import <SVGKit/SVGKit.h>

@implementation WKStickerStoreItemModel

- (Class)cell {
    return WKStickerStoreItemCell.class;
}

- (CGFloat)cellHeight {
    
    return 80.0f;
}

@end

@interface WKStickerStoreItemCell ()

@property(nonatomic,strong) UIImageView *stickerImgView;

@property(nonatomic,strong) UILabel *titleLbl;
@property(nonatomic,strong) UILabel *remarkLbl;

@property(nonatomic,strong) UIButton *downloadBtn;

@property(nonatomic,strong) WKStickerStoreItemModel *model;

@end

@implementation WKStickerStoreItemCell

- (void)setupUI {
    [super setupUI];
    
    [self.contentView addSubview:self.stickerImgView];
    [self.contentView addSubview:self.titleLbl];
    [self.contentView addSubview:self.remarkLbl];
    [self.contentView addSubview:self.downloadBtn];
}

- (void)refresh:(WKStickerStoreItemModel*)cellModel {
    [super refresh:cellModel];
    self.model = cellModel;
    
    [self.stickerImgView lim_setImageWithURL:cellModel.stickerCover placeholderImage:[WKApp shared].config.defaultPlaceholder];
    
    self.titleLbl.text = cellModel.title;
    [self.titleLbl sizeToFit];
    
    self.remarkLbl.text = cellModel.remark;
    [self.remarkLbl sizeToFit];
    
    if(cellModel.added) {
        [self.downloadBtn setBackgroundColor:[UIColor redColor]];
        [self.downloadBtn setTitle:LLang(@"移除") forState:UIControlStateNormal];
    }else {
        [self.downloadBtn setBackgroundColor:[WKApp shared].config.themeColor];
        [self.downloadBtn setTitle:LLang(@"添加") forState:UIControlStateNormal];
    }
    
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat space = 15.0f;
    
    self.stickerImgView.lim_centerY_parent = self.contentView;
    self.stickerImgView.lim_left = space;
    
    self.titleLbl.lim_left = self.stickerImgView.lim_right + space;
    self.remarkLbl.lim_left = self.titleLbl.lim_left;
    
    CGFloat remarkTopSpace  = 4.0f;
    
    CGFloat contentHeight = self.titleLbl.lim_height + remarkTopSpace + self.remarkLbl.lim_height;
    
    self.titleLbl.lim_top = self.contentView.lim_height/2.0f - contentHeight/2.0f;
    self.remarkLbl.lim_top = self.titleLbl.lim_bottom + remarkTopSpace;
    
    self.downloadBtn.lim_centerY_parent = self.contentView;
    self.downloadBtn.lim_left = self.lim_width - self.downloadBtn.lim_width - space;
}

- (UIImageView *)stickerImgView {
    if(!_stickerImgView) {
        _stickerImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
        _stickerImgView.layer.masksToBounds = YES;
        _stickerImgView.layer.cornerRadius = 4.0f;
    }
    return _stickerImgView;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.font = [[WKApp shared].config appFontOfSize:16.0f];
        _titleLbl.textColor = [[WKApp shared].config defaultTextColor];
    }
    return _titleLbl;
}
- (UILabel *)remarkLbl {
    if(!_remarkLbl) {
        _remarkLbl = [[UILabel alloc] init];
        _remarkLbl.font = [[WKApp shared].config appFontOfSize:12.0f];
        _remarkLbl.textColor = [[WKApp shared].config tipColor];
    }
    return _remarkLbl;
}

- (UIButton *)downloadBtn {
    if(!_downloadBtn) {
        _downloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 28.0f)];
        [_downloadBtn setTitle:@"添加" forState:UIControlStateNormal];
        _downloadBtn.layer.masksToBounds  = YES;
        _downloadBtn.layer.cornerRadius = 4.0f;
        [_downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [[_downloadBtn titleLabel] setFont:[[WKApp shared].config appFontOfSize:14.0f]];
        _downloadBtn.backgroundColor = [WKApp shared].config.themeColor;
        [_downloadBtn addTarget:self action:@selector(downloadPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadBtn;
}

-(void) downloadPressed {
    if(self.model.onAdd) {
        self.model.onAdd();
    }
}

@end
