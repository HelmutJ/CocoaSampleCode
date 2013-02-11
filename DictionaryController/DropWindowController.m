/*
     File: DropWindowController.m 
 Abstract: This sample's secondary NSWindowController for dropping file objects to. 
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "DropWindowController.h"
#import "DropView.h"

@implementation DropWindowController

@synthesize fileAttrs;

// -------------------------------------------------------------------------------
//	dropHasOcurred:notif
// -------------------------------------------------------------------------------
- (void)dropHasOcurred:(NSNotification *)notif
{
	self.fileAttrs = [[notif userInfo] objectForKey:@"info"];	// this will send both will/did change KVO notifications
	
	// get the file attributes to be used in our dictionary
	NSFileWrapper *fileWrapper = [[[NSFileWrapper alloc] initWithPath: [[notif userInfo] objectForKey:@"path"]] autorelease];
		
	// set the icon and name for the view
	NSImage* theIcon = [fileWrapper icon];
	if (theIcon == nil)
	{
		// it's possible NSFileWrapper might not give us the icon (i.e. volumes), to ask NSWorkspace
		theIcon = [[NSWorkspace sharedWorkspace] iconForFile:[[notif userInfo] objectForKey:@"path"]];
	}
	[icon setImage:theIcon];	
	[name setStringValue: [[[notif userInfo] objectForKey:@"path"] lastPathComponent]];
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
    self.fileAttrs = nil;	// causes a release
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// here we exclude the key-value pair for "NSFileExtendedAttributes" from the controller
	// since it is also a dictionary.  Note: to be explicit we are showing this in code rather than in IB.
	//
	[dictController setExcludedKeys:[NSArray arrayWithObjects:@"NSFileExtendedAttributes", nil]];
	
	// bind the "fileAttrs" dictionary to our dictionary controller
	[dictController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"fileAttrs" options:nil];
	// another way without bindings is:
	// [dictController setContent:entry];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropHasOcurred:) name:DropHasOccurred object:nil];
}

@end
