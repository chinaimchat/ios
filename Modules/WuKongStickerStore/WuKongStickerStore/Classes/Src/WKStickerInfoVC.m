//
//  WKStickerInfoVC.m
//  WuKongBase
//
//  Created by tt on 2021/9/29.
//

#import "WKStickerInfoVC.h"
#import "WKStickerManager.h"
#import "WKStickerStoreDetailVC.h"
#import "WKStickerImageView.h"
@interface WKStickerInfoVC ()

@property(nonatomic,strong) WKStickerImageView *stickerImgView;

@property(nonatomic,strong) UIView *bottomView;

@property(nonatomic,strong) UIView *bottomContentView;

@property(nonatomic,strong) UIImageView *stickerIconImgView;
@property(nonatomic,strong) UILabel *stickerNameLbl;
@property(nonatomic,strong) UILabel *stickerRemarkLbl;
@property(nonatomic,strong) UIButton *addBtn;

@end

@implementation WKStickerInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.stickerImgView];
    
    [self.view addSubview:self.bottomView];
    [self.bottomView addSubview:self.bottomContentView];
    
    [self.bottomContentView addSubview:self.stickerIconImgView];
    [self.bottomContentView addSubview:self.stickerNameLbl];
    [self.bottomContentView addSubview:self.stickerRemarkLbl];
    [self.bottomContentView addSubview:self.addBtn];
    
    [self.view setBackgroundColor:[WKApp shared].config.backgroundColor];
    
    [self refresh:nil];
    
    if(self.category && self.category.length>0) {
        [self loadAndRefresh];
    }
   
}

-(void) loadAndRefresh {
    __weak typeof(self) weakSelf = self;
    [self request].then(^(WKStickerInfoResp *resp){
        [weakSelf refresh:resp];
    });
}

-(void) refresh:(WKStickerInfoResp*)resp {
    
    if(self.placeholderSvg) {
        self.stickerImgView.placehoderSvg = self.placeholderSvg;
    }
    self.stickerImgView.stickerURL = [[WKApp shared] getFileFullUrl:self.stickerURL];
    
  
    
    if(!resp) {
        self.bottomView.hidden = YES;
    }else{
        self.bottomView.hidden = NO;
        self.stickerNameLbl.text = resp.title;
        [self.stickerNameLbl sizeToFit];
        
        self.stickerRemarkLbl.text = resp.desc;
        [self.stickerRemarkLbl sizeToFit];
        
        [self.stickerIconImgView lim_setImageWithURL:[[WKApp shared] getFileFullUrl:resp.cover] placeholderImage:[WKApp shared].config.defaultStickerPlaceholder];
        
        if(resp.added) {
            [self.addBtn setBackgroundColor:[WKApp shared].config.tipColor];
            [self.addBtn setEnabled:NO];
            [self.addBtn setTitle:@"已添加" forState:UIControlStateNormal];
        }else{
            [self.addBtn setBackgroundColor:[WKApp shared].config.themeColor];
            [self.addBtn setEnabled:YES];
            [self.addBtn setTitle:@"添加" forState:UIControlStateNormal];
        }
        [self.addBtn addTarget:self action:@selector(addPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self layout];
}

-(void) addPressed {
    __weak typeof(self) weakSelf = self;
    [[WKStickerManager shared] addStickerWithCategory:self.category callback:^(NSError * _Nullable error) {
        if(!error) {
            [[WKStickerManager shared] loadUserCategory];
            [weakSelf loadAndRefresh];
        }
    }];
}

-(void) layout {
    self.stickerImgView.lim_centerX_parent = self.view;
    self.stickerImgView.lim_centerY_parent = self.view;
    
    self.bottomView.lim_top =WKScreenHeight - self.bottomView.lim_height;
    
    self.stickerIconImgView.lim_centerY_parent = self.bottomContentView;
    self.stickerIconImgView.lim_left = 15.0f;
    
    CGFloat remarkTopSpace = 4.0f;
    CGFloat contentHeight = self.stickerNameLbl.lim_height + remarkTopSpace + self.stickerRemarkLbl.lim_height;
    
    self.stickerNameLbl.lim_top = self.bottomContentView.lim_height/2.0f - contentHeight/2.0f;
    self.stickerNameLbl.lim_left = self.stickerIconImgView.lim_right + 15.0f;
    
    self.stickerRemarkLbl.lim_top = self.stickerNameLbl.lim_bottom + remarkTopSpace;
    self.stickerRemarkLbl.lim_left = self.stickerNameLbl.lim_left;
    
    self.addBtn.lim_left = self.bottomContentView.lim_width - self.addBtn.lim_width - 15.0f;
    self.addBtn.lim_centerY_parent = self.bottomContentView;
}

-(AnyPromise*) request {
   return [[WKAPIClient sharedClient] GET:@"sticker/user/sticker" parameters:@{@"category":self.category} model:WKStickerInfoResp.class];
}


- (WKStickerImageView *)stickerImgView {
    if(!_stickerImgView) {
        _stickerImgView = [[WKStickerImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 150.0f,  150.0f)];
    }
    return _stickerImgView;
}

- (UIView *)bottomView {
    if(!_bottomView) {
        _bottomView =[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, self.bottomContentView.lim_height+[WKApp shared].config.visibleEdgeInsets.bottom)];
        [_bottomView setBackgroundColor:[WKApp shared].config.cellBackgroundColor];
        _bottomView.userInteractionEnabled = YES;
        [_bottomView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomPressed)]];
        
    }
    return _bottomView;
}

-(void) bottomPressed {
    WKStickerStoreDetailVC *vc = [[WKStickerStoreDetailVC alloc] initWithCategory:self.category];
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

- (UIView *)bottomContentView {
    if(!_bottomContentView) {
        _bottomContentView =[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 80.0f)];
    }
    return _bottomContentView;
}

- (UIImageView *)stickerIconImgView {
    if(!_stickerIconImgView) {
        _stickerIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
    }
    return _stickerIconImgView;
}

- (UILabel *)stickerNameLbl {
    if(!_stickerNameLbl) {
        _stickerNameLbl = [[UILabel alloc] init];
    }
    return _stickerNameLbl;
}

- (UILabel *)stickerRemarkLbl {
    if(!_stickerRemarkLbl) {
        _stickerRemarkLbl = [[UILabel alloc] init];
        _stickerRemarkLbl.font = [[WKApp shared].config appFontOfSize:14.0f];
        [_stickerRemarkLbl setTextColor:[WKApp shared].config.tipColor];
    }
    return _stickerRemarkLbl;
}

- (UIButton *)addBtn {
    if(!_addBtn) {
        _addBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 30.0f)];
        _addBtn.layer.masksToBounds = YES;
        _addBtn.layer.cornerRadius = 4.0f;
        [_addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [[_addBtn titleLabel] setFont:[[WKApp shared].config appFontOfSize:14.0f]];
    }
    return _addBtn;
}



@end




@implementation WKStickerInfoResp

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKStickerInfoResp *resp = [WKStickerInfoResp new];
    resp.title = dictory[@"title"];
    resp.desc = dictory[@"desc"];
    resp.cover = dictory[@"cover"];
    resp.added = [dictory[@"added"] boolValue];
    return resp;
}

@end
