#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与 Android StringUtils.TappableSuffixInfo 对齐。
@interface WKSystemNotifyTappableSuffix : NSObject
@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger end;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *packetNo;
@property (nonatomic, copy) NSString *transferNo;
@property (nonatomic, copy) NSString *colorHint;
- (BOOL)opensRedPacketDetail;
- (BOOL)opensTransferDetail;
@end

/// 与 Android TemplateNotifyClickable.ClickSpan 对齐：模板展开后昵称区间 + uid。
@interface WKSystemNotifyNickSpan : NSObject
@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger end;
@property (nonatomic, copy) NSString *uid;
@end

@interface WKSystemNotifyBuilt : NSObject
/// 最终展示串（1011 含前置 🧧，与 Android 一致）。
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSUInteger emojiPrefixLength;
@property (nonatomic, copy) NSArray<WKSystemNotifyNickSpan *> *nickSpans;
@property (nonatomic, strong, nullable) WKSystemNotifyTappableSuffix *tappableSuffix;
@end

@interface WKSystemNotifyDisplay : NSObject

/// 与 Android StringUtils.isTemplateNotifyJson 一致（含 {n} 占位且带 extra）。
+ (BOOL)isTemplateNotifyJson:(NSDictionary *)contentRoot;

/// 与 Android getShowContent 一致的纯文案（无 emoji、无链），用于 1012 非模板兜底等。
+ (nullable NSString *)plainShowTextFromNotifyContentRoot:(NSDictionary *)contentRoot;

/// 1011：对齐 applyRedPacketClaimTipStyle（🧧 + 灰字主体 + 领取者昵称区间 + 句末红包链）。
+ (nullable WKSystemNotifyBuilt *)buildRedPacketOpenNotify:(NSDictionary *)contentRoot;

/// 1012 且 JSON 模板：对齐 buildTemplateNotifyClickable + applyTradeSystemTemplateNotify（昵称可点 + tappable_suffix）。
+ (nullable WKSystemNotifyBuilt *)buildTradeSystemTemplateNotify:(NSDictionary *)contentRoot;

@end

NS_ASSUME_NONNULL_END
