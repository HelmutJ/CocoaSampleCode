/*

File: MainController.m

Abstract: Main Controller Class for the LayerBackedOpenGLView Example

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Inc.,
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

Copyright © 2007 Apple Inc., All Rights Reserved

*/

#import "MainController.h"
#import "MyOpenGLView.h"
#import "Scene.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>

@interface MainController (RotationMethods)
- (BOOL)isRotating;
- (void)startRotation;
- (void)stopRotation;
- (void)toggleRotation;

- (void)startRotationTimer;
- (void)stopRotationTimer;
- (void)rotationTimerFired:(NSTimer *)timer;
@end

@implementation MainController

- (void) awakeFromNib {
    // Set up some visual properties of our controlBox that aren't yet settable in Interface Builder in the WWDC beta.
    [controlBox setBoxType:NSBoxCustom];
    [controlBox setCornerRadius:12.0];

    // Start the Earth rotating.
    [self startRotation];
}

#pragma mark *** Action Methods ***

- (void)showControlBox:(id)sender {
    if ([controlBox superview] != openGLView) {
        // Determine desired start and end positions for animating the controlBox into view.
        NSRect bounds = [openGLView bounds];
        NSPoint endOrigin = NSMakePoint(0.5 * (NSWidth(bounds) - NSWidth([controlBox frame])), 24.0);
        NSPoint startOrigin = NSMakePoint(endOrigin.x, -NSHeight([controlBox frame]));

        // Position the controlBox outside the openGLView's bounds, and make it initially fully transparent.
        [controlBox setFrameOrigin:startOrigin];
        [openGLView addSubview:controlBox];
        [controlBox setAlphaValue:0.0];

        // Now animate the controlBox into view and simultaneously fade it in.
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.5];
        [[controlBox animator] setAlphaValue:1.0];
        [[controlBox animator] setFrameOrigin:endOrigin];
        [NSAnimationContext endGrouping];
    }
}

- (void)hideControlBox:(id)sender {
    if ([controlBox superview] == openGLView) {
        // Remove the controlBox from the view tree.
        [controlBox removeFromSuperview];
    }
}

#pragma mark *** Property Accessors ***

- (BOOL)isLayerBacked {
    return layerBacked;
}

- (void)setLayerBacked:(BOOL)flag {
    if (flag != layerBacked) {
        layerBacked = flag;
        [openGLView setWantsLayer:flag];
        if (flag) {
            // Bring controlBox in on a slight delay, to give its backing layer tree a chance to animate into view.
            [self performSelector:@selector(showControlBox:) withObject:self afterDelay:0.1];
        } else {
            [self hideControlBox:self];
        }
    }
}

- (BOOL)isFiltered {
    return filter != nil;
}

- (void)setFiltered:(BOOL)flag {
    if (flag != [self isFiltered]) {
        if (flag) {
            // Instantiate a Core Image "Glass Distortion" filter.
            filter = [CIFilter filterWithName:@"CIGlassDistortion"];
            [filter setDefaults];
            CIImage *glassImage = [CIImage imageWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"smoothtexture"]]];
            [filter setValue:glassImage forKey:@"inputTexture"];

            // Apply the glass distortion to filter the openGLView content that's rendered behind the controlBox.
            [[controlBox animator] setBackgroundFilters:[NSArray arrayWithObject:filter]];
        } else {
            // Remove the filter and discard our pointer to it.
            [[controlBox animator] setBackgroundFilters:nil];
            filter = nil;
        }
    }
}

#pragma mark *** Event Handling ***

- (void)keyDown:(NSEvent *)event {
    Scene *scene = [openGLView scene];
    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch (c) {

        // [space] toggles rotation of the globe.
        case 32:
            [self toggleRotation];
            break;

        // [W] toggles wireframe rendering
        case 'w':
        case 'W':
            [scene toggleWireframe];
            [openGLView setNeedsDisplay:YES];
            break;

        default:
            break;
    }
}

// Holding the mouse button and dragging the mouse changes the "roll" angle (y-axis) and the direction from which sunlight is coming (x-axis).
- (void)mouseDown:(NSEvent *)theEvent {
    Scene *scene = [openGLView scene];
    BOOL wasAnimating = [self isRotating];
    BOOL dragging = YES;
    NSPoint windowPoint;
    NSPoint lastWindowPoint = [theEvent locationInWindow];
    float dx, dy;

    if (wasAnimating) {
        [self stopRotation];
    }
    while (dragging) {
        theEvent = [[openGLView window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        windowPoint = [theEvent locationInWindow];
        switch ([theEvent type]) {
            case NSLeftMouseUp:
                dragging = NO;
                break;

            case NSLeftMouseDragged:
                dx = windowPoint.x - lastWindowPoint.x;
                dy = windowPoint.y - lastWindowPoint.y;
                [scene setSunAngle:[scene sunAngle] - 1.0 * dx];
                [scene setRollAngle:[scene rollAngle] - 0.5 * dy];
                lastWindowPoint = windowPoint;

                // Render a frame.
                [openGLView setNeedsDisplay:YES];
                break;

            default:
                break;
        }
    }
    if (wasAnimating) {
        [self startRotation];
        timeBefore = CFAbsoluteTimeGetCurrent();
    }
}

@end

@implementation MainController (RotationMethods)

- (BOOL)isRotating {
    return isRotating;
}

- (void)startRotation {
    if (!isRotating) {
        isRotating = YES;
        [self startRotationTimer];
    }
}

- (void)stopRotation {
    if (isRotating) {
        if (rotationTimer != nil) {
            [self stopRotationTimer];
        }
        isRotating = NO;
    }
}

- (void)toggleRotation {
    if ([self isRotating]) {
        [self stopRotation];
    } else {
        [self startRotation];
    }
}

- (void)startRotationTimer {
    if (rotationTimer == nil) {
        rotationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.017 target:self selector:@selector(rotationTimerFired:) userInfo:nil repeats:YES] retain];
    }
}

- (void)stopRotationTimer {
    if (rotationTimer != nil) {
        [rotationTimer invalidate];
        [rotationTimer release];
        rotationTimer = nil;
    }
}

- (void)rotationTimerFired:(NSTimer *)timer {
    Scene *scene = [openGLView scene];
    [scene advanceTimeBy:0.017];
    [openGLView setNeedsDisplay:YES];
}

@end
