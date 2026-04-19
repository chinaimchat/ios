//
//  LLLabelListCell.m
//  LLLabel
//
//  Created by LQ on 2020/12/9.
//

#import "LLLabelListCell.h"

@implementation LLLabelListModel

- (Class)cell {
    return LLLabelListCell.class;
}

- (NSNumber *)showArrow {
    return @(false);
}

@end

@interface LLLabelListCell ()

@property(nonatomic,strong) UILabel *titleLbl;
@property(nonatomic,strong) UILabel *descLbl;
@property(nonatomic,strong) LLLabelListModel *model;

@end

@implementation LLLabelListCell

+ (CGSize)sizeForModel:(WKFormItemModel *)model {
    return CGSizeMake(WKScreenWidth, 50.0f);
}

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.titleLbl];
    [self.contentView addSubview:self.descLbl];
}

- (void)refresh:(LLLabelListModel *)model {
    [super refresh:model];
    self.model = model;
    // 与 Android LabelAdapter：String.format("%s(%d)", name, count)
    self.titleLbl.text = [NSString stringWithFormat:@"%@(%d)", model.title ?: @"", (int)model.num.intValue];
    [self.titleLbl sizeToFit];
    self.descLbl.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLbl.lim_centerY_parent = self.contentView;
    self.titleLbl.lim_left = 15.0f;
    self.titleLbl.lim_width = self.contentView.lim_width - self.titleLbl.lim_left * 2.0f;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.font = [[WKApp shared].config appFontOfSize:16.0f];
        _titleLbl.textColor = [WKApp shared].config.defaultTextColor;
        _titleLbl.numberOfLines = 1;
        _titleLbl.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _titleLbl;
}

- (UILabel *)descLbl {
    if(!_descLbl) {
        _descLbl = [[UILabel alloc] init];
        _descLbl.font = [[WKApp shared].config appFontOfSize:16.0f];
        _descLbl.textColor =[WKApp shared].config.tipColor;
        _descLbl.numberOfLines = 1;
        _descLbl.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _descLbl;
}

@end
