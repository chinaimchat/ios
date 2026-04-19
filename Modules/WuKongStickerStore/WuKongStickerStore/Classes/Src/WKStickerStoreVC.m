//
//  WKStickerStoreVC.m
//  WuKongBase
//
//  Created by tt on 2021/9/27.
//

#import "WKStickerStoreVC.h"

@interface WKStickerStoreVC ()

@end

@implementation WKStickerStoreVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [WKStickerStoreVM new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"表情商店");
}


@end
