//
//  WKStickerCollectedContentView.m
//  WuKongBase
//
//  Created by apple-2 on 2021/10/21.
//

#import "WKStickerCollectedContentView.h"
#import "WKCollectionViewGridLayout.h"
#import "WKStickerGIFCell.h"
#import "WKStickerPackage.h"
#import "WKLottieStickerContent.h"
#import "WKStickerCollectAddCell.h"
#import "WKGIFContent.h"

@interface WKStickerCollectedContentView () <UICollectionViewDataSource,UICollectionViewDelegate>

@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) WKCollectionViewGridLayout *newGridLayout;
@property(nonatomic, copy) NSString *notiName;
@property(nonatomic,assign) BOOL selectedInner;

@end


@implementation WKStickerCollectedContentView

//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        [self establishControlsInLIMStickerCollectedContentView];
//    }
//    return self;
//}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self establishControlsInLIMStickerCollectedContentView];
    }
    return self;
}

- (void)dealloc {
    
}


- (void)setSelected:(BOOL)selected {
    BOOL change = self.selectedInner != selected;
    self.selectedInner = selected;
    if(change) {
        [self.collectionView reloadData];
    }
}
- (BOOL)selected {
    return self.selectedInner;
}



#pragma mark -> Controls
- (void)establishControlsInLIMStickerCollectedContentView {
    [self setBackgroundColor:[UIColor clearColor]];
    _modelsArray = @[];
    [self addSubview:self.collectionView];
    [self requestStickerCollectedEmojis];
    _notiName = @"RefreshStickerColllected";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStickerCollection:)
                                                 name:_notiName object:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _collectionView.lim_size = self.lim_size;
}

- (WKCollectionViewGridLayout *)newGridLayout {
    if (!_newGridLayout) {
        _newGridLayout = [WKCollectionViewGridLayout new];
        _newGridLayout.itemSpacing = 5;
        _newGridLayout.lineSpacing = 5;
        _newGridLayout.lineSize = 0;
        _newGridLayout.lineItemCount = 4;
        _newGridLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _newGridLayout.sectionsStartOnNewLine = NO;
    }
    return _newGridLayout;
}

- (UICollectionView *)collectionView {
    if(!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:self.newGridLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView setBackgroundColor:[UIColor clearColor]];
        [_collectionView setContentInset:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        [_collectionView registerClass:[WKStickerGIFCell class] forCellWithReuseIdentifier:[WKStickerGIFCell reuseIdentifier]];
        [_collectionView registerClass:[WKStickerCollectAddCell class] forCellWithReuseIdentifier:[WKStickerCollectAddCell reuseIdentifier]];
    }
    return _collectionView;
}


#pragma mark -> Delegates
#pragma mark -> UICollectionViewDataSource && UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _modelsArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id cellModel =   _modelsArray[indexPath.row];
    NSString *identifier;
    if([cellModel isKindOfClass:[WKStickerCollectAddCellModel class]]) { // add
        identifier = [WKStickerCollectAddCell reuseIdentifier];
    }else {
        identifier = [WKStickerGIFCell reuseIdentifier];
    }
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    if([cell isKindOfClass:[WKStickerGIFCell class]]) {
        ((WKStickerGIFCell*)cell).allowLongPress = true;
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(WKStickerGIFCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    id cellModel =   _modelsArray[indexPath.row];
    if([cellModel isKindOfClass:[WKStickerCollectAddCellModel class]]) { // add
        
    }else {
        WKSticker *sticker = (WKSticker*)cellModel;
        sticker.isPlay = self.selected;
        [cell refresh:sticker];
    }
//    [cell setResp:resp];
//
//    if (resp.isDefault) {
//        UIImage *img = [[WKResource shared] resourceForImage:resp.defaultName podName:@"WuKongBase_images"];
//        [cell setDefaultAddImage:img];
//    }
//    else {
//        [cell setGifURL:[[WKApp shared] getFileFullUrl:resp.path]];
//    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id cellModel =  _modelsArray[indexPath.row];
    if([cellModel isKindOfClass:[WKStickerCollectAddCellModel class]]) { // add
        if (self.stickerCollected) {
            self.stickerCollected(self.modelsArray);
        }
    }else{ // send gif/sticker
        WKSticker *sticker = (WKSticker*)cellModel;
        WKMessageContent *messageContent;
        if([sticker.format isEqualToString:@"lim"]) {
            WKLottieStickerContent *content = [WKLottieStickerContent new];
            content.format = sticker.format;
            content.url = sticker.path;
            content.category = sticker.category;
            
            messageContent = content;
        }else{
            messageContent = [WKGIFContent initWithURL:sticker.path width:sticker.width?sticker.width.integerValue:0 height:sticker.height?sticker.height.integerValue:0];
        }
        [self.context sendMessage:messageContent];
    }
}


#pragma mark -> Events


#pragma mark -> Private Methods
- (void)requestStickerCollectedEmojis {
    __weak typeof(self) weakSelf = self;
    [WKApp.shared loadCollectStickers].then(^(NSArray<WKSticker*> *collectStickers){
        NSMutableArray *array = @[[self setDefaultSticker]].mutableCopy;
        [array addObjectsFromArray:collectStickers];
        weakSelf.modelsArray = array;
        [weakSelf.collectionView reloadData];
    });
}

- (WKStickerCollectAddCellModel *)setDefaultSticker {
    WKStickerCollectAddCellModel *defaultModel = [WKStickerCollectAddCellModel new];
//    defaultModel.isDefault = YES;
//    defaultModel.defaultName = @"icon_emoji_CollecetNew";
    return defaultModel;
}

//刷新管理页面新增、删除后的数据
- (void)refreshStickerCollection:(NSNotification *)noti {
    [self requestStickerCollectedEmojis];
}


#pragma mark -> Public Methods
- (UIImage *)tabIcon {
    return [WKApp.shared loadImage:@"Conversation/Panel/Collection" moduleID:@"WuKongBase"];
}

- (void)setModelsArray:(NSArray *)modelsArray {
    _modelsArray = modelsArray;
    [_collectionView reloadData];
}

@end
