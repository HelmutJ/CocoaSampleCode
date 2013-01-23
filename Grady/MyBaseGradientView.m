/*
     File: MyBaseGradientView.m 
 Abstract: The base NSView class for drawing any variation of NSGradient.
  
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

#import "MyBaseGradientView.h"

@implementation MyBaseGradientView

// -------------------------------------------------------------------------------
//	resetGradient:
//
//	Remove the current NSGradient and set one up again with the current start
//	and end colors.
// -------------------------------------------------------------------------------
- (void)resetGradient
{
	if (forceColorChange && myGradient != nil)
	{
		[myGradient release];
		myGradient = nil;
	}
	
	if (myGradient == nil)
	{
		myGradient = [[NSGradient alloc] initWithStartingColor:myStartColor endingColor:myEndColor];
		forceColorChange = NO;
	}
}

// -------------------------------------------------------------------------------
//	setStartColor:startColor
//
//	This method is called when the user changes the start color swatch,
//	which requires that the NSGradient be re-created.
// -------------------------------------------------------------------------------
- (void)setStartColor:(NSColor*)startColor
{
	myStartColor = startColor;
	forceColorChange = YES;
	[self setNeedsDisplay:YES];	// make sure we update the change
}

// -------------------------------------------------------------------------------
//	setEndColor:endColor
//
//	This method is called when the user changes the end color swatch,
//	which requires that the NSGradient be re-created.
// -------------------------------------------------------------------------------
- (void)setEndColor:(NSColor*)endColor
{
	myEndColor = endColor;
	forceColorChange = YES;
	[self setNeedsDisplay:YES];	// make sure we update the change
}

// -------------------------------------------------------------------------------
//	setAngle:angle
//
//	This method is called when the user changes the angle indicator,
//	which requires a re-display or update on this view.
// -------------------------------------------------------------------------------
- (void)setAngle:(CGFloat)angle
{
	myAngle = angle;
	[self setNeedsDisplay:YES];	// make sure we update the change
}

// -------------------------------------------------------------------------------
//	setRadialDraw:isRadial
//
//	This method is called when the user changes the radial flag (checkbox state),
//	which requires a re-display or update on this view.
// -------------------------------------------------------------------------------
- (void)setRadialDraw:(BOOL)isRadial
{
	myIsRadial = isRadial;
	[self setNeedsDisplay:YES];	// make sure we update the change
}

// -------------------------------------------------------------------------------
//	getRelativeCenterPositionFromEvent:theEvent
//
//	Computes the offset point for the radial NSGradient based on the mouse position.
// -------------------------------------------------------------------------------
- (NSPoint)getRelativeCenterPositionFromEvent:(NSEvent*)theEvent
{
	NSPoint curMousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint pt = NSMakePoint( (curMousePt.x - NSMidX([self bounds])) / ([self bounds].size.width / 2.0),
							  (curMousePt.y - NSMidY([self bounds])) / ([self bounds].size.height / 2.0));
	return pt;
}

// -------------------------------------------------------------------------------
//	mouseDown:theEvent
//
//	If the user mouseDowns in this view and we are drawing a radial NSGradient,
//	update the view's gradient with the current mouse position as the offset.
// -------------------------------------------------------------------------------
- (void)mouseDown:(NSEvent*)theEvent
{
	if (myIsRadial)
	{
		myOffsetPt = [self getRelativeCenterPositionFromEvent: theEvent];
		[self setNeedsDisplay:YES];	// make sure we update the change
	}
}

// -------------------------------------------------------------------------------
//	mouseDragged:theEvent
//
//	If the user drags the mouse inside this view and we are drawing a radial NSGradient,
//	update the view's gradient with the current mouse position as the offset.
// -------------------------------------------------------------------------------
- (void)mouseDragged:(NSEvent*)theEvent
{
	if (myIsRadial)
	{
		myOffsetPt = [self getRelativeCenterPositionFromEvent: theEvent];
		[self setNeedsDisplay:YES];	// make sure we update the change
	}
}

@end
