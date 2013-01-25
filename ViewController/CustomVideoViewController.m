/*
     File: CustomVideoViewController.m 
 Abstract: The view controller for displaying a VideoView. 
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

#import "CustomVideoViewController.h"

@implementation CustomVideoViewController

// -------------------------------------------------------------------------------
//	awakeFromNib:
//
//	Load the movie from out bundle and set it to play back and forth.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	NSString* moviePathStr = [[NSBundle mainBundle] pathForResource:@"adam" ofType:@"mov"];
    
    player = [[AVPlayer alloc] init];
    AVURLAsset *file = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:moviePathStr isDirectory:NO]];
    
	[file loadValuesAsynchronouslyForKeys:nil completionHandler:^(void) {
		
		// The asset invokes its completion handler on an arbitrary queue when loading is complete.
		// Because we want to access our AVPlayer in our ensuing set-up, we must dispatch our handler to the main queue.
		dispatch_async(dispatch_get_main_queue(), ^(void) {
                
			// Create an AVPlayerLayer and add it to the player view if there is video, but hide it until it's ready for display
            AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
            [newPlayerLayer setFrame:[[self.view layer] bounds]];
            [newPlayerLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
            [[self.view layer] addSublayer:newPlayerLayer];
            
            // Create a new AVPlayerItem and make it our player's current item.
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:file];
            [player replaceCurrentItemWithPlayerItem:playerItem];
            
            playingForward = YES;
            [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:playerItem queue:nil usingBlock:^(NSNotification *note) {
                if(playingForward) {
                    [player seekToTime:CMTimeMultiplyByFloat64(playerItem.duration, 0.99f)];
                    [player play];
                    player.rate = -1;
                    playingForward = NO;
                } else {
                    [player seekToTime:kCMTimeZero];
                    [player play];
                    player.rate = 1;
                    playingForward = YES;
                }
            }];
            
            [player play];
            [player release];
		});
		
	}];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObject:self];
    
    [super dealloc];
}

@end
