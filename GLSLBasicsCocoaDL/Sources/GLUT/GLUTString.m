//---------------------------------------------------------------------------------------
//
//	File: GLUTString.m
//
//  Abstract: A simple utility class for drawing strings using glut
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
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
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#import <glut/glut.h>

#import "GLUTString.h"

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#define kNibble 4

static const GLuint kDoubleDecimals = kNibble * sizeof(GLdouble);
static const GLuint kFloatDecimals  = kNibble * sizeof(GLfloat);

static const GLuint kCharSize = sizeof(GLchar);

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

@implementation GLUTString

//---------------------------------------------------------------------------------------

- (id) initWithViewSizeAndDrawCoordinates:(const NSSize *)theSize 
							  coordinates:(const NSPoint *)theCoordinates
{
	self = [super init];
	
	if( self )
	{
		font   = GLUT_BITMAP_9_BY_15;
		width  = (GLsizei)theSize->width;
		height = (GLsizei)theSize->height;
		drawX  = (GLint)theCoordinates->x;
		drawY  = (GLint)theCoordinates->y;
		red    = 1.0f;
		green  = 1.0f;
		blue   = 1.0f;
	} // if
	
	return self;
} // init

//---------------------------------------------------------------------------------------

- (void) dealloc
{
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------------

- (void) setGLUTFont:(void *)theFont
{
	font = theFont;
} // setGLUTFont

//---------------------------------------------------------------------------------------

- (void) setGLUTFontColor:(const GLfloat *)theColors
{
	red   = theColors[0];
	green = theColors[1];
	blue  = theColors[2];
} // setGLUTFontColor

//---------------------------------------------------------------------------------------

- (void) setViewSize:(const NSSize *)theSize
{
	width  = (GLsizei)theSize->width;
	height = (GLsizei)theSize->height;
} // setViewSize

//---------------------------------------------------------------------------------------

- (void) setDrawCoordinates:(const NSPoint *)theCoordinates
{
	drawX  = (GLint)theCoordinates->x;
	drawY  = (GLint)theCoordinates->y;
} // setDrawCoordinates

//---------------------------------------------------------------------------------------

- (void) drawUTF8StringUsingGLUT:(const GLchar *)theString
{
	GLuint stringLength = strlen(theString);
	
	GLuint i;
	
	glPushAttrib(GL_TRANSFORM_BIT | GL_CURRENT_BIT);
	
		glMatrixMode(GL_PROJECTION);
		
		glPushMatrix();
		
			glLoadIdentity();
			
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT,0); 
			glOrtho(0, width, 0, height, -10.0, 10.0);
			
			glMatrixMode(GL_MODELVIEW);
			
			glPushMatrix();
			
				glLoadIdentity();
				
				glColor3f(red, green, blue);
				
				glRasterPos2i(drawX, drawY);
			
				for( i = 0; i < stringLength; i++ ) 
				{
					glutBitmapCharacter( font, theString[i] );
				} // for
			
			glPopMatrix();
			
			glMatrixMode(GL_PROJECTION);
		
		glPopMatrix();
	
	glPopAttrib();
} // drawUTF8StringUsingGLUT

//---------------------------------------------------------------------------------------

- (void) drawString:(NSString *)theString
{
	const char *str =[theString UTF8String];
	
	if( str != NULL )
	{
		[self drawUTF8StringUsingGLUT:str];
	} // if
} // drawString

//---------------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

