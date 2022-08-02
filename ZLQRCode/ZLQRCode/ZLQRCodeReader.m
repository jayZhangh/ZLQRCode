//
//  ZLQRCodeReader.m
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import "ZLQRCodeReader.h"
#import <AVFoundation/AVFoundation.h>
#import "ZLQRCodeScanView.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define ZLScaleValue(scaleValue) scaleValue/320.0*[UIScreen mainScreen].bounds.size.width

@interface ZLQRCodeReader () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, weak) ZLQRCodeScanView *scanView;
@end

@implementation ZLQRCodeReader

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat scanWH = ZLScaleValue(220);
    CGFloat scanX = (kScreenWidth - scanWH) * 0.5;
    CGFloat scanY = (kScreenHeight - scanWH) * 0.5;
    self.scanRect = CGRectMake(scanX, scanY, scanWH, scanWH);
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized || status == AVAuthorizationStatusRestricted) {
        [self loadScanView];
        
    } else if (status == AVAuthorizationStatusNotDetermined) {
        // 请求使用相机权限
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadScanView];
                });
            } else {
                [self alertWithMessage:@"请在设置中打开访问相机相机的权限"];
            }
        }];
    } else {
        [self alertWithMessage:@"请在设置中打开访问相机相机的权限"];
    }
    
    CGFloat photoBtnW = 90;
    CGFloat photoBtnH = 44;
    CGFloat photoBtnX = self.view.bounds.size.width - photoBtnW - 10;
    CGFloat photoBtnY = self.view.bounds.size.height - photoBtnH - 10;
    UIButton *photoBtn = [[UIButton alloc] initWithFrame:CGRectMake(photoBtnX, photoBtnY, photoBtnW, photoBtnH)];
    [photoBtn setTitle:@"相册" forState:UIControlStateNormal];
    photoBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [photoBtn addTarget:self action:@selector(analyzeOnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photoBtn];
}

// 从相册解析二维码图片
- (void)analyzeOnClick {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)loadScanView {
    // 检测是否可以使用相机
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self alertWithMessage:@"设备不支持相机，无法使用扫描功能!"];
        return;
    }
    
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建设备输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //创建元数据输出流
    self.output = [[AVCaptureMetadataOutput alloc]init];
    //为输出流对象设置代理 并在主线程里刷新
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    //设置高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    // 添加设备输入流
    [self.session addInput:input];
    // 添加设备输出流
    [self.session addOutput:self.output];
    
    // 创建摄像数据输出流并将其添加到会话对象上 --> 用于识别光线强弱
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:self.videoDataOutput];
    
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    self.output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,//二维码
                                 //以下为条形码，如果项目只需要扫描二维码，下面都不要写
                                 AVMetadataObjectTypeEAN13Code,
                                 AVMetadataObjectTypeEAN8Code,
                                 AVMetadataObjectTypeUPCECode,
                                 AVMetadataObjectTypeCode39Code,
                                 AVMetadataObjectTypeCode39Mod43Code,
                                 AVMetadataObjectTypeCode93Code,
                                 AVMetadataObjectTypeCode128Code,
                                 AVMetadataObjectTypePDF417Code];
    
    // 实例化预览图层, 用于显示会话对象
    self.layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    // 保持纵横比；填充层边界
    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    layer.frame = self.view.layer.bounds;
    self.layer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer insertSublayer:self.layer atIndex:0];
    
    // 在block中使用weak self，不然会导致该controller的内存无法回收
    __weak typeof(self) wekself = self;
    // 添加通知
    [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification * _Nonnull note) {
        // 如果不设置，整个屏幕都可以扫
        wekself.output.rectOfInterest = [wekself.layer metadataOutputRectOfInterestForRect:wekself.scanRect];
    }];
    
    // 添加扫描视图
    ZLQRCodeScanView *scanView = [[ZLQRCodeScanView alloc] initWithScanRect:self.scanRect];
    [self.view addSubview:scanView];
    self.scanView = scanView;
    
    scanView.offFlashBlock = ^(BOOL flag) {
        [wekself offFlashWithMode:(flag ? AVCaptureTorchModeOn : AVCaptureTorchModeOff)];
    };
    
    //开始捕获
    [self.session startRunning];
}

// 根据Mode是否打开闪光灯
- (void)offFlashWithMode:(AVCaptureTorchMode)mode {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    if ([captureDevice hasTorch]) {
        BOOL locked = [captureDevice lockForConfiguration:&error];
        if (locked && error == nil) {
            // 打开手电筒 | 关闭手电筒
            captureDevice.torchMode = mode;
            [captureDevice unlockForConfiguration];
        }
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
// 扫描到数据后的回调
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        if (self.qrcodeValueBlock) {
            self.qrcodeValueBlock(metadataObject.stringValue);
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.session startRunning];
        });
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 获取到光线的强弱值
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    // 这个方法会时时调用，但内存很稳定
//    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
//    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary *)metadataDict];
//    CFRelease(metadataDict);
//    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
//    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
//    NSLog(@"%f", brightnessValue);
//    self.scanView.brightnessValue = brightnessValue;
}

#pragma mark - UIImagePickerContorllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    // 对选取照片的处理，如果选取的图片尺寸过大，则压缩选取图片，否则不处理
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *image = [self imageSizeWithScreenImage:originalImage];
    // CIDetector (CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个CIDetector，并设定识别类型 CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    // 获取识别结果
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    NSString *alertMsg = @"识别结果为nil";
    if ([features count] <= 0) {
        
    } else {
        CIQRCodeFeature *feature = [features firstObject];
        alertMsg = feature.messageString;
//        for (CIQRCodeFeature *feature in features) {
//            NSLog(@"%@", feature.messageString);
//        }
    }
    
    [self alertWithMessage:alertMsg];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// 返回一张不超过屏幕尺寸的image
- (UIImage *)imageSizeWithScreenImage:(UIImage *)image {
    CGFloat imageW = image.size.width;
    CGFloat imageH = image.size.height;
    CGFloat screenW = kScreenWidth;
    CGFloat screenH = kScreenHeight;
    if (imageW <= screenW && imageH <= screenH) {
        return image;
    }
    
    CGFloat max = MAX(imageW, imageH);
    CGFloat scale = max / (screenH * 2.0);
    
    CGSize size = CGSizeMake(imageW / scale, imageW / scale);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)alertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - destroy
- (void)dealloc {
    NSLog(@"ZLQRCodeReader - dealloc");
    // 将引用置空
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.session stopRunning];
    self.session = nil;
    self.layer = nil;
    self.output = nil;
    self.videoDataOutput = nil;
}

@end
