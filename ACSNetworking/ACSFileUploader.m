// ACSFileUploader.m
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

#import "ACSFileUploader.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <CommonCrypto/CommonDigest.h>
#import "NSData+ACSMimeType.h"

@implementation ACSFileUploader

ACSSynthesizeSnippet(URL);
ACSSynthesizeSnippet(tag);
ACSSynthesizeSnippet(mark);
ACSSynthesizeSnippet(path);
ACSSynthesizeSnippet(method);
ACSSynthesizeSnippet(delegate);
ACSSynthesizeSnippet(parameters);
ACSSynthesizeSnippet(responseType);
ACSSynthesizeSnippet(progressBlock);

ACSNETWORK_STATIC_INLINE NSString * acs_md5(NSString *text) {
    const char *str = [text UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSMutableString *md5Ciphertext = [NSMutableString stringWithString:@""];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5Ciphertext appendFormat:@"%02x",r[i]];
    }
    return [md5Ciphertext copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, \ntag: %@,\nURL: %@, \nmark: %@, \npath: %@, \nmethod: %@,\nfileInfo: %@,\nparameters: %@>", NSStringFromClass([self class]), self, @(self.tag), self.URL, self.mark, self.path, ACSHTTPMethod(self.method), self.fileInfo, self.parameters];
}

#ifdef _AFNETWORKING_

@synthesize operation = _operation;
@synthesize operationManager = _operationManager;

- (void)URLOperationFormManager:(AFHTTPRequestOperationManager *)operationManager
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    _operationManager = operationManager;
    self.URL = self.URL ?: [NSURL URLWithString:self.path ?: @""
                                  relativeToURL:operationManager.baseURL];
    __weak __typeof__(self) weakSelf = self;
    NSURLRequest *URLRequest = [[operationManager.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                                         URLString:self.URL.absoluteString
                                                                                        parameters:self.parameters
                                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                             __strong __typeof__(weakSelf) self = weakSelf;
                                                                             NSArray *allKeys = self.fileInfo.allKeys;
                                                                             for (NSString *keyName in allKeys) {
                                                                                 id fileValue = self.fileInfo[keyName];
                                                                                 if ([fileValue isKindOfClass:[NSString class]]) {
                                                                                     
                                                                                     [formData appendPartWithFileURL:[NSURL fileURLWithPath:fileValue]
                                                                                                                name:keyName
                                                                                                               error:nil];
                                                                                 }
                                                                                 else if ([fileValue isKindOfClass:[NSData class]]) {
                                                                                     NSDictionary *mimeTypeData = [fileValue mimeTypeData];
                                                                                     NSString *mimeType = mimeTypeData[ACSDataMimeTypeKey];
                                                                                     NSString *extension = mimeTypeData[ACSDataExtensionKey];
                                                                                     NSString *fileName = [acs_md5([NSString stringWithFormat:@"%@", @(arc4random())]) stringByAppendingPathExtension:extension];
                                                                                     [formData appendPartWithFileData:fileValue name:keyName fileName:fileName mimeType:mimeType];
                                                                                 }
                                                                                 #if __IPHONE_OS_VERSION_MIN_REQUIRED
                                                                                 else if ([fileValue isKindOfClass:[UIImage class]]) {
                                                                                     [formData appendPartWithFormData:UIImageJPEGRepresentation(fileValue, self.compressionQuality) name:keyName];
                                                                                 }
                                                                                 #else
                                                                                 else if ([fileValue isKindOfClass:[NSImage class]]) {
                                                                                     [formData appendPartWithFormData:[fileValue TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:self.compressionQuality] name:keyName];
                                                                                 }
                                                                                 #endif
                                                                                 else if ([fileValue isKindOfClass:[NSURL class]]) {
                                                                                     [formData appendPartWithFileURL:fileValue name:keyName error:nil];
                                                                                 }
                                                                             }
                                                                         } error:nil] copy];
    
    AFHTTPRequestOperation *operation = [operationManager HTTPRequestOperationWithRequest:URLRequest
                                                                                  success:success
                                                                                  failure:failure];
    
    __weak __typeof(self) wrequester = self;
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
        __strong __typeof(wrequester) srequester = wrequester;
        if (srequester) {
            
            if (srequester.progressBlock) {
                srequester.progressBlock(ACSRequestProgressMake(bytesWritten,
                                                                (CGFloat)totalBytesWritten / totalBytesExpectedToWrite,
                                                                totalBytesWritten,
                                                                totalBytesExpectedToWrite), nil, nil);
            }
            
            if (srequester.delegate) {
                if ([srequester.delegate respondsToSelector:@selector(request:didFileProgressing:)]) {
                    [srequester.delegate request:srequester didFileProgressing:ACSRequestProgressMake(bytesWritten,
                                                                                                      (CGFloat)totalBytesWritten / totalBytesExpectedToWrite,
                                                                                                      totalBytesWritten,
                                                                                                      totalBytesExpectedToWrite)];
                }
            }
        }
    }];
    
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

- (ACSRequestMethod)method {
    if (_method == ACSRequestMethodGET || _method == ACSRequestMethodHEAD) {
        _method = ACSRequestMethodPOST;
    }
    return _method;
}

- (CGFloat)compressionQuality {
    if (_compressionQuality <= 0) {
        return 0.5;
    }
    return _compressionQuality;
}

@end

ACSNETWORK_STATIC_INLINE void ACSSetupCallback(ACSFileUploader **uploader, id *callback) {
    if (*callback) {
        if ([(*callback) conformsToProtocol:@protocol(ACSURLRequesterDelegate)]) {
            (*uploader).delegate = *callback;
        }
        else {
            if (strstr(object_getClassName(*callback), "Block") != NULL) {
                (*uploader).progressBlock = *callback;
            }
        }
    }
}

__attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSString *path, NSDictionary *fileInfo, id callback) {
    ACSFileUploader *uploader = [[ACSFileUploader alloc] init];
    uploader.path = path;
    uploader.fileInfo = fileInfo;
    ACSSetupCallback(&uploader, &callback);
    return uploader;
}

__attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSURL *URL, NSDictionary *fileInfo, id callback) {
    ACSFileUploader *uploader = [[ACSFileUploader alloc] init];
    uploader.URL = URL;
    uploader.fileInfo = fileInfo;
    ACSSetupCallback(&uploader, &callback);
    return uploader;
}

__attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSDictionary *fileInfo, id callback) {
    ACSFileUploader *uploader = [[ACSFileUploader alloc] init];
    uploader.fileInfo = fileInfo;
    ACSSetupCallback(&uploader, &callback);
    return uploader;
}
