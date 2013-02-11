/*
    File: OverlayView.m
Abstract: The OverlayView class is a subclass of NSView which will be drawn on top of other views.

 Version: 1.0

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

#import "OverlayView.h"
#import "DimensionLineDrawing.h"

#define HIGHLIGHT_THICKNESS 3.0

@implementation OverlayView

@synthesize overlaidView;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // Create a tracking area that will give our view mouseMoved events.
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseMoved|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
        [trackingArea release];
    }
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES; // We want to be able to receive mouseMoved: events when we're the firstResponder view.
}

- (void)setSelectionHighlightNeedsDisplay {
    if (selectedView != nil) {
        NSView *superviewOfSelectedView = [selectedView superview];
        if (superviewOfSelectedView != nil) {

            // We could invalidate several rectangles that more tightly bound the area we actually need to redraw, if that proved to yield a worthwhile performance benefit, but since we're drawing dimension lines to all four edges of the selectedView's superview, we'll just invalidate the superview's bounds for simplicity.
            NSRect superviewRect = [self convertRect:[superviewOfSelectedView bounds] fromView:superviewOfSelectedView];    
            [self setNeedsDisplayInRect:superviewRect];

            // Make sure we'll also draw the entire box rectangle, in case half its stroke thickness exceeds the margin to the superview's bounds.
            NSRect boundingRect = NSInsetRect([self convertRect:[selectedView bounds] fromView:selectedView], -0.5 * HIGHLIGHT_THICKNESS, -0.5 * HIGHLIGHT_THICKNESS); // Outset by half of stroke width.
            [self setNeedsDisplayInRect:boundingRect];
        }
    }
}

- (NSView *)selectedView {
    return selectedView;
}

- (void)setSelectedView:(NSView *)newSelectedView {
    if (selectedView != newSelectedView) {

        // Schedule to erase highlight of previously selected view (if any).
        [self setSelectionHighlightNeedsDisplay];

        // Remember new selected view.
        [selectedView release];
        selectedView = [newSelectedView retain];

        // Schedule to draw highlight of newly selected view (if any).
        [self setSelectionHighlightNeedsDisplay];
    }
}

- (void)selectViewForEvent:(NSEvent *)theEvent {
    // Find out which view in the overlaid view this event would be associated with by using hitTest. Be sure to convert the point into the correct coordinate space.
    NSView *hitView = [overlaidView hitTest:[[overlaidView superview] convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (hitView) {
        // Choose the immediately enclosing NSBox instead, if the hitView is the NSBox's contentView, or the immediately enclosing NSScrollView, if the hitView is its documentView.
        NSView *parent = [hitView superview];
        if (parent && [parent isKindOfClass:[NSBox class]] && hitView == [(NSBox *)parent contentView]) {
            hitView = parent;
        } else {
            NSScrollView *enclosingScrollView = [hitView enclosingScrollView];
            if (enclosingScrollView && hitView == [enclosingScrollView documentView]) {
                hitView = enclosingScrollView;
            }
        }
    }
    [self setSelectedView:hitView];
}

- (void)drawRect:(NSRect)rect {
    // Fill with a mostly transparent tint color to make the presence of the OverlayView more obvious for demo purposes.  There's no other need to do this; you may draw whatever you like in an overlay view.
    [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.2] set];
    [NSBezierPath fillRect:rect];

    // Draw around/atop the selectedView to show the user that it's selected.
    if (selectedView != nil) {

        // Enforce cliping to the selectedView's superview's bounds.
        NSView *superviewOfSelectedView = [selectedView superview];
        NSRectClip([self convertRect:[superviewOfSelectedView bounds] fromView:superviewOfSelectedView]);

        NSRect selectionRect = [self convertRect:[selectedView bounds] fromView:selectedView];
        NSRect enclosingRect = [self convertRect:[superviewOfSelectedView bounds] fromView:superviewOfSelectedView];

        // Stroke a rect surrounding the view.
        [[NSColor redColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:selectionRect];
        [path setLineWidth:HIGHLIGHT_THICKNESS];
        [path stroke];

        // Draw dimension lines.
        DrawHorizontalDimensionLine(NSMinX(enclosingRect), NSMinX(selectionRect), NSMidY(selectionRect)); // -x line
        DrawHorizontalDimensionLine(NSMaxX(selectionRect), NSMaxX(enclosingRect), NSMidY(selectionRect)); // +x line
        DrawVerticalDimensionLine(NSMinY(enclosingRect), NSMinY(selectionRect), NSMidX(selectionRect)); // -y line
        DrawVerticalDimensionLine(NSMaxY(selectionRect), NSMaxY(enclosingRect), NSMidX(selectionRect)); // -y line
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    // Figure out which view (if any) was clicked, and select it.
    [self selectViewForEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent {
    // Figure out which view (if any) was clicked, and make sure it's selected.
    [self selectViewForEvent:theEvent];

    // Remember start point for drag.
    lastWindowPoint = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    // Let the user drag the selected view, if any.
    if (selectedView != nil) {

        // Calculate (dx,dy) for this mouse move, in the selected view's superview's coordinate space.
        NSView *superview = [selectedView superview];
        NSPoint windowPoint = [theEvent locationInWindow];
        NSPoint lastSuperviewPoint = [superview convertPoint:lastWindowPoint fromView:nil];
        NSPoint superviewPoint = [superview convertPoint:windowPoint fromView:nil];
        CGFloat dx = superviewPoint.x - lastSuperviewPoint.x;
        CGFloat dy = superviewPoint.y - lastSuperviewPoint.y;

        // Move view's frameOrigin by (dx,dy).
        NSRect frame = [selectedView frame];
        frame.origin.x += dx;
        frame.origin.y += dy;
        [self setSelectionHighlightNeedsDisplay]; // Schedule erase of selection highlight for old position.
        [selectedView setFrameOrigin:frame.origin];
        [self setSelectionHighlightNeedsDisplay]; // Schedule erase of selection highlight for new position.

        // Save windowPoint as the lastWindowPoint for the next drag increment.
        lastWindowPoint = windowPoint;
    }
}

- (void)dealloc {
    [selectedView release];
    [super dealloc];
}

@end
