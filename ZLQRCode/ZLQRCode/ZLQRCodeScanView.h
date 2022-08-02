//
//  ZLQRCodeScanView.h
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLQRCodeScanView : UIView
// 是否隐藏开启闪光灯按钮
@property (nonatomic, assign) float brightnessValue;
@property (nonatomic, copy) void (^offFlashBlock)(BOOL flag);
- (instancetype)initWithScanRect:(CGRect)scanRect;
@end

NS_ASSUME_NONNULL_END
