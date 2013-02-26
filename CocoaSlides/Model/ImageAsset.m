/*

File: ImageAsset.m

Abstract: ImageAsset Model Class for CocoaSlides

Version: 1.4

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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/

#import "ImageAsset.h"
#import "NSImage+Conversion.h"

@implementation ImageAsset

+ (NSArray *)fileTypes {
    return [NSImage imageFileTypes];
}

- (void)dealloc {
    if (imageProperties) {
        CFRelease(imageProperties);
    }
    if (imageSource) {
        CFRelease(imageSource);
    }
    [super dealloc];
}

- (NSInteger)pixelsWide {
    if (!imageProperties) [self loadMetadata];
    return [[(NSDictionary *)imageProperties valueForKey:(NSString *)kCGImagePropertyPixelWidth] intValue];
}

- (NSInteger)pixelsHigh {
    if (!imageProperties) [self loadMetadata];
    return [[(NSDictionary *)imageProperties valueForKey:(NSString *)kCGImagePropertyPixelHeight] intValue];
}

// Many kinds of image files contain prerendered thumbnail images that can be quickly loaded without having to decode the entire contents of the image file and reconstruct the full-size image.  The ImageIO framework's CGImageSource API provides a means to do this, using the CGImageSourceCreateThumbnailAtIndex() function.  For more information on CGImageSource objects and their capabilities, see the CGImageSource reference on the Apple Developer Connection website, at http://developer.apple.com/documentation/GraphicsImaging/Reference/CGImageSource/Reference/reference.html
- (BOOL)createImageSource {
    if (imageSource == NULL) {
        // Compose absolute URL to file.
        NSURL *sourceURL = [[self url] absoluteURL];
        if (sourceURL == nil) {
            return NO;
        }
        
        // Create a CGImageSource from the URL.
        imageSource = CGImageSourceCreateWithURL((CFURLRef)sourceURL, NULL);
        if (imageSource == NULL) {
            return NO;
        }
        CFStringRef imageSourceType = CGImageSourceGetType(imageSource);
        if (imageSourceType == NULL) {
            CFRelease(imageSource);
            return NO;
        }
        CFRelease(imageSourceType);
    }
    return imageSource ? YES : NO;
}

- (BOOL)loadMetadata {
    if (imageProperties == NULL) {
        if (![self createImageSource]) {
            return NO;
        }
        
        // This code looks at the first image only.  To be truly general, we'd need to handle the possibility of an image source having more than one image to offer us.
        int index = 0;
        imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL);
    }
    
    // Return indicating success!
    return imageProperties ? YES : NO;
}

- (BOOL)loadPreviewImage {
    BOOL success;

    if (![self createImageSource]) return NO;

    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
        // Ask ImageIO to create a thumbnail from the file's image data, if it can't find a suitable existing thumbnail image in the file.  We could comment out the following line if only existing thumbnails were desired for some reason (maybe to favor performance over being guaranteed a complete set of thumbnails).
        [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent,
        [NSNumber numberWithInt:160], (NSString *)kCGImageSourceThumbnailMaxPixelSize,
        nil];
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);

    NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail];
    [self performSelectorOnMainThread:@selector(setPreviewImage:) withObject:image waitUntilDone:NO];
    success = image ? YES : NO;
    [image release];

    CGImageRelease(thumbnail);
    [options release];

    return success;
}

@end
