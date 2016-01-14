//
//  NSData+ACSMimeType.m
//  Stoney
//
//  Created by Stoney on 15/11/7.
//  Copyright © 2015年 Stone.y. All rights reserved.
//

#import "NSData+ACSMimeType.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#pragma mark - 前缀 A

const char aiff[5] = {0x46, 0x4F, 0x52, 0x4D, 0x00};

const char avi[4] = {0x52, 0x49, 0x46, 0x46}; //WAV/4XM

const char asf[8] = {0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11}; //WMA/WMV

#pragma mark - 前缀 B

const char bin[7] = {0x42, 0x4C, 0x49, 0x32, 0x32, 0x33, 0x51};

const char bmp[2] = {0x42, 0x4D};

const char bpg[4] = {0x42, 0x50, 0x47, 0xFB};

#pragma mark - 前缀 C

const char chm[4] = {0x49, 0x54, 0x53, 0x46};

const char class[4] = {0xCA, 0xFE, 0xBA, 0xBE}; // .a

#pragma mark - 前缀 D

const char dmg[1] = {0x78};

#pragma mark - 前缀 E

const char exe[2] = {0x4D, 0x5A};

#pragma mark - 前缀 F

const char flv[3] = {0x46, 0x4C, 0x56};

#pragma mark - 前缀 G

const char gho[2] = {0xFE, 0xEF};

const char gif[3] = {0x47, 0x49, 0x46};
const char gz[3] = {0x1F, 0x8B, 0x08};

#pragma mark - 前缀 H

#pragma mark - 前缀 I

const char ico[4] = {0x00, 0x00, 0x01, 0x00};

const char iso[5] = {0x43, 0x44, 0x30, 0x30, 0x31};

#pragma mark - 前缀 J

const char jg[4] = {0x4A, 0x47, 0x04, 0x0E};

const char jp2[8] = {0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20};

const char jpg[3] = {0xFF, 0xD8, 0xFF}; //JPEG JFIF JPE

#pragma mark - 前缀 K

#pragma mark - 前缀 L

const char lib[8] = {0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A};

const char lzh[3] = {	0x2D, 0x6C, 0x68};

const char _log[8] = {0x2A, 0x2A, 0x2A, 0x20, 0x20, 0x49, 0x6E, 0x73};

#pragma mark - 前缀 M

const char mp[2] = {0x0C, 0xED};

const char mp3[2] = {0xFF, 0xFA};

const char mp3_id3v1[2] = {0xFF, 0xFB};

const char mp3_id3v2[3] = {0x49, 0x44, 0x33};

const char mlv[4] = {0x4D, 0x4C, 0x56, 0x49};

const char mp4[8] = {0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70};

const char mpg_dvd[4] = {0x00, 0x00, 0x01, 0xBA};//VOB

const char mpg_mpeg[4] = {0x00, 0x00, 0x01, 0xB3};

const char mkv[8] = {0x1A, 0x45, 0xDF, 0xA3, 0x93, 0x42, 0x82, 0x88};

const char mov[10] = {0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74};
const char mov_moov[4] = {0x6D, 0x6F, 0x6F, 0x76};
const char mov_mdat[4] = {0x6D, 0x64, 0x61, 0x74};
const char mov_f[4] = {0x66, 0x72, 0x65, 0x65};
const char mov_w[4] = {0x77, 0x69, 0x64, 0x65};
const char mov_p[4] = {0x70, 0x6E, 0x6F, 0x74};
const char mov_s[4] = {0x73, 0x6B, 0x69, 0x70};

const char m4a[11] = {0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41}; // M4R

#pragma mark - 前缀 N

#pragma mark - 前缀 O

#pragma mark - 前缀 P

const char pem[10] = {0x2D, 0x2D, 0x2D, 0x2D, 0x2D, 0x42, 0x45, 0x47, 0x49, 0x4E};

const char ps[4] = {0x25, 0x21, 0x50, 0x53};

const char psd[4] = {0x38, 0x42, 0x50, 0x53};

const char pdf[4] = {0x25, 0x50, 0x44, 0x46};

const char pch[6] = {0x56, 0x43, 0x50, 0x43, 0x48, 0x30};

const char png[4] = {0x89, 0x50, 0x4E, 0x47};

const char plist[6] = {0x62, 0x70, 0x6C, 0x69, 0x73, 0x74};

#pragma mark - 前缀 Q

#pragma mark - 前缀 R

const char rtf[6] = {0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31};

const char rar[6] = {0x52, 0x61, 0x72, 0x21, 0x1A, 0x07};

const char rgb[6] = {0x01, 0xDA, 0x01, 0x01, 0x00, 0x03};

const char rmvb[4] = {0x2E, 0x52, 0x4D, 0x46};

#pragma mark - 前缀 S

const char swf_c[3] = {0x43, 0x57, 0x53};

const char swf_f[3] = {0x46, 0x57, 0x53};

const char sqlite3[15] = {0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33};

#pragma mark - 前缀 T

const char tar[5] = {0x75, 0x73, 0x74, 0x61, 0x72};

const char tar_z1[2] = {0x1F, 0xA0};

const char tar_z2[3] = {0x1F, 0x9D, 0x90};

const char tar_bz2[3] = {0x42, 0x5A, 0x68};

const char tiff[3] = {0x49, 0x20, 0x49};

const char tiff_ii[4] = {0x49, 0x49, 0x2A, 0x00};

const char tiff_mm[3] = {0x4D, 0x4D, 0x00};

#pragma mark - 前缀 U

const char uce[4] = {0x55, 0x43, 0x45, 0x58};

const char ufa[6] = {0x55, 0x46, 0x41, 0xC6, 0xD2, 0xC1};

#pragma mark - 前缀 V

const char vcf[8] = {0x42, 0x45, 0x47, 0x49, 0x4E, 0x3A, 0x56, 0x43};

const char vmdk[3] = {0x4B, 0x44, 0x4D};

#pragma mark - 前缀 W

const char wpf[3] = {0x81, 0xCD, 0xAB};

const char webp[4] = {0x72, 0x69, 0x66, 0x66};

#pragma mark - 前缀 X

const char xar[4] = {0x78, 0x61, 0x72, 0x21};

const char xml[19] = {0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E, 0x30, 0x22};

#pragma mark - 前缀 Y

#pragma mark - 前缀 Z

#pragma mark - 前缀 数字

const char _3g2[6] = {0x66, 0x74, 0x79, 0x70, 0x33, 0x67};

const char _3gp[8] = {0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70};

const char _3gp2[8] = {0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70};

const char _3gp5[8] = {0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70};

const char _7z[6]  = {0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C};

#define if_statement(_s, _e, ...) if (!memcmp(bytes, _s, sizeof(_s) / sizeof(char))) { extension = @#_e; mimeType = @#__VA_ARGS__;}
#define else_if_statement(_s, _e, ...) else if_statement(_s, _e, __VA_ARGS__)

NSString *const ACSDataExtensionKey = @"kACSDataExtensionKey";
NSString *const ACSDataMimeTypeKey  = @"kACSDataMimeTypeKey";

@implementation NSData (ACSMimeType)

static inline NSString * ACSMIMETypeFromExtension(NSString *extension) {
#ifdef __UTTYPE__
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return CFBridgingRelease(MIMEType);
#else
#pragma unused (extension)
    return @"application/octet-stream";
#endif
}

- (NSDictionary *)mimeTypeData {
    
    char bytes[20];
    [self getBytes:&bytes length:20];
    NSString *extension = @"";
    NSString *mimeType = @"";
    
    if_statement(aiff, aiff)
    else_if_statement(avi, avi)
    else_if_statement(asf, asf)
    else_if_statement(bin, bin)
    else_if_statement(bmp, bmp)
    else_if_statement(chm, chm)
    else_if_statement(dmg, dmg)
    else_if_statement(exe, exe)
    else_if_statement(flv, flv)
    else_if_statement(gho, gho)
    else_if_statement(gif, gif)
    else_if_statement(gz, gz)
    else_if_statement(ico, ico)
    else_if_statement(iso, iso)
    else_if_statement(jg, jg)
    else_if_statement(jp2, jp2)
    else_if_statement(jpg, jpg)
    else_if_statement(lzh, lzh)
    else_if_statement(mp3, mp3)
    else_if_statement(mp3_id3v1, mp3)
    else_if_statement(mp3_id3v2, mp3)
    else_if_statement(mp4, mp4)
    else_if_statement(mpg_dvd, mpg)
    else_if_statement(mpg_mpeg, mpg)
    else_if_statement(mov, mov)
    else_if_statement(mov_f, mov)
    else_if_statement(mov_mdat, mov)
    else_if_statement(mov_moov, mov)
    else_if_statement(mov_p, mov)
    else_if_statement(mov_s, mov)
    else_if_statement(mov_w, mov)
    else_if_statement(mlv, mlv)
    else_if_statement(m4a, m4a)
    else_if_statement(pem, pem)
    else_if_statement(pdf, pdf)
    else_if_statement(plist, xml)
    else_if_statement(png, png)
    else_if_statement(ps, ps)
    else_if_statement(psd, psd)
    else_if_statement(rar, rar)
    else_if_statement(rtf, rtf)
    else_if_statement(rmvb, rmvb)
    else_if_statement(swf_c, swf, application/x-shockwave-flash) // 设置默认的MimeType
    else_if_statement(swf_f, swf, application/x-shockwave-flash) // 设置默认的MimeType
    else_if_statement(tar, tar)
    else_if_statement(tar_z1, z)
    else_if_statement(tar_z2, z)
    else_if_statement(tar_bz2, bz2)
    else_if_statement(tiff, tiff)
    else_if_statement(tiff_ii, tiff)
    else_if_statement(tiff_mm, tiff)
    else_if_statement(vcf, vcf, text/x-vcard) // 设置默认的MimeType
    else_if_statement(webp, webp, image/webp)
    else_if_statement(xar, xar)
    else_if_statement(xml, xml)
    else_if_statement(_3g2, 3g2)
    else_if_statement(_3gp, 3gp)
    else_if_statement(_3gp2, 3gp)
    else_if_statement(_3gp5, 3gp)
    else_if_statement(_7z, 7z)
    
    NSString *systemMimeType = ACSMIMETypeFromExtension(extension);
    
    if (![systemMimeType isEqualToString:@"application/octet-stream"] ||
        [[mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        mimeType = systemMimeType;
    }

    return @{ACSDataMimeTypeKey: mimeType ?: @"application/octet-stream",
             ACSDataExtensionKey: extension ?: @""};
}

@end
