/*
     File: AVSEAddMusicCommand.m
 Abstract: A subclass of AVSECommand which uses AVMutableAudioMix. This tool replaces the existing audio track of a AVMutableComposition with a custom audio track and shows the use of AVMutableAudioMixInputParameters to add volume ramps to the audio track.
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

#import "AVSEAddMusicCommand.h"

@implementation AVSEAddMusicCommand

@synthesize mutableComposition;
@synthesize mutableAudioMix;

- (void)performWithAsset:(AVAsset*)asset 
{
    AVAssetTrack *videoTrack = nil;
    AVAssetTrack *audioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    NSError *error = nil;
    
    NSString *audioURL = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"m4a"];
    
    AVAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioURL] options:nil];
    AVAssetTrack *newAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    // Check whether a composition has already been created, i.e, some other tool has already been applied.
    if (!mutableComposition) { 
        // Create a new composition
        mutableComposition = [AVMutableComposition composition];
        // Add to tracks to composition from the input video asset
        if (videoTrack != nil) {
            AVMutableCompositionTrack *vTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:videoTrack atTime:kCMTimeZero error:&error];
        }
        if (audioTrack != nil) {
            AVMutableCompositionTrack *aTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
        }    
    }
    
    // Add custom audio track to the composition
    AVMutableCompositionTrack *aTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]) ofTrack:newAudioTrack atTime:kCMTimeZero error:&error];
    
    // Mix parameters sets a volume ramp for the audio track to be mixed with the existing audio track for the duration of the composition
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:aTrack];
    [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];
    
    mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = [NSArray arrayWithObject:mixParameters];
    
    // Notify AVSEDocument class to reload the player view with the changes
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:AVSEReloadNotification 
     object:self];
}

@end
