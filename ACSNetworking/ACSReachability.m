// ACSReachability.m
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

#import "ACSReachability.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIDevice.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#else
#endif

#import <sys/socket.h>
#import <netinet6/in6.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const ACSNetworkingReachabilityDidChangeNotification = @"com.stoney.networking.reachability.change";

@interface ACSReachability ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong, nullable) dispatch_queue_t reachabilitySerialQueue;
#else
@property (nonatomic, assign, nullable) dispatch_queue_t reachabilitySerialQueue;
#endif
@property (nonatomic, strong) id reachabilityObject;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;

@end

@implementation ACSReachability {
    SCNetworkReachabilityRef _reachabilityRef;
    BOOL _alwaysReturnLocalWiFiStatus;
}

NSString * ACSStringFromReachabilityStatus(ACSReachabilityStatus status) {
    switch (status) {
#if	TARGET_OS_IPHONE
        case ACSReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"ACSNetworking", nil);
#endif
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000)
        case ACSReachabilityStatusReachableVia2G:
            return NSLocalizedStringFromTable(@"Reachable via 2G", @"ACSNetworking", nil);
        case ACSReachabilityStatusReachableVia3G:
            return NSLocalizedStringFromTable(@"Reachable via 3G", @"ACSNetworking", nil);
        case ACSReachabilityStatusReachableVia4G:
            return NSLocalizedStringFromTable(@"Reachable via 4G", @"ACSNetworking", nil);
#endif
        case ACSReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"ACSNetworking", nil);
        case ACSReachabilityStatusNotReachable:
        default:
            return NSLocalizedStringFromTable(@"Not Reachable", @"ACSNetworking", nil);
    }
}

static void ACSReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    ACSReachability *reachability = (__bridge ACSReachability *)(info);
    
    // We probably don't need an autoreleasepool here, as GCD docs state each queue has its own autorelease pool,
    // but what the heck eh?
    @autoreleasepool {
        [reachability reachabilityChanged:flags];
    }
}

-(void)dealloc {
    [self stopNotifier];
    
    if(_reachabilityRef) {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
#if !OS_OBJECT_USE_OBJC
    dispatch_release(self.reachabilitySerialQueue);
#endif
    self.reachabilitySerialQueue = nil;
}

+ (instancetype)reachabilityWithHostName:(NSString*)hostname {
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    ACSReachability *returnValue = NULL;
    if (ref) {
        returnValue = [[self alloc] init];
        if (returnValue) {
            returnValue->_reachabilityRef = ref;
            returnValue->_alwaysReturnLocalWiFiStatus = NO;
        }
        else {
            CFRelease(ref);
        }
    }
    return returnValue;
}

+ (instancetype)reachabilityWithAddress:(const void*)hostAddress {
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);
    ACSReachability *returnValue = NULL;
    
    if (ref) {
        returnValue = [[self alloc] init];
        if (returnValue) {
            returnValue->_reachabilityRef = ref;
            returnValue->_alwaysReturnLocalWiFiStatus = NO;
        }
        else {
            CFRelease(ref);
        }
    }
    return returnValue;
}

+ (instancetype)reachabilityForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&zeroAddress];
}

+ (instancetype)reachabilityForLocalWiFi {
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len            = sizeof(localWifiAddress);
    localWifiAddress.sin_family         = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr    = htonl(IN_LINKLOCALNETNUM);
    
    ACSReachability *reachability = [self reachabilityWithAddress:&localWifiAddress];
    if (reachability) {
        reachability->_alwaysReturnLocalWiFiStatus = YES;
    }
    
    return reachability;
}

// Initialization methods
- (instancetype)init {
    self = [super init];
    if (self) {
        // We need to create a serial queue.
        // We allocate this once for the lifetime of the notifier.
        self.reachabilitySerialQueue = dispatch_queue_create("com.stoney.acsreachability", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Notifier Methods

// Notifier
// NOTE: This uses GCD to trigger the blocks - they *WILL NOT* be called on THE MAIN THREAD
// - In other words DO NOT DO ANY UI UPDATES IN THE BLOCKS.
//   INSTEAD USE dispatch_async(dispatch_get_main_queue(), ^{UISTUFF}) (or dispatch_sync if you want)

- (BOOL)startNotifier {
    // allow start notifier to be called multiple times
    if(self.reachabilityObject == self) {
        return YES;
    }
    
    SCNetworkReachabilityContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    
    if(SCNetworkReachabilitySetCallback(_reachabilityRef, ACSReachabilityCallback, &context)) {
        // Set it as our reachability queue, which will retain the queue
        if(SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, self.reachabilitySerialQueue)) {
            // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
            // woah
            self.reachabilityObject = self;
            return YES;
        }
        else {
#ifdef DEBUG
            NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif
            
            // UH OH - FAILURE - stop any callbacks!
            SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        }
    }
    else {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif
    }
    
    // if we get here we fail at the internet
    self.reachabilityObject = nil;
    return NO;
}

- (void)stopNotifier {
    // First stop, any callbacks!
    SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
    
    // Unregister target from the GCD serial dispatch queue.
    SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
    
    self.reachabilityObject = nil;
}


#pragma mark - reachability tests

- (ACSReachabilityStatus)localWiFiStatusForFlags:(SCNetworkReachabilityFlags)flags {
    ACSReachabilityStatus returnValue = ACSReachabilityStatusNotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect)) {
        returnValue = ACSReachabilityStatusReachableViaWiFi;
    }
    
    return returnValue;
}


- (ACSReachabilityStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // The target host is not reachable.
        return ACSReachabilityStatusNotReachable;
    }
    
    ACSReachabilityStatus returnValue = ACSReachabilityStatusNotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = ACSReachabilityStatusReachableViaWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = ACSReachabilityStatusReachableViaWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        returnValue = ACSReachabilityStatusReachableViaWWAN;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        //来源 http://www.cocoachina.com/bbs/read.php?tid=228822
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            NSString *currentRadioAccessTechnology = info.currentRadioAccessTechnology;
            if (currentRadioAccessTechnology) {
                if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                    returnValue = ACSReachabilityStatusReachableVia4G;
                }
                else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge] ||
                         [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS] ||
                         [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                    returnValue = ACSReachabilityStatusReachableVia2G;
                }
                else {
                    returnValue = ACSReachabilityStatusReachableVia3G;
                }
            }
        }
        else {
            if ((flags & kSCNetworkReachabilityFlagsTransientConnection) == kSCNetworkReachabilityFlagsTransientConnection) {
                if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired) {
                    returnValue = ACSReachabilityStatusReachableVia2G;
                }
                else {
                    returnValue = ACSReachabilityStatusReachableVia3G;
                }
            }
        }
#endif
    }
    
    return returnValue;
}

- (BOOL)isReachable {
    return (self.reachabilityStatus != ACSReachabilityStatusNotReachable);
}

- (BOOL)isReachableViaWWAN {
#if	TARGET_OS_IPHONE
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        // Check we're REACHABLE
        if(flags & kSCNetworkReachabilityFlagsReachable) {
            // Now, check we're on WWAN
            if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
        }
    }
#endif
    return NO;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000

- (BOOL)isReachableVia2G {
    return (self.reachabilityStatus == ACSReachabilityStatusReachableVia2G);
}

- (BOOL)isReachableVia3G {
    return (self.reachabilityStatus == ACSReachabilityStatusReachableVia3G);
}

- (BOOL)isReachableVia4G {
    return (self.reachabilityStatus == ACSReachabilityStatusReachableVia4G);
}
#endif

- (BOOL)isReachableViaWiFi {
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        // Check we're reachable
        if((flags & kSCNetworkReachabilityFlagsReachable)) {
#if	TARGET_OS_IPHONE
            // Check we're NOT on WWAN
            if((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
                return NO;
            }
#endif
            return YES;
        }
    }
    
    return NO;
}

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
- (BOOL)connectionRequired {
    NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    
    return NO;
}

#pragma mark - reachability status stuff

- (ACSReachabilityStatus)reachabilityStatus {
    
    NSAssert(_reachabilityRef != NULL, @"reachabilityStatus called with NULL SCNetworkReachabilityRef");
    ACSReachabilityStatus returnValue = ACSReachabilityStatusNotReachable;
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        if (_alwaysReturnLocalWiFiStatus) {
            returnValue = [self localWiFiStatusForFlags:flags];
        }
        else {
            returnValue = [self networkStatusForFlags:flags];
        }
    }
    return returnValue;
}

- (NSString *)localizedNetworkReachabilityStatusString {
    
    return ACSStringFromReachabilityStatus(self.reachabilityStatus);
}

#pragma mark - Callback function calls this method

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    
    // this makes sure the change notification happens on the MAIN THREAD
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ACSNetworkingReachabilityDidChangeNotification
                                                            object:self];
    });
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] ||
        [key isEqualToString:@"reachableViaWWAN"] ||
        [key isEqualToString:@"reachableVia2G"] ||
        [key isEqualToString:@"reachableVia3G"] ||
        [key isEqualToString:@"reachableVia4G"] ||
        [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"reachabilityStatus"];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
