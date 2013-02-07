//---------------------------------------------------------------------------
//
//	File: OpenGLFramebuffer2DStatus.m
//
//  Abstract: Class that implements a utility toolkit for fbo status
//            check.
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
//  Copyright (c) 2008-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLFramebuffer2DMessages.h"
#import "OpenGLFramebuffer2DStatus.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLFramebuffer2DStatusData
{
    NSMutableString *message;
    GLenum           status;
    BOOL             doExit;
};

typedef struct OpenGLFramebuffer2DStatusData  OpenGLFramebuffer2DStatusData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DStatusSetMessage(OpenGLFramebuffer2DStatusDataRef pStatus)
{
	pStatus->message = [NSMutableString new];
    
    if( pStatus->message )
    {
        switch( pStatus->status )
        {
            case GL_FRAMEBUFFER_UNSUPPORTED:
                
                [pStatus->message setString:kOpenGLFramebufferUnsupported];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
                
                [pStatus->message setString:kOpenGLFramebufferIncompleteAttachement];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
                
                [pStatus->message setString:kOpenGLFramebufferIncompleteMissingAttachement];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT:
                
                [pStatus->message setString:KOpenGLFramebufferIncompleteDimensions];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT:
                
                [pStatus->message setString:kOpenGLFramebufferIncompleteFormats];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
                
                [pStatus->message setString:kOpenGLFramebufferIncompleteDrawBuffer];
                break;
                
            case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
                
                [pStatus->message setString:kOpenGLFramebufferIncompleteReadBuffer];
                break;
                
            default:
                
                [pStatus->message setString:kOpenGLFramebufferDefaultAlertPanelMessage];
                break;
        } // switch
    } // if
} // OpenGLFramebuffer2DStatusSetMessage

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DStatusInitParams(const GLenum target,
                                                const BOOL exitFlag,
                                                OpenGLFramebuffer2DStatusDataRef pStatus)
{
    pStatus->status  = glCheckFramebufferStatus( target );
    pStatus->doExit  = exitFlag;
    pStatus->message = nil;
} // OpenGLFramebuffer2DStatusInitParams

//---------------------------------------------------------------------------

static OpenGLFramebuffer2DStatusDataRef OpenGLFramebuffer2DStatusCreate(const GLenum target,
                                                                        const BOOL exitFlag)
{
    OpenGLFramebuffer2DStatusDataRef pStatus = (OpenGLFramebuffer2DStatusDataRef)calloc(1, sizeof(OpenGLFramebuffer2DStatusData));
    
    if( pStatus != NULL )
    {
        OpenGLFramebuffer2DStatusInitParams(target, 
                                            exitFlag, 
                                            pStatus);
        
        OpenGLFramebuffer2DStatusSetMessage(pStatus);
    } // if
    
    return( pStatus );
} // OpenGLFramebuffer2DStatusCreate

//---------------------------------------------------------------------------

static void OpenGLFramebuffer2DStatusDelete(OpenGLFramebuffer2DStatusDataRef pStatus)
{
    if( pStatus != NULL )
    {
        if( pStatus->message )
        {
            [pStatus->message release];
            
            pStatus->message = nil;
        } // if
        
        free(pStatus);
        
        pStatus = NULL;
    } // if
} // OpenGLFramebuffer2DStatusDelete

//---------------------------------------------------------------------------

static BOOL OpenGLFramebuffer2DStatusIsComplete(OpenGLFramebuffer2DStatusDataRef pStatus)
{
	BOOL success = pStatus->status == GL_FRAMEBUFFER_COMPLETE;
	
	if( !success )
	{
		NSRunAlertPanel(@"OpenGL FBO Status",
						pStatus->message, 
						@"OK", 
						nil, 
						nil);
		
		if( pStatus->doExit )
		{
			exit( -1 );
		} // if
	} // else
	
	return( success );
} // OpenGLFramebuffer2DStatusIsComplete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLFramebuffer2DStatus

//---------------------------------------------------------------------------

- (id) initStatusWithTarget:(const GLenum)theFBOTarget 
                       exit:(const BOOL)theExitFlag
{	
	
    self = [super init];
    
    if( self )
    {
        mpStatus = OpenGLFramebuffer2DStatusCreate( theFBOTarget, theExitFlag );
    } // if
	
	return( self );
} // initStatusWithTarget

//------------------------------------------------------------------------

+ (id) statusWithTarget:(const GLenum)theFBOTarget 
                   exit:(const BOOL)theExitFlag
{
	return( [[[OpenGLFramebuffer2DStatus allocWithZone:[self zone]] initStatusWithTarget:theFBOTarget
                                                                                    exit:theExitFlag] autorelease] );
} // statusWithTarget

//------------------------------------------------------------------------

- (void) dealloc
{
	OpenGLFramebuffer2DStatusDelete(mpStatus);
    
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (BOOL) isComplete
{
	return( OpenGLFramebuffer2DStatusIsComplete(mpStatus) );
} // isComplete

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


