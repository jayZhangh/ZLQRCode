//
//  ZLQRCodeGenerator.m
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import "ZLQRCodeGenerator.h"
#import <CoreImage/CoreImage.h>

@interface ZLQRCodeGenerator ()

@end

@implementation ZLQRCodeGenerator

+ (UIImage *)QRCodeWithContentString:(NSString *)contentString size:(CGFloat)size {
    // 0.导入头文件
    
    // 1.创建过滤器 -- 苹果没有将这个字符封装成常量
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.过滤器恢复默认设置
    [filter setDefaults];
    
    // 3.给过滤器添加数据(正则表达式/帐号和密码) -- 通过KVC设置过滤器,只能设置NSData类型
    NSString *dataString = contentString;
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    // 5.显示二维码
    //    self.qrcodeImv.image = [UIImage imageWithCIImage:outputImage];
    // 显示放大后清晰的二维码图片
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:size];
}

+ (UIImage *)QRCodeWithContentString:(NSString *)contentString size:(CGFloat)size centerLogo:(UIImage *)centerLogo {
    // 0.导入头文件
    
    // 1.创建过滤器 -- 苹果没有将这个字符封装成常量
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.过滤器恢复默认设置
    [filter setDefaults];
    
    // 3.给过滤器添加数据(正则表达式/帐号和密码) -- 通过KVC设置过滤器,只能设置NSData类型
    NSString *dataString = contentString;
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    // 5.显示二维码
    return [self qrcode:[self createNonInterpolatedUIImageFormCIImage:outputImage withSize:120] centerLogo:centerLogo];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

+ (UIImage *)qrcode:(UIImage *)qrcode centerLogo:(UIImage *)logo {
    UIGraphicsBeginImageContext(qrcode.size);
    [qrcode drawInRect:CGRectMake(0, 0, qrcode.size.width, qrcode.size.height)];
    [logo drawInRect:CGRectMake((qrcode.size.width - logo.size.width) * 0.5, (qrcode.size.height - logo.size.height) * 0.5, logo.size.width, logo.size.height)];
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return returnImage;
}

@end
