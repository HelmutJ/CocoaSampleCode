//---------------------------------------------------------------------------
//
//	File: OpenGLTeapotBase.h
//
//  Abstract: Class that implements a method for generating an IBO teapot
//            with enabled sphere map texture coordinate generation.
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
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLIBORenderer.h"
#import "OpenGLTeapotBase.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTeapotBaseData
{
	NSSize   size;
	GLfloat  scale[3];
	GLfloat  translate[3];
    GLenum   target;
    
    OpenGLIBORenderer *renderer;
};

typedef struct OpenGLTeapotBaseData   OpenGLTeapotBaseData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessors

//---------------------------------------------------------------------------

static BOOL OpenGLTeapotBaseSetTextureSize(const NSSize *pSize,
                                           OpenGLTeapotBaseDataRef pTeapot)
{
    BOOL success = pSize != NULL;
    
    if( success )
    {
        if( ( pSize->width <= 0.0f ) || ( pSize->height <= 0.0f ) )
        {
            pTeapot->size.width  = 1920.0f;	// Default texture width for a HD movie
            pTeapot->size.height = 1080.0f;	// Default texture height for a HD movie
        } // if
        else
        {
            pTeapot->size.width  = pSize->width;
            pTeapot->size.height = pSize->height;
        } // else
    } // if
    
    return( success );
} // OpenGLTeapotBaseSetTextureSize

//---------------------------------------------------------------------------

static inline BOOL OpenGLTeapotBaseSetTextureTarget(const GLenum target,
                                                    OpenGLTeapotBaseDataRef pTeapot)
{
    BOOL isValid = (target == GL_TEXTURE_RECTANGLE_ARB) || (target == GL_TEXTURE_2D);
    
	pTeapot->target = isValid ? target : GL_TEXTURE_2D;
    
    return( isValid );
} // OpenGLTeapotBaseSetTextureTarget

//---------------------------------------------------------------------------

static inline void OpenGLTeapotBaseSetDefaultScale(OpenGLTeapotBaseDataRef pTeapot)
{
	pTeapot->scale[0] = 0.5f;
	pTeapot->scale[1] = 0.5f;
	pTeapot->scale[2] = 0.5f;
} // OpenGLTeapotBaseSetDefaultScale

//---------------------------------------------------------------------------

static inline void OpenGLTeapotBaseSetDefaultTranslation(OpenGLTeapotBaseDataRef pTeapot)
{
	pTeapot->translate[0] =  0.0f;
	pTeapot->translate[1] = -0.75f;
	pTeapot->translate[2] =  0.0f;
} // OpenGLTeapotBaseSetDefaultTranslation

//------------------------------------------------------------------------

static BOOL OpenGLTeapotBaseSetScale(const GLfloat *pScale,
                                     OpenGLTeapotBaseDataRef pTeapot)
{
    BOOL success = pScale != NULL;
    
    if( success )
    {
        pTeapot->scale[0] = pScale[0];
        pTeapot->scale[1] = pScale[1];
        pTeapot->scale[2] = pScale[2];
    } // if
    
    return( success );
} // OpenGLTeapotBaseSetScale

//------------------------------------------------------------------------

static BOOL OpenGLTeapotBaseSetTranslation(const GLfloat *pTranslation,
                                           OpenGLTeapotBaseDataRef pTeapot)
{
    BOOL success = pTranslation != NULL;
    
    if( success )
    {
        pTeapot->translate[0] = pTranslation[0];
        pTeapot->translate[1] = pTranslation[1];
        pTeapot->translate[2] = pTranslation[2];
    } // if
    
    return( success );
} // OpenGLTeapotBaseSetTranslation

//------------------------------------------------------------------------
//
// Turn on sphere map automatic texture coordinate generation.
//
//------------------------------------------------------------------------

static inline void OpenGLTeapotBaseGenSphereMap(OpenGLTeapotBaseDataRef pTeapot)
{
    glTexGeni( GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
    glTexGeni( GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
} // OpenGLTeapotBaseGenSphereMap

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static OpenGLTeapotBaseDataRef OpenGLTeapotBaseCreate(const NSSize *pSize,
                                                      const GLenum target)
{
	OpenGLTeapotBaseDataRef pTeapot 
    = (OpenGLTeapotBaseDataRef)calloc(1, sizeof(OpenGLTeapotBaseData));
	
	if( pTeapot != NULL )
	{
        OpenGLTeapotBaseSetTextureTarget(target, pTeapot);
		OpenGLTeapotBaseSetTextureSize(pSize, pTeapot);
        
        OpenGLTeapotBaseSetDefaultScale(pTeapot);
        OpenGLTeapotBaseSetDefaultTranslation(pTeapot);
        
		OpenGLTeapotBaseGenSphereMap(pTeapot);
    } // if
    
    return(pTeapot);
} // OpenGLTeapotBaseCreate

//---------------------------------------------------------------------------

static OpenGLTeapotBaseDataRef OpenGLTeapotBaseCreateWithPropertyList(NSString *pPListPath,
                                                                      const NSSize *pSize,
                                                                      const GLenum target)
{
    OpenGLTeapotBaseDataRef pTeapot = OpenGLTeapotBaseCreate(pSize, target);
    
    if( pTeapot != NULL )
    {
        pTeapot->renderer = [[OpenGLIBORenderer alloc] initIBORendererWithPListAtPath:pPListPath
                                                                                 type:GL_FLOAT];
    } // if
	
	return( pTeapot );
} // OpenGLTeapotBaseCreateWithPropertyList

//---------------------------------------------------------------------------

static OpenGLTeapotBaseDataRef OpenGLTeapotBaseCreateWithPropertyListInAppBundle(NSString *pPListName,
                                                                                 const NSSize *pSize,
                                                                                 const GLenum target)
{
    OpenGLTeapotBaseDataRef pTeapot = OpenGLTeapotBaseCreate(pSize, target);
    
    if( pTeapot != NULL )
    {
        pTeapot->renderer = [[OpenGLIBORenderer alloc] initIBORenderertWithPListInAppBundle:pPListName
                                                                                       type:GL_FLOAT];
    } // if
	
	return( pTeapot );
} // OpenGLTeapotBaseCreateWithPropertyListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLTeapotBaseDelete(OpenGLTeapotBaseDataRef pTeapot)
{
	if( pTeapot != NULL )
	{
        if( pTeapot->renderer )
        {
            [pTeapot->renderer release];
            
            pTeapot->renderer = nil;
        } // if
        
		free(pTeapot);
		
		pTeapot = NULL;
	} // if
} // OpenGLTeapotBaseDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLTeapotBase

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initTeapotBaseWithPListAtPath:(NSString *)thePListPath
                                size:(const NSSize *)theSize
                              target:(const GLenum)theTarget
{
	self = [super init];
    
	if( self )
	{
		mpTeapot = OpenGLTeapotBaseCreateWithPropertyList(thePListPath,
                                                          theSize, 
                                                          theTarget);
	} // if
	
	return( self );
} // initTeapotBaseWithPListAtPath

//---------------------------------------------------------------------------

- (id) initTeapotWithPListInAppBundle:(NSString *)thePListName
                                 size:(const NSSize *)theSize
                               target:(const GLenum)theTarget
{
	self = [super init];
    
	if( self )
	{
		mpTeapot = OpenGLTeapotBaseCreateWithPropertyListInAppBundle(thePListName,
                                                                     theSize, 
                                                                     theTarget);
	} // if
	
	return( self );
} // initTeapotWithPListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructors

//---------------------------------------------------------------------------

- (void) dealloc
{
	OpenGLTeapotBaseDelete(mpTeapot);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (NSSize) size
{
	return( mpTeapot->size );
} // size

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
	return( OpenGLTeapotBaseSetTextureSize(theSize, mpTeapot) );
} // setSize

//---------------------------------------------------------------------------

- (BOOL) setTarget:(const GLenum)theTarget
{
	return( OpenGLTeapotBaseSetTextureTarget(theTarget, mpTeapot) );
} // setTarget

//---------------------------------------------------------------------------

- (BOOL) setScale:(const GLfloat *)theScale
{
	return( OpenGLTeapotBaseSetScale(theScale, mpTeapot) );
} // setScale

//---------------------------------------------------------------------------

- (BOOL) setTranslation:(const GLfloat *)theTranslation
{
	return( OpenGLTeapotBaseSetTranslation(theTranslation, mpTeapot) );
} // setTranslation

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// To rotate without skewing or translation, we must be in 0-centered 
// normalized texture coordinates.
//
//---------------------------------------------------------------------------

- (void) normalize
{    
    glScalef(mpTeapot->size.width, 
             mpTeapot->size.height, 
             1.0f);
} // normalize

//---------------------------------------------------------------------------
//
// Scale the teapot object.
//
//---------------------------------------------------------------------------

- (void) scale
{
	glScalef(mpTeapot->scale[0], 
			 mpTeapot->scale[1], 
			 mpTeapot->scale[2]);
} // scale

//---------------------------------------------------------------------------
//
// Translate the teapot to the new coordinates.
//
//---------------------------------------------------------------------------

- (void) translate
{
	glTranslatef(mpTeapot->translate[0], 
                 mpTeapot->translate[1], 
                 mpTeapot->translate[2]);
} // translate

//---------------------------------------------------------------------------

- (void) display
{
	[mpTeapot->renderer render];
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


