//
//  ViewController.m
//  ZLQRCode
//
//  Created by ZhangLiang on 2022/8/2.
//

#import "ViewController.h"
#import "ZLQRCode/ZLQRCodeGenerator.h"
#import "ZLQRCode/ZLQRCodeReader.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *qrcodeImv;

- (IBAction)generatorAction:(id)sender;
- (IBAction)scanAction:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
}

- (IBAction)scanAction:(id)sender {
    ZLQRCodeReader *reader = [[ZLQRCodeReader alloc] init];
    reader.qrcodeValueBlock = ^(NSString * _Nonnull codeString) {
        NSLog(@"codeString: %@", codeString);
    };
//    [self presentViewController:reader animated:YES completion:nil];
    [self.navigationController pushViewController:reader animated:YES];
}

- (IBAction)generatorAction:(id)sender {
    self.qrcodeImv.image = [ZLQRCodeGenerator QRCodeWithContentString:@"Hello World!" size:200];
}

@end
