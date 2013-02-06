/*
    File: ResizableView.m
Abstract: Implements a view with a resize box.  Resizing the view changes the size of the window if necessary.
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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/


#import "ResizableView.h"
#import "DragThumbView.h"
#import <AppKit/NSLayoutConstraint.h>

@implementation ResizableView

- (void)awakeFromNib {
    [dragThumbView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *views = NSDictionaryOfVariableBindings(dragThumbView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[dragThumbView(15)]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[dragThumbView(15)]|" options:0 metrics:nil views:views]];
    [super awakeFromNib];
}

- (void)drawRect:(NSRect)rect {
    [[NSColor whiteColor] set];
    NSRect bounds = [self bounds];
    NSRectFill(bounds);
    [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] set];
    NSFrameRect(bounds);
}

- (void)setOwnSizeConstraints:(NSArray *)newConstraints {
    if (sizeConstraints != newConstraints) {
        if (sizeConstraints) [self removeConstraints:sizeConstraints];
        [sizeConstraints release];
        sizeConstraints = [newConstraints retain];
        if (sizeConstraints) {
            [self addConstraints:sizeConstraints];
        }
    }
}

- (NSArray *)sizeConstraintsForCurrentPosition {
    NSMutableArray *constraints = [NSMutableArray array];
    NSSize size = [self bounds].size;
    NSDictionary *metrics = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:size.width], @"width", [NSNumber numberWithDouble:size.height], @"height", nil]; 
    NSDictionary *views = NSDictionaryOfVariableBindings(self);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[self(width@250)]" options:0 metrics:metrics views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(height@250)]" options:0 metrics:metrics views:views]];
    return constraints;
}

- (void)updateConstraints {
    if (!sizeConstraints) [self setOwnSizeConstraints:[self sizeConstraintsForCurrentPosition]];
    [super updateConstraints];
}

- (BOOL)isFlipped {
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint locationInSelf = [self convertPoint:[event locationInWindow] fromView:nil]; 
    NSRect dragThumbFrame = [dragThumbView frame];
    
    if (NSPointInRect(locationInSelf, dragThumbFrame)) {        
        dragOffsetIntoGrowBox = NSMakeSize(locationInSelf.x - dragThumbFrame.origin.x, locationInSelf.y - dragThumbFrame.origin.y);
        NSDictionary *metrics = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:NSMinX(dragThumbFrame)], @"initialThumbX", [NSNumber numberWithDouble:NSMinY(dragThumbFrame)], @"initialThumbY", nil]; 
        NSDictionary *views = NSDictionaryOfVariableBindings(dragThumbView);
        
        horizontalDragConstraint = [[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(initialThumbX)-[dragThumbView]" options:0 metrics:metrics views:views] lastObject] retain];
        verticalDragConstraint = [[[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(initialThumbY)-[dragThumbView]" options:0 metrics:metrics views:views] lastObject] retain];
        
        // try lowering the priority to NSLayoutPriorityDragThatCannotResizeWindow to see the difference
        [horizontalDragConstraint setPriority:NSLayoutPriorityDragThatCanResizeWindow];
        [verticalDragConstraint setPriority:NSLayoutPriorityDragThatCanResizeWindow];
        
        [self addConstraint:horizontalDragConstraint];
        [self addConstraint:verticalDragConstraint];
        
//        [[self window] visualizeConstraints:[NSArray arrayWithObjects:horizontalDragConstraint, verticalDragConstraint, nil]]; // just for fun.  Try it out!
    }
}


- (void)mouseDragged:(NSEvent *)theEvent {
    if (horizontalDragConstraint) {
        // update the dragging constraints for the new location
        NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        [horizontalDragConstraint setConstant:locationInSelf.x - dragOffsetIntoGrowBox.width];
        [verticalDragConstraint setConstant:locationInSelf.y - dragOffsetIntoGrowBox.height];
    } else {
        [super mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (horizontalDragConstraint) {
        
        [self removeConstraint:horizontalDragConstraint];
        [horizontalDragConstraint release];
        horizontalDragConstraint = nil;
        
        [self removeConstraint:verticalDragConstraint];
        [verticalDragConstraint release];
        verticalDragConstraint = nil;
        
        [self setOwnSizeConstraints:[self sizeConstraintsForCurrentPosition]];
        
//        [[self window] visualizeConstraints:nil]; // just for fun. Try it out!
    } else {
        [super mouseUp:theEvent];
    }
}

@end
