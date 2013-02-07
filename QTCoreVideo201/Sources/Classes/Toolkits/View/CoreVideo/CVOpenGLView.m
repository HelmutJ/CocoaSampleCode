//---------------------------------------------------------------------------
//
//	File: CVOpenGLView.m
//
//  Abstract: Core video + OpenGL view toolkit
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
//  Copyright (c) 2009-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "QTVisualContext.h"

#import "CVOpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const char *kVideoFormat = "yuv2";

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLContext
{
	BOOL                  inUse;               // Set to true if using QT OpenGL visual context
    NSOpenGLContext      *context;
    NSOpenGLPixelFormat  *format;
};

typedef struct OpenGLContext   OpenGLContext;

//---------------------------------------------------------------------------

struct CVOpenGLViewData
{
	BOOL                 isValid;               // Set to true if the QT movie was obtained
    BOOL                 isVideo;               // Set to true if the QT movie was obtained
    char                 format[5];             // Pixel Format
    GLuint               align;
	NSSize               size;                  // Frame width & height
	CFAllocatorRef       allocator;				// CF allocator used throughout
	CGDirectDisplayID    displayId;				// Display used by CoreVideo
    CVDisplayLinkRef     displayLink;			// Display link maintained by CV
	CVOptionFlags        lockFlags;				// Flags used for locking the base address
	CVPixelBufferRef     buffer;                // The current frame from CV
    QTMovie             *movie;
    NSRecursiveLock     *lock;
    QTVisualContext     *visual;
    OpenGLContext        graphics;
};

typedef struct CVOpenGLViewData   CVOpenGLViewData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Methods

//---------------------------------------------------------------------------

@interface CVOpenGLView(Private)

- (void) deleteQTMovie;
- (void) deleteQTVisualContext;
- (void) deleteRecursiveLock;
- (void) deleteCVDisplayLink;
- (void) deleteCVPixelBuffer;
- (void) deleteQTCVOpenGLView;
- (void) deleteAssets;

- (void) drawBegin;
- (void) drawEnd;

- (void) prepareQTMovie:(NSString *)theMoviePath;
- (void) prepareCVDisplayLink;
- (void) prepareQTVisualContext;
- (void) prepare:(NSString *)theMoviePath;

- (CVReturn) getFrameForTime:(const CVTimeStamp *)timeStamp 
					flagsOut:(CVOptionFlags *)flagsOut;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Render Callback

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// This is the CoreVideo DisplayLink callback notifying the application when 
// the display will need each frame and is called when the DisplayLink is 
// running -- in response, we call our getFrameForTime method.
//
//---------------------------------------------------------------------------

static CVReturn CoreVideoRenderCallback(CVDisplayLinkRef    displayLink, 
										const CVTimeStamp  *inNow, 
										const CVTimeStamp  *inOutputTime, 
										CVOptionFlags       flagsIn, 
										CVOptionFlags      *flagsOut, 
										void               *displayLinkContext)
{
    CVOpenGLView *context = (CVOpenGLView *)displayLinkContext;
    
	return( [context getFrameForTime:inOutputTime 
                            flagsOut:flagsOut] );
} // CoreVideoRenderCallback

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation CVOpenGLView

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if( self )
	{
		mpCVGLView = (CVOpenGLViewDataRef)calloc(1, sizeof(CVOpenGLViewData) );
		
		if( mpCVGLView != NULL )
		{
			// Initialize core video attributes
			
			mpCVGLView->allocator   = kCFAllocatorDefault;
			mpCVGLView->displayId   = kCGDirectMainDisplay;
			mpCVGLView->displayLink = NULL;
			mpCVGLView->buffer      = NULL;
			mpCVGLView->isValid     = NO;
            mpCVGLView->isVideo     = YES;
			mpCVGLView->lockFlags   = 0;
            mpCVGLView->align       = 4;
            
            // Preferred pixel format for the "video" visual context is "yuv2"
            
            mpCVGLView->format[0] = (kCVPixelFormatType_422YpCbCr8 & 0x000000FF);
            mpCVGLView->format[1] = (kCVPixelFormatType_422YpCbCr8 & 0x0000FF00) >> 8;
            mpCVGLView->format[2] = (kCVPixelFormatType_422YpCbCr8 & 0x00FF0000) >> 16;
            mpCVGLView->format[3] = (kCVPixelFormatType_422YpCbCr8 & 0xFF000000) >> 24;
            mpCVGLView->format[4] = '\0';
            
            // OpenGL context attributes
            
            mpCVGLView->graphics.inUse   = NO;
            mpCVGLView->graphics.context = [self openGLContext];
            mpCVGLView->graphics.format  = [self pixelFormat];
            
			// Initialize default movie HD frame size
			
			mpCVGLView->size.width  = 1920.0f;
			mpCVGLView->size.height = 1080.0f;
            
			// We need a lock around our draw function so two different
			// threads don't try and draw at the same time
			
			mpCVGLView->lock = [NSRecursiveLock new];
            
            // Initialize the visual context
            
            mpCVGLView->visual = nil;
            
            // Initialize the QT movie object
            
            mpCVGLView->movie = nil;
 		} // if
		else
		{
			NSLog( @">> ERROR: CoreVideo OpenGL View - Allocating Memory For View Data Failed!" );
		} // else
	} // if
	
	return( self );
} // initWithFrame

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - DisplayLink

//---------------------------------------------------------------------------
//
// Activate the display link
//
//---------------------------------------------------------------------------

- (BOOL) start
{
	CVReturn success = CVDisplayLinkStart( mpCVGLView->displayLink );
    
    return( success == kCVReturnSuccess );
} // start

//---------------------------------------------------------------------------

- (BOOL) isRunning
{
    return( CVDisplayLinkIsRunning( mpCVGLView->displayLink ) );
} // isRunning

//---------------------------------------------------------------------------
//
// If the display link is active, stop it
//
//---------------------------------------------------------------------------

- (BOOL) stop
{
    CVReturn success = kCVReturnError;
    
	if( CVDisplayLinkIsRunning( mpCVGLView->displayLink ) ) 
	{
    	success = CVDisplayLinkStop( mpCVGLView->displayLink );
    } // if
    
    return( success == kCVReturnSuccess );
} // stop

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// Stop and release the mpCVGLView->movie
//
//---------------------------------------------------------------------------

- (void) deleteQTMovie
{
    if( mpCVGLView->movie ) 
	{
    	[mpCVGLView->movie setRate:0.0];
		
        SetMovieVisualContext( [mpCVGLView->movie quickTimeMovie], NULL );
		
        [mpCVGLView->movie release];
		
        mpCVGLView->movie = nil;
    } // if
} // deleteQTMovie

//---------------------------------------------------------------------------
//
// Release the pixel image context
//
//---------------------------------------------------------------------------

- (void) deleteQTVisualContext
{
	if( mpCVGLView->visual )
	{
		[mpCVGLView->visual release];
		
		mpCVGLView->visual = nil;
	} // if
} // deleteQTVisualContext

//---------------------------------------------------------------------------
//
// Release the recursive mpCVGLView->lock
//
//---------------------------------------------------------------------------

- (void) deleteRecursiveLock
{
    if( mpCVGLView->lock ) 
	{
    	[mpCVGLView->lock release];
		
        mpCVGLView->lock = nil;
    } // if 
} // deleteRecursiveLock

//---------------------------------------------------------------------------
//
// It is critical to dispose of the display link
//
//---------------------------------------------------------------------------

- (void) deleteCVDisplayLink
{
    if( mpCVGLView->displayLink != NULL ) 
	{
    	[self stop];
        
        CVDisplayLinkRelease( mpCVGLView->displayLink );
		
        mpCVGLView->displayLink = NULL;
    } // if
} // deleteCVDisplayLink

//---------------------------------------------------------------------------
//
// Don't leak pixel buffers
//
//---------------------------------------------------------------------------

- (void) deleteCVPixelBuffer
{
	// If we have a previous frame release it
	
	if( mpCVGLView->buffer != NULL ) 
	{
		CVPixelBufferRelease( mpCVGLView->buffer );
		
		mpCVGLView->buffer = NULL;
	} // if
} // deleteCVPixelBuffer

//---------------------------------------------------------------------------

- (void) deleteQTCVOpenGLView
{
	if( mpCVGLView != NULL )
	{
		[self deleteCVDisplayLink];
		[self deleteCVPixelBuffer];
		
		free( mpCVGLView );
	} // if
} // deleteData

//---------------------------------------------------------------------------

- (void) deleteAssets
{
	[self deleteQTMovie];
	[self deleteQTVisualContext];
	[self deleteQTCVOpenGLView];
	[self deleteRecursiveLock];
} // deleteAssets

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
	[self deleteAssets];	
	[super cleanUp];
} // cleanUp

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUp];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Draw tools

//---------------------------------------------------------------------------

- (void) drawBegin
{
	// Prevent drawing from another thread if we're drawing already    
	
	[mpCVGLView->lock lock];
	
	// Make the GL context the current context & clear view port
	
	[self makeCurrentContext];
} // drawBegin

//---------------------------------------------------------------------------

- (void) drawEnd
{
	// Async flush buffer
	
	[self flushBuffer];
	
	// Give time to the Visual Context so it can release internally held 
	// resources for later re-use this function should be called in every 
	// rendering pass, after old images have been released, new images 
	// have been used and all rendering has been flushed to the screen.
	
	[mpCVGLView->visual task];
	
	// Allowing drawing now
	
	[mpCVGLView->lock unlock];
} // drawEnd

//---------------------------------------------------------------------------

- (void) drawScene
{
    return;
} // drawScene

//---------------------------------------------------------------------------

- (void) drawRect:(NSRect)rect
{  
	[self drawBegin];
	
	[self drawScene];
	
	[self drawEnd];
} // drawRect

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Get Movie Frames

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
	if( !mpCVGLView->isValid )
	{
		return( kCVReturnAllocationFailed );
	} // if
	
	// There is no autorelease pool when this method is called because it will
	// be called from another thread it's important to create one or you will 
	// leak objects
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if( pool )
	{
		// Check for a new frame
		
		if (	( [mpCVGLView->visual isValidVisualContext] ) 
			&&	( [mpCVGLView->visual isNewImageAvailable:timeStamp] ) ) 
		{
			CVPixelBufferRef buffer = [mpCVGLView->visual copyImageForTime:timeStamp];
			
			if( buffer != NULL )
			{
				[self deleteCVPixelBuffer];
				
				mpCVGLView->buffer = buffer;
			} // if
            
			// The above call may produce a null frame so check for this first
			// if we have a frame, then draw it
			
			if( mpCVGLView->buffer != NULL )
			{
				[self drawRect:NSZeroRect];
			} // if
			else
			{
				NSLog( @">> WARNING: CoreVideo OpenGL View - QT Visual Context Copy Image for Time Error!" );
			} // else
		} // if
		
		[pool release];
	} // if
	
	return( kCVReturnSuccess );
} // getFrameForTime

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initializers

//---------------------------------------------------------------------------

- (void) prepareQTMovie:(NSString *)theMoviePath
{
	// If we already have a QTMovie release it
	
	[self deleteQTMovie];
	
	// Instantiate a mpCVGLView->movie object
	
	NSError *movieError = nil;
	
	mpCVGLView->movie = [[QTMovie alloc] initWithFile:theMoviePath 
                                                error:&movieError];
	
	if( ( mpCVGLView->movie != nil ) && ( movieError == nil ) )
	{
		// We've a valid mpCVGLView->movie
		
		mpCVGLView->isValid = YES;
		
		// Now get the mpCVGLView->movie size
		
		[[mpCVGLView->movie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&mpCVGLView->size];
	} // if
	else 
	{
		NSLog( @">> ERROR: CoreVideo OpenGL View - %@", movieError );
		
		[movieError release];
	} // else
} // prepareQTMovie

//---------------------------------------------------------------------------

- (void) prepareCVDisplayLink
{
	[self deleteCVDisplayLink];
	
    // Create display link for the main display
	
    CVReturn result = CVDisplayLinkCreateWithCGDisplay(mpCVGLView->displayId, 
													   &mpCVGLView->displayLink);
	
    if( ( result == kCVReturnSuccess ) && ( mpCVGLView->displayLink != NULL ) ) 
	{
    	// Set the current display of a display link.
        
		CVDisplayLinkSetCurrentCGDisplay(mpCVGLView->displayLink, 
                                         mpCVGLView->displayId);
        
        // Set the renderer output callback function
		
    	CVDisplayLinkSetOutputCallback(mpCVGLView->displayLink, 
									   &CoreVideoRenderCallback, 
									   self);
        
        // Activates a display link
		
    	CVDisplayLinkStart( mpCVGLView->displayLink );
    } // if
} // prepareCVDisplayLink

//---------------------------------------------------------------------------

- (void) prepareQTVisualContext
{
	// Delete the old qt visual context
	
	[self deleteQTVisualContext];
	
	// Instantiate a new qt visual context object
    
    if( mpCVGLView->graphics.inUse )
    {
        mpCVGLView->visual = [[QTVisualContext alloc] initQTVisualContextWithSize:&mpCVGLView->size
                                                                          context:mpCVGLView->graphics.context
                                                                           format:mpCVGLView->graphics.format];
    } // if
    else
    {
        mpCVGLView->visual = [[QTVisualContext alloc] initQTVisualContextWithSize:&mpCVGLView->size
                                                                           format:mpCVGLView->format
                                                                        alignment:mpCVGLView->align];
    } // else
} // prepareQTVisualContext

//---------------------------------------------------------------------------
//
// Upon subclassing implement, to initialize 3D objects
//
//---------------------------------------------------------------------------

- (void) prepareScene
{
	return;
} // prepareScene

//---------------------------------------------------------------------------

- (void) prepare:(NSString *)theMoviePath
{
	// New QT & CV resources for a mpCVGLView->movie
	
	[self prepareQTMovie:theMoviePath];
	
	if( mpCVGLView->isValid )
	{
		[self prepareCVDisplayLink];
		[self prepareQTVisualContext];
		
		// New OpenGL resources for a movie
		
		[self prepareScene];
	} // if
} // prepare

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Open a movie

//---------------------------------------------------------------------------
//
// Open a Movie File and instantiate a QTMovie object
//
//---------------------------------------------------------------------------

- (void) openMovie:(NSString *)theMoviePath
{
	// New mpCVGLView->movie resources
	
	[self prepare:theMoviePath];
	
	if( mpCVGLView->isValid )
	{
		// Set Movie to loop
		
		[mpCVGLView->movie setAttribute:[NSNumber numberWithBool:YES] 
                                 forKey:QTMovieLoopsAttribute];
		
		// Targets a movie to render into a visual context
		
		[mpCVGLView->visual setMovie:mpCVGLView->movie];
        
		// Play the movie
		
		[mpCVGLView->movie setRate:1.0];
		
		// Set the window title from the movie if it has a name associated with it
		
		[[self window] setTitle:[mpCVGLView->movie attributeForKey:QTMovieDisplayNameAttribute]];
	} // if
} // openMovie

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (void) setAlignment:(const GLuint)theAlignment
{
    mpCVGLView->align = theAlignment;
} // setAlignment

//---------------------------------------------------------------------------

- (void) setContext:(const BOOL)theGLCtxInUse
{
    mpCVGLView->graphics.inUse = theGLCtxInUse;
} // setContext

//---------------------------------------------------------------------------

- (void) setFormat:(const char *)theFormat
{
    if( theFormat != NULL )
    {
        mpCVGLView->format[0] = theFormat[0];
        mpCVGLView->format[1] = theFormat[1];
        mpCVGLView->format[2] = theFormat[2];
        mpCVGLView->format[3] = theFormat[3];
        
        mpCVGLView->isVideo = strncmp(mpCVGLView->format, kVideoFormat, 4) == 0;
    } // if
} // setFormat

//---------------------------------------------------------------------------

- (GLenum) format
{
    return( mpCVGLView->isVideo ? GL_YCBCR_422_APPLE : GL_BGRA );
} // format

//---------------------------------------------------------------------------

- (NSSize) size
{
	return( mpCVGLView->size );
} // size

//---------------------------------------------------------------------------

- (BOOL) isValid
{
	return( mpCVGLView->buffer != NULL );
} // isValid

//---------------------------------------------------------------------------

- (CVPixelBufferRef) pixelBuffer
{
    return( mpCVGLView->buffer );
} // pixelBuffer

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
