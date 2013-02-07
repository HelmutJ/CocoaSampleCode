//---------------------------------------------------------------------------
//
//	File: OpenGLCopier.m
//
//  Abstract: A functor for copying pixels from a source to destination. 
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

#import "OpenGLImage2DBuffer.h"
#import "OpenGLUtilities.h"

#import "OpenGLCopier.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Function Pointer - Definition

//---------------------------------------------------------------------------

typedef void (*OpenGLMemCopyRowFuncPtr)(GLubyte  *pixelsDst, 
                                        const GLubyte *pixelsSrc,
                                        const GLuint pixelsCount,
                                        const GLuint pixelsSize);

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLCopierData
{
    BOOL                 fixAlpha;  // Fix the alpha channel
    BOOL                 doVR;      // Do vertical reflection
    BOOL                 isBGRA;    // Texture is BGRA format
    BOOL                 isVideo;   // Texture is Y'CbCr format
    GLenum               type;      // texture type
    GLenum               format;    // texture format
    const GLvoid        *data;      // Source data
    OpenGLImage2DBuffer  buffer;    // Destination memory buffer
};

typedef struct OpenGLCopierData  OpenGLCopierData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static void OpenGLCopierSetSize(const GLuint width,
                                const GLuint height,
                                OpenGLCopierDataRef pCopier)
{
    pCopier->buffer.width    = width; 
    pCopier->buffer.height   = height; 
    pCopier->buffer.spp      = OpenGLUtilitiesGetSPP(pCopier->type);
    pCopier->buffer.rowBytes = pCopier->buffer.width  * pCopier->buffer.spp;
    pCopier->buffer.size     = pCopier->buffer.height * pCopier->buffer.rowBytes;
    pCopier->buffer.data     = NULL;
} // OpenGLCopierSetSize

//---------------------------------------------------------------------------

static void OpenGLCopierSetFormat(const GLenum format,
                                  OpenGLCopierDataRef pCopier)
{
    pCopier->format  = format; 
    pCopier->isBGRA  = format == GL_BGRA;
    pCopier->isVideo = format == GL_YCBCR_422_APPLE;
    pCopier->type    = pCopier->isVideo ? GL_UNSIGNED_SHORT_8_8_APPLE : GL_UNSIGNED_INT_8_8_8_8_REV;
 } // OpenGLCopierSetFormat

//---------------------------------------------------------------------------

static void OpenGLCopierSetProperties(const GLuint width,
                                      const GLuint height,
                                      const GLenum format,
                                      OpenGLCopierDataRef pCopier)
{
    OpenGLCopierSetFormat(format, pCopier);
    OpenGLCopierSetSize(width, height, pCopier);
} // OpenGLCopierSetProperties

//---------------------------------------------------------------------------

static OpenGLCopierDataRef OpenGLCopierCreate(const GLuint width,
                                              const GLuint height,
                                              const GLenum format)
{
    OpenGLCopierDataRef pCopier = (OpenGLCopierDataRef)calloc(1, sizeof(OpenGLCopierData));
    
    if( pCopier != NULL )
    {
        OpenGLCopierSetProperties(width, height, format, pCopier);
    } // if
    else
    {
        NSLog(@">> ERROR: OpenGL Copier - Failed allocating memory for copier backing store!");
    }  // else
	
	return( pCopier );
} // OpenGLCopierCreateWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLCopierDelete(OpenGLCopierDataRef pCopier) 
{
    if( pCopier != NULL )
    {        
        free( pCopier );
        
        pCopier = NULL;
    } // if
} // OpenGLCopierDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------
//
// Fix alpha channel layout and copy pixels
//
//---------------------------------------------------------------------------

static void OpenGLMemCopyRowFixAlpha(GLubyte  *pixelsDst, 
                                     const GLubyte *pixelsSrc,
                                     const GLuint pixelsCount,
                                     const GLuint pixelsSize)
{
    uint32_t  i;
    uint32_t  iMax   = pixelsCount;
    uint32_t *pixels = (uint32_t *)pixelsSrc;
    
    for( i = 0; i < iMax; ++i )
    {
        pixels[i] = (pixels[i] << 24) | ((pixels[i] & 0xFF00) << 8) | ((pixels[i] >> 8) & 0xFF00) | (pixels[i] >> 24);
    } // for
    
    memcpy(pixelsDst, pixelsSrc, pixelsSize);
} // OpenGLMemCopyRowFixAlpha

//---------------------------------------------------------------------------

static void OpenGLMemCopyRowDefault(GLubyte  *pixelsDst, 
                                    const GLubyte *pixelsSrc,
                                    const GLuint pixelsCount,
                                    const GLuint pixelsSize)
{
    memcpy(pixelsDst, pixelsSrc, pixelsSize);
} // OpenGLMemCopyRowDefault

//---------------------------------------------------------------------------
//
// Copy memory from a source buffer to a destination buffer, fix 
// alpha channel if desired, and vertical reflect.
//
//---------------------------------------------------------------------------

static void OpenGLCopierVR(OpenGLCopierDataRef pCopier)
{
    uint32_t i;
    uint32_t iMax = pCopier->buffer.height;
    
    GLuint pixelsSrcWidth    = pCopier->buffer.width;
    GLuint pixelsSrcRowBytes = pCopier->buffer.rowBytes;
    GLuint pixelsSrcSize     = pCopier->buffer.size;
    GLuint pixelsSrcTopRow   = pixelsSrcSize - pixelsSrcRowBytes;
    GLuint pixelsDstRowBytes = pixelsSrcRowBytes;
    
    GLubyte *pixelsDst = (GLubyte *)pCopier->buffer.data;
    
    const GLubyte *pixelsSrc = (const GLubyte *)(pCopier->data + pixelsSrcTopRow);
    
    OpenGLMemCopyRowFuncPtr GLMemCopy = (pCopier->fixAlpha && pCopier->isBGRA) 
    ? &OpenGLMemCopyRowFixAlpha 
    : &OpenGLMemCopyRowDefault;
    
    for( i = 0; i < iMax; ++i )
    {
        GLMemCopy(pixelsDst, 
                  pixelsSrc, 
                  pixelsSrcWidth, 
                  pixelsDstRowBytes);
        
        pixelsSrc -= pixelsSrcRowBytes;
        pixelsDst += pixelsDstRowBytes;
    } // for
} // OpenGLCopierVR

//---------------------------------------------------------------------------
//
// Copy memory from a source buffer to a destination buffer and fix 
// alpha channel if desired.
//
//---------------------------------------------------------------------------

static void OpenGLCopierDefault(OpenGLCopierDataRef pCopier)
{
    if(pCopier->fixAlpha && pCopier->isBGRA)
    {
        uint32_t i;
        uint32_t iMax = pCopier->buffer.height;
        
        GLuint pixelsSrcWidth    = pCopier->buffer.width;
        GLuint pixelsSrcRowBytes = pCopier->buffer.rowBytes;
        GLuint pixelsDstRowBytes = pCopier->buffer.rowBytes;
        
        GLubyte *pixelsDst = (GLubyte *)pCopier->buffer.data;
        
        const GLubyte *pixelsSrc = (const GLubyte *)pCopier->data;
        
        for( i = 0; i < iMax; ++i )
        {
            OpenGLMemCopyRowFixAlpha(pixelsDst, 
                                     pixelsSrc, 
                                     pixelsSrcWidth, 
                                     pixelsDstRowBytes);
            
            pixelsSrc += pixelsSrcRowBytes;
            pixelsDst += pixelsDstRowBytes;
        } // for
    } // if
    else
    {
        memcpy(pCopier->buffer.data, 
               pCopier->data, 
               pCopier->buffer.size);
    } // else
} // OpenGLCopierFixAlpha

//---------------------------------------------------------------------------

static BOOL OpenGLCopierFunctorMain(const GLvoid *pSrc,
                                    GLvoid *pDst,
                                    OpenGLCopierDataRef pCopier)
{
    BOOL success = (pSrc != NULL) && (pDst != NULL);
    
    if( success )
    {
        pCopier->data = pSrc;
        
        pCopier->buffer.data = pDst;
        
        if( pCopier->doVR )
        { 
            OpenGLCopierVR(pCopier);
        } // if
        else
        {
            OpenGLCopierDefault(pCopier);
        } // else
    } // if
    
    return( success );
} // OpenGLCopierFunctorMain

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLCopier

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initCopierWithFormat:(const GLenum)theFormat
                      width:(const GLuint)theWidth
                     height:(const GLuint)theHeight
{
	self = [super init];
	
	if( self )
	{
		mpCopier = OpenGLCopierCreate(theWidth, 
                                      theHeight, 
                                      theFormat);
	} // if
	
	return  self;
} // initCopierWithFormat

//---------------------------------------------------------------------------

+ (id) copierWithFormat:(const GLenum)theFormat
                  width:(const GLuint)theWidth
                 height:(const GLuint)theHeight
{
	return( [[[OpenGLCopier allocWithZone:[self zone]] initCopierWithFormat:theFormat
                                                                      width:theWidth
                                                                     height:theHeight] autorelease] );
} // copierWithFormat

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLCopierDelete(mpCopier);
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (void) setNeedsVR:(const BOOL)doVR
{
    mpCopier->doVR = doVR;
} // setNeedsVR

//---------------------------------------------------------------------------

- (void) setFixAlpha:(const BOOL)doFixAlpha
{
    mpCopier->fixAlpha = doFixAlpha;
} // setFixAlpha

//---------------------------------------------------------------------------

- (void) setProperties:(const GLenum)theFormat
                 width:(const GLuint)theWidth
                height:(const GLuint)theHeight
{
    OpenGLCopierSetProperties(theWidth, theHeight, theFormat, mpCopier);
} // setProperties

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) copy:(GLvoid *)theDst
       source:(const GLvoid *)theSrc;
{
    return( OpenGLCopierFunctorMain(theSrc, theDst, mpCopier) );
} // copy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
