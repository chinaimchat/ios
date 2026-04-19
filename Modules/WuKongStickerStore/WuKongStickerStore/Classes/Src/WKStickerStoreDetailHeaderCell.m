//
//  WKStickerStoreDetailHeaderCell.m
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import "WKStickerStoreDetailHeaderCell.h"

@implementation WKStickerStoreDetailHeaderModel

- (Class)cell {
    return WKStickerStoreDetailHeaderCell.class;
}

- (CGFloat)cellHeight {
    return 80.0f;
}

@end

@interface WKStickerStoreDetailHeaderCell ()

@property(nonatomic,strong) UILabel *titleLbl;
@property(nonatomic,strong) UILabel *remarkLbl;
@property(nonatomic,strong) UIButton *addBtn;

@property(nonatomic,strong) WKStickerStoreDetailHeaderModel *model;

@end

@implementation WKStickerStoreDetailHeaderCell


- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.titleLbl];
    [self.contentView addSubview:self.remarkLbl];
    [self.contentView addSubview:self.addBtn];
}

- (void)refresh:(WKStickerStoreDetailHeaderModel *)model {
    [super refresh:model];
    self.model  = model;
    
    self.titleLbl.text = model.title;
    [self.titleLbl sizeToFit];
    
    self.remarkLbl.text = model.remark;
    [self.remarkLbl sizeToFit];
    
    if(model.added) {
        [self.addBtn setBackgroundColor:[UIColor grayColor]];
        [self.addBtn setEnabled:NO];
        [self.addBtn setTitle:LLang(@"已添加") forState:UIControlStateNormal];
    }else{
        [self.addBtn setBackgroundColor:[WKApp shared].config.themeColor];
        [self.addBtn setEnabled:YES];
        [self.addBtn setTitle:LLang(@"添加") forState:UIControlStateNormal];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat remarkTopSpace = 5.0f;
    
    CGFloat contentHeight = self.titleLbl.lim_height + remarkTopSpace + self.remarkLbl.lim_height;
    
    self.titleLbl.lim_top = self.contentView.lim_height/2.0f - contentHeight/2.0f;
    self.titleLbl.lim_left = 15.0f;
    
    self.remarkLbl.lim_top = self.titleLbl.lim_bottom + 5.0f;
    self.remarkLbl.lim_left = self.titleLbl.lim_left;
    
    self.addBtn.lim_left = self.contentView.lim_width - self.addBtn.lim_width - 15.0f;
    self.addBtn.lim_top = self.titleLbl.lim_top;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.font = [[WKApp shared].config appFontOfSizeSemibold:18.0f];
        _titleLbl.textColor = [WKApp shared].config.defaultTextColor;
    }
    return _titleLbl;
}

- (UILabel *)remarkLbl {
    if(!_remarkLbl) {
        _remarkLbl = [[UILabel alloc] init];
        _remarkLbl.font = [[WKApp shared].config appFontOfSize:14.0f];
        _remarkLbl.textColor = [WKApp shared].config.tipColor;
    }
    return _remarkLbl;
}

- (UIButton *)addBtn {
    if(!_addBtn) {
        _addBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 30.0f)];
        _addBtn.layer.masksToBounds = YES;
        _addBtn.layer.cornerRadius = 4.0f;
        [_addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _addBtn.backgroundColor = [WKApp shared].config.themeColor;
        [_addBtn.titleLabel setFont:[[WKApp shared].config appFontOfSize:15.0f]];
        [_addBtn addTarget:self action:@selector(addPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

-(void) addPressed {
    if(self.model.onAdd) {
        self.model.onAdd();
    }
}

@end
