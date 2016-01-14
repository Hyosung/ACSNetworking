//
//  NSData+ACSMimeType.h
//  Stoney
//
//  Created by Stoney on 15/11/7.
//  Copyright © 2015年 Stone.y. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const ACSDataExtensionKey;
FOUNDATION_EXPORT NSString *const ACSDataMimeTypeKey;

@interface NSData (ACSMimeType)

@property (nonatomic, copy, readonly) NSDictionary *mimeTypeData;

@end
