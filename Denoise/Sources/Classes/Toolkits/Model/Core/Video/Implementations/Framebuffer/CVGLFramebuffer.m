//---------------------------------------------------------------------------
//
//	File: CVGLTexture.m
//
//  Abstract: Utility class for managing FBOs using CoreVideo opaque
//            texture references.  The CoreVideo textures are vertically 
//            reflected in our FBO, and the texture ready for display and
//            with proper aspect is returned as a result of render to 
//            texture.
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
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLQuad.h"

#import "CVGLFramebuffer.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structure

//---------------------------------------------------------------------------

struct CVGLFramebufferData
{
	NSSize              size;
    CVOpenGLTextureRef  image;
    OpenGLQuad         *quads[2];
};

typedef struct CVGLFramebufferData  CVGLFramebufferData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static void  CVGLFramebufferUpdateArrayAtIndex(const BOOL isVR,
                                               const GLuint idx,
                                               const NSSize *pSize,
                                               CVGLFramebufferDataRef pFramebuffer)                                           
{    
    GLfloat texCoords[8];
    GLfloat vertices[8];
    
    texCoords[0] = 0.0f;
    texCoords[1] = 0.0f;
    texCoords[2] = 0.0f;
    texCoords[3] = pSize->height;
    texCoords[4] = pSize->width;
    texCoords[5] = pSize->height;
    texCoords[6] = pSize->width;
    texCoords[7] = 0.0f;
    
    if( isVR )
    {
        vertices[0] = 0.0f;
        vertices[1] = pSize->height;
        vertices[2] = 0.0f;
        vertices[3] = 0.0f;
        vertices[4] = pSize->width;
        vertices[5] = 0.0f;
        vertices[6] = pSize->width;
        vertices[7] = pSize->height;
    } // if
    else
    {
        vertices[0] = 0.0f;
        vertices[1] = 0.0f;
        vertices[2] = 0.0f;
        vertices[3] = pSize->height;
        vertices[4] = pSize->width;
        vertices[5] = pSize->height;
        vertices[6] = pSize->width;
        vertices[7] = 0.0f;
    } // else
    
    [pFramebuffer->quads[idx] setTexCoords:texCoords];
    [pFramebuffer->quads[idx] setVertices:vertices];
} // CVGLFramebufferUpdateArrayAtIndex

//---------------------------------------------------------------------------

static void CVGLFramebufferCreateQuadAtIndex(const BOOL isVR,
                                             const GLuint idx,
                                             const NSSize *pSize,
                                             CVGLFramebufferDataRef pFramebuffer)
{
    pFramebuffer->quads[idx] = [[OpenGLQuad alloc] initQuadWithSize:pSize 
                                                             target:GL_TEXTURE_RECTANGLE_ARB];
    
    if( pFramebuffer->quads[idx] )
    {
        CVGLFramebufferUpdateArrayAtIndex(isVR, idx, pSize, pFramebuffer);
        
        [pFramebuffer->quads[idx] acquire];
    } // if
} // CVGLFramebufferCreateQuadAtIndex

//---------------------------------------------------------------------------

static void CVGLFramebufferCreateQuateWithSize(const NSSize *pSize,
                                               CVGLFramebufferDataRef pFramebuffer)
{
	pFramebuffer->size.width  = pSize->width;
	pFramebuffer->size.height = pSize->height;
    
	// A Quad, when using CoreVideo clean texture coordinates
    
    CVGLFramebufferCreateQuadAtIndex(NO, 0, pSize, pFramebuffer);
    CVGLFramebufferCreateQuadAtIndex(YES, 1, pSize, pFramebuffer);
} // newOpenGLQuads

//---------------------------------------------------------------------------

static CVGLFramebufferDataRef CVGLFramebufferCreateWithSize(const NSSize *pSize)
{
    CVGLFramebufferDataRef pFramebuffer = (CVGLFramebufferDataRef)calloc(1, sizeof(CVGLFramebufferData));
    
    if( pFramebuffer != NULL )
    {
        CVGLFramebufferCreateQuateWithSize(pSize, pFramebuffer);
    } // if
    else
    {
        NSLog( @">> ERROR: CV GL Framebuffer - Failed allocating memory for the framebuffer backing store!" );
    } // else
	
	return( pFramebuffer );
} // CVGLFramebufferCreateWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void CVGLFramebufferDeleteQuads(CVGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->quads[0] )
	{
		[pFramebuffer->quads[0] release];
	} // if
    
	if( pFramebuffer->quads[1] )
	{
		[pFramebuffer->quads[1] release];
	} // if
} // CVGLFramebufferDeleteQuads

//---------------------------------------------------------------------------

static void CVGLFramebufferDeleteTexture(CVGLFramebufferDataRef pFramebuffer)
{
	if( pFramebuffer->image != NULL )
	{
		CVOpenGLTextureRelease( pFramebuffer->image );
		
		pFramebuffer->image = NULL;
	} // if
} // CVGLFramebufferDeleteTexture

//---------------------------------------------------------------------------

static void CVGLFramebufferDeleteAssets(CVGLFramebufferDataRef pFramebuffer)
{
	CVGLFramebufferDeleteQuads(pFramebuffer);
	CVGLFramebufferDeleteTexture(pFramebuffer);
} // CVGLFramebufferDeleteAssets

//---------------------------------------------------------------------------

static void CVGLFramebufferDelete(CVGLFramebufferDataRef pFramebuffer)
{    
	if( pFramebuffer != NULL )
	{
        CVGLFramebufferDeleteAssets(pFramebuffer);
        
		free( pFramebuffer );
        
        pFramebuffer = NULL;
	} // if
} // CVGLFramebufferDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static void CVGLFramebufferRender(CVGLFramebufferDataRef pFramebuffer)
{
	// get the texture target
	
	GLenum target = CVOpenGLTextureGetTarget(pFramebuffer->image);
    
	// get the texture target name
	
	GLint name = CVOpenGLTextureGetName(pFramebuffer->image);
    
	if( name )
    {
        // bind to the CoreVideo texture
        
        glBindTexture( target, name );
        
        // draw the quad
        
        NSUInteger quadIndex = CVOpenGLTextureIsFlipped(pFramebuffer->image);
        
        // If flipped, then use the vertical-reflect quad
        
        [pFramebuffer->quads[quadIndex] display];
        
        // Unbind the CoreVideo texture
        
        glBindTexture( target, 0 );
    } // if
} // CVGLFramebufferRender

//---------------------------------------------------------------------------

static void CVGLFramebufferSetImage(CVImageBufferRef pImageBuffer,
                                    CVGLFramebufferDataRef pFramebuffer)
{
    CVOpenGLTextureRelease( pFramebuffer->image );
    CVOpenGLTextureRetain( pImageBuffer );
    
    pFramebuffer->image = pImageBuffer;
} // CVGLFramebufferSetImage

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation CVGLFramebuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------
//
// Initialize on startup
//
//---------------------------------------------------------------------------

- (id) initFramebufferWithSize:(const NSSize *)theSize
{
	self = [super initFramebuffer2DWithSize:theSize
                                     target:GL_TEXTURE_RECTANGLE_ARB
                                     format:GL_BGRA
                                      level:0];
	
	if( self )
	{
		mpFramebuffer = CVGLFramebufferCreateWithSize(theSize);
	} // if
	
	return  self;
} // initFramebufferWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	CVGLFramebufferDelete(mpFramebuffer);
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Render to texture

//---------------------------------------------------------------------------
//
// Render to texture the video frame provided by Core Video.
//
//---------------------------------------------------------------------------

- (void) update:(CVImageBufferRef)theImageBuffer;
{
    CVGLFramebufferSetImage(theImageBuffer, mpFramebuffer);
    
    [self enable];
    {
        CVGLFramebufferRender(mpFramebuffer);
    }
    [self disable];
} // update

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
