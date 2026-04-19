//
//  LLLabelQuickAddVC.m
//  LLLabel
//
//  Created by LQ on 2023/2/21.
//

#import "LLLabelQuickAddVC.h"

@interface LLLabelQuickAddVC ()

@end

@implementation LLLabelQuickAddVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [LLLabelQuickAddVM new];
    }
    return self;
}

- (void)viewDidLoad {
    
    __weak typeof(self) weakSelf =self;
    self.viewModel.onUpdateFinishBtn = ^{
        [weakSelf updateFinishBtn];
    };
    
    [super viewDidLoad];
    
    self.finishBtn.enabled = NO;
    self.rightView = self.finishBtn;
    
    [self.finishBtn addTarget:self action:@selector(finishedPressed) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void) finishedPressed {
    __weak typeof(self) weakSelf = self;
    [weakSelf.view showHUD];
    [self.viewModel finishLabel:self.uids].then(^(NSDictionary* resultDict){
        [weakSelf.view hideHud];
      
        [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_LABELLIST_REFRESH object:nil];
        
        if(weakSelf.onFinish) {
            weakSelf.onFinish(resultDict);
        }
    }).catch(^(NSError *error){
        [weakSelf.view switchHUDError:error.domain];
    });
}

- (void)reloadData {
    [super reloadData];
    [self updateFinishBtn];
}

-(void) updateFinishBtn {
    self.finishBtn.enabled = YES;
    if(!self.viewModel.labelName || [[self.viewModel.labelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        self.finishBtn.enabled = NO;
        return;
    }
}

@end
