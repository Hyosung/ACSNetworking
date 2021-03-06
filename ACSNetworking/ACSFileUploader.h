// ACSFileUploader.h
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

#import "ACSFileRequest.h"

@interface ACSFileUploader : ACSFileRequest

@property (nonatomic, copy) NSDictionary *fileInfo;

/**
 图片压缩质量 0-1 默认0.5
 */
@property (nonatomic) CGFloat compressionQuality;

@end

/**
 callback只能为id <ACSURLRequesterDelegate>/ACSRequestProgressHandler/NULL
 */

extern __attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSString *path, NSDictionary *fileInfo, id callback);
extern __attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSURL *URL, NSDictionary *fileInfo, id callback);
extern __attribute__((overloadable)) ACSFileUploader * ACSCreateUploader(NSDictionary *fileInfo, id callback);
