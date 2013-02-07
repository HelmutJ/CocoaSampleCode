//---------------------------------------------------------------------------
//
//	File: OpenGLQuadBase.m
//
//  Abstract: Utility bass class for constructing a VBO quad.
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

#import "OpenGLQuadBase.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLQuadBaseData
{
	GLuint    name;			// buffer identifier
	GLuint    count;		// vertex count
	GLuint    size;			// size of vertices or texture coordinates
	GLuint    capacity;		// vertex size + texture coordinate size
	GLsizei   stride;		// vbo stride
	GLenum    target[2];    // vbo & texture target repectively
	GLenum    usage;		// vbo usage
	GLenum    type;			// vbo type
	GLenum    mode;			// vbo mode
	GLfloat   width;		// quad width
	GLfloat   height;		// quad height
	GLfloat   aspect;		// aspect ratio
	GLfloat  *data;			// vbo data
	GLenum    quadType;		// vbo quad type
    GLfloat   vertices[8];  // Quad vertices
    GLfloat   texCoords[8]; // Quad texture coordinates
};

typedef struct OpenGLQuadBaseData  OpenGLQuadBaseData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessors

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseSetSize(const NSSize *pSize,
                                  OpenGLQuadBaseDataRef pQuadBase)                           
{
    BOOL success = (pSize != NULL);
    
    if( success )
    {
        pQuadBase->width  = pSize->width;
        pQuadBase->height = pSize->height;
        pQuadBase->aspect = pSize->width / pSize->height;
    } // if
    else
    {
        pQuadBase->width  = 1920.0f;
        pQuadBase->height = 1080.0f;
        pQuadBase->aspect = pQuadBase->width / pQuadBase->height;
    } // else
    
    return( success );
} // OpenGLQuadBaseSetSize

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseSetTarget(const GLenum target,
                                    OpenGLQuadBaseDataRef pQuadBase)
{
    BOOL isValid = (target == GL_TEXTURE_RECTANGLE_ARB) || (target == GL_TEXTURE_2D);
    
	pQuadBase->target[1] = isValid ? target : GL_TEXTURE_2D;
    
    return( isValid );
} // OpenGLQuadBaseSetTarget

//---------------------------------------------------------------------------

static void OpenGLQuadSetDefaults(OpenGLQuadBaseDataRef pQuadBase)
{
    pQuadBase->name      = 0;
	pQuadBase->count     = 4;
	pQuadBase->size      = 8 * sizeof(GLfloat);
	pQuadBase->capacity  = 2 * pQuadBase->size;
	pQuadBase->usage     = GL_STATIC_DRAW;
	pQuadBase->type      = GL_FLOAT;
	pQuadBase->mode      = GL_QUADS;
	pQuadBase->stride    = 0;
	pQuadBase->data      = NULL;
	pQuadBase->target[0] = GL_ARRAY_BUFFER;
} // OpenGLQuadSetDefaults

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseSetTextureCoordinates(const GLfloat *pTexCoords,
                                                OpenGLQuadBaseDataRef pQuadBase)
{
    BOOL success = pTexCoords != NULL;
    
    if( success )
    {
        pQuadBase->texCoords[0] = pTexCoords[0];
        pQuadBase->texCoords[1] = pTexCoords[1];
        pQuadBase->texCoords[2] = pTexCoords[2];
        pQuadBase->texCoords[3] = pTexCoords[3];
        pQuadBase->texCoords[4] = pTexCoords[4];
        pQuadBase->texCoords[5] = pTexCoords[5],
        pQuadBase->texCoords[6] = pTexCoords[6];
        pQuadBase->texCoords[7] = pTexCoords[7];
    } // if
    
    return( success );
} // OpenGLQuadBaseSetTextureCoordinates

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseSetVertexArray(const GLfloat *pVertices,
                                         OpenGLQuadBaseDataRef pQuadBase)
{
    BOOL success = pVertices != NULL;
    
    if( success )
    {
        pQuadBase->vertices[0] = pVertices[0];
        pQuadBase->vertices[1] = pVertices[1];
        pQuadBase->vertices[2] = pVertices[2];
        pQuadBase->vertices[3] = pVertices[3];
        pQuadBase->vertices[4] = pVertices[4];
        pQuadBase->vertices[5] = pVertices[5],
        pQuadBase->vertices[6] = pVertices[6];
        pQuadBase->vertices[7] = pVertices[7];
    } // if
    
    return( success );
} // OpenGLQuadBaseSetVertexArray

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initializers

//---------------------------------------------------------------------------

static void OpenGLQuadInitArrays(OpenGLQuadBaseDataRef pQuadBase)
{
    pQuadBase->texCoords[0]  = 0.0f;
    pQuadBase->texCoords[1]  = 0.0f;
    pQuadBase->texCoords[2]  = 0.0f;
    pQuadBase->texCoords[3]  = 1.0f;
    pQuadBase->texCoords[4]  = 1.0f;
    pQuadBase->texCoords[5]  = 1.0f;
    pQuadBase->texCoords[6]  = 1.0f;
    pQuadBase->texCoords[7]  = 0.0f;
    
    pQuadBase->vertices[0]  = -1.0f;
    pQuadBase->vertices[1]  = -1.0f;
    pQuadBase->vertices[2]  = -1.0f;
    pQuadBase->vertices[3]  =  1.0f;
    pQuadBase->vertices[4]  =  1.0f;
    pQuadBase->vertices[5]  =  1.0f;
    pQuadBase->vertices[6]  =  1.0f;
    pQuadBase->vertices[7]  = -1.0f;
} // OpenGLQuadInitArrays

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static OpenGLQuadBaseDataRef OpenGLQuadBaseCreate(const NSSize *pSize,
                                                  const GLenum target)
{
    OpenGLQuadBaseDataRef pQuadBase = (OpenGLQuadBaseDataRef)calloc(1, sizeof(OpenGLQuadBaseData));
    
    if( pQuadBase != NULL )
    {
        OpenGLQuadBaseSetSize(pSize, pQuadBase);
        OpenGLQuadBaseSetTarget(target, pQuadBase);
        OpenGLQuadSetDefaults(pQuadBase);
        OpenGLQuadInitArrays(pQuadBase);
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL Quad - Failure Allocating Memory For Data!" );
    }  // else
	
	return( pQuadBase );
} // OpenGLQuadBaseCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLQuadDeleteBuffer(OpenGLQuadBaseDataRef pQuadBase)
{
    if( pQuadBase->name )
    {
        glDeleteBuffers( 1, &pQuadBase->name );
    } // if
} // OpenGLQuadDeleteBuffer

//---------------------------------------------------------------------------

static void OpenGLQuadBaseDelete(OpenGLQuadBaseDataRef pQuadBase)
{
	if( pQuadBase != NULL )
	{
        OpenGLQuadDeleteBuffer(pQuadBase);
		
		free( pQuadBase );
		
		pQuadBase = NULL;
	} // if
} // OpenGLQuadBaseDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseAcquire(OpenGLQuadBaseDataRef pQuadBase)
{
    if( !pQuadBase->name )
    {
        glGenBuffers(1, &pQuadBase->name);
        
        if( pQuadBase->name )
        {
            glBindBuffer(pQuadBase->target[0], pQuadBase->name);
            {
                glBufferData(pQuadBase->target[0], pQuadBase->capacity, NULL, pQuadBase->usage);
                
                glBufferSubData(pQuadBase->target[0], 0, pQuadBase->size, pQuadBase->vertices);
                glBufferSubData(pQuadBase->target[0], pQuadBase->size, pQuadBase->size, pQuadBase->texCoords);
            }
            glBindBuffer(pQuadBase->target[0], 0);
        } // if
    } // if
    
    return( pQuadBase->name != 0 );
} // OpenGLQuadBaseAcquire

//---------------------------------------------------------------------------

static BOOL OpenGLQuadBaseUpdate(OpenGLQuadBaseDataRef pQuadBase)
{
    GLboolean success = GL_FALSE;
    
    glBindBuffer(pQuadBase->target[0], 
                 pQuadBase->name);
    {
        glBufferData(pQuadBase->target[0], 
                     pQuadBase->capacity, 
                     NULL, 
                     pQuadBase->usage);
        
        pQuadBase->data = (GLfloat *)glMapBuffer(pQuadBase->target[0], GL_READ_WRITE);
        
        if( pQuadBase->data != NULL )
        {
            // Vertices
            
            pQuadBase->data[0] = pQuadBase->vertices[0];
            pQuadBase->data[1] = pQuadBase->vertices[1];
            pQuadBase->data[2] = pQuadBase->vertices[2];
            pQuadBase->data[3] = pQuadBase->vertices[3];
            pQuadBase->data[4] = pQuadBase->vertices[4];
            pQuadBase->data[5] = pQuadBase->vertices[5],
            pQuadBase->data[6] = pQuadBase->vertices[6];
            pQuadBase->data[7] = pQuadBase->vertices[7];
            
            // Texture coordinates
            
            pQuadBase->data[8]  = pQuadBase->texCoords[0];
            pQuadBase->data[9]  = pQuadBase->texCoords[1];
            pQuadBase->data[10] = pQuadBase->texCoords[2];
            pQuadBase->data[11] = pQuadBase->texCoords[3];
            pQuadBase->data[12] = pQuadBase->texCoords[4];
            pQuadBase->data[13] = pQuadBase->texCoords[5],
            pQuadBase->data[14] = pQuadBase->texCoords[6];
            pQuadBase->data[15] = pQuadBase->texCoords[7];
        } // if
        
        success = glUnmapBuffer(pQuadBase->target[0]);
    }
    glBindBuffer(pQuadBase->target[0], 0);
    
    return( success );
} // OpenGLQuadBaseUpdate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLQuadBase

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if( self )
	{
		mpQuadBase = OpenGLQuadBaseCreate(NULL, GL_TEXTURE_2D);
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (id) initQuadBaseWithSize:(const NSSize *)theSize
                     target:(const GLenum)theTarget
{
	self = [super init];
	
	if( self )
	{
		mpQuadBase = OpenGLQuadBaseCreate(theSize, theTarget);
	} // if
	
	return( self );
} // initQuadBaseWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	OpenGLQuadBaseDelete(mpQuadBase);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors - Getters

//---------------------------------------------------------------------------

- (GLuint) buffer
{
    return( mpQuadBase->name );
} // buffer

//---------------------------------------------------------------------------

- (GLuint) count
{
    return( mpQuadBase->count );
} // count

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( mpQuadBase->size );
} // size

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpQuadBase->target[0] );
} // target

//---------------------------------------------------------------------------

- (GLenum) type
{
    return( mpQuadBase->type );
} // type

//---------------------------------------------------------------------------

- (GLenum) mode
{
    return( mpQuadBase->mode );
} // mode

//---------------------------------------------------------------------------

- (GLsizei) stride
{
    return( mpQuadBase->stride );
} // stride

//---------------------------------------------------------------------------

- (GLfloat) aspect
{
    return( mpQuadBase->aspect );
} // aspect

//---------------------------------------------------------------------------

- (GLfloat) width
{
    return( mpQuadBase->width );
} // aspect

//---------------------------------------------------------------------------

- (GLfloat) height
{
    return( mpQuadBase->height );
} // height

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors - Setters

//---------------------------------------------------------------------------

- (BOOL) setTexCoords:(const GLfloat *)theTexCoords
{
    return( OpenGLQuadBaseSetTextureCoordinates(theTexCoords, mpQuadBase) );
} // setTexCoords

//---------------------------------------------------------------------------

- (BOOL) setVertices:(const GLfloat *)theVertices
{
    return( OpenGLQuadBaseSetVertexArray(theVertices, mpQuadBase) );
} // setVertices

//---------------------------------------------------------------------------

- (BOOL) setTarget:(const GLenum)theTarget
{
    return( OpenGLQuadBaseSetTarget(theTarget, mpQuadBase) );
} // setTarget

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLQuadBaseSetSize(theSize, mpQuadBase) );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) acquire
{
    return( OpenGLQuadBaseAcquire(mpQuadBase) );
} // acquire

//---------------------------------------------------------------------------

- (BOOL) update
{
    return( OpenGLQuadBaseUpdate(mpQuadBase) );
} // update

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
