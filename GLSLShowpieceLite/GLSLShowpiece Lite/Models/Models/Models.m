//-------------------------------------------------------------------------
//
//	File: Models.m
//
//  Abstract: Utilities for drawing of various models.
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
//  Copyright (c) 2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

#import "Models.h"

#import <OpenGL/glu.h>
#import <GLUT/glut.h>

#import "Bunny.h"
#import "Teapot.h"

static const GLdouble kSphereRadius     = 0.5;
static const GLint    kSphereSlices     = 30;
static const GLint    kSphereStacks     = 30;
static const GLint    kTeapotGrid       = 8;
static const GLdouble kTeapotScale      = 0.5f;
static const GLdouble kTeapotSmallScale = 0.25;
static const GLenum   kTeapotType       = GL_FILL;

static void DrawSphere( GLUquadric *quadric )
{
	if ( quadric != NULL )
	{
		gluSphere( quadric, kSphereRadius, kSphereSlices, kSphereStacks );
	} // if
	else
	{
		glutSolidSphere( kSphereRadius, kSphereSlices, kSphereStacks );
	} // else
} // DrawSphere

@implementation Models

- (id) init
{
	[super init];
	
	// Create a GLU quadric, used for rendering certain geometry

	quadric = gluNewQuadric();
	
	gluQuadricDrawStyle(quadric, GLU_FILL);
	gluQuadricNormals(quadric, GL_SMOOTH);
	gluQuadricTexture(quadric, GL_TRUE);

	return self;
} // init

- (void) dealloc
{
	// Free the GLU quadric
	
	if ( quadric != NULL )
	{
		gluDeleteQuadric( quadric );
		
		quadric = NULL;
	} // if
	
	[super dealloc];
} // dealloc

- (void) drawModel:(GLuint)modelType
{
	switch ( modelType )
	{
		case kModelSolidSphere:
			DrawSphere( quadric );
			break;
		case kModelSolidTeapot:
			DrawTeapot( kTeapotGrid, kTeapotScale, kTeapotType);
			break;
		case kModelSolidSmallTeapot:
			DrawTeapot( kTeapotGrid, kTeapotSmallScale, kTeapotType);
			break;
		case kModelSolidStanfordBunny:
			DrawStanfordBunnySolidList( );
			break;
		default:
			DrawSphere( quadric );
			break;
	}; // switch
} // drawModel

@end
