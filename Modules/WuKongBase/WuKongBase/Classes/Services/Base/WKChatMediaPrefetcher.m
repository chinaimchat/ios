#import "WKChatMediaPrefetcher.h"
#import "WKMessageListDataProvider.h"
#import "WKMessageModel.h"
#import "WKApp.h"
#import "WKConstant.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
#import <WuKongIMSDK/WKSDK.h>
#import <SDWebImage/SDWebImage.h>

static dispatch_queue_t WKChatVideoPrefetchSerialQueue(void) {
    static dispatch_queue_t q;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        q = dispatch_queue_create("com.wukong.chat.video_prefetch", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(q, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    });
    return q;
}

static uint64_t WKChatVideoPrefetchGeneration = 0;

@implementation WKChatMediaPrefetcher

+ (void)prefetchImageURLsForVisibleRowsInTableView:(UITableView *)tableView
                                      dataProvider:(id<WKMessageListDataProvider>)dataProvider {
    if (!tableView || !dataProvider) {
        return;
    }
    NSArray<NSIndexPath *> *visible = [tableView indexPathsForVisibleRows];
    if (visible.count == 0) {
        return;
    }
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (NSIndexPath *ip in visible) {
        WKMessageModel *m = [dataProvider messageAtIndexPath:ip];
        if (!m || m.revoke || m.message.isDeleted) {
            continue;
        }
        if (m.contentType != WK_IMAGE) {
            continue;
        }
        if (m.content.flame) {
            continue;
        }
        WKImageContent *ic = (WKImageContent *)m.content;
        if (!ic.remoteUrl.length) {
            continue;
        }
        NSString *lp = ic.localPath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:lp]) {
            NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:lp error:nil];
            if ([attr fileSize] > 0) {
                continue;
            }
        }
        NSURL *u = [[WKApp shared] getImageFullUrl:ic.remoteUrl];
        if (u) {
            [urls addObject:u];
        }
    }
    if (urls.count == 0) {
        return;
    }
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls];
}

+ (NSArray<WKMessage *> *)wk_messagesSmallVideoNearVisible:(UITableView *)tableView
                                              dataProvider:(id<WKMessageListDataProvider>)dataProvider
                                                       band:(NSInteger)band
                                                    maxPick:(NSInteger)maxPick {
    NSArray<NSIndexPath *> *visible = [tableView indexPathsForVisibleRows];
    if (visible.count == 0 || !dataProvider) {
        return @[];
    }
    NSMutableOrderedSet<NSIndexPath *> *pathSet = [NSMutableOrderedSet orderedSet];
    for (NSIndexPath *ip in visible) {
        NSArray<WKMessageModel *> *rows = [dataProvider messagesAtSection:ip.section];
        NSInteger n = (NSInteger)rows.count;
        if (n <= 0) {
            continue;
        }
        NSInteger lo = MAX(0, ip.row - band);
        NSInteger hi = MIN(n - 1, ip.row + band);
        for (NSInteger r = lo; r <= hi; r++) {
            [pathSet addObject:[NSIndexPath indexPathForRow:r inSection:ip.section]];
        }
    }
    NSMutableArray<WKMessage *> *out = [NSMutableArray array];
    for (NSIndexPath *ip in pathSet) {
        WKMessageModel *mm = [dataProvider messageAtIndexPath:ip];
        if (!mm || mm.revoke || mm.message.isDeleted) {
            continue;
        }
        if (mm.contentType != WK_SMALLVIDEO && mm.contentType != WK_VIDEO) {
            continue;
        }
        if (mm.content.flame) {
            continue;
        }
        if (![mm.content isKindOfClass:[WKMediaMessageContent class]]) {
            continue;
        }
        WKMediaMessageContent *media = (WKMediaMessageContent *)mm.content;
        if (media.remoteUrl.length == 0) {
            continue;
        }
        NSString *lp = media.localPath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:lp]) {
            NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:lp error:nil];
            if ([attr fileSize] > 0) {
                continue;
            }
        }
        WKMessage *msg = mm.message;
        if (!msg) {
            continue;
        }
        if ([[WKSDK shared] getMessageDownloadTask:msg]) {
            continue;
        }
        [out addObject:msg];
        if ((NSInteger)out.count >= maxPick) {
            break;
        }
    }
    return out;
}

+ (void)schedulePrefetchSmallVideosNearVisibleRowsInTableView:(UITableView *)tableView
                                                 dataProvider:(id<WKMessageListDataProvider>)dataProvider {
    if (!tableView || !dataProvider) {
        return;
    }
    uint64_t gen = ++WKChatVideoPrefetchGeneration;
    const int64_t debounceNs = (int64_t)(0.15 * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, debounceNs), dispatch_get_main_queue(), ^{
        if (gen != WKChatVideoPrefetchGeneration) {
            return;
        }
        NSArray<WKMessage *> *batch = [self wk_messagesSmallVideoNearVisible:tableView
                                                                dataProvider:dataProvider
                                                                        band:10
                                                                     maxPick:4];
        if (batch.count == 0) {
            return;
        }
        dispatch_queue_t q = WKChatVideoPrefetchSerialQueue();
        dispatch_async(q, ^{
            for (WKMessage *msg in batch) {
                if (gen != WKChatVideoPrefetchGeneration) {
                    break;
                }
                if ([[WKSDK shared] getMessageDownloadTask:msg]) {
                    continue;
                }
                WKMediaMessageContent *media = (WKMediaMessageContent *)msg.content;
                NSString *lp = media.localPath;
                if ([[NSFileManager defaultManager] fileExistsAtPath:lp]) {
                    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:lp error:nil];
                    if ([attr fileSize] > 0) {
                        continue;
                    }
                }
                [[WKSDK shared].mediaManager download:msg];
                /// 弱网：串行且间隔启动，避免与图片预取、首屏请求瞬时叠峰。
                usleep(220000);
            }
        });
    });
}

@end
