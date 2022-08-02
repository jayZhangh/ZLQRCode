//
//  ZLQRCodeGenerator.h
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLQRCodeGenerator : NSObject
+ (UIImage *)QRCodeWithContentString:(NSString *)contentString size:(CGFloat)size;
+ (UIImage *)QRCodeWithContentString:(NSString *)contentString size:(CGFloat)size centerLogo:(UIImage *)centerLogo;
@end

NS_ASSUME_NONNULL_END
