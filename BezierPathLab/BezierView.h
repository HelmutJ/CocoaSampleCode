/*
     File: BezierView.h
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


#import <Cocoa/Cocoa.h>

enum  {	// Types of Bezier Paths.
    SquarePath,
    CirclePath,
    ArcPath,
    LinePath
};
typedef NSInteger BezierPathType;

enum { // Types of Cap Styles.
    ButtLine,
    SquareLine,
    RoundLine
};
typedef NSInteger CapStyleType;

@interface BezierView : NSView
{
    NSColor *lineColor, *fillColor, *backgroundColor;
    NSBezierPath *path;
    CGFloat lineWidth, angle, dashCount;
    BezierPathType pathType;
    CapStyleType capStyle;
    BOOL filled;
    CGFloat dashArray[3];
    
    // Outlets
    id lineColorWell;
    id fillColorWell;
    id backgroundColorWell;
    id lineWidthSlider;
    id pathTypeMatrix;
    id filledBox;
    id angleSlider;
    id capStyleMatrix;
    id zoomSlider;
    id lineTypeMatrix;
}

// Outlet-setting methods (we need these to set the initial values for the controls)

- (void) setLineColor:(NSColor *)newColor;
- (void) setFillColor:(NSColor *)newColor;
- (void) setBackgroundColor:(NSColor *)newColor;
- (void) setPath:(NSBezierPath *)newPath;
- (void) setLineWidth:(CGFloat) newWidth;
- (void) setAngle:(CGFloat) newAngle;
- (void) setZoom:(CGFloat) scaleFactor;

// Methods to change the path attributes.

- (void) setPathType:(id)sender;
- (void) setFilled:(id)sender;
- (void) setCapStyle:(id)sender;
- (void) changeLineWidth:(id)sender;
- (void) changeAngleSlider:(id)sender;
- (void) changeLineType:(id)sender;
- (void) changeZoomSlider:(id)sender;
- (void) changeLineColor:(id)sender;
- (void) changeFillColor:(id)sender;
- (void) changeBackgroundColor:(id)sender;

@end
