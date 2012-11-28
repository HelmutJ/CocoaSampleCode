/*

File: ImageInfoPanel.m

Abstract: ImageInfoPanel.m class implementation

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
            1/08   added CFRelease() call to setURL: method to fix leak
*/

#import "ImageInfoPanel.h"


// This routine is provided so that the panel can dynamically 
// support all the file formats supported by ImageIO.
//

static NSString* ImageIOLocalizedString (NSString* key)
{
    static NSBundle* b = nil;

    if (b==nil)
        b = [NSBundle bundleWithIdentifier:@"com.apple.ImageIO.framework"];

    return [b localizedStringForKey:key value:key table: @"CGImageSource"];
}


@implementation DemoAppThumbView

- (void) dealloc
{
    [self setImage:nil];
}


- (void) setImage:(CGImageRef)image
{
    CGImageRetain(image);
    CGImageRelease(mImage);
    mImage = image;
    [self setNeedsDisplay:YES];
}


// compute bounds rect to hold our image
//
- (CGRect) boundsRectToFitImage
{
    float srcWidth  = (float)CGImageGetWidth (mImage);
    float srcHeight = (float)CGImageGetHeight(mImage);

    NSRect bounds = [self bounds];

    if ((srcWidth/srcHeight) < (bounds.size.width/bounds.size.height))
    {
        float w = bounds.size.height * srcWidth/srcHeight;
        bounds.origin.x += (bounds.size.width - w)/2;
        bounds.size.width = w;
    }
    else
    {
        float h = bounds.size.width * srcHeight/srcWidth;
        bounds.origin.y += (bounds.size.height - h)/2;
        bounds.size.height = h;
    }

    CGRect result = *(CGRect*)&bounds;
    result = CGRectIntegral(result);

    return result;
}


// This view completely covers its frame rectangle when drawing so return YES. 
//
- (BOOL) isOpaque
{
    return YES;
}


- (void) drawRect:(NSRect)rect
{
    // drawBackground
    [[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0] set];
    [NSBezierPath fillRect:[self bounds]];

    if (mImage)
    {
        NSGraphicsContext* nsctx = [NSGraphicsContext currentContext];
        CGContextRef  c = (CGContextRef)[nsctx graphicsPort];
        CGRect  r = [self boundsRectToFitImage];
        CGContextSetInterpolationQuality(c, kCGInterpolationNone);
        CGContextDrawImage(c, r, mImage);
    }
}

@end


#pragma mark -


ImageInfoPanel*  gSharedInfoPanel = nil;

@implementation ImageInfoPanel

- (void) awakeFromNib
{
    if (gSharedInfoPanel==nil)
        gSharedInfoPanel = self;
        
    [self setBecomesKeyOnlyIfNeeded:YES];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:nil];
    [nc addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:nil];
}


- (void) windowBecameMain:(NSNotification*)notif
{
    NSWindow* w = [notif object];
    NSDocument* doc = [[NSDocumentController sharedDocumentController] documentForWindow:w];
    [self setURL:[doc fileURL]];
}


- (void) windowResignedMain:(NSNotification*)notif
{
    [self setURL:nil];
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// Build image property tree for display of image properties in the
// image information panel
//
- (NSArray*) propTree:(NSDictionary*)branch
{
    NSMutableArray* tree = [[NSMutableArray alloc] init];
    unsigned int i, count = [branch count];

    for (i=0; i<count; i++)
    {
        NSArray* keys = [[branch allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString* key = [keys objectAtIndex:i];
        NSString* locKey = ImageIOLocalizedString(key);
        id obj = [branch objectForKey:key];
        NSDictionary* leaf = nil;
        
        if ([obj isKindOfClass:[NSDictionary class]])
            leaf = [NSDictionary dictionaryWithObjectsAndKeys:
                        locKey,@"key",  @"",@"val",  [self propTree:obj],@"children",  nil];
        else
            leaf = [NSDictionary dictionaryWithObjectsAndKeys:
                        locKey,@"key",  obj,@"val",  nil];
                        
        [tree addObject:leaf];
    }
    return tree;
}


// Image Info Panel setup:
// - Create the image thumbnail for the image info panel
// - Create the metadata tree for the info panel's outline view
// - Set the image path, image file type and image file size strings
//
- (void) setURL:(NSURL*)url
{
    if (nil == url) {
        return;
    }
    
    if ([url isEqual:mUrl])
        return;
    
    mUrl = url;
    
    CGImageSourceRef source = NULL;
    
    if (url) source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);

//    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (source)
    {
        // get image properties (height, width, depth, metadata etc.) for display
        NSDictionary* props = (__bridge_transfer NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        [mTree setContent:[self propTree:props]];
        
        // image thumbnail options
        NSDictionary* thumbOpts = [NSDictionary dictionaryWithObjectsAndKeys:
                        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                        [NSNumber numberWithInt:128], (id)kCGImageSourceThumbnailMaxPixelSize, 
                        nil];
                    
        // make image thumbnail
        CGImageRef image = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)thumbOpts);
        [mThumbView setImage:image];
        CGImageRelease(image);
        
        // set image path string for image info panel
        [mFilePath setStringValue:[mUrl path]];
        
        // set image type string for image info panel
        NSString* uti = (__bridge NSString*)CGImageSourceGetType(source);
        [mFileType setStringValue:[NSString stringWithFormat:@"%@\n%@",
                        ImageIOLocalizedString(uti), uti]];
        
        // set image size string for image info panel
        CFDictionaryRef fileProps = CGImageSourceCopyProperties(source, nil);
        [mFileSize setStringValue:[NSString stringWithFormat:@"%@ bytes",
            (__bridge id)CFDictionaryGetValue(fileProps, kCGImagePropertyFileSize)]];
        CFRelease(fileProps);
        CFRelease(source);
    }
    else  // couldn't make image source for image, so display nothing
    {
        [mTree setContent:nil];
        [mThumbView setImage:nil];
        
        [mFilePath setStringValue:@""];
        [mFileType setStringValue:@""];
        [mFileSize setStringValue:@""];
    }
}


+ (void) setURL:(NSURL*)url
{
    // Update the info panel after a short delay so that 
    // we don't slow down the display of the main window.
    [gSharedInfoPanel performSelector:@selector(setURL:) withObject:url afterDelay:0.01];
}

@end
