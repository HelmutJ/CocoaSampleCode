/*
    File: SplitView.m
Abstract: An NSSplitView-like class.  Demonstrates layout from a view's perspective, dragging, and priorities.
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

#import "SplitView.h"
#import <AppKit/NSLayoutConstraint.h>

@interface SplitView ()
@property (retain) NSArray *viewStackConstraints;
@property (retain) NSArray *heightConstraints;
@end

@implementation SplitView

@synthesize viewStackConstraints=_viewStackConstraints, heightConstraints=_heightConstraints;

- (void) dealloc
{
    [_heightConstraints release];
    [_viewStackConstraints release];
    [_draggingConstraint release];
    
    [super dealloc];
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (CGFloat)dividerThickness {
    return 9;
}

#pragma mark View Stack

// set up constraints to lay out subviews in a vertical stack with space between each consecutive pair.  This doesn't specify the heights of views, just that they're stacked up head to tail.
- (void)updateViewStackConstraints {
    if (!self.viewStackConstraints) {
        NSMutableArray *stackConstraints = [NSMutableArray array];
        NSDictionary *metrics = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:[self dividerThickness]], @"dividerThickness", nil];
        NSMutableDictionary *viewsDict = [NSMutableDictionary dictionary];
        
        // iterate over our subviews from top to bottom
        NSView *previousView = nil;
        for (NSView *currentView in [self subviews]) {
            [viewsDict setObject:currentView forKey:@"currentView"];
            
            if (!previousView) {
                // tie topmost view to the top of the container
                [stackConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[currentView]" options:0 metrics:metrics views:viewsDict]];
            } else {
                // tie current view to the next one higher up
                [viewsDict setObject:previousView forKey:@"previousView"];
                [stackConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previousView]-dividerThickness-[currentView]" options:0 metrics:metrics views:viewsDict]];
            }

            // each view should fill the splitview horizontally
            [stackConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[currentView]|" options:0 metrics:metrics views:viewsDict]];
            
            previousView = currentView;
        }
        
        // tie the bottom view to the bottom of the splitview
        if ([[self subviews] count] > 0) [stackConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[currentView]|" options:0 metrics:metrics views:viewsDict]];
        
        [self setViewStackConstraints:stackConstraints];
    }
}

// passing nil marks us as needing to update the stack constraints 
- (void)setViewStackConstraints:(NSArray *)stackConstraints {
    if (_viewStackConstraints != stackConstraints) {
        if (_viewStackConstraints) [self removeConstraints:_viewStackConstraints];
        [_viewStackConstraints release];
        _viewStackConstraints = [stackConstraints retain];
        
        if (_viewStackConstraints) {
            [self addConstraints:_viewStackConstraints];
        } else {
            [self setNeedsUpdateConstraints:YES];
        }
    }
}

// need to recompute the view stack when we gain or lose a subview
- (void)didAddSubview:(NSView *)subview {
    [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setViewStackConstraints:nil];
    [super didAddSubview:subview];
}
- (void)willRemoveSubview:(NSView *)subview {
    [self setViewStackConstraints:nil];
    [super willRemoveSubview:subview];
}

#pragma mark View Heights 

- (void)setHeightConstraints:(NSArray *)heightConstraints {
    if (_heightConstraints != heightConstraints) {
        if (_heightConstraints) [self removeConstraints:_heightConstraints];
        [_heightConstraints release];
        _heightConstraints = [heightConstraints retain];
        if (_heightConstraints) {
            [self addConstraints:_heightConstraints];
        } else {
            [self setNeedsUpdateConstraints:YES];
        }
    }
}

int DistanceOfViewWithIndexFromDividerWithIndex(int viewIndex, int dividerIndex) {
    return ABS(viewIndex - (dividerIndex + 0.5)) - 0.5;
}

/* make constraints specifying that each view wants its height to be the current percentage of the total space available
 
 The priorities are not all equal, though. The views closest to the dividerIndex maintain height with the lowest priority, and priority increases as we move away from the divider.
 
 Thus, the views closest to the divider are affected by divider dragging first.
 
 -1 for dividerIndex means that no divider is being dragged and all the height constraints should have the same priority. 
 */
- (NSArray *)constraintsForHeightsWithPrioritiesLowestAroundDivider:(int)dividerIndex {
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *views = [self subviews];
    NSInteger numberOfViews = [views count];
    
    CGFloat spaceForAllDividers = [self dividerThickness] * (numberOfViews - 1);
    CGFloat spaceForAllViews = NSHeight([self bounds]) - spaceForAllDividers;
    CGFloat priorityIncrement = 1.0 / numberOfViews;
    
    for (int i = 0; i < numberOfViews; i++) {
        NSView *currentView = [views objectAtIndex:i];
        CGFloat percentOfTotalHeight = NSHeight([currentView frame])/spaceForAllViews;

        // currentView.height == (self.height - spaceForAllDividers) * percentOfTotalHeight
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:currentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:percentOfTotalHeight constant:-spaceForAllDividers * percentOfTotalHeight];
        
        if (dividerIndex == -2) {
            [heightConstraint setPriority:NSLayoutPriorityDefaultLow];                        
        } else {
            [heightConstraint setPriority:NSLayoutPriorityDefaultLow + priorityIncrement*DistanceOfViewWithIndexFromDividerWithIndex(i, dividerIndex)];                        
        }
        
        [constraints addObject:heightConstraint];
    }
    
    return constraints;
}

- (void)updateHeightConstraints {
    if (!self.heightConstraints) self.heightConstraints = [self constraintsForHeightsWithPrioritiesLowestAroundDivider:-2];
}

#pragma mark Update Layout Constraints Override 

- (void)updateConstraints {
    [super updateConstraints];
    [self updateViewStackConstraints];
    [self updateHeightConstraints];
}

#pragma mark Divider Dragging 

- (int)dividerIndexForPoint:(NSPoint)point {
    __block int dividerIndex = -1;
    [[self subviews] enumerateObjectsUsingBlock:^(id subview, NSUInteger i, BOOL *stop) {
        NSRect subviewFrame = [subview frame];
        if (point.y > NSMaxY([subview frame])) {
            // the point is between us and the subview above
            dividerIndex = i - 1;
            *stop = YES; 
        } else if (point.y > NSMinY(subviewFrame)) {
            // the point is in the interior of our view, not on a divider
            dividerIndex = -1;
            *stop = YES;
        }
    }];
    return dividerIndex;
}

-(void)mouseDown:(NSEvent *)theEvent {
    NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int dividerIndex = [self dividerIndexForPoint:locationInSelf];
    
    if (dividerIndex != -1) {
        // First we lock the heights in place for the given dividerIndex
        self.heightConstraints = [self constraintsForHeightsWithPrioritiesLowestAroundDivider:dividerIndex];
        
        // Now we add a constraint that forces the bottom edge of the view above the divider to align with the mouse location
        NSView *viewAboveDivider = [[self subviews] objectAtIndex:dividerIndex];
        _draggingConstraint = [[[NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewAboveDivider]-100-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewAboveDivider)] lastObject] retain];
        [_draggingConstraint setPriority:NSLayoutPriorityDragThatCannotResizeWindow];
        _draggingConstraint.constant = locationInSelf.y;
        
        [self addConstraint:_draggingConstraint];
    } else {
        [super mouseDown:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (_draggingConstraint) {
        // update the dragging constraint for the new location
        NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [_draggingConstraint setConstant:locationInSelf.y];
    } else {
        [super mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (_draggingConstraint) {
        [self removeConstraint:_draggingConstraint];
        [_draggingConstraint release];
        _draggingConstraint = nil;
        
        // We lock the current heights in place
        self.heightConstraints = [self constraintsForHeightsWithPrioritiesLowestAroundDivider:-2];
    } else {
        [super mouseUp:theEvent];
    }
}

#pragma mark Drawing 

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blackColor] set];
    NSRectFill(dirtyRect);
}

@end
