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

@implementation ACSFileUploader

@synthesize URL = _URL;
@synthesize path = _path;
@synthesize method = _method;
@synthesize parameters = _parameters;
@synthesize responseType = _responseType;
@synthesize progressBlock = _progressBlock;

- (ACSRequestMethod)method {
    if (_method == ACSRequestMethodGET || _method == ACSRequestMethodHEAD) {
        _method = ACSRequestMethodPOST;
    }
    return _method;
}

#ifdef _AFNETWORKING_
- (NSMutableURLRequest *)URLRequestFormOperationManager:(AFHTTPRequestOperationManager *)operationManager {
    NSURL *__weak tempURL = self.URL ?: [NSURL URLWithString:self.path ?: @""
                                               relativeToURL:operationManager.baseURL];
    self.URL = tempURL;
    __weak __typeof__(self) weakSelf = self;
    return [operationManager.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                    URLString:self.URL.absoluteString
                                                                   parameters:self.parameters
                                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                        __strong __typeof__(weakSelf) self = weakSelf;
                                                        NSArray *allKeys = self.fileInfo.allKeys;
                                                        for (NSString *keyName in allKeys) {
                                                            id fileURL = self.fileInfo[keyName];
                                                            if ([fileURL isKindOfClass:[NSString class]]) {
                                                                fileURL = [NSURL URLWithString:fileURL];
                                                            }
                                                            [formData appendPartWithFileURL:fileURL
                                                                                       name:keyName
                                                                                      error:nil];
                                                        }
                                                    } error:nil];
}
#endif

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