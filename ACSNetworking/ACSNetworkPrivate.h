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
#import <CommonCrypto/CommonDigest.h>

#ifdef __cplusplus
#define ACSNETWORK_EXTERN        extern "C" __attribute__((visibility ("default")))
#else
#define ACSNETWORK_EXTERN        extern __attribute__((visibility ("default")))
#endif

#define ACSNETWORK_STATIC_INLINE	 static inline

#define ACSSynthesizeSnippet(propertyName) @synthesize propertyName = _##propertyName

typedef NS_ENUM(NSUInteger, ACSResponseType) {
    
    //上传文件与普通的GET/POST请求
    ACSResponseTypeData = 0  ,
    ACSResponseTypeJSON      ,
    ACSResponseTypePropertyList ,
    //下载文件
    ACSResponseTypeImage     ,
    ACSResponseTypeFilePath
};

typedef NS_ENUM(NSUInteger, ACSRequestType) {
    
    ACSRequestTypeDefault = 0  ,
    ACSRequestTypeJSON ,
    ACSRequestTypePropertyList
};

typedef NS_ENUM(NSUInteger, ACSRequestMethod) {
    ACSRequestMethodGET = 0  ,
    ACSRequestMethodPOST     ,
    ACSRequestMethodHEAD     ,
    ACSRequestMethodPUT      ,
    ACSRequestMethodPATCH    ,
    ACSRequestMethodDELETE
};

typedef struct ACSRequestProgress {
    NSUInteger bytes;
    CGFloat progressValue;
    long long totalBytes, totalBytesExpected;
} ACSRequestProgress;

#define ACSRequestProgressZero (ACSRequestProgress){0, 0.0, 0, 0}

typedef void(^ACSRequestCompletionHandler)(id result, NSError *error);
typedef void(^ACSRequestProgressHandler)(ACSRequestProgress progress, id result, NSError *error);

#pragma mark - Static inline

ACSNETWORK_STATIC_INLINE ACSRequestProgress ACSRequestProgressMake(NSUInteger bytes, CGFloat progressValue, long long totalBytes, long long totalBytesExpected) {
    ACSRequestProgress progress = {bytes, progressValue, totalBytes, totalBytesExpected};
    return progress;
}

ACSNETWORK_STATIC_INLINE bool ACSRequestProgressIsEmpty(ACSRequestProgress progress) {
    return progress.bytes <= 0 && progress.totalBytes <= 0 && progress.totalBytesExpected <= 0;
}

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

ACSNETWORK_STATIC_INLINE NSString * ACSMD5(NSString *plaintext) {
    const char *str = [plaintext UTF8String];
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
    
    NSString *pathExtension = (extension && ![extension isEqualToString:@""]) ? [NSString stringWithFormat:@".%@", [extension lowercaseString]] : @"";
    NSString *fileName = [NSString stringWithFormat:@"%@%@", ACSMD5(URL.absoluteString), pathExtension];
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    return filePath;
}

ACSNETWORK_STATIC_INLINE NSData * ACSFileDataFromPath(NSString *path, NSTimeInterval downloadExpirationTimeInterval) {
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

ACSNETWORK_STATIC_INLINE unsigned long long ACSFileSizeFromPath(NSString *path) {
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

#endif
