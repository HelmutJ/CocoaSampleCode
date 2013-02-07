//---------------------------------------------------------------------------
//
//	File: OpenGLTeapot.h
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
//  Copyright (c) 2009, 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLTeapotProtocol.h"
#import "OpenGLTextured2DTeapot.h"
#import "OpenGLTexturedRectTeapot.h"

#import "OpenGLTeapot.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTeapotData
{
	GLenum  target;
    
    id<OpenGLTeapotProtocol> object;
};

typedef struct OpenGLTeapotData   OpenGLTeapotData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static OpenGLTeapotDataRef OpenGLTeapotCreateWithPropertyList(NSString *pPListPath,
                                                              const NSSize *pSize,
                                                              const GLenum target)
{
	OpenGLTeapotDataRef pTeapot = (OpenGLTeapotDataRef)calloc(1, sizeof(OpenGLTeapotData));
    
    if( pTeapot != NULL )
    {
        BOOL isValid = (target == GL_TEXTURE_2D) || (target == GL_TEXTURE_RECTANGLE_ARB);
        
        pTeapot->target = (isValid) ? target : GL_TEXTURE_2D;
        
        if( pTeapot->target == GL_TEXTURE_2D )
        {
            pTeapot->object = [[OpenGLTextured2DTeapot alloc] initTextured2DTeapotdWithPListAtPath:pPListPath 
                                                                                              size:pSize];
        } // if
        else
        {
            pTeapot->object = [[OpenGLTexturedRectTeapot alloc] initTextured2DTeapotdWithPListAtPath:pPListPath 
                                                                                                size:pSize];
        } // else
    } // if
	
	return( pTeapot );
} // OpenGLTeapotCreateWithPropertyList

//---------------------------------------------------------------------------

static OpenGLTeapotDataRef OpenGLTeapotCreateWithPropertyListInAppBundle(NSString *pPListName,
                                                                         const NSSize *pSize,
                                                                         const GLenum target)
{
	OpenGLTeapotDataRef pTeapot = (OpenGLTeapotDataRef)calloc(1, sizeof(OpenGLTeapotData));
    
    if( pTeapot != NULL )
    {
        BOOL isValid = (target == GL_TEXTURE_2D) || (target == GL_TEXTURE_RECTANGLE_ARB);
        
        pTeapot->target = (isValid) ? target : GL_TEXTURE_2D;
        
        if( pTeapot->target == GL_TEXTURE_2D )
        {
            pTeapot->object = [[OpenGLTextured2DTeapot alloc] initTextured2DWithPListInAppBundle:pPListName 
                                                                                            size:pSize];
        } // if
        else
        {
            pTeapot->object = [[OpenGLTexturedRectTeapot alloc] initTexturedRectWithPListInAppBundle:pPListName 
                                                                                                size:pSize];
        } // else
    } // if
	
	return( pTeapot );
} // OpenGLTeapotCreateWithPropertyListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLTeapotDelete(OpenGLTeapotDataRef pTeapot)
{
	if( pTeapot != NULL )
	{
        if( pTeapot->object )
        {
            [pTeapot->object release];
            
            pTeapot->object = nil;
        } // if
        
		free(pTeapot);
		
		pTeapot = NULL;
	} // if
} // OpenGLTeapotDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLTeapot

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initTeapotdWithPListAtPath:(NSString *)thePListPath
							 size:(const NSSize *)theSize
                           target:(const GLenum)theTarget
{
	self = [super init];
    
	if( self )
	{
		mpTeapot = OpenGLTeapotCreateWithPropertyList(thePListPath,
                                                      theSize, 
                                                      theTarget);
	} // if
	
	return( self );
} // initTeapotdWithPListAtPath

//---------------------------------------------------------------------------

- (id) initTeapotWithPListInAppBundle:(NSString *)thePListName
                                 size:(const NSSize *)theSize
                               target:(const GLenum)theTarget
{
	self = [super init];
    
	if( self )
	{
		mpTeapot = OpenGLTeapotCreateWithPropertyListInAppBundle(thePListName,
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
	OpenGLTeapotDelete(mpTeapot);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpTeapot->target );
} // target

//---------------------------------------------------------------------------

- (NSSize) size
{
    return( [mpTeapot->object size] );
} // size

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
	return( [mpTeapot->object setSize:theSize] );
} // setSize

//---------------------------------------------------------------------------

- (BOOL) setTarget:(const GLenum)theTarget
{
	return( [mpTeapot->object setTarget:theTarget] );
} // setTarget

//---------------------------------------------------------------------------

- (BOOL) setScale:(const GLfloat *)theScale
{
	return( [mpTeapot->object setScale:theScale] );
} // setScale

//---------------------------------------------------------------------------

- (BOOL) setTranslation:(const GLfloat *)theTranslation
{
	return( [mpTeapot->object setTranslation:theTranslation] );
} // setTranslation

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) display
{
	[mpTeapot->object display];
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


