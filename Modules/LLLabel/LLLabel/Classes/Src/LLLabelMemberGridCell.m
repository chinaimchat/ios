//
//  LLLabelMemberGridCell.m
//  LLLabel
//

#import "LLLabelMemberGridCell.h"
#import "LLLabelAddVM.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

static NSInteger const kLLLabelMemberGridColumns = 5;
static CGFloat const kLLLabelMemberRowHeight = 76.0f;
static CGFloat const kLLLabelMemberAvatar = 44.0f;
static CGFloat const kLLLabelMemberLineSpacing = 12.0f;
static CGFloat const kLLLabelMemberInterItem = 8.0f;

static NSString *const kLLLabelMemCVReuse = @"LLLabelMemCV";
static NSString *const kLLLabelAddCVReuse = @"LLLabelAddCV";

@implementation LLLabelMemberGridModel

- (Class)cell {
    return LLLabelMemberGridCell.class;
}

- (NSNumber *)showArrow {
    return @(NO);
}

+ (CGFloat)heightForMemberCount:(NSInteger)count tableWidth:(CGFloat)width {
    (void)width;
    UIEdgeInsets inset = [self gridSectionInset];
    NSInteger slots = count + 1;
    NSInteger rows = (slots + kLLLabelMemberGridColumns - 1) / kLLLabelMemberGridColumns;
    if (rows < 1) {
        rows = 1;
    }
    return inset.top + inset.bottom + (CGFloat)rows * kLLLabelMemberRowHeight + MAX(0, rows - 1) * kLLLabelMemberLineSpacing;
}

+ (UIEdgeInsets)gridSectionInset {
    return UIEdgeInsetsMake(10.0f, 12.0f, 14.0f, 12.0f);
}

@end

#pragma mark - Collection cells

@interface LLLabelMemberAvatarCVCell : UICollectionViewCell

- (void)configureWithChannel:(WKChannelInfo *)info removeHandler:(void (^)(void))removeHandler;

@end

@interface LLLabelMemberAddCVCell : UICollectionViewCell
@end

@interface LLLabelMemberAvatarCVCell ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *removeBtn;
@property (nonatomic, copy) void (^removeTap)(void);

@end

@implementation LLLabelMemberAvatarCVCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.removeBtn];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.removeTap = nil;
}

- (void)configureWithChannel:(WKChannelInfo *)info removeHandler:(void (^)(void))removeHandler {
    self.removeTap = removeHandler;
    NSString *urlStr = info.channel.channelType == WK_GROUP ? [WKAvatarUtil getGroupAvatar:info.channel.channelId] : [WKAvatarUtil getAvatar:info.channel.channelId];
    [self.avatarView lim_setImageWithURL:[NSURL URLWithString:urlStr ?: @""] placeholderImage:[WKApp shared].config.defaultAvatar];
    self.nameLabel.text = info.displayName ?: @"";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    self.avatarView.frame = CGRectMake(floor((w - kLLLabelMemberAvatar) / 2.0f), 0.0f, kLLLabelMemberAvatar, kLLLabelMemberAvatar);
    self.avatarView.layer.cornerRadius = kLLLabelMemberAvatar / 2.0f;
    self.removeBtn.frame = CGRectMake(CGRectGetMaxX(self.avatarView.frame) - 14.0f, CGRectGetMinY(self.avatarView.frame) - 4.0f, 22.0f, 22.0f);
    self.nameLabel.frame = CGRectMake(2.0f, CGRectGetMaxY(self.avatarView.frame) + 4.0f, w - 4.0f, self.contentView.bounds.size.height - CGRectGetMaxY(self.avatarView.frame) - 4.0f);
}

- (void)onRemove:(UIButton *)sender {
    (void)sender;
    if (self.removeTap) {
        self.removeTap();
    }
}

- (UIImageView *)avatarView {
    if (!_avatarView) {
        _avatarView = [[UIImageView alloc] init];
        _avatarView.clipsToBounds = YES;
        _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _avatarView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [[WKApp shared].config appFontOfSize:11.0f];
        _nameLabel.textColor = [WKApp shared].config.defaultTextColor;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.numberOfLines = 2;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nameLabel;
}

- (UIButton *)removeBtn {
    if (!_removeBtn) {
        _removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _removeBtn.backgroundColor = [UIColor colorWithWhite:0.35f alpha:0.92f];
        _removeBtn.layer.cornerRadius = 11.0f;
        _removeBtn.layer.masksToBounds = YES;
        [_removeBtn setTitle:@"−" forState:UIControlStateNormal];
        [_removeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _removeBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
        [_removeBtn addTarget:self action:@selector(onRemove:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _removeBtn;
}

@end

@implementation LLLabelMemberAddCVCell {
    UIImageView *_addIcon;
    UIView *_circle;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _circle = [[UIView alloc] init];
        _circle.backgroundColor = [WKApp shared].config.style == WKSystemStyleDark ? [UIColor colorWithWhite:0.22f alpha:1.0f] : [UIColor colorWithWhite:0.94f alpha:1.0f];
        _circle.layer.cornerRadius = kLLLabelMemberAvatar / 2.0f;
        _circle.layer.masksToBounds = YES;
        [self.contentView addSubview:_circle];
        _addIcon = [[UIImageView alloc] init];
        _addIcon.contentMode = UIViewContentModeCenter;
        _addIcon.image = [[WKApp shared] loadImage:@"Add" moduleID:@"LLLabel"];
        [self.contentView addSubview:_addIcon];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    _circle.frame = CGRectMake(floor((w - kLLLabelMemberAvatar) / 2.0f), 0.0f, kLLLabelMemberAvatar, kLLLabelMemberAvatar);
    _addIcon.frame = _circle.frame;
}

@end

#pragma mark - Grid table cell

@interface LLLabelMemberGridCell () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) LLLabelMemberGridModel *gridModel;

@end

@implementation LLLabelMemberGridCell

+ (CGSize)sizeForModel:(WKFormItemModel *)model {
    return CGSizeMake(WKScreenWidth, model.cellHeight);
}

- (void)setupUI {
    [super setupUI];
    self.arrowImgView.hidden = YES;
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.minimumLineSpacing = kLLLabelMemberLineSpacing;
    flow.minimumInteritemSpacing = kLLLabelMemberInterItem;
    flow.sectionInset = [LLLabelMemberGridModel gridSectionInset];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.scrollEnabled = NO;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:LLLabelMemberAvatarCVCell.class forCellWithReuseIdentifier:kLLLabelMemCVReuse];
    [_collectionView registerClass:LLLabelMemberAddCVCell.class forCellWithReuseIdentifier:kLLLabelAddCVReuse];
    [self.contentView addSubview:_collectionView];
}

- (void)refresh:(LLLabelMemberGridModel *)model {
    [super refresh:model];
    self.gridModel = model;
    self.arrowImgView.hidden = YES;
    [self.collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.frame = self.contentView.bounds;
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat W = self.collectionView.bounds.size.width;
    if (W <= 0) {
        return;
    }
    UIEdgeInsets inset = flow.sectionInset;
    CGFloat usable = W - inset.left - inset.right - kLLLabelMemberInterItem * (CGFloat)(kLLLabelMemberGridColumns - 1);
    CGFloat itemW = floor(usable / (CGFloat)kLLLabelMemberGridColumns);
    flow.itemSize = CGSizeMake(itemW, kLLLabelMemberRowHeight);
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    (void)collectionView;
    (void)section;
    LLLabelAddVM *vm = self.gridModel.addVM;
    if (!vm) {
        return 0;
    }
    return (NSInteger)vm.memberItems.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LLLabelAddVM *vm = self.gridModel.addVM;
    if (!vm) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:kLLLabelAddCVReuse forIndexPath:indexPath];
    }
    if (indexPath.item < (NSInteger)vm.memberItems.count) {
        LLLabelMemberAvatarCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kLLLabelMemCVReuse forIndexPath:indexPath];
        WKChannelInfo *info = vm.memberItems[(NSUInteger)indexPath.item];
        NSInteger idx = indexPath.item;
        __weak typeof(self) weakSelf = self;
        [cell configureWithChannel:info removeHandler:^{
            [weakSelf.gridModel.addVM removeMember:idx];
        }];
        return cell;
    }
    return [collectionView dequeueReusableCellWithReuseIdentifier:kLLLabelAddCVReuse forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    LLLabelAddVM *vm = self.gridModel.addVM;
    if (!vm) {
        return;
    }
    if (indexPath.item < (NSInteger)vm.memberItems.count) {
        WKChannelInfo *info = vm.memberItems[(NSUInteger)indexPath.item];
        if (info.channel.channelType == WK_PERSON) {
            [[WKApp shared] invoke:WKPOINT_USER_INFO param:@{ @"uid": info.channel.channelId ?: @"" }];
        }
    } else {
        [vm openMemberPicker];
    }
}

@end
