//---------------------------------------------------------------------------
//
//	File: OpenGLFBOUtilityToolKit.m
//
//  Abstract: A basic utility class for managing FBOs
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
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

//------------------------------------------------------------------------

#import <OpenGL/OpenGL.h>

#import "OpenGLAlertsUtilityToolkit.h"
#import "OpenGLFBOUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct FBOAttributes
{
	GLuint    framebuffer;		// Frame buffer
	GLuint    texture[2];		// FBO attached texture
	GLsizei   textureWidth;		// Texture width
	GLsizei   textureHeight;	// Texture height
	GLint     viewport[4];		// Viewport dimensions
	GLint     drawBuffer;       // Current draw buffer
	BOOL      fboIsInstalled;	// True if the fbo was installed
};

typedef struct FBOAttributes   FBOAttributes;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Get a new FBO --

//------------------------------------------------------------------------

static GLvoid CheckFrameBufferStatus( FBOAttributesRef theFBOAttributesRef )
{
	GLenum     theFBOStatus     = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
	GLboolean  theFBOStatusIsOk = GL_FALSE;
	
	if ( theFBOStatus == GL_FRAMEBUFFER_COMPLETE_EXT )
	{
		theFBOStatusIsOk = GL_TRUE;
	} // if
	else
	{
		OpenGLAlertsUtilityToolkit *alert = [OpenGLAlertsUtilityToolkit withAlertType:alertIsForOpenGLFBO];
		
		if ( alert )
		{
			[alert displayAlertBox:theFBOStatusIsOk];
		} // if
	} // else	
	
	theFBOAttributesRef->fboIsInstalled =		( theFBOAttributesRef->framebuffer != 0       )
											&&	( theFBOAttributesRef->texture[0]  != 0       )
											&&	( theFBOAttributesRef->texture[1]  != 0       )
											&&  ( theFBOStatusIsOk                 == GL_TRUE );
} // CheckFrameBufferStatus

//------------------------------------------------------------------------

static GLvoid CreateObjects( FBOAttributesRef theFBOAttributesRef )
{
	// glGenTextures returns n texture names in textures.  For
	// more details refer to:
	//
	// http://www.opengl.org/documentation/specs/man_pages/hardcopy/GL/html/gl/gentextures.html
	
	glGenTextures( 2, theFBOAttributesRef->texture );
	
	// For details on FBOs refer to:
	//
	// http://oss.sgi.com/projects/ogl-sample/registry/EXT/framebuffer_object.txt

	glGenFramebuffersEXT(1, &theFBOAttributesRef->framebuffer);
} // CreateObjects

//------------------------------------------------------------------------

static GLvoid InitializeTexture( const GLint theIndex, FBOAttributesRef theFBOAttributesRef )
{
	// For details on glBindTexture refer to:
	//
	// http://www.opengl.org/documentation/specs/man_pages/hardcopy/GL/html/gl/bindtexture.html
	
	glBindTexture( GL_TEXTURE_2D, theFBOAttributesRef->texture[theIndex] );
	
	// For details on glTexParameteri, and texture parameters 
	// GL_TEXTURE_MIN_FILTER, GL_TEXTURE_MAG_FILTER, GL_NEAREST, 
	// GL_TEXTURE_WRAP_S, and GL_TEXTURE_WRAP_T refer to:
	//
	// http://www.opengl.org/documentation/specs/man_pages/hardcopy/GL/html/gl/texparameter.html
	
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );

	// For details on glTexImage2D refer to:
	//
	// http://www.opengl.org/documentation/specs/man_pages/hardcopy/GL/html/gl/teximage2d.html
	
	glTexImage2D(	GL_TEXTURE_2D,							// target texture
					0,										// level-of-detail number
					GL_RGBA8,								// internal format
					theFBOAttributesRef->textureWidth,		// width of the texture image
					theFBOAttributesRef->textureHeight,		// height of the texture image
					0,										// width of the border
					GL_RGBA,								// format of the pixel data, you may use GL_BGRA_EXT
					GL_FLOAT,								// data type of the pixel data, you may use GL_UNSIGNED_INT_8_8_8_8_REV
					NULL );									// a pointer to the image data in memory
} // InitializeTextures

//------------------------------------------------------------------------
//
// Initialize both textures for color attachment
//	
//------------------------------------------------------------------------

static GLvoid InitializeTextures( FBOAttributesRef theFBOAttributesRef )
{
	InitializeTexture( 0, theFBOAttributesRef );
	InitializeTexture( 1, theFBOAttributesRef );
} // InitializeTextures

//------------------------------------------------------------------------

static GLvoid BindTexturesToFBO( FBOAttributesRef theFBOAttributesRef )
{
	// For details on FBOs refer to:
	//
	// http://oss.sgi.com/projects/ogl-sample/registry/EXT/framebuffer_object.txt

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, theFBOAttributesRef->framebuffer);

	// Specifying GL_COLOR_ATTACHMENTm_EXT enables drawing only to the
	// image attached to the framebuffer at GL_COLOR_ATTACHMENTm_EXT. 
	// Each GL_COLOR_ATTACHMENTm_EXT adheres to 
	//
	//		GL_COLOR_ATTACHMENTm_EXT = GL_COLOR_ATTACHMENT0_EXT + m.  
	//
	// The initial value of GL_DRAW_BUFFER for application-created 
	// framebuffer objects is GL_COLOR_ATTACHMENT0_EXT.


	glFramebufferTexture2DEXT(	GL_FRAMEBUFFER_EXT,					// Frame buffer target
								GL_COLOR_ATTACHMENT0_EXT,			// Output fragment color to image attached at color attachment point 0
								GL_TEXTURE_2D,						// Texture target
								theFBOAttributesRef->texture[0],	// Texture object 0
								0 );								// Mipmap level of the texture image to attach to the frame buffer

	glFramebufferTexture2DEXT(	GL_FRAMEBUFFER_EXT,					// Frame buffer target
								GL_COLOR_ATTACHMENT1_EXT,			// Output fragment color to image attached at color attachment point 1
								GL_TEXTURE_2D,						// Texture target
								theFBOAttributesRef->texture[1],	// Texture object 1
								0 );								// Mipmap level of the texture image to attach to the frame buffer

	CheckFrameBufferStatus( theFBOAttributesRef );
											
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
} // BindTexturesToFBO

//------------------------------------------------------------------------      

static GLvoid GetNewFBO( FBOAttributesRef theFBOAttributesRef )
{
	// Create objects
	
	CreateObjects( theFBOAttributesRef );
	
	// Initialize FBO textures

	InitializeTextures( theFBOAttributesRef );

	// Bind to FBO before checking status
	
	BindTexturesToFBO( theFBOAttributesRef );
} // GetNewFBO

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -- Handling opaque data reference memory --

//------------------------------------------------------------------------

static FBOAttributesRef CallocFBOAttributesRef( const GLsizei theTextureWidth, 
												const GLsizei theTextureHeight )
{
	FBOAttributesRef fboAttributes = (FBOAttributesRef)malloc( sizeof( FBOAttributes ) );
	
	if ( fboAttributes != NULL )
	{
		fboAttributes->textureWidth   = theTextureWidth;
		fboAttributes->textureHeight  = theTextureHeight;
		fboAttributes->texture[0]     = 0;
		fboAttributes->texture[1]     = 0;
		fboAttributes->viewport[0]    = 0;
		fboAttributes->viewport[1]    = 0;
		fboAttributes->viewport[2]    = 0;
		fboAttributes->viewport[3]    = 0;
		fboAttributes->drawBuffer     = 0;
		fboAttributes->framebuffer    = 0;
		fboAttributes->fboIsInstalled = NO;
	} // if
	
	return  fboAttributes;
} // CallocFBOAttributesRef

//------------------------------------------------------------------------

static GLvoid FreeFBOAttributesRef( FBOAttributesRef theFBOAttributesRef )
{
	// Delete the FBO textures
	
	if ( theFBOAttributesRef->texture[0] != 0 )
	{
		glDeleteTextures( 1, &theFBOAttributesRef->texture[0] );
	} // if

	if ( theFBOAttributesRef->texture[1] != 0 )
	{
		glDeleteTextures( 1, &theFBOAttributesRef->texture[1] );
	} // if

	// Delete the framebuffer object

	if ( theFBOAttributesRef->framebuffer != 0 )
	{
		glDeleteFramebuffersEXT( 1, &theFBOAttributesRef->framebuffer );
	} // if
	
	// Delete the reference to the opaque data structure

	if ( theFBOAttributesRef != NULL )
	{
		free( theFBOAttributesRef );
	} // if
	
	theFBOAttributesRef = NULL;
} // FreeFBOAttributesRef

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLFBOUtilityToolKit

//------------------------------------------------------------------------

- (id) initWithTextureSize:(NSSize)theTextureSize bounds:(NSRect)theBounds
{
	self = [super initWithBounds:theBounds];
	
	GLsizei  theTextureWidth  = (GLsizei)theTextureSize.width;
	GLsizei  theTextureHeight = (GLsizei)theTextureSize.height;
		
	fboAttributes = CallocFBOAttributesRef( theTextureWidth, theTextureHeight );
	
	if ( fboAttributes != NULL )
	{
		GetNewFBO( fboAttributes );
	} // if
	
	return self;
} // initWithTexture

//------------------------------------------------------------------------

- (void) dealloc
{
	// Delete OpenGL resources
	
	FreeFBOAttributesRef( fboAttributes );

	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------
//
// Copy to texture by writing into a second texture whilst reading
// from the first.
//
//------------------------------------------------------------------------

- (void) draw
{
	// Write into the second texture

	glDrawBuffer(GL_COLOR_ATTACHMENT1_EXT);

	// Read from the first texture
	
	glBindTexture(GL_TEXTURE_2D, fboAttributes->texture[0]);
} // draw

//------------------------------------------------------------------------
//
// Bind to FBO and draw into it.
//
//------------------------------------------------------------------------

- (void) bind
{
	// Save the current draw buffer
	
	glGetIntegerv(GL_DRAW_BUFFER, &fboAttributes->drawBuffer);
	
	// Cache the window viewport dimensions so we can reset them

	glGetIntegerv(GL_VIEWPORT, fboAttributes->viewport);
	
	// Enable the FBO
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboAttributes->framebuffer);
	
	// Write into the first texture
	
	glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);

	// Set the viewport to the dimensions of our texture
	
	glViewport( 0, 0, fboAttributes->textureWidth, fboAttributes->textureHeight );
} // bind

//------------------------------------------------------------------------

- (void) unbind
{
    // Restore the cached viewport dimensions
	
	glViewport(	fboAttributes->viewport[0], 
				fboAttributes->viewport[1], 
				fboAttributes->viewport[2], 
				fboAttributes->viewport[3] );

	// Disable the FBO
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	
	// Render to the cached draw buffer

    glDrawBuffer(fboAttributes->drawBuffer);

	// Read from the second texture
	
	glBindTexture(GL_TEXTURE_2D, fboAttributes->texture[1]);

	// Bind to the texture
	
	glEnable( GL_TEXTURE_2D );

		// Render a full-screen quad textured with the  
		// results of our computation.
		
		[self quads];

	glDisable( GL_TEXTURE_2D );
} // end

//------------------------------------------------------------------------

- (BOOL) installed
{
	return  fboAttributes->fboIsInstalled;
} // installed

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

