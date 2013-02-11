/*
    File: DimensionLineDrawing.m
Abstract: These functions are used to draw the lines from the edge of a selected view to the edge of the containing view.

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

#import "DimensionLineDrawing.h"

#define DIMENSION_LINE_THICKNESS                3.0
#define DIMENSION_LINE_ARROW_SIDE_LENGTH        8.0
#define DIMENSION_LINE_STROKE_COLOR             [NSColor redColor]
#define DIMENSION_LINE_LABEL_TEXT_COLOR         [NSColor redColor]
#define DIMENSION_LINE_LABEL_BACKGROUND_COLOR   [NSColor yellowColor]

static void DrawDimensionLineLabelAtCenterPoint(CGFloat dimension, NSPoint center) {
    NSString *labelString = [NSString stringWithFormat:@"%ld", (long)dimension];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]], NSFontAttributeName, DIMENSION_LINE_LABEL_TEXT_COLOR, NSForegroundColorAttributeName, DIMENSION_LINE_LABEL_BACKGROUND_COLOR, NSBackgroundColorAttributeName, nil];
    NSSize labelSize = [labelString sizeWithAttributes:attributes];
    NSRect labelRect = NSMakeRect(center.x - 0.5 * labelSize.width, center.y - 0.5 * labelSize.height, labelSize.width, labelSize.height);
    [labelString drawInRect:labelRect withAttributes:attributes];
}

void DrawHorizontalDimensionLine(CGFloat x1, CGFloat x2, CGFloat y) {

    // Stroke the line.
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:DIMENSION_LINE_THICKNESS];
    [path moveToPoint:NSMakePoint(x1, y)];
    [path lineToPoint:NSMakePoint(x2, y)];
    [DIMENSION_LINE_STROKE_COLOR set];

    // Stroke arrowheads (if line is long enough to bother).
    if (fabs(x2 - x1) >= 2.0 * DIMENSION_LINE_ARROW_SIDE_LENGTH) {

        // Stroke min end arrowhead.
        CGFloat minX = MIN(x1, x2);
        [path moveToPoint:NSMakePoint(minX + DIMENSION_LINE_ARROW_SIDE_LENGTH, y - DIMENSION_LINE_ARROW_SIDE_LENGTH)];
        [path lineToPoint:NSMakePoint(minX, y)];
        [path lineToPoint:NSMakePoint(minX + DIMENSION_LINE_ARROW_SIDE_LENGTH, y + DIMENSION_LINE_ARROW_SIDE_LENGTH)];        

        // Stroke max end arrowhead.
        CGFloat maxX = MAX(x1, x2);
        [path moveToPoint:NSMakePoint(maxX - DIMENSION_LINE_ARROW_SIDE_LENGTH, y - DIMENSION_LINE_ARROW_SIDE_LENGTH)];
        [path lineToPoint:NSMakePoint(maxX, y)];
        [path lineToPoint:NSMakePoint(maxX - DIMENSION_LINE_ARROW_SIDE_LENGTH, y + DIMENSION_LINE_ARROW_SIDE_LENGTH)];        
    }    
    [path stroke];

    // Draw a text box showing the dimension.
    DrawDimensionLineLabelAtCenterPoint(fabs(x2 - x1), NSMakePoint(0.5 * (x1 + x2), y));
}

void DrawVerticalDimensionLine(CGFloat y1, CGFloat y2, CGFloat x) {

    // Stroke the line.
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:DIMENSION_LINE_THICKNESS];
    [path moveToPoint:NSMakePoint(x, y1)];
    [path lineToPoint:NSMakePoint(x, y2)];
    [DIMENSION_LINE_STROKE_COLOR set];

    // Stroke arrowheads (if line is long enough to bother).
    if (fabs(y2 - y1) >= 2.0 * DIMENSION_LINE_ARROW_SIDE_LENGTH) {

        // Stroke min end arrowhead.
        CGFloat minY = MIN(y1, y2);
        [path moveToPoint:NSMakePoint(x - DIMENSION_LINE_ARROW_SIDE_LENGTH, minY + DIMENSION_LINE_ARROW_SIDE_LENGTH)];
        [path lineToPoint:NSMakePoint(x, minY)];
        [path lineToPoint:NSMakePoint(x + DIMENSION_LINE_ARROW_SIDE_LENGTH, minY + DIMENSION_LINE_ARROW_SIDE_LENGTH)];

        // Stroke max end arrowhead.
        CGFloat maxY = MAX(y1, y2);
        [path moveToPoint:NSMakePoint(x - DIMENSION_LINE_ARROW_SIDE_LENGTH, maxY - DIMENSION_LINE_ARROW_SIDE_LENGTH)];
        [path lineToPoint:NSMakePoint(x, maxY)];
        [path lineToPoint:NSMakePoint(x + DIMENSION_LINE_ARROW_SIDE_LENGTH, maxY - DIMENSION_LINE_ARROW_SIDE_LENGTH)];
    }    
    [path stroke];

    // Draw a text box showing the dimension.
    DrawDimensionLineLabelAtCenterPoint(fabs(y2 - y1), NSMakePoint(x, 0.5 * (y1 + y2)));
}
