//
//  LLLabelNameSettingInputCell.m
//  LLBase
//
//  Created by LQ on 2022/11/21.
//

#import "LLLabelNameSettingInputCell.h"

@implementation LLLabelNameSettingInputModel

- (Class)cell {
    return LLLabelNameSettingInputCell.class;
}

@end

@interface LLLabelNameSettingInputCell ()

@property(nonatomic,strong) UITextField *textfield;
@property(nonatomic,strong) LLLabelNameSettingInputModel *labelNameSettingInputModel;

@end

@implementation LLLabelNameSettingInputCell

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.textfield];
}
- (void)refresh:(LLLabelNameSettingInputModel *)model {
    [super refresh:model];
    self.labelNameSettingInputModel = model;
    self.textfield.placeholder = model.placeholder;
    self.textfield.text = model.value;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textfield.frame = self.contentView.bounds;
    self.textfield.lim_left = 15.0f;
}

- (UITextField *)textfield {
    if(!_textfield) {
        _textfield = [[UITextField alloc] init];
        [_textfield addTarget:self action:@selector(valueChange) forControlEvents:UIControlEventEditingChanged];
       
    }
    return _textfield;
}

-(void) valueChange {
    if(self.labelNameSettingInputModel.onChange) {
        self.labelNameSettingInputModel.onChange(self.textfield.text);
    }
}

@end
