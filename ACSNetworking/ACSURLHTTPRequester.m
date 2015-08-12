// ACSURLHTTPRequester.m
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

#import "ACSURLHTTPRequester.h"

@implementation ACSURLHTTPRequester

@synthesize URL = _URL;
@synthesize path = _path;
@synthesize method = _method;
@synthesize delegate = _delegate;
@synthesize parameters = _parameters;
@synthesize responseType = _responseType;
@synthesize operationManager = _operationManager;

#ifdef _AFNETWORKING_
- (NSMutableURLRequest *)URLRequestFormOperationManager:(AFHTTPRequestOperationManager *)operationManager {
    _operationManager = operationManager;
    NSURL *__weak tempURL = self.URL ?: [NSURL URLWithString:self.path ?: @"" relativeToURL:operationManager.baseURL];
    self.URL = tempURL;
    return [operationManager.requestSerializer requestWithMethod:ACSHTTPMethod(self.method)
                                                       URLString:self.URL.absoluteString
                                                      parameters:self.parameters
                                                           error:nil];
}
#endif

@end

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSString *path, ACSRequestMethod method, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = method;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSURL *URL, ACSRequestMethod method, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = method;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSString *path, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = ACSRequestMethodPOST;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSURL *URL, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = ACSRequestMethodPOST;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSString *path, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = ACSRequestMethodGET;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSURL *URL, NSDictionary *parameters, ACSRequestCompletionHandler completionBlock) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = ACSRequestMethodGET;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    requester.completionBlock = completionBlock;
    return requester;
}
