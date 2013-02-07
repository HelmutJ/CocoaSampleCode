//---------------------------------------------------------------------------
//
//	File: OpenGLQuad.m
//
//  Abstract: A facade for for handling a texture 2D or texture rectangle 
//            bound to a VBO quad.
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

#import "OpenGLQuadProtocol.h"
#import "OpenGLQuadTex2D.h"
#import "OpenGLQuadTexRect.h"

#import "OpenGLQuad.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLQuadData
{
	NSSize  size;
    GLenum  target;
    
    id<OpenGLQuadProtocol> quad;
};

typedef struct OpenGLQuadData  OpenGLQuadData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static OpenGLQuadDataRef OpenGLQuadCreate(const NSSize *pSize,
                                          const GLenum target)
{
    OpenGLQuadDataRef pQuad = (OpenGLQuadDataRef)calloc(1, sizeof(OpenGLQuadData));
    
    if( pQuad != NULL )
    {
        if( target == GL_TEXTURE_RECTANGLE_ARB )
        {
            pQuad->target = GL_TEXTURE_RECTANGLE_ARB;
            pQuad->quad   = [[OpenGLQuadTexRect alloc] initQuadTexRectWithSize:pSize];
        } // if
        else
        {
            if( target != GL_TEXTURE_2D )
            {
                NSLog( @">> WARNING: OpenGL Quad - Invliad texture target!" );
                NSLog( @">> WARNING: OpenGL Quad - Using a texture 2D target instead!" );
            } // if
            
            pQuad->target = GL_TEXTURE_2D;
            pQuad->quad   = [[OpenGLQuadTex2D alloc] initQuadTex2DWithSize:pSize];
        } // else
        
        pQuad->size.width  = [pQuad->quad width];
        pQuad->size.height = [pQuad->quad height];
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL Quad - Failure Allocating Memory For Data!" );
    }  // else
	
	return( pQuad );
} // OpenGLQuadCreate

//---------------------------------------------------------------------------

static void OpenGLQuadDelete(OpenGLQuadDataRef pQuad)
{
	if( pQuad != NULL )
	{
        if( pQuad->quad )
        {
            [pQuad->quad release];
            
            pQuad->quad = nil;
        } // if
        
		free( pQuad );
		
		pQuad = NULL;
	} // if
} // OpenGLQuadDelete

//---------------------------------------------------------------------------

static BOOL OpenGLQuadSetSize(const NSSize *pSize,
                              OpenGLQuadDataRef pQuad)
{
    BOOL success = [pQuad->quad setSize:pSize];
    
    if( success )
    {
        pQuad->size.width  = pSize->width;
        pQuad->size.height = pSize->height;
    } // if
    
    return( success );
} // OpenGLQuadSetSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLQuad

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
		mpQuad = OpenGLQuadCreate(NULL, GL_TEXTURE_2D);
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (id) initQuadWithSize:(const NSSize *)theSize
{
	self = [super init];
	
	if( self )
	{
		mpQuad = OpenGLQuadCreate(theSize, GL_TEXTURE_2D);
	} // if
	
	return( self );
} // initQuadWithSize

//---------------------------------------------------------------------------

- (id) initQuadWithSize:(const NSSize *)theSize
                 target:(const GLenum)theTarget
{
	self = [super init];
	
	if( self )
	{
		mpQuad = OpenGLQuadCreate(theSize, theTarget);
	} // if
	
	return( self );
} // initQuadWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	OpenGLQuadDelete(mpQuad);
    
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (BOOL) setTexCoords:(const GLfloat *)theTexCoords
{
    return( [mpQuad->quad setTexCoords:theTexCoords] );
} // setTexCoords

//---------------------------------------------------------------------------

- (BOOL) setVertices:(const GLfloat *)setVertices
{
    return( [mpQuad->quad setVertices:setVertices] );
} // setVertices

//---------------------------------------------------------------------------

- (BOOL) setTarget:(const GLenum)theTarget
{
    return( [mpQuad->quad setTarget:theTarget] );
} // setTarget

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( OpenGLQuadSetSize(theSize, mpQuad) );
} // setSize

//---------------------------------------------------------------------------

- (NSSize) size
{
    return( mpQuad->size );
} // size

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpQuad->target );
} // target

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (BOOL) acquire
{
    return( [mpQuad->quad acquire] );
} // acquire

//---------------------------------------------------------------------------

- (BOOL) update
{
    return( [mpQuad->quad update] );
} // update

//---------------------------------------------------------------------------
//
// Draw a quad using texture & vertex coordinates
//
//---------------------------------------------------------------------------

- (void) display
{
    [mpQuad->quad display];
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
