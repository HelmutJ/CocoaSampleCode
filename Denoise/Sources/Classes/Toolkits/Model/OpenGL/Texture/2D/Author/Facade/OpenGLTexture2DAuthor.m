//---------------------------------------------------------------------------
//
//	File: OpenGLTexture2DAuthor.m
//
//  Abstract: Utility toolkit for managing PBOs for texture read or writes.
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

#import "OpenGLTexture2DAuthorProtocol.h"

#import "OpenGLTexture2DReader.h"
#import "OpenGLTexture2DWriter.h"
#import "OpenGLTexture2DAuthor.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTexture2DAuthorData
{
    BOOL isReadOnly;
    BOOL isWriteOnly;
    
    NSSize size;
    
    id<OpenGLTexture2DAuthorProtocol> author;
};

typedef struct OpenGLTexture2DAuthorData   OpenGLTexture2DAuthorData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static OpenGLTexture2DAuthorDataRef OpenGLTexture2DAuthorCreate(const NSSize *pSize,
                                                                const GLenum  usage,
                                                                const GLenum target,
                                                                const GLint level,
                                                                const GLenum format,
                                                                const BOOL hasBorder)
{
	OpenGLTexture2DAuthorDataRef pTex2DAuthor = (OpenGLTexture2DAuthorDataRef)calloc(1, sizeof(OpenGLTexture2DAuthorData));
	
	if( pTex2DAuthor != NULL )
	{
        pTex2DAuthor->isWriteOnly = (usage == GL_STREAM_DRAW) || (usage == GL_STATIC_DRAW) || (usage == GL_DYNAMIC_DRAW);
        pTex2DAuthor->isReadOnly  = (usage == GL_STREAM_READ) || (usage == GL_STATIC_READ) || (usage == GL_DYNAMIC_READ);
        
        if( pTex2DAuthor->isWriteOnly )
        {
            pTex2DAuthor->author = [[OpenGLTexture2DWriter alloc] initTexture2DWriterWithSize:pSize
                                                                                        usage:usage
                                                                                       target:target
                                                                                        level:level
                                                                                       format:format
                                                                                       border:hasBorder];
        } // if
        else
        {
            if( !pTex2DAuthor->isReadOnly )
            {
                NSLog( @">> WARNING: OpenGL Texture 2D Author - Invalid usage!" );
                NSLog( @">> WARNING: OpenGL Texture 2D Author - Usage is set to stream read!" );
            } // if
            
            pTex2DAuthor->author = [[OpenGLTexture2DReader alloc] initTexture2DReaderWithSize:pSize
                                                                                        usage:usage
                                                                                       target:target
                                                                                        level:level
                                                                                       format:format
                                                                                       border:hasBorder];
        } // else
        
        if( pTex2DAuthor->author )
        {
            pTex2DAuthor->size.width  = (CGFloat)[pTex2DAuthor->author width];
            pTex2DAuthor->size.height = (CGFloat)[pTex2DAuthor->author height];
        } // if
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL Texture 2D Author - Allocating memory for authoring failed!" );
    } // else
	
	return( pTex2DAuthor );
} // OpenGLTexture2DAuthorCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorDelete(OpenGLTexture2DAuthorDataRef pTex2DAuthor)
{
	if( pTex2DAuthor != NULL )
	{
        if( pTex2DAuthor->author )
        {
            [pTex2DAuthor->author release];
            
            pTex2DAuthor->author = nil;
        } // if
        
		free( pTex2DAuthor );
		
		pTex2DAuthor = NULL;
	} // if
} // OpenGLTexture2DAuthorDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLTexture2DAuthor

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initTexture2DAuthorWithSize:(const NSSize *)theSize
                             usage:(const GLenum)theUsage
                            target:(const GLenum)theTarget
                            format:(const GLenum)theFormat
{
	self = [super init];
	
	if( self )
	{
		mpTex2DAuthor = OpenGLTexture2DAuthorCreate(theSize, 
                                                    theUsage, 
                                                    theTarget, 
                                                    0, 
                                                    theFormat, 
                                                    NO);
	} // if
	
	return  self;
} // initTexture2DAuthorWithSize

//---------------------------------------------------------------------------

- (id) initTexture2DAuthorWithSize:(const NSSize *)theSize
                             usage:(const GLenum)theUsage
                            target:(const GLenum)theTarget
                             level:(const GLint)thelevel
                            format:(const GLenum)theFormat
                            border:(const BOOL)hasBorder
{
	self = [super init];
	
	if( self )
	{
		mpTex2DAuthor = OpenGLTexture2DAuthorCreate(theSize, 
                                                    theUsage, 
                                                    theTarget, 
                                                    thelevel, 
                                                    theFormat, 
                                                    hasBorder);
	} // if
	
	return  self;
} // initTexture2DAuthorWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLTexture2DAuthorDelete(mpTex2DAuthor);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLuint) texture
{
    return( [mpTex2DAuthor->author texture] );
} // texture

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( [mpTex2DAuthor->author target] );
} // target

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( [mpTex2DAuthor->author format] );
} // format

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( [mpTex2DAuthor->author width] );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( [mpTex2DAuthor->author height] );
} // height

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( [mpTex2DAuthor->author size] );
} // size

//---------------------------------------------------------------------------

- (GLint) level
{
    return( [mpTex2DAuthor->author level] );
} // level

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
    return( [mpTex2DAuthor->author rowBytes] );
} // rowbytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
    return( [mpTex2DAuthor->author samplesPerPixel] );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLfloat) aspect
{
    return( [mpTex2DAuthor->author aspect] );
} // aspect

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( [mpTex2DAuthor->author buffer] );
} // buffer

//---------------------------------------------------------------------------

- (NSSize) bounds
{
    return( mpTex2DAuthor->size );
} // bounds

//---------------------------------------------------------------------------

- (BOOL) isReadOnly
{
    return( mpTex2DAuthor->isReadOnly );
} // isReadOnly

//---------------------------------------------------------------------------

- (BOOL) isWriteOnly
{
    return( mpTex2DAuthor->isWriteOnly );
} // isWriteOnly

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( [mpTex2DAuthor->author setSize:theSize] );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) map
{
    return( [mpTex2DAuthor->author map] );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( [mpTex2DAuthor->author unmap] );
} // unmap

//---------------------------------------------------------------------------

- (void) bind
{
	[mpTex2DAuthor->author bind];
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
	[mpTex2DAuthor->author unbind];
} // unbind

//---------------------------------------------------------------------------

- (BOOL) copy:(const GLvoid *)theBuffer
      needsVR:(const BOOL)doVR
{
    return( [mpTex2DAuthor->author copy:theBuffer
                                needsVR:doVR] );
} // write

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
