/*
    File: Controller.m
Abstract: Handles all UI interaction and code for saving the image.
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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

#import "Controller.h"
#import "DataProvider.h"

@interface Controller()
-(bool)userCanceled;
-(void)progress:(float)percent;
-(void)updateProgress;
-(void)startSaveUI;
-(void)endSaveUI;
@end

@implementation Controller

static NSString *kWidthKey = @"width";
static NSString *kHeightKey = @"height";
static NSString *kLocationKey = @"location";

// Callback for our custom data provider in order to provide progress for UI.
static void MyProgressCallback(void *context, float percentProgress)
{
	[(Controller*)context progress:percentProgress];
}

// Callback for our custom data provider to determine if we should stop providing data in order to implement cancel
static bool MyCancelCallback(void *context)
{
	return [(Controller*)context userCanceled];
}

-(void)saveTo:(NSDictionary*)info;
{
	// Since we are being spun off into a thread, we need our own auto-release pool
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// Signal that we are ready to start so that our progress sheet is displayed
	[self performSelectorOnMainThread:@selector(startSaveUI) withObject:nil waitUntilDone:YES];	

	// Collect the size and save location for the image in question
	size_t w = [[info objectForKey:kWidthKey] intValue];
	size_t h = [[info objectForKey:kHeightKey] intValue];
	NSURL *location = [info objectForKey:kLocationKey];
	
	// Create a generic rgb color space
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

	// Setup our data provider
	CGDataProviderRef provider = CreateDataProvider(w, h, self, MyProgressCallback, MyCancelCallback);

	// Create the image with our data provider and color space - it will retain both so we will release them both after
	CGImageRef image = CGImageCreate(
		w, h, // width & height
		kBitsPerComponent, kBitsPerPixel, // bits per component, bits per pixel
		w * kBytesPerPixel, // bytes per row
		colorSpace, // color space
		kImageFlags, // format (XRGB) (see DataProvider.h)
		provider, // data provider
		NULL, // color decode array
		true, // allow interpolation
		kCGRenderingIntentDefault); // default rendering intent
	CFRelease(colorSpace);
	CFRelease(provider);
	
	// Create a URL to our file destination and a CGImageDestination to save to.
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((CFURLRef)location, kUTTypeJPEG, 1, NULL);
	
	// Add the image created above
	CGImageDestinationAddImage(imageDestination, image, NULL);
	
	// Finalize the image destination, which will write the image data to disk.
	success = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	CFRelease(image);
	
	// Finally, signal that we are done so that the UI becomes active again.
	[self performSelectorOnMainThread:@selector(endSaveUI) withObject:nil waitUntilDone:YES];	
	
	// Clean out our auto release pool.
	[pool drain];
}

-(IBAction)save:(id)sender
{
	#pragma unused(sender)
	// Clear the message just to avoid confusion.
	[messageText setStringValue:@""];
	
	// Verify the image width & height. Appkit's NSNumberFormatter
	// will complain about out of range, but won't actually clip the range
	// We just clip the range here and push it back out to the UI.
	// Since JPEG doesn't seem to support images larger than 65500 per side, that is our new limit.
	int w = [width intValue], h = [height intValue];
	if((w < 1) || (w > 65500) || (h < 1) || (h > 65500))
	{
		[messageText setStringValue:[NSString stringWithFormat:@"%i x %i is too big", w, h]];
	}
	else
	{
		// Configure and start a save panel to save the image
		// If the panel is successful then saveImageDidEnd:returnCode:contextInfo
		// will complete the transaction.
		NSSavePanel * panel = [NSSavePanel savePanel];
		[panel setCanSelectHiddenExtension:YES];
		[panel setRequiredFileType:@"jpg"];
		[panel setAllowsOtherFileTypes:NO];
		
		[panel
			beginSheetForDirectory:nil
			file:@"Test Image"
			modalForWindow:[self window]
			modalDelegate:self
			didEndSelector:@selector(saveImageDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
	}
}

-(void)saveImageDidEnd:(NSSavePanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	#pragma unused(contextInfo)
	// If the user elected to save, then do so.
	if(returnCode == NSOKButton)
	{
		// Fill out the information needed to save
		NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[width objectValue], kWidthKey, [height objectValue], kHeightKey, [panel URL], kLocationKey, nil];
		// And dispatch the operation to a background thread to avoid locking up the UI.
		// detachNewThreadSelector:toTarget:withObject: will retain it's parameters so we don't have to.
		// Equivalent to [self saveTo:info]
		[NSThread detachNewThreadSelector:@selector(saveTo:) toTarget:self withObject:info];
	}
}

-(IBAction)cancel:(id)sender
{
	#pragma unused(sender)
	// Set the cancel flag - this will be picked up later in the Data Provider.
	cancel = true;
}

-(bool)userCanceled
{
	// Return the cancel flag's current state.
	return cancel;
}

-(void)progress:(float)percent
{
	// Only update the progress bar if the new value is significantly different
	// from the old value. Here we define significant as 1%
	if(percent > lastProgressUpdate + 1.0f)
	{
		// Remeber the new significant percentage...
		lastProgressUpdate = percent;
		// And call back to the main thread to update the progress bar
		// (this is called within our provider on the background thread)
		[self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:NO];
	}
}

-(void)updateProgress
{
	[progress setDoubleValue:lastProgressUpdate];
}

-(void)startSaveUI
{
	// Reset UI variables for this run
	lastProgressUpdate = 0.0;
	cancel = false;
	[progress setDoubleValue:0.0];
	// Begin our progress sheet.
	[NSApp beginSheet:sheetWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(void)endSaveUI
{
	// End the progress sheet.
	[NSApp endSheet:sheetWindow];
	// Send it on it's merry way.
	[sheetWindow orderOut:self];
	// Provide some feedback to the user about what just happened.
	if(success)
	{
		[messageText setStringValue:@"Save succeeded."];
	}
	else if(cancel)
	{
		[messageText setStringValue:@"Save canceled by user."];
	}
	else
	{
		[messageText setStringValue:@"Save failed."];
	}
}

@end
