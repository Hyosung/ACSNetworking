// ACSReachability.h
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
#import <SystemConfiguration/SystemConfiguration.h>

typedef NS_ENUM(NSInteger, ACSReachabilityStatus) {
    ACSReachabilityStatusNotReachable     = 0,
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    ACSReachabilityStatusReachableViaWWAN = 1,
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    ACSReachabilityStatusReachableVia2G = 2,
    ACSReachabilityStatusReachableVia3G = 3,
    ACSReachabilityStatusReachableVia4G = 4,
#endif
    
#endif
    ACSReachabilityStatusReachableViaWiFi = 5,
};

/**
 `ACSReachability` monitors the reachability of domains, and addresses for both WWAN(2G/3G/4G) and WiFi network interfaces.
 
 Reachability can be used to determine background information about why a network operation failed, or to trigger a network operation retrying when a connection is established. It should not be used to prevent a user from initiating a network request, as it's possible that an initial request may be required to establish reachability.
 
 See Apple's Reachability Sample Code ( https://developer.apple.com/library/prerelease/ios/samplecode/Reachability/ )
 
 https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFNetworkReachabilityManager.h
 
 @warning Instances of `ACSReachability` must be started with `-startMonitoring` before reachability status can be determined.
 */

@interface ACSReachability : NSObject

/**
 The current network reachability status.
 */
@property (readonly, nonatomic, assign) ACSReachabilityStatus reachabilityStatus;

/**
 Whether or not the network is currently reachable.
 */
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
/**
 Whether or not the network is currently reachable via WWAN.
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
/**
 Whether or not the network is currently reachable via 2G.
 */
@property (readonly, nonatomic, assign, getter = isReachableVia2G) BOOL reachableVia2G NS_AVAILABLE_IOS(7_0);

/**
 Whether or not the network is currently reachable vai 3G.
 */
@property (readonly, nonatomic, assign, getter = isReachableVia3G) BOOL reachableVia3G NS_AVAILABLE_IOS(7_0);

/**
 Whether or not the network is currently reachable via 4G.
 */
@property (readonly, nonatomic, assign, getter = isReachableVia4G) BOOL reachableVia4G NS_AVAILABLE_IOS(7_0);
#endif

#endif

/**
 Whether or not the network is currently reachable via WiFi.
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

///---------------------
/// @name Initialization
///---------------------

/*!
 * Use to check the reachability of a given host name.
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;

/*!
 * Use to check the reachability of a given IP address.
 */
+ (instancetype)reachabilityWithAddress:(const void *)hostAddress;

/*!
 * Checks whether the default route is available. Should be used by applications that do not connect to a particular host.
 */
+ (instancetype)reachabilityForInternetConnection;

/*!
 * Checks whether a local WiFi connection is available.
 */
+ (instancetype)reachabilityForLocalWiFi;

/*!
 * Start listening for reachability notifications on the current run loop.
 */
- (BOOL)startNotifier;
- (void)stopNotifier;

/*!
 * WWAN may be available, but not active until a connection has been established. WiFi may require a connection for VPN on Demand.
 */
- (BOOL)connectionRequired;

///-------------------------------------------------
/// @name Getting Localized Reachability Description
///-------------------------------------------------

/**
 Returns a localized string representation of the current network reachability status.
 */
- (NSString *)localizedNetworkReachabilityStatusString;

@end

///----------------
/// @name Constants
///----------------

/**
 ##  Reachability
 
 The following constants are provided by `ACSReachability` as possible network reachability statuses.
 
 enum {
 ACSReachabilityStatusNotReachable,
 ACSReachabilityStatusReachableVia2G,
 ACSReachabilityStatusReachableVia3G,
 ACSReachabilityStatusReachableVia4G,
 ACSReachabilityStatusReachableViaWiFi,
 }
 
 `ACSReachabilityStatusNotReachable`
 The `baseURL` host cannot be reached.
 
 `ACSReachabilityStatusReachableVia2G`
 The `baseURL` host can be reached via a cellular connection, 2G.
 
 `ACSReachabilityStatusReachableVia3G`
 The `baseURL` host can be reached via a cellular connection, 3G.
 
 `ACSReachabilityStatusReachableVia4G`
 The `baseURL` host can be reached via a cellular connection, 4G.
 
 `ACSReachabilityStatusReachableViaWiFi`
 The `baseURL` host can be reached via a Wi-Fi connection.
 */

///--------------------
/// @name Notifications
///--------------------

 /*
 @warning In order for network reachability to be monitored, include the `SystemConfiguration` framework in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 */
extern NSString * const ACSNetworkingReachabilityDidChangeNotification;
///--------------------
/// @name Functions
///--------------------

/**
 Returns a localized string representation of an `ACSReachabilityStatus` value.
 */
extern NSString * ACSStringFromReachabilityStatus(ACSReachabilityStatus status);