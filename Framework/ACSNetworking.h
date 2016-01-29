// ACSNetworking.h
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

//! Project version number for ACSNetworking.
FOUNDATION_EXPORT double ACSNetworkingVersionNumber;

//! Project version string for ACSNetworking.
FOUNDATION_EXPORT const unsigned char ACSNetworkingVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ACSNetworking/PublicHeader.h>

#import <Availability.h>
#import <TargetConditionals.h>

#ifndef __ACSNETWORKING__
#define __ACSNETWORKING__

#import <ACSNetworking/ACSCache.h>
#import <ACSNetworking/ACSNetworkConfiguration.h>
#import <ACSNetworking/ACSReachability.h>

#import <ACSNetworking/ACSFileUploader.h>
#import <ACSNetworking/ACSFileDownloader.h>
#import <ACSNetworking/ACSURLHTTPRequester.h>
#import <ACSNetworking/ACSRequestManager.h>

#endif /* __ACSNETWORKING__ */