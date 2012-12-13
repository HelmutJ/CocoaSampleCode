/* 
     File: BezierView.m 
 Abstract: BezierView implements a view with a single bezier path.  The path is created 
 using various constructs to demonstrate some different methods of creating bezier
 paths.  The color of the background and path element can be customized. In addition, 
 the line and cap style can be selected.  An example of the -setLineDash:count:phase: 
 method is included.   
 
 The application also includes a zoom feature that can be used to better view the 
 different line and fill styles. 
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

#import "BezierView.h"
#import <AppKit/NSGraphicsContext.h>

@implementation BezierView

// After the application loads the nib file, the default values need to be set.

- (void)awakeFromNib {
    [self setLineColor:[lineColorWell color]];
    [self setFillColor:[fillColorWell color]];
    [self setBackgroundColor:[backgroundColorWell color]];
    [self setLineWidth:[lineWidthSlider doubleValue]];
    [self setPathType:pathTypeMatrix];
    [self setFilled:filledBox];
    [self setAngle:[angleSlider doubleValue]];
    [self setZoom:[zoomSlider doubleValue]];
    [self setCapStyle: ButtLine];
    [self changeLineType:lineTypeMatrix];
}

// The dealloc method frees the view, colors, and path.

- (void)dealloc {
    [lineColor release];
    [fillColor release];
    [backgroundColor release];
    [path release];
    [super dealloc];
}

// Accessor methods.

- (void)setLineColor:(NSColor *)newColor {
    if (lineColor != newColor) {
        [lineColor release];
        lineColor = [newColor copyWithZone:[self zone]];
    }
}
    
- (void)setFillColor:(NSColor *)newColor {
    if (fillColor != newColor) {
        [fillColor release];
        fillColor = [newColor copyWithZone:[self zone]];
    }
}

- (void)setBackgroundColor:(NSColor *)newColor {
    if (backgroundColor != newColor) {
        [backgroundColor release];
        backgroundColor = [newColor copyWithZone:[self zone]];
    }
}

- (void)setPath:(NSBezierPath *)newPath {
    if (path != newPath) {
        [path release];
        path = [newPath copyWithZone:[self zone]];
    }
}
- (void)setLineWidth:(CGFloat)newWidth {
    lineWidth = floor(newWidth);
}
- (void)setAngle:(CGFloat)newAngle {
    angle = newAngle;
}

// This method scales the view by the given scaleFactor.

- (void)setZoom:(CGFloat)scaleFactor {
    NSRect frame = [self frame];
    NSRect bounds = [self bounds];
    frame.size.width = bounds.size.width * scaleFactor;
    frame.size.height = bounds.size.height * scaleFactor;
    [self setFrameSize: frame.size];    // Change the view's size.
    [self setBoundsSize: bounds.size];  // Restore the view's bounds, which causes the view to be scaled.
}

// Actions performed by the controls.
 
- (void)changeLineColor:(id)sender {
    [self setLineColor:[sender color]];
    [self setNeedsDisplay:YES];
}
- (void)changeFillColor:(id)sender {
    [self setFillColor:[sender color]];
    [self setNeedsDisplay:YES];
}
- (void)changeBackgroundColor:(id)sender {
    [self setBackgroundColor:[sender color]];
    [self setNeedsDisplay:YES];
}
- (void)changeLineWidth:(id)sender {
    [self setLineWidth:[sender doubleValue]];
    [self setNeedsDisplay:YES];
}
- (void)setPathType:(id)sender {
    pathType = [sender selectedTag];
    [self setNeedsDisplay:YES];
}
- (void)setFilled:(id)sender {
    filled = [sender state];
    [self setNeedsDisplay:YES];
}
- (void)changeAngleSlider:(id)sender {
    [self setAngle:[sender doubleValue]];
    [self setNeedsDisplay:YES];
}

- (void)setCapStyle:(id)sender {
    capStyle = [sender selectedTag];
    [self setNeedsDisplay:YES];
}

- (void)changeZoomSlider:(id)sender {
    [self setZoom: [sender doubleValue]];
    [[self superview] setNeedsDisplay:YES];
}

// The -changeLineType: method sets the array dashCount, which specifies the alternating 
// lengths of painted and unpainted line segments.  The Bezier path uses this array with 
// the -setLineDash:count:phase: method to set the line pattern.
 
- (void)changeLineType:(id)sender {
    NSInteger dashType = [sender selectedTag];
    switch (dashType) {
        case 0: {
            dashCount = 0;
        }
        break;
        case 1: {
            dashCount = 2;
            dashArray[0] = 5;
            dashArray[1] = 5;
        }
        break;
        case 2: {
            dashCount = 3;
            dashArray[0] = 8;
            dashArray[1] = 3;
            dashArray[2] = 8;
        }
        break;
        case 3: {
            dashCount = 3;
            dashArray[0] = 9;
            dashArray[1] = 6;
            dashArray[2] = 3;
        }
        break;
    }
    [self setNeedsDisplay:YES];
}

// The -drawRect: method takes all the settings and applies the transformations
// to the path that is drawn in the BezierView.
 
- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    NSAffineTransform *rotation    = [NSAffineTransform transform];
    NSAffineTransform *translation = [NSAffineTransform transform];
    CGFloat emptySpace = 40;  // Defines the amount of padding between the path and the enclosing view

    [backgroundColor set];
    NSRectFill([self bounds]);
    [lineColor set];
    
    // Draw the Bezier Path
    switch (pathType) {
	case SquarePath: {
	    if (NSMaxX(bounds) > NSMaxY(bounds)) {
		CGFloat width = (NSMaxY(bounds) - emptySpace)/sqrt(2);
		[self setPath:[NSBezierPath bezierPathWithRect:NSMakeRect(width/-2,width/-2,width, width)]];
	    } else {
		CGFloat width = (NSMaxX(bounds) - emptySpace)/sqrt(2);
		[self setPath:[NSBezierPath bezierPathWithRect: NSMakeRect(width/-2, width/-2, width, width)]];
	    }
	}
	break;
	case CirclePath: {
	    if (NSMaxX(bounds) > NSMaxY(bounds)) {
		CGFloat width = NSMaxY(bounds) - emptySpace;
		[self setPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(width/-2,width/-2,width, width)]];
	    } else {
		CGFloat width = NSMaxX(bounds) - emptySpace;
		[self setPath:[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(width/-2, width/-2, width, width)]];
	    }
	}
	break;
	case ArcPath: {
	    [self setPath:[NSBezierPath bezierPath]];
	    if (NSMaxX(bounds) > NSMaxY(bounds)) {
		[path appendBezierPathWithArcWithCenter:(NSPoint){0,0} 
		    radius:NSMaxY(bounds)/2-20 startAngle:0 endAngle:45];
	    } else {
		[path appendBezierPathWithArcWithCenter:(NSPoint){0,0} 
		    radius:NSMaxX(bounds)/2-20 startAngle:0 endAngle:45];
	    }
	}
	break;
        case LinePath: {
	    CGFloat width;
	    [self setPath:[NSBezierPath bezierPath]];
	    if (NSMaxX(bounds) > NSMaxY(bounds)) {
		width = NSMaxY(bounds) - emptySpace;
	    } else {
		width = NSMaxX(bounds) - emptySpace;
	    }
	    [path moveToPoint: (NSPoint) {width/-2, 0}];
	    [path lineToPoint: (NSPoint) {width/2, 0}];
	}
	break;
        default:
            break;
    }
    
    switch (capStyle) {
        case ButtLine: {
            [path setLineCapStyle: NSButtLineCapStyle];
        }
        break;
        case SquareLine: {
            [path setLineCapStyle: NSSquareLineCapStyle];
        }
        break;
        case RoundLine: {
            [path setLineCapStyle: NSRoundLineCapStyle];
        }
        break;
        default:
            break;
    }
    
    if (dashCount) {
        [path setLineDash:dashArray count:dashCount phase: 0.0];
    }
    
    [path setLineWidth: lineWidth];

    [NSGraphicsContext saveGraphicsState];
    [rotation rotateByDegrees:angle];
    [translation translateXBy: NSMaxX(bounds)/2 yBy: NSMaxY(bounds)/2];
    [translation concat];
    [rotation concat];
    [path stroke];
    if (filled) {
        [fillColor set];
        [path fill];
    }
    [currentContext restoreGraphicsState];
            
}

@end
