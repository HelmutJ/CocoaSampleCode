/*

File: WindowController.m

Abstract: Implements a window controller to recieve events from and
	dispatch state updates to the various view.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#import "WindowController.h"
#import "GradientView.h"
#import "ShadingView.h"
#import "PreviewView.h"

// Utility function to convert from NSColor to CGColorRef
CGColorRef CreateCGColorFromNSColor(NSColor * color)
{
	NSColor * rgbColor = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
	CGFloat r, g, b, a;
	[rgbColor getRed:&r green:&g blue:&b alpha:&a];
	return CGColorCreateGenericRGB(r, g, b, a);
}

// Some private methods for our window controller
@interface WindowController (private_methods)

-(void)recalculateGradients;
-(void)repositionGradients;

@end

@implementation WindowController

-(void)awakeFromNib
{
	// Center the window
	[[self window] center];
	// Request that the color panel show alpha
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	// Initialize our CGColorRefs with the current color values from the nib
	color1 = CreateCGColorFromNSColor([colorWell1 color]);
	color2 = CreateCGColorFromNSColor([colorWell2 color]);
	color3 = CreateCGColorFromNSColor([colorWell3 color]);
	// Setup the gradients views.
	[self recalculateGradients];
	[self repositionGradients];
}

// Sets up the objects required to display the gradients
// and passes them to the gradient views.
-(void)recalculateGradients
{
	// Update the ShadingView
	// Create a new shading function with our current colors
	// and their starting locations
	CGFunctionRef colorFunction = CreateShadingFunction(
		color1, [colorStart1 doubleValue],
		color2, [colorStart2 doubleValue],
		color3, [colorStart3 doubleValue]);
	// Tell the shading view to use this new function
	[shadingView setShadingFunction:colorFunction];
	// The shading view will retain, so release.
	CGFunctionRelease(colorFunction);
	
	// Update the GradientView & PreviewView
	// Create a new gradient with our current colors
	// and their starting locaitons
	CGGradientRef gradient = CreateGradient(
		color1, [colorStart1 doubleValue],
		color2, [colorStart2 doubleValue],
		color3, [colorStart3 doubleValue]);
	// Tell the gradient & preview views to use this new function
	[gradientView setGradient:gradient];
	[previewView setGradient:gradient];
	// These views retain, so release.
	CGGradientRelease(gradient);
}

// When the start or end point or radii changes, we need to inform the views
// so that they can rerender.
-(void)repositionGradients
{
	CGPoint startPoint = CGPointMake([startX doubleValue], [startY doubleValue]);
	CGPoint endPoint = CGPointMake([endX doubleValue], [endY doubleValue]);
	CGFloat startRad = [startRadius doubleValue], endRad = [endRadius doubleValue];
	[shadingView setStartPoint:startPoint];
	[shadingView setStartRadius:startRad];
	[shadingView setEndPoint:endPoint];
	[shadingView setEndRadius:endRad];
	[gradientView setStartPoint:startPoint];
	[gradientView setStartRadius:startRad];
	[gradientView setEndPoint:endPoint];
	[gradientView setEndRadius:endRad];
}

// One of our color wells has changed, convert the color to a CGColorRef
// and rebuild the gradients.

- (IBAction)changeColor1:(id)sender
{
	CGColorRelease(color1);
	color1 = CreateCGColorFromNSColor([sender color]);
	[self recalculateGradients];
}

- (IBAction)changeColor2:(id)sender
{
	CGColorRelease(color2);
	color2 = CreateCGColorFromNSColor([sender color]);
	[self recalculateGradients];
}

- (IBAction)changeColor3:(id)sender
{
	CGColorRelease(color3);
	color3 = CreateCGColorFromNSColor([sender color]);
	[self recalculateGradients];
}

// One of the color starting locations has changed, so request
// that the gradients be recalculated.

- (IBAction)changeColor1Start:(id)sender
{
	[self recalculateGradients];
}

- (IBAction)changeColor2Start:(id)sender
{
	[self recalculateGradients];
}

- (IBAction)changeColor3Start:(id)sender
{
	[self recalculateGradients];
}

// The clipping shape has changed, so inform the views
// of the new shape to use.
- (IBAction)changeShape:(id)sender
{
	switch([sender selectedTag])
	{
		case 0: // Square
			[shadingView setShapeSquare];
			[gradientView setShapeSquare];
			break;
			
		case 1: // Circle
			[shadingView setShapeCircle];
			[gradientView setShapeCircle];
			break;
			
		case 2: // Filled Star
			[shadingView setShapeFilledStar];
			[gradientView setShapeFilledStar];
			break;
			
		case 3: // Hollow Star
			[shadingView setShapeHollowStar];
			[gradientView setShapeHollowStar];
			break;
	}
}

// The type of gradient has changed, so inform the
// views to use the new clipping shape.
// Additionally, hide or show the radii controls
// as appropriate to the new gradient type.
- (IBAction)changeType:(id)sender
{
	BOOL hideRadius = NO;
	switch([sender selectedTag])
	{
		case 0:
			[shadingView setTypeAxial];
			[gradientView setTypeAxial];
			hideRadius = YES;
			break;
			
		case 1:
			[shadingView setTypeRadial];
			[gradientView setTypeRadial];
			break;
	}
	[startRadiusLabel setHidden:hideRadius];
	[startRadius setHidden:hideRadius];
	[endRadiusLabel setHidden:hideRadius];
	[endRadius setHidden:hideRadius];
}

// Inform the views as to if they should render
// the gradients with extended start/end.

-(IBAction)changeExtendStart:(id)sender
{
	BOOL extend = [sender state] == NSOnState;
	[shadingView setExtendStart:extend];
	[gradientView setExtendStart:extend];
}

-(IBAction)changeExtendEnd:(id)sender
{
	BOOL extend = [sender state] == NSOnState;
	[shadingView setExtendEnd:extend];
	[gradientView setExtendEnd:extend];
}

// Inform the views that the start/end point/radii
// has been changed by the user.

-(IBAction)changeStartX:(id)sender
{
	[self repositionGradients];
}

-(IBAction)changeStartY:(id)sender
{
	[self repositionGradients];
}

-(IBAction)changeStartRadius:(id)sender
{
	[self repositionGradients];
}

-(IBAction)changeEndX:(id)sender
{
	[self repositionGradients];
}

-(IBAction)changeEndY:(id)sender
{
	[self repositionGradients];
}

-(IBAction)changeEndRadius:(id)sender
{
	[self repositionGradients];
}

// Handle one of the built in presents
-(IBAction)changePreset:(id)sender
{
	NSInteger type = 0;
	switch(@"%i", [[sender selectedItem] tag])
	{
		case 1: // Horizontal
			[startX setDoubleValue:0.0];
			[startY setDoubleValue:-0.9];
			[endX setDoubleValue:0.0];
			[endY setDoubleValue:0.9];
			break;
			
		case 2: // Vertical
			[startX setDoubleValue:-0.9];
			[startY setDoubleValue:0.0];
			[endX setDoubleValue:0.9];
			[endY setDoubleValue:0.0];
			break;
			
		case 3: // Diagonal
			[startX setDoubleValue:-0.9];
			[startY setDoubleValue:-0.9];
			[endX setDoubleValue:0.9];
			[endY setDoubleValue:0.9];
			break;
			
		case 4: // Toroidal
			[startX setDoubleValue:0.0];
			[startY setDoubleValue:0.0];
			[startRadius setDoubleValue:0.25];
			[endX setDoubleValue:0.0];
			[endY setDoubleValue:0.0];
			[endRadius setDoubleValue:0.75];
			type = 1;
			break;

		case 5: // Conical
			[startX setDoubleValue:0.0];
			[startY setDoubleValue:0.75];
			[startRadius setDoubleValue:0.05];
			[endX setDoubleValue:0.0];
			[endY setDoubleValue:-0.25];
			[endRadius setDoubleValue:0.45];
			type = 1;
			break;
	}
	[geometry selectCellWithTag:type];
	[self changeType:geometry];
	[self repositionGradients];
}

// Inform the gradient views
// that they should show or hide
// the clipping region (presented in light gray).
-(IBAction)changeShowClip:(id)sender
{
	[shadingView setShowClip:[sender state]];
	[gradientView setShowClip:[sender state]];
}

// Inform the gradient views
// that they should show or hide
// the end points, joining line, and radii circles
-(IBAction)changeShowEndpoints:(id)sender
{
	[shadingView setShowEndpoints:[sender state]];
	[gradientView setShowEndpoints:[sender state]];
}

@end