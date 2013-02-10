/*
     File: AppController.m
 Abstract: Create a fire effect using emitter layers
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

@interface AppController (Internal)
-(CGImageRef)CGImageNamed:(NSString*)name;
@end

@implementation AppController

-(void)awakeFromNib {
	//Create the root layer
	rootLayer = [CALayer layer];
	
	//Set the root layer's background color to black
	rootLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	
	//Create the fire emitter layer
	fireEmitter = [CAEmitterLayer layer];
	fireEmitter.emitterPosition = CGPointMake(225, 50);
	fireEmitter.emitterMode = kCAEmitterLayerOutline;
	fireEmitter.emitterShape = kCAEmitterLayerLine;
	fireEmitter.renderMode = kCAEmitterLayerAdditive;
	fireEmitter.emitterSize = CGSizeMake(0, 0);
	
	//Create the smoke emitter layer
	smokeEmitter = [CAEmitterLayer layer];
	smokeEmitter.emitterPosition = CGPointMake(225, 50);
	smokeEmitter.emitterMode = kCAEmitterLayerPoints;
	
	//Create the fire emitter cell
	CAEmitterCell* fire = [CAEmitterCell emitterCell];
	fire.emissionLongitude = M_PI;
	fire.birthRate = 0;
	fire.velocity = 80;
	fire.velocityRange = 30;
	fire.emissionRange = 1.1;
	fire.yAcceleration = 200;
	fire.scaleSpeed = 0.3;
	CGColorRef color = CGColorCreateGenericRGB(0.8, 0.4, 0.2, 0.10);
	fire.color = color;
	CGColorRelease(color);
	fire.contents = (id) [self CGImageNamed:@"fire.png"];
	
	//Name the cell so that it can be animated later using keypaths
	[fire setName:@"fire"];
	
	//Add the fire emitter cell to the fire emitter layer
	fireEmitter.emitterCells = [NSArray arrayWithObject:fire] ;
	
	//Create the smoke emitter cell
	CAEmitterCell* smoke = [CAEmitterCell emitterCell];
	smoke.birthRate = 11;
	smoke.emissionLongitude = M_PI / 2;
	smoke.lifetime = 0;
	smoke.velocity = 40;
	smoke.velocityRange = 20;
	smoke.emissionRange = M_PI / 4;
	smoke.spin = 1;
	smoke.spinRange = 6;
	smoke.yAcceleration = 160;
	smoke.contents = (id) [self CGImageNamed:@"smoke.png"];
	smoke.scale = 0.1;
	smoke.alphaSpeed = -0.12;
	smoke.scaleSpeed = 0.7;
	
	//Name the cell so that it can be animated later using keypaths
	[smoke setName:@"smoke"];
	
	//Add the smoke emitter cell to the smoke emitter layer
	smokeEmitter.emitterCells = [NSArray arrayWithObject:smoke];
	
	//Add the two emitter layers to the root layer
	[rootLayer addSublayer:smokeEmitter];
	[rootLayer addSublayer:fireEmitter];

	//Set the view's layer to the base layer
	[view setLayer:rootLayer];
	[view setWantsLayer:YES];
	
	//Set the fire simulation to reflect the initial slider position
	[self slidersChanged:self];
	
	//Force the view to update
	[view setNeedsDisplay:YES];
}

//Update the emitters when the slider value changes
-(IBAction)slidersChanged:(id)sender {
	//Query the gasSlider's value
	float gas = [gasSlider intValue] / 100.0;
	
	//Update the fire properties
	[fireEmitter setValue:[NSNumber numberWithInt:(gas * 1000)] forKeyPath:@"emitterCells.fire.birthRate"];
	[fireEmitter setValue:[NSNumber numberWithFloat:gas] forKeyPath:@"emitterCells.fire.lifetime"];
	[fireEmitter setValue:[NSNumber numberWithFloat:(gas * 0.35)] forKeyPath:@"emitterCells.fire.lifetimeRange"];
	fireEmitter.emitterSize = CGSizeMake(50 * gas, 0);

	//Update the smoke properites
	[smokeEmitter setValue:[NSNumber numberWithInt:gas * 4] forKeyPath:@"emitterCells.smoke.lifetime"];
	CGColorRef color = CGColorCreateGenericRGB(1, 1, 1, gas * 0.3);
	[smokeEmitter setValue:(id)color forKeyPath:@"emitterCells.smoke.color"];
	CGColorRelease(color);
}

//Return a CGImageRef from the specified image file in the app's bundle
-(CGImageRef)CGImageNamed:(NSString*)name {
	CFURLRef url = (CFURLRef) [[NSBundle mainBundle] URLForResource:name withExtension:nil];
	CGImageSourceRef source = CGImageSourceCreateWithURL(url, NULL);
	CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	return (CGImageRef)[NSMakeCollectable(image) autorelease];
}

@end
