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

#import "AlertPanelKit.h"
#import "QTCoreVideoOpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct CVAttributes
{
	CFAllocatorRef      allocator;		// CF allocator used throughout
	CGDirectDisplayID   displayId;		// Display used by CoreVideo
    CVDisplayLinkRef    displayLink;	// Display link maintained by CV
	CVOptionFlags       lockFlags;		// Flags used for locking the base address
	CVPixelBufferRef    videoFrame;		// The current frame from CV
};

typedef struct CVAttributes  CVAttributes;

//---------------------------------------------------------------------------

struct QTMovieAttributes
{
	NSSize   frame;			// Frame width & height
	GLuint   frameSize;		// Frame width & height
};

typedef struct QTMovieAttributes   QTMovieAttributes;

//---------------------------------------------------------------------------

struct AppControlsAttributes
{
	GLSLTypes               shaderType;				// Shader selection
	AnimationSequenceTypes  animationSequenceType;	// Selected animation set
	float                   uniformFloatValue[5];	// Uniform values
	BOOL                    uniformStyleFlag;		// The shader style (if more than one)
	BOOL                    controlIsVisible[8];	// Fade in/out controls
};

typedef struct AppControlsAttributes   AppControlsAttributes;

//---------------------------------------------------------------------------

struct QTCVOpenGLAttributes
{
	AppControlsAttributes  appControls;		// Values from UI
	CVAttributes           coreVideo;		// CoreVideo attributes
	QTMovieAttributes      qtMovie;			// QT movie attributes
};

typedef struct QTCVOpenGLAttributes   QTCVOpenGLAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -- Render Callback --

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// This is the CoreVideo DisplayLink callback notifying the application when 
// the display will need each frame and is called when the DisplayLink is 
// running -- in response, we call our getFrameForTime method.
//
//---------------------------------------------------------------------------

static CVReturn CoreVideoRenderCallback(	CVDisplayLinkRef    displayLink, 
											const CVTimeStamp  *inNow, 
											const CVTimeStamp  *inOutputTime, 
											CVOptionFlags       flagsIn, 
											CVOptionFlags      *flagsOut, 
											void               *displayLinkContext )
{
	return [(QTCoreVideoOpenGLView *)displayLinkContext getFrameForTime:inOutputTime flagsOut:flagsOut];
} // CoreVideoRenderCallback

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation QTCoreVideoOpenGLView

//---------------------------------------------------------------------------

#pragma mark -- Initialize Instance Variables --

//---------------------------------------------------------------------------

 - (void) initQTMovieSize
{
	attributes->qtMovie.frame.width  = 1920.0f;
	attributes->qtMovie.frame.height = 820.0f;
	attributes->qtMovie.frameSize    = 0;
} // initQTMovieSize

//---------------------------------------------------------------------------

- (void) initCoreVideoAttributes
{
	attributes->coreVideo.allocator   = kCFAllocatorDefault;
	attributes->coreVideo.displayId   = kCGDirectMainDisplay;
	attributes->coreVideo.displayLink = NULL;
	attributes->coreVideo.videoFrame  = NULL;
	attributes->coreVideo.lockFlags   = 0;
} // initCoreVideoAttributes

//---------------------------------------------------------------------------

- (void) initAppControls
{
	// Default shader type
	
	attributes->appControls.shaderType = kShaderBlur;
	
	// Default animation set
	
	attributes->appControls.animationSequenceType = kAnimationWakeUpSequence;
	
	// Default uniform values for the shader(s)
	
	attributes->appControls.uniformFloatValue[0] = 0.5f;
	attributes->appControls.uniformFloatValue[1] = 0.5f;
	attributes->appControls.uniformFloatValue[2] = 0.5f;
	attributes->appControls.uniformFloatValue[3] = 0.5f;
	attributes->appControls.uniformFloatValue[4] = 0.5f;
	
	// Default boolean uniform value for the shader style,
	// if a shader has more than one style
	
	attributes->appControls.uniformStyleFlag = NO;

	// Application controls are visible or not?

	attributes->appControls.controlIsVisible[kControlPopUpMenu] = YES;
	
	attributes->appControls.controlIsVisible[kControlTopSlider]          = YES;
	attributes->appControls.controlIsVisible[kControlTopTextField]       = YES;
	attributes->appControls.controlIsVisible[kControlTopStaticTextField] = YES;
	
	attributes->appControls.controlIsVisible[kControlBottomSlider]          = NO;
	attributes->appControls.controlIsVisible[kControlBottomTextField]       = NO;
	attributes->appControls.controlIsVisible[kControlBottomStaticTextField] = NO;
	
	attributes->appControls.controlIsVisible[kControlColorWell] = NO;
	
	attributes->appControls.controlIsVisible[kControlPushButton] = NO;
} // initAppControls

//---------------------------------------------------------------------------

- (void) initObjects
{
	// QTKit & CoreVideo
	
	movie         = nil;
	visualContext = nil;
	
	// Shaders
	
	shaderUnits = [GLSLUnitsController new];
} // initObjects

//---------------------------------------------------------------------------
//
// We need a lock around our draw function so two different threads don't
// try and draw at the same time
//
//---------------------------------------------------------------------------

- (void) newRecursiveLock
{
	lock = [NSRecursiveLock new];
} // newRecursiveLock

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (void) awakeFromNib
{
	viewMemObj = [[MemObject alloc] initMemoryWithType:kMemAlloc size:sizeof(QTCVOpenGLAttributes)];
	
	if ( viewMemObj )
	{
		attributes = (QTCVOpenGLAttributesRef)[viewMemObj pointer];
		
		if ( [viewMemObj isPointerValid] )
		{
			[self initQTMovieSize];
			[self initCoreVideoAttributes];
			[self initAppControls];
			[self initObjects];
			
			[self newRecursiveLock];
		} // if
		else
		{
			[[AlertPanelKit withTitle:@"QTCoreVideo OpenGL View" 
							  message:@"Failure Allocating Memory For View Attributes"
								 exit:YES] displayAlertPanel];
		} // else
	} // if
} // awakeFromNib

//---------------------------------------------------------------------------

#pragma mark -- Cleanup all the Resources --

//---------------------------------------------------------------------------

- (void) deleteGLSLUnits
{
	if ( shaderUnits )
	{
		[shaderUnits release];
		
		shaderUnits = nil;
	} // if
} // deleteGLSLUnits

//---------------------------------------------------------------------------
//
// Stop and release the movie
//
//---------------------------------------------------------------------------

- (void) deleteQTMovie
{
    if ( movie != nil ) 
	{
    	[movie setRate:0.0];
		
        SetMovieVisualContext( [movie quickTimeMovie], NULL );
		
        [movie release];
		
        movie = nil;
    } // if
} // deleteQTMovie

//---------------------------------------------------------------------------
//
// It is critical to dispose of the display link
//
//---------------------------------------------------------------------------

- (void) deleteCVDisplayLink
{
    if ( attributes->coreVideo.displayLink ) 
	{
    	CVDisplayLinkStop( attributes->coreVideo.displayLink );
        CVDisplayLinkRelease( attributes->coreVideo.displayLink );
		
        attributes->coreVideo.displayLink = NULL;
    } // if
} // deleteCVDisplayLink

//---------------------------------------------------------------------------
//
// Don't leak Core Video OpenGL textures
//
//---------------------------------------------------------------------------

- (void) deleteCVTexture
{
	// If we have a previous frame release it
	
	if ( attributes->coreVideo.videoFrame != NULL ) 
	{
		CVOpenGLTextureRelease( attributes->coreVideo.videoFrame );
		
		attributes->coreVideo.videoFrame = NULL;
	} // if
} // deleteCVTexture

//---------------------------------------------------------------------------
//
// Release the pixel image context
//
//---------------------------------------------------------------------------

- (void) deleteQTVisualContext
{
	if ( visualContext )
	{
		[visualContext release];
		
		visualContext = nil;
	} // if
} // deleteQTVisualContext
 
//---------------------------------------------------------------------------

- (void) deleteQTCVOpenGLAttributes
{
	if ( viewMemObj )
	{
		[viewMemObj release];
		
		viewMemObj = nil;
	} // if
} // deleteQTCVOpenGLAttributes

//---------------------------------------------------------------------------
//
// Release the recursive lock
//
//---------------------------------------------------------------------------

- (void) deleteRecursiveLock
{
    if ( lock ) 
	{
    	[lock release];
		
        lock = nil;
    } // if 
} // deleteRecursiveLock

//---------------------------------------------------------------------------
//
// It is very important that we clean up the rendering objects before the 
// view is disposed, remember that with the display link running you're 
// applications render callback may be called at any time including when 
// the application is quitting or the view is being disposed, additionally 
// you need to make sure you're not consuming OpenGL resources or leaking 
// textures -- this clean up routine makes sure to stop and release 
// everything.
//
//---------------------------------------------------------------------------

- (void) cleanUp
{
	[self deleteCVDisplayLink];
	[self deleteCVTexture];
	[self deleteQTVisualContext];
	[self deleteQTMovie];
	[self deleteQTCVOpenGLAttributes];
	[self deleteGLSLUnits];
	[self deleteRecursiveLock];
} // delete

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self  cleanUp];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -- Draw into a OpenGL view --

//---------------------------------------------------------------------------

- (void) drawObject
{
	if ( attributes->coreVideo.videoFrame != NULL )
	{
		// Some set up

		[self setupView:0.5];
		
		// Draw into the view
		
		[shaderUnits excuteShaderUnit:attributes->coreVideo.videoFrame
								type:attributes->appControls.shaderType
								flag:attributes->appControls.uniformStyleFlag
								value:attributes->appControls.uniformFloatValue];
	} // if
} // drawObject

//---------------------------------------------------------------------------

- (void) drawBegin
{
	// Prevent drawing from another thread if we're drawing already    
	
	[lock lock];
    
	// Make the GL context the current context
	
	[[self openGLContext] makeCurrentContext];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
} // drawBegin

//---------------------------------------------------------------------------

- (void) drawEnd
{
	[[self openGLContext] flushBuffer];

	// Give time to the Visual Context so it can release internally held 
	// resources for later re-use this function should be called in every 
	// rendering pass, after old images have been released, new images 
	// have been used and all rendering has been flushed to the screen.
	
	[visualContext task];

    [lock unlock];
} // drawEnd

//---------------------------------------------------------------------------

- (void) drawRect:(NSRect)rect
{  
	[self drawBegin];
	
		[self drawObject];
	
	[self drawEnd];
} // drawRect

//---------------------------------------------------------------------------

#pragma mark -- Display Link Obtaining Frames --

//---------------------------------------------------------------------------
//
// getFrameForTime is called from the Display Link callback when it's time 
// for us to check to see if we have a frame available to render -- if we do, 
// draw -- if not, just task the Visual Context and split.
//
//---------------------------------------------------------------------------

- (CVReturn) getFrameForTime:(const CVTimeStamp *)timeStamp 
					flagsOut:(CVOptionFlags *)flagsOut
{
	// There is no autorelease pool when this method is called because it will
	// be called from another thread it's important to create one or you will 
	// leak objects
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	// Check for new frame
	
	if (		( [visualContext isValidVisualContext] ) 
			&&	( [visualContext isNewImageAvailable:timeStamp] ) ) 
	{		
		// If we have a previous frame release it
		
		[self deleteCVTexture];
		
		// Get a "frame" (image image) from the Visual Context, indexed by 
		// the provided time
		
		attributes->coreVideo.videoFrame = [visualContext copyImageForTime:timeStamp];
		
		// The above call may produce a null frame so check for this first
        // if we have a frame, then draw it
		
		if ( attributes->coreVideo.videoFrame != NULL )
		{
        	[self drawRect:NSZeroRect];
		} // if
		else
		{
			NSLog( @"WARNING: QT Visual Contex Copy Image for Time Error!" );
		} // else
	} // if
    
    [pool release];
	
	return kCVReturnSuccess;
} // getFrameForTime

//---------------------------------------------------------------------------

#pragma mark -- Initialize movie frame size --

//---------------------------------------------------------------------------

- (void) newQTMovieAttributes:(NSString *)theMoviePath
{
	// If we already have a QTMovie release it
	
	[self deleteQTMovie];

	// Instantiate a movie object
	
	movie = [[QTMovie alloc] initWithFile:theMoviePath error:nil];

	// Get the movie size
	
	[[movie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&attributes->qtMovie.frame];
} // newQTMovieAttributes

//---------------------------------------------------------------------------

#pragma mark -- Initialize Core Video --

//---------------------------------------------------------------------------

- (void) newCVDisplayLink
{
	[self deleteCVDisplayLink];
	
    // Create display link for the main display
	
    CVDisplayLinkCreateWithCGDisplay(	attributes->coreVideo.displayId, 
										&attributes->coreVideo.displayLink );
	
    if ( attributes->coreVideo.displayLink != NULL ) 
	{
    	// Set the current display of a display link.
		
    	CVDisplayLinkSetCurrentCGDisplay(	attributes->coreVideo.displayLink, 
											attributes->coreVideo.displayId );
        
        // Set the renderer output callback function
		
    	CVDisplayLinkSetOutputCallback( attributes->coreVideo.displayLink, 
										&CoreVideoRenderCallback, 
										self );
        
        // Activates a display link
		
    	CVDisplayLinkStart( attributes->coreVideo.displayLink );
    } // if
} // newCVDisplayLink

//---------------------------------------------------------------------------

#pragma mark -- Initialize QT Visual Context --

//---------------------------------------------------------------------------

- (void) newQTVisualContext
{
	// Delete the old qt visual context
	
	[self deleteQTVisualContext];
	
	// Instantiate a new qt visual context object
	
	visualContext = [[QTVisualContextKit alloc] initQTVisualContextWithSize:attributes->qtMovie.frame
																		type:kQTOpenGLTextureContext
																		context:[self openGLContext]
																		pixelFormat:[self pixelFormat]];
} // newQTVisualContext

//---------------------------------------------------------------------------

#pragma mark -- Open a movie with new resources --

//---------------------------------------------------------------------------

- (void) newResourceForMovie:(NSString *)theMoviePath
{
	// New QT & CV resources for a movie
	
	[self newQTMovieAttributes:theMoviePath];
	[self newCVDisplayLink];
	[self newQTVisualContext];
	
	// New OpenGL GLSL units for a movie
	
	[shaderUnits getShaderUnitsWithSize:&attributes->qtMovie.frame];
} // newResourceForMovie

//---------------------------------------------------------------------------
//
// Open a Movie File and instantiate a QTMovie object
//
//---------------------------------------------------------------------------

- (void) openMovie:(NSString *)theMoviePath
{
	// New movie resources
	
	[self newResourceForMovie:theMoviePath];
	
	// Set Movie to loop
	
	[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
	
	// Targets a Movie to render into a visual context
	
	[visualContext setMovie:movie];
	
	// Play the Movie
	
	[movie setRate:1.0];

	// Set the window title from the Movie if it has a name associated with it
	
	[[self window] setTitle:[movie attributeForKey:QTMovieDisplayNameAttribute]];
} // openMovie

//---------------------------------------------------------------------------

#pragma mark -- CoreVideo Accessor --

//---------------------------------------------------------------------------

- (CVDisplayLinkRef) displayLink
{
	return attributes->coreVideo.displayLink;
} // displayLink

//---------------------------------------------------------------------------

#pragma mark -- Shader Accessors --

//---------------------------------------------------------------------------
//
// Shader selection from popup button
//
//---------------------------------------------------------------------------

- (void) setShaderItem:(const GLSLTypes)theShader
{
	attributes->appControls.shaderType = theShader;
} // setShaderItem

//---------------------------------------------------------------------------
//
// Setting uniform value for top slider
//
//---------------------------------------------------------------------------

- (void) setUniformUsingTopSliderOrTopTextField:(const float)theUniformValue
{
	attributes->appControls.uniformFloatValue[0] = theUniformValue;
} // setUniformUsingTopSliderOrTopTextField

//---------------------------------------------------------------------------
//
// Setting uniform value for bottom slider
//
//---------------------------------------------------------------------------

- (void) setUniformUsingBottomSliderOrBottomTextField:(const float)theUniformValue
{
	attributes->appControls.uniformFloatValue[1] = theUniformValue;
} // setUniformUsingBottomSliderOrBottomTextField

//---------------------------------------------------------------------------
//
// Setting uniform value for color match accessory slider
//
//---------------------------------------------------------------------------

- (void) setUniformUsingColorPanelAccessoryControls:(const float)theUniformValue
{
	attributes->appControls.uniformFloatValue[1] = theUniformValue;
} // setUniformUsingColorPanelAccessoryControls

//---------------------------------------------------------------------------
//
// Setting uniform values for color well
//
//---------------------------------------------------------------------------

- (void) setUniformUsingColorWell:(const NSColor *)theColor
{
	attributes->appControls.uniformFloatValue[2] = [theColor redComponent];
	attributes->appControls.uniformFloatValue[3] = [theColor greenComponent];
	attributes->appControls.uniformFloatValue[4] = [theColor blueComponent];
} // setUniformUsingColorWell

//---------------------------------------------------------------------------
//
// The flag for style
//
//---------------------------------------------------------------------------

- (void) setUniformUsingPushButtonState:(const BOOL)theFlag
{
	attributes->appControls.uniformStyleFlag = theFlag;
} // setUniformUsingPushButtonState

//---------------------------------------------------------------------------

#pragma mark -- App Control States for View Animation --

//---------------------------------------------------------------------------

- (BOOL) controlIsVisible:(const AppControlTypes)theControl
{
	return  attributes->appControls.controlIsVisible[theControl];
} // controlIsVisible

//---------------------------------------------------------------------------

- (void) setControlIsVisible:(const BOOL)theControlIsVisible
					 control:(const AppControlTypes)theControl
{
	attributes->appControls.controlIsVisible[theControl] = theControlIsVisible;
} // setTopSliderIsVisible

//---------------------------------------------------------------------------

- (AnimationSequenceTypes) animationSequenceType
{
	return attributes->appControls.animationSequenceType;
} // animationSequenceType

//---------------------------------------------------------------------------

- (void) setAnimationSequenceType:(const AnimationSequenceTypes)theAnimationSequence
{
	attributes->appControls.animationSequenceType = theAnimationSequence;
} // setAnimationSequenceType

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
