//---------------------------------------------------------------------------
//
//	File: OpenGLQuadsUtilityToolkit.m
//
//  Abstract: Utility toolkit to generating data streams using quads
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
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//------------------------------------------------------------------------

#import "OpenGLQuadsUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLQuadsUtilityToolkit

//------------------------------------------------------------------------

- (id) initWithBounds:(NSRect)theBounds
{
	self = [super init];
	
	bounds.origin.x    = theBounds.origin.x;
	bounds.origin.y    = theBounds.origin.y;
	bounds.size.width  = theBounds.size.width;
	bounds.size.height = theBounds.size.height;
	
	return self;
} // init

//------------------------------------------------------------------------

- (void) dealloc
{
	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------
//
// This method demonstrates that a viewport-sized quad is equivalent in
// having a data stream generator. That is to say, in order to utilize 
// a fragment shader in an OpenGL pipeline, it is essential that one 
// should generate pixels. As a result, upon drawing a quad the size of 
// our viewport, one is generating a fragment for every pixel of our 
// destination texture. It should be noted that this is not part of 
// the computational process, as this is only the visualization of the 
// results.
//
//------------------------------------------------------------------------

- (void) quads
{
	glBegin( GL_QUADS );
	
		glTexCoord2f( 0.0f, 0.0f ); 
		glVertex2f( bounds.origin.x, bounds.origin.y );
		
		glTexCoord2f( bounds.size.width, 0.0f ); 
		glVertex2f( bounds.size.width, bounds.origin.y );
		
		glTexCoord2f( bounds.size.width, bounds.size.height ); 
		glVertex2f( bounds.size.width,  bounds.size.height );
		
		glTexCoord2f( 0.0f, bounds.size.height ); 
		glVertex2f( bounds.origin.x, bounds.size.height );

	glEnd();
} // quads

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

