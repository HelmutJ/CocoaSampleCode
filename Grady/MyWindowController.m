/*
     File: MyWindowController.m 
 Abstract: The window controller class for this sample.
  
  Version: 1.1 
  
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

#import "MyWindowController.h"

#import "MyBaseGradientView.h"
#import "MyRectGradientView.h"

@implementation MyWindowController

// -------------------------------------------------------------------------------
//	initWithPath:newPath
// -------------------------------------------------------------------------------
- initWithPath:(NSString*)newPath
{
    return [super initWithWindowNibName:@"TestWindow"];
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// make sure our angle text input keep the right format
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle: NSNumberFormatterDecimalStyle];
	[[angle cell] setFormatter:formatter];
	[formatter release];
	
	// setup the initial start color
	[rectGradientView setStartColor:[NSColor orangeColor]];
	[bezierGradientView setStartColor:[NSColor orangeColor]];
	[startColorWell setColor:[NSColor orangeColor]];
	
	// setup the initial end color
	[rectGradientView setEndColor:[NSColor blueColor]];
	[bezierGradientView setEndColor:[NSColor blueColor]];
	[endColorWell setColor:[NSColor blueColor]];
	
	// setup the initial angle value
	[rectGradientView setAngle:90.0];
	[bezierGradientView setAngle:90.0];
	[angle setStringValue:@"90.0"];
	[angleSlider setFloatValue:90.0];
}

// -------------------------------------------------------------------------------
//	swapColors:sender
// -------------------------------------------------------------------------------
// user wants to swap the start and end colors
//
- (IBAction)swapColors:(id)sender
{
	NSColor* startColor = [startColorWell color];
	NSColor* endColor = [endColorWell color];
	
	// change all our view's start and end colors
	[rectGradientView setStartColor: endColor];
	[rectGradientView setEndColor: startColor];
	
	[bezierGradientView setStartColor: endColor];
	[bezierGradientView setEndColor: startColor];
	
	// fix our color wells
	[startColorWell setColor: endColor];
	[endColorWell setColor: startColor];
}

// -------------------------------------------------------------------------------
//	startColor:sender
// -------------------------------------------------------------------------------
// user changed the start color
//
- (IBAction)startColor:(id)sender
{
	NSColor* newColor = [sender color];
	[rectGradientView setStartColor: newColor];
	[bezierGradientView setStartColor: newColor];
}

// -------------------------------------------------------------------------------
//	endColor:sender
// -------------------------------------------------------------------------------
// user changed the end color
//
- (IBAction)endColor:(id)sender
{
	NSColor* newColor = [sender color];
	[rectGradientView setEndColor: newColor];
	[bezierGradientView setEndColor: newColor];
}

// -------------------------------------------------------------------------------
//	controlTextDidEndEditing:notification
// -------------------------------------------------------------------------------
// user changed the angle value
//
- (void)controlTextDidEndEditing:(NSNotification*)notification
{
	CGFloat theAngle = [angle floatValue];
	[rectGradientView setAngle: theAngle];
	[bezierGradientView setAngle: theAngle];
	
	double theAngleDougle = [angle doubleValue];
	[angleSlider setDoubleValue: theAngleDougle];
	[angleSlider setNeedsDisplay: YES];
}

// -------------------------------------------------------------------------------
//	angleSliderChange:sender
// -------------------------------------------------------------------------------
// user changed the angle from the circular slider
//
- (IBAction)angleSliderChange:(id)sender
{
	float angleValue = [sender floatValue];
	[rectGradientView setAngle: angleValue];
	[bezierGradientView setAngle: angleValue];
	[angle setDoubleValue: angleValue];
}

// -------------------------------------------------------------------------------
//	radialDraw:sender
// -------------------------------------------------------------------------------
// user changed the draw radial gradient checkbox
//
- (IBAction)radialDraw:(id)sender
{
	[rectGradientView setRadialDraw: [[sender selectedCell] state]];
	[bezierGradientView setRadialDraw: [[sender selectedCell] state]];
	
	// angle factor does not relate to radial draws
	[angleSlider setEnabled: ![[sender selectedCell] state]];
	[angle setEnabled: ![[sender selectedCell] state]];
	
	// hide/show the explain text for radial gradients
	[radialExplainText setHidden: ![[sender selectedCell] state]];
}

@end
