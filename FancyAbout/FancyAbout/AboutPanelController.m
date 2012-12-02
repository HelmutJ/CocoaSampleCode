/*
     File: AboutPanelController.m 
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


#import "AboutPanelController.h"


//	Another approach would be to allow changing these through NSUserDefaults
#define	SCROLL_DELAY_SECONDS	0.03	// time between animation frames
#define SCROLL_AMOUNT_PIXELS	1.00	// amount to scroll in each animation frame

//	We pad this many blank lines at the end of the text, so the visible part
//	of the text can scroll out of sight.
#define	BLANK_LINE_COUNT		50


@implementation AboutPanelController

#pragma mark PRIVATE INSTANCE METHODS

- (void) createPanelToDisplay
{
    //	Programmatically create the new panel
    panelToDisplay = [[NSFancyPanel alloc]
        initWithContentRect: [[panelInNib contentView] frame]
        styleMask: NSBorderlessWindowMask
        backing: [panelInNib backingType]
        defer: NO];
    
    // Make us the controller
    [(NSFancyPanel *)panelToDisplay setController:self];

    //	Tweak esthetics, making it all white and with a shadow
    [panelToDisplay setBackgroundColor:[NSColor whiteColor]];
    [panelToDisplay setHasShadow:YES];

    [panelToDisplay setBecomesKeyOnlyIfNeeded:NO];

    //	We want to know if the window is no longer key/main
    [panelToDisplay setDelegate:self];

    //	Move the guts of the nib-based panel to the programmatically-created one
    {
        NSView *content;

        content = [[panelInNib contentView] retain];
        [content removeFromSuperview];
        [panelToDisplay setContentView: content];
        [content release];
    }
}

// Take version information from standard keys in the application’s bundle
// dictionary and display it.
//
- (void) displayVersionInfo
{
    NSString *value;

    value = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (value != nil)
    {
        [shortInfoField setStringValue: value];
    }

    value = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (value != nil)
    {
        value = [@"Version " stringByAppendingString:value];
        [versionField setStringValue: value];
    }
}

//	Watch for notifications that the application is no longer active, or that
//	another window has replaced the About panel as the main window, and hide
//	on either of these notifications.
//
- (void)watchForNotificationsWhichShouldHidePanel
{
    // This works better than just making the panel hide when the app
    // deactivates (setHidesOnDeactivate:YES), because if we use that
    // then the panel will return when the app reactivates.
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(hidePanel)
        name:NSApplicationWillResignActiveNotification
        object:nil];

    // If the panel is no longer main, hide it.
    // (We could also use the delegate notification for this.)
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hidePanel)
                                                 name:NSWindowDidResignMainNotification
                                               object:panelToDisplay];
}

// Get and return the text to scroll. This implementation just loads the contents
// of the “README.rtf” in the main bundle. You might choose a different file, or
// a completely different implementation.
//
- (NSAttributedString *) textToScroll
{
    NSString *path;

    // Locate the README.rtf inside the application’s bundle.
    path = [[NSBundle mainBundle] pathForResource: @"AboutContent" ofType: @"rtf"];

    // Suck the contents of the rich text file into a mutable “attributed string”.
    return [[[NSMutableAttributedString alloc] initWithPath:path documentAttributes:NULL] autorelease];
}

// Load the text to scroll into the scrolling text view. The odd thing here is
// that we load not only the text you'd expect, but also a bunch of blank lines
// at the end. The blank lines allow the real text to scroll out of sight.
//
- (void)loadTextToScroll
{
    NSMutableAttributedString *textToScroll;
    NSAttributedString *newline;

    //	Get whatever text we want to display
    textToScroll = [[self textToScroll] mutableCopy];

    // Append a bunch of blank lines to the end of the text, so it can always
    // scroll out of sight. This is not an elegant solution, and could fail if
    // the window and view are sufficiently tall. (I choose not to listen to
    // the rumors of the 5-meter tall Apple Drive-In Display.)

    // Make up one newline
    newline = [[[NSAttributedString alloc] initWithString: @"\n"] autorelease];

    // Append that one newline to the real text a bunch of times
    for (NSInteger i = 0; i < BLANK_LINE_COUNT; i++)
        [textToScroll appendAttributedString:newline];

    // Put the final result into the UI
    [[textView textStorage] setAttributedString:textToScroll];
}

//	Scroll to hide the top 'newAmount' pixels of the text
- (void)setScrollAmount:(float)newAmount
{
    // Scroll so that (0, amount) is at the upper left corner of the scroll view
    // (in other words, so that the top 'newAmount' scan lines of the text
    // is hidden).
    //
    [[textScrollView documentView] scrollPoint:NSMakePoint(0.0, newAmount)];

    // If anything overlaps the text we just scrolled, it won’t get redraw by the
    // scrolling, so force everything in that part of the panel to redraw.
    {
        NSRect scrollViewFrame;

        // Find where the scrollview’s bounds are, then convert to panel’s coordinates
        scrollViewFrame = [textScrollView bounds];
        scrollViewFrame = [[panelToDisplay contentView] convertRect:scrollViewFrame fromView:textScrollView];

        // Redraw everything which overlaps it.
        [[panelToDisplay contentView] setNeedsDisplayInRect: scrollViewFrame];
    }
}

// Scroll one frame of animation
- (void)scrollOneUnit
{
    float currentScrollAmount;

    // How far have we scrolled so far?
    currentScrollAmount = [textScrollView documentVisibleRect].origin.y;

    // Scroll one unit more
    [self setScrollAmount:(currentScrollAmount + SCROLL_AMOUNT_PIXELS)];
}

// If we don't already have a timer, start one messaging us regularly
- (void)startScrollingAnimation
{
    // Already scrolling?
    if (scrollingTimer != nil)
        return;

    // Start a timer which will send us a 'scrollOneUnit' message regularly
    scrollingTimer = [[NSTimer scheduledTimerWithTimeInterval:SCROLL_DELAY_SECONDS
                                                       target:self
                                                     selector:@selector(scrollOneUnit)
                                                     userInfo:nil
                                                      repeats:YES] retain];
}

// Stop the timer and forget about it
- (void)stopScrollingAnimation
{
    [scrollingTimer invalidate];

    [scrollingTimer release];
    scrollingTimer = nil;
}


#pragma mark PUBLIC CLASS METHODS

+ (AboutPanelController *)sharedInstance
{
    static AboutPanelController	*sharedInstance = nil;

    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
        [NSBundle loadNibNamed:@"AboutPanel.nib" owner:sharedInstance];
    }

    return sharedInstance;
}


#pragma mark PUBLIC INSTANCE METHODS

// Show the panel, starting the text at the top with the animation going
- (void)showPanel
{
    // Scroll to the top
    [self setScrollAmount: 0.0];

    [self startScrollingAnimation];

    // Make it the key window so it can watch for keystrokes
    [panelToDisplay makeKeyAndOrderFront:nil];
}

// Stop scrolling and hide the panel. (We stop the scrolling only to avoid
// wasting the processor, since if we kept scrolling it wouldn’t be visible anyway.)
//
- (void)hidePanel
{
    [self stopScrollingAnimation];

    [panelToDisplay orderOut: nil];
}

//	This method exists only because this is a developer example.
//	You wouldn’t want it in a real application.
//
- (void)setShowsScroller:(BOOL)newSetting
{
    [textScrollView setHasVerticalScroller:newSetting];
}


#pragma mark PUBLIC INSTANCE METHODS -- NSNibAwaking INFORMAL PROTOCOL

- (void)awakeFromNib
{
    //	Create 'panelToDisplay', a borderless window, using the guts of the more vanilla 'panelInNib'.
    [self createPanelToDisplay];

    //	Fill in text fields
    [self displayVersionInfo];

    [self loadTextToScroll];

    //	Make things look nice
    [panelToDisplay center];

    //	Make lots of other things dismiss the panel
    [self watchForNotificationsWhichShouldHidePanel];
}


#pragma mark PUBLIC INSTANCE METHODS -- NSFancyPanel DELEGATE

- (BOOL)handlesKeyDown: (NSEvent *)keyDown inWindow:(NSWindow *)window
{
    // Close the panel on any keystroke.
    // We could also check for the Escape key by testing
    //		[[keyDown characters] isEqualToString: @"\033"]

    [self hidePanel];
    return YES;
}

- (BOOL)handlesMouseDown:(NSEvent *)mouseDown inWindow:(NSWindow *)window
{
    // Close the panel on any click
    [self hidePanel];
    return YES;
}

@end

