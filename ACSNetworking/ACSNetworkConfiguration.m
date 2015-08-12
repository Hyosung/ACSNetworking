// ACSNetworkConfiguration.m
// ACSNetworking
//
// Created by Stoney on 8/4/15.
// Copyright (c) 2015年 Stone.y ( https://github.com/Hyosung/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ACSNetworkConfiguration.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

#import "ACSCache.h"

@interface ACSNetworkConfiguration ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
#else
@property (nonatomic, assign) dispatch_queue_t backgroundQueue;
#endif
@property (nonatomic, strong) NSFileManager *fileManager;
@end

@implementation ACSNetworkConfiguration

- (void)dealloc {
    
#if TARGET_OS_IPHONE
    [self removeObservers];
#endif
    
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_backgroundQueue);
#endif
}

+ (instancetype)defaultConfiguration {
    static dispatch_once_t onceToken;
    static ACSNetworkConfiguration *networkConfig = nil;
    dispatch_once(&onceToken, ^{
        networkConfig = [[self alloc] init];
    });
    return networkConfig;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _backgroundQueue = dispatch_queue_create("com.stoney.ACSNetworking", DISPATCH_QUEUE_SERIAL);
        
        dispatch_sync(_backgroundQueue, ^{
            _fileManager = [NSFileManager new];
        });
        
        _timeoutInterval = 30.0;
        [self setDownloadFolderName:@"Download"];
        _cacheExpirationTimeInterval = 60.0 * 3;
        _downloadExpirationTimeInterval = (60.0 * 60.0 * 24.0 * 7);
        
#if TARGET_OS_IPHONE
        [self addObservers];
#endif
    }
    return self;
}

- (void)setDownloadFolderName:(NSString *)downloadFolderName {
    NSParameterAssert(downloadFolderName && ![[downloadFolderName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]);
    
    if (![_downloadFolderName isEqualToString:downloadFolderName]) {
        NSString *docmentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *tempDownloadFolder = [docmentPath stringByAppendingPathComponent:downloadFolderName];
        
        if (_downloadFolderName) {
            NSAssert(![_fileManager fileExistsAtPath:tempDownloadFolder], @"文件夹名字已被使用，请重新换一个名字");
            //移动已有的文件夹到指定的路径上（实则是修改文件夹名称）
            [_fileManager moveItemAtPath:_downloadFolder
                                  toPath:tempDownloadFolder
                                   error:nil];
        }
        else {
            if (![_fileManager fileExistsAtPath:tempDownloadFolder]) {
                [_fileManager createDirectoryAtPath:tempDownloadFolder
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:NULL];
            }
        }
        
        _downloadFolder = tempDownloadFolder;
        _downloadFolderName = downloadFolderName;
    }
}

#pragma mark - Private

#if TARGET_OS_IPHONE
- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDisk) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundCleanDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)backgroundCleanDisk {
 
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    [self cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#endif

- (void)cleanDisk {
    [self cleanDiskWithCompletionBlock:NULL];
}

- (void)cleanDiskWithCompletionBlock:(void (^)(void)) completionBlock {
    dispatch_async(self.backgroundQueue, ^{
        [self removeFolderInFile:[ACSCache sharedCache].diskCachePath
                      expiration:self.cacheExpirationTimeInterval
                       cachePath:nil];
        [self removeFolderInFile:self.downloadFolder
                      expiration:self.downloadExpirationTimeInterval
                       cachePath:[ACSCache sharedCache].diskCachePath];
        if (completionBlock != NULL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

/**
 移除已过期的文件
 
 @param path         文件夹路径
 @param timeInterval 过期时间
 @param cachePath    下载文件的路径缓存文件夹
 */
- (void)removeFolderInFile:(NSString *) path
                expiration:(NSTimeInterval) timeInterval
                 cachePath:(NSString *) cachePath {
    
    NSURL *folderURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey];
    // This enumerator prefetches useful properties for our cache files.
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtURL:folderURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-timeInterval];
    
    for (NSURL *fileURL in fileEnumerator) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        
        // Skip directories.
        if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        // Remove files that are older than the expiration date;
        NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
        if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [self.fileManager removeItemAtURL:fileURL error:NULL];
            if ([self.fileManager fileExistsAtPath:cachePath]) {
                NSString *fileCachePath = [cachePath stringByAppendingPathComponent:[fileURL URLByDeletingPathExtension].lastPathComponent];
                [self.fileManager removeItemAtPath:fileCachePath error:NULL];
            }
            continue;
        }
    }
}

@end
