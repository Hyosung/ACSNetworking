// ACSURLHTTPRequester.h
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

@interface ACSURLHTTPRequester : ACSHTTPRequest

/**
 是否缓存响应的数据
 */
@property BOOL cacheResponseData;
@property (nonatomic, copy) ACSRequestCompletionHandler completionBlock;

@end

/**
 callback只能为id <ACSURLRequesterDelegate>/ACSRequestProgressHandler/NULL
 */

extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSString *path, ACSRequestMethod method, NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSString *path, NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSString *path, NSDictionary *parameters, id callback);

extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(NSURL *URL, ACSRequestMethod method, NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSURL *URL, NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSURL *URL, NSDictionary *parameters, id callback);

extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateRequester(ACSRequestMethod method, NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreateGETRequester(NSDictionary *parameters, id callback);
extern __attribute__((overloadable)) ACSURLHTTPRequester * ACSCreatePOSTRequester(NSDictionary *parameters, id callback);
