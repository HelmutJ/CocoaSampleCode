/*
	    File: ImageInfo.m
	Abstract: ImageInfo class.
	 Version: 1.0
	
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

#import "ImageInfo.h"

#define	kQCPlugIn_Name				@"Image Information"
#define	kQCPlugIn_Description		@"Show image in setting pane"

@interface ImageInfo (Internal)

- (void) _releasedUnusedControllers;
- (void) _setImageForControllers:(id<QCPlugInInputImageSource>) image;

@end

@implementation ImageInfo

@dynamic inputImage;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a consumer */
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method). Only needs to be executed when input image changes */
	return kQCPlugInTimeModeNone;
}

- (id) init
{
	/* When plug-in is initialized. Initialized our array that will keep track or active plug-in controllers */
	if (self = [super init])
		_plugInControllers = [NSMutableArray new];
		
	return self;
}

- (void) dealloc
{
	/* Release plug-in controller array at dealloc */
	[_plugInControllers release];
	[super dealloc];
}

- (QCPlugInViewController*) createViewController
{
	QCPlugInViewController*			controller;

	/* Create plug-in controller and keep it around */
	controller = [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"ImageInfoUI"];

	/* In the case of when the setting pane is showed but image does not change, execute won't be called 
	   We then need to set the image manually on the QCView */
	[(QCView*)[[[controller view] subviews] objectAtIndex:0] setValue:_image forInputKey:@"Image"];
	
	[_plugInControllers addObject:controller];
	
	return controller;
}

@end

@implementation ImageInfo (Internal)

/* Release unused plug-in controllers */
- (void) _releasedUnusedControllers
{
	NSInteger		i;
	
	for (i=[_plugInControllers count]-1; i>=0; --i) {
		if ([[_plugInControllers objectAtIndex:i] retainCount] == 1)
			[_plugInControllers removeObjectAtIndex:i];
	}
}

/* Sets all plug-in controller to the given image */
- (void) _setImageForControllers:(id<QCPlugInInputImageSource>) image
{
	NSUInteger		i;

	for (i=0; i<[_plugInControllers count]; ++i)
		[(QCView*)[[[[_plugInControllers objectAtIndex:i] view] subviews] objectAtIndex:0] setValue:self.inputImage forInputKey:@"Image"];
}

@end

@implementation ImageInfo (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/* Release unused plug-in controllers */
	if ([_plugInControllers count])
		[self _releasedUnusedControllers];
	
	/* Sets current input image on all controllers */
	if ([_plugInControllers count])
		[self _setImageForControllers:self.inputImage];
	
	/* Keep a reference to the image in the case a setting pane is showed later */
	if (_image != self.inputImage) {
		[(id)_image release];
		_image = [(id)self.inputImage retain];
	}
	/* Otherwise, this plug-in does nothing */
	
	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context;
{
	/* Release unused plug-in controllers */
	[self _releasedUnusedControllers];
}

- (void) stopExecution:(id<QCPlugInContext>)context;
{
	/* Release unused plug-in controllers */
	[self _releasedUnusedControllers];
}

@end