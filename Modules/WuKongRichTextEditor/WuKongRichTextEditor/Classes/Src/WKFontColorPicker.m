//
//  WKFontColorPicker.m
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/22.
//

#import "WKFontColorPicker.h"
#import <WuKongBase/WuKongBase.h>

#define fontColorItemWidth 32.0f
#define fontColorItemSpace  10.0f

@interface WKFontColorPicker ()

@property(nonatomic,strong) UIView *colorBoxView;

@property(nonatomic,strong) NSMutableArray<UIColor*> *colors;

@end

@implementation WKFontColorPicker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0.0f, 0.0f, (fontColorItemWidth + fontColorItemSpace)*self.colors.count + fontColorItemSpace, 50.0f);
        [self addSubview:self.colorBoxView];
        
        NSInteger i = 0;
        for (UIColor *color in self.colors) {
            [self.colorBoxView addSubview:[[WKFontColorItem alloc] initWithColor:color onClick:^{
                if(self.onSelected) {
                    self.onSelected(i==0?nil:color);
                    
                }
            }]];
            i++;
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.colorBoxView.frame = self.bounds;
    
    NSArray *subviews = self.colorBoxView.subviews;
    UIView *preView;
    CGFloat space = fontColorItemSpace;
    for (UIView *view in subviews) {
        view.lim_left = space;
        view.lim_centerY_parent = self;
        if(preView) {
            view.lim_left = preView.lim_right + space;
        }
        preView = view;
    }
    if(preView) {
        self.colorBoxView.lim_width = preView.lim_right;
    }
}

- (UIView *)colorBoxView {
    if(!_colorBoxView) {
        _colorBoxView = [[UIView alloc] init];
    }
    return _colorBoxView;
}

- (NSMutableArray<UIColor *> *)colors {
    if(!_colors) {
        UIColor *firstColor;
        if(WKApp.shared.config.style == WKSystemStyleDark) {
            firstColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]; 
        } else {
            firstColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
        }
        _colors = [NSMutableArray arrayWithArray:@[firstColor,[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f],[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f]]];
    }
    return _colors;
}

@end

@interface WKFontColorItem ()

@property (nonatomic, strong) UIView *colorBoxView;

@property(nonatomic,strong) UIImageView *iconImgView;

@property(nonatomic,copy) void(^onClick)(void);

@end

@implementation WKFontColorItem

-(instancetype) initWithColor:(UIColor*)color onClick:(void(^)(void))onClick{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0.0f, 0.0f, fontColorItemWidth, fontColorItemWidth);
        self.color = color;
        self.onClick = onClick;
        [self addSubview:self.colorBoxView];
        [self.colorBoxView addSubview:self.iconImgView];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)]];
    }
    return self;
}

-(void) onTap {
    if(self.onClick) {
        self.onClick();
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.colorBoxView.frame = self.bounds;
    self.iconImgView.lim_centerX_parent = self;
    self.iconImgView.lim_centerY_parent = self;
    
}

-(UIView*) colorBoxView {
    if(!_colorBoxView) {
        _colorBoxView = [[UIView alloc] init];
        _colorBoxView.layer.masksToBounds = YES;
//        _colorBoxView.layer.cornerRadius = 2.0f;
//        _colorBoxView.layer.borderWidth = 1.0f;
//        _colorBoxView.layer.borderColor = [WKApp.shared.config lineColor].CGColor;
    }
    return _colorBoxView;
}

- (UIImageView *)iconImgView {
    if(!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
        
        UIImage *img =  [[self imageName:@"ColorPickerItem"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_iconImgView setImage:img];
        _iconImgView.tintColor = self.color;
        
    }
    return _iconImgView;
}


-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRichTextEditor"];
}

@end
