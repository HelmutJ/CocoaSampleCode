/*

File: Plasma.m

Abstract: Plasma Exhibit

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

#import "Plasma.h"

@implementation Plasma

- (id) init
{
	[super init];
	
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
		vertex_string   = [bundle pathForResource: @"Plasma" ofType: @"vert"];
		vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
		fragment_string = [bundle pathForResource: @"Plasma" ofType: @"frag"];
		fragment_string = [NSString stringWithContentsOfFile: fragment_string];
		if ([self loadVertexShader: vertex_string fragmentShader: fragment_string])
			NSLog(@"Failed to load Plasma");

		/* Setup uniforms */
		glUseProgramObjectARB(program_object);
	}

	{
		GLfloat palette[512][3];
		GLfloat *pattern;
		/* Create the palette */
		{
			int i;

			for (i=0; i< 256;i++)
			{
				float x = i;
				palette[i][0] = 1.0f - sin(3.1415 * x / 256.0);
				palette[i][1] = (128.0f + 128.0f * sin(3.1415 * x / 128.0))/384.0f;
				palette[i][2] = sin(3.1415 * x / 256.0);
			}
		}
		glActiveTexture(GL_TEXTURE1);
		glGenTextures(1, &paletteID);
		glBindTexture(GL_TEXTURE_1D, paletteID);
		glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, 256, 0, GL_RGB, GL_FLOAT, palette);
		glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		/* Create the pattern texture, use symmetry to get rid of the seams */
		{
			int i,j;
			pattern = malloc(sizeof(GLfloat) * 128*128*3);
			for (i = 0; i < 64; i++)
			{
				float y = (float)i;
				for (j=0; j< 64; j++)
				{
					float x = (float) j;
					float f = 0.25*(sin(x/16.0) + sin(y/16.0) + sin((x+y)/16.0) + sin(sqrtf(x*x+y*y)/8.0));
					pattern[i*128+j] = f;
					pattern[i*128+(127-j)] = f;
					pattern[(127-i)*128+j] = f;
					pattern[(127-i)*128+(127-j)] = f;
				}
			}
			glActiveTexture(GL_TEXTURE0);
			glGenTextures(1, &patternID);
			glBindTexture(GL_TEXTURE_2D, patternID);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128, 128, 0, GL_LUMINANCE, GL_FLOAT, pattern);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			free(pattern);
		}
	}

	glUniform3fARB(glGetUniformLocationARB(program_object, "LightPos"), 0.0, 0.0, 20.0);
	offset_uniform = glGetUniformLocationARB(program_object, "offset");

	/* Set the texture units for the samplers */
	glUniform1iARB(glGetUniformLocationARB(program_object, "pattern"), 0);
	glUniform1iARB(glGetUniformLocationARB(program_object, "palette"), 1);
}

- (void) dealloc
{
	[super dealloc];
	glDeleteTextures(1, &patternID);
	glDeleteTextures(1, &paletteID);
}

- (NSString *) name
{
	return @"Plasma";
}

- (NSString *) descriptionFilename
{
	NSBundle *bundle;
	NSString *string;
	bundle = [NSBundle bundleForClass: [self class]];
	string = [bundle pathForResource: @"Plasma" ofType: @"rtf"];

	return string;
}

- (void) renderFrame
{
	[super renderFrame];

	glUseProgramObjectARB(program_object);

	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_1D, paletteID);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, patternID);

	glUniform1fvARB(offset_uniform, 1,&offset);
	offset = offset + (1.0/256.0);
	if (offset > 1.0)
		offset = 0;
	teapot(16, 0.5, GL_FILL);

	glUseProgramObjectARB(NULL);
}

@end
