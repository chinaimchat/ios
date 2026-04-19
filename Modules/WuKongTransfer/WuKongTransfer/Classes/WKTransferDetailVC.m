#import "WKTransferDetailVC.h"
#import "WKTransferAPI.h"
#import "WKTransferLocalSync.h"
#import <WuKongBase/WKApp.h>
#import <WuKongIMSDK/WKMessageDB.h>

@interface WKTransferDetailVC ()

@property (nonatomic, copy) NSString *transferNo;
@property (nonatomic, copy, nullable) NSString *clientMsgNo;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *remarkLabel;
@property (nonatomic, strong) UIButton *acceptButton;

@end

@implementation WKTransferDetailVC

- (instancetype)initWithTransferNo:(NSString *)transferNo {
    return [self initWithTransferNo:transferNo clientMsgNo:nil];
}

- (instancetype)initWithTransferNo:(NSString *)transferNo clientMsgNo:(NSString *)clientMsgNo {
    if (self = [super init]) {
        self.transferNo = transferNo;
        self.clientMsgNo = clientMsgNo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"转账详情";
    self.view.backgroundColor = UIColor.whiteColor;

    CGFloat w = self.view.bounds.size.width;

    self.amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, w, 50)];
    self.amountLabel.textAlignment = NSTextAlignmentCenter;
    self.amountLabel.font = [UIFont boldSystemFontOfSize:36];
    self.amountLabel.textColor = [UIColor colorWithRed:0.98 green:0.60 blue:0.16 alpha:1.0];
    [self.view addSubview:self.amountLabel];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 180, w, 30)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.statusLabel];

    self.remarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, w - 40, 30)];
    self.remarkLabel.textAlignment = NSTextAlignmentCenter;
    self.remarkLabel.font = [UIFont systemFontOfSize:14];
    self.remarkLabel.textColor = [UIColor lightGrayColor];
    [self.view addSubview:self.remarkLabel];

    self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.acceptButton.frame = CGRectMake(40, 280, w - 80, 50);
    self.acceptButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.60 blue:0.16 alpha:1.0];
    self.acceptButton.layer.cornerRadius = 25;
    [self.acceptButton setTitle:@"收款" forState:UIControlStateNormal];
    self.acceptButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.acceptButton addTarget:self action:@selector(onAccept) forControlEvents:UIControlEventTouchUpInside];
    self.acceptButton.hidden = YES;
    [self.view addSubview:self.acceptButton];

    [self loadDetail];
}

- (void)loadDetail {
    [[WKTransferAPI shared] getTransferDetail:self.transferNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && !error) {
                double amount = [result[@"amount"] doubleValue];
                self.amountLabel.text = [NSString stringWithFormat:@"¥%.2f", amount];
                self.remarkLabel.text = result[@"remark"] ?: @"";

                int status = [result[@"status_code"] intValue];
                NSString *toUid = result[@"to_uid"] ?: @"";
                NSString *myUid = [WKApp shared].loginInfo.uid;

                switch (status) {
                    case 0:
                        self.statusLabel.text = @"待收款";
                        if ([toUid isEqualToString:myUid]) {
                            self.acceptButton.hidden = NO;
                        }
                        break;
                    case 1:
                        self.statusLabel.text = @"已收款";
                        self.acceptButton.hidden = YES;
                        break;
                    case 2:
                        self.statusLabel.text = @"已退回";
                        self.acceptButton.hidden = YES;
                        break;
                }

                if (self.clientMsgNo.length > 0) {
                    WKMessage *m = [[WKMessageDB shared] getMessageWithClientMsgNo:self.clientMsgNo];
                    if (m) {
                        WKTransferMessageStatus local = [WKTransferLocalSync transferStatusFromApiStatusCode:status];
                        [WKTransferLocalSync applyTransferStatus:local toTransferMessage:m];
                    }
                }
            }
        });
    }];
}

- (void)onAccept {
    [[WKTransferAPI shared] acceptTransfer:self.transferNo callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (self.clientMsgNo.length > 0) {
                    WKMessage *m = [[WKMessageDB shared] getMessageWithClientMsgNo:self.clientMsgNo];
                    if (m) {
                        [WKTransferLocalSync applyTransferStatus:WKTransferMessageStatusAccepted toTransferMessage:m];
                    }
                }
                [WKAlertUtil showMsg:@"收款成功"];
                [self loadDetail];
            } else {
                [WKAlertUtil showMsg:error.localizedDescription ?: @"收款失败"];
            }
        });
    }];
}

@end
