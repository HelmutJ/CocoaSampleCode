//---------------------------------------------------------------------------
//
//	File: OpenGLTexture2D.m
//
//  Abstract: Utility toolkit for handling hinted texture 2D or rectangles.
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
#import "OpenGLSurface2D.h"
#import "OpenGLUtilities.h"
#import "OpenGLImage2DBuffer.h"
#import "OpenGLTexture2D.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTex2DAttribs
{
    BOOL      isPrivate;      // Texture 2D is using private storage
    BOOL      isShared;       // Texture 2D is using shared storage
    BOOL      isCached;       // Texture 2D is using cached storage
    BOOL      isTex2D;        // The target is texture 2D & not texture rectangle
    BOOL      hasSurface;     // Texture 2D is using global i/o surfaces
    BOOL      hasMipmaps;     // Auto mipmap generation
    GLint     hint;           // Texture 2D hint
	GLint     level;          // level-of-detail	number
	GLint     border;         // width of the border, either 0  or 1
	GLint     xoffset;        // x offset for texture 2D copy
	GLint     yoffset;        // y offset for texture 2D copy
	GLuint    name;           // Texture 2D id
	GLenum    target;         // e.g., texture 2D or texture 2D rectangle
	GLenum    format;         // format
	GLenum    internal;       // internal format
	GLenum    sized;          // OpenGL sized type
	GLenum    type;           // OpenGL specific type
    GLvoid   *pixels;         // Image buffer for texture
};

typedef struct OpenGLTex2DAttribs  OpenGLTex2DAttribs;

//---------------------------------------------------------------------------

struct OpenGLTexture2DData
{
    OpenGLCopier        *copier;    // Copy functor
    OpenGLSurface2D     *surface;   // I/O surface backing store
    OpenGLTex2DAttribs   texture;   // Texture attributes
    OpenGLImage2DBuffer  image;     // Image buffer
};

typedef struct OpenGLTexture2DData  OpenGLTexture2DData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructors

//---------------------------------------------------------------------------

static void OpenGLTexture2DDeleteSurface(OpenGLTexture2DDataRef pTexture2D) 
{
    if( pTexture2D->surface )
    {
        [pTexture2D->surface release];
        
        pTexture2D->surface = nil;
    } // if
} // OpenGLTexture2DDeleteSurface

//---------------------------------------------------------------------------

static void OpenGLTexture2DDeleteCopier(OpenGLTexture2DDataRef pTexture2D) 
{
    if( pTexture2D->copier )
    {
        [pTexture2D->copier release];
        
        pTexture2D->copier = nil;
    } // if
} // OpenGLTexture2DDeleteCopier

//---------------------------------------------------------------------------

static void OpenGLTexture2DDeleteName(OpenGLTexture2DDataRef pTexture2D) 
{
    if( pTexture2D->texture.name )
    {
        glDeleteTextures(1, &pTexture2D->texture.name);
        
        pTexture2D->texture.name = 0;
    } // if
} // OpenGLTexture2DDeleteName

//---------------------------------------------------------------------------

static void OpenGLTexture2DDeleteImage(OpenGLTexture2DDataRef pTexture2D) 
{
    if( pTexture2D->image.data != NULL )
    {
        free(pTexture2D->image.data);
        
        pTexture2D->image.data = NULL;
    } // if
} // OpenGLTexture2DDeleteImage

//---------------------------------------------------------------------------

static void OpenGLTexture2DDeleteAssets(OpenGLTexture2DDataRef pTexture2D) 
{
    OpenGLTexture2DDeleteCopier(pTexture2D);
    OpenGLTexture2DDeleteSurface(pTexture2D);
    OpenGLTexture2DDeleteName(pTexture2D);
    OpenGLTexture2DDeleteImage(pTexture2D);
} // OpenGLTexture2DDeleteAssets

//---------------------------------------------------------------------------

static void OpenGLTexture2DDelete(OpenGLTexture2DDataRef pTexture2D) 
{
    if( pTexture2D != NULL )
    {
        OpenGLTexture2DDeleteAssets(pTexture2D);
        
        free( pTexture2D );
        
        pTexture2D = NULL;
    } // if
} // OpenGLTexture2DDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessor - Bounds

//---------------------------------------------------------------------------

static void OpenGLTexture2DTestAndSetSize(const NSSize *pSize,
                                          OpenGLTexture2DDataRef pTexture2D)
{
    NSSize  size;
    
    if( pSize != NULL )
    {
        size.width  = pSize->width;
        size.height = pSize->height;
    } // if
    else
    {
        size.width  = 1920.0f;
        size.height = 1080.0f;
    } // else
    
    pTexture2D->image.aspect = size.width / size.height;
    
    pTexture2D->image.width  = (GLuint)size.width;
    pTexture2D->image.height = (GLuint)size.height;
} // OpenGLTexture2DTestAndSetSize

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DProxyImage(OpenGLTexture2DDataRef pTexture2D)
{
    GLint width  = 0;
    GLint height = 0;
    
    glTexImage2D(GL_PROXY_TEXTURE_2D, 
				 pTexture2D->texture.level, 
				 pTexture2D->texture.internal, 
				 pTexture2D->image.width, 
				 pTexture2D->image.height, 
				 pTexture2D->texture.border, 
				 pTexture2D->texture.format, 
				 pTexture2D->texture.type, 
				 NULL);
    
    glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 
                             0,
                             GL_TEXTURE_WIDTH, 
                             &width);
    
    glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 
                             0,
                             GL_TEXTURE_HEIGHT, 
                             &height);
    
    return( (width == 0) || (height == 0) );
} // OpenGLTexture2DProxyImage

//---------------------------------------------------------------------------

static void OpenGLTexture2DRecalcSize(OpenGLTexture2DDataRef pTexture2D)
{
    GLint maxSize = 0;
    
    glGetIntegerv( GL_MAX_TEXTURE_SIZE, &maxSize );
    
    if( pTexture2D->image.aspect > 1.0f )
    {
        pTexture2D->image.width  = maxSize; 
        pTexture2D->image.height = maxSize / (GLuint)pTexture2D->image.aspect;
    } // if
    else
    {
        pTexture2D->image.width  = maxSize * (GLuint)pTexture2D->image.aspect;
        pTexture2D->image.height = maxSize; 
    } // else
    
    GLfloat width  = (GLfloat)pTexture2D->image.width;
    GLfloat height = (GLfloat)pTexture2D->image.height;
    
    pTexture2D->image.aspect = width / height;
} // OpenGLTexture2DRecalcSize

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DSetSize(const NSSize *pSize,
                                   OpenGLTexture2DDataRef pTexture2D)
{
    GLuint width  = (GLuint)pSize->width;
    GLuint height = (GLuint)pSize->height;
    
    BOOL success =      (width  != pTexture2D->image.width) 
    ||  (height != pTexture2D->image.height);
    
    if( success )
    {
        OpenGLTexture2DTestAndSetSize(pSize, pTexture2D);
        
        if( OpenGLTexture2DProxyImage(pTexture2D) )
        {
            OpenGLTexture2DRecalcSize(pTexture2D);
        } // if
    } // if
    
    return( success );
} // OpenGLTexture2DSetSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessors

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DSetHint(const NSInteger hint,
                                          OpenGLTexture2DDataRef pTexture2D)
{
    BOOL storageNone    = hint == 0;
    BOOL storagePrivate = hint == GL_STORAGE_PRIVATE_APPLE;
    BOOL storageShared  = hint == GL_STORAGE_SHARED_APPLE;
    BOOL storageCached  = hint == GL_STORAGE_CACHED_APPLE;
    
    BOOL hinted = storageNone || storagePrivate || storageShared || storageCached;
    
	pTexture2D->texture.hint = hinted ? hint : 0;
    
	pTexture2D->texture.isPrivate = storageNone || storagePrivate;
	pTexture2D->texture.isShared  = storageShared;
	pTexture2D->texture.isCached  = storageCached;
    
	pTexture2D->texture.hasSurface = storageCached || storagePrivate;
} // OpenGLTexture2DSetHint

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DSetTarget(const GLenum target,
                                            OpenGLTexture2DDataRef pTexture2D)
{
    BOOL isTex2D   = target == GL_TEXTURE_2D;
    BOOL isTexRect = target == GL_TEXTURE_RECTANGLE_ARB;
    BOOL isValid   = isTexRect || isTex2D;
    
	pTexture2D->texture.target  = isValid ? target : GL_TEXTURE_2D;
	pTexture2D->texture.isTex2D = isTex2D;
} // OpenGLTexture2DSetTarget

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DSetLevel(const GLint level,
                                           OpenGLTexture2DDataRef pTexture2D)
{
	pTexture2D->texture.level = level;
} // OpenGLTexture2DSetLevel

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DSetBorder(const BOOL hasBorder,
                                            OpenGLTexture2DDataRef pTexture2D)
{
	pTexture2D->texture.border = hasBorder ? 1 : 0;
} // OpenGLTexture2DSetBorder

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DSetMipmaps(const BOOL hasMipmaps,
                                             OpenGLTexture2DDataRef pTexture2D)
{
	pTexture2D->texture.hasMipmaps = hasMipmaps && pTexture2D->texture.isTex2D;
} // OpenGLTexture2DSetMipmaps

//---------------------------------------------------------------------------
//
// Format              Type                           Internal   Sized
//                                                    Format     Internal
//                                                               Format
//---------------------------------------------------------------------------
//
// Non-linear RGBA
//----------------
// GL_BGRA             GL_UNSIGNED_INT_8_8_8_8_REV   GL_RGBA     GL_RGBA8
//
// "Video" format
// ---------------
// GL_YCBCR_422_APPLE  GL_UNSIGNED_SHORT_8_8_APPLE   GL_RGB      GL_RGB8
//
//---------------------------------------------------------------------------

static void OpenGLTexture2DSetFormat(const GLenum format,
                                     OpenGLTexture2DDataRef pTexture2D)
{
    BOOL isVideo = format == GL_YCBCR_422_APPLE;
    BOOL isBGRA  = format == GL_BGRA;
    BOOL isValid = isVideo || isBGRA;
    
    pTexture2D->texture.format = isValid ? format : GL_BGRA;
    
    if( isVideo )
    {
        pTexture2D->texture.type     = GL_UNSIGNED_SHORT_8_8_APPLE;
        pTexture2D->texture.internal = GL_RGB;
        pTexture2D->texture.sized    = GL_RGB8;
    } // if
    else
    {
        pTexture2D->texture.type     = GL_UNSIGNED_INT_8_8_8_8_REV;
        pTexture2D->texture.internal = GL_RGBA;
        pTexture2D->texture.sized    = GL_RGBA8;
    } // else
} // OpenGLTexture2DSetFormat

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initializers

//---------------------------------------------------------------------------

static void OpenGLTexture2DInitSurface(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->texture.hasSurface )
    {
        OpenGLTexture2DDeleteSurface(pTexture2D);
        
        pTexture2D->surface = [[OpenGLSurface2D alloc] initSurface2DWithWidth:pTexture2D->image.width 
                                                                       height:pTexture2D->image.height 
                                                                       format:pTexture2D->texture.format
                                                                     isGlobal:YES];
    } // if
} // OpenGLTexture2DInitSurface

//---------------------------------------------------------------------------

static void OpenGLTexture2DInitCopier(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->copier )
    {
        [pTexture2D->copier setProperties:pTexture2D->texture.format 
                                    width:pTexture2D->image.width 
                                   height:pTexture2D->image.height]; 
    } // if
    else
    {
        pTexture2D->copier = [[OpenGLCopier alloc] initCopierWithFormat:pTexture2D->texture.format
                                                                  width:pTexture2D->image.width 
                                                                 height:pTexture2D->image.height];
        
        if( pTexture2D->copier )
        {
            [pTexture2D->copier setFixAlpha:NO];
        } // if
    } // else
} // OpenGLTexture2DInitCopier

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DInitImage(OpenGLTexture2DDataRef pTexture2D)
{
	pTexture2D->image.spp      = OpenGLUtilitiesGetSPP(pTexture2D->texture.type);
	pTexture2D->image.rowBytes = pTexture2D->image.width  * pTexture2D->image.spp;
	pTexture2D->image.size     = pTexture2D->image.height * pTexture2D->image.rowBytes;
	pTexture2D->image.data     = NULL;
} // OpenGLTexture2DInitImage

//---------------------------------------------------------------------------

static inline void OpenGLTexture2DInitData(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->texture.isShared )
    {
        GLvoid *pData = realloc(pTexture2D->image.data, 
                                pTexture2D->image.size);
        
        if( pData != NULL )
        {
            pTexture2D->image.data = pData;
        } // if
        else
        {
            OpenGLTexture2DDeleteImage(pTexture2D);
            
            pTexture2D->image.data = calloc(1, pTexture2D->image.size);
        } // if
    } // if
} // OpenGLTexture2DInitData

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Copy Pixels

//---------------------------------------------------------------------------

static inline BOOL OpenGLTexture2DCopy(const BOOL doVR,
                                       const GLvoid *pPixelsSrc,
                                       OpenGLTexture2DDataRef pTexture2D)
{
    [pTexture2D->copier setNeedsVR:doVR];
    
    return( [pTexture2D->copier copy:pTexture2D->texture.pixels
                              source:pPixelsSrc] );
} // OpenGLTexture2DCopy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilties - Texture

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DGenerate(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->texture.isPrivate )
    {
        glTextureRangeAPPLE(pTexture2D->texture.target, 0, NULL);
        
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
    } // if
    else
    {
        GLvoid *pixels = ( pTexture2D->texture.isCached ) 
        ? [pTexture2D->surface base] 
        : pTexture2D->image.data;
        
        glTextureRangeAPPLE(pTexture2D->texture.target, 
                            pTexture2D->image.size, 
                            pixels);
        
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
    } // else
	
	glGenTextures(1, &pTexture2D->texture.name);
    
    return( pTexture2D->texture.name != 0 );
} // OpenGLTexture2DGenerate

//---------------------------------------------------------------------------

static void OpenGLTexture2DSetParams(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->texture.isPrivate )
    {
        glTexParameteri(pTexture2D->texture.target, 
                        GL_TEXTURE_STORAGE_HINT_APPLE, 
                        GL_STORAGE_PRIVATE_APPLE);
    }
    else
    {
        glTexParameteri(pTexture2D->texture.target, 
                        GL_TEXTURE_STORAGE_HINT_APPLE, 
                        pTexture2D->texture.hint);
	} // else
    
	glTexParameteri(pTexture2D->texture.target, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(pTexture2D->texture.target, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    if( pTexture2D->texture.hasMipmaps )
    {
        glTexParameterf(pTexture2D->texture.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(pTexture2D->texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        
        glTexParameteri(pTexture2D->texture.target, GL_GENERATE_MIPMAP, GL_TRUE);
    } // if
    else
    {
        glTexParameteri(pTexture2D->texture.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(pTexture2D->texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    } // else
} // OpenGLTexture2DSetParams

//---------------------------------------------------------------------------

static void OpenGLTexture2DImage(OpenGLTexture2DDataRef pTexture2D)
{
    pTexture2D->texture.pixels = ( pTexture2D->texture.hasSurface ) 
    ? [pTexture2D->surface base] 
    : pTexture2D->image.data;
    
    glTexImage2D(pTexture2D->texture.target, 
                 pTexture2D->texture.level, 
                 pTexture2D->texture.internal, 
                 pTexture2D->image.width,
                 pTexture2D->image.height, 
                 pTexture2D->texture.border, 
                 pTexture2D->texture.format, 
                 pTexture2D->texture.type, 
                 pTexture2D->texture.pixels);
} // OpenGLTexture2DImage

//---------------------------------------------------------------------------
//
// glGenerateMipmap generates mipmaps for the texture attached to target  
// of the active texture unit.
//
// Mipmap generation replaces texel array levels level base + 1 through 
// q with arrays derived from the level base array, regardless of their 
// previous contents. All other mimap arrays, including the level base 
// array, are left unchanged by this computation.
// 
// The internal formats of the derived mipmap arrays all match those of  
// the level base array. The contents of the derived arrays are computed  
// by repeated, filtered reduction of the level base array. For 2D texture
// arrays, each layer is filtered independently.
//
//---------------------------------------------------------------------------

static inline void OpenGLTexture2DGenMipmap(OpenGLTexture2DDataRef pTexture2D)
{
    if( pTexture2D->texture.hasMipmaps )
    {
        glGenerateMipmap(GL_TEXTURE_2D);
    } // if
} // OpenGLTexture2DGenMipmap

//---------------------------------------------------------------------------

static void OpenGLTexture2DAcquire(OpenGLTexture2DDataRef pTexture2D)
{
	glEnable(pTexture2D->texture.target);
    {
        OpenGLTexture2DDeleteName(pTexture2D);
        
        if( OpenGLTexture2DGenerate(pTexture2D) )
        {
            glBindTexture(pTexture2D->texture.target, 
                          pTexture2D->texture.name);
            {
                OpenGLTexture2DSetParams(pTexture2D);
                OpenGLTexture2DImage(pTexture2D);
                OpenGLTexture2DGenMipmap(pTexture2D);
            }
            glBindTexture(pTexture2D->texture.target, 0);
        } // if
    }
	glDisable(pTexture2D->texture.target);
} // OpenGLTexture2DAcquire

//---------------------------------------------------------------------------
//
// Enbale & bind the current texture 2D.
//
//---------------------------------------------------------------------------

static inline void OpenGLTexture2DBind(OpenGLTexture2DDataRef pTexture2D)
{
	glEnable(pTexture2D->texture.target);
	
	glBindTexture(pTexture2D->texture.target, 
				  pTexture2D->texture.name);
} // OpenGLTexture2DBind

//---------------------------------------------------------------------------
//
// Disable & unbind the current texture 2D.
//
//---------------------------------------------------------------------------

static inline void OpenGLTexture2DUnbind(OpenGLTexture2DDataRef pTexture2D)
{
	glBindTexture(pTexture2D->texture.target, 0);
    
	glDisable(pTexture2D->texture.target);
} // OpenGLTexture2DUnbind

//---------------------------------------------------------------------------

static void OpenGLTexture2DWrite(OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DBind(pTexture2D);
    
    glTexSubImage2D(pTexture2D->texture.target, 
                    pTexture2D->texture.level, 
                    pTexture2D->texture.xoffset, 
                    pTexture2D->texture.yoffset, 
                    pTexture2D->image.width,
                    pTexture2D->image.height,
                    pTexture2D->texture.format, 
                    pTexture2D->texture.type, 
                    pTexture2D->texture.pixels);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DWrite

//---------------------------------------------------------------------------

static void OpenGLTexture2DWriteWithBuffer(const GLvoid *pBuffer,
                                           OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DBind(pTexture2D);
    
    glTexSubImage2D(pTexture2D->texture.target, 
                    pTexture2D->texture.level, 
                    pTexture2D->texture.xoffset, 
                    pTexture2D->texture.yoffset, 
                    pTexture2D->image.width,
                    pTexture2D->image.height,
                    pTexture2D->texture.format, 
                    pTexture2D->texture.type, 
                    pBuffer);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DWriteWithBuffer

//---------------------------------------------------------------------------

static void OpenGLTexture2DRead(OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DBind(pTexture2D);
    
	glGetTexImage(pTexture2D->texture.target, 
				  pTexture2D->texture.level, 
				  pTexture2D->texture.format,
				  pTexture2D->texture.type, 
				  pTexture2D->texture.pixels);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DRead

//---------------------------------------------------------------------------

static void OpenGLTexture2DReadIntoBuffer(GLvoid *pBuffer,
                                          OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DBind(pTexture2D);
    
	glGetTexImage(pTexture2D->texture.target, 
				  pTexture2D->texture.level, 
				  pTexture2D->texture.format,
				  pTexture2D->texture.type, 
				  pBuffer);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DReadIntoBuffer

//---------------------------------------------------------------------------

static void OpenGLTexture2DCopyWithBuffer(const BOOL flag,
                                          const GLvoid *pBuffer,
                                          OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DCopy(flag, pBuffer, pTexture2D);
    
    OpenGLTexture2DBind(pTexture2D);
    
    glTexSubImage2D(pTexture2D->texture.target, 
                    pTexture2D->texture.level, 
                    pTexture2D->texture.xoffset, 
                    pTexture2D->texture.yoffset, 
                    pTexture2D->image.width,
                    pTexture2D->image.height,
                    pTexture2D->texture.format, 
                    pTexture2D->texture.type, 
                    pTexture2D->texture.pixels);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DCopyWithBuffer

//---------------------------------------------------------------------------

static void OpenGLTexture2DUpdateWithBuffer(const NSRect *pBounds,
                                            const GLvoid *pBuffer,
                                            OpenGLTexture2DDataRef pTexture2D)
{
    GLuint width = 0;
    GLuint height = 0;
    
    GLint offsets[2] = {0, 0};
    
    if( pBounds != NULL )
    {
        width  = (GLuint)pBounds->size.width;
        height = (GLuint)pBounds->size.height;
        
        offsets[0] = (GLint)pBounds->origin.x;
        offsets[1] = (GLint)pBounds->origin.y;
    } // if
    else
    {
        width  = pTexture2D->image.width;
        height = pTexture2D->image.height;
        
        offsets[0] = pTexture2D->texture.xoffset;
        offsets[1] = pTexture2D->texture.yoffset;
    } // else
    
    OpenGLTexture2DBind(pTexture2D);
    
    glTexSubImage2D(pTexture2D->texture.target, 
                    pTexture2D->texture.level, 
                    offsets[0], 
                    offsets[1], 
                    width,
                    height,
                    pTexture2D->texture.format, 
                    pTexture2D->texture.type, 
                    pBuffer);
    
    OpenGLTexture2DUnbind(pTexture2D);
} // OpenGLTexture2DUpdateWithBuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static BOOL OpenGLTexture2DAcquireWithSize(const NSSize *pSize,
                                           OpenGLTexture2DDataRef pTexture2D)
{
    BOOL success = OpenGLTexture2DSetSize(pSize, pTexture2D);
    
    if( success )
    {
        OpenGLTexture2DInitImage(pTexture2D);
        OpenGLTexture2DInitSurface(pTexture2D);
        OpenGLTexture2DInitCopier(pTexture2D);
        OpenGLTexture2DInitData(pTexture2D);
        
        OpenGLTexture2DAcquire(pTexture2D);
    } // if
    
    return( success );
} // OpenGLTexture2DAcquireWithSize

//---------------------------------------------------------------------------

static void OpenGLTexture2DCreateAssets(const NSSize *pSize,
                                        const GLenum target,
                                        const GLint level,
                                        const GLenum format,
                                        const GLenum hint,
                                        const BOOL hasBorder,
                                        const BOOL hasMipmaps,
                                        OpenGLTexture2DDataRef pTexture2D)
{
    OpenGLTexture2DSetHint(hint, pTexture2D);
    OpenGLTexture2DSetTarget(target, pTexture2D);
    OpenGLTexture2DSetFormat(format, pTexture2D);
    OpenGLTexture2DSetLevel(level, pTexture2D);
    OpenGLTexture2DSetBorder(hasBorder, pTexture2D);
    OpenGLTexture2DSetMipmaps(hasMipmaps, pTexture2D);
    
    OpenGLTexture2DAcquireWithSize(pSize, pTexture2D);
} // OpenGLTexture2DCreateAssets

//---------------------------------------------------------------------------

static OpenGLTexture2DDataRef OpenGLTexture2DCreateWithSize(const NSSize *pSize,
                                                            const GLenum target,
                                                            const GLint level,
                                                            const GLenum format,
                                                            const GLenum hint,
                                                            const BOOL hasBorder,
                                                            const BOOL hasMipmaps)
{
    OpenGLTexture2DDataRef pTexture2D = (OpenGLTexture2DDataRef)calloc(1, sizeof(OpenGLTexture2DData));
    
    if( pTexture2D != NULL )
    {
        OpenGLTexture2DCreateAssets(pSize,
                                    target,
                                    level,
                                    format,
                                    hint,
                                    hasBorder,
                                    hasMipmaps,
                                    pTexture2D);
    } // if
    else
    {
        NSLog(@">> ERROR: OpenGL Texture 2D - Failed allocating memory for texture 2D backing store!");
    }  // else
	
	return( pTexture2D );
} // OpenGLTexture2DCreateWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLTexture2D

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Designated Initializers

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initTexture2DWithSize:(const NSSize *)theSize
                      target:(const GLenum)theTarget
                       level:(const GLint)thelevel
                      format:(const GLenum)theFormat
                      border:(const BOOL)hasBorder
{
	self = [super init];
	
	if( self )
	{
		mpTexture2D = OpenGLTexture2DCreateWithSize(theSize, 
                                                    theTarget,
                                                    thelevel,
                                                    theFormat,
                                                    GL_STORAGE_PRIVATE_APPLE,
                                                    hasBorder,
                                                    NO);
	} // if
	
	return  self;
} // initTexture2DWithSize

//---------------------------------------------------------------------------

- (id) initTexture2DWithSize:(const NSSize *)theSize
                      target:(const GLenum)theTarget
                       level:(const GLint)thelevel
                      format:(const GLenum)theFormat
                        hint:(const GLenum)theHint
                      border:(const BOOL)hasBorder
{
	self = [super init];
	
	if( self )
	{
		mpTexture2D = OpenGLTexture2DCreateWithSize(theSize, 
                                                    theTarget, 
                                                    thelevel,
                                                    theFormat,
                                                    theHint,
                                                    hasBorder,
                                                    NO);
	} // if
	
	return  self;
} // initTexture2DWithSize

//---------------------------------------------------------------------------

- (id) initTexture2DWithSize:(const NSSize *)theSize
                      target:(const GLenum)theTarget
                       level:(const GLint)thelevel
                      format:(const GLenum)theFormat
                        hint:(const GLenum)theHint
                      border:(const BOOL)hasBorder
                     mipmaps:(const BOOL)hasMipmaps
{
	self = [super init];
	
	if( self )
	{
		mpTexture2D = OpenGLTexture2DCreateWithSize(theSize, 
                                                    theTarget, 
                                                    thelevel,
                                                    theFormat,
                                                    theHint,
                                                    hasBorder,
                                                    hasMipmaps);
	} // if
	
	return  self;
} // initTexture2DWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    OpenGLTexture2DDelete(mpTexture2D);
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLuint) texture
{
    return(mpTexture2D->texture.name);
} // texture

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( mpTexture2D->image.width );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( mpTexture2D->image.height );
} // height

//---------------------------------------------------------------------------

- (GLuint) size
{
    return( mpTexture2D->image.size );
} // size

//---------------------------------------------------------------------------

- (GLuint) rowBytes
{
    return( mpTexture2D->image.rowBytes );
} // rowbytes

//---------------------------------------------------------------------------

- (GLuint) samplesPerPixel
{
    return( mpTexture2D->image.spp );
} // samplesPerPixel

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpTexture2D->texture.target );
} // target

//---------------------------------------------------------------------------

- (GLenum) type
{
    return( mpTexture2D->texture.type );
} // type

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( mpTexture2D->texture.format );
} // format

//---------------------------------------------------------------------------

- (GLenum) internal
{
    return( mpTexture2D->texture.internal );
} // internal

//---------------------------------------------------------------------------

- (GLenum) sized
{
    return( mpTexture2D->texture.sized );
} // sized

//---------------------------------------------------------------------------

- (GLint) level
{
    return( mpTexture2D->texture.level );
} // level

//---------------------------------------------------------------------------

- (GLfloat) aspect
{
    return( mpTexture2D->image.aspect );
} //aspect

//---------------------------------------------------------------------------

- (GLvoid *) buffer
{
    return( mpTexture2D->texture.pixels );
} // buffer

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLTexture2DAcquireWithSize(theSize, mpTexture2D) );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) bind
{
	OpenGLTexture2DBind(mpTexture2D);
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
	OpenGLTexture2DUnbind(mpTexture2D);
} // unbind

//---------------------------------------------------------------------------

- (void) write
{
	OpenGLTexture2DWrite(mpTexture2D);
} // write

//---------------------------------------------------------------------------

- (void) write:(const GLvoid *)theBuffer;
{
    OpenGLTexture2DWriteWithBuffer(theBuffer, mpTexture2D);
} // write

//---------------------------------------------------------------------------

- (void) read
{
    OpenGLTexture2DRead(mpTexture2D);
} // read

//---------------------------------------------------------------------------

- (void) read:(GLvoid *)theBuffer
{
    OpenGLTexture2DReadIntoBuffer(theBuffer, mpTexture2D);
} // read

//---------------------------------------------------------------------------

- (void) copy:(const GLvoid *)theBuffer
         doVR:(const BOOL)theFlag
{
    OpenGLTexture2DCopyWithBuffer(theFlag, theBuffer, mpTexture2D);
} // write

//---------------------------------------------------------------------------

- (void) update:(const GLvoid *)theBuffer
         bounds:(const NSRect *)thebounds
{
    OpenGLTexture2DUpdateWithBuffer(thebounds, theBuffer, mpTexture2D);
} // update

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
