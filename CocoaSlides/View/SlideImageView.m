/*

File: SlideImageView.m

Abstract: SlideImageView is a simple subclass of NSImageView that adds a bit of drawing for a more slide-like appearance, and passes mouseDown: events to its superview (which in the Cocoa Slides application is a SlideCarrierView).

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

#import "SlideImageView.h"

@implementation SlideImageView

// Pass mouseDown: events through to our superview.
- (void)mouseDown:(NSEvent *)theEvent {
    [[self superview] mouseDown:theEvent];
}

// Fill in semitransparent gray bands in any areas that the image doesn't cover, to give a more slide-like appearance.
- (void)drawRect:(NSRect)rect {
    NSImage *image = [self image];
    if (image != nil && [self imageScaling] == NSScaleProportionally) {
        NSSize imageSize = [image size];
        NSSize viewSize = [self bounds].size;
        if (imageSize.height > 0.0 && viewSize.height > 0.0) {
            CGFloat imageAspectRatio = imageSize.width / imageSize.height;
            CGFloat viewAspectRatio = viewSize.width / viewSize.height;
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] set];
            if (imageAspectRatio > viewAspectRatio) {
                // Fill in bands at top and bottom.
                CGFloat thumbnailHeight = viewSize.width / imageAspectRatio;
                CGFloat bandHeight = 0.5 * (viewSize.height - thumbnailHeight);
                NSRectFill(NSMakeRect(0, 0, viewSize.width, bandHeight));
                NSRectFill(NSMakeRect(0, viewSize.height - bandHeight, viewSize.width, bandHeight));
            } else if (imageAspectRatio < viewAspectRatio) {
                // Fill in bands at left and right.
                CGFloat thumbnailWidth = viewSize.height * imageAspectRatio;
                CGFloat bandWidth = 0.5 * (viewSize.width - thumbnailWidth);
                NSRectFill(NSMakeRect(0, 0, bandWidth, viewSize.height));
                NSRectFill(NSMakeRect(viewSize.width - bandWidth, 0, bandWidth, viewSize.height));
            }
        }
    }

    // Now let NSImageView do its drawing.
    [super drawRect:rect];
}

@end
