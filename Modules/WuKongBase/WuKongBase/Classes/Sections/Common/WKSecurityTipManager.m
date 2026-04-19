//
//  WKSecurityTipManager.m
//  WuKongBase
//
//  Created by tt on 2022/3/22.
//

#import "WKSecurityTipManager.h"

@implementation WKSecurityTipManager

+ (instancetype)shared{
    static WKSecurityTipManager *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[WKSecurityTipManager alloc] init];
    });
    return _shared;
}

-(void) sync {
}

-(void) syncIfNeed {
}

-(BOOL) match:(NSString*)text {
    return false;
}

@end
