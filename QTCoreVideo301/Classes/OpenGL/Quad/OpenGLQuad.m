//---------------------------------------------------------------------------
//
//	File: OpenGLQuad.m
//
//  Abstract: Class that implements a method for generating a quad.
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
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "AlertPanelKit.h"
#import "OpenGLQuad.h"

//---------------------------------------------------------------------------

//-------------------------------------------------------------------------

struct OpenGLTextureCoordinates
{
	GLfloat topLeft[2];
	GLfloat	topRight[2];
	GLfloat	bottomRight[2];
	GLfloat	bottomLeft[2];
};

typedef struct OpenGLTextureCoordinates   OpenGLTextureCoordinates;
typedef        OpenGLTextureCoordinates  *OpenGLTextureCoordinatesRef;

//---------------------------------------------------------------------------

struct OpenGLQuadAttributes
{
	GLuint   displayList;
	GLsizei  range;
	GLfloat  width;
	GLfloat  height;
	GLfloat  aspect;
};

typedef struct OpenGLQuadAttributes  OpenGLQuadAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLQuad

//------------------------------------------------------------------------

- (void) initQuadDisplayList:(GLsizei)theRange
{
	quad->range       = theRange;
	quad->displayList = glGenLists( theRange );
	
	glNewList( quad->displayList, GL_COMPILE );
	
		glBegin( GL_QUADS );
		
			glTexCoord2f( 0.0f, 0.0f );
			glVertex2f( -1.0f, -1.0f );
			
			glTexCoord2f( 0.0f, quad->height );
			glVertex2f( -1.0f,  1.0f );
			
			glTexCoord2f( quad->width, quad->height );
			glVertex2f( 1.0f,  1.0f );
			
			glTexCoord2f( quad->width, 0.0f );
			glVertex2f( 1.0f, -1.0f );
		
		glEnd();
	
	glEndList();
} // initQuadDisplayList

//------------------------------------------------------------------------

- (void) initQuadDisplayListWithCleanTexCoords:(OpenGLTextureCoordinatesRef)theTexCoords 
										 range:(GLsizei)theRange
{
	quad->range       = theRange;
	quad->displayList = glGenLists( theRange );
	
	glNewList( quad->displayList, GL_COMPILE );
	
		glBegin( GL_QUADS );
		
			glTexCoord2fv( theTexCoords->bottomLeft );
			glVertex2i( -1, -1 );
			
			glTexCoord2fv( theTexCoords->topLeft );
			glVertex2i( -1,  1 );
			
			glTexCoord2fv( theTexCoords->topRight );
			glVertex2i( 1,  1 );
			
			glTexCoord2fv( theTexCoords->bottomRight ); 
			glVertex2i( 1, -1 );
		
		glEnd();
	
	glEndList();
} // initQuadDisplayList

//------------------------------------------------------------------------

- (void) initQuadSize:(const NSSize *)theSize
{
	if ( ( theSize->width <= 0.0f ) || ( theSize->height <= 0.0f ) )
	{
		quad->width  = 1920;	// Default texture width for a HD movie
		quad->height = 820;		// Default texture height for a HD movie
	} // if
	else
	{
		quad->width  = theSize->width;
		quad->height = theSize->height;
	} // else
} // initQuadSize

//------------------------------------------------------------------------

- (id) initQuadWithSize:(const NSSize *)theSize 
				  range:(const GLsizei)theRange
{
	self = [super initMemoryWithType:kMemAlloc 
								size:sizeof(OpenGLQuadAttributes)];
	
	if ( self )
	{
		quad = (OpenGLQuadAttributesRef)[self pointer];
		
		if ( [self isPointerValid] )
		{
			[self initQuadSize:theSize];
			[self initQuadDisplayList:theRange];
			
			quad->aspect = quad->width / quad->height;
		} // if
		else
		{
			[[AlertPanelKit withTitle:@"OpenGL Quad" 
							  message:@"Failure Allocating Memory For OpenGL Quad Attributes using size"
								 exit:NO] displayAlertPanel];
		} // else
	} // if
	
	return  self;
} // initQuadWithSize

//------------------------------------------------------------------------

+ (id) quadWithSize:(const NSSize *)theSize 
			  range:(const GLsizei)theRange

{
	return  [[[OpenGLQuad allocWithZone:[self zone]] initQuadWithSize:theSize 
																range:theRange] autorelease];
} // quadWithSize

//------------------------------------------------------------------------

- (id) initQuadWithCleanTextureCoordinates:(CVOpenGLTextureRef)theTexture 
									 range:(const GLsizei)theRange
{
	if ( theTexture != NULL )
	{
		self = [super initMemoryWithType:kMemAlloc 
									size:sizeof(OpenGLQuadAttributes)];
		
		if ( self )
		{
			quad = (OpenGLQuadAttributesRef)[self pointer];
			
			if ( [self isPointerValid] )
			{
				OpenGLTextureCoordinates texCoords;
				
				CVOpenGLTextureGetCleanTexCoords(	theTexture, 
												 texCoords.bottomLeft, 
												 texCoords.bottomRight, 
												 texCoords.topRight, 
												 texCoords.topLeft );
				
				GLfloat width  = texCoords.topRight[0] - texCoords.topLeft[0];
				GLfloat height = texCoords.topRight[1] - texCoords.bottomRight[1];
				NSSize  size   = NSMakeSize( width, height );
				
				[self initQuadSize:&size];
				[self initQuadDisplayListWithCleanTexCoords:&texCoords range:theRange];
				
				quad->aspect = quad->width / quad->height;
			} // if
			else
			{
				[[AlertPanelKit withTitle:@"OpenGL Quad" 
								  message:@"Failure Allocating Memory For OpenGL Quad Attributes using Core Video texture reference"
									 exit:NO] displayAlertPanel];
			} // else
		} // if
	} // if
	else
	{
		[[AlertPanelKit withTitle:@"OpenGL Quad" 
						  message:@"Can not generate a quad using a NULL Core Video texture reference"
							 exit:NO] displayAlertPanel];
	} // else
	
	return  self;
} // initQuadWithSize

//------------------------------------------------------------------------

+ (id) quadWithCleanTextureCoordinates:(CVOpenGLTextureRef)theTexture 
								 range:(const GLsizei)theRange

{
	return  [[[OpenGLQuad allocWithZone:[self zone]] initQuadWithCleanTextureCoordinates:theTexture 
																				   range:theRange] autorelease];
} // quadWithCleanTextureCoordinates

//------------------------------------------------------------------------

- (void) dealloc
{
	if ( quad->displayList )
	{
		glDeleteLists( quad->displayList, quad->range );
	} // if
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (void) draw
{
	glScalef( quad->aspect, 1.0f, 1.0f );
	
	glCallList( quad->displayList );
} // callList

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------


