//
//  WKSystemContent.m
//  WuKongIMSDK
//
//  Created by tt on 2020/1/4.
//

#import "WKSystemContent.h"
#import "WKConnectionManager.h"
#import "WKSDK.h"
@interface WKSystemContent ()



@end
@implementation WKSystemContent

- (void)decodeWithJSON:(NSDictionary *)contentDic {
     self.content = contentDic;
    self.displayContent =[self getDisplayContent];
}


- (NSDictionary *)encodeWithJSON {
    return self.content;
}

- (NSString *)conversationDigest {
    NSString *s = self.displayContent;
    if (![s isKindOfClass:[NSString class]] || s.length == 0) {
        s = [self getDisplayContent];
    }
    if (![s isKindOfClass:[NSString class]] || s.length == 0) {
        return @"";
    }
    return [s stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
}

- (NSString *)searchableWord {
    NSString *s = self.displayContent;
    return [s isKindOfClass:[NSString class]] ? s : @"";
}

-(NSString*) getDisplayContent {
    if(!self.content) {
        return @"未知";
    }
    id rawContent = self.content[@"content"];
    NSString *content;
    if ([rawContent isKindOfClass:[NSString class]]) {
        content = (NSString *)rawContent;
    } else if (rawContent != nil && rawContent != [NSNull null]) {
        content = [NSString stringWithFormat:@"%@", rawContent];
    } else {
        content = @"";
    }
    id extra =self.content[@"extra"];
    if(extra && [extra isKindOfClass:[NSArray class]]) {
        NSArray *extraArray = (NSArray*)extra;
        if(extraArray.count>0) {
            for (int i=0; i<=extraArray.count-1; i++) {
                NSDictionary *extrDict = extraArray[i];
                NSString *name = extrDict[@"name"]?:@"";
                
                if([[WKSDK shared].options.connectInfo.uid isEqualToString:extrDict[@"uid"]]) {
                    name = @"你";
                }
                NSString *replacement = name.length ? name : @"";
                content = [content stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%d}",i] withString:replacement];
            }
        }
        
    }
    return content.length ? content : @"未知";
}
@end
