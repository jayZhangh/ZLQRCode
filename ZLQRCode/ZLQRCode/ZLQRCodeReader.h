//
//  ZLQRCodeReader.h
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLQRCodeReader : UIViewController
@property (nonatomic, copy) void (^qrcodeValueBlock)(NSString *codeString);
@end

NS_ASSUME_NONNULL_END
