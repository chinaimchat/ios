//
//  WKProhibitwordsService.m
//  WuKongBase
//

#import "WKProhibitwordsService.h"

@implementation WKProhibitwordsService

static WKProhibitwordsService *_instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)shared {
    if (_instance == nil) {
        _instance = [[super alloc] init];
    }
    return _instance;
}

- (BOOL)containsProhibitedContent:(NSString *)text {
    if (text.length == 0) {
        return NO;
    }
    return NO;
}

@end
