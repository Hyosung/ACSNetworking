// ACSFileDownloader.m
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

#import "ACSFileDownloader.h"

#import "ACSCache.h"
#import "ACSRequestManager.h"
#import <fcntl.h>
#import <unistd.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#ifdef _AFNETWORKING_

@interface ACSDownloadRequestOperation : AFHTTPRequestOperation

/**
 A Boolean value that indicates if we should try to resume the download. Defaults is `YES`.
 
 Can only be set while creating the request.
 */
@property (nonatomic, assign, readwrite) BOOL shouldResume;

/**
 Expected total length. This is different than expectedContentLength if the file is resumed.
 
 Note: this can also be zero if the file size is not sent (*)
 */
@property (nonatomic, readwrite, assign) long long totalContentLength;

/**
 Indicator for the file offset on partial downloads. This is greater than zero if the file download is resumed.
 */
@property (nonatomic, readwrite, assign) long long offsetContentLength;

@property (nonatomic, readwrite, assign) long long totalBytesReadPerDownload;

/**
 Sets a callback to be called when an undetermined number of bytes have been downloaded from the server. This is a variant of setDownloadProgressBlock that adds support for progressive downloads and adds the
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes five arguments: the number of bytes read since the last time the download progress block was called, the bytes expected to be read during the request, the bytes already read during this request, the total bytes read (including from previous partial downloads), and the total bytes expected to be read for the file. This block may be called multiple times.
 
 @see setDownloadProgressBlock
 */
@property (nonatomic, copy) void (^progressiveDownloadProgress)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile);

/**
 Returns the path used for the temporary file. Returns `nil` if the targetPath has not been set.
 */
@property (nonatomic, copy) NSString *tempPath;

///----------------------------------
/// @name Creating Request Operations
///----------------------------------

/**
 Creates and returns an `ACSDownloadRequestOperation`
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param shouldResume If YES, tries to resume a partial download if found.
 @return A new download request operation
 */
- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
                   shouldResume:(BOOL)shouldResume;

- (void)setupOperationManager:(AFHTTPRequestOperationManager *) manager;

@end

@interface AFURLConnectionOperation ()
@property (nonatomic, readwrite, strong) NSURLRequest *request;
@property (nonatomic, readonly, assign) long long totalBytesRead;
@end

@implementation ACSDownloadRequestOperation

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest shouldResume:(BOOL)shouldResume {
    self = [super initWithRequest:urlRequest];
    if (self) {
        _shouldResume = shouldResume;
        
        // Download is saved into a temorary file and renamed upon completion.
        NSString *tempPath = [self tempPath];
        
        // Do we need to resume the file?
        BOOL isResuming = [self updateByteStartRangeForRequest];
        
        // Try to create/open a file at the target location
        // 尝试创建或者打开这个临时文件
        if (!isResuming) {
            int fileDescriptor = open([tempPath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
            if (fileDescriptor > 0) close(fileDescriptor);
        }
        
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:isResuming];
        // If the output stream can't be created, instantly destroy the object.
        if (!self.outputStream) return nil;
    }
    return self;
}

- (void)setupOperationManager:(AFHTTPRequestOperationManager *)manager {
    NSParameterAssert(manager);
    self.responseSerializer = manager.responseSerializer;
    self.shouldUseCredentialStorage = manager.shouldUseCredentialStorage;
    self.credential = manager.credential;
    self.securityPolicy = manager.securityPolicy;
    
    self.completionQueue = manager.completionQueue;
    self.completionGroup = manager.completionGroup;
}

// updates the current request to set the correct start-byte-range.
- (BOOL)updateByteStartRangeForRequest {
    BOOL isResuming = NO;
    if (self.shouldResume) {
        unsigned long long downloadedBytes = ACSFileSizeFromPath(self.tempPath);
        if (downloadedBytes > 1) {
            
            // If the the current download-request's data has been fully downloaded, but other causes of the operation failed (such as the inability of the incomplete temporary file copied to the target location), next, retry this download-request, the starting-value (equal to the incomplete temporary file size) will lead to an HTTP 416 out of range error, unless we subtract one byte here. (We don't know the final size before sending the request)
            downloadedBytes--;
            
            NSMutableURLRequest *mutableURLRequest = [self.request mutableCopy];
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
            self.request = mutableURLRequest;
            isResuming = YES;
        }
    }
    return isResuming;
}

#pragma mark - Public

- (NSString *)tempPath {
    
    return ACSFilePathFromURL(self.request.URL, NSTemporaryDirectory(), @"tmp");
}

#pragma mark - AFHTTPRequestOperation

+ (NSIndexSet *)acceptableStatusCodes {
    NSMutableIndexSet *acceptableStatusCodes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    [acceptableStatusCodes addIndex:416];
    
    return acceptableStatusCodes;
}

#pragma mark - AFURLRequestOperation

- (void)pause {
    [super pause];
    [self updateByteStartRangeForRequest];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [super connection:connection didReceiveResponse:response];
    
    // check if we have the correct response
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) return;
    
    // check for valid response to resume the download if possible
    long long totalContentLength = self.response.expectedContentLength;
    long long fileOffset = 0;
    if(httpResponse.statusCode == 206) {
        NSString *contentRange = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if ([bytes count] == 4) {
                fileOffset = [bytes[1] longLongValue];
                totalContentLength = [bytes[3] longLongValue]; // if this is *, it's converted to 0
            }
        }
    }else if (httpResponse.statusCode != 200){
        return;
    }
    
    self.totalBytesReadPerDownload = 0;
    self.offsetContentLength = MAX(fileOffset, 0);
    self.totalContentLength = totalContentLength;
    
    // Truncate cache file to offset provided by server.
    // Using self.outputStream setProperty:@(_offsetContentLength) forKey:NSStreamFileCurrentOffsetKey]; will not work (in contrary to the documentation)
    NSString *tempPath = [self tempPath];
    unsigned long long downloadedBytes = ACSFileSizeFromPath(tempPath);
    if (downloadedBytes != _offsetContentLength) {
        [self.outputStream close];
        BOOL isResuming = _offsetContentLength > 0;
        if (isResuming) {
            NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:tempPath];
            [file truncateFileAtOffset:_offsetContentLength];
            [file closeFile];
        }
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:isResuming];
        [self.outputStream open];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data  {
    if (![self.responseSerializer validateResponse:self.response data:data ?: [NSData data] error:NULL]) {
        return; // don't write to output stream if any error occurs
    }
    
    [super connection:connection didReceiveData:data];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // track custom bytes read because totalBytesRead persists between pause/resume.
        self.totalBytesReadPerDownload += [data length];
        
        if (self.progressiveDownloadProgress) {
             self.progressiveDownloadProgress([data length],
                                              self.totalBytesRead,
                                              self.response.expectedContentLength,
                                              self.totalBytesReadPerDownload + self.offsetContentLength,
                                              self.totalContentLength);
        }
    });
}

@end

#endif

@implementation ACSFileDownloader

@synthesize URL = _URL;
@synthesize path = _path;
@synthesize method = _method;
@synthesize delegate = _delegate;
@synthesize parameters = _parameters;
@synthesize responseType = _responseType;
@synthesize progressBlock = _progressBlock;

- (instancetype)init {
    return [self initWithShouldResume:YES];
}

- (instancetype)initWithShouldResume:(BOOL) shouldResume {
    self = [super init];
    if (self) {
        _shouldResume = shouldResume;
    }
    return self;
}

#ifdef _AFNETWORKING_

@synthesize operation = _operation;
@synthesize operationManager = _operationManager;

- (void)URLOperationFormManager:(AFHTTPRequestOperationManager *)operationManager
             downloadExpiration:(NSTimeInterval)timeInterval
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    _operationManager = operationManager;
    self.URL = self.URL ?: [NSURL URLWithString:self.path ?: @""
                                  relativeToURL:operationManager.baseURL];
    NSURLRequest *URLRequest = [[operationManager.requestSerializer requestWithMethod:@"GET"
                                                                            URLString:self.URL.absoluteString
                                                                           parameters:self.parameters
                                                                                error:nil] copy];
    
    NSString *filePath = [[ACSCache sharedCache] fetchAbsolutePathforURL:self.URL];
    NSData *fileData = ACSFileDataFromPath(filePath, timeInterval);
    if (fileData) {
        id resultData = nil;
        if (self.responseType == ACSResponseTypeFilePath) {
            resultData = filePath;
        }
        else if (self.responseType == ACSResponseTypeImage) {
#if TARGET_OS_IPHONE
            resultData = [UIImage imageWithData:fileData];
#else
            resultData = [[NSImage alloc] initWithData:fileData];
#endif
        }
        else if (self.responseType == ACSResponseTypeData) {
            resultData = fileData;
        }
        if (self.progressBlock) {
            self.progressBlock(ACSRequestProgressZero, resultData, nil);
        }
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                [self.delegate request:self didReceiveData:resultData];
            }
        }
        return;
    }
    
    ACSDownloadRequestOperation *operation = [[ACSDownloadRequestOperation alloc] initWithRequest:URLRequest
                                                                                     shouldResume:self.shouldResume];
    
    __weak __typeof__(operation) woperation = operation;
    __weak __typeof(self) wrequester = self;
    [operation setProgressiveDownloadProgress:^(NSUInteger bytesRead,
                                                long long totalBytesRead,
                                                long long totalBytesExpectedToRead,
                                                long long totalBytesReadForFile,
                                                long long totalBytesExpectedToReadForFile) {
        __strong __typeof(woperation) soperation = woperation;
        if (soperation) {
            
            NSInteger statusCode = soperation.response.statusCode;
            if (statusCode == 200 || statusCode == 206) {
                __strong __typeof(wrequester) srequester = wrequester;
                if (srequester) {
                    
                    CGFloat progressValue = 0.0;
                    if (totalBytesExpectedToRead > 0) {
                        progressValue = totalBytesReadForFile / (totalBytesExpectedToReadForFile  * 1.0f);
                    }
                    
                    if (srequester.progressBlock) {
                        
                        srequester.progressBlock(ACSRequestProgressMake(bytesRead,
                                                                        progressValue,
                                                                        totalBytesRead,
                                                                        totalBytesExpectedToRead), nil, nil);
                    }
                    if (srequester.delegate) {
                        if ([srequester.delegate respondsToSelector:@selector(request:didFileProgressing:)]) {
                            [srequester.delegate request:srequester didFileProgressing:ACSRequestProgressMake(bytesRead,
                                                                                                              progressValue,
                                                                                                              totalBytesRead,
                                                                                                              totalBytesExpectedToRead)];
                        }
                    }
                }
            }
        }
    }];
    [operation setCompletionBlockWithSuccess:success failure:failure];
    
    _operation = operation;
    [operationManager.operationQueue addOperation:operation];
}

- (void)cancel {
    if (!self.operation) {
        return;
    }
    
    [self.operation cancel];
}

- (BOOL)pause {

    if (!self.operation ||
        [self.operation isPaused]) {
        return NO;
    }
    
    [self.operation pause];
    return YES;
}

- (BOOL)resume {
    if (!self.operation ||
        ![self.operation isPaused]) {
        return NO;
    }
    
    [self.operation resume];
    return YES;
}

- (BOOL)isPaused {
    
    return [self.operation isPaused];
}

- (BOOL)isExecuting {
    return [self.operation isExecuting];
}

#endif

/**
 限死请求方式
 */
- (ACSRequestMethod)method {
    return ACSRequestMethodGET;
}

@end

ACSNETWORK_STATIC_INLINE void ACSSetupCallback(ACSFileDownloader **downloader, id *callback) {
    if (*callback) {
        if ([(*callback) conformsToProtocol:@protocol(ACSURLRequesterDelegate)]) {
            (*downloader).delegate = *callback;
        }
        else {
            if (strstr(object_getClassName(*callback), "Block") != NULL) {
                (*downloader).progressBlock = *callback;
            }
        }
    }
}

#pragma mark - Path

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(NSString *path, BOOL shouldResume, id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] initWithShouldResume:shouldResume];
    downloader.path = path;
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(NSString *path, id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] init];
    downloader.path = path;
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}

#pragma mark - URL

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(NSURL *URL, id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] init];
    downloader.URL = URL;
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(NSURL *URL, BOOL shouldResume, id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] initWithShouldResume:shouldResume];
    downloader.URL = URL;
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}

#pragma mark - Default BaseURL

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] init];
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}

__attribute__((overloadable)) ACSFileDownloader * ACSCreateDownloader(BOOL shouldResume, id callback) {
    ACSFileDownloader *downloader = [[ACSFileDownloader alloc] initWithShouldResume:shouldResume];
    downloader.responseType = ACSResponseTypeFilePath;
    ACSSetupCallback(&downloader, &callback);
    return downloader;
}
