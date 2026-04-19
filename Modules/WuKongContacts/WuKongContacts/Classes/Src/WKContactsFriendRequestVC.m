//
//  WKContactsFriendRequestVC.m
//  WuKongContacts
//
//  Created by tt on 2020/1/5.
//

#import "WKContactsFriendRequestVC.h"
#import "WKContactsFriendRequestCell.h"
#import "WKContactsSync.h"
@interface WKContactsFriendRequestVC ()<UITableViewDataSource,UITableViewDelegate,WKContactsManagerDelegate>

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray<WKFriendRequestDBModel*> *items;
@property(nonatomic,strong) UIButton *addFriendBtn;

@end

@implementation WKContactsFriendRequestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.items =  [NSMutableArray arrayWithArray:[[WKContactsManager shared] getAllFriendRequest]];
    self.rightView = self.addFriendBtn;
    
    [[WKContactsManager shared] addDelegate:self];
}

- (void)dealloc{
    [[WKContactsManager shared] removeDelegate:self];
}

- (NSString *)langTitle {
    return LLang(@"新的朋友");
}

// 右上角更多按钮
-(UIButton*) addFriendBtn {
    if(!_addFriendBtn) {
        _addFriendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_addFriendBtn addTarget:self action:@selector(addFriendPressed) forControlEvents:UIControlEventTouchUpInside];
        _addFriendBtn.frame = CGRectMake(0 , 0, 110, 44);
        [_addFriendBtn setTitle:LLang(@"添加朋友") forState:UIControlStateNormal];
        [[_addFriendBtn titleLabel] setFont:[[WKApp shared].config appFontOfSize:15.0f]];
        [_addFriendBtn setTitleColor:[WKApp shared].config.navBarButtonColor forState:UIControlStateNormal];
//       _moreButtonItem =[[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _addFriendBtn;
}

-(void) addFriendPressed {
    [[WKApp shared] invoke:WKPOINT_CONVERSATION_ADDCONTACTS param:nil];
}

// 确认邀请（先输入可选自我介绍，再提交 friend/sure）
-(void) requestFriendSure:(WKFriendRequestDBModel*)model {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LLang(@"同意加好友") message:LLang(@"可填写向对方展示的自我介绍，不填则使用默认") preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *tf = alertController.textFields.firstObject;
        NSString *remark = [[tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
        if (remark.length > 100) {
            remark = [remark substringToIndex:100];
        }
        [weakSelf submitFriendSure:model remark:remark];
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LLang(@"自我介绍（选填）");
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) submitFriendSure:(WKFriendRequestDBModel*)model remark:(NSString*)remark {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:model.token forKey:@"token"];
    if (remark.length > 0) {
        params[@"remark"] = remark;
    }
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] POST:@"friend/sure" parameters:params].then(^(){
        // 更新状态
        [[WKContactsManager shared] updateFriendRequestStatus:model.uid status:WKFriendRequestStatusSured];
        [weakSelf startSyncContacts:model.uid];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }).catch(^(NSError *err){
        [weakSelf.view showMsg:err.domain];
    });
}

// 开始同步联系人
-(void) startSyncContacts:(NSString*)uid {
    [[[WKContactsSync alloc] init] sync:^(NSError *error) {
        [[WKSDK shared].channelManager fetchChannelInfo:[WKChannel personWithChannelID:uid]];
    }];
}

#pragma mark - table
-(UITableView *)tableView{
    if(!_tableView){
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect]];
        [_tableView setBackgroundColor:[UIColor redColor]];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        UIEdgeInsets separatorInset   = _tableView.separatorInset;
        separatorInset.right          = 0;
        _tableView.separatorInset = separatorInset;
        _tableView.backgroundColor=[UIColor clearColor];
        
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [_tableView registerClass:WKContactsFriendRequestCell.class forCellReuseIdentifier:[WKContactsFriendRequestCell cellId]];
        
    }
    return _tableView;
}

- (void)viewConfigChange:(WKViewConfigChangeType)type {
    [super viewConfigChange:type];
    if(type == WKViewConfigChangeTypeStyle) {
        [self.addFriendBtn setTitleColor:[WKApp shared].config.defaultTextColor forState:UIControlStateNormal];
    }
}

#pragma mark -- WKContactsManagerDelegate

-(void) contactsManager:(WKContactsManager*)manager lastFriendRequest:(WKFriendRequestDBModel*)friendRequestDBModel {
    self.items =  [NSMutableArray arrayWithArray: [[WKContactsManager shared] getAllFriendRequest]];
    [self.tableView reloadData];
}

-(void) contactsManager:(WKContactsManager *)manager friendAccepted:(NSDictionary*)param {
    NSString *toUID = param[@"to_uid"];
    if(!toUID || [toUID isEqualToString:@""]) {
        return;
    }
    self.items =  [NSMutableArray arrayWithArray:[[WKContactsManager shared] getAllFriendRequest]];
    for (WKFriendRequestDBModel *model in self.items) {
        if([model.uid isEqualToString:toUID]) {
            model.status = WKFriendRequestStatusSured;
            model.readed = 1;
        }
    }
    [self.tableView reloadData];
    
}


#pragma mark - UITableViewDataSource,UITableViewDelegate

#pragma mark UITableDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.items.count;
}
-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKFriendRequestDBModel *model = self.items[indexPath.row];
    WKContactsFriendRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKContactsFriendRequestCell cellId]];
    cell.first = indexPath.row == 0;
    cell.last = self.items.count-1 == indexPath.row;
    __weak typeof(self) weakSelf = self;
    [cell setOnPass:^(WKFriendRequestDBModel * _Nonnull model) {
        [weakSelf requestFriendSure:model];
    }];
    [cell refresh:model];
    return cell;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return  80.0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        WKFriendRequestDBModel *model = self.items[indexPath.row];
        [[WKFriendRequestDB shared] deleteFriendRequest:model.uid];
        [self.items removeObject:model];
        [self.tableView reloadData];
        
    }
}

@end
