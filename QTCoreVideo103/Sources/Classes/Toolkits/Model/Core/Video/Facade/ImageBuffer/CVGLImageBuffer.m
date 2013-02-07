//---------------------------------------------------------------------------
//
//	File: CVGLImagebuffer.h
//
//  Abstract: A facade for managing Core Video image buffer references
//            with OpenGL PBO, FBO, texture range, or texture 2D backing 
//            stores.
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

#import "CVGLProtocol.h"

#import "CVGLFramebuffer.h"
#import "CVGLPixelbuffer.h"
#import "CVGLTexture2D.h"

#import "CVGLImagebuffer.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct CVGLImagebufferData
{
    GLuint width;
    GLuint height;
    GLenum target;
    GLenum format;
    
	id<CVGLProtocol>  buffer;
};

typedef struct CVGLImagebufferData  CVGLImagebufferData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation CVGLImagebuffer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initImagebufferWithSize:(const NSSize *)theSize
{
	self = [super init];
    
	if( self )
	{
        mpImagebuffer = (CVGLImagebufferDataRef)calloc(1, sizeof(CVGLImagebufferData));
        
        if( mpImagebuffer != NULL )
        {
            mpImagebuffer->buffer = [[CVGLFramebuffer alloc] initFramebufferWithSize:theSize];
            
            if( !mpImagebuffer->buffer )
            {
                NSLog( @">> ERROR: CoreVideo Imagebuffer - Failed instantiating a FBO bound backing store!" );
            } // if
            else
            {
                mpImagebuffer->target = [mpImagebuffer->buffer target];
                mpImagebuffer->format = [mpImagebuffer->buffer format];
                mpImagebuffer->width  = [mpImagebuffer->buffer width];
                mpImagebuffer->height = [mpImagebuffer->buffer height];
            } // else
        } // if
	} // if
	
	return  self;
} // initImagebufferWithSize

//---------------------------------------------------------------------------

- (id) initImagebufferWithSize:(const NSSize *)theSize
                        target:(const GLenum)theTarget
                        format:(const GLenum)theFormat
{
    
    self = [super init];
    
	if( self )
	{
        mpImagebuffer = (CVGLImagebufferDataRef)calloc(1, sizeof(CVGLImagebufferData));
        
        if( mpImagebuffer != NULL )
        {
            mpImagebuffer->target = theTarget;
            mpImagebuffer->format = theFormat;

            mpImagebuffer->buffer = [[CVGLTexture2D alloc] initTexture2DWithSize:theSize
                                                                          target:theTarget
                                                                          format:theFormat];
            
            if( !mpImagebuffer->buffer )
            {
                NSLog( @">> ERROR: CoreVideo Imagebuffer - Failed instantiating a texture 2D/rectangle backing store!" );
            } // if
            else
            {
                mpImagebuffer->width  = [mpImagebuffer->buffer width];
                mpImagebuffer->height = [mpImagebuffer->buffer height];
           } // else
        } // if
	} // if
	
	return  self;
} // initImagebufferWithSize

//---------------------------------------------------------------------------

- (id) initImagebufferWithSize:(const NSSize *)theSize
                        target:(const GLenum)theTarget
                        format:(const GLenum)theFormat
                          hint:(const GLenum)theHint
{
    self = [super init];
    
	if( self )
	{
        mpImagebuffer = (CVGLImagebufferDataRef)calloc(1, sizeof(CVGLImagebufferData));
        
        if( mpImagebuffer != NULL )
        {
            mpImagebuffer->target = theTarget;
            mpImagebuffer->format = theFormat;

            mpImagebuffer->buffer = [[CVGLTexture2D alloc] initTexture2DWithSize:theSize
                                                                          target:theTarget
                                                                          format:theFormat
                                                                            hint:theHint];
            
            if( !mpImagebuffer->buffer )
            {
                NSLog( @">> ERROR: CoreVideo Imagebuffer - Failed instantiating a texture 2D backing store with hint!" );
            } // if
            else
            {
                mpImagebuffer->width  = [mpImagebuffer->buffer width];
                mpImagebuffer->height = [mpImagebuffer->buffer height];
            } // else
        } // if
	} // if
	
	return  self;
} // initTexture2DWithSize

//---------------------------------------------------------------------------

- (id) initImagebufferWithSize:(const NSSize *)theSize
                        target:(const GLenum)theTarget
                        format:(const GLenum)theFormat
                          hint:(const GLenum)theHint
                       mipmaps:(const BOOL)hasMipmaps
{
    self = [super init];
    
	if( self )
	{
        mpImagebuffer = (CVGLImagebufferDataRef)calloc(1, sizeof(CVGLImagebufferData));
        
        if( mpImagebuffer != NULL )
        {
            mpImagebuffer->target = theTarget;
            mpImagebuffer->format = theFormat;
            
            mpImagebuffer->buffer = [[CVGLTexture2D alloc] initTexture2DWithSize:theSize
                                                                          target:theTarget
                                                                          format:theFormat
                                                                            hint:theHint
                                                                         mipmaps:hasMipmaps];
            
            if( !mpImagebuffer->buffer )
            {
                NSLog( @">> ERROR: CoreVideo Imagebuffer - Failed instantiating a texture 2D backing store with hint and mipmaps!" );
            } // if
            else
            {
                mpImagebuffer->width  = [mpImagebuffer->buffer width];
                mpImagebuffer->height = [mpImagebuffer->buffer height];
            } // else
        } // if
	} // if
	
	return  self;
} // initTexture2DWithSize

//---------------------------------------------------------------------------

- (id) initImagebufferWithSize:(const NSSize *)theSize
                         usage:(const GLenum)theUsage
                        target:(const GLenum)theTarget
                        format:(const GLenum)theFormat
{
    self = [super init];
    
    if( self )
    {
        mpImagebuffer = (CVGLImagebufferDataRef)calloc(1, sizeof(CVGLImagebufferData));
        
        if( mpImagebuffer != NULL )
        {
            mpImagebuffer->target = theTarget;
            mpImagebuffer->format = theFormat;

            mpImagebuffer->buffer = [[CVGLPixelbuffer alloc] initTexture2DAuthorWithSize:theSize
                                                                                   usage:theUsage
                                                                                  target:theTarget
                                                                                  format:theFormat];
            
            if( !mpImagebuffer->buffer )
            {
                NSLog( @">> ERROR: CoreVideo Imagebuffer - Failure instantiating a PBO bound backing store!" );
            } // if
            else
            {
                mpImagebuffer->width  = [mpImagebuffer->buffer width];
                mpImagebuffer->height = [mpImagebuffer->buffer height];
            } // else
        } //if
    } // if
	
	return  self;
} // initImagebufferWithSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
    if( mpImagebuffer != NULL )
    {
        if( mpImagebuffer->buffer )
        {
            [mpImagebuffer->buffer release];
            
            mpImagebuffer->buffer = nil;
        } // if
        
        free(mpImagebuffer);
        
        mpImagebuffer = NULL;
    } // if
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLenum) target
{
    return( mpImagebuffer->target );
} // target

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( mpImagebuffer->format );
} // format

//---------------------------------------------------------------------------

- (GLuint) width
{
    return( mpImagebuffer->width );
} // width

//---------------------------------------------------------------------------

- (GLuint) height
{
    return( mpImagebuffer->height );
} // height

//---------------------------------------------------------------------------

- (BOOL) setSize:(const NSSize *)theSize
{
    return( [mpImagebuffer->buffer setSize:theSize] );
} // setSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) bind
{
    [mpImagebuffer->buffer bind];
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
    [mpImagebuffer->buffer unbind];
} // unbind

//---------------------------------------------------------------------------

- (void) update:(CVImageBufferRef)theImageBuffer;
{
    [mpImagebuffer->buffer update:theImageBuffer];
} // update

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
