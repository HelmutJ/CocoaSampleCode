/*
     File: DotView.m
 Abstract: Simple NSView subclass showing how to draw, handle simple events, and target/action methods.
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
#import "DotView.h"

@implementation DotView

// initWithFrame: is NSView's designated initializer (meaning it should be
// overridden in the subclassers if needed, and it should call super, that is
// NSView's implementation).  In DotView we do just that, and also set the
// instance variables.
//
// Note that we initialize the instance variables here in the same way they are
// initialized in the nib file. This is adequate, but a better solution is to make
// sure the two places are initialized from the same place. Slightly more
// sophisticated apps which load nibs for each document or window would initialize
// UI elements at the time they're loaded from values in the program.

- (id)initWithFrame:(NSRect)frame {
    if(self = [super initWithFrame:frame]) {
        center.x = 50.0;
        center.y = 50.0;
        radius = 10.0;
        color = [[NSColor redColor] retain];
    }
    return self;
}

// dealloc is the method called when objects are being freed. (Note that "release"
// is called to release objects; when the number of release calls reduce the
// total reference count on an object to zero, dealloc is called to free
// the object.  dealloc should free any memory allocated by the subclass
// and then call super to get the superclass to do additional cleanup.

- (void)dealloc {
    [color release];
    [super dealloc];
}

// drawRect: should be overridden in subclassers of NSView to do necessary
// drawing in order to recreate the the look of the view. It will be called
// to draw the whole view or parts of it (pay attention the rect argument);
// it will also be called during printing if your app is set up to print.
// In DotView we first clear the view to white, then draw the dot at its
// current location and size.

- (void)drawRect:(NSRect)rect {
    NSRect dotRect;

    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]

    dotRect.origin.x = center.x - radius;
    dotRect.origin.y = center.y - radius;
    dotRect.size.width  = 2 * radius;
    dotRect.size.height = 2 * radius;
    
    [color set];
    [[NSBezierPath bezierPathWithOvalInRect:dotRect] fill];
}

// Views which totally redraw their whole bounds without needing any of the
// views behind it should override isOpaque to return YES. This is a performance
// optimization hint for the display subsystem. This applies to DotView, whose
// drawRect: does fill the whole rect its given with a solid, opaque color.

- (BOOL)isOpaque {
    return YES;
}

// Recommended way to handle events is to override NSResponder (superclass
// of NSView) methods in the NSView subclass. One such method is mouseUp:.
// These methods get the event as the argument. The event has the mouse
// location in window coordinates; use convertPoint:fromView: (with "nil"
// as the view argument) to convert this point to local view coordinates.
//
// Note that once we get the new center, we call setNeedsDisplay:YES to 
// mark that the view needs to be redisplayed (which is done automatically
// by the AppKit).

- (void)mouseUp:(NSEvent *)event {
    NSPoint eventLocation = [event locationInWindow];
    center = [self convertPoint:eventLocation fromView:nil];
    [self setNeedsDisplay:YES];
}

// setRadius: is an action method which lets you change the radius of the dot.
// We assume the sender is a control capable of returning a floating point
// number; so we ask for it's value, and mark the view as needing to be 
// redisplayed. A possible optimization is to check to see if the old and
// new value is the same, and not do anything if so.

- (void)setRadius:(id)sender {
    radius = [sender doubleValue];
    [self setNeedsDisplay:YES];
}

// setColor: is an action method which lets you change the color of the dot.
// We assume the sender is a control capable of returning a color (NSColorWell
// can do this). We get the value, release the previous color, and mark the
// view as needing to be redisplayed. A possible optimization is to check to
// see if the old and new value is the same, and not do anything if so.
 
- (void)setColor:(id)sender {
    [color autorelease];
    color = [[sender color] retain];
    [self setNeedsDisplay:YES];
}

@end

