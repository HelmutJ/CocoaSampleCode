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

@implementation AppView

- (id) initWithCoder:(NSCoder*)decoder
{
	/* Register for drag & drop */
	if(self = [super initWithCoder:decoder])
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	return self;
}

- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender
{
	NSPasteboard*				pasteboard = [sender draggingPasteboard];
	CGImageSourceRef			sourceRef;
	
	/* Check if the dragged file is valid by creating an ImageIO source with it */
	if([[pasteboard types] containsObject:NSFilenamesPboardType]) {
		if(_sourceRef = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[pasteboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0]], NULL))
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (void) draggingExited:(id<NSDraggingInfo>)sender
{
	/* Destroy ImageIO source */
	if(_sourceRef) {
		CFRelease(_sourceRef);
		_sourceRef = NULL;
	}
}

- (BOOL) performDragOperation:(id<NSDraggingInfo>)sender
{
	CGImageRef					imageRef;
	
	/* Create the image from the dragged file and update our application controller */
	if(_sourceRef) {
		if(imageRef = CGImageSourceCreateImageAtIndex(_sourceRef, 0, NULL)) {
			[(AppController*)[NSApp delegate] setSourceImage:imageRef];
			CGImageRelease(imageRef);
		}
		CFRelease(_sourceRef);
		_sourceRef = NULL;
		return (imageRef ? YES : NO);
	}
	
	return NO;
}

- (void) mouseDown:(NSEvent*)event
{
	NSPoint						point = [self convertPoint:[event locationInWindow] fromView:nil];
	
	/* Start drag & drop */
	if([self loadedComposition])
	[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"png"] fromRect:NSMakeRect(point.x - 16, point.y - 16, 32, 32) source:self slideBack:YES event:event];
}

- (NSArray*) namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination
{
	unsigned					index = 0;
	NSArray*					array = nil;
	CGImageRef					imageRef;
	CGImageDestinationRef		destinationRef;
	NSString*					name;
	
	/* Make sure we are dragging to a file */
	if(![dropDestination isFileURL])
	return nil;
	
	/* Get the resized image from our application controller */
	imageRef = [(AppController*)[NSApp delegate] getResizedImage];
	if(imageRef == NULL)
	return nil;
	
	/* Generate a unique file name */
	do {
		index += 1;
		name = [NSString stringWithFormat:@"Image-%i.png", index];
	} while([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL URLWithString:name relativeToURL:dropDestination] path]]);
	
	/* Save the CGImageRef as a PNG file using ImageIO */
	if(destinationRef = CGImageDestinationCreateWithURL((CFURLRef)[NSURL URLWithString:name relativeToURL:dropDestination], kUTTypePNG, 1, NULL)) {
		CGImageDestinationAddImage(destinationRef, imageRef, NULL);
		if(CGImageDestinationFinalize(destinationRef))
		array = [NSArray arrayWithObject:name];
		CFRelease(destinationRef);
	}
	
	return array;
}

@end

@implementation AppController

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
	/* Load the preview composition on the QCView */
	[qcView loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"Composition" ofType:@"qtz"]];
	[qcView startRendering];
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
	/* Clean up */
	if(_imageRef)
	CGImageRelease(_imageRef);
	if(_renderer)
	[_renderer release];
}

- (void) windowWillClose:(NSNotification*)notification
{
	/* Terminate the application */
	[NSApp terminate:self];
}

- (BOOL) compositionParameterView:(QCCompositionParameterView*)parameterView shouldDisplayParameterWithKey:(NSString*)portKey attributes:(NSDictionary*)portAttributes
{
	/* Make sure the input image parameter is not visible as we are setting it directly */
	return ![portKey isEqualToString:QCCompositionInputImageKey];
}

- (void) compositionParameterView:(QCCompositionParameterView*)parameterView didChangeParameterWithKey:(NSString*)portKey
{
	/* Since one of the parameter has changed, we need to re-renderer the QCRenderer */
	if(![_renderer renderAtTime:0.0 arguments:nil])
	NSLog(@"QCRenderer failed rendering");
	
	/* Forward the image produced by the QCRenderer to the preview composition on the QCView */
	[qcView setValue:[_renderer valueForOutputKey:QCCompositionOutputImageKey ofType:@"QCImage"] forInputKey:@"inImage"];
}

- (void) setSourceImage:(CGImageRef)imageRef
{
	static CGColorSpaceRef				deviceRGBColorSpace = NULL;
	QCComposition*						composition = [[QCCompositionRepository sharedCompositionRepository] compositionWithIdentifier:@"/image resizer"];
	CGColorSpaceRef						colorSpace;
	
	/* Keep around DeviceRGB colorspace */
	if(deviceRGBColorSpace == NULL)
	deviceRGBColorSpace = CGColorSpaceCreateDeviceRGB();
	
	/* Replace our current image with the new one and re-create the QCRenderer */
	if(imageRef != _imageRef) {
		CGImageRelease(_imageRef);
		_imageRef = CGImageRetain(imageRef);
		
		/* Compute colorspace to use for the QCRenderer (use the one from the source image if possible - Quartz Composer cannot render in gray or device colorspaces) */
		colorSpace = CGImageGetColorSpace(imageRef);
		if((CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) || CFEqual(colorSpace, deviceRGBColorSpace))
		colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		else
		colorSpace = CGColorSpaceRetain(colorSpace);
		
		/* Re-create QCRenderer and set source image */
		[_renderer release];
		_renderer = [[QCRenderer alloc] initWithComposition:composition colorSpace:colorSpace];
		[_renderer setValue:(id)_imageRef forInputKey:QCCompositionInputImageKey];
		[paramView setCompositionRenderer:_renderer];
		
		/* We don't need the colorspace anymore */
		CGColorSpaceRelease(colorSpace);
		
		/* Force-update the preview composition in the QCView */
		[self compositionParameterView:nil didChangeParameterWithKey:nil];
	}
}

- (CGImageRef) getResizedImage
{
	return (CGImageRef)[_renderer valueForOutputKey:QCCompositionOutputImageKey ofType:@"CGImage"];
}

@end
