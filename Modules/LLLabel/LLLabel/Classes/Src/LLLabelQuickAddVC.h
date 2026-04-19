//
//  LLLabelQuickAddVC.h
//  LLLabel
//
//  Created by LQ on 2023/2/21.
//

#import <WuKongBase/WuKongBase.h>
#import "LLLabelQuickAddVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface LLLabelQuickAddVC : WKBaseTableVC<LLLabelQuickAddVM*>

@property(nonatomic,strong) NSArray<NSString*> *uids;

@property(nonatomic,strong) void(^onFinish)(NSDictionary*result);


@end

NS_ASSUME_NONNULL_END
