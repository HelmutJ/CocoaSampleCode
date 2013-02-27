/*

File: Gooch.m

Abstract: Gooch Exhibit

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
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

  Copyright (c) 2004-2006 Apple Computer, Inc., All rights reserved.

*/

#import "Gooch.h"

#define NUM_GOOCH_COLORS         3
#define GOOCH_TRANSITION_TIME   30
#define GOOCH_IDLE_TIME        250

static const GLfloat gooch_warm_colors[3][3] = {
	{ 0.6, 0.6, 0.0 },
	{ 1.0, 0.7, 0.1 },
	{ 0.5, 0.7, 0.2 },
};

static const GLfloat gooch_cool_colors[3][3] = {
	{ 0.0, 0.0, 0.6 },
	{ 0.3, 0.1, 0.5 },
	{ 0.0, 0.0, 0.5 },
};

@implementation Gooch

- (id) init
{
	[super init];
	cur_color = 0;
	color_cycle_pause = GOOCH_IDLE_TIME;

	memcpy(warm, gooch_warm_colors[cur_color], sizeof(warm));
	memcpy(cool, gooch_cool_colors[cur_color], sizeof(cool));
	
	return self;
}

- (void) initLazy
{
	[super initLazy];
	
	/* Setup GLSL */
   {
      NSBundle *bundle;
      NSString *vertex_string, *fragment_string;

      bundle = [NSBundle bundleForClass: [self class]];

		/* Load vertex and fragment shader */
      vertex_string   = [bundle pathForResource: @"Gooch" ofType: @"vert"];
      vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
      fragment_string = [bundle pathForResource: @"Gooch" ofType: @"frag"];
      fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load Gooch");
			
		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
		glUniform3fvARB(glGetUniformLocationARB(program_object, "WarmColor"), 1, warm);
		glUniform3fvARB(glGetUniformLocationARB(program_object, "CoolColor"), 1, cool);
		glUniform3fARB(glGetUniformLocationARB(program_object, "SurfaceColor"), 0.75, 0.75, 0.75);
		glUniform3fARB(glGetUniformLocationARB(program_object, "LightPosition"), 0.0, 10.0, 0.0);
		glUniform1fARB(glGetUniformLocationARB(program_object, "DiffuseWarm"), 0.4);
		glUniform1fARB(glGetUniformLocationARB(program_object, "DiffuseCool"), 0.4);
	}

}

- (void) dealloc
{
	[super dealloc];
}

- (NSString *) name
{
	return @"Gooch";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
   string = [bundle pathForResource: @"Gooch" ofType: @"rtf"];
	
	return string;
}

- (void) renderFrame
{
	[super renderFrame];

	glUseProgramObjectARB(program_object);
	
	/* Animate through the different warm and cool colors */
	if((--color_cycle_pause) < 0)
	{
		if(color_cycle_pause > -GOOCH_TRANSITION_TIME)
		{
			float lerp = (float)color_cycle_pause / (float)(-GOOCH_TRANSITION_TIME);
			int nextColor = (cur_color == (NUM_GOOCH_COLORS-1)) ? 0 : cur_color+1;

			warm[0] = gooch_warm_colors[nextColor][0] * lerp + gooch_warm_colors[cur_color][0] * (1.0f-lerp);
			warm[1] = gooch_warm_colors[nextColor][1] * lerp + gooch_warm_colors[cur_color][1] * (1.0f-lerp);
			warm[2] = gooch_warm_colors[nextColor][2] * lerp + gooch_warm_colors[cur_color][2] * (1.0f-lerp);

			cool[0] = gooch_cool_colors[nextColor][0] * lerp + gooch_cool_colors[cur_color][0] * (1.0f-lerp);
			cool[1] = gooch_cool_colors[nextColor][1] * lerp + gooch_cool_colors[cur_color][1] * (1.0f-lerp);
			cool[2] = gooch_cool_colors[nextColor][2] * lerp + gooch_cool_colors[cur_color][2] * (1.0f-lerp);
		}
		else
		{
			color_cycle_pause = GOOCH_IDLE_TIME;
			cur_color = (cur_color == (NUM_GOOCH_COLORS-1)) ? 0 : cur_color+1;
		}

		glUniform3fvARB(glGetUniformLocationARB(program_object, "WarmColor"), 1, warm);
		glUniform3fvARB(glGetUniformLocationARB(program_object, "CoolColor"), 1, cool);
	}

	teapot(16, 0.5, GL_FILL);
	
	glUseProgramObjectARB(NULL);

	/* Draw the silhouette edges */
	glPushAttrib(GL_COLOR_BUFFER_BIT | GL_POLYGON_BIT | GL_LINE_BIT | GL_CURRENT_BIT);

	glLineWidth(4.0);
	glColor3f(0,0,0);
	glCullFace(GL_FRONT);
	glEnable(GL_CULL_FACE);
	glEnable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	teapot(16, 0.5, GL_FILL);

	glPopAttrib();
}

@end
