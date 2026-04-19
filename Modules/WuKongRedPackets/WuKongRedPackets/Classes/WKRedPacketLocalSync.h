#import <Foundation/Foundation.h>

@class WKChannel;
@class WKMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WKRedPacketLocalSync : NSObject

+ (NSInteger)localMessageStatusAfterOpenSuccessFromResponse:(NSDictionary *)response;
+ (double)resolvedOpenAmountFromResponse:(NSDictionary *)response;

+ (NSInteger)statusFromDetailDict:(NSDictionary *)detail currentUid:(nullable NSString *)uid;

+ (void)applyStatus:(NSInteger)status toRedPacketMessage:(WKMessage *)message;

/**
 * 对齐 Android RedPacketLocalSync.applyOpened：优先 clientSeq / clientMsgNo，再按会话 + packet_no 分页搜，最后全局扫红包消息。
 */
+ (void)applyOpenedWithStatus:(NSInteger)status
                     packetNo:(NSString *)packetNo
                      channel:(nullable WKChannel *)channel
                    clientSeq:(uint32_t)clientSeq
                  clientMsgNo:(nullable NSString *)clientMsgNo;

/** 对齐 refineLocalMessageFromDetail：拉详情后用 statusFromDetail 再写回（内部仍走 applyOpened 寻址）。 */
+ (void)refineWithPacketNo:(NSString *)packetNo
                   channel:(nullable WKChannel *)channel
                 clientSeq:(uint32_t)clientSeq
               clientMsgNo:(nullable NSString *)clientMsgNo;

/**
 * 消息入库拦截：同一会话、相同 packet_no 已有一条且非同一 DB 记录时返回 NO，避免本机发送与服务端下行各存一条导致双气泡。
 */
+ (BOOL)shouldStoreIncomingRedPacketMessage:(WKMessage *)incoming;

@end

NS_ASSUME_NONNULL_END
