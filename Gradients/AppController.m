/*
     File: AppController.m
 Abstract: Continuously animate a gradient layer
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
*/

#import "AppController.h"


@implementation AppController

-(void)awakeFromNib {
	
	//Create the root layer
	rootLayer = [CALayer layer];
	
	//Set the root layer's attributes
	rootLayer.bounds = CGRectMake(0, 0, [view bounds].size.width, [view bounds].size.height);
	CGColorRef black = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1);
	rootLayer.backgroundColor = black;
	CGColorRelease(black);
	
	//Create a 3D perspective transform
	CATransform3D t = CATransform3DIdentity;
	t.m34 = 1.0 / -900.0;
	rootLayer.sublayerTransform = t;
	
	
	//Create the gradient layer
	gradientLayer = [CAGradientLayer layer];
	
	//Create 2 colors for the gradient
	CGColorRef green = CGColorCreateGenericRGB(0.0, 1.0, 0.0, 1);
	CGColorRef blue = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1);
	
	//Package the colors in a NSArray and add it to the layer
	NSArray *colors = [NSArray arrayWithObjects:(id) green, (id) blue, nil];
	gradientLayer.colors = colors;
	
	//Release the colors
	CGColorRelease(green);
	CGColorRelease(blue);
	
	//Set the size and position of the gradient layer
	gradientLayer.bounds = CGRectMake(0, 0, 250, 300);
	gradientLayer.position = CGPointMake([view bounds].size.width / 2.0, [view bounds].size.height / 2.0);
	
	//Rotate the gradient layer by adding a rotation matrix
	gradientLayer.transform = CATransform3DMakeRotation(0.5, 1, -1, 0);
	
	//Build the layer heirarchy and turn on CoreAnimation for the view
	[rootLayer addSublayer:gradientLayer];
	[view setLayer:rootLayer];
	[view setWantsLayer:YES];
	
	//Start a timer to automaticly call animate
	autoTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(animate) userInfo:NULL repeats:YES];
}	

//Animate to a new set of random colors
-(void)animate {
	//Generate 2 new random colors
	CGColorRef color1 = CGColorCreateGenericRGB(randFloat(), randFloat(), randFloat(), 1);
	CGColorRef color2 = CGColorCreateGenericRGB(randFloat(), randFloat(), randFloat(), 1);
	
	//Package the new color pair in an array (the format required for CAGradientLayer)
	NSArray *colors = [NSArray arrayWithObjects:(id) color1, color2, nil];

	//Set the duration for implicit animations to 1.5 sec
	[CATransaction setAnimationDuration:1.5];
	
	//implicitly animate the gradient colors
	[gradientLayer setColors:colors];
	
	//Release the colors
	CGColorRelease(color1);
	CGColorRelease(color2);
}

//Resize the gradient layer to match the new window size
-(void)windowDidResize:(NSNotification*)aNotification {
	//Querey the view's size
	float viewHeight = [view bounds].size.height;
	float viewWidth = [view bounds].size.width;
	
	//Disable implict animations for the resize
	[CATransaction setDisableActions:YES];
	
	//Resize the gradient layer and place it in the center
	gradientLayer.bounds = CGRectMake(0, 0, viewWidth / 2.5f, viewHeight / 1.6f);
	gradientLayer.position = CGPointMake(viewWidth / 2.0f, viewHeight / 2.0f);
	
	//Re-enable implict animations
	[CATransaction setDisableActions:NO];
}

// Generate a random floating point value  in [0, 1]
float randFloat() {
	return (random() % 1001) / 1000.0f;
}

@end
