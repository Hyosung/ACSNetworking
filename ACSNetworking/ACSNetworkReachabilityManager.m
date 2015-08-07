// ACSNetworkReachabilityManager.m
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

#import "ACSNetworkReachabilityManager.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const ACSNetworkingReachabilityDidChangeNotification = @"com.stoney.networking.reachability.change";
NSString * const ACSNetworkingReachabilityNotificationStatusItem = @"ACSNetworkingReachabilityNotificationStatusItem";

typedef void (^ACSNetworkReachabilityStatusBlock)(ACSNetworkReachabilityStatus status);

typedef NS_ENUM(NSUInteger, ACSNetworkReachabilityAssociation) {
    ACSNetworkReachabilityForAddress = 1,
    ACSNetworkReachabilityForAddressPair = 2,
    ACSNetworkReachabilityForName = 3,
};

NSString * ACSStringFromNetworkReachabilityStatus(ACSNetworkReachabilityStatus status) {
    switch (status) {
        case ACSNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"ACSNetworking", nil);
#if	TARGET_OS_IPHONE
        case ACSNetworkReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"ACSNetworking", nil);
#endif
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000)
        case ACSNetworkReachabilityStatusReachableVia2G:
            return NSLocalizedStringFromTable(@"Reachable via 2G", @"ACSNetworking", nil);
        case ACSNetworkReachabilityStatusReachableVia3G:
            return NSLocalizedStringFromTable(@"Reachable via 3G", @"ACSNetworking", nil);
        case ACSNetworkReachabilityStatusReachableVia4G:
            return NSLocalizedStringFromTable(@"Reachable via 4G", @"ACSNetworking", nil);
#endif
        case ACSNetworkReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"ACSNetworking", nil);
        case ACSNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"ACSNetworking", nil);
    }
}

static ACSNetworkReachabilityStatus ACSNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    ACSNetworkReachabilityStatus status = ACSNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = ACSNetworkReachabilityStatusNotReachable;
    }
#if	defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        status = ACSNetworkReachabilityStatusReachableViaWWAN;
        //来源 http://www.cocoachina.com/bbs/read.php?tid=228822
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            NSString *currentRadioAccessTechnology = info.currentRadioAccessTechnology;
            if (currentRadioAccessTechnology) {
                if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                    status = ACSNetworkReachabilityStatusReachableVia4G;
                }
                else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                    status = ACSNetworkReachabilityStatusReachableVia2G;
                }
                else {
                    status = ACSNetworkReachabilityStatusReachableVia3G;
                }
            }
        }
        else {
            if ((flags & kSCNetworkReachabilityFlagsTransientConnection) == kSCNetworkReachabilityFlagsTransientConnection) {
                if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired) {
                    status = ACSNetworkReachabilityStatusReachableVia2G;
                }
                else {
                    status = ACSNetworkReachabilityStatusReachableVia3G;
                }
            }
        }
#else
        status = ACSNetworkReachabilityStatusReachableViaWWAN;
#endif
    }
#endif
    else {
        status = ACSNetworkReachabilityStatusReachableViaWiFi;
    }
    
    return status;
}

static void ACSNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    ACSNetworkReachabilityStatus status = ACSNetworkReachabilityStatusForFlags(flags);
    ACSNetworkReachabilityStatusBlock block = (__bridge ACSNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{ ACSNetworkingReachabilityNotificationStatusItem: @(status) };
        [notificationCenter postNotificationName:ACSNetworkingReachabilityDidChangeNotification object:nil userInfo:userInfo];
    });
    
}

static const void * ACSNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void ACSNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface ACSNetworkReachabilityManager ()
@property (readwrite, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) ACSNetworkReachabilityAssociation networkReachabilityAssociation;
@property (readwrite, nonatomic, assign) ACSNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) ACSNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation ACSNetworkReachabilityManager


+ (instancetype)sharedManager {
    static ACSNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;
        
        _sharedManager = [self managerForAddress:&address];
    });
    
    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);
    
    ACSNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = ACSNetworkReachabilityForName;
    
    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    
    ACSNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = ACSNetworkReachabilityForAddress;
    
    return manager;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.networkReachability = reachability;
    self.networkReachabilityStatus = ACSNetworkReachabilityStatusUnknown;
    
    return self;
}

- (void)dealloc {
    [self stopMonitoring];
    
    if (_networkReachability) {
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

#pragma mark -

- (BOOL)isReachable {
#if	TARGET_OS_IPHONE
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
#else
    return [self isReachableViaWiFi];
#endif
    
}

#if	defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (BOOL)isReachableViaWWAN {
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    return [self isReachableVia2G] || [self isReachableVia3G] || [self isReachableVia4G] || self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableViaWWAN;
#else
    return self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableViaWWAN;
#endif
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000

- (BOOL)isReachableVia2G {
    return self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableVia2G;
}

- (BOOL)isReachableVia3G {
    return self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableVia3G;
}

- (BOOL)isReachableVia4G {
    return self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableVia4G;
}
#endif

#endif

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == ACSNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];
    
    if (!self.networkReachability) {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    ACSNetworkReachabilityStatusBlock callback = ^(ACSNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        
    };
    
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, ACSNetworkReachabilityRetainCallback, ACSNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, ACSNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    switch (self.networkReachabilityAssociation) {
        case ACSNetworkReachabilityForName:
            break;
        case ACSNetworkReachabilityForAddress:
        case ACSNetworkReachabilityForAddressPair:
        default: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                SCNetworkReachabilityFlags flags;
                SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
                ACSNetworkReachabilityStatus status = ACSNetworkReachabilityStatusForFlags(flags);
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(status);
                    
                    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                    [notificationCenter postNotificationName:ACSNetworkingReachabilityDidChangeNotification object:nil userInfo:@{ ACSNetworkingReachabilityNotificationStatusItem: @(status) }];
                    
                    
                });
            });
        }
            break;
    }
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return ACSStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(ACSNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] ||
        [key isEqualToString:@"reachableViaWWAN"] ||
        [key isEqualToString:@"reachableVia2G"] ||
        [key isEqualToString:@"reachableVia3G"] ||
        [key isEqualToString:@"reachableVia4G"] ||
        [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end

