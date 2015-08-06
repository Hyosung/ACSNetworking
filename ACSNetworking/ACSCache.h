// ACSCache.h
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

#import <Foundation/Foundation.h>

@interface ACSCache : NSObject

+ (instancetype)sharedCache;

/**
 本地缓存文件夹
 */
@property (nonatomic, copy, readonly) NSString *diskCachePath;

/**
 从内存中取缓存对象
 */
- (id)objectFromMemoryCacheForURL:(NSURL *) URL;

/**
 从本地磁盘中取缓存对象，首先是取内存中的缓存，在没有的情况下，才从磁盘中取
 */
- (id)objectFromDiskCacheForURL:(NSURL *) URL;
- (void)setObject:(id) obj forURL:(NSURL *) URL;
- (void)setObject:(id) obj forURL:(NSURL *) URL toDisk:(BOOL) toDisk;
- (void)removeObjectForURL:(NSURL *) URL;

/**
 清理内存与本地磁盘中的缓存
 */
- (void)cleanDiskMemory;

/**
 取内存中的缓存数据
 */
- (id)fetchDataFromMemoryCacheForURL:(NSURL *) URL;

/**
 取本地磁盘中的缓存对象
 */
- (id)fetchDataFromDiskCacheForURL:(NSURL *) URL;

/**
 存缓存数据
 */
- (void)storeCacheData:(id) data forURL:(NSURL *) URL;
- (void)storeCacheData:(id) data forURL:(NSURL *) URL toDisk:(BOOL) toDisk;

/**
 存相对路径
 
 @param absolutePath 文件的绝对路径
 @param URL          请求的URL
 */
- (void)storeAbsolutePath:(NSString *) absolutePath forURL:(NSURL *) URL;

/**
 取绝对路径
 
 @param URL 请求的URL
 
 @return 文件的绝对路径
 */
- (NSString *)fetchAbsolutePathforURL:(NSURL *) URL;

@end
