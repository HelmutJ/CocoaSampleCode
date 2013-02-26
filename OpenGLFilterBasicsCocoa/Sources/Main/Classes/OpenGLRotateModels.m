//---------------------------------------------------------------------------
//
//	File: OpenGLRotateModels.m
//
//  Abstract: Utility toolKit for rotatting models
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

#import "OpenGLModelTypes.h"
#import "OpenGLRotateModels.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLRotateModels

//------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	// Instantiate a Stanford Bunny model as a display list
	
	modelIsBunny = [[OpenGLBunnyModel alloc] initWithModelType:modelTypeSolid modelRange:1];

	// Instantiate a torus (a surface having genus one) as a display list
	
	modelIsTorus = [[OpenGLTorusModel alloc] initWithModelType:modelTypeSolid
													modelRange:1
													innerRadii:0.05
													outerRadii:0.9 
													sidesCount:64 
													ringsCount:64];

	return  self;
} // init

//------------------------------------------------------------------------

- (void) dealloc
{
	// Delete the models
	
	[modelIsBunny dealloc];
	[modelIsTorus dealloc];

	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Rotating the models --

//------------------------------------------------------------------------

- (void) rotateSolidBunny
{
	glPushMatrix( );
	
		glRotatef( -angle, 0.0f, 1.0f, 0.25f );
		
		[modelIsBunny callList];
		
	glPopMatrix( );
} // rotateSolidBunny

//------------------------------------------------------------------------

- (void) rotateSolidTorus:(GLfloat)theAngle
{
	glPushMatrix( );
	
		glRotatef( theAngle, 0.0f, 1.0f, 0.5f );
		
		[modelIsTorus callList];
		
	glPopMatrix( );
} // rotateSolidTorus

//------------------------------------------------------------------------

- (void) rotateSolidTori
{
	[self rotateSolidTorus:(  2.25f * angle )];
	[self rotateSolidTorus:( -1.5f  * angle )];
	[self rotateSolidTorus:(  1.75f * angle )];
} // rotateSolidTori

//------------------------------------------------------------------------

- (void) rotateModels
{
	[self rotateSolidBunny];
	[self rotateSolidTori];
} // RotateModels

//------------------------------------------------------------------------
//
// We'll animate our models here.
//
//------------------------------------------------------------------------

- (void) rotate
{
	angle += 0.5f;

	[self rotateModels];
} // rotate

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

