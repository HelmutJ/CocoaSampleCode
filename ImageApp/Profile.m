/*

File: Profile.m

Abstract: Profile.m class implementation

Version: <1.0>

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright © 2005-2012 Apple Inc. All Rights Reserved.

Change History (most recent first):
            1/08   added CFRelease() call to arrayOfAllProfilesWithSpace: 
                    method to fix leak

*/

#import "Profile.h"

// Callback routine with a description of a profile that is 
// called during an iteration through the available profiles.
//
static bool profileIterate (CFDictionaryRef profileInfo, void *userInfo)
{
    NSMutableArray* array = (__bridge NSMutableArray*) userInfo;

    Profile* prof = [Profile profileWithIterateData:profileInfo];
    if (prof)
    {
        [array addObject:prof];
    }
    
    return true;
}

@implementation Profile

// return an array of all profiles for the given color space
//
+ (NSArray*) arrayOfAllProfilesWithSpace:(icColorSpaceSignature)space
{
    CFIndex  i, count;
    Profile* prof = nil;
    NSMutableArray* profs = nil;
    
    NSArray* profArray = [Profile arrayOfAllProfiles];
    if (profArray) 
    {
        profs = [NSMutableArray arrayWithCapacity:0];
        
        count = [profArray count];
        for (i=0; i<count; i++)
        {
            prof = (Profile*)[profArray objectAtIndex:i];
            icProfileClassSignature  pClass = [prof classType];
            
            if ([prof spaceType] == space && [prof description] && 
                (pClass == icSigDisplayClass || pClass == icSigOutputClass))
                [profs addObject:prof];
        }        
    }
    return profs;
}

// return an array of all profiles
//

+ (NSArray*) arrayOfAllProfiles
{
    NSMutableArray* profs = [NSMutableArray arrayWithCapacity:0];
    
    ColorSyncIterateInstalledProfiles(profileIterate, NULL, (__bridge void *)profs, NULL);

    return (NSArray*)profs;
}

// default RGB profiile
//
+ (Profile*) profileDefaultRGB
{
    CFStringRef path = (__bridge CFStringRef)[[[NSUserDefaultsController sharedUserDefaultsController] defaults]
                        objectForKey:@"DefaultRGBProfile"];
    return [Profile profileWithPath:path];
}

// default Gray profile
//
+ (Profile*) profileDefaultGray
{
    CFStringRef path = (__bridge CFStringRef)[[[NSUserDefaultsController sharedUserDefaultsController] defaults]
                        objectForKey:@"DefaultGrayProfile"];
    return [Profile profileWithPath:path];
}

// default CMYK profile
//
+ (Profile*) profileDefaultCMYK
{
    CFStringRef path = (__bridge CFStringRef)[[[NSUserDefaultsController sharedUserDefaultsController] defaults]
                        objectForKey:@"DefaultCMYKProfile"];
    return [Profile profileWithPath:path];
}

// build profile from sRGB
//
+ (Profile*) profileWithSRGB
{
    return [[Profile alloc] initWithSRGB];
}

// build profile from Linear RGB
//
+ (Profile*) profileWithLinearRGB
{
    return [[Profile alloc] initWithLinearRGB];
}

// build profile from iterate data
//
+ (Profile*) profileWithIterateData:(CFDictionaryRef) data
{
    return [[Profile alloc] initWithIterateData:data];
}

// build profile from path
//
+ (Profile*) profileWithPath:(CFStringRef)path
{
    return [[Profile alloc] initWithCFPath:path];
}

// build profile from Generic RGB
//
- (Profile*) initWithSRGB
{
    mRef = ColorSyncProfileCreateWithName (kColorSyncSRGBProfile);

    if (mRef)
    {
        mURL = (CFURLRef) CFRetain (ColorSyncProfileGetURL (mRef, NULL));
        mClass = icSigDisplayClass;
        mSpace = icSigRgbData;
        return self;
    }
    else
    {
        return nil;
    }
}


- (Profile*) initWithLinearRGB
{
    static const uint8_t bytes[0x220] = 
        "\x00\x00\x02\x20\x61\x70\x70\x6c\x02\x20\x00\x00\x6d\x6e\x74\x72"
        "\x52\x47\x42\x20\x58\x59\x5a\x20\x07\xd2\x00\x05\x00\x0d\x00\x0c"
        "\x00\x00\x00\x00\x61\x63\x73\x70\x41\x50\x50\x4c\x00\x00\x00\x00"
        "\x61\x70\x70\x6c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\xf6\xd6\x00\x01\x00\x00\x00\x00\xd3\x2d"
        "\x61\x70\x70\x6c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x0a\x72\x58\x59\x5a\x00\x00\x00\xfc\x00\x00\x00\x14"
        "\x67\x58\x59\x5a\x00\x00\x01\x10\x00\x00\x00\x14\x62\x58\x59\x5a"
        "\x00\x00\x01\x24\x00\x00\x00\x14\x77\x74\x70\x74\x00\x00\x01\x38"
        "\x00\x00\x00\x14\x63\x68\x61\x64\x00\x00\x01\x4c\x00\x00\x00\x2c"
        "\x72\x54\x52\x43\x00\x00\x01\x78\x00\x00\x00\x0e\x67\x54\x52\x43"
        "\x00\x00\x01\x78\x00\x00\x00\x0e\x62\x54\x52\x43\x00\x00\x01\x78"
        "\x00\x00\x00\x0e\x64\x65\x73\x63\x00\x00\x01\xb0\x00\x00\x00\x6d"
        "\x63\x70\x72\x74\x00\x00\x01\x88\x00\x00\x00\x26\x58\x59\x5a\x20"
        "\x00\x00\x00\x00\x00\x00\x74\x4b\x00\x00\x3e\x1d\x00\x00\x03\xcb"
        "\x58\x59\x5a\x20\x00\x00\x00\x00\x00\x00\x5a\x73\x00\x00\xac\xa6"
        "\x00\x00\x17\x26\x58\x59\x5a\x20\x00\x00\x00\x00\x00\x00\x28\x18"
        "\x00\x00\x15\x57\x00\x00\xb8\x33\x58\x59\x5a\x20\x00\x00\x00\x00"
        "\x00\x00\xf3\x52\x00\x01\x00\x00\x00\x01\x16\xcf\x73\x66\x33\x32"
        "\x00\x00\x00\x00\x00\x01\x0c\x42\x00\x00\x05\xde\xff\xff\xf3\x26"
        "\x00\x00\x07\x92\x00\x00\xfd\x91\xff\xff\xfb\xa2\xff\xff\xfd\xa3"
        "\x00\x00\x03\xdc\x00\x00\xc0\x6c\x63\x75\x72\x76\x00\x00\x00\x00"
        "\x00\x00\x00\x01\x01\x00\x00\x00\x74\x65\x78\x74\x00\x00\x00\x00"
        "\x43\x6f\x70\x79\x72\x69\x67\x68\x74\x20\x41\x70\x70\x6c\x65\x20"
        "\x43\x6f\x6d\x70\x75\x74\x65\x72\x20\x49\x6e\x63\x2e\x00\x00\x00"
        "\x64\x65\x73\x63\x00\x00\x00\x00\x00\x00\x00\x13\x4c\x69\x6e\x65"
        "\x61\x72\x20\x52\x47\x42\x20\x50\x72\x6f\x66\x69\x6c\x65\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";

    CFDataRef data = CFDataCreateWithBytesNoCopy (NULL, bytes, sizeof (bytes), kCFAllocatorNull);

    mRef = ColorSyncProfileCreate (data, NULL);

    if (data) CFRelease (data);

    if (mRef)
    {
        mClass = icSigDisplayClass;
        mSpace = icSigRgbData;

        return self;
    }
    else
    {
        return nil;
    }
}


- (Profile*) initWithIterateData:(CFDictionaryRef) data
{
    CFDataRef headerData = CFDictionaryGetValue (data, kColorSyncProfileHeader);
        
    if (headerData)
    {
        icHeader* header = (icHeader*) CFDataGetBytePtr (headerData);
        mClass = header->deviceClass;
        mSpace = header->colorSpace;
    }

    mURL = (CFURLRef) CFDictionaryGetValue (data, kColorSyncProfileURL);
    if (mURL) CFRetain (mURL);

    mName = (CFStringRef)CFDictionaryGetValue (data, kColorSyncProfileDescription);
    if (mName) CFRetain (mName);

    return self;
}

- (Profile*) initWithCFPath:(CFStringRef) path
{
    if (path)
    {
        mURL = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, 0);
        
        mRef = ColorSyncProfileCreateWithURL (mURL, NULL);
        
        if (mRef)
        {
            CFDataRef headerData = ColorSyncProfileCopyHeader (mRef);
            
            if (headerData)
            {
                icHeader* header = (icHeader*) CFDataGetBytePtr (headerData);
                mClass = header->deviceClass;
                mSpace = header->colorSpace;
                CFRelease (headerData);
                
                return self;
            }
        }
    }

    return nil;
}


- (void) dealloc
{
    if (mRef) CFRelease(mRef);
    CGColorSpaceRelease(mColorspace);
    if (mName) CFRelease (mName);
    if (mPath) CFRelease (mPath);
    if (mURL) CFRelease(mURL);
}


- (ColorSyncProfileRef) ref
{
    if (mRef == NULL)
    {
        mRef = ColorSyncProfileCreateWithURL (mURL, NULL);
    }
    
    return mRef;
}


- (CFURLRef) url
{
    if (mURL == NULL)
    {
        mURL = (CFURLRef) ColorSyncProfileGetURL (mRef, NULL);
     }
     
     return mURL;
}


- (icProfileClassSignature) classType
{
    return mClass;
}


- (icColorSpaceSignature) spaceType
{
    return mSpace;
}


// profile description string
//
- (NSString*) description
{
    if (mName == nil)
    {
        mName = ColorSyncProfileCopyDescriptionString (mRef);
    }
    
    return (__bridge NSString*) mName;
}


- (NSString*) path
{
    if (mPath == NULL)
    {
        if (mURL == NULL)
        {
           (void) [self url];
        }
        
        if (mURL)
        {
            mPath =  CFURLCopyPath (mURL);
        }
    }

    return (__bridge NSString*)mPath;
}


- (BOOL) isEqual:(id)obj
{
    if ([obj isKindOfClass:[self class]])
        return [(NSString*)[self path] isEqualToString:(NSString*)[obj path]];
    return [super isEqual:obj];
}


- (CGColorSpaceRef) colorspace
{
    if (mColorspace == nil)
        mColorspace = CGColorSpaceCreateWithPlatformColorSpace((void *)[self ref]);
    return mColorspace;
}


- (id) valueForUndefinedKey:(NSString*)key
{
    printf ("Called\n");
    
    return (id)CFSTR("0");
}

@end


