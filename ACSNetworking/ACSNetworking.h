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

#ifndef __ACSNETWORKING__
#define __ACSNETWORKING__

/**
 How to use?
 
 AppDelegate.m -> application:didFinishLaunchingWithOptions:
 [ACSNetworkConfiguration defaultConfiguration].baseURL = [NSURL URLWithString:@"http://example.com"];
 [ACSNetworkConfiguration defaultConfiguration].downloadExpirationTimeInterval = 60.0 * 60.0 * 24.0; //One day
 [ACSNetworkConfiguration defaultConfiguration].cacheExpirationTimeInterval = 60.0 * 2; //Two minutes
 
 /------------------------/
 GET Request
 
 ------>Block
 [[ACSRequestManager sharedManager] fetchDataFromRequester:ACSCreateGETRequester(@"path", @{@"key": @"value"}, ^(id result, NSError *error) {
 
 })];
 
 ------>Delegate
 ACSURLHTTPRequester *requester = ACSCreateGETRequester(@"path", @{@"key": @"value"}, self);
 [[ACSRequestManager sharedManager] fetchDataFromRequester:requester];
 
 POST Request
 
 ------>Block
 [[ACSRequestManager sharedManager] fetchDataFromRequester:ACSCreatePOSTRequester(@"path", @{@"key": @"value"}, ^(id result, NSError *error) {
 
 })];
 
 ------>Delegate
 ACSURLHTTPRequester *requester = ACSCreatePOSTRequester(@"path", @{@"key": @"value"}, self);
 [[ACSRequestManager sharedManager] fetchDataFromRequester:requester];
 
 Upload File (fileValue Supported formats NSURL/NSString/UIImage/NSData)
 
 ------>Block
 [[ACSRequestManager sharedManager] uploadFileFromRequester:ACSCreateUploader(@"uploadFile", @{@"fileKey": @"fileValue"}, ^(ACSRequestProgress progress, id result, NSError *error) {
 
 })];
 
 ------>Delegate
 ACSFileUploader *uploader = ACSCreateUploader(@"uploadFile", @{@"fileKey": @"fileValue"}, self);
 [[ACSRequestManager sharedManager] fetchDataFromRequester:uploader];
 
 Download File 
 
 ------>Block
 [[ACSRequestManager sharedManager] downloadFileFromRequester:ACSCreateDownloader(@"downloadFile", ^(ACSRequestProgress progress, id result, NSError *error) {
 
 })];
 
 ------>Delegate
 ACSFileDownloader *downloader = ACSCreateDownloader(@"downloadFile", self);
 [[ACSRequestManager sharedManager] fetchDataFromRequester:downloader];
 
 **/

#import "ACSCache.h"
#import "ACSNetworkConfiguration.h"
#import "ACSReachability.h"

#import "ACSFileUploader.h"
#import "ACSFileDownloader.h"
#import "ACSURLHTTPRequester.h"
#import "ACSRequestManager.h"

#endif /* __ACSNETWORKING__ */
