//
//  ViewController.m
//  ACSNetworking Example
//
//  Created by 上海易凡 on 16/1/29.
//  Copyright © 2016年 Stone.y. All rights reserved.
//

#import "ViewController.h"

#import "ACSNetworking.h"

@interface ViewController () <ACSURLRequesterDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *ac_imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *ac_progressView;
@property (weak, nonatomic) IBOutlet UIProgressView *ac_fileProgressView;
@property (weak, nonatomic) IBOutlet UILabel *ac_fileLabel;

@property (nonatomic, strong) ACSFileDownloader *imageDownloader;
@property (nonatomic, strong) ACSFileDownloader *fileDownloader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)beginDownloadFile:(UIButton *)sender {
#ifdef _AFNETWORKING_
    if ([self.fileDownloader isExecuting]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载中" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    self.ac_fileLabel.text = @"下载中";
    if ([self.fileDownloader isPaused]) {
        [self.fileDownloader resume];
    }
    else {
        //https://codeload.github.com/xujingzhou/VideoBeautify/zip/master
        //http://free2.macx.cn:8182/tools/other4/QuartzCode1-36-2.dmg
        NSURL *URL = [NSURL URLWithString:@"http://free2.macx.cn:8182/tools/other4/QuartzCode1-36-2.dmg"];
        self.fileDownloader = ACSCreateDownloader(URL, self
                                                  
                                                  /*^(ACSRequestProgress progress, NSString *filePath, NSError *error) {
                                                   if (error) {
                                                   self.ac_fileLabel.text = @"下载失败";
                                                   }
                                                   else {
                                                   if (!filePath) {
                                                   self.ac_fileProgressView.progress = progress.progressValue;
                                                   }
                                                   else {
                                                   self.ac_fileLabel.text = @"下载完成";
                                                   }
                                                   }
                                                   }*/);
        [[ACSRequestManager sharedManager] downloadFileFromRequester:self.fileDownloader];
    }
    
#endif
}

- (void)request:(ACSHTTPRequest *)requester didReceiveData:(NSString *)filePath {
    NSLog(@"%@", filePath);
    self.ac_fileLabel.text = @"下载完成";
}

- (void)request:(ACSHTTPRequest *)requester didFailToProcessForDataWithError:(NSError *)error {
    NSLog(@"didFailToProcessForDataWithError %@", error);
    self.ac_fileLabel.text = @"处理数据失败";
}

- (void)request:(ACSHTTPRequest *)requester didFailToRequestForDataWithError:(NSError *)error {
    NSLog(@"didFailToRequestForDataWithError %@", error);
    self.ac_fileLabel.text = @"下载失败";
}

- (void)request:(ACSHTTPRequest *)requester didFileProgressing:(ACSRequestProgress)progress {
    //    NSLog(@"%lu, %lld, %lld", (unsigned long)progress.bytes, progress.totalBytes, progress.totalBytesExpected);
    self.ac_fileProgressView.progress = progress.progressValue;
}

- (IBAction)pauseDownloadFile:(UIButton *)sender {
#ifdef _AFNETWORKING_
    if (![self.fileDownloader isExecuting]) {
        return;
    }
    [self.fileDownloader pause];
    self.ac_fileLabel.text = @"暂停中";
#endif
}

- (IBAction)beginDownload:(UIButton *)sender {
#ifdef _AFNETWORKING_
    if (![self.imageDownloader isExecuting]) {
        
        NSArray *URLStrings = @[
                                @"http://firicon.fir.im/5c38fa602ef8a27f5e42ca34c06681895e991bc6",
                                @"http://img5q.duitang.com/uploads/item/201507/19/20150719142423_Tmwz5.jpeg",
                                @"http://img.wallba.com/data/Image/2012zwj/8yue/8-21/mxbz/tangyan/1/20128219928562.jpg",
                                @"http://i1.mopimg.cn/img/dzh/2015-01/410/20150120231848318.jpg",
                                @"http://h.hiphotos.baidu.com/zhidao/pic/item/0d338744ebf81a4cbe1483bbd42a6059252da69a.jpg"
                                ];
        
        self.imageDownloader = ACSCreateDownloader([NSURL URLWithString:URLStrings[4]], ^(ACSRequestProgress progress, UIImage *image, NSError *error) {
            if (!image && !error) {
                self.ac_progressView.progress = (CGFloat)progress.totalBytes / (CGFloat)progress.totalBytesExpected;
            }
            else if (image) {
                self.ac_imageView.image = image;
            }
        });
        self.imageDownloader.responseType = ACSResponseTypeImage;
        [[ACSRequestManager sharedManager] downloadFileFromRequester:self.imageDownloader];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载中" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
#endif
}

- (IBAction)stopDownload:(UIButton *)sender {
#ifdef _AFNETWORKING_
    [self.imageDownloader cancel];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
