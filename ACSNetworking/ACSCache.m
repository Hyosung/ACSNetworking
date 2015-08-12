// ACSCache.m
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

#import "ACSCache.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif
#import "ACSNetworkPrivate.h"
#import "ACSNetworkConfiguration.h"
#import <CommonCrypto/CommonDigest.h>

@interface ACSCachedObject : NSObject <NSCoding>

/**
 缓存数据的更新时间
 */
@property (nonatomic, readonly) NSDate *modificationDate;

/**
 缓存内存是否过期
 */
@property (nonatomic, readonly, getter=isExpiration) BOOL expiration;

/**
 缓存的内容
 */
@property (nonatomic, strong, readonly) id content;

- (instancetype)initWithContent:(id) content;
- (void)updateContent:(id) content;

@end

@implementation ACSCachedObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _content = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(content))];
        _modificationDate = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(modificationDate))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_content forKey:NSStringFromSelector(@selector(content))];
    [aCoder encodeObject:_modificationDate forKey:NSStringFromSelector(@selector(modificationDate))];
}

- (instancetype)initWithContent:(id) content {
    self = [super init];
    if (self) {
        _content = content;
        _modificationDate = [NSDate date];
    }
    return self;
}

- (void)updateContent:(id) content {
    _content = content;
    _modificationDate = [NSDate date];
}

- (BOOL)isExpiration {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.modificationDate];
    return (timeInterval > [ACSNetworkConfiguration defaultConfiguration].cacheExpirationTimeInterval);
}

@end

@interface AutoCleanCache : NSCache
@end

@implementation AutoCleanCache

- (void)dealloc {
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
#endif
}

- (instancetype)init {
    self = [super init];
    if (self) {
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeAllObjects)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
#endif
    }
    return self;
}

@end


@interface ACSCache ()

@property (nonatomic, strong) AutoCleanCache *memoryCache;
@property (nonatomic, copy, readwrite) NSString *diskCachePath;
@property (nonatomic, copy) NSString *applicationPath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)setObject:(id)obj forURL:(NSURL *)URL toDisk:(BOOL)toDisk fileAttributes:(NSDictionary *) attributes;

@end

@implementation ACSCache

ACSNETWORK_STATIC_INLINE NSString * ACSCacheKeyForURL(NSURL *URL) {
    const char *str = [URL.absoluteString UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSMutableString *md5Ciphertext = [NSMutableString stringWithString:@""];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5Ciphertext appendFormat:@"%02x",r[i]];
    }
    return [md5Ciphertext copy];
}

ACSNETWORK_STATIC_INLINE NSString * ACSDiskCacheFilePath(NSString *pathComponent, NSString *diskFolder) {
    assert(pathComponent);
    assert(diskFolder);
    
    NSFileManager *fileManager = [NSFileManager new];
    if (![fileManager fileExistsAtPath:diskFolder]) {
        [fileManager createDirectoryAtPath:diskFolder
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
    }
    return [diskFolder stringByAppendingPathComponent:pathComponent];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.memoryCache = [[AutoCleanCache alloc] init];
        self.memoryCache.name = @"com.acsnetworking.cache";
        self.diskCachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.acsnetworking.cachedefault"];
        self.applicationPath = NSHomeDirectory();
        self.fileManager = [NSFileManager new];
    }
    return self;
}

+ (instancetype)sharedCache {
    static dispatch_once_t onceToken;
    static ACSCache *networkCache = nil;
    dispatch_once(&onceToken, ^{
        networkCache = [[self alloc] init];
    });
    return networkCache;
}

- (id)objectFromMemoryCacheForURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    
    return [self.memoryCache objectForKey:ACSCacheKeyForURL(URL)];
}

- (id)objectFromDiskCacheForURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    
    // First check the in-memory cache...
    id objcect = [self objectFromMemoryCacheForURL:URL];
    if (objcect) {
        return objcect;
    }
    
    // Second check the disk cache...
    id diskObject = [NSKeyedUnarchiver unarchiveObjectWithFile:ACSDiskCacheFilePath(ACSCacheKeyForURL(URL), self.diskCachePath)];
    if (diskObject) {
        [self setObject:diskObject forURL:URL toDisk:NO];
    }
    
    return diskObject;
}

- (void)setObject:(id)obj forURL:(NSURL *)URL {
    [self setObject:obj forURL:URL toDisk:YES];
}

- (void)setObject:(id)obj forURL:(NSURL *)URL toDisk:(BOOL)toDisk {
    [self setObject:obj forURL:URL toDisk:toDisk fileAttributes:nil];
}

- (void)setObject:(id)obj forURL:(NSURL *)URL toDisk:(BOOL)toDisk fileAttributes:(NSDictionary *)attributes {
    if (!obj || !URL) {
        return;
    }
    
    NSString *cacheKey = ACSCacheKeyForURL(URL);
    [self.memoryCache setObject:obj forKey:cacheKey];
    
    if (toDisk) {
        NSString *filePath = ACSDiskCacheFilePath(cacheKey, self.diskCachePath);
        [NSKeyedArchiver archiveRootObject:obj toFile:filePath];
        if (attributes.count) {
            /**
             设置文件属性
             */
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSError *error = nil;
            [fileURL setResourceValues:attributes error:&error];
        }
    }
}

- (void)removeObjectForURL:(NSURL *)URL {
    if (!URL) {
        return;
    }
    
    NSString *cacheKey = ACSCacheKeyForURL(URL);
    [self.memoryCache removeObjectForKey:cacheKey];
    [self.fileManager removeItemAtPath:ACSDiskCacheFilePath(cacheKey, self.diskCachePath) error:nil];
}

- (void)cleanDiskMemory {
    [self.memoryCache removeAllObjects];
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
}

- (id)fetchDataFromMemoryCacheForURL:(NSURL *)URL {
    ACSCachedObject *cacheObject = [self.memoryCache objectForKey:ACSCacheKeyForURL(URL)];
    if (cacheObject.isExpiration) {
        return nil;
    }
    
    return cacheObject.content;
}

- (id)fetchDataFromDiskCacheForURL:(NSURL *)URL {
    id object = [self fetchDataFromMemoryCacheForURL:URL];
    if (object) {
        return object;
    }
    
    ACSCachedObject *cacheObject = [NSKeyedUnarchiver unarchiveObjectWithFile:ACSDiskCacheFilePath(ACSCacheKeyForURL(URL), self.diskCachePath)];
    if (cacheObject.isExpiration) {
        return nil;
    }
    return cacheObject.content;
}

- (void)storeCacheData:(id)data forURL:(NSURL *)URL {
    [self storeCacheData:data forURL:URL toDisk:YES];
}

- (void)storeCacheData:(id)data forURL:(NSURL *)URL toDisk:(BOOL)toDisk {
    ACSCachedObject *cacheObject = [self objectFromDiskCacheForURL:URL];
    if (!cacheObject) {
        cacheObject = [[ACSCachedObject alloc] init];
    }
    [cacheObject updateContent:data];
    [self setObject:cacheObject forURL:URL];
}

- (void)storeAbsolutePath:(NSString *)absolutePath forURL:(NSURL *)URL {
    if (!absolutePath || !URL) {
        return;
    }
    
    absolutePath = [absolutePath stringByReplacingOccurrencesOfString:self.applicationPath
                                                           withString:@""
                                                              options:NSAnchoredSearch
                                                                range:NSMakeRange(0, absolutePath.length)];
    [self setObject:absolutePath
             forURL:URL
             toDisk:YES
     fileAttributes:@{NSURLIsHiddenKey: @1}];
}

- (NSString *)fetchAbsolutePathforURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    NSString *relativePath = [self objectFromDiskCacheForURL:URL];
    if (!relativePath) {
        return nil;
    }
    
    return [self.applicationPath stringByAppendingPathComponent:relativePath];
}

@end
