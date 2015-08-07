//
//  ViewController.m
//  ACNetworkingExample
//
//  Created by 上海易凡 on 15/7/30.
//  Copyright (c) 2015年 Stone.y. All rights reserved.
//

#import "ViewController.h"

#import <ACSNetworking.h>

void ACPrintRunTime(void (^codeBlock)(CFAbsoluteTime startTime)) {
    assert(codeBlock);
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    codeBlock(startTime);
    NSLog(@"运行时间：%f", CFAbsoluteTimeGetCurrent() - startTime);
}

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *ac_imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *ac_progressView;
@property (weak, nonatomic) IBOutlet UIProgressView *ac_MP3ProgressView;
@property (weak, nonatomic) IBOutlet UILabel *ac_MP3Label;

@property (nonatomic, copy) NSString *downloadIdentifier;
@property (nonatomic, copy) NSString *MP3Identifier;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)beginDownloadMP3:(UIButton *)sender {
    
    if ([[ACSRequestManager sharedManager] isPausedOperationWithIdentifier:self.MP3Identifier]) {
        [[ACSRequestManager sharedManager] resumeOperationWithIdentifier:self.MP3Identifier];
    }
    else {
        self.ac_MP3Label.text = @"下载中";
        NSURL *URL = [NSURL URLWithString:@"http://music.baidu.com/data/music/file?link=http://yinyueshiting.baidu.com/data2/music/245838837/245838806223200128.mp3?xcode=b34776036c683819d7984b79751f9d39&song_id=245838806"];
        self.MP3Identifier = [[ACSRequestManager sharedManager] downloadFileFromRequester:ACSCreateDownloader(URL, ^(ACSRequestProgress progress, NSString *mp3Path, NSError *error) {
            if (error) {
                self.ac_MP3Label.text = @"下载失败";
            }
            else {
                if (!mp3Path) {
                    self.ac_MP3ProgressView.progress = (CGFloat)progress.totalBytes / (CGFloat)progress.totalBytesExpected;
                }
                else {
                    self.ac_MP3Label.text = @"下载完成";
                }
            }
        })];
    }
}

- (IBAction)pauseDownloadMP3:(UIButton *)sender {
    if (![[ACSRequestManager sharedManager] isExecutingOperationWithIdentifier:self.MP3Identifier]) {
        return;
    }
    
    [[ACSRequestManager sharedManager] pauseOperationWithIdentifier:self.MP3Identifier];
    self.ac_MP3Label.text = @"暂停中";
}

- (IBAction)beginDownload:(UIButton *)sender {
    
    NSArray *URLStrings = @[
                          @"http://firicon.fir.im/5c38fa602ef8a27f5e42ca34c06681895e991bc6",
                          @"http://img5q.duitang.com/uploads/item/201507/19/20150719142423_Tmwz5.jpeg",
                          @"http://img.wallba.com/data/Image/2012zwj/8yue/8-21/mxbz/tangyan/1/20128219928562.jpg",
                          @"http://i1.mopimg.cn/img/dzh/2015-01/410/20150120231848318.jpg",
                          @"http://h.hiphotos.baidu.com/zhidao/pic/item/0d338744ebf81a4cbe1483bbd42a6059252da69a.jpg",
                          @"http://img1.imgtn.bdimg.com/it/u=4285455535,4054079836&fm=21&gp=0.jpg"
                          ];
    
    if (![[ACSRequestManager sharedManager] isExecutingOperationWithIdentifier:self.downloadIdentifier]) {
        
        ACSFileDownloader *downloader = ACSCreateDownloader([NSURL URLWithString:URLStrings[4]], ^(ACSRequestProgress progress, UIImage *image, NSError *error) {
            if (!image && !error) {
                self.ac_progressView.progress = (CGFloat)progress.totalBytes / (CGFloat)progress.totalBytesExpected;
            }
            else if (image) {
                self.ac_imageView.image = image;
            }
        });
        downloader.responseType = ACSResponseTypeImage;
        
        self.downloadIdentifier = [[ACSRequestManager sharedManager] downloadFileFromRequester:downloader];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载中" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)stopDownload:(UIButton *)sender {
    [[ACSRequestManager sharedManager] cancelOperationWithIdentifier:self.downloadIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
