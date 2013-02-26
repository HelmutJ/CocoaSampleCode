//-------------------------------------------------------------------------
//
//	File: Fur.m
//
//  Abstract: Fur GLSL Exhibit
// 			 
//  Author: "OpenGL Shading Language" book. (a.k.a "the orange book")
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

#import "Fur.h"

static const GLint    kShells            = 10;
static const GLfloat  kFurHeight         = 0.25f;
static const GLfloat  kRatio             = 40.0f; // (float)kShells / kFurHeight;
static const GLfloat  kShellTransparency = 0.3f;

@implementation Fur

- (void) getTextures
{
	noiseTexture  = [self loadTextureFromResource: @"Noise" ];
	colorTexture  = [self loadTextureFromResource: @"Leopard" ];
} // getTextures

- (void) getUniforms
{
	glUseProgramObjectARB(programObject);
	
	glUniform1fARB([self getUniformLocation:programObject uniformName:"ambient"], 0.2);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"lightPosition"], 0.0, 0.0, 5.0);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"spacing"], 1);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"noiseTexture"], 0);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"colorTexture"], 1);
} // getUniforms

- (void) newSolidTeapotList
{
	static BOOL teapotInited = NO;
	
	if( !teapotInited )
	{
		teapotInited = YES;
		
		solidTeapotDisplayList = glGenLists(1);
		
		glNewList(solidTeapotDisplayList, GL_COMPILE);
				
			[model drawModel:kModelSolidTeapot];
				
		glEndList();
	} // if
} // newSolidTeapotList

- (void) drawSolidTeapotList
{
	GLint    i;
	GLint    furHeightLoc = [self getUniformLocation:programObject uniformName:"furHeight"];
	GLfloat  v0;
	
	for (i = 1; i < kShells; i++)
	{
		v0 = (GLfloat)i / kRatio;
		
		glUniform1fARB(furHeightLoc, v0);
		glCallList(solidTeapotDisplayList);
	} // for
} // drawSolidTeapotList

- (void) initLazy
{
	[super initLazy];

	// Setup GLSL
	
	// Here we get a new model
	
	model = [[Models alloc] init];
	
	// get all the textures

	[self getTextures];
	
	// Load vertex and fragment shaders

	[self loadShadersFromResource:@"Fur" ];

	// Setup uniforms
	
	[self getUniforms];
	
	// Create a display list for the teapot (especially important with the number of
	// teapots per frame in this shell-based approach)
	
	[self newSolidTeapotList];
} // initLazy

- (void) dealloc
{
	glDeleteTextures(1, &noiseTexture);
	glDeleteTextures(1, &colorTexture);
	
	glDeleteLists(solidTeapotDisplayList, 1);
	
	[model dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Fur";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Fur" ofType: @"rtf"];
} // descriptionFilename

- (void) renderFrameInitialSetup
{
	glDisable(GL_TEXTURE_3D);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
} // renderFrameInitialSetup

- (void) renderFrameMoreSetup
{
	GLint transparencyLoc = 0;
	GLint furHeightLoc    = 0;
	
	glColor3f(0.9, 0.65, 0.4);
	
	glEnable(GL_COLOR_MATERIAL);
	
	glCallList(solidTeapotDisplayList);
	
	glUseProgramObjectARB(programObject);
	
	glColor3f(1.0, 1.0, 1.0);
	
	glDisable(GL_COLOR_MATERIAL);
	
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, noiseTexture);
	
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, colorTexture);
	
	glActiveTexture(GL_TEXTURE0);
	
	glEnable(GL_BLEND);
	
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	transparencyLoc = [self getUniformLocation:programObject uniformName:"transparency"];
	furHeightLoc    = [self getUniformLocation:programObject uniformName:"furHeight"];

	glUniform1fARB(transparencyLoc, 1);
	glUniform1fARB(furHeightLoc, 0);
	
	glUniform1fARB(transparencyLoc, kShellTransparency);
	
	glEnable(GL_CULL_FACE);
} // renderFrameMoreSetup

- (void) renderFrame
{
	[super renderFrame];
	
	glPushAttrib(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_CURRENT_BIT);
	
		[self renderFrameInitialSetup];
		
		// Draw the skin before the fur
		
		[self renderFrameMoreSetup];
			
		[self drawSolidTeapotList];
		
		glUseProgramObjectARB(NULL);
	
	glPopAttrib();
} // renderFrame

@end
