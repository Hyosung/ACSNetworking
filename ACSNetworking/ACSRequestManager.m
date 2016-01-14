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

NSString *const ACSNetworkingErrorDomain = @"com.stoney.ACSNetworkingErrorDomain";
NSString *const ACSNetworkingErrorDescriptionKey = @"ACSNetworkingErrorDescriptionKey";

@interface ACSRequestManager ()

#ifdef _AFNETWORKING_
@property (nonatomic, strong) ACSNetworkConfiguration *configuration;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, weak  ) AFHTTPRequestSerializer <AFURLRequestSerialization> *rs;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void (^)(AFHTTPRequestOperation *, id))requestSuccess:(id <ACSURLHTTPRequest>) requester;
- (void (^)(AFHTTPRequestOperation *, NSError *))requestFailure:(id <ACSURLHTTPRequest>) requester;
#endif

@end

@implementation ACSRequestManager

#pragma mark - Extern Method

NSString * ACSFilePathFromURL(NSURL *URL, NSString *folderPath, NSString *extension) {
    
    assert(URL);
    assert(folderPath);
    
    NSString *pathExtension = (extension && ![extension isEqualToString:@""]) ? [NSString stringWithFormat:@".%@", [extension lowercaseString]] : @"";
    NSString *fileName = [NSString stringWithFormat:@"%@%@", ACSFileNameForURL(URL), pathExtension];
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    return filePath;
}

NSData * ACSFileDataFromPath(NSString *path, NSTimeInterval downloadExpirationTimeInterval) {
    NSFileManager *fileManager = [NSFileManager new];
    if (![fileManager fileExistsAtPath:path]) {
        return nil;
    }
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    if (fileAttributes) {
        //判断文件是否过期
        NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:[fileAttributes fileModificationDate]];
        if (timeDifference > downloadExpirationTimeInterval) {
            return nil;
        }
    }
    return [fileManager contentsAtPath:path];
}

unsigned long long ACSFileSizeFromPath(NSString *path) {
    unsigned long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileAttributes) {
            fileSize = [fileAttributes fileSize];
        }
    }
    return fileSize;
}

#pragma mark - Static inline

///**
// *  @author Stoney, 15-07-31 09:07:27
// *
// *  @brief  生成请求的标识
// *
// */
//ACSNETWORK_STATIC_INLINE NSString * ACSGenerateOperationIdentifier() {
//    return [NSString stringWithFormat:@"%08x%08x", arc4random(), arc4random()];
//}

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

ACSNETWORK_STATIC_INLINE NSString * ACSExtensionFromContentType(NSString *contentType) {
    
    NSRange pointRange = [contentType rangeOfString:@"."options:NSBackwardsSearch];
    if (pointRange.location == NSNotFound) {
        return nil;
    }
    
    return [contentType substringFromIndex:pointRange.location + 1];
}

#ifdef _AFNETWORKING_

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static ACSRequestManager *network = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        network = [[self alloc] initWithConfiguration:nil];
    });
    return network;
}

+ (instancetype)manager {
    return [[self alloc] initWithConfiguration:nil];
}

- (instancetype)initWithConfiguration:(ACSNetworkConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration ?: [ACSNetworkConfiguration defaultConfiguration];
        
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.configuration.baseURL];
        self.manager.requestSerializer = self.configuration.requestSerializer;
        self.manager.responseSerializer = self.configuration.responseSerializer;
        self.manager.securityPolicy = self.configuration.securityPolicy;
        self.rs = self.configuration.requestSerializer;
        self.fileManager = [NSFileManager new];
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (NSString *)description {
#ifdef _AFNETWORKING_
    return [NSString stringWithFormat:@"<%@: %p, manager: %@>", NSStringFromClass([self class]), self, self.manager];
#else
    return [super description];
#endif
}


#pragma mark - Request Operation

- (void)cancelAllOperations {
    [self.manager.operationQueue cancelAllOperations];
}

#pragma mark - Request Methods

- (void)fetchDataFromRequester:(ACSURLHTTPRequester *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(!(requester.path && requester.URL), @"path与URL只能填写其中一个");
    NSAssert(requester.responseType == ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂只支持JSON与data");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL operationCreateSEL = @selector(URLOperationFormManager:cacheExpiration:success:failure:);
#pragma clang diagnostic pop
    
    NSAssert([requester respondsToSelector:operationCreateSEL], @"未找到URLOperationFormManager:cacheExpiration:success:failure:");
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[requester methodSignatureForSelector:operationCreateSEL]];
    invocation.target = requester;
    invocation.selector = operationCreateSEL;
    
    NSTimeInterval cacheExpirationTimeInterval = self.configuration.cacheExpirationTimeInterval;
    AFHTTPRequestOperationManager *manager = self.manager;
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = [self requestSuccess:requester];
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = [self requestFailure:requester];
    
    [invocation setArgument:&manager atIndex:2];
    [invocation setArgument:&cacheExpirationTimeInterval atIndex:3];
    [invocation setArgument:&success atIndex:4];
    [invocation setArgument:&failure atIndex:5];
    [invocation invoke];
}

- (void)uploadFileFromRequester:(ACSFileUploader *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(!(requester.path && requester.URL), @"path与URL只能填写其中一个");
    NSAssert(requester.responseType == ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂只支持JSON与data");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL operationCreateSEL = @selector(URLOperationFormManager:success:failure:);
#pragma clang diagnostic pop
    
    NSAssert([requester respondsToSelector:operationCreateSEL], @"未找到URLOperationFormManager:success:failure:");
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[requester methodSignatureForSelector:operationCreateSEL]];
    invocation.target = requester;
    invocation.selector = operationCreateSEL;
    
    AFHTTPRequestOperationManager *manager = self.manager;
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = [self requestSuccess:requester];
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = [self requestFailure:requester];
    [invocation setArgument:&manager atIndex:2];
    [invocation setArgument:&success atIndex:3];
    [invocation setArgument:&failure atIndex:4];
    [invocation invoke];
}

- (void)downloadFileFromRequester:(ACSFileDownloader *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(!(requester.path && requester.URL), @"path与URL只能填写其中一个");
    NSAssert(requester.responseType != ACSResponseTypeJSON || requester.responseType == ACSResponseTypeData, @"responseType暂不只支持JSON");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL operationCreateSEL = @selector(URLOperationFormManager:downloadExpiration:success:failure:);
#pragma clang diagnostic pop
    
    NSAssert([requester respondsToSelector:operationCreateSEL], @"未找到URLOperationFormManager:downloadExpiration:success:failure:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[requester methodSignatureForSelector:operationCreateSEL]];
    invocation.target = requester;
    invocation.selector = operationCreateSEL;
    
    NSTimeInterval downloadExpirationTimeInterval = self.configuration.downloadExpirationTimeInterval;
    AFHTTPRequestOperationManager *manager = self.manager;
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = [self requestSuccess:requester];
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = [self requestFailure:requester];
    
    [invocation setArgument:&manager atIndex:2];
    [invocation setArgument:&downloadExpirationTimeInterval atIndex:3];
    [invocation setArgument:&success atIndex:4];
    [invocation setArgument:&failure atIndex:5];
//    [invocation retainArguments];
    [invocation invoke];
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
            
            if (requester.delegate) {
                if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                    [requester.delegate request:requester didReceiveData:resultObject];
                }
                
                if ([requester.delegate respondsToSelector:@selector(request:didFailToProcessForDataWithError:)] && error) {
                    [requester.delegate request:requester didFailToProcessForDataWithError:error];
                }
            }
        }
        else if ([requester isKindOfClass:[ACSFileDownloader class]]) {
            NSString *filePath;
            BOOL isExist;
            @synchronized(self) {
                //获取后缀
                NSString *extension = ACSExtensionFromMIMEType(operation.response.MIMEType);
                if (!extension || [extension isEqualToString:@""]) {
                    extension = ACSExtensionFromContentType([operation.response.allHeaderFields valueForKey:@"Content-Type"]);
                }
                //下载路径
                filePath = ACSFilePathFromURL(requester.URL, self.configuration.downloadFolder, extension);
                NSString *srcFilePath = ACSFilePathFromURL(requester.URL, NSTemporaryDirectory(), @"tmp");
                //删除已存在的文件以便于后面的移动操作
                if ([self.fileManager fileExistsAtPath:srcFilePath]) {
                    
                    if ([self.fileManager fileExistsAtPath:filePath]) {
                        [self.fileManager removeItemAtPath:filePath error:NULL];
                    }
                    //移动
                    if ([self.fileManager moveItemAtPath:srcFilePath toPath:filePath error:NULL]) {
                        [[ACSCache sharedCache] storeAbsolutePath:filePath forURL:requester.URL];
                    }
                }
                isExist = [self.fileManager fileExistsAtPath:filePath];
            }
            id resultData = nil;
            if (isExist) {
                if (requester.responseType == ACSResponseTypeFilePath) {
                    resultData = filePath;
                }
                else if (requester.responseType == ACSResponseTypeImage) {
#if TARGET_OS_IPHONE
                    resultData = [UIImage imageWithContentsOfFile:filePath];
#else
                    resultData = [[NSImage alloc] initWithContentsOfFile:filePath];
#endif
                    NSAssert(resultData, @"当前下载文件并非图片，请使用ACSResponseTypeFilePath");
                }
                else if (requester.responseType == ACSResponseTypeData) {
                    resultData = [self.fileManager contentsAtPath:filePath];
                }
            }
            
            if (((ACSFileDownloader *)requester).progressBlock) {
                ((ACSFileDownloader *)requester).progressBlock(ACSRequestProgressZero, resultData, nil);
            }
            if (requester.delegate) {
                if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                    [requester.delegate request:requester didReceiveData:resultData];
                }
                
                if ([requester.delegate respondsToSelector:@selector(request:didFailToProcessForDataWithError:)] && !resultData) {
                    NSError *error = [NSError errorWithDomain:ACSNetworkingErrorDomain code:ACSNetworkingErrorCodeEmptyData userInfo:@{ACSNetworkingErrorDescriptionKey: @"Empty Data"}];
                    [requester.delegate request:requester didFailToProcessForDataWithError:error];
                }
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
            
            if (requester.delegate) {
                if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                    [requester.delegate request:requester didReceiveData:resultObject];
                }
                
                if ([requester.delegate respondsToSelector:@selector(request:didFailToProcessForDataWithError:)] && error) {
                    [requester.delegate request:requester didFailToProcessForDataWithError:error];
                }
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
            id resultObject = nil;
            if (((ACSURLHTTPRequester *)requester).cacheResponseData &&
                ((ACSURLHTTPRequester *)requester).method == ACSRequestMethodGET) {
                resultObject = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:requester.URL
                                                                    cacheExpiration:self.configuration.cacheExpirationTimeInterval];
            }
            if (((ACSURLHTTPRequester *)requester).completionBlock) {
                ((ACSURLHTTPRequester *)requester).completionBlock(resultObject, resultObject ? nil : error);
            }
            
            if (requester.delegate) {
                if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)] && resultObject) {
                    [requester.delegate request:requester didReceiveData:resultObject];
                }
                
                if ([requester.delegate respondsToSelector:@selector(request:didFailToRequestForDataWithError:)] && error) {
                    [requester.delegate request:requester didFailToRequestForDataWithError:error];
                }
            }
        }
        else if ([requester isKindOfClass:[ACSFileUploader class]] ||
                 [requester isKindOfClass:[ACSFileDownloader class]]) {
            if (((id <ACSURLFileRequest>)requester).progressBlock) {
                ((id <ACSURLFileRequest>)requester).progressBlock(ACSRequestProgressZero, nil, error);
            }
            if (requester.delegate) {
                if ([requester.delegate respondsToSelector:@selector(request:didFailToRequestForDataWithError:)]) {
                    [requester.delegate request:requester didFailToRequestForDataWithError:error];
                }
            }
        }
    };
    return failureBlock;
}
#endif

@end

#pragma mark - 旧写法

@implementation ACSRequestManager (ACSRequestManagerBlockOld)

#ifdef _AFNETWORKING_

- (ACSURLHTTPRequester *)fetchDataFromPath:(NSString *)path
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

- (ACSURLHTTPRequester *)GET_fetchDataFromPath:(NSString *)path
                                    parameters:(NSDictionary *)parameters
                                    completion:(ACSRequestCompletionHandler)completionBlock{
    return [self fetchDataFromPath:path
                            method:ACSRequestMethodGET
                        parameters:parameters
                        completion:completionBlock];
}

- (ACSURLHTTPRequester *)POST_fetchDataFromPath:(NSString *)path
                                     parameters:(NSDictionary *)parameters
                                     completion:(ACSRequestCompletionHandler)completionBlock {
    return [self fetchDataFromPath:path
                            method:ACSRequestMethodPOST
                        parameters:parameters
                        completion:completionBlock];
}

- (ACSFileUploader *)uploadFileFromPath:(NSString *)path
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

- (ACSFileDownloader *)downloadFileFromPath:(NSString *)path
                                   progress:(ACSRequestProgressHandler)progressBlock{
    NSURL *URL = [NSURL URLWithString:path ?: @""
                        relativeToURL:self.manager.baseURL];
    return [self downloadFileFromURLString:URL.absoluteString
                                  progress:progressBlock];
}


- (ACSURLHTTPRequester *)fetchDataFromURLString:(NSString *)URLString
                                         method:(ACSRequestMethod)method
                                     parameters:(NSDictionary *)parameters
                                     completion:(ACSRequestCompletionHandler)completionBlock {
    ACSURLHTTPRequester *requester = ACSCreateRequester([NSURL URLWithString:URLString],
                                                        method,
                                                        parameters,
                                                        completionBlock);
    [self fetchDataFromRequester:requester];
    return requester;
}

- (ACSFileUploader *)uploadFileFromURLString:(NSString *)URLString
                                    fileInfo:(NSDictionary *)fileInfo
                                  parameters:(NSDictionary *)parameters
                                    progress:(ACSRequestProgressHandler)progressBlock {
    ACSFileUploader *uploader = ACSCreateUploader([NSURL URLWithString:URLString],
                                                  fileInfo,
                                                  progressBlock);
    uploader.parameters = parameters;
    [self uploadFileFromRequester:uploader];
    return uploader;
}

- (ACSFileDownloader *)downloadFileFromURLString:(NSString *)URLString
                                        progress:(ACSRequestProgressHandler)progressBlock{
    ACSFileDownloader *downloader = ACSCreateDownloader([NSURL URLWithString:URLString], progressBlock);
    [self downloadFileFromRequester:downloader];
    return downloader;
}

#endif

@end
