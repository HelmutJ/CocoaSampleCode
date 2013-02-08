/*
     File: DockTileAppDelegate.m
 Abstract: DockTile is a "game" which demonstrates the use of NSDockTile, and more importantly, the NSDockTilePlugIn protocol introduced in 10.6.
 
 The game is terribly simple: Your score goes up by 1 just by launching the app! So keep on launching the app over and over to reach new high scores.
 
 The high score is shown in the dock tile, and the app window, where you can also reset it.
 
 The whole game is implemented in the DockTileAppDelegate class, which is the delegate of the application. On applicationDidFinishLaunching: it updates the highScore. The only other thing it does is to implement resetHighScore: to set it back to 0.
 
 The dock tile plug-in is useful as a way to show off your high score even when the app is not running. The plug-in simply reads the high score from defaults, displays it as a badge on the dock tile, then updates it on receipt of a distributed notification that indicates when the high score changed.
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

#import "DockTileAppDelegate.h"

@implementation DockTileAppDelegate

/* highScore accessors. highScore is declared as a property, but we don't have an instance variable for it, and nor do we use synthesized accessors since we do special things.
*/
- (NSInteger)highScore {
    // We get the value from defaults (preferences), we don't keep a copy of the high score in the app.
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"HighScore"];
}

- (void)setHighScore:(NSInteger)newScore {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // We just save the value out, we don't keep a copy of the high score in the app.
    [defaults setInteger:newScore forKey:@"HighScore"];

    // Save the value out to defaults now. We often don't explicit synchronize, since it's best to let the system take care of it automatically. However, in this case since we're asking the plug-in to update the score, synchronizing before the notification ensures that the plug-in sees the latest value. Always make sure the value is updated and synchronized before sending out the distributed notification to other processes.
    [defaults synchronize];	

    // And post a notification so the plug-in sees the change.
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DockTileDemoHighScoreChanged" object:nil];

    // Now update the dock tile. Note that a more general way to do this would be to observe the highScore property, but we're just keeping things short and sweet here, trying to demo how to write a plug-in. 
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", (long)newScore]];
}

/* On launch, get the previous score, increment by one, and save it. By definition all updated scores are high scores. 
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setHighScore:[self highScore] + 1];
}

/* Reset the high score. Simple...
*/
- (void)resetHighScore:(id)sender {
    [self setHighScore:0];
}

@end
