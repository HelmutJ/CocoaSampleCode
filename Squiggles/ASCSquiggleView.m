/*
     File: ASCSquiggleView.m
 Abstract: ASCSquiggleView is a subclass of NSView that supports custom drawing and event handling.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "ASCSquiggleView.h"
#import "ASCSquiggle.h"

@interface ASCSquiggleView()

@property NSMutableArray *squiggles;

@end


@implementation ASCSquiggleView

static CGFloat randomComponent(void) {
    return (CGFloat)(random() / (CGFloat)INT_MAX);
}

#pragma mark - Init Methods

// The designated initializer for NSView.
- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];

    if (self) {
        // Default view has one rotation.
        _rotations = 1;

        // Default view has no squiggles.
        _squiggles = [NSMutableArray array];
    }

    return self;
}

#pragma mark - Public Methods

// Removes all squiggles from the view.
- (void)removeAllSquiggles {
    
    [self.squiggles removeAllObjects];
    [self setNeedsDisplay:YES];
}


- (void)setRotations:(NSUInteger)rotations {
    /*
     Updates the number of rotations and redisplay if "rotations" is different than the current number of rotations.
     */    
    if (_rotations != rotations) {
        _rotations = rotations;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark - Drawing Methods

// The method invoked when it is time for an NSView to draw itself.
- (void)drawRect:(NSRect)rect {

    // Clear our current background and make it white.
    [[NSColor whiteColor] set];
    NSRectFill(rect);


    /*
      Create a coordinate transformation based on the value of the rotation slider (to be repeatedly applied below).
     */
    CGFloat widthOverTwo = self.bounds.size.width / 2.0;
    CGFloat heightOverTwo = self.bounds.size.height / 2.0;
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:widthOverTwo yBy:heightOverTwo];
    
    [transform rotateByDegrees:360.f / self.rotations];

    [transform translateXBy:-widthOverTwo yBy:-heightOverTwo];

	// For each rotation, draw the the full list of squiggles.
    for (NSUInteger idx = 0; idx < self.rotations; idx++) {

        [self.squiggles enumerateObjectsUsingBlock:^(ASCSquiggle *squiggle, NSUInteger squiggleIndex, BOOL *stop) {
            [squiggle draw];
        }];

        // Apply the transform to rotate in preparation for the next pass.
        [transform concat];
    }
}

#pragma mark - Mouse Event Methods

/*
 Override two of NSResponder's mouse handling methods to respond to the events we want.
 */

// Start drawing a new squiggle on mouse down.
- (void)mouseDown:(NSEvent *)event {

	// Convert from the window's coordinate system to this view's coordinates.
    NSPoint locationInView = [self convertPoint:event.locationInWindow fromView:nil];

    ASCSquiggle *newSquiggle = [[ASCSquiggle alloc] initWithInitialPoint:locationInView];
    
    CGFloat red     = randomComponent(),
            green   = randomComponent(),
            blue    = randomComponent(),
            alpha   = randomComponent() / 2.f + .5f;

    newSquiggle.color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];

    newSquiggle.thickness = 1 + 3.f * randomComponent();

    [self.squiggles addObject:newSquiggle];

    [self setNeedsDisplay:YES];
}

// Draw points on existing squiggle on mouse drag.
- (void)mouseDragged:(NSEvent *)event {
    
	// Convert from the window's coordinate system to this view's coordinates.
    NSPoint locationInView = [self convertPoint:event.locationInWindow
                                       fromView:nil];

    ASCSquiggle *currentSquiggle = [self.squiggles lastObject];

    [currentSquiggle addPoint:locationInView];

    [self setNeedsDisplay:YES];
}

#pragma mark - NSView display optimization

/*
 Opaque content drawing can allow some optimizations to happen. The default value is NO.
 */
- (BOOL)isOpaque {
	return YES;
}


@end
