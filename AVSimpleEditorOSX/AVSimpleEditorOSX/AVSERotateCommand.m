/*
     File: AVSERotateCommand.m
 Abstract: A subclass of AVSECommand which uses AVMutableVideoComposition to achieve a rotate effect. This tool rotates the composition by 90 degrees. This is achieved by applying a CGAffineTransformRotate along with CGAffineTransformMakeTranslation to move the rotated composition into view.
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


#import "AVSERotateCommand.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@implementation AVSERotateCommand

@synthesize mutableComposition;
@synthesize mutableVideoComposition;
@synthesize newWindowWidth;
@synthesize newWindowHeight;

- (void)performWithAsset:(AVAsset*)asset 
{
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
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
    
    // Check whether a composition has already been created, i.e, some other tool has already been applied
    if (!mutableComposition) { 
        // Create a new composition
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
    
    // Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
    t1 = CGAffineTransformMakeTranslation(mutableComposition.naturalSize.height, 0.0);
    // Rotate transformation
    t2 = CGAffineTransformRotate(t1, degreesToRadians(90.0));
    
    // Check whether a video composition already exists to set the appropriate render sizes and transforms
    if (!mutableVideoComposition) {
        // Create a new video composition
        mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        mutableVideoComposition.renderSize = CGSizeMake(mutableComposition.naturalSize.height,mutableComposition.naturalSize.width);
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        // The rotate transform is set on a layer instruction  
        instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[mutableComposition.tracks objectAtIndex:0]];
        [layerInstruction setTransform:t2 atTime:kCMTimeZero];
    }else{
        mutableVideoComposition.renderSize = CGSizeMake(mutableVideoComposition.renderSize.height, mutableVideoComposition.renderSize.width);
        // Extract the existing layer instruction on the mutableVideoComposition
        instruction = [mutableVideoComposition.instructions objectAtIndex:0];
        layerInstruction = [instruction.layerInstructions objectAtIndex:0];
        // Check if a transform already exists on this layer instruction, this is done to add the current transform on top of previous edits
        CGAffineTransform existingTransform;
        if (![layerInstruction getTransformRampForTime:[mutableComposition duration] startTransform:&existingTransform endTransform:NULL timeRange:NULL]) {
            [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        }else {
            // Note: the point of origin for rotation is the upper left corner of the composition, t3 is to compensate for origin
            CGAffineTransform t3 = CGAffineTransformMakeTranslation(-1*mutableComposition.naturalSize.height/2, 0.0);
            CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, CGAffineTransformConcat(t2, t3));
            [layerInstruction setTransform:newTransform atTime:kCMTimeZero];
        }
    }
    
    // Add the layer instruction to an instruction which is then added to the mutableVideoComposition 
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    mutableVideoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    // Resize window to adjust for rotation (AVSEDocument class handles the resizing)
    newWindowWidth = mutableComposition.naturalSize.height;
    newWindowHeight = mutableComposition.naturalSize.width;
    
    // Notify AVSEDocument class to reload the player view with the changes
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:AVSEReloadNotification
     object:self];
}

@end
