/*
     File: AppController.m
 Abstract: Create a fireworks simulation using particles, respond to user actions
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "AppController.h"

@implementation AppController

-(void)awakeFromNib {
	//Create the root layer
	rootLayer = [CALayer layer];
	
	//Set the root layer's attributes
	rootLayer.bounds = CGRectMake(0, 0, 640, 480);
	CGColorRef color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1);
	rootLayer.backgroundColor = color;
	CGColorRelease(color);
	
	//Load the spark image for the particle
	const char* fileName = [[[NSBundle mainBundle] pathForResource:@"tspark" ofType:@"png"] UTF8String];
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(fileName);
	id img = (id) CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
	
	mortor = [[CAEmitterLayer layer] retain];
	mortor.emitterPosition = CGPointMake(320, 0);
	mortor.renderMode = kCAEmitterLayerAdditive;
	
	//Invisible particle representing the rocket before the explosion
	CAEmitterCell *rocket = [[CAEmitterCell emitterCell] retain];
	rocket.emissionLongitude = M_PI / 2;
	rocket.emissionLatitude = 0;
	rocket.lifetime = 1.6;
	rocket.birthRate = 1;
	rocket.velocity = 400;
	rocket.velocityRange = 100;
	rocket.yAcceleration = -250;
	rocket.emissionRange = M_PI / 4;
	color = CGColorCreateGenericRGB(0.5, 0.5, 0.5, 0.5);
	rocket.color = color;
	CGColorRelease(color);
	rocket.redRange = 0.5;
	rocket.greenRange = 0.5;
	rocket.blueRange = 0.5;
	
	//Name the cell so that it can be animated later using keypath
	[rocket setName:@"rocket"];
	
	//Flare particles emitted from the rocket as it flys
	CAEmitterCell *flare = [CAEmitterCell emitterCell];
	flare.contents = img;
	flare.emissionLongitude = (4 * M_PI) / 2;
	flare.scale = 0.4;
	flare.velocity = 100;
	flare.birthRate = 45;
	flare.lifetime = 1.5;
	flare.yAcceleration = -350;
	flare.emissionRange = M_PI / 7;
	flare.alphaSpeed = -0.7;
	flare.scaleSpeed = -0.1;
	flare.scaleRange = 0.1;
	flare.beginTime = 0.01;
	flare.duration = 0.7;
	
	//The particles that make up the explosion
	CAEmitterCell *firework = [CAEmitterCell emitterCell];
	firework.contents = img;
	firework.birthRate = 9999;
	firework.scale = 0.6;
	firework.velocity = 130;
	firework.lifetime = 2;
	firework.alphaSpeed = -0.2;
	firework.yAcceleration = -80;
	firework.beginTime = 1.5;
	firework.duration = 0.1;
	firework.emissionRange = 2 * M_PI;
	firework.scaleSpeed = -0.1;
	firework.spin = 2;
	
	//Name the cell so that it can be animated later using keypath
	[firework setName:@"firework"];
	
	//preSpark is an invisible particle used to later emit the spark
	CAEmitterCell *preSpark = [CAEmitterCell emitterCell];
	preSpark.birthRate = 80;
	preSpark.velocity = firework.velocity * 0.70;
	preSpark.lifetime = 1.7;
	preSpark.yAcceleration = firework.yAcceleration * 0.85;
	preSpark.beginTime = firework.beginTime - 0.2;
	preSpark.emissionRange = firework.emissionRange;
	preSpark.greenSpeed = 100;
	preSpark.blueSpeed = 100;
	preSpark.redSpeed = 100;
	
	//Name the cell so that it can be animated later using keypath
	[preSpark setName:@"preSpark"];
	
	//The 'sparkle' at the end of a firework
	CAEmitterCell *spark = [CAEmitterCell emitterCell];
	spark.contents = img;
	spark.lifetime = 0.05;
	spark.yAcceleration = -250;
	spark.beginTime = 0.8;
	spark.scale = 0.4;
	spark.birthRate = 10;
	
	preSpark.emitterCells = [NSArray arrayWithObjects:spark, nil];
	rocket.emitterCells = [NSArray arrayWithObjects:flare, firework, preSpark, nil];
	mortor.emitterCells = [NSArray arrayWithObjects:rocket, nil];
	[rootLayer addSublayer:mortor];
	
	//Set the view's layer to the base layer
	[theView setLayer:rootLayer];
	[theView setWantsLayer:YES];
	
	//Force the view to update
	[theView setNeedsDisplay:YES];
}

//Update particle properites based on the slider values
-(IBAction)slidersMoved:(id)sender {
	[mortor setValue:[NSNumber numberWithFloat:[rocketRange floatValue] * M_PI / 4] 
		  forKeyPath:@"emitterCells.rocket.emissionRange"]; 
	
	[mortor setValue:[NSNumber numberWithFloat:[rocketVelocity floatValue]]
		  forKeyPath:@"emitterCells.rocket.velocity"];
	
	[mortor setValue:[NSNumber numberWithFloat:[rocketVelocityRange floatValue]]
		  forKeyPath:@"emitterCells.rocket.velocityRange"];
	
	[mortor setValue:[NSNumber numberWithFloat:(-1 * [rocketGravity floatValue])]
		  forKeyPath:@"emitterCells.rocket.yAcceleration"];
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkRange floatValue] * M_PI / 4]
		  forKeyPath:@"emitterCells.rocket.emitterCells.firework.emissionRange"]; 
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkVelocity floatValue]]
		  forKeyPath:@"emitterCells.rocket.emitterCells.firework.velocity"];
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkVelocityRange floatValue]]
		  forKeyPath:@"emitterCells.rocket.emitterCells.firework.velocityRange"];
	
	[mortor setValue:[NSNumber numberWithFloat:(-1 * [fireworkGravity floatValue])]
		  forKeyPath:@"emitterCells.rocket.emitterCells.firework.yAcceleration"];
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkVelocity floatValue] * 0.70]
		  forKeyPath:@"emitterCells.rocket.emitterCells.preSpark.velocity"];
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkGravity floatValue] * -0.85]
		  forKeyPath:@"emitterCells.rocket.emitterCells.preSpark.yAcceleration"];
	
	[mortor setValue:[NSNumber numberWithFloat:[fireworkRange floatValue] * M_PI / 4]
		  forKeyPath:@"emitterCells.rocket.emitterCells.preSpark.emissionRange"];
	
	mortor.speed = [animationSpeed floatValue] / 100.0;
}

//Reset the slider positions to the default values
-(IBAction)resetSliders:(id)sender {
	[rocketRange setIntValue:1];
	[rocketVelocity setIntValue:400];
	[rocketVelocityRange setIntValue:100];
	[rocketGravity setIntValue:250];
	
	[fireworkRange setIntValue:8];
	[fireworkVelocity setIntValue:130];
	[fireworkVelocityRange setIntValue:0];
	[fireworkGravity setIntValue:80];
	
	[animationSpeed setIntValue:100];
	
	[self slidersMoved:self]; 
}
@end
