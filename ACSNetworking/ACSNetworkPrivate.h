// ACSNetworkPrivate.h
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

#if __has_include(<AFNetworking.h>)
#import <AFNetworking.h>
#elif __has_include("AFNetworking.h")
#import "AFNetworking.h"
#else
#error "请导入AFNetworking"
#endif

#ifndef __ACSNETWORK_PRIVATE__
#define __ACSNETWORK_PRIVATE__

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define ACSNETWORK_EXTERN        extern "C" __attribute__((visibility ("default")))
#else
#define ACSNETWORK_EXTERN        extern __attribute__((visibility ("default")))
#endif

#define ACSNETWORK_STATIC_INLINE	 static inline

#ifdef NS_ASSUME_NONNULL_BEGIN
#define __ACSNonnull _Nonnull
#else
#define __ACSNonnull
#endif

#define ACSSynthesizeSnippet(propertyName) @synthesize propertyName = _##propertyName

typedef NS_ENUM(NSUInteger, ACSResponseType) {
    //未经过处理的数据
//    ACSResponseTypeRaw = 0   ,
    //上传文件与普通的GET/POST请求
    ACSResponseTypeData = 0  ,
    ACSResponseTypeJSON      ,
    //下载文件
    ACSResponseTypeImage     ,
    ACSResponseTypeFilePath
};

typedef NS_ENUM(NSUInteger, ACSRequestMethod) {
    ACSRequestMethodGET = 0  ,
    ACSRequestMethodPOST     ,
    ACSRequestMethodHEAD     ,
    ACSRequestMethodPUT      ,
    ACSRequestMethodPATCH    ,
    ACSRequestMethodDELETE
};

ACSNETWORK_STATIC_INLINE NSString * ACSHTTPMethod(ACSRequestMethod method) {
    static dispatch_once_t onceToken;
    static NSDictionary *methods = nil;
    dispatch_once(&onceToken, ^{
        methods = @{
                    @(ACSRequestMethodGET)   : @"GET",
                    @(ACSRequestMethodPUT)   : @"PUT",
                    @(ACSRequestMethodHEAD)  : @"HEAD",
                    @(ACSRequestMethodPOST)  : @"POST",
                    @(ACSRequestMethodPATCH) : @"PATCH",
                    @(ACSRequestMethodDELETE): @"DELETE"
                    };
    });
    return methods[@(method)];
}

typedef struct ACSRequestProgress {
    NSUInteger bytes;
    CGFloat progressValue;
    long long totalBytes, totalBytesExpected;
} ACSRequestProgress;

ACSNETWORK_STATIC_INLINE ACSRequestProgress ACSRequestProgressMake(NSUInteger bytes, CGFloat progressValue, long long totalBytes, long long totalBytesExpected) {
    ACSRequestProgress progress = {bytes, progressValue, totalBytes, totalBytesExpected};
    return progress;
}

ACSNETWORK_STATIC_INLINE bool ACSRequestProgressIsEmpty(ACSRequestProgress progress) {
    return progress.bytes <= 0 && progress.totalBytes <= 0 && progress.totalBytesExpected <= 0;
}

#define ACSRequestProgressZero (ACSRequestProgress){0, 0.0, 0, 0}

typedef void(^ACSRequestCompletionHandler)(id result, NSError *error);
typedef void(^ACSRequestProgressHandler)(ACSRequestProgress progress, id result, NSError *error);

#endif
