/*
	    File: AppController.m
	Abstract: View and Controller classes.
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

#import "AppController.h"

@implementation RenderView

- (void) mouseDown:(NSEvent*)event
{
	/* If there is a option-click, edit report location field */
	if([event modifierFlags] & NSAlternateKeyMask)
	[(AppController*)[NSApp delegate] editLocation];
	else
	[super mouseDown:event];
}

- (BOOL) renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
	BOOL			success = [super renderAtTime:time arguments:arguments];
	
	/* Set window to report name */
	if(success)
	[[self window] setTitle:[self valueForOutputKey:@"reportName"]];
	
	return success;
}

@end

@implementation AppController

- (void) applicationWillFinishLaunching:(NSNotification*)notification
{
	NSString*		path = [[NSBundle mainBundle] pathForResource:@"Composition" ofType:@"qtz"];
	
	/* Put panel just above Desktop */
	[mainPanel setLevel:kCGDesktopWindowLevel + 1];
	
	/* Load composition */
	path = [[NSBundle mainBundle] pathForResource:@"Composition" ofType:@"qtz"];
	if((path == nil) || ![renderView loadCompositionFromFile:path])
	[NSApp terminate:nil];
	
	/* Configure composition to use default report URL */
	path = [[NSBundle mainBundle] pathForResource:@"Report" ofType:@"xml"];
	if(path == nil)
	[NSApp terminate:nil];
	path = [[NSURL fileURLWithPath:path] absoluteString];
	[renderView setValue:path forInputKey:@"reportURL"];
	
	/* Make sure QCView only renders at most once per minute */
	[renderView setMaxRenderingFrameRate:(1.0 / 60.0)];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
	/* Show panel */
	[mainPanel makeKeyAndOrderFront:nil];
	
	/* Start rendering */
	[renderView startRendering];
}

- (void) editLocation
{
	/* Update location text field */
	[locationField setStringValue:[renderView valueForInputKey:@"reportURL"]];
	
	/* Show location text field */
	[renderView setHidden:YES];
	[locationField setHidden:NO];
}

- (IBAction) updateLocation:(id)sender
{
	NSString*				location = [locationField stringValue];
	NSURL*					url = nil;
	
	/* Convert specified location to an URL */
	if([location length]) {
		if([location characterAtIndex:0] == '/')
		url = [NSURL fileURLWithPath:location];
		else
		url = [NSURL URLWithString:location];
	}
	
	/* Update composition report URL if applicable */
	if(url)
	[renderView setValue:[url absoluteString] forInputKey:@"reportURL"];
	
	/* Hide location text field */
	[locationField setHidden:YES];
	[renderView setHidden:NO];
}

- (void) windowWillClose:(NSNotification*)notification
{
	/* Quit application */
	[NSApp terminate:nil];
}

@end
