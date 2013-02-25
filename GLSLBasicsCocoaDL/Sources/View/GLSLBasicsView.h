//-------------------------------------------------------------------------
//
//	File: GLSLBasicsView.h
//
//  Abstract: Main rendering class
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
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
//  Copyright (c) 2007-2008 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
//
// Required Includes
//
//-------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#import "GLUTString.h"
#import "Shader.h"
#import "TranguloidTrefoilGeometry.h"

//-------------------------------------------------------------------------
//
// Custom OpenGL View
//
//-------------------------------------------------------------------------

@interface GLSLBasicsView : NSOpenGLView
{
	@private
		BOOL                leftMouseIsDown;			// was the left mouse button pressed?
		BOOL                rightMouseIsDown;			// was the right mouse button pressed?
		GLhandleARB		    programObject;				// the program object
		GLuint              tranguloidTrefoilDL;		// display list ID for the geometry
		GLuint	            paletteID;					// texture color palette
		GLuint              patternID;					// texture color patterns
		GLint               locations[4];				// uniforms for the fragment & vertex shaders 
		GLfloat			    zoom;						// zoom used for animation
		GLfloat			    angle;						// angle used for animation
		GLfloat             pitch;						// pitch used for animation
		GLfloat             offset;						// delta change for animation
		NSPoint             lastMousePoint;				// last mouse point 
		NSRect              bounds;						// current view bounds
		NSTimeInterval      lastFrameReferenceTime;		// used to compute change in time
		NSTimer            *timer;						// timer to update the view content
		NSString           *infoString;					// view bounds as string
		GLUTString         *info;						// for displaying a string using GLUT bitmap fonts
		TranguloidTrefoil  *tranguloidTrefoil;			// tranguloid trefoil geometry
		Shader             *plasma;						// plasma fragemnt and vertex shaders
} // OpenGLView

@end

//-------------------------------------------------------------------------

