//
//  LLLabelNameSettingCell.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelNameSettingCell.h"

@implementation LLLabelNameSettingModel

- (Class)cell {
    return LLLabelNameSettingCell.class;
}
- (NSNumber *)showArrow {
    return @(false);
}

@end

@interface LLLabelNameSettingCell ()

@property(nonatomic,strong) UILabel *titleLbl;

@end

@implementation LLLabelNameSettingCell

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.titleLbl];
}
- (void)refresh:(LLLabelNameSettingModel *)model {
    [super refresh:model];
    if(model.value && ![model.value isEqualToString:@""]) {
        self.titleLbl.text = model.value;
        self.titleLbl.textColor = [WKApp shared].config.defaultTextColor;
    }else{
        self.titleLbl.textColor = [WKApp shared].config.tipColor;
        self.titleLbl.text = LLang(@"未设置标签名字");
    }
    [self.titleLbl sizeToFit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLbl.lim_centerY_parent = self.contentView;
    self.titleLbl.lim_left = 15.0f;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.font = [[WKApp shared].config appFontOfSize:16.0f];
        _titleLbl.textColor = [WKApp shared].config.tipColor;
        _titleLbl.numberOfLines = 1;
    }
    return _titleLbl;
}

@end
