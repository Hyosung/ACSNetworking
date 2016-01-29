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
#import "ACSReachability.h"
#import "ACSCache.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#else
#import <AppKit/AppKit.h>
#endif

NSString *const ACSNetworkingErrorDomain = @"com.stoney.ACSNetworkingErrorDomain";
NSString *const ACSNetworkingErrorDescriptionKey = @"ACSNetworkingErrorDescriptionKey";

@interface ACSRequestManager ()

#ifdef _AFNETWORKING_
@property (nonatomic, strong) ACSNetworkConfiguration *configuration;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) ACSReachability *reachability;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void (^)(AFHTTPRequestOperation *, id))requestSuccess:(ACSHTTPRequest *) requester;
- (void (^)(AFHTTPRequestOperation *, NSError *))requestFailure:(ACSHTTPRequest *) requester;
- (void)loadData:(ACSHTTPRequest *) requester;
- (void)failureCallback:(ACSHTTPRequest *) requester error:(NSError *) error;

#endif

@end

@implementation ACSRequestManager

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

#ifdef _AFNETWORKING_

#pragma mark - Lifecycle

- (void)dealloc {
    [self.reachability stopNotifier];
    self.reachability = nil;
}

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
        self.manager.securityPolicy = self.configuration.securityPolicy;
        self.fileManager = [NSFileManager new];
        self.reachability = [ACSReachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, manager: %@>", NSStringFromClass([self class]), self, self.manager];
}


#pragma mark - Request Operation

- (void)cancelAllOperations {
    [self.manager.operationQueue cancelAllOperations];
}

#pragma mark - Request Methods

- (void)fetchDataFromRequester:(ACSURLHTTPRequester *) requester {
    [self loadData:requester];
}

- (void)uploadFileFromRequester:(ACSFileUploader *) requester {
    [self loadData:requester];
}

- (void)downloadFileFromRequester:(ACSFileDownloader *) requester {
    [self loadData:requester];
}

#pragma mark - Private Methods

- (void (^)(AFHTTPRequestOperation *, id))requestSuccess:(ACSHTTPRequest *)requester {
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^ (AFHTTPRequestOperation *operation,
                                                            id responseObject) {
        
        if (operation.isCancelled) {
            return;
        }
        
        if ([requester isKindOfClass:[ACSURLHTTPRequester class]] || [requester isKindOfClass:[ACSFileUploader class]]) {
            
            NSError *error = nil;
            id resultObject = responseObject;
            switch (requester.responseType) {
                case ACSResponseTypeJSON: {
                    resultObject  = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];
                    break;
                }
                case ACSResponseTypePropertyList: {
                    resultObject = [NSPropertyListSerialization propertyListWithData:responseObject
                                                                             options:NSPropertyListMutableContainers
                                                                              format:NULL
                                                                               error:&error];
                    break;
                }
                    
                default:
                    break;
            }
            
            if ([requester isKindOfClass:[ACSURLHTTPRequester class]]) {
                if (((ACSURLHTTPRequester *)requester).cacheResponseData &&
                    requester.method == ACSRequestMethodGET &&
                    resultObject) {
                    
                    [[ACSCache sharedCache] storeCacheData:responseObject forURL:requester.URL];
                }
                
                if (((ACSURLHTTPRequester *)requester).completionBlock) {
                    ((ACSURLHTTPRequester *)requester).completionBlock(resultObject, error);
                }
            }
            else {
                
                if (((ACSFileUploader *)requester).progressBlock) {
                    ((ACSFileUploader *)requester).progressBlock(ACSRequestProgressZero, resultObject, error);
                }
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
                    NSError *error = [NSError errorWithDomain:ACSNetworkingErrorDomain code:ACSNetworkingErrorCodeEmptyData userInfo:@{ACSNetworkingErrorDescriptionKey: NSLocalizedStringFromTable(@"Empty Data", @"ACSNetworking", nil)}];
                    [requester.delegate request:requester didFailToProcessForDataWithError:error];
                }
            }
        }
    };
    return successBlock;
}

- (void (^)(AFHTTPRequestOperation *, NSError *))requestFailure:(ACSHTTPRequest *)requester {
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^ (AFHTTPRequestOperation *operation,
                                                                   NSError *error) {
        
        if (operation.isCancelled) {
            return;
        }
        
        [self failureCallback:requester error:error];
    };
    return failureBlock;
}

- (void)loadData:(ACSHTTPRequest *) requester {
    NSAssert(requester, @"requester不能为nil");
    NSAssert(!(requester.path && requester.URL), @"path与URL只能填写其中一个");
    
    requester.URL = requester.URL ?: [NSURL URLWithString:requester.path ?: @"" relativeToURL:self.manager.baseURL];
    
    // 加载缓存
    if ([self loadCacheData:requester]) {
        return;
    }
    
    // 判断网络是否正常
    BOOL isReachable = [self.reachability isReachable];
    
    if (!isReachable) {
        
        NSError *error = [NSError errorWithDomain:ACSNetworkingErrorDomain code:ACSNetworkingErrorCodeNoNetwork userInfo:@{ACSNetworkingErrorDescriptionKey: NSLocalizedStringFromTable(@"No Network", @"ACSNetworking", nil)}];
        [self failureCallback:requester error:error];
        return;
    }
    
    AFHTTPRequestOperationManager *manager = self.manager;
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = [self requestSuccess:requester];
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = [self requestFailure:requester];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL operationCreateSEL = @selector(URLOperationFormManager:success:failure:);
    
    NSAssert([requester respondsToSelector:operationCreateSEL], @"未找到URLOperationFormManager:success:failure:");
#pragma clang diagnostic pop
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[requester methodSignatureForSelector:operationCreateSEL]];
    invocation.target = requester;
    invocation.selector = operationCreateSEL;
    
    [invocation setArgument:&manager atIndex:2];
    [invocation setArgument:&success atIndex:3];
    [invocation setArgument:&failure atIndex:4];
    [invocation invoke];
}

- (id)loadCacheData:(ACSHTTPRequest *) requester {
    id tempData = nil;
    if ([requester isKindOfClass:[ACSURLHTTPRequester class]]) {
        if (requester.method == ACSRequestMethodGET && ((ACSURLHTTPRequester *)requester).cacheResponseData) {
            tempData = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:requester.URL cacheExpiration:self.configuration.cacheExpirationTimeInterval];
        }
    }
    else if ([requester isKindOfClass:[ACSFileDownloader class]]) {
        tempData = [[ACSCache sharedCache] fetchAbsolutePathforURL:requester.URL];
    }
    
    tempData = [self dataSerializer:tempData responseType:requester.responseType];
    
    if (tempData) {
        
        if ([requester respondsToSelector:@selector(progressBlock)]) {
             ((ACSFileDownloader *)requester).progressBlock(ACSRequestProgressZero, tempData, nil);
        }
        else if ([requester respondsToSelector:@selector(completionBlock)]) {
            ((ACSURLHTTPRequester *)requester).completionBlock(tempData, nil);
        }
        
        if (requester.delegate) {
            if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                [requester.delegate request:requester didReceiveData:tempData];
            }
        }
    }
    return tempData;
}

- (void)failureCallback:(ACSHTTPRequest *)requester error:(NSError *)error {
    if ([requester isKindOfClass:[ACSURLHTTPRequester class]]) {
        id resultObject = nil;
        if (((ACSURLHTTPRequester *)requester).cacheResponseData &&
            ((ACSURLHTTPRequester *)requester).method == ACSRequestMethodGET) {
            resultObject = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:requester.URL
                                                                cacheExpiration:self.configuration.cacheExpirationTimeInterval];
            
            resultObject = [self dataSerializer:resultObject responseType:requester.responseType];
        }
        if (((ACSURLHTTPRequester *)requester).completionBlock) {
            ((ACSURLHTTPRequester *)requester).completionBlock(resultObject, resultObject ? nil : error);
        }
        
        if (requester.delegate) {
            
            if (resultObject) {
                if ([requester.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                    [requester.delegate request:requester didReceiveData:resultObject];
                }
            }
            else {
                
                if ([requester.delegate respondsToSelector:@selector(request:didFailToRequestForDataWithError:)]) {
                    [requester.delegate request:requester didFailToRequestForDataWithError:error];
                }
            }
        }
    }
    else if ([requester isKindOfClass:[ACSFileRequest class]]) {
        if (((ACSFileRequest *)requester).progressBlock) {
            ((ACSFileRequest *)requester).progressBlock(ACSRequestProgressZero, nil, error);
        }
        if (requester.delegate) {
            if ([requester.delegate respondsToSelector:@selector(request:didFailToRequestForDataWithError:)]) {
                [requester.delegate request:requester didFailToRequestForDataWithError:error];
            }
        }
    }
}

- (id)dataSerializer:(id) data responseType:(ACSResponseType) responseType {
    id serualizerResult = data;
    switch (responseType) {
        case ACSResponseTypeJSON: {
            serualizerResult = [NSJSONSerialization JSONObjectWithData:data
                                                               options:NSJSONReadingAllowFragments
                                                                 error:NULL];
            break;
        }
        case ACSResponseTypePropertyList: {
            serualizerResult = [NSPropertyListSerialization propertyListWithData:data
                                                                         options:NSPropertyListMutableContainers
                                                                          format:NULL
                                                                           error:NULL];
            break;
        }
        case ACSResponseTypeImage: {
            if ([data isKindOfClass:[NSString class]]) {
                data = ACSFileDataFromPath(data, self.configuration.downloadExpirationTimeInterval);
            }
            
#if TARGET_OS_IPHONE
            serualizerResult = [UIImage imageWithData:data];
#else
            serualizerResult = [[NSImage alloc] initWithData:data];
#endif
            break;
        }
        case ACSResponseTypeFilePath: {
            if ([data isKindOfClass:[NSData class]]) {
                serualizerResult = nil;
            }
        }
        case ACSResponseTypeData: {
            if ([data isKindOfClass:[NSString class]]) {
               serualizerResult = ACSFileDataFromPath(data, self.configuration.downloadExpirationTimeInterval);
            }
            break;
        }
        default:
            break;
    }

    return serualizerResult;
}

#endif

@end
