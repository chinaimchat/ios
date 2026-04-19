//
//  WKStickerStoreDetailVC.m
//  WuKongBase
//
//  Created by tt on 2021/9/28.
//

#import "WKStickerStoreDetailVC.h"

@interface WKStickerStoreDetailVC ()

@end

@implementation WKStickerStoreDetailVC

-(instancetype) initWithCategory:(NSString*)category
{
    self = [super init];
    if (self) {
        self.viewModel = [[WKStickerStoreDetailVM alloc] initWithCategory:category];
        
        __weak typeof(self) weakSelf = self;
        [self.viewModel setOnRequestFinished:^{
            weakSelf.title = weakSelf.viewModel.stickerPackage.title;
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.stickerName;
   
}


@end
