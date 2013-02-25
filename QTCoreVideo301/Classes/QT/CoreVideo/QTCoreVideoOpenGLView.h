//---------------------------------------------------------------------------
//
//	File: QTCoreVideoOpenGLView.m
//
//  Abstract: Main rendering class
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

//---------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>

#import <OpenGL/OpenGL.h>

#import "MemObject.h"

#import "QTVisualContextKit.h"

#import "GLSLTypes.h"
#import "GLSLUnitsController.h"
#import "OpenGLViewKit.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

enum AppControlTypes
{
	kControlTopSlider = 0,
	kControlTopTextField,
	kControlTopStaticTextField,
	kControlColorWell,
	kControlBottomSlider,
	kControlBottomTextField,
	kControlBottomStaticTextField,
	kControlPushButton,
	kControlPopUpMenu
};

typedef enum AppControlTypes AppControlTypes;

//---------------------------------------------------------------------------

enum AnimationSequenceTypes
{
	kAnimationDefaultSequence = 0,
	kAnimationFirstSequence,
	kAnimationSecondSequence,
	kAnimationThirdSequence,
	kAnimationWakeUpSequence
};

typedef enum AnimationSequenceTypes AnimationSequenceTypes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

typedef struct QTCVOpenGLAttributes *QTCVOpenGLAttributesRef;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@interface QTCoreVideoOpenGLView : OpenGLViewKit
{
	@private
		QTCVOpenGLAttributesRef   attributes;
		QTVisualContextKit       *visualContext;
		MemObject                *viewMemObj;
		GLSLUnitsController      *shaderUnits;
		QTMovie                  *movie;
		NSRecursiveLock          *lock;
		NSColorPanel             *colorPanel; 
} // QTCoreVideoOpenGLView

// Render clean up routine

- (void) cleanUp;

// Display Link handler

- (CVReturn) getFrameForTime:(const CVTimeStamp *)timeStamp flagsOut:(CVOptionFlags *)flagsOut;

// QuickTime Movie

- (void) openMovie:(NSString*)path;

// Accessors

- (CVDisplayLinkRef) displayLink;

- (void) setShaderItem:(const GLSLTypes)theShader;

- (void) setUniformUsingTopSliderOrTopTextField:(const float)theUniformValue;
- (void) setUniformUsingBottomSliderOrBottomTextField:(const float)theUniformValue;
- (void) setUniformUsingPushButtonState:(const BOOL)theFlag;
- (void) setUniformUsingColorPanelAccessoryControls:(const float)theUniformValue;
- (void) setUniformUsingColorWell:(const NSColor *)theColor;

- (AnimationSequenceTypes) animationSequenceType;

- (void) setAnimationSequenceType:(const AnimationSequenceTypes)theAnimationSequence;

- (BOOL) controlIsVisible:(const AppControlTypes)theControl;

- (void) setControlIsVisible:(const BOOL)theControlIsVisible
					 control:(const AppControlTypes)theControl;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
