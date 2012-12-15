/*
     File: MyWindowController.m 
 Abstract: The sample's main NSWindowController.
  
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"
#import "ExtraAlertView.h"

@implementation MyWindowController

// this is an anchor value into our help book - found in "page-b.html",
// which will tell Apple Help to automatically go to this page when opening the help book
//
NSString *const kHelpAnchor	= @"anchor-two";    

// -------------------------------------------------------------------------------
//	initWithPath:newPath
// -------------------------------------------------------------------------------
- (id)initWithPath:(NSString *)newPath
{
#pragma unused (newPath)
	return [super initWithWindowNibName:@"TestWindow"];	
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// set our default values for our custom strings
	[self setValue:NSLocalizedString(@"Yes_Key", nil) forKey:@"defaultButtonTitle"];
	[self setValue:NSLocalizedString(@"No_Key", nil) forKey:@"secondButtonTitle"];
	[self setValue:NSLocalizedString(@"Custom_Key", nil) forKey:@"alternateButtonTitle"];
	[self setValue:NSLocalizedString(@"Msg_Key", nil) forKey:@"messageTitle"];
	[self setValue:NSLocalizedString(@"InformMsg_Key", nil) forKey:@"informativeTitle"];
}

// -------------------------------------------------------------------------------
//	handleResult:withResult
//
//	Used to handle the result for both sheet and modal alert cases.
// -------------------------------------------------------------------------------
-(void)handleResult:(NSAlert *)alert withResult:(NSInteger)result
{
	// report which button was clicked
	switch(result)
	{
		case NSAlertDefaultReturn:
			NSLog(@"result: NSAlertDefaultReturn");
			break;
		
		case NSAlertAlternateReturn:
			NSLog(@"result: NSAlertAlternateReturn");
			break;
		
		case NSAlertOtherReturn:
			NSLog(@"result: NSAlertOtherReturn");
			break;
            
        default:
            break;
	}
	
	// suppression button only exists in 10.5 and later
    if ([alert showsSuppressionButton])
    {
        if ([[[alert suppressionButton] cell] state])
            NSLog(@"suppress alert: YES");
        else
            NSLog(@"suppress alert: NO");
    }
}

// -------------------------------------------------------------------------------
//	alertDidEnd:returnCode:contextInfo
//
//	This method is called only when a the sheet version of this alert is dismissed.
// -------------------------------------------------------------------------------
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (contextInfo)
	[[alert window] orderOut:self];
	[self handleResult:alert withResult:returnCode];
}

// -------------------------------------------------------------------------------
//	alertShowHelp
//
//	The delegate method for displaying alert help.
// -------------------------------------------------------------------------------
- (BOOL)alertShowHelp:(NSAlert *)alert
{
	// get the localized name of our help book
    //
    // to make this work, the help book name needs to be defined in your InfoPlist.strings
    // file with an entry for "CFBundleHelpBookName"
    //
    NSString *helpBookName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleHelpBookName"];
    
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[alert helpAnchor] inBook:helpBookName];
    
	return YES;
}

// -------------------------------------------------------------------------------
//	testAction:
//
//	The user clicked the "Test" button from the accessory view.
// -------------------------------------------------------------------------------
- (IBAction)testAction:(id)sender
{
#pragma unused (sender)
	NSLog(@"Test button was clicked.");
}

// -------------------------------------------------------------------------------
//	openAlert:
//
//	The user clicked the "Open…" button.
// -------------------------------------------------------------------------------
- (IBAction)openAlert:(id)sender
{
#pragma unused (sender)
	NSString *useSecondButtonStr = nil;
	if (useSecondButtonState)		// use the second button, but only if checkbox is checked
		useSecondButtonStr = secondButtonTitle;
	
	NSString *useAlternateButtonStr = nil;
	if (useAlternateButtonState)	// use the alternate (third) button, but only if checkbox is checked
		useAlternateButtonStr = alternateButtonTitle;
	
	NSAlert *testAlert = [NSAlert alertWithMessageText:messageTitle
                                         defaultButton:defaultButtonTitle
                                       alternateButton:useAlternateButtonStr
                                           otherButton:useSecondButtonStr
                             informativeTextWithFormat:@"%@", informativeTitle];

	// use the popup's selection's tag to determine which alert style we want
	[testAlert setAlertStyle:[[popupStyle selectedCell] tag]];
	
	if (useCustomIcon)
	{
		NSImage* image = [NSImage imageNamed:@"moof.icns"];
		[testAlert setIcon: image];
	}
	
	// determine if we should use the help button
	[testAlert setShowsHelp:useHelpButtonState];
	if (useHelpButtonState)
		[testAlert setHelpAnchor:kHelpAnchor];	// use this anchor as a direction point to our help book
	
	[testAlert setDelegate:(id<NSAlertDelegate>)self];	// this allows "alertShowHelp" to be called when the user clicks the help button

	// note: accessoryView and suppression checkbox are available in 10.5 on up
    [testAlert setShowsSuppressionButton:useSuppressionState];
    [[testAlert suppressionButton] setTitle:suppressionButtonTitle];
    
    // use a custom accessory view?
    if (useAccessoryViewState)
        [testAlert setAccessoryView:accessoryView];

	if (openAsSheetState)	// sheet or modal alert?
	{
		[testAlert beginSheetModalForWindow:[self window]
                              modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:nil];
	}
	else
	{
		NSInteger result = [testAlert runModal];
		[self handleResult:testAlert withResult:result];
	}
}

@end
