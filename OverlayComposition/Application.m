/*
	    File: Application.m
	Abstract: Application class.
	 Version: 1.1
	
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

/* We use CGL macros to ensure optimal performances and avoid having to deal with the current OpenGL context */
#import <OpenGL/CGLMacro.h>

#import "Application.h"

//CONSTANTS:

#define kOpenURLPortKey			@"openURL"

//CLASS INTERFACES:

@interface Application (Internal)
- (BOOL) _hasURLPort;
- (NSURL*) _renderWithArguments:(NSDictionary*)arguments;
- (NSMenu*) _contextualMenu;
@end

//CLASS IMPLEMENTATIONS:

@implementation ApplicationView

- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
	/* We want the first click to be interpreted */
	return YES;
}

- (NSMenu*) menuForEvent:(NSEvent*)event
{
	/* Simply return menu from application's nib */
	return [(Application*)NSApp _contextualMenu];
}

- (void) drawRect:(NSRect)rect
{
	/* Clear the view with transparency */
	[[NSColor clearColor] set];
	NSRectFill(rect);
}

- (void) mouseDown:(NSEvent*)event
{
	NSRect								bounds = [self bounds];
	NSPoint								mouse;
	NSURL*								openURL;
	
	/* Make sure the current composition has an "openURL" output String port and we have a double-click */
	if(![(Application*)NSApp _hasURLPort] || ([event clickCount] != 2)) {
		[super mouseDown:event];
		return;
	}
	
	/* Normalize the mouse coordinates */
	mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	mouse.x /= bounds.size.width;
	mouse.y /= bounds.size.height;
	
	/* Render a single frame immediately passing the mouse coordinates and the event, and if a URL is returned, open it */
	openURL = [(Application*)NSApp _renderWithArguments:[NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPoint:mouse], QCRendererMouseLocationKey, event, QCRendererEventKey, nil]];
	if(openURL)
	[[NSWorkspace sharedWorkspace] openURL:openURL];
}

- (void) mouseUp:(NSEvent*)event
{
	NSRect								bounds = [self bounds];
	NSPoint								mouse;
	
	/* Make sure the current composition has an "openURL" output String port and we have a double-click */
	if(![(Application*)NSApp _hasURLPort] || ([event clickCount] != 2)) {
		[super mouseDown:event];
		return;
	}
	
	/* Normalize the mouse coordinates */
	mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	mouse.x /= bounds.size.width;
	mouse.y /= bounds.size.height;
	
	/* Render a single frame immediately passing the mouse coordinates and the event */
	[(Application*)NSApp _renderWithArguments:[NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPoint:mouse], QCRendererMouseLocationKey, event, QCRendererEventKey, nil]];
}

@end

@implementation Application

+ (void) initialize
{
	NSMutableDictionary*				defaults = [NSMutableDictionary dictionary];
	
	/* Preset our user defaults */
	[defaults setObject:[NSNumber numberWithInteger:30] forKey:kUserDefaultKey_RenderPeriod];
	[defaults setObject:[NSNumber numberWithInteger:256] forKey:kUserDefaultKey_RenderWidth];
	[defaults setObject:[NSNumber numberWithInteger:256] forKey:kUserDefaultKey_RenderHeight];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	
	/* Set checkmark for render frequency menu items */
	if([menuItem action] == @selector(setRefreshFrequency:)) {
		if([menuItem tag] == [defaults integerForKey:kUserDefaultKey_RenderPeriod])
		[menuItem setState:NSOnState];
		else
		[menuItem setState:NSOffState];
	}
	else if([menuItem action] == @selector(setParameters:))
	return [parametersView hasParameters];
	
	return [super validateMenuItem:menuItem];
}

- (NSMenu*) _contextualMenu
{
	return contextualMenu;
}

- (BOOL) _hasURLPort
{
	return _hasURLPort;
}

- (NSURL*) _renderWithArguments:(NSDictionary*)arguments
{
	CGLContextObj						cgl_ctx = [_glContext CGLContextObj];
	NSTimeInterval						time = [NSDate timeIntervalSinceReferenceDate];
	NSURL*								url = nil;
	NSString*							string;
	
	/* Compute rendering time */
	if(_startTime <= 0.0)
	_startTime = time;
	time -= _startTime;
	
	/* Render a frame from the composition or paint with red on error */
	if([_renderer renderAtTime:time arguments:arguments]) {
		/* If the composition has an output port with key "OpenURL" and of type String, try to make a URL out of its current value */
		if(_hasURLPort) {
			string = [_renderer valueForOutputKey:kOpenURLPortKey];
			if([string length])
			url = [NSURL URLWithString:string];
		}
	}
	else {
		glClearColor(1.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
	}
	[_glContext flushBuffer];
	
	return url;
}

- (void) _renderTimer:(NSTimer*)timer
{
	[self _renderWithArguments:nil];
}

- (void) _viewGlobalFrameDidChange:(NSNotification*)notification
{
	NSRect								frame = [[_window contentView] frame];
	CGLContextObj						cgl_ctx = [_glContext CGLContextObj];
	
	/* Make sure to update the OpenGL context */
	[_glContext update];
	glViewport(0, 0, frame.size.width, frame.size.height);
	
	/* Re-render immediately */
	[self _renderWithArguments:nil];
}

- (void) finishLaunching
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	NSOpenGLPixelFormatAttribute		attributes[] = {NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, 24, 0};
	GLint								value;
	NSString*							path;
	
	/* Call super */
	[super finishLaunching];
	
	/* Create and configure main window */
	_window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 256, 256) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[_window setFrameAutosaveName:@"mainWindow"];
	[_window setHasShadow:NO];
	[_window setAlphaValue:1.0];
	[_window setBackgroundColor:[NSColor clearColor]];
	[_window setOpaque:NO];
	[_window setDelegate:self];
	[_window setMovableByWindowBackground:YES];
	[_window setLevel:kCGDesktopWindowLevel];
	[_window setContentView:[[[ApplicationView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)] autorelease]];
	[_window setContentSize:NSMakeSize((CGFloat)[defaults integerForKey:kUserDefaultKey_RenderWidth], (CGFloat)[defaults integerForKey:kUserDefaultKey_RenderHeight])];
	
	/* Create and configure OpenGL context */
	_glFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
	_glContext = [[NSOpenGLContext alloc] initWithFormat:_glFormat shareContext:nil];
	if(_glContext == nil) {
		NSLog(@"Failed creating OpenGL context");
		[NSApp terminate:nil];
	}
	value = 1;
	[_glContext setValues:&value forParameter:NSOpenGLCPSwapInterval];
	value = 0;
	[_glContext setValues:&value forParameter:NSOpenGLCPSurfaceOpacity];
	
	/* Show main window and attach OpenGL context */
	[_window makeKeyAndOrderFront:nil];
	[_glContext setView:[_window contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewGlobalFrameDidChange:) name:NSViewGlobalFrameDidChangeNotification object:[_window contentView]];
	
	/* Create QCRenderer from selected composition file or fail to default composition file on error */
	if(path = [defaults objectForKey:kUserDefaultKey_CompositionPath]) {
		_renderer = [[QCRenderer alloc] initWithOpenGLContext:_glContext pixelFormat:_glFormat file:path];
		[_renderer setInputValuesWithPropertyList:[defaults objectForKey:kUserDefaultKey_CompositionParameters]];
	}
	if(_renderer == nil)
	_renderer = [[QCRenderer alloc] initWithOpenGLContext:_glContext pixelFormat:_glFormat file:[[NSBundle mainBundle] pathForResource:@"Default Composition" ofType:@"qtz"]];
	if(_renderer == nil) {
		[NSApp terminate:nil];
		NSLog(@"Failed creating QCRenderer");
	}
	_hasURLPort = ([[_renderer outputKeys] containsObject:kOpenURLPortKey] && [[[[_renderer attributes] objectForKey:kOpenURLPortKey] objectForKey:QCPortAttributeTypeKey] isEqualToString:QCPortTypeString]);
	[parametersView setCompositionRenderer:_renderer];
	
	/* Render a frame immediately */
	[self _renderWithArguments:nil];
	
	/* Create rendering timer */
	_timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)[defaults integerForKey:kUserDefaultKey_RenderPeriod] target:self selector:@selector(_renderTimer:) userInfo:nil repeats:YES] retain];
}

@end

@implementation Application (Actions)

- (IBAction) selectComposition:(id)sender
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	NSOpenPanel*						openPanel = [NSOpenPanel openPanel];
	QCRenderer*							renderer;
	
	/* Allow user to select a composition file and create a QCRenderer from it */
	if([openPanel runModalForTypes:[NSArray arrayWithObject:@"qtz"]] == NSFileHandlingPanelOKButton) {
		if((renderer = [[QCRenderer alloc] initWithOpenGLContext:_glContext pixelFormat:_glFormat file:[openPanel filename]])) {
			/* Replace current QCRenderer with new one */
			[_renderer release];
			_renderer = renderer;
			_hasURLPort = ([[_renderer outputKeys] containsObject:kOpenURLPortKey] && [[[[_renderer attributes] objectForKey:kOpenURLPortKey] objectForKey:QCPortAttributeTypeKey] isEqualToString:QCPortTypeString]);
			[parametersView setCompositionRenderer:_renderer];
			
			/* Update defaults */
			[defaults setObject:[openPanel filename] forKey:kUserDefaultKey_CompositionPath];
			[defaults removeObjectForKey:kUserDefaultKey_CompositionParameters];
			
			/* Re-render immediately */
			_startTime = 0.0;
			[self _renderWithArguments:nil];
		}
		else
		NSBeep();
	}
}

- (void) _parametersSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	
	/* Dismiss parameters window */
	[sheet orderOut:nil];
	
	/* Save parameters to defaults */
	[defaults setObject:[_renderer propertyListFromInputValues] forKey:kUserDefaultKey_CompositionParameters];
	
	/* Re-render immediately */
	[self _renderWithArguments:nil];
}

- (IBAction) setParameters:(id)sender
{
	/* Show or hide parameters window sheet */
	if([sender isKindOfClass:[NSMenuItem class]])
	[NSApp beginSheet:parametersWindow modalForWindow:_window modalDelegate:self didEndSelector:@selector(_parametersSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	else
	[NSApp endSheet:parametersWindow];
}

- (void) _dimensionsSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	/* Dismiss dimensions window */
	[sheet orderOut:nil];
}

- (IBAction) updateDimensions:(id)sender
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	NSRect								frame = [_window frame];
	
	/* Update main window dimensions */
	[_window setFrame:NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height - (CGFloat)[defaults integerForKey:kUserDefaultKey_RenderHeight], (CGFloat)[defaults integerForKey:kUserDefaultKey_RenderWidth], (CGFloat)[defaults integerForKey:kUserDefaultKey_RenderHeight]) display:YES animate:NO];
	
	/* Force update as NSViewGlobalFrameDidChangeNotification is not always posted */
	[self _viewGlobalFrameDidChange:nil];
}

- (IBAction) setDimensions:(id)sender
{
	/* Show or hide dimensions window sheet */
	if([sender isKindOfClass:[NSMenuItem class]])
	[NSApp beginSheet:dimensionsWindow modalForWindow:_window modalDelegate:self didEndSelector:@selector(_dimensionsSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	else
	[NSApp endSheet:dimensionsWindow];
}

- (IBAction) setRefreshFrequency:(id)sender
{
	NSUserDefaults*						defaults = [NSUserDefaults standardUserDefaults];
	
	/* Update rendering period */
	[defaults setInteger:[(NSMenuItem*)sender tag] forKey:kUserDefaultKey_RenderPeriod];
	
	/* Reset rendering timer */
	[_timer invalidate];
	[_timer release];
	_timer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)[defaults integerForKey:kUserDefaultKey_RenderPeriod] target:self selector:@selector(_renderTimer:) userInfo:nil repeats:YES] retain];
	
	/* Re-render immediately */
	[self _renderWithArguments:nil];
}

@end
