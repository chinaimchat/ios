//
//  AppDelegate.m
//  TangSengDaoDao
//
//  Created by tt on 2019/11/30.
//  Copyright © 2019 xinbida. All rights reserved.
//

#import "AppDelegate.h"
@import WuKongBase;
#import "WKMainTabController.h"
@import WuKongContacts;
@import WuKongTransfer;
@import WuKongRedPackets;
@import WuKongWallet;
@import WuKongPinned;
@import WuKongCustomerService;
@import WuKongRichTextEditor;
@import LLLabel;
#import "WKMeVC.h"

#import "SELUpdateAlert.h"


// 多域名入口：与 Android / Web 侧保持一致，具体 host 由 WKApiHostPool 从 11 个候选中选出（首次启动随机一个）。
// 运行期失败时 WKAPIClient 会按池顺序自动切换下一个健康域名；不再把单一主域写死在此处。
#define HTTPS_ON true // https开关





@interface AppDelegate ()<UITabBarControllerDelegate>

@property(nonatomic,strong) WKConversationListVC *conversationList;
//@property(nonatomic,strong)  WKContactsVC *contactVC;
@property(nonatomic,strong) WKMeVC *meVC;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor grayColor];
    [self.window makeKeyAndVisible];

    // 加载登录信息
    [[WKApp shared].loginInfo load];

    // 多域名入口：从池中取当前首选 host 拼 base URL；运行期由 WKAPIClient 的故障切换自动跟随。
    NSString *scheme = HTTPS_ON ? @"https" : @"http";
    NSString *preferredHost = [WKApiHostPool preferredHost];
    NSString *baseURL = [NSString stringWithFormat:@"%@://%@/v1/", scheme, preferredHost];
    NSString *webURL  = [NSString stringWithFormat:@"%@://%@/web/", scheme, preferredHost];
    NSString *wsURL   = [NSString stringWithFormat:@"wss://%@/ws", preferredHost];

    // app配置
    WKAppConfig *config = [WKAppConfig new];
    config.apiBaseUrl = baseURL; // api地址
    config.fileBaseUrl = baseURL; // 文件上传地址
    config.fileBrowseUrl = baseURL; // 文件预览地址
    config.imageBrowseUrl = baseURL; // 图片预览地址
    config.reportUrl = [NSString stringWithFormat:@"%@report/html", baseURL]; //举报地址
    config.privacyAgreementUrl = [NSString stringWithFormat:@"%@privacy_policy.html", webURL]; //隐私协议
    config.userAgreementUrl = [NSString stringWithFormat:@"%@user_agreement.html", webURL]; //用户协议
    config.connectURL = wsURL; // WebSocket 连接地址
    // 与 Android TSApplication：{@code WKCustomerServiceApplication.instance.init(WKBaseApplication.getInstance().appID)}，默认 {@code wukongchat}
    config.customerServiceAppId = @"wukongchat";
    [WKApp shared].config = config;
    [WKCustomerServiceManager shared].appID = config.customerServiceAppId;
    
    // app首页设置
    [WKApp shared].getHomeViewController = ^UIViewController * _Nonnull{
        WKMainTabController *homeViewController =  [WKMainTabController new];
        return homeViewController;
    };

   
    // app初始化
    [[WKApp shared] appInit];
    
    if (@available(iOS 13.0, *)) {
        if([WKApp shared].config.style == WKSystemStyleDark) {
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }else{
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    }
   
    return YES;
}

-(void) applicationWillEnterForeground:(UIApplication *)application {
    NSInteger lastCheckUpdateTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCheckUpdateTime"];
    if(lastCheckUpdateTime == 0) {
        [self checkAppVersionOrUpdate];
    }else if ([[NSDate date] timeIntervalSince1970] - lastCheckUpdateTime > 60.0f * 30.0f){
        [self checkAppVersionOrUpdate];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"内存警告");
}

-(void) checkAppVersionOrUpdate {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"common/appversion/iOS/%@",appVersion] parameters:nil].then(^(NSDictionary *resultDict){
        [[NSUserDefaults standardUserDefaults] setInteger:[[NSDate date] timeIntervalSince1970] forKey:@"lastCheckUpdateTime"];
        NSString *version = resultDict[@"app_version"];
        if(!version||[version isEqualToString:@""]) {
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"lastAlertUpdateTime"];
            return;
        }
        
        if([self versionStrToInt:version]>[self versionStrToInt:appVersion]) {
            NSString  *updateDesc = resultDict[@"update_desc"];
            BOOL isForce = resultDict[@"is_force"]?[resultDict[@"is_force"] boolValue]:false;
            NSString *downloadURL = resultDict[@"download_url"];
            
            [SELUpdateAlert showUpdateAlertWithVersion:resultDict[@"app_version"] Description:updateDesc downloadURL:downloadURL forceUpdate:isForce];
        }
      
    });
}

-(NSInteger) versionStrToInt:(NSString*)versionStr {
    return [[versionStr stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (!deviceToken || ![deviceToken isKindOfClass:[NSData class]] || deviceToken.length==0) {
        return;
    }
    NSString *(^getDeviceToken)(void) = ^() {
            if (@available(iOS 13.0, *)) {
                const unsigned char *dataBuffer = (const unsigned char *)deviceToken.bytes;
                NSMutableString *myToken  = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
                for (int i = 0; i < deviceToken.length; i++) {
                    [myToken appendFormat:@"%02x", dataBuffer[i]];
                }
                return (NSString *)[myToken copy];
            } else {
                NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
                NSString *myToken = [[deviceToken description] stringByTrimmingCharactersInSet:characterSet];
                return [myToken stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
        };
    NSString *myToken = getDeviceToken();
    NSLog(@"myToken----------->%@",myToken);
    [WKApp shared].loginInfo.deviceToken = myToken;
    [[WKApp shared].loginInfo save];
   NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [[WKAPIClient sharedClient] POST:@"user/device_token" parameters:@{@"device_token":myToken,@"device_type":@"IOS",@"bundle_id":bundleID}].catch(^(NSError *error){
        WKLogError(@"上传设备token失败！-> %@",error);
    });
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"didReceiveRemoteNotification------>");
    [WKApp.shared application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    WKLogError(@"注册远程通知失败->%@",error);
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    return [[WKApp shared] appOpenURL:url options:options];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    
    return [[WKApp shared] appContinueUserActivity:userActivity restorationHandler:restorationHandler];
}

/// iOS 全局禁用横屏，统一与 Android 保持竖屏体验，避免横屏布局/生命周期崩溃。
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

@end

