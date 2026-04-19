//
//  WKStickerStoreContentCell.m
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import "WKStickerStoreContentCell.h"
#import "WKStickerImageView.h"

@implementation WKStickerStoreContentModel

- (Class)cell {
    return WKStickerStoreContentCell.class;
}

@end

@interface WKStickerStoreContentCell ()

@property(nonatomic,strong) UIView *contentBoxView;

@property(nonatomic,strong) WKStickerStoreContentModel *model;

@end

#define stickerItemSize CGSizeMake(80.0f,80.0f)

#define stickerItemInsets UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)

#define stickerNumOfRow 4 // 每行数量

@implementation WKStickerStoreContentCell

+ (CGSize)sizeForModel:(WKStickerStoreContentModel *)model {
    
    NSInteger row =  [self getRow:model.list.count];
    return CGSizeMake(WKScreenWidth, row*(stickerItemSize.height+stickerItemInsets.top+stickerItemInsets.bottom));
}


- (void)onWillDisplay {
    [super onWillDisplay];
    for (WKStickerImageView *stickerImgView in  self.contentBoxView.subviews) {
        stickerImgView.isPlay = true;
    }
}

- (void)onEndDisplay {
    [super onEndDisplay];
    for (WKStickerImageView *stickerImgView in  self.contentBoxView.subviews) {
        stickerImgView.isPlay = false;
    }
}

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.contentBoxView];
}

- (void)refresh:(WKStickerStoreContentModel *)model {
    [super refresh:model];
    self.model = model;
    [self.contentBoxView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if(model.list && model.list.count>0) {
        for (WKSticker *sticker in model.list) {
            [self.contentBoxView addSubview:[self newStickerImgView:sticker]];
        }
    }
    
    self.contentBoxView.lim_width = (stickerItemSize.height + stickerItemInsets.top + stickerItemInsets.bottom) * stickerNumOfRow;
    
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
   NSArray *subviews = self.contentBoxView.subviews;
    
    
    NSInteger currentRow = 0;
    NSInteger currentCol = 0;
    NSInteger i = 0;
    UIView *lastView;
    for (UIView *view in subviews) {
        if(i%stickerNumOfRow == 0) {
            currentRow++;
            currentCol = 0;
        }
        currentCol++;
        
        view.lim_left = (currentCol - 1)*(stickerItemSize.width+stickerItemInsets.left + stickerItemInsets.right);
        view.lim_top = (currentRow-1) * (stickerItemSize.height + stickerItemInsets.top + stickerItemInsets.bottom);
        
        i++;
        
        lastView = view;
    }
    
    self.contentBoxView.lim_height = lastView.lim_bottom;
    
    self.contentBoxView.lim_centerX_parent = self.contentView;
    
}

- (UIView *)contentBoxView {
    if(!_contentBoxView) {
        _contentBoxView = [[UIView alloc] init];
    }
    return _contentBoxView;
}

+(NSInteger) getRow:(NSInteger)count {
    NSInteger row =  count / stickerNumOfRow;
     if(count % stickerNumOfRow !=0) {
         row++;
     }
    return row;
}



-(WKStickerImageView*) newStickerImgView:(WKSticker*)sticker {
    WKStickerImageView *imgView  = [[WKStickerImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, stickerItemSize.width, stickerItemSize.height)];
    imgView.placehoderSvg = sticker.placeholder;
    imgView.stickerURL = [[WKApp shared] getFileFullUrl:sticker.path];
    
    return imgView;
}

@end
