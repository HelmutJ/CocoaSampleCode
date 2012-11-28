/*

File: PrintView.m

Abstract: Print.m class implementation

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

#import "PrintView.h"
#import "ImageDoc.h"


@implementation PrintView


- (id) initWithFrame:(NSRect)frame document:(ImageDoc*)imageDoc
{
    if ((self = [super initWithFrame:frame])!= nil)
        mImageDoc  = imageDoc;

    return self;
}

- (NSString *) printJobTitle
{
    return [mImageDoc displayName];
}


- (void) drawRect: (NSRect) rect 
{
    // FYI: rect is a scaled and clipped to the page boundaries part of the 
    // document [printInfo imageablePageBounds]
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    
    float scale, xScale, yScale;
    
    CGSize  imageSize;
    NSRect  printableRect = NSIntegralRect([self frame]);
    
    imageSize = [mImageDoc imageSize];
    CGRect  imageRect = {{0,0}, {imageSize.width, imageSize.height}};
    
    // adjust for orientation and non-symetric DPI of the image
    
    CGAffineTransform imTransform = [mImageDoc imageTransform];
    
    imageSize = CGRectApplyAffineTransform(imageRect, imTransform).size;
    
    // find the scale to fit
    
    xScale = printableRect.size.width  / imageSize.width;
    yScale = printableRect.size.height / imageSize.height;
    scale = MIN(xScale, yScale);
    
    // adjust the image transform
    
    imTransform = CGAffineTransformConcat(imTransform, CGAffineTransformMakeScale(scale,scale));
    
    // center the image
    
    float tx = (printableRect.size.width - imageSize.width * scale)  / 2.
    + printableRect.origin.x;
    float ty = (printableRect.size.height - imageSize.height* scale) / 2.
    + printableRect.origin.y;
    
    imTransform.tx += tx;
    imTransform.ty += ty;
    
    // adjust transform
    CGContextConcatCTM(context, imTransform);
    
    // draw!
    [mImageDoc  drawImage:context imageRect:imageRect];
    
    CGContextRestoreGState(context);
}

@end
