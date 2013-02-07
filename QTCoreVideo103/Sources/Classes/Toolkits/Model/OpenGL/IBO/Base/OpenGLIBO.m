//---------------------------------------------------------------------------
//
//	File: OpenGLIBO.m
//
//  Abstract: Utility class that implements a method for generating a
//            3D object using IBOs.
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
//  Copyright (c) 2009-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLIBO.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLBuffer
{
	GLint    count;
	GLuint   name;
	GLenum   type;
	GLenum   target;
	GLenum   usage;
	GLenum   access;
	GLsizei  stride;
};

typedef struct OpenGLBuffer  OpenGLBuffer;

//---------------------------------------------------------------------------

struct OpenGLVoidPtr
{
	GLsizeiptr     size;
	GLintptr       offset;
	const GLvoid  *data;
};

typedef struct OpenGLVoidPtr  OpenGLVoidPtr;

//---------------------------------------------------------------------------

struct OpenGLShortPtr
{
	GLsizeiptr     size;
	GLintptr       offset;
	const GLshort *data;
};

typedef struct OpenGLShortPtr  OpenGLShortPtr;

//---------------------------------------------------------------------------

struct OpenGLGeometry
{
    OpenGLBuffer   buffer;
	OpenGLVoidPtr  vertices;
	OpenGLVoidPtr  normals;
	GLvoid        *pointer;
};

typedef struct OpenGLGeometry  OpenGLGeometry;

//---------------------------------------------------------------------------

struct OpenGLElements
{
    OpenGLBuffer    buffer;
	OpenGLShortPtr  indices;
	GLshort        *pointer;
};

typedef struct OpenGLElements  OpenGLElements;

//---------------------------------------------------------------------------

struct OpenGLIBOData
{
	GLsizeiptr      size;
    OpenGLGeometry  geometry;
	OpenGLElements  elements;
};

typedef struct OpenGLIBOData   OpenGLIBOData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Macros

//---------------------------------------------------------------------------

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static OpenGLIBODataRef OpenGLIBOCreate(const GLenum type)
{
	OpenGLIBODataRef pIBO = (OpenGLIBODataRef)calloc(1, sizeof(OpenGLIBOData));
	
	if( pIBO != NULL )
	{
		pIBO->size = 0;
		
		pIBO->geometry.buffer.name   = 0;
		pIBO->geometry.buffer.count  = 3;
		pIBO->geometry.buffer.stride = 0;
		pIBO->geometry.buffer.type   = type;
		pIBO->geometry.buffer.target = GL_ARRAY_BUFFER;
		pIBO->geometry.buffer.usage  = GL_STREAM_DRAW;
		pIBO->geometry.buffer.access = GL_READ_WRITE;
        
		pIBO->geometry.pointer = NULL;
        
		pIBO->geometry.vertices.offset = 0;
		pIBO->geometry.vertices.size   = 0;
		pIBO->geometry.vertices.data   = NULL;
		
		pIBO->geometry.normals.offset = 0;
		pIBO->geometry.normals.size   = 0;
		pIBO->geometry.normals.data   = NULL;
		
		pIBO->elements.pointer = NULL;
        
		pIBO->elements.buffer.name    = 0;
		pIBO->elements.buffer.stride  = 0;
		pIBO->elements.buffer.type    = GL_SHORT;
		pIBO->elements.buffer.target  = GL_ELEMENT_ARRAY_BUFFER;
		pIBO->elements.buffer.usage   = GL_STATIC_DRAW;
		pIBO->elements.buffer.access  = GL_READ_WRITE;
        
		pIBO->elements.indices.offset = 0;
        pIBO->elements.indices.size   = 0;
		pIBO->elements.indices.data   = NULL;
    } // if
	
	return( pIBO );
} // OpenGLIBOCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLIBODeleteGeometry(OpenGLIBODataRef pIBO)
{
    if( pIBO->geometry.buffer.name )
    {
        glDeleteBuffers( 1, &pIBO->geometry.buffer.name );
        
        pIBO->geometry.buffer.name = 0;
    } // if
} // OpenGLIBODeleteGeometry

//---------------------------------------------------------------------------

static void OpenGLIBODeleteElements(OpenGLIBODataRef pIBO)
{
    if( pIBO->elements.buffer.name )
    {
        glDeleteBuffers( 1, &pIBO->elements.buffer.name );
        
        pIBO->elements.buffer.name = 0;
    } // if
} // OpenGLIBODeleteElements

//---------------------------------------------------------------------------

static void OpenGLIBODeleteBuffers(OpenGLIBODataRef pIBO)
{
    OpenGLIBODeleteGeometry(pIBO);
    OpenGLIBODeleteElements(pIBO);
} // OpenGLIBODeleteBuffers

//---------------------------------------------------------------------------

static void OpenGLIBODelete(OpenGLIBODataRef pIBO)
{
	if( pIBO != NULL )
	{
        OpenGLIBODeleteBuffers(pIBO);
		
		free( pIBO );
		
		pIBO = NULL;
	} // if
} // OpenGLIBODelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Acquire

//---------------------------------------------------------------------------

static BOOL OpenGLIBOAcquireGeometry(OpenGLIBODataRef pIBO)
{
	glGenBuffers(1, &pIBO->geometry.buffer.name);
	
	if( pIBO->geometry.buffer.name )
	{		
		pIBO->size = pIBO->geometry.vertices.size + pIBO->geometry.normals.size;
		
		glBindBuffer(pIBO->geometry.buffer.target, pIBO->geometry.buffer.name);
		{
            glBufferData(pIBO->geometry.buffer.target, 
                         pIBO->size,
                         0, 
                         pIBO->geometry.buffer.usage);
            
            glBufferSubData(pIBO->geometry.buffer.target, 
                            0, 
                            pIBO->geometry.vertices.size, 
                            pIBO->geometry.vertices.data);
            
            glBufferSubData(pIBO->geometry.buffer.target, 
                            pIBO->geometry.vertices.size, 
                            pIBO->geometry.normals.size, 
                            pIBO->geometry.normals.data);
		}
        glBindBuffer(pIBO->geometry.buffer.target, 0);
	} // if
    
    return( pIBO->geometry.buffer.name != 0);
} // OpenGLIBOAcquireGeometry

//---------------------------------------------------------------------------
//
// Create a VBO for an index array.
//
// Target of this VBO is GL_ELEMENT_ARRAY_BUFFER and usage is GL_STATIC_DRAW
//
//---------------------------------------------------------------------------

static BOOL OpenGLIBOAcquireElements(OpenGLIBODataRef pIBO)
{
    glGenBuffers(1, &pIBO->elements.buffer.name);
    
    if( pIBO->elements.buffer.name )
    {
        glBindBuffer( pIBO->elements.buffer.target, pIBO->elements.buffer.name );
        {
            glBufferData(pIBO->elements.buffer.target, 
                         pIBO->elements.indices.size, 
                         pIBO->elements.indices.data, 
                         pIBO->elements.buffer.usage);
        }
        glBindBuffer(pIBO->elements.buffer.target, 0);
    } // if
    
    return( pIBO->elements.buffer.name != 0);
} // OpenGLIBOAcquireElements

//---------------------------------------------------------------------------
//
// Create a vertex name objects. Try to put both vertex coordinates 
// and normal arrays in the same name object.
//
//---------------------------------------------------------------------------

static BOOL OpenGLIBOAcquire(OpenGLIBODataRef pIBO)
{
	BOOL success = OpenGLIBOAcquireGeometry(pIBO);
	
	if( success )
	{
        success = OpenGLIBOAcquireElements(pIBO);
        
		if( !success )
		{
			glDeleteBuffers(1, &pIBO->geometry.buffer.name);
		} // else
	} // if
	
	return( success );
} // OpenGLIBOAcquire

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Bind/Unbind

//---------------------------------------------------------------------------
//
// Bind to display the geometry
//
//---------------------------------------------------------------------------

static void OpenGLIBOBind(OpenGLIBODataRef pIBO)
{
	glBindBuffer(pIBO->geometry.buffer.target, 
                 pIBO->geometry.buffer.name);
    
	glNormalPointer(pIBO->geometry.buffer.type, 
                    0, 
                    BUFFER_OFFSET(pIBO->geometry.normals.offset));
    
	glVertexPointer(pIBO->geometry.buffer.count, 
                    pIBO->geometry.buffer.type, 
                    pIBO->geometry.buffer.stride, 
                    BUFFER_OFFSET(0));
	
	glBindBuffer(pIBO->elements.buffer.target, 
                 pIBO->elements.buffer.name);
    
	glIndexPointer(pIBO->elements.buffer.type, 
                   pIBO->elements.buffer.stride,
                   BUFFER_OFFSET(0));
} // OpenGLIBOBind

//---------------------------------------------------------------------------
//
// Unbind to revert back to the original state(s)
//
//---------------------------------------------------------------------------

static void OpenGLIBOUnbind(OpenGLIBODataRef pIBO)
{
	glBindBuffer(pIBO->elements.buffer.target, 0);
	glBindBuffer(pIBO->geometry.buffer.target, 0);
} // OpenGLIBOUnbind

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Copiers

//---------------------------------------------------------------------------
//
// Update the vertices in an IBO.
//
//---------------------------------------------------------------------------

static BOOL OpenGLIBOCopyElements(const GLvoid *ptrSrc,
                                  const GLsizeiptr size,
                                  OpenGLIBODataRef pIBO)
{
    BOOL success = size < pIBO->elements.indices.size;
    
    if( success )
    {
        glBindBuffer(pIBO->elements.buffer.target, 
                     pIBO->elements.buffer.name);
        
        GLvoid *ptrDst = glMapBuffer(pIBO->elements.buffer.target, 
                                     pIBO->elements.buffer.access);
        
        success = ptrDst != NULL;
        
        if( success )
        {
            memcpy(ptrDst, ptrSrc, size);
            
            glUnmapBuffer(pIBO->elements.buffer.target);
        } // if
        
        glBindBuffer(pIBO->elements.buffer.target, 0);
    } // if
    
    return( success );
} // OpenGLIBOCopyElements

//---------------------------------------------------------------------------
//
// Update the vertices in an IBO.
//
//---------------------------------------------------------------------------

static BOOL OpenGLIBOCopyArray(const bool isNormals,
                               const GLvoid *ptrSrc,
                               const GLsizeiptr size,
                               OpenGLIBODataRef pIBO)
{
    BOOL success = NO;
    
    GLsizeiptr offset = 0;
    
    if( isNormals )
    {
        offset  = pIBO->geometry.vertices.size;
        success = (size + offset) < pIBO->size;
    } // if
    else
    {
        success = size < pIBO->geometry.vertices.size;
    } // else
    
    if( success )
    {
        glBindBuffer(pIBO->geometry.buffer.target, 
                     pIBO->geometry.buffer.name);
        
        GLvoid *ptrDst = glMapBuffer(pIBO->geometry.buffer.target, 
                                     pIBO->geometry.buffer.access);
        
        success = ptrDst != NULL;
        
        if( success )
        {
            if( offset > 0 )
            {
                ptrDst += offset;
            } // if
            
            memcpy(ptrDst, ptrSrc, size);
            
            glUnmapBuffer(pIBO->geometry.buffer.target);
        } // if
        
        glBindBuffer(pIBO->geometry.buffer.target, 0);
    } // if
    
    return( success );
} // OpenGLIBOCopyArray

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Map/Unmap

//---------------------------------------------------------------------------

static BOOL OpenGLIBOMapArray(OpenGLIBODataRef pIBO)
{
    BOOL success = NO;
    
    glBindBuffer(pIBO->geometry.buffer.target, 
                 pIBO->geometry.buffer.name);
    
    pIBO->geometry.pointer = glMapBuffer(pIBO->geometry.buffer.target, 
                                         pIBO->geometry.buffer.access);
    
    success = pIBO->geometry.pointer != NULL;
    
    return( success );
} // OpenGLIBOMapArray

//---------------------------------------------------------------------------

static BOOL OpenGLIBOUnmapArray(OpenGLIBODataRef pIBO)
{
    BOOL success = glUnmapBuffer(pIBO->geometry.buffer.target);
    
    glBindBuffer(pIBO->geometry.buffer.target, 0);
	
    return( success );
} // OpenGLIBOUnmapArray

//---------------------------------------------------------------------------

static BOOL OpenGLIBOMapElements(OpenGLIBODataRef pIBO)
{
    BOOL success = NO;
    
    glBindBuffer(pIBO->elements.buffer.target,
                 pIBO->elements.buffer.name);
    
    pIBO->elements.pointer = (GLshort *)glMapBuffer(pIBO->elements.buffer.target, 
                                                    pIBO->elements.buffer.access);
    
    success = pIBO->elements.pointer != NULL;
    
    return( success );
} // OpenGLIBOMapElements

//---------------------------------------------------------------------------

static BOOL OpenGLIBOUnmapElements(OpenGLIBODataRef pIBO)
{
    BOOL success = glUnmapBuffer(pIBO->elements.buffer.target);
    
    glBindBuffer(pIBO->elements.buffer.target, 0);
	
    return( success );
} // OpenGLIBOUnmapElements

//---------------------------------------------------------------------------

static BOOL OpenGLIBOMap(const GLenum target,
                         OpenGLIBODataRef pIBO)
{
    BOOL success = NO;
    
    if( target == GL_ELEMENT_ARRAY_BUFFER )
    {
        success = OpenGLIBOMapElements(pIBO);
    } // if
    else
    {
        success = OpenGLIBOMapArray(pIBO);
    } // else
    
    return( success );
} // OpenGLIBOMap

//---------------------------------------------------------------------------

static BOOL OpenGLIBOUnmap(const GLenum target,
                           OpenGLIBODataRef pIBO)
{
    BOOL success = NO;
    
    if( target == GL_ELEMENT_ARRAY_BUFFER )
    {
        success = OpenGLIBOUnmapElements(pIBO);
    } // if
    else
    {
        success = OpenGLIBOUnmapElements(pIBO);
    } // else
    
    return( success );
} // OpenGLIBOUnmap

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLIBO

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (id) initIBOWithType:(const GLenum)theType
{
	self = [super init];
	
	if( self )
	{
		mpIBO = OpenGLIBOCreate(theType);
	} // if
	
	return  self;
} // initIBOWithVertices

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc
{
	OpenGLIBODelete(mpIBO);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (void) setVertices:(const GLvoid *)theVertices
				size:(const GLsizeiptr)theSize
{
	mpIBO->geometry.vertices.data = theVertices;
	mpIBO->geometry.vertices.size = theSize;
} // setVertices

//---------------------------------------------------------------------------

- (void) setNormals:(const GLvoid *)theNormals
			   size:(const GLsizeiptr)theSize
			 offset:(const GLsizeiptr)theOffset
{
	mpIBO->geometry.normals.data   = theNormals;
	mpIBO->geometry.normals.size   = theSize;
	mpIBO->geometry.normals.offset = theOffset;
} // setNormals

//---------------------------------------------------------------------------

- (void) setElements:(const GLshort *)theElements
                size:(const GLsizeiptr)theSize
{
	mpIBO->elements.indices.data = theElements;
	mpIBO->elements.indices.size = theSize;
} // setElements

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) acquire
{
	return( OpenGLIBOAcquire(mpIBO) );
} // acquire

//---------------------------------------------------------------------------

- (void) bind
{
	OpenGLIBOBind(mpIBO);
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
	OpenGLIBOUnbind(mpIBO);
} // unbind

//---------------------------------------------------------------------------
//
// Copy an array of vertices into an acquired IBO.
//
//---------------------------------------------------------------------------

- (BOOL) copyVertices:(const GLvoid *)theVertices
				 size:(const GLsizeiptr)theSize
{
	return( OpenGLIBOCopyArray(NO, theVertices, theSize, mpIBO) );
} // copyVertices

//---------------------------------------------------------------------------
//
// Copy an array of normals into an acquired IBO.
//
//---------------------------------------------------------------------------

- (BOOL) copyNormals:(const GLvoid *)theNormals
				size:(const GLsizeiptr)theSize
{
	return( OpenGLIBOCopyArray(YES, theNormals, theSize, mpIBO) );
} // copyNormals

//---------------------------------------------------------------------------
//
// Copy an array of indicies into an acquired IBO.
//
//---------------------------------------------------------------------------

- (BOOL) copyElements:(const GLshort *)theElements
                 size:(const GLsizeiptr)theSize
{
	return( OpenGLIBOCopyElements(theElements, theSize, mpIBO) );
} // copyElements

//---------------------------------------------------------------------------

- (BOOL) map:(const GLenum)theTarget
{
    return( OpenGLIBOMap(theTarget, mpIBO) );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap:(const GLenum)theTarget
{
    return( OpenGLIBOUnmap(theTarget, mpIBO) );
} // unmap

//---------------------------------------------------------------------------

- (GLvoid *) vertices
{
    return( mpIBO->geometry.pointer );
} // vertices

//---------------------------------------------------------------------------

- (GLvoid *) normals
{
    return( mpIBO->geometry.pointer + mpIBO->geometry.vertices.size );
} // normals

//---------------------------------------------------------------------------

- (GLshort *) elements
{
    return( mpIBO->elements.pointer );
} // elements

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
