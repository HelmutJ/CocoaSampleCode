//-------------------------------------------------------------------------
//
//	File: Gooch.m
//
//  Abstract: Gooch GLSL Exhibit
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

#import "Gooch.h"

static const GLint kNumGoochColors      = 3;
static const GLint kGoochTransitionTime = 30;
static const GLint kGoochIdleTime       = 250;

static const GLfloat kGoochWarmColors[3][3] =	{	
													{ 0.6, 0.6, 0.0 },
													{ 1.0, 0.7, 0.1 },
													{ 0.5, 0.7, 0.2 }
												};

static const GLfloat kGoochCoolColors[3][3] =	{
													{ 0.0, 0.0, 0.6 },
													{ 0.3, 0.1, 0.5 },
													{ 0.0, 0.0, 0.5 }
												};

@implementation Gooch

- (void) setupColors
{
	currentColor    = 0;
	colorCyclePause = kGoochIdleTime;

	memmove(warm, kGoochWarmColors[currentColor], sizeof(warm));
	memmove(cool, kGoochCoolColors[currentColor], sizeof(cool));
} // setupColors

- (void) setupUniforms
{
	glUseProgramObjectARB(programObject);
	
	glUniform3fvARB([self getUniformLocation:programObject uniformName:"WarmColor"], 1, warm);
	glUniform3fvARB([self getUniformLocation:programObject uniformName:"CoolColor"], 1, cool);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"SurfaceColor"], 0.75, 0.75, 0.75);
	glUniform3fARB([self getUniformLocation:programObject uniformName:"LightPosition"], 0.0, 10.0, 0.0);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"DiffuseWarm"], 0.4);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"DiffuseCool"], 0.4);
} // setupUniforms

- (void) initLazy
{
	[super initLazy];
	
	// Setup GLSL

	// Here we get a new model
	
	model = [[Models alloc] init];

	// Load vertex and fragment shader
	
	[self loadShadersFromResource:@"Gooch" ];
	
	// Initialize warm & cool colors
	
	[self setupColors];

	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	[model dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Gooch";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Gooch" ofType: @"rtf"];;
} // descriptionFilename

- (void) animateColors
{
	if((--colorCyclePause) < 0)
	{
		if(colorCyclePause > -kGoochTransitionTime)
		{
			GLfloat lerp      = (float)colorCyclePause / (float)(-kGoochTransitionTime);
			GLint   nextColor = (currentColor == (kNumGoochColors-1)) ? 0 : currentColor+1;

			warm[0] = kGoochWarmColors[nextColor][0] * lerp + kGoochWarmColors[currentColor][0] * (1.0f-lerp);
			warm[1] = kGoochWarmColors[nextColor][1] * lerp + kGoochWarmColors[currentColor][1] * (1.0f-lerp);
			warm[2] = kGoochWarmColors[nextColor][2] * lerp + kGoochWarmColors[currentColor][2] * (1.0f-lerp);

			cool[0] = kGoochCoolColors[nextColor][0] * lerp + kGoochCoolColors[currentColor][0] * (1.0f-lerp);
			cool[1] = kGoochCoolColors[nextColor][1] * lerp + kGoochCoolColors[currentColor][1] * (1.0f-lerp);
			cool[2] = kGoochCoolColors[nextColor][2] * lerp + kGoochCoolColors[currentColor][2] * (1.0f-lerp);
		} // if
		else
		{
			colorCyclePause = kGoochIdleTime;
			currentColor = (currentColor == (kNumGoochColors-1)) ? 0 : currentColor+1;
		} // else

		glUniform3fvARB([self getUniformLocation:programObject uniformName:"WarmColor"], 1, warm);
		glUniform3fvARB([self getUniformLocation:programObject uniformName:"CoolColor"], 1, cool);
	} // if
} // 

- (void) drawSilhouetteEdges
{
	glPushAttrib(GL_COLOR_BUFFER_BIT | GL_POLYGON_BIT | GL_LINE_BIT | GL_CURRENT_BIT);

	glLineWidth(4.0);
	glColor3f(0,0,0);
	glCullFace(GL_FRONT);
	
	glEnable(GL_CULL_FACE);
	glEnable(GL_LINE_SMOOTH);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnable(GL_BLEND);
	
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
} // drawSilhouetteEdges

- (void) renderFrame
{
	[super renderFrame];

	glUseProgramObjectARB(programObject);

	// Animate through the different warm and cool colors
	
	[self animateColors];
	
	// Pick a geometry to use
		
	[model drawModel:kModelSolidTeapot];

	glUseProgramObjectARB(NULL);

	// Draw the silhouette edges

	[self drawSilhouetteEdges];
	
	[model drawModel:kModelSolidTeapot];
		
	glPopAttrib();
} // renderFrame

@end
