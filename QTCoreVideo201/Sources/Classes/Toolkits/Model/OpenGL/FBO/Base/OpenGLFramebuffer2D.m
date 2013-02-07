//---------------------------------------------------------------------------
//
//	File: OpenGLFramebuffer2D.m
//
//  Abstract: Utility class for managing FBOs
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
//  Copyright (c) 2008-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLImage2DAuthor.h"
#import "OpenGLTexture2D.h"
#import "OpenGLFramebuffer2DStatus.h"
#import "OpenGLFramebuffer2D.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLImage2DProps
{
    GLint    level;         // Texture level
	GLenum   format;		// Texture format
	GLenum   target;		// Texture target
	GLuint   name;          // Texture id
	GLuint   size;          // Texture size
};

typedef struct OpenGLImage2DProps  OpenGLImage2DProps;

//---------------------------------------------------------------------------

struct OpenGLFramebuffer
{
	GLenum   attachment;	// Color attachment "n" extension
	GLenum   target;		// Framebuffer and texture target respectively
	GLuint   name;          // Framebuffer & texture ids respectively
	BOOL     isValid;		// Framebuffer status
};

typedef struct OpenGLFramebuffer  OpenGLFramebuffer;

//---------------------------------------------------------------------------

struct OpenGLRenderbuffer
{
	GLuint   name;			// Depth renderbuffer id
	GLenum   internal;      // Renderbuffer internal format
	GLenum   target;        // Target type for renderbuffer
	GLenum   attachment;	// Type of frameBufferAttachment for renderbuffer
};

typedef struct OpenGLRenderbuffer  OpenGLRenderbuffer;

//---------------------------------------------------------------------------

struct OpenGLViewport
{
	GLint    x;			// lower left x coordinate
	GLint    y;			// lower left y coordinate
	GLsizei  width;		// viewport height
	GLsizei  height;	// viewport width
};

typedef struct OpenGLViewport  OpenGLViewport;

//---------------------------------------------------------------------------

struct OpenGLOrthoProj
{
	GLdouble left;		// left vertical clipping plane
	GLdouble right;		// right vertical clipping plane
	GLdouble bottom;	// bottom horizontal clipping plane
	GLdouble top;		// top horizontal clipping plane
	GLdouble zNear;		// nearer depth clipping plane
	GLdouble zFar;		// farther depth clipping plane
};

typedef struct OpenGLOrthoProj  OpenGLOrthoProj;

//---------------------------------------------------------------------------

struct OpenGLFramebuffer2DData
{
    GLvoid                 *buffer;             // Either base address of the I?o surface or memory
    OpenGLImage2DAuthor    *reader;             // Read pixels object
    OpenGLTexture2D        *texture;			// Texture bound to the framebuffer
	OpenGLOrthoProj         orthographic;		// Data for orthographic projection
	OpenGLViewport          viewport;			// FBO viewport dimensions
    OpenGLImage2DProps      image;              // Image 2D properties
	OpenGLFramebuffer       framebuffer;		// Framebuffer object attributes
	OpenGLRenderbuffer      renderbuffer;		// Depth render buffer
};

typedef struct OpenGLFramebuffer2DData  OpenGLFramebuffer2DData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDeleteRenderbuffer( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	if( pFramebuffer2D->renderbuffer.name )
	{
		glDeleteRenderbuffers( 1, &pFramebuffer2D->renderbuffer.name );
	} // if
} // OpenGLFramebuffer2DDeleteRenderbuffer

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDeleteFramebuffer( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	if( pFramebuffer2D->framebuffer.name )
	{
		glDeleteFramebuffers( 1, &pFramebuffer2D->framebuffer.name );
	} // if
} // OpenGLFramebuffer2DDeleteFramebuffer

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDeleteTexture( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	if( pFramebuffer2D->texture )
	{
		[pFramebuffer2D->texture release];
        
        pFramebuffer2D->texture = nil;
	} // if
} // OpenGLFramebuffer2DDeleteTexture

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDeleteReader( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	if( pFramebuffer2D->reader )
	{
		[pFramebuffer2D->reader release];
        
        pFramebuffer2D->reader = nil;
	} // if
} // OpenGLFramebuffer2DDeleteReader

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDeleteAssets( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
    OpenGLFramebuffer2DDeleteRenderbuffer( pFramebuffer2D );
    OpenGLFramebuffer2DDeleteFramebuffer( pFramebuffer2D );
    OpenGLFramebuffer2DDeleteTexture( pFramebuffer2D );
    OpenGLFramebuffer2DDeleteReader( pFramebuffer2D );
} // OpenGLFramebuffer2DDeleteAssets

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDelete( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	if( pFramebuffer2D != NULL )
	{
		OpenGLFramebuffer2DDeleteAssets( pFramebuffer2D );
		
		free( pFramebuffer2D );
        
        pFramebuffer2D = NULL;
	} // if
} // OpenGLFramebuffer2DDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DInitParams(OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    pFramebuffer2D->reader  = nil;
    pFramebuffer2D->texture = nil;
    pFramebuffer2D->buffer  = NULL;
    
    pFramebuffer2D->image.target = 0;
    pFramebuffer2D->image.level  = 0;
    pFramebuffer2D->image.format = 0;
	pFramebuffer2D->image.name   = 0;
	pFramebuffer2D->image.size   = 0;
    
    pFramebuffer2D->framebuffer.name       = 0;
	pFramebuffer2D->framebuffer.target     = GL_FRAMEBUFFER;
	pFramebuffer2D->framebuffer.attachment = GL_COLOR_ATTACHMENT0;
	pFramebuffer2D->framebuffer.isValid    = NO;
    
	pFramebuffer2D->renderbuffer.name       = 0;
	pFramebuffer2D->renderbuffer.target     = GL_RENDERBUFFER;
	pFramebuffer2D->renderbuffer.internal   = GL_DEPTH_COMPONENT32;
	pFramebuffer2D->renderbuffer.attachment = GL_DEPTH_ATTACHMENT;
    
	pFramebuffer2D->viewport.x      = 0;
	pFramebuffer2D->viewport.y      = 0;
	pFramebuffer2D->viewport.width  = 0;
	pFramebuffer2D->viewport.height = 0;
    
	pFramebuffer2D->orthographic.left   =  0;
	pFramebuffer2D->orthographic.right  =  0;
	pFramebuffer2D->orthographic.bottom =  0;
	pFramebuffer2D->orthographic.top    =  0;
	pFramebuffer2D->orthographic.zNear  = -10.0;
	pFramebuffer2D->orthographic.zFar   =  10.0;
} // OpenGLFramebuffer2DInitParams

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DCreateTexture(const NSSize *pSize,
                                             const GLenum target,
                                             const GLenum format,
                                             const GLint level,
                                             OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
	pFramebuffer2D->texture = [[OpenGLTexture2D alloc] initTexture2DWithSize:pSize
                                                                      target:target
                                                                       level:level
                                                                      format:format
                                                                        hint:0
                                                                      border:NO];
    
    if( pFramebuffer2D->texture )
    {
        pFramebuffer2D->image.name   = [pFramebuffer2D->texture texture];
        pFramebuffer2D->image.size   = [pFramebuffer2D->texture size];
        pFramebuffer2D->image.target = target;
        pFramebuffer2D->image.level  = level;
        pFramebuffer2D->image.format = format;
        
        pFramebuffer2D->viewport.width  = [pFramebuffer2D->texture width];
        pFramebuffer2D->viewport.height = [pFramebuffer2D->texture height];
        
        pFramebuffer2D->orthographic.right = pFramebuffer2D->viewport.width;
        pFramebuffer2D->orthographic.top   = pFramebuffer2D->viewport.height;
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL FBO 2D - Failed creating a texture with PBO!" );
    } // else
    
    return( pFramebuffer2D->texture != nil );
} // OpenGLFramebuffer2DCreateTexture

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DCreateReader(OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    NSSize size = NSMakeSize((CGFloat)pFramebuffer2D->viewport.width, 
                             (CGFloat)pFramebuffer2D->viewport.height);
    
    pFramebuffer2D->reader = [[OpenGLImage2DAuthor alloc] initImage2DAuthorWithSize:&size
                                                                              usage:GL_DYNAMIC_READ
                                                                             format:pFramebuffer2D->image.format];
    
    return( pFramebuffer2D->reader != nil );
} // OpenGLFramebuffer2DCreateReader

//---------------------------------------------------------------------------
//
// Create the depth render buffer
//
//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DCreateRenderbuffer( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	glGenRenderbuffers(1, &pFramebuffer2D->renderbuffer.name);
	
    BOOL success = pFramebuffer2D->renderbuffer.name != 0;
    
	if( success )
	{
		glBindRenderbuffer(pFramebuffer2D->renderbuffer.target, 
                           pFramebuffer2D->renderbuffer.name);
		
		glRenderbufferStorage(pFramebuffer2D->renderbuffer.target, 
                              pFramebuffer2D->renderbuffer.internal, 
                              pFramebuffer2D->viewport.width, 
                              pFramebuffer2D->viewport.height);
		
		glBindRenderbuffer(pFramebuffer2D->renderbuffer.target, 0);
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL FBO 2D - Failed creating a render buffer!" );
    } // else
	
	return( success );
} // OpenGLFramebuffer2DCreateRenderbuffer

//---------------------------------------------------------------------------
//
// Bind to FBO before checking status
//
//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DCreateFramebuffer( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{	
	glGenFramebuffers(1, &pFramebuffer2D->framebuffer.name);
	
	if( pFramebuffer2D->framebuffer.name )
	{
		glBindRenderbuffer(pFramebuffer2D->renderbuffer.target, 
                           pFramebuffer2D->renderbuffer.name);
        
		glBindFramebuffer(pFramebuffer2D->framebuffer.target, 
                          pFramebuffer2D->framebuffer.name);
		
		glFramebufferTexture2D(pFramebuffer2D->framebuffer.target, 
                               pFramebuffer2D->framebuffer.attachment, 
                               pFramebuffer2D->image.target, 
                               pFramebuffer2D->image.name,
                               pFramebuffer2D->image.level);
		
		glFramebufferRenderbuffer(pFramebuffer2D->framebuffer.target, 
                                  pFramebuffer2D->renderbuffer.attachment, 
                                  pFramebuffer2D->renderbuffer.target, 
                                  pFramebuffer2D->renderbuffer.name);
		
		pFramebuffer2D->framebuffer.isValid = [[OpenGLFramebuffer2DStatus statusWithTarget:pFramebuffer2D->framebuffer.target 
                                                                                      exit:YES] isComplete];
		
		glBindRenderbuffer(pFramebuffer2D->renderbuffer.target, 0);
		glBindFramebuffer(pFramebuffer2D->framebuffer.target, 0);
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL FBO 2D - Failed creating a frmae buffer!" );
    } // else
    
    return( pFramebuffer2D->framebuffer.isValid );
} // OpenGLFramebuffer2DCreateFramebuffer

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DCreateAssets(const NSSize *pSize,
                                            const GLenum target,
                                            const GLenum format,
                                            const GLint level,
                                            OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    BOOL success = NO;
    
    OpenGLFramebuffer2DInitParams(pFramebuffer2D);
    
    if( OpenGLFramebuffer2DCreateTexture(pSize, target, format, level, pFramebuffer2D) )
    {
        OpenGLFramebuffer2DCreateReader( pFramebuffer2D );
        
        if( OpenGLFramebuffer2DCreateRenderbuffer( pFramebuffer2D ) )
        {
            success = OpenGLFramebuffer2DCreateFramebuffer( pFramebuffer2D );
        } // if
    } // if
    
    return( success );
} // OpenGLFramebuffer2DCreateAssets

//---------------------------------------------------------------------------

static OpenGLFramebuffer2DDataRef OpenGLFramebuffer2DCreate(const NSSize *pSize,
                                                            const GLenum target,
                                                            const GLenum format,
                                                            const GLint level)
{
    OpenGLFramebuffer2DDataRef pFramebuffer2D = (OpenGLFramebuffer2DDataRef)calloc(1, sizeof(OpenGLFramebuffer2DData));
    
    if( pFramebuffer2D != NULL )
    {
        BOOL success = OpenGLFramebuffer2DCreateAssets(pSize, target, format, level, pFramebuffer2D);
        
        if( !success )
        {
            NSLog( @">> ERROR: OpenGL FBO 2D - Acquiring FBO Failed!" );
        } // if
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL FBO 2D - Allocating Memory For FBO Data Failed!" );
    } // else
    
    return( pFramebuffer2D );
} // OpenGLFramebuffer2DCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessor

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DSetSize(const NSSize *pSize,
                                       OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    BOOL success = pSize != NULL;
    
    if( success )
    {
        success =       (pSize->width  != pFramebuffer2D->viewport.width) 
        ||  (pSize->height != pFramebuffer2D->viewport.height);
        
        if( success )
        {
            success = [pFramebuffer2D->texture setSize:pSize];
            
            if( success )
            {
                pFramebuffer2D->image.name         = [pFramebuffer2D->texture texture];
                pFramebuffer2D->image.size         = [pFramebuffer2D->texture size];
                pFramebuffer2D->viewport.width     = [pFramebuffer2D->texture width];
                pFramebuffer2D->viewport.height    = [pFramebuffer2D->texture height];
                pFramebuffer2D->orthographic.right = pFramebuffer2D->viewport.width;
                pFramebuffer2D->orthographic.top   = pFramebuffer2D->viewport.height;
                
                NSSize size = NSMakeSize((CGFloat)pFramebuffer2D->viewport.width, 
                                         (CGFloat)pFramebuffer2D->viewport.height);
                
                [pFramebuffer2D->reader setSize:&size];
                
                OpenGLFramebuffer2DDeleteRenderbuffer(pFramebuffer2D);
                
                if( OpenGLFramebuffer2DCreateRenderbuffer(pFramebuffer2D) )
                {
                    OpenGLFramebuffer2DDeleteFramebuffer(pFramebuffer2D);
                    OpenGLFramebuffer2DCreateFramebuffer(pFramebuffer2D);
                } // if
            } // if
        } // if
    } // if
    
    return( success );
} // OpenGLFramebuffer2DSetSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------
//
// Reset the current viewport
//
//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DReset( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	glViewport(pFramebuffer2D->viewport.x, 
			   pFramebuffer2D->viewport.y, 
			   pFramebuffer2D->viewport.width, 
			   pFramebuffer2D->viewport.height);
	
	// select the projection matrix
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	// Orthographic projection
	
	glOrtho(pFramebuffer2D->orthographic.left, 
			pFramebuffer2D->orthographic.right, 
			pFramebuffer2D->orthographic.bottom, 
			pFramebuffer2D->orthographic.top, 
			pFramebuffer2D->orthographic.zNear, 
			pFramebuffer2D->orthographic.zFar);
	
	// Go back to texture and model-view modes
	
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
} // OpenGLFramebuffer2DReset

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DEnable( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
    glEnable( pFramebuffer2D->image.target );
    
    // bind buffers and make attachments
    
    glBindFramebuffer( pFramebuffer2D->framebuffer.target, pFramebuffer2D->framebuffer.name );
    glBindRenderbuffer( pFramebuffer2D->renderbuffer.target, pFramebuffer2D->renderbuffer.name );
    
    // reset the current viewport
    
    OpenGLFramebuffer2DReset( pFramebuffer2D );
} // OpenGLFramebuffer2DEnable

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DDisable( OpenGLFramebuffer2DDataRef pFramebuffer2D )
{
    glBindRenderbuffer( pFramebuffer2D->renderbuffer.target, 0 ); 
    glBindFramebuffer( pFramebuffer2D->framebuffer.target, 0 );
    
    glDisable( pFramebuffer2D->image.target );
} // OpenGLFramebuffer2DDisable

//---------------------------------------------------------------------------
//
// FBO readback using ReadPixels + PBO.  If successful, a valid pointer
// is returned.
//
//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DMap(OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    glBindFramebuffer(pFramebuffer2D->framebuffer.target, 
                      pFramebuffer2D->framebuffer.name);
    
    return( [pFramebuffer2D->reader map] );
} // OpenGLFramebuffer2DMap

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DUnmap(OpenGLFramebuffer2DDataRef pFramebuffer2D)
{
    BOOL success = [pFramebuffer2D->reader unmap];
    
    glBindFramebuffer(pFramebuffer2D->framebuffer.target, 0);
    
    return( success );
} // OpenGLFramebuffer2DRead

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLFramebuffer2D

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------
//
// Initialize on startup
//
//---------------------------------------------------------------------------

- (id) initFramebuffer2DWithSize:(const NSSize *)theSize
                          target:(const GLenum)theTarget
                          format:(const GLenum)theFormat
                           level:(const GLint)theLevel
{
	self = [super init];
	
	if( self )
	{
        mpFramebuffer2D = OpenGLFramebuffer2DCreate(theSize,
                                                    theTarget, 
                                                    theFormat, 
                                                    theLevel);
	} // if
	
	return  self;
} // initFramebuffer2DWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructors

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLFramebuffer2DDelete( mpFramebuffer2D );
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// Bind the texture attached to a framebuffer, to a quad or surface.
//
//---------------------------------------------------------------------------

- (void) bind
{
    [mpFramebuffer2D->texture bind];
} // bind

//---------------------------------------------------------------------------
//
// Unbind the texture attached to a framebuffer, from a quad or surface.
//
//---------------------------------------------------------------------------

- (void) unbind
{
    [mpFramebuffer2D->texture unbind];
} // unbind

//---------------------------------------------------------------------------
//
// Enable render-to-texture.
//
//---------------------------------------------------------------------------

- (void) enable
{
    OpenGLFramebuffer2DEnable( mpFramebuffer2D );
} // enable

//---------------------------------------------------------------------------
//
// Disable render-to-texture.
//
//---------------------------------------------------------------------------

- (void) disable
{
    OpenGLFramebuffer2DDisable( mpFramebuffer2D );
} // disable

//---------------------------------------------------------------------------

- (BOOL) map
{
    return( OpenGLFramebuffer2DMap(mpFramebuffer2D) );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( OpenGLFramebuffer2DUnmap(mpFramebuffer2D) );
} // unmap

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( [mpFramebuffer2D->reader buffer] );
} // pixels

//---------------------------------------------------------------------------

- (GLuint) texture
{
    return( mpFramebuffer2D->image.name );
} // texture

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpFramebuffer2D->image.target );
} // target

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( mpFramebuffer2D->image.format );
} // format

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( mpFramebuffer2D->viewport.width );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( mpFramebuffer2D->viewport.height );
} // height

//---------------------------------------------------------------------------

- (GLint) level
{
    return( mpFramebuffer2D->image.level );
} // level

//---------------------------------------------------------------------------

- (GLfloat) aspect
{
    return( [mpFramebuffer2D->texture aspect] );
} // aspect

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLFramebuffer2DSetSize(theSize, mpFramebuffer2D) );
} // setSize

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
