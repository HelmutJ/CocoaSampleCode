/*
     File: OverlayWindow.m 
 Abstract: This class does the bulk of the work of this sample, drawing a transparent overlay
 style of window that fades in and out based on where the mouse is, and controlling
 a blue selection box implemented as another transparent child window. 
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


#import "OverlayWindow.h"
#import "ColorView.h"
#include <Carbon/Carbon.h>

// A bunch of defines to handle hotkeys - if command-return is pressed, we switch modes on the blue selection box (another overlay window), switching between vertical/horizontal tracking.
const UInt32 kMyHotKeyIdentifier='folw';
const UInt32 kMyHotKey = 36; //the return key

EventHotKeyRef gMyHotKeyRef;
EventHotKeyID gMyHotKeyID;
EventHandlerUPP gAppHotKeyFunction;

pascal OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData);

@interface OverlayWindow (private)

- (void)switchDirection;

@end

// This routine is called when the command-return hotkey is pressed.  It means it's time to change modes for the blue selection box overlay window.
pascal OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData)
{
    // We can assume our hotkey was pressed

        // Get the reference to our window and call -switchDirection to reverse the trackingWin's direction.
    OverlayWindow *window = (OverlayWindow *)userData;
    [window switchDirection];
    
    return noErr;
    
}

@implementation OverlayWindow

// We override this initializer so we can set the NSBorderlessWindowMask styleMask, and set a few other important settings
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
    
    if ( self ) {
        [self setOpaque:NO]; // Needed so we can see through it when we have clear stuff on top
        [self setHasShadow:YES];
        [self setLevel:NSFloatingWindowLevel]; // Let's make it sit on top of everything else
        [self setAlphaValue:0.2]; // It'll start out mostly transparent
    }
    
    contentRect.origin.x=100;
    contentRect.origin.y=100;
    
    return self;
}

- (void)awakeFromNib
{
    NSSize cellSize = [[(ColorView *)[self contentView] myButtons] cellSize];
    
        // First we setup the blue selection box - another window that will be attached as a child window
        // to this one, and will be moved by timers as needed.
    trackingWin=[[NSWindow alloc] 
                        // NOTE: The coordinates of NSWindow are anchored at the bottom left
                    initWithContentRect:NSMakeRect(self.frame.origin.x, 
                                                   self.frame.origin.y + self.frame.size.height - cellSize.height, 
                                                   self.frame.size.width, 
                                                   cellSize.height) 
                    styleMask:NSBorderlessWindowMask 
                    backing:NSBackingStoreBuffered 
                    defer:YES];
    [trackingWin setOpaque:NO];
    [trackingWin setAlphaValue:0.2];
    [trackingWin setHasShadow:YES];
    [trackingWin setLevel:NSFloatingWindowLevel];
    
        // This next line sets things so that we can click through the blue selection box to
        // click buttons in the matrix underneath.
    [trackingWin setIgnoresMouseEvents:YES];
    
        // The content should be filled with a color, so we setup our ColorView
    [trackingWin setContentView:[[[ColorView alloc] initWithFrame:NSZeroRect] autorelease]];
    [(ColorView *)[trackingWin contentView] setColor:[[NSColor blueColor] colorWithAlphaComponent:0.5]];
        // Move the trackingWin to the front
    [trackingWin orderFront:self];
    
        // The blue tracking window is attached as a child window to the main window, so that moving
        // The main window will move the child window (even though currently you can't move the main
        // window)
    [self addChildWindow:trackingWin ordered:NSWindowAbove];
    
        // Tracking areas need to be setup to handle when the mouse moves into or out of the main window
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[[self contentView] bounds] 
                                                            options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways 
                                                            owner:self 
                                                            userInfo:nil];
    [[self contentView] addTrackingArea:trackingArea];
    [trackingArea release];
    
        // We also must determine whether the mouse is initially inside or outside the windows.
    if ( NSPointInRect([NSEvent mouseLocation],[self frame]) )
        [self mouseEntered:nil];
    else
        [self mouseExited:nil];
    
        // Start with vertical movement
    movingVertically = YES;
    
        // Now lets go setup the hotkey handler, using Carbon APIs (there is no ObjC Cocoa HotKey API as of 10.7)
    EventTypeSpec eventType;
    
    gAppHotKeyFunction = NewEventHandlerUPP(MyHotKeyHandler);
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(gAppHotKeyFunction,1,&eventType,self,NULL);
    gMyHotKeyID.signature=kMyHotKeyIdentifier;
    gMyHotKeyID.id=1;
    
    RegisterEventHotKey(kMyHotKey, cmdKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
}

// Windows created with NSBorderlessWindowMask normally can't be key, but we want ours to be
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

// Here we use NSWindow's -setFrame:display:animate: method to move the trackingWin one cell
// down/right.
- (void)moveCursor
{
    NSSize cellSize = [[(ColorView *)[self contentView] myButtons] cellSize];
    NSPoint trackingWindowOrigin = [trackingWin frame].origin;
    BOOL animate = NO;
        // There is 1 exta pixel between the cells in the NSMatrix.  Unless taken into account
        // this will cause a problem for our check down below unless taken into account.
    NSUInteger rowSpacing = [[(ColorView *)[self contentView] myButtons] numberOfRows] - 1;
    NSUInteger columnSpacing = [[(ColorView *)[self contentView] myButtons] numberOfColumns] - 1;
    
    
    if ( movingVertically ) {
            // Move down by the height of one cell
        trackingWindowOrigin.y -= cellSize.height;
            // Check if we moved to far down and reset to the top
        if ( trackingWindowOrigin.y < [self frame].origin.y - rowSpacing)
            trackingWindowOrigin.y = [self frame].origin.y + [self frame].size.height - cellSize.height;
        else
                // Don't animate the reset movement
            animate = YES;
        
    } else {
            // Move right by the height of one cell
        trackingWindowOrigin.x += cellSize.width;
            // Check if we moved to far right and reset to the left side
        if ( trackingWindowOrigin.x >= [self frame].origin.x + [self frame].size.width + columnSpacing )
            trackingWindowOrigin.x = [self frame].origin.x;
        else
                // Don't animate the reset movement
            animate = YES;
    }
    
        // Apply the new origin to the trackingWin.
    NSRect newRect = { trackingWindowOrigin, [trackingWin frame].size };
    [[trackingWin animator] setFrame:newRect display:YES animate:animate];
        
        // Call this method again in 1 second to animate to the next state.
    [self performSelector:@selector(moveCursor) withObject:nil afterDelay:1];
}

// Switches the movement direction of the trackingWin
- (void)switchDirection
{
    NSSize cellSize = [[(ColorView *)[self contentView] myButtons] cellSize];
    NSRect trackingWindowFrame = [trackingWin frame];
        
        // Stop any pending calls to -moveCursor since we may issue our own at the end
        // of this method.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if ( movingVertically ) {
            // To switch to horizontal movement, we shrink the frame to the trackingWin of a cell
            // in the NSMatrix.
        trackingWindowFrame.size.width = cellSize.width;
    } else {
            // To return to vertical movement, we restore the width of the trackingWin to the width
            // of the main window.  We must also move the trackingWin back to the left edge of the
            // main window.
        trackingWindowFrame.origin.x = [self frame].origin.x;
        trackingWindowFrame.size.width = [self frame].size.width;
    }
    
    movingVertically = !movingVertically;
    
        // Apply the new frame and animate the change.
    [[trackingWin animator] setFrame:trackingWindowFrame display:YES animate:YES];
    
    if ( NSPointInRect([NSEvent mouseLocation],[self frame]) )
        [self performSelector:@selector(moveCursor) withObject:nil afterDelay:1];
}

#pragma mark - Mouse

// If the mouse enters a window, go make sure we fade in
- (void)mouseEntered:(NSEvent *)theEvent
{
        // Use Core Animation to fade in both windows.
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [[self animator] setAlphaValue:1.0];
        [[trackingWin animator] setAlphaValue:1.0];
        
    } completionHandler:^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
            // Begin moving the trackingWin.
        [self performSelector:@selector(moveCursor) withObject:nil afterDelay:0];
    }];
}

// If the mouse exits a window, go make sure we fade out
- (void)mouseExited:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [[self animator] setAlphaValue:0.2];
        [[trackingWin animator] setAlphaValue:0.2];
        
    } completionHandler:^{
        
            // Stop all calls to moveCursor to suspend the movement of the trackingWin.
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }];
}

@end
