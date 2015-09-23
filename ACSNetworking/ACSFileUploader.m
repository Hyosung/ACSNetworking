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

@implementation ACSFileUploader

@synthesize URL = _URL;
@synthesize path = _path;
@synthesize method = _method;
@synthesize delegate = _delegate;
@synthesize parameters = _parameters;
@synthesize responseType = _responseType;
@synthesize progressBlock = _progressBlock;

#ifdef _AFNETWORKING_

@synthesize operation = _operation;
@synthesize operationManager = _operationManager;

- (void)URLOperationFormManager:(AFHTTPRequestOperationManager *)operationManager
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    _operationManager = operationManager;
    NSURL *__weak tempURL = self.URL ?: [NSURL URLWithString:self.path ?: @""
                                               relativeToURL:operationManager.baseURL];
    self.URL = tempURL;
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
                                                                                           
                                                                                           [formData appendPartWithFileURL:[NSURL URLWithString:fileValue]
                                                                                                                      name:keyName
                                                                                                                     error:nil];
                                                                                       }
                                                                                       else if ([fileValue isKindOfClass:[NSData class]]) {
                                                                                           [formData appendPartWithFormData:fileValue name:keyName];
                                                                                       }
#if __IPHONE_OS_VERSION_MIN_REQUIRED
                                                                                       else if ([fileValue isKindOfClass:[UIImage class]]) {
                                                                                           [formData appendPartWithFormData:UIImageJPEGRepresentation(fileValue, 1.0) name:keyName];
                                                                                       }
#else
                                                                                       else if ([fileValue isKindOfClass:[NSImage class]]) {
                                                                                           [formData appendPartWithFormData:[fileValue TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1.0] name:keyName];
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

@end
__attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSString *path, NSDictionary *fileInfo, ACSRequestProgressHandler progressBlock) {
    ACSFileUploader *uploader = [[ACSFileUploader alloc] init];
    uploader.path = path;
    uploader.fileInfo = fileInfo;
    uploader.progressBlock = progressBlock;
    return uploader;
}

__attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSURL *URL, NSDictionary *fileInfo, ACSRequestProgressHandler progressBlock) {
    ACSFileUploader *uploader = [[ACSFileUploader alloc] init];
    uploader.URL = URL;
    uploader.fileInfo = fileInfo;
    uploader.progressBlock = progressBlock;
    return uploader;
}
