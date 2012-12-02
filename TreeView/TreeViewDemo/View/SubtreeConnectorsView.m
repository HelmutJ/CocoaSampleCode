/*
    File: SubtreeConnectorsView.m
Abstract: SubtreeConnectorsView Implementation
 Version: 1.3

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

#import "SubtreeConnectorsView.h"
#import "SubtreeView.h"
#import "TreeView.h"

@implementation SubtreeConnectorsView

- (TreeView *)enclosingTreeView {
    NSView *ancestor = [self superview];
    while (ancestor) {
        if ([ancestor isKindOfClass:[TreeView class]]) {
            return (TreeView *)ancestor;
        }
        ancestor = [ancestor superview];
    }
    return nil;
}

- (NSBezierPath *)directConnectionsPath {
    NSRect bounds = [self bounds];
    NSPoint rootPoint = NSMakePoint(NSMinX(bounds), NSMidY(bounds));
    
    // Create a single bezier path that we'll use to stroke all the lines.
    NSBezierPath *path = [NSBezierPath bezierPath];

    // Add a stroke from rootPoint to each child SubtreeView of our containing SubtreeView.
    NSView *subtreeView = [self superview];
    if ([subtreeView isKindOfClass:[SubtreeView class]]) {

        for (NSView *subview in [subtreeView subviews]) {
            if ([subview isKindOfClass:[SubtreeView class]]) {
                NSRect subviewBounds = [subview bounds];
                NSPoint targetPoint = [self convertPoint:NSMakePoint(NSMinX(subviewBounds), NSMidY(subviewBounds)) fromView:subview];

                [path moveToPoint:rootPoint];
                [path lineToPoint:targetPoint];
            }
        }
    }

    // Return the path.
    return path;
}

- (NSBezierPath *)orthogonalConnectionsPath {
    // Compute the needed adjustment in x and y to align our lines for crisp, exact pixel coverage.  (We can only do this if the lineWidth is integral, which it usually is.)
    CGFloat adjustment = 0.0;
    CGFloat lineWidth = [[self enclosingTreeView] connectingLineWidth];
    NSSize lineSize = NSMakeSize(lineWidth, lineWidth);
    NSSize lineSizeInPixels = [self convertSizeToBase:lineSize];
    CGFloat halfLineWidthInPixels = 0.5 * lineSizeInPixels.width;
    if (fabs(halfLineWidthInPixels - floor(halfLineWidthInPixels)) > 0.0001) {
        // If line width in pixels is odd, lay our path segments along the centers of pixel rows.
        NSSize adjustmentAsSizeInPixels = NSMakeSize(0.5, 0.5);
        NSSize adjustmentAsSize = [self convertSizeFromBase:adjustmentAsSizeInPixels];
        adjustment = adjustmentAsSize.width;
    }

    NSRect bounds = [self bounds];
    NSPoint basePoint;

    // Compute point at right edge of root node, from which its connecting line to the vertical line will emerge.
    NSPoint rootPoint = NSMakePoint(NSMinX(bounds), NSMidY(bounds));

    // Align the line to get exact pixel coverage, for sharper rendering.
    basePoint = [self convertPointToBase:rootPoint];
    basePoint.x = round(basePoint.x) + adjustment;
    basePoint.y = round(basePoint.y) + adjustment;
    rootPoint = [self convertPointFromBase:basePoint];

    // Compute point (really, we're just interested in the x value) at which line from root node intersects the vertical connecting line.
    NSPoint rootIntersection = NSMakePoint(NSMidX(bounds), NSMidY(bounds));

    // Align the line to get exact pixel coverage, for sharper rendering.
    basePoint = [self convertPointToBase:rootIntersection];
    basePoint.x = round(basePoint.x) + adjustment;
    basePoint.y = round(basePoint.y) + adjustment;
    rootIntersection = [self convertPointFromBase:basePoint];

    // Create a single bezier path that we'll use to stroke all the lines.
    NSBezierPath *path = [NSBezierPath bezierPath];

    // Add a stroke from each child SubtreeView to where we'll put the vertical connecting line.  And while we're iterating over SubtreeViews, make a note of the minimum and maximum Y we'll want for the endpoints of the vertical connecting line.
    CGFloat minY = rootPoint.y;
    CGFloat maxY = rootPoint.y;
    NSView *subtreeView = [self superview];
    NSInteger subtreeViewCount = 0;
    if ([subtreeView isKindOfClass:[SubtreeView class]]) {

        for (NSView *subview in [subtreeView subviews]) {
            if ([subview isKindOfClass:[SubtreeView class]]) {
                ++subtreeViewCount;

                NSRect subviewBounds = [subview bounds];
                NSPoint targetPoint = [self convertPoint:NSMakePoint(NSMinX(subviewBounds), NSMidY(subviewBounds)) fromView:subview];

                // Align the line to get exact pixel coverage, for sharper rendering.
                basePoint = [self convertPointToBase:targetPoint];
                basePoint.x = round(basePoint.x) + adjustment;
                basePoint.y = round(basePoint.y) + adjustment;
                targetPoint = [self convertPointFromBase:basePoint];

                // TODO: Make clean line joins (test at high values of line thickness to see the problem).
                [path moveToPoint:NSMakePoint(rootIntersection.x, targetPoint.y)];
                [path lineToPoint:targetPoint];

                if (minY > targetPoint.y) {
                    minY = targetPoint.y;
                }
                if (maxY < targetPoint.y) {
                    maxY = targetPoint.y;
                }
            }
        }
    }

    if (subtreeViewCount) {
        // Add a stroke from rootPoint to where we'll put the vertical connecting line.
        [path moveToPoint:rootPoint];
        [path lineToPoint:rootIntersection];

        // Add a stroke for the vertical connecting line.
        [path moveToPoint:NSMakePoint(rootIntersection.x, minY)];
        [path lineToPoint:NSMakePoint(rootIntersection.x, maxY)];
    }

    // Return the path.
    return path;
}

- (void)drawRect:(NSRect)dirtyRect {

    // Build the set of lines to stroke, according to our enclosingTreeView's connectingLineStyle.
    NSBezierPath *path = nil;
    switch ([[self enclosingTreeView] connectingLineStyle]) {
        case TreeViewConnectingLineStyleDirect:
        default:
            path = [self directConnectionsPath];
            break;

        case TreeViewConnectingLineStyleOrthogonal:
            path = [self orthogonalConnectionsPath];
            break;
    }

    // Stroke the path with the appropriate color and line width.
    TreeView *treeView = [self enclosingTreeView];
    [[treeView connectingLineColor] set];
    [path setLineWidth:[treeView connectingLineWidth]];
    [path stroke];
}

@end
