//
//  WKRichTextContent.h
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/28.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN


@interface WKRichTextContent : WKMessageContent

@property(nonatomic,copy) NSString *content;


-(instancetype) initWithContent:(NSString*)content entities:(NSArray<WKMessageEntity*>*)entities ;

@end

NS_ASSUME_NONNULL_END
