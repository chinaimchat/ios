//
//  ZSSRichTextEditorContext.h
//  WuKongRichTextEditor
//
//  Created by tt on 2022/7/21.
//


@protocol WKRichTextEditorContext

// 隐藏键盘
- (void)dismissKeyboard;

// 设置编辑框正文高度
-(void) setEditorContentHeight:(CGFloat)height;

- (void)insertText:(NSString *)text;

// 加粗
- (void)setBold;

// 斜体
-(void) setItalic;

// 下划线
-(void) setUnderline;

// 中划线
-(void) setStrikethrough;

// 插入图片
-(void) insertImage:(NSString *)path fileURL:(NSURL*)fileURL width:(CGFloat)width height:(CGFloat)height;

- (void)insertImageBase64String:(NSString *)imageBase64String alt:(NSString *)alt;

- (void)insertImageFromDevice;

// 删除 跟按下删除键效果一样
-(void) forwardDelete;

-(void) setTextColor:(UIColor* __nullable) color;

-(void) prepareInsert;

-(NSArray<NSString*>*) editorItemsEnabled;

- (void)focusTextEditor;

@end
