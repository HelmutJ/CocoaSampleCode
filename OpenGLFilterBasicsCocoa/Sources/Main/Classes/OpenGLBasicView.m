//---------------------------------------------------------------------------
//
//	File: OpenGLBasicView.m
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

//------------------------------------------------------------------------

#import "OpenGLPixelFormatAttributes.h"
#import "OpenGLAlertsUtilityToolkit.h"
#import "OpenGLExtUtilityToolkit.h"
#import "OpenGLBasicView.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const NSTimeInterval  kScheduledTimerInSeconds = 1.0f/150.0f; 

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLBasicView

//------------------------------------------------------------------------

#pragma mark -- Reshaping & updating the state --

//------------------------------------------------------------------------

- (void) updateState
{
	[[self openGLContext] makeCurrentContext];
	
	NSRect  bounds = [self bounds];

	[controller reshape:bounds];
} // updateState

//------------------------------------------------------------------------

#pragma mark -- Designated initializer --

//------------------------------------------------------------------------

- (void) heartbeat
{
	[self updateState];
	[self setNeedsDisplay:YES];
} // heartbeat

//------------------------------------------------------------------------

- (void) initMultithreadedOpenGLEngine
{
	CGLError       cglError   = kCGLNoError;
	CGLContextObj  cglContext = CGLGetCurrentContext( );

	// Enable the multi-threaded OpenGL engine
	
	cglError =  CGLEnable( cglContext, kCGLCEMPEngine );

	if ( cglError != kCGLNoError )
	{
		// Multi-threaded execution is possibly not available
		// so what was the returned CGL error?
		
		OpenGLAlertsUtilityToolkit  *alert = [OpenGLAlertsUtilityToolkit withAlertType:alertIsForCGL];
		
		if ( alert )
		{
			[alert displayAlertBox:cglError];
		} // if
	} // if    
} // initMultithreadedOpenGLEngine

//------------------------------------------------------------------------

- (void) initSyncToVBL:(NSOpenGLContext *)theOpenGLContext 
{
	GLint  swapInterval = 1;
	
	// Sync to VBL to avoid tearing.
		
	[theOpenGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
} // initSyncToVBL

//------------------------------------------------------------------------

- (void) initTimerWithTimeInterval:(NSTimeInterval)theTimeInterval
{
	timer = [NSTimer timerWithTimeInterval:theTimeInterval 
								target:self 
								selector:@selector(heartbeat)  
								userInfo:nil 
								repeats:YES];
	
	[timer retain];

	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
} // initTimerWithTimeInterval

//------------------------------------------------------------------------
// 
// OpenGL view initializations
// 
//------------------------------------------------------------------------

- (void) initOpenGLView:(NSRect)theFrame
{
	NSOpenGLContext *context = [self openGLContext];
	
	if ( context )
	{
		// Set the current OpenGL context
		
		[context makeCurrentContext];
		
		// Initialize timer for our controller object to fire at specific 
		// time intervals

		[self initTimerWithTimeInterval:kScheduledTimerInSeconds];
		
		// Sync to VBL to avoid tearing.
			
		[self initSyncToVBL:context];
		
		// Initialize multithreaded OpenGL engine
		
		[self initMultithreadedOpenGLEngine];

		// Setting the initial frame size

		[self setFrameSize:theFrame.size];

		// Initialze the controller object for generating new data for
		// the filter and updating the results of our computation
		
		controller = [[OpenGLController alloc] init];
	} // if
} // initOpenGLView

//------------------------------------------------------------------------

- (NSOpenGLPixelFormat *) initPixelFormat
{
	NSArray *thePixelFormatAttributeKeys = [NSArray arrayWithObjects:	kOpenGLPixelFormatAttributeAccelerated,
																		kOpenGLPixelFormatAttributeNoRecovery,
																		kOpenGLPixelFormatAttributeDoubleBuffer,
																		kOpenGLPixelFormatAttributeColorSize,
																		kOpenGLPixelFormatAttributeAlphaSize,
																		kOpenGLPixelFormatAttributeDepthSize,
																		kOpenGLPixelFormatAttributeStencilSize, 
																		kOpenGLPixelFormatAttributeMultisample,
																		kOpenGLPixelFormatAttributeSampleBuffers,
																		kOpenGLPixelFormatAttributeSamples, 
																		nil];
	
	NSArray *thePixelFormatAttributeValues = [NSArray arrayWithObjects:	[NSNumber numberWithBool:YES],
																		[NSNumber numberWithBool:YES],
																		[NSNumber numberWithBool:YES],
																		[NSNumber numberWithInt:24], 
																		[NSNumber numberWithInt:8],
																		[NSNumber numberWithInt:16],
																		[NSNumber numberWithInt:8],
																		[NSNumber numberWithBool:YES],
																		[NSNumber numberWithInt:1],
																		[NSNumber numberWithInt:4],
																		nil];

	NSDictionary *thePixelFormatAttributesDictionary 
						= [NSDictionary dictionaryWithObjects:thePixelFormatAttributeValues 
													forKeys:thePixelFormatAttributeKeys];

	return [[OpenGLExtUtilityToolkit withOpenGLPixelFormatAttributesDictionary:thePixelFormatAttributesDictionary] pixelFormat];
} // initPixelFormat

//------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)theFrame pixelFormat:(NSOpenGLPixelFormat *)thePixelFormat
{	
	// Create a GL Context to use - i.e. init the superclass
	
	if( thePixelFormat == nil )
	{
		thePixelFormat = [self initPixelFormat];
	} //  if
	
	self = [super initWithFrame:theFrame pixelFormat:thePixelFormat];
			
	if ( self )
	{
		[self initOpenGLView:theFrame];
	} // if
	
	return self;
} // initWithFrame

//------------------------------------------------------------------------

- (id) initWithFrame: (NSRect)theFrame
{
	return [self initWithFrame:theFrame pixelFormat:nil];
} // initWithFrame

//------------------------------------------------------------------------
//
// Moved or resized
//
//------------------------------------------------------------------------

#pragma mark -- OpenGL update and reshape methods --

//------------------------------------------------------------------------

- (void)update
{
	[super update];
	[self  updateState];
} // update

//------------------------------------------------------------------------
//
// Scrolled, moved or resized
//
//------------------------------------------------------------------------

- (void)reshape
{
	[super reshape];
	[self  updateState];
} // reshape

//------------------------------------------------------------------------

#pragma mark -- Deleting resources --

//------------------------------------------------------------------------

- (void) dealloc
{
	// Release the OpenGL filter
	
	[controller dealloc];
	
	// Release the update timer
	
	if ( timer ) 
	{
		[timer invalidate];
		[timer release];
	} // if	

	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

#pragma mark -- Drawing a rectangle's content --

//------------------------------------------------------------------------
//
// Override the viewController's drawRect: to draw our GL content.
//	 
//------------------------------------------------------------------------

- (void) drawRect: (NSRect)theRect
{
	[[self openGLContext] makeCurrentContext];
	
	GLclampf clearColor[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	clearColor[colorIndex] = 0.0f;
	
	glClearColor( clearColor[0], clearColor[1], clearColor[2], clearColor[3] );

	[controller update];
	
	[[self openGLContext] flushBuffer];
} // drawRect

//------------------------------------------------------------------------

#pragma mark -- Actions --

//------------------------------------------------------------------------
//
//	The UI buttons are targetted to call this action method:
//
//------------------------------------------------------------------------

- (IBAction) setClearColor: (id) sender
{
	colorIndex = [sender tag];
	
	[self setNeedsDisplay: YES];
} // setClearColor

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

