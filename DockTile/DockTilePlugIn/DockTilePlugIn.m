/*
     File: DockTilePlugIn.m
 Abstract: DockTile is a "game" which demonstrates the use of NSDockTile, and more importantly, the NSDockTilePlugIn protocol introduced in 10.6.
 
 The game is terribly simple: Your score goes up by 1 just by launching the app! So keep on launching the app over and over to reach new high scores.
 
 This class, DockTilePlugIn, is part of the dock plug-in for the app, which allows the dock tile to show the score even when the app is not running. This class implements the NSDockTilePlugIn protocol, which has just one required method, -setDockTile:.
 
 When the plug-in is loaded, an instance of DockTilePlugIn is instantiated, and setDockTile: called with an instance of NSDockTile.  The implementation of setDockTile: in DockTilePlugIn sets the plug-in as an observer of high score changes (using NSDistributedNotification), causing the badge on the dock tile to update everytime the score is updated. 
 
 The NSDistributedNotificationCenter registry happens with the 10.6 method addObserverForName:object:queue:block:. The body of the block has no references to the DockTilePlugIn instance, which means the notification does not cause it to be retained. In this case that does not matter (since setDockTile:nil is called, which removes the observer), but in some cases this is important to watch for.
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

#import "DockTilePlugIn.h"

@implementation DockTilePlugIn

@synthesize highScoreObserver;

/* To update the score, we first make sure we are looking at the latest state of the defaults database, then we fetch the score and set it as the badge label.
*/
static void updateScore(NSDockTile *tile) {
    CFPreferencesAppSynchronize(CFSTR("com.apple.examples.DockTileApp"));
    NSInteger highScore = CFPreferencesGetAppIntegerValue(CFSTR("HighScore"), CFSTR("com.apple.examples.DockTileApp"), NULL);
    [tile setBadgeLabel:[NSString stringWithFormat:@"%ld", (long)highScore]];
}

- (void)setDockTile:(NSDockTile *)dockTile {
    if (dockTile) {
        // Attach an observer that will update the high score in the dock tile whenever it changes
	self.highScoreObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.apple.DockTileDemoHighScoreChanged" object:nil queue:nil usingBlock:^(NSNotification *notification) {
	    updateScore(dockTile);	// Note that this block captures (and retains) dockTile for use later. Also note that it does not capture self, which means -dealloc may be called even while the notification is active. Although it's not clear this needs to be supported, this does eliminate a potential source of leaks.
	}];
        updateScore(dockTile);	// Make sure score is updated from the get-go as well
    } else {
        // Strictly speaking this may not be necessary (since the plug-in may be terminated when it's removed from the dock), but it's good practice
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self.highScoreObserver];
	self.highScoreObserver = nil;
    }
}

- (void)dealloc {
    if (self.highScoreObserver) {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self.highScoreObserver];
	self.highScoreObserver = nil;
    }
    [super dealloc];
}

@end
