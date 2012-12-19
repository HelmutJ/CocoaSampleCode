/*
     File: AVSEAddWatermarkCommand.m
 Abstract: A subclass of AVSECommand which handles CALayer. This tool adds a title layer (CALayer) on top of an existing AVMutableComposition or an AVAsset.
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

#import "AVSEAddWatermarkCommand.h"

@implementation AVSEAddWatermarkCommand

@synthesize mutableComposition;
@synthesize mutableVideoComposition;
@synthesize watermarkLayer;

- (void)performWithAsset:(AVAsset*)asset 
{
    watermarkLayer = nil;
    CGSize videoSize;
    
    // Check if a composition already exists, else create a composition using the input asset
    if(!mutableComposition){
        AVAssetTrack *videoTrack = nil;
        AVAssetTrack *audioTrack = nil;
        // Check if the asset contains video and audio tracks
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
            videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        CMTime insertionPoint = kCMTimeZero;
        NSError * error = nil;
        mutableComposition = [AVMutableComposition composition];
        // Insert the video and audio tracks from AVAsset 
        if (videoTrack != nil) {
            AVMutableCompositionTrack *vtrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [vtrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:videoTrack atTime:insertionPoint error:&error];
        }
        if (audioTrack != nil) {
            AVMutableCompositionTrack *atrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

            [atrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:audioTrack atTime:insertionPoint error:&error];
        }
    }
    
    // Check if the input asset contains only audio
    if ([[mutableComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        if(!mutableVideoComposition){
            // build a pass through video composition
            mutableVideoComposition = [AVMutableVideoComposition videoComposition];
            mutableVideoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
            mutableVideoComposition.renderSize = mutableComposition.naturalSize;
            
            AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
            
            AVAssetTrack *videoTrack = [[mutableComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
            mutableVideoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
        }
        
        videoSize = mutableVideoComposition.renderSize;
        watermarkLayer = [self watermarkLayerForSize:videoSize];
    }
    
    // Notify AVSEDocument class to reload the player view with the changes
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:AVSEReloadNotification
     object:self];
}

- (CALayer*)watermarkLayerForSize:(CGSize)videoSize
{
    // Create a layer for the title animation
    CALayer *_watermarkLayer = [CALayer layer];
    
    // Create a layer for the text of the title.
	CATextLayer *titleLayer = [CATextLayer layer];
	titleLayer.string = @"AVSE";
	titleLayer.font = (__bridge void*)[NSFont fontWithName:@"Helvetica" size:videoSize.height/6] ;
	titleLayer.shadowOpacity = 0.5;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	titleLayer.bounds = CGRectMake(0, 0, videoSize.width/2, videoSize.height/2);
	
	// Add it to the overall layer.
	[_watermarkLayer addSublayer:titleLayer];
    [_watermarkLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    
    return _watermarkLayer;
}

@end
