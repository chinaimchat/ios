//
//  WKFavoriteVC.m
//  WuKongFavorite
//
//  Created by tt on 2020/7/14.
//

#import "WKFavoriteVC.h"
#import "WKFavoriteVM.h"
#import "WKFavoriteCell.h"
@interface WKFavoriteVC ()

@end

@implementation WKFavoriteVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [WKFavoriteVM new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak typeof(self) weakSelf = self;
    self.viewModel.onMore = ^(WKFavoriteModel * _Nonnull model) {
        WKActionSheetView2 *sheetView = [WKActionSheetView2 initWithTip:nil];
        
        BOOL showSendFriend = true;
        
        if(model.type == WKFavoriteTypeSingleImage) {
            UIImage *image = model.getOneImage();
            if(!image) {
                showSendFriend = false;
            }
        }
        
        if(showSendFriend) {
            [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLangW(@"发送给朋友",weakSelf) onClick:^{
                WKMessageContent *messageContent;
                if(model.type == WKFavoriteTypeText) {
                    NSString *text = model.payload[@"content"];
                    messageContent = [[WKTextContent alloc] initWithContent:text];
                    
                } if(model.type == WKFavoriteTypeSingleImage) {
                    UIImage *image = model.getOneImage();
                    messageContent = [WKImageContent initWithImage:image];
                }
                if(messageContent) {
                    [[WKMessageActionManager shared] sendContentToFriend:messageContent complete:nil];
                }
            }]];
        }
        
        if(model.type == WKFavoriteTypeText) {
            [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLangW(@"复制",weakSelf) onClick:^{
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                NSString *text = model.payload[@"content"];
                pasteboard.string = text;
                UIView *topView = [WKNavigationManager shared].topViewController.view;
                [topView showHUDWithHide:LLangW(@"已复制", weakSelf)];
            }]];
        }
       
        [sheetView addItem:[WKActionSheetButtonItem2 initWithTitle:LLangW(@"删除",weakSelf) onClick:^{
            [weakSelf.viewModel favoriteDelete:model.no].then(^{
                [weakSelf reloadRemoteData];
            });
        }]];
        [sheetView show];
    };
}

- (NSString *)langTitle {
    return LLang(@"我的收藏");
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLang(@"删除") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        WKFavoriteModel *data = (WKFavoriteModel*)[self.items objectAtIndex:indexPath.section].items[indexPath.row];
        [self.viewModel favoriteDelete:data.no].then(^{
            [weakSelf reloadRemoteData];
        });
        
    }];
    
    return @[action];
}

@end
