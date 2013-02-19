/*
	    File: main.m
	Abstract: Main file.
	 Version: 1.2
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
	Inc. ("Apple") in consideration of your agreement to the following
	terms, and your use, installation, modification or redistribution of
	this Apple software constitutes acceptance of these terms.  If you do
	not agree with these terms, please do not use, install, modify or
	redistribute this Apple software.
	
	In consideration of your agreement to abide by the following terms, and
	subject to these terms, Apple grants you a personal, non-exclusive
	license, under Apple's copyrights in this original Apple software (the
	"Apple Software"), to use, reproduce, modify and redistribute the Apple
	Software, with or without modifications, in source and/or binary forms;
	provided that if you redistribute the Apple Software in its entirety and
	without modifications, you must retain this notice and the following
	text and disclaimers in all such redistributions of the Apple Software.
	Neither the name, trademarks, service marks or logos of Apple Inc. may
	be used to endorse or promote products derived from the Apple Software
	without specific prior written permission from Apple.  Except as
	expressly stated in this notice, no other rights or licenses, express or
	implied, are granted by Apple herein, including but not limited to any
	patent rights that may be infringed by your derivative works or by other
	works in which the Apple Software may be incorporated.
	
	The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
	MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
	THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
	FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
	OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
	
	IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
	MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
	AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
	STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#define kSlideShowInterval			3.0

@interface SlideShowApplication : NSApplication <NSApplicationDelegate>
{
@private
	NSMutableArray*				_fileList;
	NSOpenGLContext*			_openGLContext;
	QCRenderer*					_renderer;
}
@end

@implementation SlideShowApplication

- (id) init
{
	//We need to be our own delegate
	if(self = [super init])
	[self setDelegate:self];
	
	return self;
}

- (void) applicationDidFinishLaunching:(NSNotification*)aNotification 
{
	NSArray*						imageFileTypes = [NSImage imageFileTypes];
	GLint							value = 1;
	NSOpenGLPixelFormatAttribute	attributes[] = {
														NSOpenGLPFAFullScreen,
														NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
														NSOpenGLPFANoRecovery,
														NSOpenGLPFADoubleBuffer,
														NSOpenGLPFAAccelerated,
														NSOpenGLPFADepthSize, 24,
														(NSOpenGLPixelFormatAttribute) 0
													};
	NSOpenGLPixelFormat*			format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
	NSOpenPanel*					openPanel;
	NSDirectoryEnumerator*			enumerator;
	NSString*						basePath;
	NSString*						subPath;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	QCComposition*					composition;
	NSArray*						compositions;
	CGColorSpaceRef					colorSpace;
#endif
	
	//Ask the user for a directory of images
	openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if([openPanel runModalForDirectory:nil file:nil types:nil] != NSOKButton) {
		NSLog(@"No directory specified");
		[NSApp terminate:nil];
	}
	
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	//Pick up a random transition composition from the repository
	compositions = [[QCCompositionRepository sharedCompositionRepository] compositionsWithProtocols:[NSArray arrayWithObject:QCCompositionProtocolGraphicTransition] andAttributes:nil];
	if(![compositions count]) {
		NSLog(@"No transition compositions available");
		[NSApp terminate:nil];
	}
	composition = [compositions objectAtIndex:(random() % [compositions count])];
#endif
	
	//Populate an array with all the image files in the directory (no recursivity)
	_fileList = [NSMutableArray new];
	basePath = [[openPanel filenames] objectAtIndex:0];
	enumerator = [[NSFileManager defaultManager] enumeratorAtPath:basePath];
	while(subPath = [enumerator nextObject]) {
		if([[[enumerator fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			[enumerator skipDescendents];
			continue;
		}
		if([imageFileTypes containsObject:[subPath pathExtension]])
		[_fileList addObject:[basePath stringByAppendingPathComponent:subPath]];
	}
	if([_fileList count] < 2) {
		NSLog(@"The directory contain less than 2 image files");
		[NSApp terminate:nil];
	}
	
	//Capture the main screen
	CGDisplayCapture(kCGDirectMainDisplay);
	CGDisplayHideCursor(kCGDirectMainDisplay);
	
	//Create the fullscreen OpenGL context on the main screen (double-buffered with color and depth buffers)
	_openGLContext = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
	if(_openGLContext == nil) {
		NSLog(@"Cannot create OpenGL context");
		[NSApp terminate:nil];
	}
	[_openGLContext setFullScreen];
	[_openGLContext setValues:&value forParameter:kCGLCPSwapInterval];
	
	//Create the QuartzComposer Renderer with that OpenGL context and the transition composition file
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	colorSpace = CGDisplayCopyColorSpace(kCGDirectMainDisplay);
	_renderer = [[QCRenderer alloc] initWithCGLContext:[_openGLContext CGLContextObj] pixelFormat:[format CGLPixelFormatObj] colorSpace:colorSpace composition:composition];
	CGColorSpaceRelease(colorSpace);
#else
	_renderer = [[QCRenderer alloc] initWithOpenGLContext:_openGLContext pixelFormat:format file:[[NSBundle mainBundle] pathForResource:@"Transition" ofType:@"qtz"]];
#endif
	if(_renderer == nil) {
		NSLog(@"Cannot create QCRenderer");
		[NSApp terminate:nil];
	}
	
	//Run first transition ASAP
	[self performSelector:@selector(_performTransition:) withObject:nil afterDelay:0.0];
}

- (void) _performTransition:(id)param
{
	double					time;
	NSImage*				image;
	
	//Load the next image
	image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:[_fileList objectAtIndex:0]]];
	if(image == nil)
	NSLog(@"Cannot load image file at path: %@", [_fileList objectAtIndex:0]);
	[_fileList removeObjectAtIndex:0];
	
	//Set transition source image (just get it from the previous destination image)
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	[_renderer setValue:[_renderer valueForInputKey:QCCompositionInputDestinationImageKey] forInputKey:QCCompositionInputSourceImageKey];
#else
	[_renderer setValue:[_renderer valueForInputKey:@"destination"] forInputKey:@"source"];
#endif
	
	//Set transition destination image (the new image)
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	[_renderer setValue:image forInputKey:QCCompositionInputDestinationImageKey];
#else
	[_renderer setValue:image forInputKey:@"destination"];
#endif
	
	//Release next image
	[image release];
	
	//Render transition - FIXME: do that from a runloop timer to avoid blocking the application and have accurate timing
	for(time = 0.0; time < 1.0; time += 0.01) {
		if(![_renderer renderAtTime:time arguments:nil])
		NSLog(@"Rendering failed at time %.3fs", time);
		[_openGLContext flushBuffer];
	}
	if(![_renderer renderAtTime:1.0 arguments:nil]) //This is necessary to make sure the last image rendered is at time 1.0 exactly (otherwise, we might have visual garbage)
	NSLog(@"Rendering failed at time %.3fs", time);
	[_openGLContext flushBuffer];
	
	//Schedule next transition
	if([_fileList count])
	[self performSelector:@selector(_performTransition:) withObject:nil afterDelay:kSlideShowInterval];
}

- (void) sendEvent:(NSEvent*)event
{
	//If the user pressed the [Esc] key, we need to exit
	if(([event type] == NSKeyDown) && ([event keyCode] == 0x35))
	[NSApp terminate:nil];
	
	[super sendEvent:event];
}

- (void) applicationWillTerminate:(NSNotification*)aNotification 
{
	//Destroy the renderer
	[_renderer release];
	
	//Destroy the OpenGL context
	[_openGLContext clearDrawable];
	[_openGLContext release];
	
	//Release main screen
	if(CGDisplayIsCaptured(kCGDirectMainDisplay)) {
		CGDisplayShowCursor(kCGDirectMainDisplay);
		CGDisplayRelease(kCGDirectMainDisplay);
	}
	
	//Release file list
	[_fileList release];
}

@end

int main(int argc, const char *argv[])
{
    return NSApplicationMain(argc, argv);
}
