//---------------------------------------------------------------------------
//
//	File: OpenGLTexturedRectTeapot.m
//
//  Abstract: Class that implements a method for displaying a texture 2D  
//            bound to an IBO based teapot with enabled sphere map texture 
//            coordinate generation.
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

#import "OpenGLTexturedRectTeapot.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLTexturedRectTeapot

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initTexturedRectTeapotdWithPListAtPath:(NSString *)thePListPath
                                         size:(const NSSize *)theSize
{
	self = [super initTeapotBaseWithPListAtPath:thePListPath
                                           size:theSize
                                         target:GL_TEXTURE_RECTANGLE_ARB];
    
	if( !self )
	{
        NSLog(@">> ERROR: OpenGL Textured Rect Teapot - Failed instantiating the base class!");
	} // if
	
	return( self );
} // initTexturedRectTeapotdWithPListAtPath

//---------------------------------------------------------------------------

- (id) initTexturedRectWithPListInAppBundle:(NSString *)thePListName
                                       size:(const NSSize *)theSize
{
	self = [super initTeapotWithPListInAppBundle:thePListName
                                            size:theSize
                                          target:GL_TEXTURE_RECTANGLE_ARB];
    
	if( !self )
	{
        NSLog(@">> ERROR: OpenGL Textured Rect Teapot - Failed instantiating the base class!");
	} // if
	
	return( self );
} // initTexturedRectWithPListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructors

//---------------------------------------------------------------------------

- (void) dealloc
{
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) display
{
    // Enable sphere map automatic texture coordinate generation.
    
	glEnable(GL_TEXTURE_GEN_S);
	glEnable(GL_TEXTURE_GEN_T);
    
    // Since we will be using GL_TEXTURE_RECTANGLE_ARB textures which 
    // uses pixel coordinates rather than normalized coordinates, we 
    // need to scale the texturing matrix
    
    glMatrixMode(GL_TEXTURE);
    
    // To rotate without skewing or translation, we must be in 0-centered 
    // normalized texture coordinates 
    
    [self normalize];
    
    // Set to model-view
    
    glMatrixMode(GL_MODELVIEW);
    
	// Translate the teapot to the new coordinates
	
	[self translate];
	
	// Scale the teapot object
	
	[self scale];
	
	// Draw the IBO teapot
	
	[super display];
    
	// Disable states & modes 
	
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    
    // Reset the model-view matrix
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // Disable sphere map automatic texture coordinate generation.
    
	glDisable(GL_TEXTURE_GEN_T);
	glDisable(GL_TEXTURE_GEN_S);
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


