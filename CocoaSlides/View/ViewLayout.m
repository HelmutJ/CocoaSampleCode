/*

File: ViewLayout.m

Abstract: Cocoa Slides encapsulates the various layouts it uses for positioning slides in a set of "ViewLayout" classes.  At layout time, a "ViewLayout" is given an ordered array of views to be positioned, along with a pointer to their containing superview.  Its job is simply to compute and set the desired frame origin and rotation for each given view.

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

#import "ViewLayout.h"

@implementation ViewLayout

+ (ViewLayout *)viewLayout {
    return [[[[self class] alloc] init] autorelease];
}

- (void)layoutSubviews:(NSArray *)arrangedSubviews ofView:(NSView *)view {
    // For subclasses to override.
}

@end

#define X_PADDING   10.0
#define Y_PADDING   10.0

@implementation CircularViewLayout

- (void)layoutSubviews:(NSArray *)arrangedSubviews ofView:(NSView *)view {
    NSRect box = NSInsetRect([view bounds], X_PADDING, Y_PADDING);
    NSSize maxSize = NSMakeSize(0.0, 0.0);
    for (NSView *subview in arrangedSubviews) {
        NSRect frame = [subview frame];
        maxSize.width = MAX(maxSize.width, frame.size.width);
        maxSize.height = MAX(maxSize.height, frame.size.height);
    }
    CGFloat halfMaxWidth = 0.5 * maxSize.width;
    CGFloat halfMaxHeight = 0.5 * maxSize.height;
    CGFloat radiusInset = sqrt(halfMaxWidth * halfMaxWidth + halfMaxHeight * halfMaxHeight);
    NSPoint circleCenter = NSMakePoint(NSMidX(box), NSMidY(box));
    CGFloat circleRadius = MIN(box.size.width, box.size.height) * 0.5 - radiusInset;

    CGFloat angleInRadians = 0.0;
    CGFloat angleStepInRadians = (2.0 * M_PI) / ((CGFloat)[arrangedSubviews count]);
    for (NSView *subview in arrangedSubviews) {
        NSPoint subviewCenter;
        subviewCenter.x = circleCenter.x + circleRadius * cos(angleInRadians);
        subviewCenter.y = circleCenter.y + circleRadius * sin(angleInRadians);
        NSRect frame = [subview frame];

        // Zero the view's frame rotation momentarily to make positioning the view easier.
        [subview setFrameRotation:0.0];

        // Position the view.
        [subview setFrameOrigin:NSMakePoint(subviewCenter.x - 0.5 * frame.size.width, subviewCenter.y - 0.5 * frame.size.height)];

        // Now rotate the view to the desired angle.  The -setFrameCenterRotation: method, new in Leopard, provides a convenient way to rotate a view about its center point (corresponding to the way that CALayers are rotated).  It adjusts the view's frame origin, together with its frame rotation angle, to achieve the requested rotation about the frame's center.
        CGFloat angleInDegrees = angleInRadians * (180.0 / M_PI);
        [subview setFrameCenterRotation:fmod(angleInDegrees + 270.0, 360.0)];
        angleInRadians += angleStepInRadians;
    }
}

@end

@implementation LoopViewLayout

- (void)layoutSubviews:(NSArray *)arrangedSubviews ofView:(NSView *)view {
    NSRect box = NSInsetRect([view bounds], X_PADDING, Y_PADDING);
    NSSize maxSize = NSMakeSize(0.0, 0.0);
    for (NSView *subview in arrangedSubviews) {
        NSRect frame = [subview frame];
        maxSize.width = MAX(maxSize.width, frame.size.width);
        maxSize.height = MAX(maxSize.height, frame.size.height);
    }
    CGFloat halfMaxWidth = 0.5 * maxSize.width;
    CGFloat halfMaxHeight = 0.5 * maxSize.height;
    CGFloat radiusInset = sqrt(halfMaxWidth * halfMaxWidth + halfMaxHeight * halfMaxHeight);
    NSPoint loopCenter = NSMakePoint(NSMidX(box), NSMidY(box));
    NSSize loopSize = NSMakeSize(0.5 * (box.size.width - 2.0 * radiusInset), 0.5 * (box.size.height - 2.0 * radiusInset));

    CGFloat angle = 0.0;
    CGFloat angleStep = (2.0 * M_PI) / ((CGFloat)[arrangedSubviews count]);
    for (NSView *subview in arrangedSubviews) {
        NSPoint subviewCenter;
        subviewCenter.x = loopCenter.x + loopSize.width * cos(angle);
        subviewCenter.y = loopCenter.y + loopSize.height * sin(2.0 * angle);
        NSRect frame = [subview frame];

        // Zero the view's frame rotation.
        [subview setFrameRotation:0.0];

        // Position the view.
        [subview setFrameOrigin:NSMakePoint(subviewCenter.x - 0.5 * frame.size.width, subviewCenter.y - 0.5 * frame.size.height)];
        angle += angleStep;
    }
}

@end

@implementation ScatterViewLayout

- (void)layoutSubviews:(NSArray *)arrangedSubviews ofView:(NSView *)view {
    NSRect box = NSInsetRect([view bounds], X_PADDING, Y_PADDING);
    NSPoint p;
    for (NSView *subview in arrangedSubviews) {

        // Zero the view's frame rotation momentarily to make positioning the view easier.
        [subview setFrameRotation:0.0];

        // Position the view.
        NSRect frame = [subview frame];
        p.x = box.origin.x + drand48() * (box.size.width - frame.size.width);
        p.y = box.origin.y + drand48() * (box.size.height - frame.size.height);
        [subview setFrameOrigin:p];

        // Now rotate the view to the desired angle.  The -setFrameCenterRotation: method, new in Leopard, provides a convenient way to rotate a view about its center point (corresponding to the way that CALayers are rotated).  It adjusts the view's frame origin, together with its frame rotation angle, to achieve the requested rotation about the frame's center.
        [subview setFrameCenterRotation:-30.0 + drand48() * 60.0];
    }
}

@end

@implementation WrappedViewLayout

- (void)layoutSubviews:(NSArray *)arrangedSubviews ofView:(NSView *)view {
    NSRect container = NSInsetRect([view bounds], X_PADDING, Y_PADDING);
    NSPoint p = NSMakePoint(NSMinX(container), NSMaxY(container));
    NSPoint origin;
    CGFloat rowHeight = 0.0;
    for (NSView *subview in arrangedSubviews) {
        NSRect frame = [subview frame];
        if (p.x + frame.size.width > NSMaxX(container)) {
            p.x = NSMinX(container);
            p.y -= rowHeight + Y_PADDING;
            origin.x = p.x;
            origin.y = p.y - frame.size.height;
            p.x += frame.size.width + X_PADDING;
            rowHeight = frame.size.height;
        } else {
            origin.x = p.x;
            origin.y = p.y - frame.size.height;
            p.x += frame.size.width + X_PADDING;
            rowHeight = MAX(rowHeight, frame.size.height);
        }
 
        // Zero the view's frame rotation.
        [subview setFrameRotation:0.0];

        // Position the view.
        [subview setFrameOrigin:origin];
    }
}

@end

