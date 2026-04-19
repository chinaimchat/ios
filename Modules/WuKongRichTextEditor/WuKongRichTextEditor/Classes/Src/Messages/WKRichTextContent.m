//
//  WKRichTextContent.m
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/28.
//

#import "WKRichTextContent.h"





@implementation WKRichTextContent

-(instancetype) initWithContent:(NSString*)content entities:(NSArray<WKMessageEntity*>*)entities {
    self = [super init];
    if(self) {
        self.content = content;
        self.entities = entities;
    }
    return self;
}

- (NSDictionary *)encodeWithJSON {
    NSMutableDictionary *contentDict = [NSMutableDictionary dictionary];
    contentDict[@"content"] = self.content?:@"";
    
    return contentDict;
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.content =  contentDic[@"content"]?:@"";
}

+ (NSNumber *)contentType {
    return @(WK_RICHTEXT);
}

- (NSString *)conversationDigest {
    NSMutableString *newContent = [self.content mutableCopy];
    if(self.entities) {
        NSString *imageStr = @"[图片]";
        NSInteger imgInsertCount = 0;
        for (WKMessageEntity *entity in self.entities) {
            if([entity.type isEqualToString:WKImageRichTextStyle]) {
                NSInteger index = entity.range.location+imgInsertCount*imageStr.length;
                if(index < newContent.length) {
                    [newContent insertString:imageStr atIndex:index];
                    imgInsertCount++;
                }
            }
        }
    }
    newContent = [NSMutableString stringWithString:[newContent stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    return newContent;
}

@end


