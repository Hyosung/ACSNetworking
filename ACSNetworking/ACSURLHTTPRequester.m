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

#import "ACSCache.h"

@implementation ACSURLHTTPRequester

ACSSynthesizeSnippet(URL);
ACSSynthesizeSnippet(tag);
ACSSynthesizeSnippet(mark);
ACSSynthesizeSnippet(path);
ACSSynthesizeSnippet(method);
ACSSynthesizeSnippet(delegate);
ACSSynthesizeSnippet(operation);
ACSSynthesizeSnippet(responseType);

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, \ntag: %@,\nURL: %@, \nmark: %@, \npath: %@, \nmethod: %@,\nparameters: %@, \ncacheResponseData: %@>", NSStringFromClass([self class]), self, @(self.tag), self.URL, self.mark, self.path, ACSHTTPMethod(self.method), self.parameters, self.cacheResponseData ? @"YES" : @"NO"];
}

#ifdef _AFNETWORKING_

ACSSynthesizeSnippet(parameters);
ACSSynthesizeSnippet(operationManager);

- (void)URLOperationFormManager:(AFHTTPRequestOperationManager *)operationManager
                cacheExpiration:(NSTimeInterval)timeInterval
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    _operationManager = operationManager;
    self.URL = self.URL ?: [NSURL URLWithString:self.path ?: @"" relativeToURL:operationManager.baseURL];
    NSURLRequest *URLRequest = [[operationManager.requestSerializer requestWithMethod:ACSHTTPMethod(self.method)
                                                                            URLString:self.URL.absoluteString
                                                                           parameters:self.parameters
                                                                                error:nil] copy];
    //取本地缓存
    id resultObject = [[ACSCache sharedCache] fetchDataFromDiskCacheForURL:URLRequest.URL cacheExpiration:timeInterval];
    if (resultObject && self.method == ACSRequestMethodGET && self.cacheResponseData) {
        id tempResult = resultObject;
        if ([resultObject isKindOfClass:[NSData class]]) {
            if (self.responseType == ACSResponseTypeJSON) {
                tempResult = [NSJSONSerialization JSONObjectWithData:resultObject options:NSJSONReadingAllowFragments error:nil];
            }
        }
        else if ([resultObject isKindOfClass:[NSDictionary class]] ||
                 [resultObject isKindOfClass:[NSArray class]]) {
            tempResult = [NSJSONSerialization dataWithJSONObject:resultObject options:NSJSONWritingPrettyPrinted error:nil];
        }
        
        if (self.completionBlock) {
            self.completionBlock(tempResult, nil);
        }
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(request:didReceiveData:)]) {
                [self.delegate request:self didReceiveData:tempResult];
            }
        }
        
        return;
    }
    
    AFHTTPRequestOperation *operation = [operationManager HTTPRequestOperationWithRequest:URLRequest
                                                                                  success:success
                                                                                  failure:failure];
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

@end

ACSNETWORK_STATIC_INLINE void ACSSetupCallback(ACSURLHTTPRequester **requester, id *callback) {
    if (*callback) {
        if ([(*callback) conformsToProtocol:@protocol(ACSURLRequesterDelegate)]) {
            (*requester).delegate = *callback;
        }
        else {
            if (strstr(object_getClassName(*callback), "Block") != NULL) {
                (*requester).completionBlock = *callback;
            }
        }
    }
}

#pragma mark - Path

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSString *path, ACSRequestMethod method, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = method;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSString *path, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = ACSRequestMethodGET;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSString *path, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.path = path;
    requester.method = ACSRequestMethodPOST;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

#pragma mark - URL

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSURL *URL, ACSRequestMethod method, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = method;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSURL *URL, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = ACSRequestMethodGET;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSURL *URL, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.URL = URL;
    requester.method = ACSRequestMethodPOST;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

#pragma mark - Default BaseURL

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(ACSRequestMethod method, NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.method = method;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.method = ACSRequestMethodGET;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}

__attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSDictionary *parameters, id callback) {
    ACSURLHTTPRequester *requester = [[ACSURLHTTPRequester alloc] init];
    requester.method = ACSRequestMethodPOST;
    requester.parameters = parameters;
    requester.responseType = ACSResponseTypeJSON;
    ACSSetupCallback(&requester, &callback);
    return requester;
}
