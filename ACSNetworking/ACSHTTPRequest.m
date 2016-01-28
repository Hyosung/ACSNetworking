// ACSHTTPRequest.m
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

#import "ACSHTTPRequest.h"

@implementation ACSHTTPRequest

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, \ntag: %@,\nURL: %@, \nmark: %@, \npath: %@, \nmethod: %@,\nparameters: %@>", NSStringFromClass([self class]), self, @(self.tag), self.URL, self.mark, self.path, ACSHTTPMethod(self.method), self.parameters];
}

#ifdef _AFNETWORKING_

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

- (AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer {
    switch (self.requestType) {
        case ACSRequestTypeJSON:
            return [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        case ACSRequestTypePropertyList:
            return [AFPropertyListRequestSerializer serializerWithFormat:NSPropertyListXMLFormat_v1_0 writeOptions:kNilOptions];
        case ACSRequestTypeDefault:
        default:
            return [AFHTTPRequestSerializer serializer];
    }
}

#endif

@end
