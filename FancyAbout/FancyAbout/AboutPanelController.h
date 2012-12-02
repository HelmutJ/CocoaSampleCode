/*
     File: AboutPanelController.h
 Abstract: Controller for the about window.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <AppKit/AppKit.h>
#import "NSFancyPanel.h"
@class ScrollingTextView;


@interface AboutPanelController : NSObject <NSWindowDelegate, NSFancyPanelController>
{
    // This panel exists in the nib file, but the user never sees it, because
    // we rip out its contents and place them in “panelToDisplay”.
    IBOutlet NSPanel			*panelInNib;

    // This panel is not in the nib file; we create it programmatically.
    NSPanel						*panelToDisplay;

    // Scrolling text: the scroll-view and the text-view itself
    IBOutlet NSScrollView		*textScrollView;
    IBOutlet NSTextView			*textView;

    // Outlet we fill in using information from the application’s bundle
    IBOutlet NSTextField		*versionField;
    IBOutlet NSTextField		*shortInfoField;

    // Timer to fire scrolling animation
    NSTimer						*scrollingTimer;
}


#pragma mark PUBLIC CLASS METHODS

+ (AboutPanelController *)sharedInstance;


#pragma mark PUBLIC INSTANCE METHODS

//	Show the panel, starting the text at the top with the animation going
- (void)showPanel;

//	Stop scrolling and hide the panel.
- (void)hidePanel;

//	This method exists only because this is a developer example.
//	You wouldn’t want it in a real application.
- (void)setShowsScroller:(BOOL)newSetting;

@end

