/*
     File: Controller.m 
 Abstract: Main controller object for this sample. 
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

#import "Controller.h"
#import "TrackBall.h"
#import "OverlayWindow.h"

@implementation Controller

- (NSBackgroundStyle)backgroundStyleForImage:(NSImage *)image {
    return NSBackgroundStyleLowered;
}

- (void)loadImage:(NSImage *)image {
    [image retain];
    [loadedImage release];
    loadedImage = image;
    [panorama setValue:image forInputKey:@"Image"];
    [trackBall setBackgroundStyle:[self backgroundStyleForImage:image]];
}

- (void)positionTrackBallWindow {
    // Position the trackBallWindow centered at the bottom of the panorama window.
	// All these calculations are in screen coordinates.
    [trackBallWindow setFrameOrigin:[[panorama window] frame].origin];
    NSSize contentSize = [panorama frame].size;
    NSSize trackballSize = NSMakeSize(contentSize.width / 3, contentSize.height / 3);
    [trackBall setFrame:(NSRect){NSZeroPoint, trackballSize}];
    [trackBallWindow setContentSize:trackballSize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note {
    [trackBall setTarget:self];
    [trackBall setAction:@selector(trackBallChanged:)];
    [trackBall setBackgroundStyle:NSBackgroundStyleLowered];
    
    NSWindow *panoramaWindow = [panorama window];
    
    [self loadImage:[NSImage imageNamed:@"Clown Fish"]];
    [panoramaWindow orderFront:self];
    
    trackBallWindow = [[OverlayWindow alloc] initWithContentRect:[trackBall frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [[trackBallWindow contentView] addSubview:trackBall];
    [trackBallWindow setOpaque:NO];
    [trackBallWindow setBackgroundColor:[NSColor clearColor]];
    [trackBallWindow setIgnoresMouseEvents:NO];
    
    [self positionTrackBallWindow];
    
    [panoramaWindow addChildWindow:trackBallWindow ordered:NSWindowAbove];
    [trackBallWindow makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)trackBallChanged:(TrackBall *)sender {
    NSArray *angles = [sender objectValue];
    
    [panorama setValue:[angles objectAtIndex:0] forInputKey:@"X_Rotation"];
    [panorama setValue:[angles objectAtIndex:1] forInputKey:@"Y_Rotation"];
    [panorama setValue:[angles objectAtIndex:2] forInputKey:@"Z_Rotation"];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self positionTrackBallWindow];
}

- (void)windowWillClose:(NSNotification *)notification {
    [trackBallWindow setContentView:nil];
    [trackBallWindow release];
}

- (IBAction)loadOtherPanoramicImage:(NSMenuItem *)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setResolvesAliases:NO];
    [openPanel setAllowsMultipleSelection:NO];
	[openPanel setMessage:@"Choose a panoramic image:"];
    [openPanel beginSheetModalForWindow:[panorama window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSImage *image = [[[NSImage alloc] initByReferencingURL:[openPanel URL]] autorelease];
            if (! image) NSBeep();
            else [self loadImage:image];
        }
    }];
}

@end

 