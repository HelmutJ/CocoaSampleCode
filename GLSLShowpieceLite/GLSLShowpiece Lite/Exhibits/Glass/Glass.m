//-------------------------------------------------------------------------
//
//	File: Glass.m
//
//  Abstract: Glass GLSL Exhibit
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

#import "Glass.h"

@implementation Glass

- (void) getTextures
{
	houseTexture       = [self loadTextureFromResource: @"House" ];
	frameBufferTexture = [self loadFrameBufferTexture:viewport];
} // getTextures

- (void) setupUniforms
{
	glUseProgramObjectARB(programObject);
	
	glUniform3fARB([self getUniformLocation:programObject uniformName:"LightPos"], 0.0, 0.0, 4.0);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"BaseColor"], 0.4, 0.4, 1.0);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"Depth"], 0.1);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"MixRatio"], 1);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"EnvMap"], 0);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"RefractionMap"], 1);
} // setupUniforms

- (void) initLazy
{
	[super initLazy];
	
	// Setup GLSL

	// Here we get a new model
	
	model = [[Models alloc] init];
	
	// get all the textures
	
	[self getTextures];
	
	// Load vertex and fragment shaders
	
	[self loadShadersFromResource:@"Glass" ];
		
	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	glDeleteTextures(1, &houseTexture);
	glDeleteTextures(1, &frameBufferTexture);

	[model dealloc];
	
	[super dealloc];
} // dealloc 

- (NSString *) name
{
	return @"Glass";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Glass" ofType: @"rtf"];
} // descriptionFilename

- (void) setupRenderFrameUniforms:(GLint *)theViewPort
{
	GLfloat v[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	
	v[0] = (GLfloat)viewport[2];
	v[1] = (GLfloat)viewport[3];
	v[2] = (GLfloat)NextHighestPowerOf2FromInt( viewport[2] );
	v[3] = (GLfloat)NextHighestPowerOf2FromInt( viewport[3] );
	
	glUniform1fARB([self getUniformLocation:programObject uniformName:"FrameWidth"], v[0] );
	glUniform1fARB([self getUniformLocation:programObject uniformName:"FrameHeight"], v[1] );
	glUniform1fARB([self getUniformLocation:programObject uniformName:"textureWidth"], v[2] );
	glUniform1fARB([self getUniformLocation:programObject uniformName:"textureHeight"], v[3] );
} // setupRenderFrameUniforms

- (void) renderFrame
{
	[super renderFrame];
	
	glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT);

	glDisable(GL_TEXTURE_2D);
	glDisable(GL_TEXTURE_3D);
	
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_LIGHT1);
	
	glColor4f(1, 1, 1, 1);
	
	glTranslatef(0, 0, 1);
	
	[model drawModel:kModelSolidSmallTeapot];
	
	glTranslatef(0, 0, -1);
	
	glEnable(GL_BLEND);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glUseProgramObjectARB(programObject);
	
	glGetIntegerv(GL_VIEWPORT,viewport);
	
	[self setupRenderFrameUniforms:viewport];

	[self copyFramebufferToTexture:frameBufferTexture];

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, houseTexture);
	
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, frameBufferTexture);
	
	[self copyFramebufferToTexture:frameBufferTexture];
	
	glActiveTexture(GL_TEXTURE0);
	
	[model drawModel:kModelSolidTeapot];
	
	glUseProgramObjectARB(NULL);
	
	glPopAttrib();
} // renderFrame

@end
