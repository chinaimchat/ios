//
//  WKCustomerServiceSettingVC.m
//  WuKongBase
//
//  Created by tt on 2022/4/3.
//

#import "WKCustomerServiceSettingVC.h"

@interface WKCustomerServiceSettingVC ()

@end

@implementation WKCustomerServiceSettingVC


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [WKCustomerServiceSettingVM new];
    }
    return self;
}

- (void)viewDidLoad {
    self.viewModel.channel = self.channel;
    
    [super viewDidLoad];
    
   
    
    [[WKSDK shared].channelManager fetchChannelInfo:self.channel];
}

@end
