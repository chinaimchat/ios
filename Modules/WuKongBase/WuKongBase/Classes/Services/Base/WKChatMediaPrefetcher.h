#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WKMessageListDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// 与 Android 会话内 Glide 预取思路一致：对当前屏图片消息 URL 做 SDWebImage 预加载，减轻上滑时首帧等待。
@interface WKChatMediaPrefetcher : NSObject

+ (void)prefetchImageURLsForVisibleRowsInTableView:(UITableView *)tableView
                                      dataProvider:(id<WKMessageListDataProvider>)dataProvider;

/// 即将进入可视区的视频类消息（WK_SMALLVIDEO / WK_VIDEO，与 Android WKMsgContentType 对齐）：串行 + Utility QoS + 防抖；复用 WKMediaManager download:。
+ (void)schedulePrefetchSmallVideosNearVisibleRowsInTableView:(UITableView *)tableView
                                                 dataProvider:(id<WKMessageListDataProvider>)dataProvider;

@end

NS_ASSUME_NONNULL_END
