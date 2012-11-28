/*

File: ImageView.m

Abstract: ImageView.m class implementation

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

*/

#import "ImageDoc.h"
#import "ImageView.h"
#import <Quartz/Quartz.h>


static const float  kMargin = 10;


@implementation ImageView

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    [[NSNotificationCenter defaultCenter]
        addObserver: self selector: @selector(newScreenProfile:)
        name: NSWindowDidChangeScreenProfileNotification object:nil];

    return self;
}

// This view completely covers its frame rectangle when drawing so return YES. 
//
- (BOOL) isOpaque
{
    return YES;
}

// Return a image transformation matrix that will fit the image in the view
//
- (CGAffineTransform) imageTransformToFitView
{
    CGRect imageRect = {{0,0}, [mImageDoc imageSize]};

    CGAffineTransform ctm = [mImageDoc imageTransform];
     
    CGSize ctmdSize = CGRectApplyAffineTransform(imageRect, ctm).size;

    NSSize destSize = NSInsetRect([self bounds], kMargin, kMargin).size;

    // scale to fit in view rect
    CGFloat scale = MIN(destSize.width/ctmdSize.width, destSize.height/ctmdSize.height);
    ctm = CGAffineTransformConcat(ctm, CGAffineTransformMakeScale(scale,scale));

    return ctm;
}

- (void) drawImage
{
    NSRect viewBounds = [self bounds];
    CGRect imageRect = {{0,0}, [mImageDoc imageSize]};
    
    // get transform matrix to fit image to view
    CGAffineTransform ctm = [self imageTransformToFitView];
    
    // center in view rect
    CGSize ctmdSize = CGRectApplyAffineTransform(imageRect, ctm).size;
    ctm.tx += viewBounds.origin.x + (viewBounds.size.width - ctmdSize.width)/2;
    ctm.ty += viewBounds.origin.y + (viewBounds.size.height - ctmdSize.height)/2;
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    if (context==nil)
        return;
    
    // Concatenate the current graphics state's transformation matrix (the CTM)
    // with the affine transform `ctm'
    CGContextConcatCTM(context, ctm);
    
    // use low quality interpolation while live resizing
    CGInterpolationQuality q = [self inLiveResize] ? NSImageInterpolationNone : NSImageInterpolationHigh;
    CGContextSetInterpolationQuality(context, q);
    
    // now draw using updated transform
    [mImageDoc  drawImage:context imageRect:imageRect];
}

- (void) drawCIImage
{
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    if (context==nil)
        return;

    // scale to fit in view rect
    CIImage* image = [mImageDoc currentCIImageWithTransform:[self imageTransformToFitView]];
    if (image==nil)
        return;

    // center in view rect
    NSRect viewBounds = [self bounds];
    CGRect sRect = [image extent];
    CGRect dRect = sRect;
    dRect.origin.x = viewBounds.origin.x + (viewBounds.size.width - sRect.size.width)/2;
    dRect.origin.y = viewBounds.origin.y + (viewBounds.size.height - sRect.size.height)/2;

    CIContext* ciContext = [CIContext contextWithCGContext:context options:nil];
    [ciContext drawImage:image inRect:dRect fromRect:sRect];
}


- (void) drawRect:(NSRect)rect
{
    // drawBackground
    [[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.0] set];
    [NSBezierPath fillRect:[self bounds]];
    
    if ([mImageDoc switchState])
        [self drawCIImage];
    else
        [self drawImage];
}

// Force a high quality update after live resizing
- (void) viewDidEndLiveResize
{
    if ([mImageDoc switchState]==NO)
        [self setNeedsDisplay:YES];
}


- (void) newScreenProfile:(NSNotification*)n
{
}

@end
