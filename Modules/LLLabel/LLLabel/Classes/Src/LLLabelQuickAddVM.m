//
//  LLLabelQuickAddVM.m
//  LLLabel
//
//  Created by LQ on 2023/2/21.
//

#import "LLLabelQuickAddVM.h"
#import "LLLabelNameSettingInputCell.h"

@interface LLLabelQuickAddVM ()



@end

@implementation LLLabelQuickAddVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    __weak typeof(self) weakSelf = self;
    return @[
        @{
            @"height":@(0.1f),
            @"title": LLang(@"分组名字"),
            @"items": @[
                    @{
                        @"class":LLLabelNameSettingInputModel.class,
                        @"value": self.labelName?:@"",
                        @"placeholder":LLang(@"未设置标签名字"),
                        @"showArrow":@(false),
                        @"onChange":^(NSString *value){
                            weakSelf.labelName = value;
                            if(weakSelf.onUpdateFinishBtn) {
                                weakSelf.onUpdateFinishBtn();
                            }
                        },
                    }
            ],
        }
    ];
}


-(AnyPromise*) finishLabel:(NSArray<NSString*>*)uids {
   
    return  [[WKAPIClient sharedClient] POST:@"label" parameters:@{
        @"name":self.labelName?:@"",
        @"member_uids": uids,
    }];
}

@end
