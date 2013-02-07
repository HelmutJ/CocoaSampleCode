//---------------------------------------------------------------------------
//
//	File: OpenGLPBO.h
//
//  Abstract: Utility toolkit providing basic functionality for
//            PBOs (pack/unpack).
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

#import "OpenGLPBO.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLPBOData
{
    BOOL    isRead;
    BOOL    isWrite;
    GLuint  name;       // PBO name (or id)
    GLuint  size;       // PBO size
    GLenum  target;     // e.g., pixel pack or unpack
    GLenum  usage;      // e.g., stream draw
    GLenum  access;		// e.g., read, write, or both
    GLvoid  *buffer;    // Buffer pointer.
};

typedef struct OpenGLPBOData   OpenGLPBOData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static void OpenGLPBOSetUsage(GLenum  usage,
                              OpenGLPBODataRef pPBO)
{
    pPBO->isWrite = (usage == GL_STREAM_DRAW) || (usage == GL_STATIC_DRAW) || (usage == GL_DYNAMIC_DRAW);
    pPBO->isRead  = (usage == GL_STREAM_READ) || (usage == GL_STATIC_READ) || (usage == GL_DYNAMIC_READ);
    
    if( pPBO->isWrite )
    {
        pPBO->usage  = usage;
        pPBO->target = GL_PIXEL_UNPACK_BUFFER;
        pPBO->access = GL_WRITE_ONLY;
    } // if
    else
    {
        pPBO->usage  = ( pPBO->isRead ) ? usage : GL_STREAM_READ;
        pPBO->target = GL_PIXEL_PACK_BUFFER;
        pPBO->access = GL_READ_ONLY;
        pPBO->isRead = YES;
    } // else
} // OpenGLPBOSetUsage

//---------------------------------------------------------------------------

static BOOL OpenGLPBOSetSize(const GLuint size,
                             const GLvoid *pData,
                             OpenGLPBODataRef pPBO)
{
    BOOL success = size != pPBO->size;
    
    if( success )
    {        
        pPBO->size = size;
        
        glBindBuffer(pPBO->target, pPBO->name);
        {
            glBufferData(pPBO->target, 
                         pPBO->size, 
                         pData,
                         pPBO->usage);
        }
        glBindBuffer(pPBO->target, 0);
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL PBO - Failed resizing a buffer!" );
    } // else
    
    return( success );
} // OpenGLPBOSetSize

//---------------------------------------------------------------------------

static void OpenGLPBOCreateBuffer(const GLuint size,
                                  OpenGLPBODataRef pPBO)
{
    if( !pPBO->name )
    {
        glGenBuffers(1, &pPBO->name);
	} // if
    
    if( pPBO->name )
    {
        OpenGLPBOSetSize(size, NULL, pPBO);
    } // if
} // OpenGLPBOCreateBuffer

//---------------------------------------------------------------------------

static inline void OpenGLPBOSetDefaults(OpenGLPBODataRef pPBO)
{
    pPBO->name = 0;
    pPBO->size = 0;
} // OpenGLPBOSetDefaults

//---------------------------------------------------------------------------

static OpenGLPBODataRef OpenGLPBOCreate(const GLuint size,
                                        const GLenum usage)
{
	OpenGLPBODataRef pPBO = (OpenGLPBODataRef)calloc(1, sizeof(OpenGLPBOData));
	
	if( pPBO != NULL )
	{
        OpenGLPBOSetDefaults(pPBO);
        OpenGLPBOSetUsage(usage, pPBO);
        OpenGLPBOCreateBuffer(size, pPBO);
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL PBO - Failed creating a PBO!" );
    } // else
	
	return( pPBO );
} // OpenGLPBOCreate

//---------------------------------------------------------------------------

static void OpenGLPBODelete(OpenGLPBODataRef pPBO)
{
	if( pPBO != NULL )
	{
		if( pPBO->name )
		{
			glDeleteBuffers( 1, &pPBO->name );
		} // if
        
		free( pPBO );
		
		pPBO = NULL;
	} // if
} // OpenGLPBODelete

//---------------------------------------------------------------------------

static inline BOOL OpenGLPBOMap(OpenGLPBODataRef pPBO)
{
    pPBO->buffer = glMapBuffer(pPBO->target, pPBO->access);	
    
    return( pPBO->buffer != NULL );
} // OpenGLPBOMap

//---------------------------------------------------------------------------
//
// If GPU is working with a buffer, glMapBuffer API becomes a 
// syncronization point, and will stall the GPU pipeline until 
// such time the current job is processed. 
//
// By calling glBufferData API with a NULL pointer, and before 
// calling the glMapBuffer API, the previous data in a PBO will 
// be discarded and glMapBuffer API returns a new allocated pointer 
// immediately even thought the GPU is still processing the previous
// data.
//
//---------------------------------------------------------------------------

static inline void OpenGLPBOFlush(OpenGLPBODataRef pPBO)
{
    glBufferData(pPBO->target, pPBO->size, NULL, pPBO->usage);
} // OpenGLPBOFlush

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLPBO

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initPBOWithSize:(const GLuint)theSize
                 usage:(const GLenum)theUsage
{
	self = [super init];
	
	if( self )
	{
		mpPBO = OpenGLPBOCreate(theSize, theUsage);
	} // if
	
	return  self;
} // initPBOWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLPBODelete(mpPBO);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpPBO->target );
} // target

//---------------------------------------------------------------------------

- (GLenum) access
{
    return( mpPBO->access );
} // access

//---------------------------------------------------------------------------

- (GLenum) usage
{
    return( mpPBO->usage );
} // usage
//---------------------------------------------------------------------------

- (GLuint) size
{
    return( mpPBO->size );
} // size

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( mpPBO->buffer );
} // buffer

//---------------------------------------------------------------------------

- (BOOL) setSize:(const GLuint)theSize
{
    return( OpenGLPBOSetSize(theSize, NULL, mpPBO) );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) readOnly
{
    return( mpPBO->isRead );
} // readOnly

//---------------------------------------------------------------------------

- (BOOL) writeOnly
{
    return( mpPBO->isWrite );
} // writeOnly

//---------------------------------------------------------------------------

- (BOOL) map
{
    return( OpenGLPBOMap(mpPBO) );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( glUnmapBuffer(mpPBO->target) );
} // unmap

//---------------------------------------------------------------------------

- (void) bind
{
    glBindBuffer(mpPBO->target, mpPBO->name);
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
    glBindBuffer(mpPBO->target, 0);
} // unbind

//---------------------------------------------------------------------------

- (void) flush
{
    OpenGLPBOFlush(mpPBO);
} // flush

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
