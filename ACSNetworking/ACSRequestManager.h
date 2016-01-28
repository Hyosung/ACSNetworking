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

#import "ACSNetworkGeneral.h"

@class ACSFileUploader;
@class ACSFileDownloader;
@class ACSURLHTTPRequester;
@class ACSNetworkConfiguration;

typedef NS_ENUM(NSUInteger, ACSNetworkingErrorCode) {
    ACSNetworkingErrorCodeEmptyData = 0 ,
    ACSNetworkingErrorCodeNoNetwork
};

ACSNETWORK_EXTERN NSString *const ACSNetworkingErrorDomain;
ACSNETWORK_EXTERN NSString *const ACSNetworkingErrorDescriptionKey;

@interface ACSRequestManager : NSObject

#ifdef _AFNETWORKING_

/**
 单例
 */
+ (instancetype)sharedManager;

+ (instancetype)manager;
- (instancetype)initWithConfiguration:(ACSNetworkConfiguration *) configuration;

- (void)cancelAllOperations;

/**
 请求数据
 
 @param requester 封装的请求对象
 */
- (void)fetchDataFromRequester:(ACSURLHTTPRequester *) requester;

/**
 上传文件
 
 @param requester 封装的上传文件的请求对象
 */
- (void)uploadFileFromRequester:(ACSFileUploader *) requester;

/**
 下载文件
 
 @param requester 封装的下载文件的请求对象
 */
- (void)downloadFileFromRequester:(ACSFileDownloader *) requester;

#endif

@end
