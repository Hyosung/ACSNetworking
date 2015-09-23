// ACSRequestManager.m
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

#import "ACSRequestManager.h"

#import "ACSFileUploader.h"
#import "ACSFileDownloader.h"
#import "ACSURLHTTPRequester.h"

#import "ACSNetworkConfiguration.h"
#import "ACSCache.h"

#import <CommonCrypto/CommonDigest.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>
#endif

@interface ACSRequestManager ()

#ifdef _AFNETWORKING_
@property (nonatomic, strong) ACSNetworkConfiguration *configuration;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, weak  ) AFHTTPRequestSerializer <AFURLRequestSerialization> *rs;
@property (nonatomic, strong) NSMapTable *operations;

- (void (^)(AFHTTPRequestOperation *, id))requestSuccess:(id <ACSURLHTTPRequest>) requester;
- (void (^)(AFHTTPRequestOperation *, NSError *))requestFailure:(id <ACSURLHTTPRequest>) requester;
#endif

@end

@implementation ACSRequestManager

#pragma mark - Static inline

/**
 *  @author Stoney, 15-07-31 09:07:27
 *
 *  @brief  生成请求的标识
 *
 */
ACSNETWORK_STATIC_INLINE NSString * ACSGenerateOperationIdentifier() {
    return [NSString stringWithFormat:@"%08x%08x", arc4random(), arc4random()];
}

ACSNETWORK_STATIC_INLINE NSString * ACSFileNameForURL(NSURL *URL) {
    const char *str = [URL.absoluteString UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSMutableString *md5Ciphertext = [NSMutableString stringWithString:@""];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5Ciphertext appendFormat:@"%02x",r[i]];
    }
    return [md5Ciphertext copy];
}

ACSNETWORK_STATIC_INLINE NSString * ACSFilePathFromURL(NSURL *URL, NSString *folderPath, NSString *extension) {
    
    assert(URL);
    assert(folderPath);
    
    NSString *pathExtension = extension ? [NSString stringWithFormat:@".%@", [extension lowercaseString]] : @"";
    NSString *fileName = [NSString stringWithFormat:@"%@%@", ACSFileNameForURL(URL), pathExtension];
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    return filePath;
}

ACSNETWORK_STATIC_INLINE NSData * ACSFileDataFromPath(NSString *path) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    if (fileAttributes) {
        //判断文件是否过期
        NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:[fileAttributes fileModificationDate]];
        if (timeDifference > [ACSNetworkConfiguration defaultConfiguration].downloadExpirationTimeInterval) {
            return nil;
        }
    }
    return [[NSFileManager defaultManager] contentsAtPath:path];
}

ACSNETWORK_STATIC_INLINE NSString * ACSExtensionFromMIMEType(NSString *MIMEType) {
    
#ifdef __UTTYPE__
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)MIMEType, NULL);
    CFStringRef filenameExtension = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassFilenameExtension);
    CFRelease(UTI);
    if (!filenameExtension) {
        return @"";
    }
    return CFBridgingRelease(filenameExtension);
#else
#pragma unused (MIMEType)
    return @"";
#endif
}

#ifdef _AFNETWORKING_

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static ACSRequestManager *network = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        network = [[self alloc] init];
    });
    return network;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configuration = [ACSNetworkConfiguration defaultConfiguration];
        
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.configuration.baseURL];
        self.manager.requestSerializer.timeoutInterval = self.configuration.timeoutInterval;
        self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.rs = self.manager.requestSerializer;
        self.operations = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

#pragma mark - Request Operation

- (void)cancelAllOperations {
    [self.manager.operationQueue cancelAllOperations];
    [self.operations removeAllObjects];
}

- (void)cancelOperationWithIdentifier:(NSString *) identifier {
    if (!identifier) {
        return;
    }
    NSOperation *operation = [self.operations objectForKey:identifier];
    if (!operation) {
        return;
    }
    
    [operation cancel];
    [self.operations removeObjectForKey:identifier];
}

- (void)pauseOperationWithIdentifier:(NSString *) identifier {
    if (!identifier) {
        return;
    }
    AFHTTPRequestOperation *operation = [self.operations objectForKey:identifier];
    if (!(operation && ![operation isPaused])) {
        return;
    }
    [operation pause];
}

- (void)resumeOperationWithIdentifier:(NSString *) identifier {
    if (identifier) {
        AFHTTPRequestOperation *operation = [self.operations objectForKey:identifier];
        if (operation && [operation isPaused]) {
            [operation resume];
        }
    }
}

- (BOOL)isPausedOperationWithIdentifier:(NSString *) identifier {
    if (!identifier) {
        return NO;
    }
    
    AFHTTPRequestOperation *operation = [self.operations objectForKey:identifier];
    if (!operation) {
        return NO;
    }
    
    return [operation isPaused];
}

- (BOOL)isExecutingOperationWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return NO;
    }
    
    AFHTTPRequestOperation *operation = [self.operations objectForKey:identifier];
    if (!operation) {
        return NO;
    }
    
    return [operation isExecuting];
}

#pragma mark - Request Methods

- (NSString *)fetchDataFromRequester:(ACSURLHTTPRequester *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(requester.path || requester.URL, @"path与URL只能填写其中一个");
    NSAssert(requester.responseType == ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂只支持JSON与data");
    
    NSMutableURLRequest *URLRequest = [requester URLRequestFormOperationManager:self.manager];
    
    //取本地缓存
    id resultObject = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:URLRequest.URL];
    if (resultObject && requester.method == ACSRequestMethodGET && requester.cacheResponseData) {
        id tempResult = resultObject;
        if ([resultObject isKindOfClass:[NSData class]]) {
            if (requester.responseType == ACSResponseTypeJSON) {
                tempResult = [NSJSONSerialization JSONObjectWithData:resultObject options:NSJSONReadingAllowFragments error:nil];
            }
        }
        else if ([resultObject isKindOfClass:[NSDictionary class]] ||
                 [resultObject isKindOfClass:[NSArray class]]) {
            tempResult = [NSJSONSerialization dataWithJSONObject:resultObject options:NSJSONWritingPrettyPrinted error:nil];
        }
        
        if (requester.completionBlock) {
            requester.completionBlock(tempResult, nil);
        }
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:URLRequest
                                                                              success:[self requestSuccess:requester]
                                                                              failure:[self requestFailure:requester]];
    [self.manager.operationQueue addOperation:operation];
    
    NSString *operationIdentifier = ACSGenerateOperationIdentifier();
    [self.operations setObject:operation forKey:operationIdentifier];
    
    return operationIdentifier;
}

- (NSString *)uploadFileFromRequester:(ACSFileUploader *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(requester.path || requester.URL, @"path与URL只能填写其中一个");
    NSAssert(requester.responseType == ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂只支持JSON与data");
    
    NSMutableURLRequest *URLRequest = [requester URLRequestFormOperationManager:self.manager];
    
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:URLRequest
                                                                              success:[self requestSuccess:requester]
                                                                              failure:[self requestFailure:requester]];
    
    if (requester.progressBlock) {
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten,
                                            long long totalBytesWritten,
                                            long long totalBytesExpectedToWrite) {
            requester.progressBlock(ACSRequestProgressMake(bytesWritten,
                                                           totalBytesWritten,
                                                           totalBytesExpectedToWrite), nil, nil);
        }];
    }
    
    [self.manager.operationQueue addOperation:operation];
    NSString *operationIdentifier = ACSGenerateOperationIdentifier();
    [self.operations setObject:operation forKey:operationIdentifier];
    
    return operationIdentifier;
}

- (NSString *)downloadFileFromRequester:(ACSFileDownloader *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(requester.path || requester.URL, @"path与URL只能填写其中一个");
    NSAssert(requester.responseType != ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂不只支持JSON");
    
    NSMutableURLRequest *URLRequest = [requester URLRequestFormOperationManager:self.manager];
    NSString *filePath = [[ACSCache sharedCache] fetchAbsolutePathforURL:URLRequest.URL];
    NSData *fileData = ACSFileDataFromPath(filePath);
    if (fileData) {
        id resultData = nil;
        if (requester.responseType == ACSResponseTypeFilePath) {
            resultData = filePath;
        }
        else if (requester.responseType == ACSResponseTypeImage) {
#if TARGET_OS_IPHONE
            resultData = [UIImage imageWithData:fileData];
#else
            resultData = [[NSImage alloc] initWithData:fileData];
#endif
        }
        else if (requester.responseType == ACSResponseTypeData) {
            resultData = fileData;
        }
        if (requester.progressBlock) {
            requester.progressBlock(ACSRequestProgressZero, resultData, nil);
        }
        return nil;
    }
    
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:URLRequest
                                                                              success:[self requestSuccess:requester]
                                                                              failure:[self requestFailure:requester]];
    
    filePath = ACSFilePathFromURL(URLRequest.URL, [ACSNetworkConfiguration defaultConfiguration].downloadFolder, nil);
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    if (requester.progressBlock) {
        
        __weak __typeof__(operation) weakOperation = operation;
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead,
                                              long long totalBytesRead,
                                              long long totalBytesExpectedToRead) {
            if (weakOperation.response.statusCode == 200) {
                requester.progressBlock(ACSRequestProgressMake(bytesRead,
                                                               totalBytesRead,
                                                               totalBytesExpectedToRead), nil, nil);
            }
        }];
    }
    
    [self.manager.operationQueue addOperation:operation];
    
    NSString *operationIdentifier = ACSGenerateOperationIdentifier();
    [self.operations setObject:operation forKey:operationIdentifier];
    
    return operationIdentifier;
}

- (NSString *)fetchDataFromPath:(NSString *)path
                         method:(ACSRequestMethod)method
                     parameters:(NSDictionary *)parameters
                     completion:(ACSRequestCompletionHandler)completionBlock {
    NSURL *URL = [NSURL URLWithString:path ?: @""
                        relativeToURL:self.manager.baseURL];
    
    return [self fetchDataFromURLString:URL.absoluteString
                                 method:method
                             parameters:parameters
                             completion:completionBlock];
}

- (NSString *)GET_fetchDataFromPath:(NSString *)path
                         parameters:(NSDictionary *)parameters
                         completion:(ACSRequestCompletionHandler)completionBlock{
    return [self fetchDataFromPath:path
                            method:ACSRequestMethodGET
                        parameters:parameters
                        completion:completionBlock];
}

- (NSString *)POST_fetchDataFromPath:(NSString *)path
                          parameters:(NSDictionary *)parameters
                          completion:(ACSRequestCompletionHandler)completionBlock {
    return [self fetchDataFromPath:path
                            method:ACSRequestMethodPOST
                        parameters:parameters
                        completion:completionBlock];
}

- (NSString *)uploadFileFromPath:(NSString *)path
                        fileInfo:(NSDictionary *)fileInfo
                      parameters:(NSDictionary *)parameters
                        progress:(ACSRequestProgressHandler)progressBlock {
    NSURL *URL = [NSURL URLWithString:path ?: @""
                        relativeToURL:self.manager.baseURL];
    return [self uploadFileFromURLString:URL.absoluteString
                                fileInfo:fileInfo
                              parameters:parameters
                                progress:progressBlock];
}

- (NSString *)downloadFileFromPath:(NSString *)path
                          progress:(ACSRequestProgressHandler)progressBlock{
    NSURL *URL = [NSURL URLWithString:path ?: @""
                        relativeToURL:self.manager.baseURL];
    return [self downloadFileFromURLString:URL.absoluteString
                                  progress:progressBlock];
}


- (NSString *)fetchDataFromURLString:(NSString *)URLString
                              method:(ACSRequestMethod)method
                          parameters:(NSDictionary *)parameters
                          completion:(ACSRequestCompletionHandler)completionBlock {
    ACSURLHTTPRequester *requester = ACSCreateRequester([NSURL URLWithString:URLString],
                                                        method,
                                                        parameters,
                                                        completionBlock);
    return [self fetchDataFromRequester:requester];
}

- (NSString *)uploadFileFromURLString:(NSString *)URLString
                             fileInfo:(NSDictionary *)fileInfo
                           parameters:(NSDictionary *)parameters
                             progress:(ACSRequestProgressHandler)progressBlock {
    ACSFileUploader *uploader = ACSCreateUploader([NSURL URLWithString:URLString],
                                                  fileInfo,
                                                  progressBlock);
    uploader.parameters = parameters;
    return [self uploadFileFromRequester:uploader];
}

- (NSString *)downloadFileFromURLString:(NSString *)URLString
                               progress:(ACSRequestProgressHandler)progressBlock{
    ACSFileDownloader *downloader = ACSCreateDownloader([NSURL URLWithString:URLString], progressBlock);
    return [self downloadFileFromRequester:downloader];
}

#pragma mark - Extension Methods

- (void (^)(AFHTTPRequestOperation *, id))requestSuccess:(id<ACSURLHTTPRequest>)requester {
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^ (AFHTTPRequestOperation *operation,
                                                            id responseObject) {
        
        if (operation.isCancelled) {
            return;
        }
        
        if ([requester isKindOfClass:[ACSURLHTTPRequester class]]) {
            NSError *error = nil;
            id resultObject = responseObject;
            if (((ACSURLHTTPRequester *)requester).responseType == ACSResponseTypeJSON) {
                
                resultObject  = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
            }
            
            if (((ACSURLHTTPRequester *)requester).cacheResponseData &&
                ((ACSURLHTTPRequester *)requester).method == ACSRequestMethodGET &&
                resultObject) {
                
                [[ACSCache sharedCache] storeCacheData:resultObject forURL:requester.URL];
            }
            
            if (((ACSURLHTTPRequester *)requester).completionBlock) {
                ((ACSURLHTTPRequester *)requester).completionBlock(resultObject, error);
            }
        }
        else if ([requester isKindOfClass:[ACSFileDownloader class]]) {
            //获取后缀
            NSString *extension = ACSExtensionFromMIMEType(operation.response.MIMEType);
            //下载路径
            NSString *filePath = ACSFilePathFromURL(requester.URL, [ACSNetworkConfiguration defaultConfiguration].downloadFolder, extension);
            NSString *srcFilePath = [filePath stringByDeletingPathExtension];
            
            //删除已存在的文件以便于后面的移动操作
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            //移动
            if ([[NSFileManager defaultManager] moveItemAtPath:srcFilePath toPath:filePath error:nil]) {
                [[ACSCache sharedCache] storeAbsolutePath:filePath forURL:requester.URL];
            }
            
            NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:filePath];
            id resultData = nil;
            if (fileData) {
                if (requester.responseType == ACSResponseTypeFilePath) {
                    resultData = filePath;
                }
                else if (requester.responseType == ACSResponseTypeImage) {
#if TARGET_OS_IPHONE
                    resultData = [UIImage imageWithData:fileData];
#else
                    resultData = [[NSImage alloc] initWithData:fileData];
#endif
                }
                else if (requester.responseType == ACSResponseTypeData) {
                    resultData = fileData;
                }
            }
            
            if (((ACSFileDownloader *)requester).progressBlock) {
                ((ACSFileDownloader *)requester).progressBlock(ACSRequestProgressZero, resultData, nil);
            }
        }
        else if ([requester isKindOfClass:[ACSFileUploader class]]) {
            NSError *error = nil;
            id resultObject = responseObject;
            if (((ACSFileUploader *)requester).responseType == ACSResponseTypeJSON) {
                
                resultObject  = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
            }
            
            if (((ACSFileUploader *)requester).progressBlock) {
                ((ACSFileUploader *)requester).progressBlock(ACSRequestProgressZero, resultObject, error);
            }
        }
    };
    return successBlock;
}

- (void (^)(AFHTTPRequestOperation *, NSError *))requestFailure:(id<ACSURLHTTPRequest>)requester {
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^ (AFHTTPRequestOperation *operation,
                                                                   NSError *error) {
        
        if (operation.isCancelled) {
            return;
        }
        
        if ([requester isKindOfClass:[ACSURLHTTPRequester class]]) {
            if (((ACSURLHTTPRequester *)requester).completionBlock) {
                
                id resultObject = nil;
                if (((ACSURLHTTPRequester *)requester).cacheResponseData &&
                    ((ACSURLHTTPRequester *)requester).method == ACSRequestMethodGET) {
                    resultObject = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:requester.URL];
                }
                ((ACSURLHTTPRequester *)requester).completionBlock(resultObject, resultObject ? nil : error);
            }
        }
        else if ([requester isKindOfClass:[ACSFileUploader class]] ||
                 [requester isKindOfClass:[ACSFileDownloader class]]) {
            if (((id <ACSURLFileRequest>)requester).progressBlock) {
                ((id <ACSURLFileRequest>)requester).progressBlock(ACSRequestProgressZero, nil, error);
            }
        }
    };
    return failureBlock;
}
#endif

@end