/*
     File: MyDocument.m
 Abstract: MyDocument class.
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

#import "MyDocument.h"

@implementation MyDocument

- (void) dealloc
{
	/* Unregister from composition picker panel notifications */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QCCompositionPickerPanelDidSelectCompositionNotification object:nil];
	
	[super dealloc];
}

- (NSString*) windowNibName
{
	return @"MyDocument";
}

- (void) windowControllerDidLoadNib:(NSWindowController*)aController
{
	QCCompositionPickerPanel*					panel = [QCCompositionPickerPanel sharedCompositionPickerPanel];
	NSView*										contentView = [[aController window] contentView];
	
	[super windowControllerDidLoadNib:aController];
    
	/* Make the text view and its scrollview transparent */
	[textView setDrawsBackground:NO];
	[scrollView setDrawsBackground:NO];
	
	/* Load the RTF data in the text view if available or use some default text */
	if(_rtfData) {
		[textView replaceCharactersInRange:NSMakeRange(0, 0) withRTF:_rtfData];
		[_rtfData release];
	}
	else {
		[textView replaceCharactersInRange:NSMakeRange(0, 0) withString:@"Type some text here or select a composition in the picker..."];
		[textView setTextColor:[NSColor whiteColor]];
		[textView setFont:[NSFont systemFontOfSize:24]];
		[textView setSelectedRange:NSMakeRange(0, [[textView textStorage] length])];
	}
	
	/* Configure and show the composition picker panel - only the first time this method is ran */
	if(![[[panel compositionPickerView] compositions] count]) {
		[[panel compositionPickerView] setCompositionsFromRepositoryWithProtocol:QCCompositionProtocolGraphicAnimation andAttributes:nil];
		[panel orderFront:nil];
	}
	
	/* Register for composition picker panel notifications */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSelectComposition:) name:QCCompositionPickerPanelDidSelectCompositionNotification object:nil];
	
	/* Set up Core Animation */
	[contentView setLayer:[QCCompositionLayer compositionLayerWithComposition:[[panel compositionPickerView] selectedComposition]]];
	[contentView setWantsLayer:YES];
}

- (NSData*) dataRepresentationOfType:(NSString *)aType
{
	/* Return the text view contents as RTF data */
	return [[textView textStorage] RTFFromRange:NSMakeRange(0, [[textView textStorage] length]) documentAttributes:nil];
}

- (BOOL) loadDataRepresentation:(NSData*)data ofType:(NSString*)aType
{
	/* Save RTF data for -windowControllerDidLoadNib: */
	_rtfData = [data copy];
	
	return YES;
}

- (void) _didSelectComposition:(NSNotification*)notification
{
	QCComposition*						composition = [[notification userInfo] objectForKey:@"QCComposition"];
	NSWindow*							window = [[[self windowControllers] objectAtIndex:0] window];
	
	/* Replace the content view of the window with a Quartz Composer layer with the selected composition */
	[[window contentView] setLayer:[QCCompositionLayer compositionLayerWithComposition:composition]];
}

@end

@implementation MyDocument (FirstResponderActions)

- (IBAction) orderFrontFontPanel:(id)sender
{
	[[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}

- (IBAction) orderFrontCompositionPanel:(id)sender
{
	[[QCCompositionPickerPanel sharedCompositionPickerPanel] orderFront:sender];
}

@end
