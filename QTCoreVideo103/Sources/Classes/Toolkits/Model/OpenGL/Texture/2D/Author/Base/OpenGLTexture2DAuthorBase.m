//---------------------------------------------------------------------------
//
//	File: OpenGLTexture2DAuthorBase.m
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

#import "OpenGLCopier.h"
#import "OpenGLPBO.h"
#import "OpenGLTexture2D.h"
#import "OpenGLTexture2DAuthorBase.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTexture2DAuthorBaseData
{
	OpenGLPBO       *pbo;       // OpenGL PBO
	OpenGLTexture2D *texture;   // OpenGL texture
    OpenGLCopier    *copier;    // For memory copy
};

typedef struct OpenGLTexture2DAuthorBaseData OpenGLTexture2DAuthorBaseData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static inline BOOL OpenGLTexture2DAuthorBaseCreateBuffer(const GLenum  usage,
                                                         OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    pTex2DAuthorBase->pbo = [[OpenGLPBO alloc] initPBOWithSize:[pTex2DAuthorBase->texture size] 
                                                         usage:usage];
    
    return( pTex2DAuthorBase->pbo != nil );
} // OpenGLTexture2DAuthorBaseCreateBuffer

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DAuthorBaseCreateCopier(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    pTex2DAuthorBase->copier = [[OpenGLCopier alloc] initCopierWithFormat:[pTex2DAuthorBase->texture format] 
                                                                    width:[pTex2DAuthorBase->texture width] 
                                                                   height:[pTex2DAuthorBase->texture height]];
    
    BOOL success = pTex2DAuthorBase->copier != nil;
    
    if( success )
    {
        [pTex2DAuthorBase->copier setFixAlpha:NO];
    } // if
    
    return( success );
} // OpenGLTexture2DAuthorBaseCreateCopier

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseCreateAssets(const NSSize *pSize,
                                                  const GLenum  usage,
                                                  const GLenum target,
                                                  const GLint level,
                                                  const GLenum format,
                                                  const BOOL hasBorder,
                                                  OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    pTex2DAuthorBase->texture = [[OpenGLTexture2D alloc] initTexture2DWithSize:pSize
                                                                        target:target
                                                                         level:level
                                                                        format:format
                                                                          hint:0
                                                                        border:hasBorder];
    
    if( pTex2DAuthorBase->texture )
    {
        OpenGLTexture2DAuthorBaseCreateBuffer(usage, pTex2DAuthorBase);
        OpenGLTexture2DAuthorBaseCreateCopier(pTex2DAuthorBase);
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL Texture 2D Author Base - Instantiating texture 2D object failed!" );
    } // else
} // OpenGLTexture2DAuthorBaseCreateAssets

//---------------------------------------------------------------------------

static OpenGLTexture2DAuthorBaseDataRef OpenGLTexture2DAuthorBaseCreate(const NSSize *pSize,
                                                                        const GLenum  usage,
                                                                        const GLenum target,
                                                                        const GLint level,
                                                                        const GLenum format,
                                                                        const BOOL hasBorder)
{
	OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase 
    = (OpenGLTexture2DAuthorBaseDataRef)calloc(1, sizeof(OpenGLTexture2DAuthorBaseData));
	
	if( pTex2DAuthorBase != NULL )
	{
        OpenGLTexture2DAuthorBaseCreateAssets(pSize,
                                              usage,
                                              target,
                                              level,
                                              format,
                                              hasBorder,
                                              pTex2DAuthorBase);
	} // if
    else
    {
        NSLog( @">> ERROR: OpenGL Texture 2D Author Base - Allocating memory for authoring failed!" );
    } // else
	
	return( pTex2DAuthorBase );
} // OpenGLTexture2DAuthorBaseCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseDeleteCopier(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    if( pTex2DAuthorBase->copier )
    {
        [pTex2DAuthorBase->copier release];
        
        pTex2DAuthorBase->copier = nil;
    } // if
} // OpenGLTexture2DAuthorBaseDeleteCopier

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseDeleteBuffer(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    if( pTex2DAuthorBase->pbo )
    {
        [pTex2DAuthorBase->pbo release];
        
        pTex2DAuthorBase->pbo = nil;
    } // if
} // OpenGLTexture2DAuthorBaseDeleteBuffer

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseDeleteImage(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    if( pTex2DAuthorBase->texture )
    {
        [pTex2DAuthorBase->texture release];
        
        pTex2DAuthorBase->texture = nil;
    } // if
} // OpenGLTexture2DAuthorBaseDeleteImage

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseDeleteAssests(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    OpenGLTexture2DAuthorBaseDeleteCopier(pTex2DAuthorBase);
    OpenGLTexture2DAuthorBaseDeleteBuffer(pTex2DAuthorBase);
    OpenGLTexture2DAuthorBaseDeleteImage(pTex2DAuthorBase);
} // OpenGLTexture2DAuthorBaseDeleteAssests

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseDelete(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
	if( pTex2DAuthorBase != NULL )
	{
		OpenGLTexture2DAuthorBaseDeleteAssests(pTex2DAuthorBase);
		
		free( pTex2DAuthorBase );
		
		pTex2DAuthorBase = NULL;
	} // if
} // OpenGLTexture2DAuthorBaseDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DAuthorBaseUnmap(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    // Release pointer to the mapping buffer
    
    BOOL success = [pTex2DAuthorBase->pbo unmap];
    
    // At this stage, it is good idea to unbind PBOs.
    // Once bound to ID 0, all pixel operations default 
    // to normal behavior.  In our case since both PBOs
    // will have the same target we'll unbind once.
    
    [pTex2DAuthorBase->pbo unbind];
    
    return( success );
} // unmap

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseRead(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    [pTex2DAuthorBase->pbo bind];
    
    [pTex2DAuthorBase->pbo flush];
    
    [pTex2DAuthorBase->texture read:NULL];
} // OpenGLTexture2DAuthorBaseRead

//---------------------------------------------------------------------------

static void OpenGLTexture2DAuthorBaseWrite(OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    [pTex2DAuthorBase->pbo bind];
    
    [pTex2DAuthorBase->texture write:NULL];
    
    [pTex2DAuthorBase->pbo flush];
} // OpenGLTexture2DAuthorBaseWrite

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DAuthorBaseCopy(const BOOL doVR,
                                          const GLvoid *pPixelsSrc,
                                          OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    BOOL success = NO;
    
    if( [pTex2DAuthorBase->pbo writeOnly] )
    {
        [pTex2DAuthorBase->copier setNeedsVR:doVR];
        
        success = [pTex2DAuthorBase->copier copy:[pTex2DAuthorBase->pbo buffer] 
                                          source:pPixelsSrc];
    } // if
    
    return( success );
} // OpenGLTexture2DAuthorBaseCopy

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DAuthorBaseSetSize(const NSSize *pSize,
                                             OpenGLTexture2DAuthorBaseDataRef pTex2DAuthorBase)
{
    GLuint width  = (GLuint)pSize->width;
    GLuint height = (GLuint)pSize->height;
    
    BOOL success =      (width  != [pTex2DAuthorBase->texture width]) 
                    ||  (height != [pTex2DAuthorBase->texture height]);
    
    if( success )
    {
        success = [pTex2DAuthorBase->texture setSize:pSize];
        
        if( success )
        {
            [pTex2DAuthorBase->pbo setSize:[pTex2DAuthorBase->texture size]];
            
            [pTex2DAuthorBase->copier setProperties:[pTex2DAuthorBase->texture format] 
                                              width:[pTex2DAuthorBase->texture width] 
                                             height:[pTex2DAuthorBase->texture height]];
        } // if
    } // if
    
    return( success );
} // OpenGLTexture2DSetSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLTexture2DAuthorBase

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initTexture2DAuthorBaseWithSize:(const NSSize *)theSize
                                 usage:(const GLenum)theUsage
                                target:(const GLenum)theTarget
                                format:(const GLenum)theFormat
{
	self = [super init];
	
	if( self )
	{
		mpTex2DAuthorBase = OpenGLTexture2DAuthorBaseCreate(theSize, 
                                                            theUsage, 
                                                            theTarget, 
                                                            0, 
                                                            theFormat, 
                                                            NO);
	} // if
	
	return  self;
} // initTexture2DAuthorBaseWithSize

//---------------------------------------------------------------------------

- (id) initTexture2DAuthorBaseWithSize:(const NSSize *)theSize
                                 usage:(const GLenum)theUsage
                                target:(const GLenum)theTarget
                                 level:(const GLint)thelevel
                                format:(const GLenum)theFormat
                                border:(const BOOL)hasBorder
{
	self = [super init];
	
	if( self )
	{
		mpTex2DAuthorBase = OpenGLTexture2DAuthorBaseCreate(theSize, 
                                                            theUsage, 
                                                            theTarget, 
                                                            thelevel, 
                                                            theFormat, 
                                                            hasBorder);
	} // if
	
	return  self;
} // initTexture2DAuthorBaseWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLTexture2DAuthorBaseDelete(mpTex2DAuthorBase);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLuint) texture
{
    return( [mpTex2DAuthorBase->texture texture] );
} // texture

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( [mpTex2DAuthorBase->texture target] );
} // target

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( [mpTex2DAuthorBase->texture format] );
} // format

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( [mpTex2DAuthorBase->texture width] );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( [mpTex2DAuthorBase->texture height] );
} // height

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( [mpTex2DAuthorBase->texture size] );
} // size

//---------------------------------------------------------------------------

- (GLint) level
{
    return( [mpTex2DAuthorBase->texture level] );
} // level

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
    return( [mpTex2DAuthorBase->texture rowBytes] );
} // rowbytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
    return( [mpTex2DAuthorBase->texture samplesPerPixel] );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLfloat) aspect
{
    return( [mpTex2DAuthorBase->texture aspect] );
} // aspect

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( [mpTex2DAuthorBase->pbo buffer] );
} // buffer

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLTexture2DAuthorBaseSetSize(theSize, mpTex2DAuthorBase) );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) map
{
    return( [mpTex2DAuthorBase->pbo map] );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( OpenGLTexture2DAuthorBaseUnmap(mpTex2DAuthorBase) );
} // unmap

//---------------------------------------------------------------------------

- (void) read
{
    OpenGLTexture2DAuthorBaseRead(mpTex2DAuthorBase);
} // read

//---------------------------------------------------------------------------

- (void) write
{
    OpenGLTexture2DAuthorBaseWrite(mpTex2DAuthorBase);
} // write

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

- (void) bind
{
	[mpTex2DAuthorBase->texture bind];
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
	[mpTex2DAuthorBase->texture unbind];
} // unbind

//---------------------------------------------------------------------------

- (BOOL) copy:(const GLvoid *)theBuffer
      needsVR:(const BOOL)doVR
{
    return( OpenGLTexture2DAuthorBaseCopy(doVR, theBuffer, mpTex2DAuthorBase) );
} // copy

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
