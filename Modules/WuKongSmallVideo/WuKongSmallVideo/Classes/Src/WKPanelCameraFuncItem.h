//
//  WKPanelCameraFuncItem.h
//  WuKongSmallVideo
//
//  Created by tt on 2022/5/4.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKPanelCameraFuncItem : WKPanelDefaultFuncItem

/// 与 Android `chatFunction`「拍摄」一致，供工具栏与 `panelmore.items` 共用；`finishUI` 在拍照结束或取消时调用（如恢复工具栏按钮状态）。
+ (void)openCaptureForConversationContext:(id<WKConversationContext>)context finishUI:(void (^ _Nullable)(void))finishUI;

@end

NS_ASSUME_NONNULL_END
