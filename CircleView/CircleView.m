/*
     File: CircleView.m
 Abstract: NSView subclass showing the use of the text system for drawing glyphs.
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

#import <Cocoa/Cocoa.h>
#import "CircleView.h"

@implementation CircleView

// Many of the methods here are similar to those in the simpler DotView example.
// See that example for detailed explanations; here we will discuss those
// features that are unique to CircleView. 

// CircleView draws text around a circle, using Cocoa's text system for
// glyph generation and layout, then calculating the positions of glyphs
// based on that layout, and using NSLayoutManager for drawing.

- (id)initWithFrame:(NSRect)frame {
    if(self = [super initWithFrame:frame])  {
        // First, we set default values for the various parameters.
        center.x = frame.size.width / 2;
        center.y = frame.size.height / 2;
        radius = 115.0;
        startingAngle = M_PI_2;
        angularVelocity = M_PI_2;
        
        // Next, we create and initialize instances of the three 
        // basic non-view components of the text system:
        // an NSTextStorage, an NSLayoutManager, and an NSTextContainer.
        textStorage = [[NSTextStorage alloc] initWithString:@"Here's to the crazy ones, the misfits, the rebels, the troublemakers, the round pegs in the square holes, the ones who see things differently."];
        layoutManager = [[NSLayoutManager alloc] init];
        textContainer = [[NSTextContainer alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textContainer release];	// The layoutManager will retain the textContainer
        [textStorage addLayoutManager:layoutManager];
        [layoutManager release];	// The textStorage will retain the layoutManager
        
        // Screen fonts are not suitable for scaled or rotated drawing.
        // Views that use NSLayoutManager directly for text drawing should
        // set this parameter appropriately.
        [layoutManager setUsesScreenFonts:NO];
    }
    return self;
}

- (void)dealloc {
    [timer invalidate];
    [timer release];
    [textStorage release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    NSUInteger glyphIndex;
    NSRange glyphRange;
    NSRect usedRect;
     
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);

    // Note that usedRectForTextContainer: does not force layout, so it must 
    // be called after glyphRangeForTextContainer:, which does force layout.
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    usedRect = [layoutManager usedRectForTextContainer:textContainer];

    for (glyphIndex = glyphRange.location; glyphIndex < NSMaxRange(glyphRange); glyphIndex++) {
        NSGraphicsContext *context = [NSGraphicsContext currentContext];
	NSRect lineFragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
	NSPoint viewLocation, layoutLocation = [layoutManager locationForGlyphAtIndex:glyphIndex];
        CGFloat angle, distance;
        NSAffineTransform *transform = [NSAffineTransform transform];
    
        // Here layoutLocation is the location (in container coordinates) where the glyph was laid out. 
        layoutLocation.x += lineFragmentRect.origin.x;
        layoutLocation.y += lineFragmentRect.origin.y;

        // We then use the layoutLocation to calculate an appropriate position for the glyph 
        // around the circle (by angle and distance, or viewLocation in rectangular coordinates).
        distance = radius + usedRect.size.height - layoutLocation.y;
        angle = startingAngle + layoutLocation.x / distance;

        viewLocation.x = center.x + distance * sin(angle);
        viewLocation.y = center.y + distance * cos(angle);
        
        // We use a different affine transform for each glyph, to position and rotate it
        // based on its calculated position around the circle.  
        [transform translateXBy:viewLocation.x yBy:viewLocation.y];
        [transform rotateByRadians:-angle];

        // We save and restore the graphics state so that the transform applies only to this glyph.
        [context saveGraphicsState];
        [transform concat];
        // drawGlyphsForGlyphRange: draws the glyph at its laid-out location in container coordinates.
        // Since we are using the transform to place the glyph, we subtract the laid-out location here.
        [layoutManager drawGlyphsForGlyphRange:NSMakeRange(glyphIndex, 1) atPoint:NSMakePoint(-layoutLocation.x, -layoutLocation.y)];
        [context restoreGraphicsState];
    }
}

- (BOOL)isOpaque {
    return YES;
}

// DotView changes location on mouse up, but here we choose to do so
// on mouse down and mouse drags, so the text will follow the mouse.

- (void)mouseDown:(NSEvent *)event {
    NSPoint eventLocation = [event locationInWindow];
    center = [self convertPoint:eventLocation fromView:nil];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint eventLocation = [event locationInWindow];
    center = [self convertPoint:eventLocation fromView:nil];
    [self setNeedsDisplay:YES];
}

// DotView uses action methods to set its parameters.  Here we have
// factored each of those into a method to set each parameter directly
// and a separate action method.

- (void)setColor:(NSColor *)color {
    // Text drawing uses the attributes set on the text storage rather
    // than drawing context attributes like the current color.
    [textStorage addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [textStorage length])];
    [self setNeedsDisplay:YES];
}

- (void)setRadius:(CGFloat)distance {
    radius = distance;
    [self setNeedsDisplay:YES];
}

- (void)setStartingAngle:(CGFloat)angle {
    startingAngle = angle;
    [self setNeedsDisplay:YES];
}
    
- (void)setAngularVelocity:(CGFloat)velocity {
    angularVelocity = velocity;
    [self setNeedsDisplay:YES];
}
    
- (void)setString:(NSString *)string {
    [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:string];
    [self setNeedsDisplay:YES];
}

- (IBAction)takeColorFrom:(id)sender {
    [self setColor:[sender color]];
}

- (IBAction)takeRadiusFrom:(id)sender {
    [self setRadius:[sender doubleValue]];
}

- (IBAction)takeStartingAngleFrom:(id)sender {
    [self setStartingAngle:[sender doubleValue]];
}

- (IBAction)takeAngularVelocityFrom:(id)sender {
    [self setAngularVelocity:[sender doubleValue]];
}

- (IBAction)takeStringFrom:(id)sender {
    [self setString:[sender stringValue]];
}

- (IBAction)startAnimation:(id)sender {
    [self stopAnimation:sender];
    
    // We schedule a timer for a desired 30fps animation rate.
    // In performAnimation: we determine exactly
    // how much time has elapsed and animate accordingly.
    timer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/30.0) target:self selector:@selector(performAnimation:) userInfo:nil repeats:YES] retain];
    
    // The next two lines make sure that animation will continue to occur
    // while modal panels are displayed and while event tracking is taking
    // place (for example, while a slider is being dragged).
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
    
    lastTime = [NSDate timeIntervalSinceReferenceDate];
}

- (IBAction)stopAnimation:(id)sender {
    [timer invalidate];
    [timer release];
    timer = nil;
}

- (IBAction)toggleAnimation:(id)sender {
    if (timer != nil) {
        [self stopAnimation:sender];
    } else {
        [self startAnimation:sender];
    }
}

- (void)performAnimation:(NSTimer *)aTimer {
    // We determine how much time has elapsed since the last animation,
    // and we advance the angle accordingly.
    NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate];
    [self setStartingAngle:startingAngle + angularVelocity * (thisTime - lastTime)];
    lastTime = thisTime;
}

@end

