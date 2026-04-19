//
//  WKCustomerServiceSettingVC.h
//  WuKongBase
//
//  Created by tt on 2022/4/3.
//

#import <WuKongBase/WuKongBase.h>
#import "WKCustomerServiceSettingVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKCustomerServiceSettingVC : WKBaseTableVC<WKCustomerServiceSettingVM*>

@property(nonatomic,strong) WKChannel *channel;

@end

NS_ASSUME_NONNULL_END
