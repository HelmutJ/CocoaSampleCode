//-------------------------------------------------------------------------
//
//	File: Fire.m
//
//  Abstract: Fire GLSL Exhibit
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

#import "Fire.h"

@implementation Fire

- (void) setupUniforms
{
	glUseProgramObjectARB(programObject);
	
	glUniform3fARB([self getUniformLocation:programObject uniformName:"LightPosition"], 0.0, 0.0, 4.0);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"NoiseScale"], 1.2);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"Scale"], 0.4);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"Color1"], 0.8, 0.7, 0.0);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"Color2"], 0.6, 0.1, 0.0);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"Noise"], 0);
} // setupUniforms

- (void) setupGeometry
{
	geometry = [[KleinSurface alloc] init];
	
	geometryDisplayList = [geometry getDisplayList];
} // setupGeometry

- (void) initLazy
{
	[super initLazy];

	// Setup GLSL

	// Here we get a new klein bottle
	
	[self setupGeometry];
	
	// noise texture
	
	noiseTexture = [self loadNoiseTexture];

	// Load vertex and fragment shaders
	
	[self loadShadersFromResource:@"Fire" ];
		
	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	glDeleteTextures(1, &noiseTexture);

	[geometry dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Fire";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Fire" ofType: @"rtf"];
} // descriptionFilename

- (void) renderFrame
{
	[super renderFrame];
	
	glUseProgramObjectARB(programObject);

	glBindTexture(GL_TEXTURE_3D, noiseTexture);
	
	// Use our display list

	glCallList(geometryDisplayList);
		
	glUseProgramObjectARB(NULL);
} // renderFrame

@end
