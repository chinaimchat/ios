//
//  WKWebViewVC.h
//  WuKongBase
//
//  Created by tt on 2020/4/3.
//

#import "WKBaseVC.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewVC : WKBaseVC

@property(nonatomic,strong) NSURL *url;
@property(nonatomic,assign) BOOL skipInitialReload;
@property(nonatomic,assign,readonly) BOOL hasLoadedWebSession;

/// 发现里换了一个外链入口（与当前 `url` 不是同一站点）时，在同一边 WK 实例上加载新地址；最小化回来同一站点时不要调这个。
- (void)reloadFromWorkplaceDiscoverURLString:(NSString *)urlString;

// 频道对象，如果是从聊天页面跳转到web请给channel赋值
@property(nonatomic,strong,nullable) WKChannel *channel;
@end

NS_ASSUME_NONNULL_END
