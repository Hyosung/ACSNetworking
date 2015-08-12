// ACSURLHTTPRequest.h
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

#import "ACSNetworkPrivate.h"

@protocol ACSURLHTTPRequest <NSObject>

/**
 响应的结果的类型 默认data
 */
@property ACSResponseType responseType;

/**
 请求的URL
 */
@property (copy) NSURL *URL;

/**
 请求的路径 相对路径
 */
@property (copy) NSString *path;

/**
 请求方式
 */
@property ACSRequestMethod method;

@property (nonatomic, copy) NSDictionary *parameters;

#ifdef _AFNETWORKING_
- (NSMutableURLRequest *)URLRequestFormOperationManager:(AFHTTPRequestOperationManager *) operationManager;
#endif
@end
