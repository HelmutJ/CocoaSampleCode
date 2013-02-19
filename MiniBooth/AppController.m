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

/* We override this method to know whenever the composition is rendered in the QCView */
- (BOOL) renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
	id										image;
	
	/* Call super so that rendering happens */
	if(![super renderAtTime:time arguments:arguments])
	return NO;
	
	/* Retrieve the current video input image from the "videoImage" output of the composition then use it as a default image for the Composition Picker panel
		Because we pass the image from one Quartz Composer object to another one, we can use the optimized QCImage type
	*/
	if(image = [self valueForOutputKey:@"videoImage" ofType:@"QCImage"])
	[[[QCCompositionPickerPanel sharedCompositionPickerPanel] compositionPickerView] setDefaultValue:image forInputKey:QCCompositionInputImageKey];
	
	return YES;
}

@end

@implementation AppController

- (void) _didSelectComposition:(NSNotification*)notification
{
	QCComposition*						composition = [[notification userInfo] objectForKey:@"QCComposition"];
	
	/* Set the identifier of the selected composition on the "compositionIdentifier" input of the composition,
		which passes it in turn to a Composition Loader patch which loads the composition and applies it to the video input */
	[qcView setValue:[composition identifier] forInputKey:@"compositionIdentifier"];
}

- (void) applicationDidFinishLaunching:(NSNotification*)notification
{
	QCCompositionPickerPanel*				pickerPanel = [QCCompositionPickerPanel sharedCompositionPickerPanel];
	
	/* Load our composition file on the QCView and start rendering */
	if(![qcView loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"Composition" ofType:@"qtz"]])
	[NSApp terminate:nil];
	[qcView startRendering];
	
	/* Configure and show the Composition Picker panel */
	[[pickerPanel compositionPickerView] setAllowsEmptySelection:YES];
	[[pickerPanel compositionPickerView] setShowsCompositionNames:YES];
	[[pickerPanel compositionPickerView] setCompositionsFromRepositoryWithProtocol:QCCompositionProtocolImageFilter andAttributes:nil];
	[pickerPanel orderFront:nil];
	
	/* Register for composition picker panel notifications */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSelectComposition:) name:QCCompositionPickerPanelDidSelectCompositionNotification object:nil];
}

- (void) applicationWillTerminate:(NSNotification*)notification
{
	/* Unregister from composition picker panel notifications */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QCCompositionPickerPanelDidSelectCompositionNotification object:nil];
}

- (void) windowWillClose:(NSNotification*)notification
{
	[NSApp terminate:self];
}

- (IBAction) toggleCompositionPicker:(id)sender
{
	QCCompositionPickerPanel*				pickerPanel = [QCCompositionPickerPanel sharedCompositionPickerPanel];
	
	/* Toggle the Composition Picker panel visibility */
	if([pickerPanel isVisible])
	[pickerPanel orderOut:sender];
	else
	[pickerPanel orderFront:sender];
}

- (IBAction) savePNG:(id)sender
{
	NSSavePanel*							savePanel = [NSSavePanel savePanel];
	CGImageRef								imageRef;
	CGImageDestinationRef					destinationRef;
	
	/* Display the save panel */
	[savePanel setRequiredFileType:@"png"];
	if([savePanel runModalForDirectory:nil file:@"My Picture"] == NSFileHandlingPanelOKButton) {
		/* Grab the current contents of the QCView as a CGImageRef and use ImageIO to save it as a PNG file */
		if(imageRef = (CGImageRef)[qcView createSnapshotImageOfType:@"CGImage"]) {
			if(destinationRef = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[savePanel filename]], kUTTypePNG, 1, NULL)) {
				CGImageDestinationAddImage(destinationRef, imageRef, NULL);
				if(!CGImageDestinationFinalize(destinationRef))
				NSBeep();
				CFRelease(destinationRef);
			}
			else
			NSBeep();
			CGImageRelease(imageRef);
		}
		else
		NSBeep();
	} 
}

@end
