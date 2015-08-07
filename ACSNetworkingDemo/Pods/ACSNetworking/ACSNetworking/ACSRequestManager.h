// ACSRequestManager.h
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

#import "ACSNetworkPrivate.h"

@class ACSFileUploader;
@class ACSFileDownloader;
@class ACSURLHTTPRequester;

@interface ACSRequestManager : NSObject

#ifdef _AFNETWORKING_
+ (instancetype)sharedManager;

- (void)cancelAllOperations;
- (void)cancelOperationWithIdentifier:(NSString *) identifier;
- (void)pauseOperationWithIdentifier:(NSString *) identifier;
- (void)resumeOperationWithIdentifier:(NSString *) identifier;
- (BOOL)isPausedOperationWithIdentifier:(NSString *) identifier;
- (BOOL)isExecutingOperationWithIdentifier:(NSString *) identifier;

/**
 请求数据
 
 @param requester 封装的请求对象
 
 @return operation identifier 当返回nil时，说明使用的是缓存
 */
- (NSString *)fetchDataFromRequester:(ACSURLHTTPRequester *) requester;

/**
 上传文件
 
 @param requester 封装的上传文件的请求对象
 
 @return operation identifier
 */
- (NSString *)uploadFileFromRequester:(ACSFileUploader *) requester;

/**
 下载文件
 
 @param requester 封装的下载文件的请求对象
 
 @return operation identifier 当返回nil时，说明使用的是缓存
 */
- (NSString *)downloadFileFromRequester:(ACSFileDownloader *) requester;

#pragma mark - 默认的baseURL

- (NSString *)fetchDataFromPath:(NSString *) path
                         method:(ACSRequestMethod) method
                     parameters:(NSDictionary *) parameters
                     completion:(ACSRequestCompletionHandler) completionBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用fetchDataFromRequester:");

- (NSString *)GET_fetchDataFromPath:(NSString *) path
                         parameters:(NSDictionary *) parameters
                         completion:(ACSRequestCompletionHandler) completionBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用fetchDataFromRequester:");

- (NSString *)POST_fetchDataFromPath:(NSString *) path
                          parameters:(NSDictionary *) parameters
                          completion:(ACSRequestCompletionHandler) completionBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用fetchDataFromRequester:");

- (NSString *)uploadFileFromPath:(NSString *) path
                        fileInfo:(NSDictionary *) fileInfo
                      parameters:(NSDictionary *) parameters
                        progress:(ACSRequestProgressHandler) progressBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用uploadFileFromRequester:");

- (NSString *)downloadFileFromPath:(NSString *) path
                          progress:(ACSRequestProgressHandler) progressBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用downloadFileFromRequester:");

#pragma mark - 自定义请求链接

- (NSString *)fetchDataFromURLString:(NSString *) URLString
                              method:(ACSRequestMethod) method
                          parameters:(NSDictionary *) parameters
                          completion:(ACSRequestCompletionHandler) completionBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用fetchDataFromRequester:");

- (NSString *)uploadFileFromURLString:(NSString *) URLString
                             fileInfo:(NSDictionary *) fileInfo
                           parameters:(NSDictionary *) parameters
                             progress:(ACSRequestProgressHandler) progressBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用uploadFileFromRequester:");

- (NSString *)downloadFileFromURLString:(NSString *) URLString
                               progress:(ACSRequestProgressHandler) progressBlock NS_DEPRECATED_IOS(2_0, 6_0, "请使用downloadFileFromRequester:");
#endif

@end
