/*
     File: BlastAppController.m
 Abstract: BlastAppController. Central controller object for BlastApp.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <Cocoa/Cocoa.h>
#import "BlastAppController.h"
#import "Game.h"


@implementation BlastAppController

- (void)createNewGame:(id)sender {
    if (game == nil) {
        if (![NSBundle loadNibNamed:@"Game.nib" owner:self]) {
            NSLog(@"No nib file for game?");
            return;
        } else {
            // game is an outlet that gets initialized to the game view when the nib file is being loaded...
            [game startGame:nil];
            [[game window] center];
        }
    }
    [[game window] makeKeyAndOrderFront:nil];
}

- (void)createDemo:(id)sender {
    if (demo == nil) {
        Game *origGame = game;	// Preserve the actual game
        if (![NSBundle loadNibNamed:@"Game.nib" owner:self]) {
            NSLog(@"No nib file for game?");
            return;
        } else {
            // game is an outlet that gets initialized to the game view when the nib file is being loaded...
            demo = game;
            game = origGame;	// Restore the actual game
            [game stop:nil];	// Pause it...
            [demo setDemo:YES];
	    [[demo window] setTitle:NSLocalizedString(@"BlastApp Demo", "Window title when running in demo mode")];
            [demo startGame:nil];
        }
    }
    [[demo window] makeKeyAndOrderFront:nil];
}

// applicationDidFinishLaunching: is called as the first thing in the run loop of the
// application. At this point, everything is created, but we haven't entered
// the event loop yet.

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self createNewGame:nil];
}

// applicationDidHide is called when the application is hidden. It doesn't
// make sense to run the game while the application is running, also,
// in case the boss walks by you want to be able to hit just Command-h and
// have the game hide and pause at the same time. This way the boss won't
// ask where the noises are coming from and you will not have lost
// a high-score game.

- (void)applicationDidHide:(NSNotification *)notification {
    if (game != nil) [game stop:nil];
    if (demo != nil) [demo stop:nil];
}

- (void)applicationDidUnhide:(NSNotification *)notification {
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {
    [game updateHighScore];
    return YES;
}

- (void)showPrefs:(id)sender {
    [game showPrefs:sender];
}

- (void)setGame:(Game *)obj {
    game = obj;
}

@end
