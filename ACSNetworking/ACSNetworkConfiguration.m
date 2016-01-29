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

+ (instancetype)configuration {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _backgroundQueue = dispatch_queue_create("com.stoney.ACSNetworking", DISPATCH_QUEUE_SERIAL);
#ifdef _AFNETWORKING_
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
#endif
        
        dispatch_sync(_backgroundQueue, ^{
            _fileManager = [NSFileManager new];
        });
        _cacheExpirationTimeInterval = 60.0 * 3;
        _downloadExpirationTimeInterval = (60.0 * 60.0 * 24.0 * 7);
        
        [self createDownloadFolder];
        
#if TARGET_OS_IPHONE
        [self addObservers];
#endif
    }
    return self;
}

/**
 创建下载目录
 */
- (void)createDownloadFolder {
    NSString *docmentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *tempDownloadFolder = [docmentPath stringByAppendingPathComponent:@"com.stoney.ACSNetworking_Download"];
    
    NSError *error = nil;
    if (![_fileManager fileExistsAtPath:tempDownloadFolder]) {
        
        [_fileManager createDirectoryAtPath:tempDownloadFolder
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error];
    }
    
    _downloadFolder = tempDownloadFolder;
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
