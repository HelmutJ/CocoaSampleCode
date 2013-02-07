//---------------------------------------------------------------------------
//
//	File: OpenGLImage2DAuthorBase.m
//
//  Abstract: Base utility toolkit for handling PBO Read or draw pixels.
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
//  Neither the buffer, trademarks, service marks or logos of Apple Computer,
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

#import "OpenGLImage2DBuffer.h"

#import "OpenGLUtilities.h"

#import "OpenGLCopier.h"
#import "OpenGLPBO.h"
#import "OpenGLImage2DAuthorBase.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLImage2DProperties
{
    GLenum  usage;
    GLenum  format;
    GLenum  source;
    GLenum  internal;
    GLint   offsets[2];
};

typedef struct OpenGLImage2DProperties   OpenGLImage2DProperties;

//---------------------------------------------------------------------------

struct OpenGLImage2DAuthorBaseData
{
    OpenGLImage2DBuffer      buffer;
    OpenGLImage2DProperties  props;
    
    OpenGLPBO    *pbo;
    OpenGLCopier *copier;
};

typedef struct OpenGLImage2DAuthorBaseData   OpenGLImage2DAuthorBaseData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static void OpenGLImage2DAuthorBaseInitProperties(const GLenum usage,
                                                  const GLenum format,
                                                  OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    BOOL isVideo = format == GL_YCBCR_422_APPLE;
    BOOL isBGRA  = format == GL_BGRA;
    BOOL isValid = isVideo || isBGRA;
    
    pImage2DAuthorBase->props.format     = isValid ? format : GL_BGRA;
    pImage2DAuthorBase->props.source     = isVideo ? GL_UNSIGNED_SHORT_8_8_APPLE : GL_UNSIGNED_INT_8_8_8_8_REV;
    pImage2DAuthorBase->props.internal   = GL_UNSIGNED_BYTE;
    pImage2DAuthorBase->props.usage      = usage;
    pImage2DAuthorBase->props.offsets[0] = 0;
    pImage2DAuthorBase->props.offsets[1] = 0;
} // OpenGLImage2DAuthorBaseInitProperties

//---------------------------------------------------------------------------

static void OpenGLImage2DAuthorBaseInitBuffer(const NSSize *pSize,
                                              OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    pImage2DAuthorBase->buffer.width    = (GLuint)pSize->width;
    pImage2DAuthorBase->buffer.height   = (GLuint)pSize->height;
    pImage2DAuthorBase->buffer.spp      = OpenGLUtilitiesGetSPP(pImage2DAuthorBase->props.source);
    pImage2DAuthorBase->buffer.rowBytes = pImage2DAuthorBase->buffer.width * pImage2DAuthorBase->buffer.spp;
    pImage2DAuthorBase->buffer.size     = pImage2DAuthorBase->buffer.rowBytes * pImage2DAuthorBase->buffer.height;
    pImage2DAuthorBase->buffer.aspect   = (GLfloat)pImage2DAuthorBase->buffer.width / (GLfloat)pImage2DAuthorBase->buffer.height;
    pImage2DAuthorBase->buffer.data     = NULL;
} // OpenGLImage2DAuthorBaseInitBuffer

//---------------------------------------------------------------------------

static inline BOOL OpenGLImage2DAuthorBaseCreateBuffer(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    pImage2DAuthorBase->pbo = [[OpenGLPBO alloc] initPBOWithSize:pImage2DAuthorBase->buffer.size 
                                                           usage:pImage2DAuthorBase->props.usage];
    
    return( pImage2DAuthorBase->pbo != nil );
} // OpenGLImage2DAuthorBaseCreateBuffer

//---------------------------------------------------------------------------

static inline BOOL OpenGLImage2DAuthorBaseCreateCopier(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    pImage2DAuthorBase->copier = [[OpenGLCopier alloc] initCopierWithFormat:pImage2DAuthorBase->props.format
                                                                      width:pImage2DAuthorBase->buffer.width
                                                                     height:pImage2DAuthorBase->buffer.height];
    
    return( pImage2DAuthorBase->copier != nil );
} // OpenGLImage2DAuthorBaseCreateCopier

//---------------------------------------------------------------------------

static BOOL OpenGLImage2DAuthorBaseCreateAssets(const NSSize *pSize,
                                                const GLenum usage,
                                                const GLenum format,
                                                OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    BOOL success = NO;
    
    OpenGLImage2DAuthorBaseInitProperties(usage, format, pImage2DAuthorBase);
    OpenGLImage2DAuthorBaseInitBuffer(pSize, pImage2DAuthorBase);
    
    if( OpenGLImage2DAuthorBaseCreateBuffer(pImage2DAuthorBase) )
    {
        success = OpenGLImage2DAuthorBaseCreateCopier(pImage2DAuthorBase);
    } // if
    
    return( success );
} // OpenGLImage2DAuthorBaseCreateBuffer

//---------------------------------------------------------------------------

static OpenGLImage2DAuthorBaseDataRef OpenGLImage2DAuthorBaseCreate(const NSSize *pSize,
                                                                    const GLenum usage,
                                                                    const GLenum format)
{
    OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase 
    = (OpenGLImage2DAuthorBaseDataRef)calloc(1, sizeof(OpenGLImage2DAuthorBaseData));
    
    if( pImage2DAuthorBase != NULL )
    {
        OpenGLImage2DAuthorBaseCreateAssets(pSize, usage, format, pImage2DAuthorBase);
    } // if
    else
    {
        NSLog( @"OpenGL Read Pixels - Failure allocating memory for the backing store!" );
    } // else
    
    return( pImage2DAuthorBase );
} // OpenGLImage2DAuthorBaseCreate

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void  OpenGLImage2DAuthorBaseDeleteCopier(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    if( pImage2DAuthorBase->copier )
    {
        [pImage2DAuthorBase->copier release];
        
        pImage2DAuthorBase->copier = nil;
    } // if
} // OpenGLImage2DAuthorBaseDeleteCopier

//---------------------------------------------------------------------------

static void  OpenGLImage2DAuthorBaseDeleteBuffer(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    if( pImage2DAuthorBase->pbo )
    {
        [pImage2DAuthorBase->pbo release];
        
        pImage2DAuthorBase->pbo = nil;
    } // if
} // OpenGLImage2DAuthorBaseDeleteBuffer

//---------------------------------------------------------------------------

static void  OpenGLImage2DAuthorBaseDeleteAssets(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    OpenGLImage2DAuthorBaseDeleteCopier(pImage2DAuthorBase);
    OpenGLImage2DAuthorBaseDeleteBuffer(pImage2DAuthorBase);
} // OpenGLImage2DAuthorBaseDeleteAssets

//---------------------------------------------------------------------------

static void  OpenGLImage2DAuthorBaseDelete(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
	if( pImage2DAuthorBase != NULL )
	{
        OpenGLImage2DAuthorBaseDeleteAssets(pImage2DAuthorBase);
        
		free( pImage2DAuthorBase );
		
		pImage2DAuthorBase = NULL;
	} // if
} // OpenGLImage2DAuthorBaseDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------
//
// Copy pixels from framebuffer to PBO by using offset instead of a 
// pointer. OpenGL should perform asynch DMA transfer, so that the
// glReadPixels API returns immediately.
//
//---------------------------------------------------------------------------

static void OpenGLImage2DAuthorBaseRead(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    [pImage2DAuthorBase->pbo bind];
    
    [pImage2DAuthorBase->pbo flush];
    
    glReadPixels(pImage2DAuthorBase->props.offsets[0], 
                 pImage2DAuthorBase->props.offsets[1], 
                 pImage2DAuthorBase->buffer.width,
                 pImage2DAuthorBase->buffer.height, 
                 pImage2DAuthorBase->props.format, 
                 pImage2DAuthorBase->props.internal, 
                 NULL);
} // OpenGLImage2DAuthorBaseReadPixels

//---------------------------------------------------------------------------
//
// Draw pixels to a framebuffer with PBO by using offset instead of a 
// pointer. OpenGL should perform asynch DMA transfer, so that the
// glDrawPixels API returns immediately.
//
//---------------------------------------------------------------------------

static void OpenGLImage2DAuthorBaseWrite(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    [pImage2DAuthorBase->pbo bind];
    
    glDrawPixels(pImage2DAuthorBase->buffer.width, 
                 pImage2DAuthorBase->buffer.height, 
                 pImage2DAuthorBase->props.format, 
                 pImage2DAuthorBase->props.internal, 
                 NULL);
    
    [pImage2DAuthorBase->pbo flush];
} // OpenGLImage2DAuthorBaseDrawPixels

//---------------------------------------------------------------------------

static BOOL OpenGLImage2DAuthorBaseUnmap(OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    // Release pointer to the mapping buffer
    
    BOOL success = [pImage2DAuthorBase->pbo unmap];
    
    // At this stage, it is good idea to unbind PBOs.
    // Once bound to ID 0, all pixel operations default 
    // to normal behavior.  In our case since both PBOs
    // will have the same target we'll unbind once.
    
    [pImage2DAuthorBase->pbo unbind];
    
    return( success );
} // OpenGLImage2DAuthorBaseUnmap

//---------------------------------------------------------------------------

static BOOL OpenGLImage2DAuthorBaseCopy(const BOOL doVR,
                                        const GLvoid *pPixelsSrc,
                                        OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    BOOL success = NO;
    
    if( [pImage2DAuthorBase->pbo writeOnly] )
    {
        [pImage2DAuthorBase->copier setNeedsVR:doVR];
        
        success = [pImage2DAuthorBase->copier copy:[pImage2DAuthorBase->pbo buffer] 
                                            source:pPixelsSrc];
    } // if
    
    return( success );
} // OpenGLImage2DAuthorBaseCopy

//---------------------------------------------------------------------------

static BOOL OpenGLImage2DAuthorBaseSetSize(const NSSize *pSize,
                                           OpenGLImage2DAuthorBaseDataRef pImage2DAuthorBase)
{
    BOOL success = pSize != NULL;
    
    if( success )
    {
        GLuint width  = (GLuint)pSize->width;
        GLuint height = (GLuint)pSize->height;
        
        success =       ( width  != pImage2DAuthorBase->buffer.width  ) 
                    ||	( height != pImage2DAuthorBase->buffer.height );
        
        if( success )
        {
            OpenGLImage2DAuthorBaseInitBuffer(pSize, pImage2DAuthorBase);
            
            [pImage2DAuthorBase->pbo setSize:pImage2DAuthorBase->buffer.size];
        } // if
    } // if
    
    return( success );
} // OpenGLImage2DAuthorBaseSetSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLImage2DAuthorBase

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------
//
// Make sure client goes through designated initializer
//
//---------------------------------------------------------------------------

- (id) init
{
	[self doesNotRecognizeSelector:_cmd];
	
	return nil;
} // init

//---------------------------------------------------------------------------

- (id) initImage2DAuthorBaseWithSize:(const NSSize *)theSize
                               usage:(const GLenum)theUsage
                              format:(const GLenum)theFormat
{
	self = [super init];
	
	if( self )
	{
		mpImage2DAuthorBase = OpenGLImage2DAuthorBaseCreate(theSize, 
                                                            theUsage, 
                                                            theFormat);
	} // if
	
	return  self;
} // initImage2DAuthorBaseWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	OpenGLImage2DAuthorBaseDelete(mpImage2DAuthorBase);
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) read
{
	OpenGLImage2DAuthorBaseRead(mpImage2DAuthorBase);
} // map

//---------------------------------------------------------------------------

- (void) write
{
	OpenGLImage2DAuthorBaseWrite(mpImage2DAuthorBase);
} // map

//---------------------------------------------------------------------------

- (BOOL) map
{
	return( [mpImage2DAuthorBase->pbo map] );
} // map

//---------------------------------------------------------------------------

- (BOOL) unmap
{
    return( OpenGLImage2DAuthorBaseUnmap(mpImage2DAuthorBase) );
} // unmap

//---------------------------------------------------------------------------

- (BOOL) copy:(const GLvoid *)theBuffer
      needsVR:(const BOOL)doVR
{
    return( OpenGLImage2DAuthorBaseCopy(doVR, theBuffer, mpImage2DAuthorBase) );
} // copy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark PBO Setters

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLImage2DAuthorBaseSetSize(theSize, mpImage2DAuthorBase) );
} // setSize

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
	return( [mpImage2DAuthorBase->pbo buffer] );
} // data

//---------------------------------------------------------------------------

- (GLuint) size
{
	return( mpImage2DAuthorBase->buffer.size );
} // size

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
	return( mpImage2DAuthorBase->buffer.rowBytes );
} // rowBytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
	return( mpImage2DAuthorBase->buffer.spp );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLuint) width
{
	return( mpImage2DAuthorBase->buffer.width );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
	return( mpImage2DAuthorBase->buffer.height );
} // height

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
