/*
     File: DotView.m
 Abstract:  Simple NSView subclass showing how to draw, handle simple events, and target/action methods. This version also adds ability to undo all changes by simple use of NSUndoManager in the setters.
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

@synthesize color, radius, center;

// initWithFrame: is NSView's designated initializer (meaning it should be overridden in the
// subclassers if needed, and it should call super, that is NSView's implementation).  
// In DotView we do just that, and also set the instance variables.
//
// Note that we initialize the instance variables here in the same way they are
// initialized in the nib file. This is adequate, but a better solution is to make
// sure the two places are initialized from the same place. An even better approach is to
// simply use Cocoa Bindings, where the values are kept in sync automatically. For purposes
// of illustration and transparency (since this is a mod of the DotView example), we
// do not use bindings here.

static NSString *DotViewUndoAndRedisplay;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.center = NSMakePoint(50, 50);
        self.radius = 10.0;
        self.color = [NSColor redColor];
        [self addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionOld context:DotViewUndoAndRedisplay];
        [self addObserver:self forKeyPath:@"radius" options:NSKeyValueObservingOptionOld context:DotViewUndoAndRedisplay];
        [self addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionOld context:DotViewUndoAndRedisplay];
    }
    return self;
}

// dealloc is the method called when objects are being freed. (Note that "release"
// is called to release objects; when the number of release calls reduce the
// total reference count on an object to zero, dealloc is called to free
// the object.  dealloc should free any memory allocated by the subclass
// and then call super to get the superclass to do additional cleanup.

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"color" context:DotViewUndoAndRedisplay];
    [self removeObserver:self forKeyPath:@"radius" context:DotViewUndoAndRedisplay];
    [self removeObserver:self forKeyPath:@"center" context:DotViewUndoAndRedisplay];    
    self.color = nil;
    [super dealloc];
}

// drawRect: should be overridden in subclassers of NSView to do necessary
// drawing in order to recreate the the look of the view. It will be called
// to draw the whole view or parts of it (pay attention the rect argument);
// it will also be called during printing if your app is set up to print.
// In DotView we first clear the view to white, then draw the dot at its
// current location and size.

- (void)drawRect:(NSRect)rect {
    // Draw the background
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);

    // Draw the dot
    NSPoint c = self.center;
    CGFloat r = self.radius;
    NSRect dotRect = NSMakeRect(c.x - r, c.y - r, 2 * r, 2 * r);
    [self.color set];
    [[NSBezierPath bezierPathWithOvalInRect:dotRect] fill];
}

// Views which totally redraw their whole bounds without needing any of the
// views behind it should override isOpaque to return YES. This is a performance
// optimization hint for the display subsystem. This applies to DotView, whose
// drawRect: does fill the whole rect its given with a solid, opaque color.

- (BOOL)isOpaque {
    return YES;
}

// Rather than creating accessor methods for every single property we want react 
// to changes in, we observe them using KVO.

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == DotViewUndoAndRedisplay) {
        NSUndoManager *undoManager = [[self window] undoManager];
        if ([keyPath isEqual:@"center"]) [[undoManager prepareWithInvocationTarget:self] setCenter:[[change objectForKey:NSKeyValueChangeOldKey] pointValue]];
        else if ([keyPath isEqual:@"radius"]) [[undoManager prepareWithInvocationTarget:self] setRadius:[[change objectForKey:NSKeyValueChangeOldKey] doubleValue]];
        else if ([keyPath isEqual:@"color"]) [undoManager registerUndoWithTarget:self selector:@selector(setColor:) object:[change objectForKey:NSKeyValueChangeOldKey]];
	[self setNeedsDisplay:YES];
    }
}

// Recommended way to handle events is to override NSResponder (superclass
// of NSView) methods in the NSView subclass. One such method is mouseUp:.
// These methods get the event as the argument. The event has the mouse
// location in window coordinates; use convertPoint:fromView: (with "nil"
// as the view argument) to convert this point to local view coordinates.

- (void)mouseUp:(NSEvent *)event {
    NSPoint eventLocationInViewCoords = [self convertPoint:[event locationInWindow] fromView:nil];
    self.center = eventLocationInViewCoords;
}

// Target/action methods. In this version of DotView the action methods simply call the 
// setters. Using Cocoa Bindings would eliminate the need for these two methods.

- (void)changeSize:(id)sender {
    self.radius = [sender doubleValue];
}

- (void)changeColor:(id)sender {
    self.color = [sender color];
}

@end

