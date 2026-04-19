#import "WKWalletBalanceSyncContent.h"
#import <WuKongBase/WuKongBase.h>

@implementation WKWalletBalanceSyncContent

+ (NSNumber *)contentType {
    return @(WK_WALLET_BALANCE_SYNC);
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    if (![contentDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    _walletSyncVersion = [contentDic[@"wallet_sync_version"] intValue];
    if (_walletSyncVersion == 0) {
        _walletSyncVersion = [contentDic[@"walletSyncVersion"] intValue];
    }
    _balance = [contentDic[@"balance"] doubleValue];
    _usdtAvailable = [contentDic[@"usdt_available"] doubleValue];
    if (contentDic[@"usdt_available"] == nil || contentDic[@"usdt_available"] == [NSNull null]) {
        _usdtAvailable = [contentDic[@"usdtAvailable"] doubleValue];
    }
    if ((contentDic[@"balance"] == nil || contentDic[@"balance"] == [NSNull null]) && !isnan(_usdtAvailable)) {
        _balance = _usdtAvailable;
    }
}

- (NSDictionary *)encodeWithJSON {
    return @{
        @"type": @(WK_WALLET_BALANCE_SYNC),
        @"wallet_sync_version": @(self.walletSyncVersion),
        @"balance": @(self.balance),
    };
}

/// 与 Android {@code wallet_balance_sync_session_preview} 一致：会话列表摘要，非聊天气泡主文案。
- (NSString *)conversationDigest {
    return LLang(@"钱包余额已更新");
}

@end
