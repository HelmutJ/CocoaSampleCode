//-------------------------------------------------------------------------
//
//	File: Cloud2.m
//
//  Abstract: Cloud 2 GLSL Exhibit
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

#import "Cloud2.h"

@implementation Cloud2

- (void) initScale
{
	scale = [[UniformData alloc] init];
	
	[scale initCurrent:0.6];
	[scale initMax:0.9];
	[scale initMin:0.3];
	[scale initDelta:0.0002];
} // initScale

- (void) setupUniforms
{
	[self initScale];
	
	glUseProgramObjectARB(programObject);
	
	glUniform3fARB([self getUniformLocation:programObject uniformName:"LightPos"], 0.0, 0.0, 4.0);
	glUniform1fvARB([self getUniformLocation:programObject uniformName:"Scale"], 1, [scale current]);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"SkyColor"], 0.0, 0.0, 0.8);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"CloudColor"], 0.8, 0.8, 0.8);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"Noise"], 0);
} // setupUniforms

- (void) initLazy
{
	[super initLazy];
	
	// Setup GLSL

	// Here we get a new model
	
	model = [[Models alloc] init];

	// noise texture
	
	noiseTexture = [self loadNoiseTexture];

	// Load vertex and fragment shaders

	[self loadShadersFromResource:@"Cloud2" ];

	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	glDeleteTextures(1, &noiseTexture);
	
	[scale dealloc];
	
	[model dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Cloud 2";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Cloud2" ofType: @"rtf"];
} // descriptionFilename

- (void) renderFrame
{
	[super renderFrame];

	glUseProgramObjectARB(programObject);

	[scale animate];
	
	glUniform1fvARB([self getUniformLocation:programObject uniformName:"Scale"], 1, [scale current]);

	glBindTexture(GL_TEXTURE_3D, noiseTexture);

	[model drawModel:kModelSolidTeapot];

	glUseProgramObjectARB(NULL);
} // renderFrame

@end
