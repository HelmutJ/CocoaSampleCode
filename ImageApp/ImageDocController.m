/*

File: ImageDocController.m

Abstract: ImageDocController class implementation

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

Copyright © 2005-2012 Apple Inc. Inc. All Rights Reserved.

*/

#import "ImageDocController.h"


/* 
    Typically, an application that uses NSDocumentController can only
    support a static list of file formats enumerated in its Info.plist file.
    
    This subclass of NSDocumentController is provided so that this
    application can dynamically support all the file formats supported 
    by ImageIO.
 */


static NSString* ImageIOLocalizedString (NSString* key)
{
    static NSBundle* b = nil;
    
    if (b==nil)
        b = [NSBundle bundleWithIdentifier:@"com.apple.ImageIO.framework"];

    // Returns a localized version of the string designated by 'key' in table 'CGImageSource'. 
    return [b localizedStringForKey:key value:key table: @"CGImageSource"];
}


@implementation ImageDocController

- (NSString*) defaultType
{
    return @"public.tiff";
}


// Return the names of NSDocument subclasses supported by this application.
// In this app, the only class is "ImageDoc".
//
- (NSArray*) documentClassNames
{
    return [NSArray arrayWithObject:@"ImageDoc"];
}


// Given a document type name, return the subclass of NSDocument
// that should be instantiated when opening a document of that type.
// In this app, the only class is "ImageDoc".
//
- (Class)documentClassForType:(NSString *)typeName
{
    return [[NSBundle mainBundle] classNamed:@"ImageDoc"];
}


// Given a document type name, return a string describing the document 
// type that is fit to present to the user.
//
- (NSString*) displayNameForType:(NSString *)typeName;
{
    return ImageIOLocalizedString(typeName);
}


// Return the name of the document type that should be used when opening a URL
// In this app, we return the UTI type returned by CGImageSourceGetType.
//
- (NSString*) typeForContentsOfURL:(NSURL *)absURL error:(NSError **)outError
{
    NSString* type = nil;
    CGImageSourceRef isrc = CGImageSourceCreateWithURL((__bridge CFURLRef)absURL, nil);
    if (isrc)
    {
        type = (__bridge NSString*)CGImageSourceGetType(isrc);
        CFRelease(isrc);
    }
    return type;
}


// Given a document type, return an array of corresponding file name extensions 
// and HFS file type strings of the sort returned by NSFileTypeForHFSTypeCode().
// In this app, 'typeName' is a UTI type so we can call UTTypeCopyDeclaration().
//

- (NSArray*) fileExtensionsFromType:(NSString *)typeName;
{
    NSArray* readExts = nil;
    
    CFDictionaryRef utiDecl = UTTypeCopyDeclaration((__bridge CFStringRef)typeName);
    if (utiDecl)
    {
        CFDictionaryRef utiSpec = CFDictionaryGetValue(utiDecl, kUTTypeTagSpecificationKey);
        if (utiSpec)
        {
            CFTypeRef  ext = CFDictionaryGetValue(utiSpec, kUTTagClassFilenameExtension);

            if (ext && CFGetTypeID(ext) == CFStringGetTypeID())
                readExts = [NSArray arrayWithObject:(__bridge id)ext];
            if (ext && CFGetTypeID(ext) == CFArrayGetTypeID())
                readExts = [NSArray arrayWithArray:(__bridge id)ext];
        }
        CFRelease(utiDecl);
    }
    
    return readExts;
}

@end
