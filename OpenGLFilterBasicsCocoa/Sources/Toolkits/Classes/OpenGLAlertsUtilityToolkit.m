//---------------------------------------------------------------------------
//
//	File: OpenGLAlertsUtilityToolkit.m
//
//  Abstract: Utility toolkit to display an alert when an OpenGL related
//            error or warning occurs
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

#import "OpenGLErrors.h"
#import "OpenGLAlertsUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#define GL_FRAMEBUFFER_MIGHT_FAIL_ON_ALL_HARDWARE 0x8FFF

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLAlertsUtilityToolkit

//------------------------------------------------------------------------
//
// These are CGL related warnings or errors
//
//------------------------------------------------------------------------

- (void) initWithCGLAlertsDefaultDictionary
{	
	NSArray *theCGLAlertValues 
						= [NSArray arrayWithObjects:	kCGLErrorBadAttribute, 
														kCGLErrorLBadProperty, 
														kCGLErrorBadPixelFormat, 
														kCGLErrorBadRendererInfo,
														kCGLErrorBadContext, 
														kCGLErrorBadDrawable, 
														kCGLErrorBadDisplay, 
														kCGLErrorBadState,
														kCGLErrorBadValue, 
														kCGLErrorBadMatch, 
														kCGLErrorBadEnumeration, 
														kCGLErrorBadOffScreen,
														kCGLErrorBadFullScreen, 
														kCGLErrorBadWindow, 
														kCGLErrorBadAddress, 
														kCGLErrorBadCodeModule,
														kCGLErrorBadAlloc, 
														kCGLErrorBadConnection, 
														nil];
	
	NSArray *theCGLAlertKeys
						= [NSArray arrayWithObjects:	[NSNumber numberWithInt:kCGLBadAttribute],
														[NSNumber numberWithInt:kCGLBadProperty],
														[NSNumber numberWithInt:kCGLBadPixelFormat],
														[NSNumber numberWithInt:kCGLBadRendererInfo],
														[NSNumber numberWithInt:kCGLBadContext],
														[NSNumber numberWithInt:kCGLBadDrawable],
														[NSNumber numberWithInt:kCGLBadDisplay],
														[NSNumber numberWithInt:kCGLBadState],
														[NSNumber numberWithInt:kCGLBadValue],
														[NSNumber numberWithInt:kCGLBadMatch],
														[NSNumber numberWithInt:kCGLBadEnumeration],
														[NSNumber numberWithInt:kCGLBadOffScreen],
														[NSNumber numberWithInt:kCGLBadFullScreen],
														[NSNumber numberWithInt:kCGLBadWindow],
														[NSNumber numberWithInt:kCGLBadAddress],
														[NSNumber numberWithInt:kCGLBadCodeModule],
														[NSNumber numberWithInt:kCGLBadAlloc],
														[NSNumber numberWithInt:kCGLBadConnection],
														nil];

	alertDefaultDictionary 
			= [[NSDictionary alloc] initWithObjects:theCGLAlertValues forKeys:theCGLAlertKeys];
} // initWithCGLAlertsDefaultDictionary

//------------------------------------------------------------------------
//
// These are OpenGL FBO related warnings or errors
//
//------------------------------------------------------------------------

- (void) initWithOpenGLFBOAlertsDefaultDictionary
{		
	NSArray *theOpenGLFBOAlertValues 
						= [NSArray arrayWithObjects:	kOpenGLErrorFramebufferIncompleteAttachement, 
														kOpenGLErrorFramebufferUnSupportedFormat,
														kOpenGLErrorFramebufferMissingAttachment, 
														kOpenGLErrorFramebufferIncompleteDimensions,
														kOpenGLErrorFramebufferIncompleteFormat, 
														kOpenGLErrorFramebufferIncompleteDrawBuffer, 
														kOpenGLErrorFramebufferIncompleteReadBuffer, 
														kOpenGLErrorFramebufferWillFailOnAllHardware,
														nil];
	
	NSArray *theOpenGLFBOAlertKeys
						= [NSArray arrayWithObjects:	[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_UNSUPPORTED_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT],
														[NSNumber numberWithInt:GL_FRAMEBUFFER_MIGHT_FAIL_ON_ALL_HARDWARE],
														nil];

	alertDefaultDictionary 
			= [[NSDictionary alloc] initWithObjects:theOpenGLFBOAlertValues forKeys:theOpenGLFBOAlertKeys];
} // initWithOpenGLFBOAlertsDefaultDictionary

//------------------------------------------------------------------------
//
// These are OpenGL shader compilation & linking related errors
//
//------------------------------------------------------------------------

- (void) initWithOpenGLShaderAlertsDefaultDictionary
{		
	NSArray *theOpenGLShaderAlertValues 
						= [NSArray arrayWithObjects:	kOpenGLObjectCompileStatusARB, 
														kOpenGLObjecLinkStatusARB,
														nil];
	
	NSArray *theOpenGLShaderAlertKeys
						= [NSArray arrayWithObjects:	[NSNumber numberWithInt:GL_OBJECT_COMPILE_STATUS_ARB],
														[NSNumber numberWithInt:GL_OBJECT_LINK_STATUS_ARB],
														nil];

	alertDefaultDictionary 
			= [[NSDictionary alloc] initWithObjects:theOpenGLShaderAlertValues forKeys:theOpenGLShaderAlertKeys];
} // initWithOpenGLShaderAlertsDefaultDictionary

//------------------------------------------------------------------------

- (id) initWithAlertType:(OpenGLAlertTypes)theAlertType
{
	self = [super init];
	
	alertType = theAlertType;
	
	// If the the purpose of the alert dialog is for displaying CGL errors/warnings
	// then initialize a dictionary with its keys and values, else initialize a
	// dictionary for FBO status errors/warnings
	
	switch ( alertType )
	{
		case alertIsForCGL:
		
			[self initWithCGLAlertsDefaultDictionary];
		
			alertTitle = [[NSString alloc] initWithString:@"CGL Error"];
			
			break;
		
		case alertIsForOpenGLFBO:
			
			[self initWithOpenGLFBOAlertsDefaultDictionary];

			alertTitle = [[NSString alloc] initWithString:@"Framebuffer Status Error"];
			
			break;
			
		case alertIsForOpenGLShaders:
		
			[self initWithOpenGLShaderAlertsDefaultDictionary];

			alertTitle = [[NSString alloc] initWithString:@"Shader Error"];
			
			break;
	} // switch
	
	return self;
} // initWithAlertType

//------------------------------------------------------------------------

+ (id) withAlertType:(OpenGLAlertTypes)theAlertType
{
	return [[[OpenGLAlertsUtilityToolkit allocWithZone:[self zone]] initWithAlertType:theAlertType] autorelease];
} // withAlertType

//------------------------------------------------------------------------

- (void) dealloc
{
	// Title is no longer needed
	
	if ( alertTitle )
	{
		[alertTitle release];
	} // if
	
	// The dictionaries are no longer needed
	
	if ( alertDefaultDictionary )
	{
		[alertDefaultDictionary release];
	} // if
		
	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------
//
// Display an alert dialog box with a message
//
//------------------------------------------------------------------------

- (void) displayAlertBoxWithMessage:(NSString *)theAlertMessage
{
	NSRunAlertPanel
		(
			alertTitle, 
			@"\"%@\"", 
			@"OK", 
			nil, 
			nil, 
			theAlertMessage
		);
} // displayAlertBoxWithMessage

//------------------------------------------------------------------------
//
// In case of an unkonwn error/warning display an alert dialog box with
// an error number.
//
//------------------------------------------------------------------------

- (void) displayAlertBoxWithErrorNumber:(NSInteger)theAlertErrorNumber
{
	NSRunAlertPanel
		(
			alertTitle, 
			@"Error = %ld", 
			@"OK", 
			nil, 
			nil, 
			theAlertErrorNumber
		);
} // displayAlertBoxWithErrorNumber

//------------------------------------------------------------------------
//
// For CGL errors/warnings, display either an alert dialog box with a
// message, or an alert dialog box with an error number.
//
//------------------------------------------------------------------------

- (void) displayAlertBoxWithCGLErrorNumber:(NSInteger)theAlertErrorNumber
{
	NSNumber *alertKey = [NSNumber numberWithInt:theAlertErrorNumber];

	if ( alertKey )
	{
		NSString *alertMessage = [alertDefaultDictionary objectForKey:alertKey];

		if ( alertMessage )
		{
			[self displayAlertBoxWithMessage:alertMessage];
		} // if
		else
		{
			[self displayAlertBoxWithErrorNumber:theAlertErrorNumber];
		} // else
	}  // if
} // displayAlertBoxWithCGLErrorNumber

//------------------------------------------------------------------------
//
// For known FBO status errors/warnings display an alert dialog box with
// a message.  Otherwise, display a the status message that FBO might fail
// on all hardware.
//
//------------------------------------------------------------------------

- (void) displayAlertBoxWithOpenGLFBOErrorNumber:(NSInteger)theAlertErrorNumber
{
	NSNumber *alertKey = [NSNumber numberWithInt:theAlertErrorNumber];

	if ( alertKey )
	{
		NSString *alertMessage = [alertDefaultDictionary objectForKey:alertKey];

		if ( alertMessage )
		{
			[self displayAlertBoxWithMessage:alertMessage];
		} // if
		else
		{
			NSNumber *alertFailure = [NSNumber numberWithInt:GL_FRAMEBUFFER_MIGHT_FAIL_ON_ALL_HARDWARE];
			
			if ( alertFailure )
			{
				NSString *alertFailureMessage = [alertDefaultDictionary objectForKey:alertFailure];
				
				if ( alertFailureMessage )
				{
					[self displayAlertBoxWithMessage:alertFailureMessage];
				} // if
			} // if
		} // else
	}  // if
} // displayAlertBoxWithOpenGLFBOErrorNumber

//------------------------------------------------------------------------
//
// For OpenGL shader errors/warnings, display an alert dialog box with 
// a message.
//
//------------------------------------------------------------------------

- (void) displayAlertBoxWithShaderErrorNumber:(NSInteger)theAlertErrorNumber
{
	NSNumber *alertKey = [NSNumber numberWithInt:theAlertErrorNumber];

	if ( alertKey )
	{
		NSString *alertMessage = [alertDefaultDictionary objectForKey:alertKey];

		if ( alertMessage )
		{
			[self displayAlertBoxWithMessage:alertMessage];
		} // if
	}  // if
} // displayAlertBoxWithShaderErrorNumber

//------------------------------------------------------------------------
//
// Depending on initilization with either alert for CGL or FBO, select
// the appropriate display method.
//
//------------------------------------------------------------------------

- (void) displayAlertBox:(NSInteger)theAlertErrorNumber
{
	switch ( alertType )
	{
		case alertIsForCGL:

			[self displayAlertBoxWithCGLErrorNumber:theAlertErrorNumber];
			
			break;
	
		case alertIsForOpenGLFBO:
			
			[self displayAlertBoxWithOpenGLFBOErrorNumber:theAlertErrorNumber];
			
			break;
			
		case alertIsForOpenGLShaders:
			
			[self displayAlertBoxWithShaderErrorNumber:theAlertErrorNumber];
			
			break;
	} // switch
} // displayAlertBox

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

