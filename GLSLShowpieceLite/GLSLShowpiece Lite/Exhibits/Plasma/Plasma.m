//-------------------------------------------------------------------------
//
//	File: Plasma.m
//
//  Abstract: Plasma GLSL Exhibit
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

#import "Plasma.h"

@implementation Plasma

- (void) initPalette
{
	GLfloat   palette[512][3];
	GLfloat   x[3];
	GLint     i;

	for (i=0; i< 256;i++)
	{
		x[0] = (GLfloat)i;
		x[1] = 3.1415 * x[0];
		x[2] = x[1] / 256.0;
		
		palette[i][0] = 1.0f - sin(x[2]);
		palette[i][1] = (128.0f + 128.0f * sin(x[1] / 128.0))/384.0f;
		palette[i][2] = sin(x[2]);
	} // for
		
	glActiveTexture(GL_TEXTURE1);
	glGenTextures(1, &paletteID);
	glBindTexture(GL_TEXTURE_1D, paletteID);

	glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, 256, 0, GL_RGB, GL_FLOAT, palette);
	glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
} // initPalette

- (void) initPattern
{
	GLfloat  *pattern;
	GLfloat   f;
	GLfloat   x;
	GLfloat   y;
	GLsizei   size   = 128;
	GLsizei   width  = size;
	GLsizei   height = size;
	GLint     i;
	GLint     j;
	GLint     l;
	GLint     m;
	GLint     n;

	glActiveTexture(GL_TEXTURE0);
	glGenTextures(1, &patternID);
	glBindTexture(GL_TEXTURE_2D, patternID);

	// Create the pattern texture, use symmetry to get rid of the seams

	pattern = (GLfloat *)malloc(sizeof(GLfloat) * width * height * 3);
	
	if ( pattern != NULL )
	{
		for (i = 0; i < 64; i++)
		{
			y = (GLfloat)i;
			
			for (j=0; j< 64; j++)
			{
				x = (GLfloat) j;
				f = 0.25*(sin(x/16.0) + sin(y/16.0) + sin((x+y)/16.0) + sin(sqrtf(x*x+y*y)/8.0));
				
				l = i * size;
				m = ( 127 - i ) * size;
				n = 127 - j;
				
				pattern[l+j] = f;
				pattern[l+n] = f;
				pattern[m+j] = f;
				pattern[m+n] = f;
			} // for
		} // for

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_LUMINANCE, GL_FLOAT, pattern);
				
		free( pattern );
	} // if
} // initPattern

- (void) setupUniforms
{
	glUseProgramObjectARB(programObject);

	// Create the palette

	[self initPalette];
	
	// Create the plasma pattern
	
	[self initPattern];
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	glUniform3fARB([self getUniformLocation:programObject uniformName:"LightPosition"], 0.0, 0.0, 20.0);
	
	offsetUniform = [self getUniformLocation:programObject uniformName:"offset"];

	// Set the texture units for the samplers
	
	glUniform1iARB([self getUniformLocation:programObject uniformName:"pattern"], 0);
	glUniform1iARB([self getUniformLocation:programObject uniformName:"palette"], 1);
} // setupUniforms

- (void) initLazy
{
	[super initLazy];
	
	// Setup GLSL

	// Here we get a new model
	
	model = [[Models alloc] init];
	
	// Load vertex and fragment shaders
	
	[self loadShadersFromResource:@"Plasma" ];
		
	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	glDeleteTextures(1, &patternID);
	glDeleteTextures(1, &paletteID);

	[model dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Plasma";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Plasma" ofType: @"rtf"];
} // descriptionFilename

- (void) updateOffset
{
	offset += 1.0/256.0;
	
	if (offset > 1.0)
	{
		offset = 0;
	} // if
} // updateOffset

- (void) renderFrame
{
	[super renderFrame];

	glUseProgramObjectARB(programObject);

	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_1D, paletteID);
	
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, patternID);

	glUniform1fvARB(offsetUniform, 1,&offset);
	
	[self updateOffset];
	
	[model drawModel:kModelSolidTeapot];

	glUseProgramObjectARB(NULL);
} // renderFrame

@end
