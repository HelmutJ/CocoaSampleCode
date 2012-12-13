/*
     File: SimpleLayoutView.m
 Abstract: Simple NSView subclass showing animation capabilities. Not a generally reusable class, more demo-ware.
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
#import "SimpleLayoutView.h"


/* Default separation between items, and default size of added subviews.
*/
#define SEPARATION 10.0
#define BOXWIDTH 80.0
#define BOXHEIGHT 80.0

@implementation SimpleLayoutView

/* By default NSColorPanel does not show an alpha (opacity) slider; enable it
*/
+ (void)initialize {
    if (self == [SimpleLayoutView class]) {
        [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    }
}

/* Start off in column mode. 
*/
- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setLayoutStyle:ColumnLayout];
    }
    return self;
}

/* Get/set layoutStyle
*/
- (Layout)layoutStyle {
    return layoutStyle;
}

- (void)setLayoutStyle:(Layout)newLayoutStyle {
    if (newLayoutStyle != layoutStyle) {
        layoutStyle = newLayoutStyle;
        [self layout];
    }
}

/* This method returns a rect that is integral in base coordinates.
*/
- (NSRect)integralRect:(NSRect)rect {
    return [self convertRectFromBase:NSIntegralRect([self convertRectToBase:rect])];
}

/* This method simply computes the new layout, and calls setFrame: on all subview with their locations. Since the calls are made to the subviews' animators, the subview animate to their new locations.
*/
- (void)layout {
    NSArray *subviews = [self subviews];

    switch ([self layoutStyle]) {
        case ColumnLayout: {
            NSPoint curPoint = NSMakePoint([self bounds].size.width / 2.0, 0.0);            // Starting point: center bottom of view
            for (NSView *subview in subviews) {
                NSRect frame = NSMakeRect(curPoint.x - BOXWIDTH / 2.0, curPoint.y, BOXWIDTH, BOXHEIGHT);    // Centered horizontally, stacked higher
                [[subview animator] setFrame:[self integralRect:frame]];
                curPoint.y += frame.size.height + SEPARATION;                // Next view location; we're stacking higher
            }
            break;
        }
        case RowLayout: {
            NSPoint curPoint = NSMakePoint(0.0, [self bounds].size.height / 2.0);        // Starting point: center left edge of view
            for (NSView *subview in subviews) {
                NSRect frame = NSMakeRect(curPoint.x, curPoint.y - BOXHEIGHT / 2.0, BOXWIDTH, BOXHEIGHT);    // Centered vertically, stacked left to right
                [[subview animator] setFrame:[self integralRect:frame]];
                curPoint.x += frame.size.width + SEPARATION;                // Next view location
            }
            break;
        }
        case GridLayout: {
            NSInteger viewsPerSide = ceil(sqrt([subviews count]));          // Put the views in a roughly square grid
            NSInteger index = 0;
            NSPoint curPoint = NSZeroPoint;                                 // Starting at the bottom left corner
            for (NSView *subview in subviews) {
                NSRect frame = NSMakeRect(curPoint.x, curPoint.y, BOXWIDTH, BOXHEIGHT);
                [[subview animator] setFrame:[self integralRect:frame]];
                curPoint.x += BOXWIDTH + SEPARATION;                        // Stack them horizontally
                if ((++index) % viewsPerSide == 0) {                        // And if we have enough on this row, move up to the next
                    curPoint.x = 0;                
                    curPoint.y += BOXHEIGHT + SEPARATION;
                }
            }
            break;
        }
        default:;
    }
}

/* Changing frame (which is what happens when the window is resized) should cause relayout.
*/
- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    [self layout];
}

/* Create a new view to be added/animated. Any kind of view can be added here, we go for simple colored box using the Leopard "custom" box type.
*/
- (NSView *)viewToBeAdded {
    NSBox *box = [[[NSBox alloc] initWithFrame:NSMakeRect(0.0, 0.0, BOXWIDTH, BOXHEIGHT)] autorelease];
    [box setBoxType:NSBoxCustom];
    [box setBorderType:NSLineBorder];
    [box setTitlePosition:NSNoTitle];
    [box setFillColor:[boxColorField color]];
    return box;
}

/* Action methods to add/remove boxes, giving us something to animate.  Note that we cause a relayout here; a better design is to relayout in the view automatically on addition/removal of subviews.
*/
- (IBAction)addABox:(id)sender {
    [self addSubview:[self viewToBeAdded]];
    [self layout];
}

- (IBAction)removeLastBox:(id)sender {
    [[[self subviews] lastObject] removeFromSuperview];        // This removes and releases the view
    [self layout];
}

/* Action method to change layout style.
*/
- (IBAction)changeLayout:(id)sender {
    [self setLayoutStyle:[sender selectedTag]];
}

@end
