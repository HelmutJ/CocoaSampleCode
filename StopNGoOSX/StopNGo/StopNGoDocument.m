/*
     File: StopNGoDocument.m
 Abstract: Document that captures stills to a QuickTime movie
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "StopNGoDocument.h"

#define DEFAULT_FRAMES_PER_SECOND	5.0

@implementation StopNGoDocument

@synthesize outputURL;

- (BOOL)setupAVCapture
{
	NSError *error = nil;
    
    session = [AVCaptureSession new];
	[session setSessionPreset:AVCaptureSessionPresetPhoto];
	
	// Select a video device, make an input
	for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
		if ([device hasMediaType:AVMediaTypeVideo] || [device hasMediaType:AVMediaTypeMuxed]) {
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
			if (error) {
                [session release];
                NSLog(@"deviceInputWithDevice failed with error %@", [error localizedDescription]);
				return NO;
            }
			if ([session canAddInput:input])
				[session addInput:input];
			break;
		}
	}
	
	// Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	if ([session canAddOutput:stillImageOutput])
		[session addOutput:stillImageOutput];
	
	// Make a preview layer so we can see the visual output of an AVCaptureSession
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[previewLayer setFrame:[previewView bounds]];
	[[previewLayer connection] setAutomaticallyAdjustsVideoMirroring:NO];
	[[previewLayer connection] setVideoMirrored:YES];
    
    // add the preview layer to the hierarchy
	CALayer *rootLayer = [previewView layer];
	[rootLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
	[rootLayer addSublayer:previewLayer];
	
    // start the capture session running, note this is an async operation
    // status is provided via notifications such as AVCaptureSessionDidStartRunningNotification/AVCaptureSessionDidStopRunningNotification
    [session startRunning];
	
	return YES;
}

- (BOOL)setupAssetWriterForURL:(NSURL *)fileURL formatDescription:(CMFormatDescriptionRef)formatDescription
{
	NSError *error = nil;
    
    // allocate the writer object with our output file URL
	assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
	if (error) {
        NSLog(@"AVAssetWriter initWithURL failed with error %@", [error localizedDescription]);
        return NO;
    }

    // initialized a new input for video to receive sample buffers for writing
    // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
	videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil]; // passthru
	[videoInput setExpectsMediaDataInRealTime:YES];
	if ([assetWriter canAddInput:videoInput])
		[assetWriter addInput:videoInput];
	
    // initiates a sample-writing at time 0
	nextPresentationTime = kCMTimeZero;
	[assetWriter startWriting];
	[assetWriter startSessionAtSourceTime:nextPresentationTime];
    
	return YES;
}

- (IBAction)takePicture:(id)sender
{
    // initiate a still image capture, return immediately
    // the completionHandler is called when a sample buffer has been captured
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection 
												  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *__strong error) {
        
        // set up the AVAssetWriter using the format description from the first sample buffer captured
		if (!assetWriter) {
			CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(imageDataSampleBuffer);
			if ( NO == [self setupAssetWriterForURL:self.outputURL formatDescription:formatDescription] ) return;
            [self setFileURL:self.outputURL];
            [self setFileType:@"mov"];
		}
        
		// re-time the sample buffer
		CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
		timingInfo.duration = frameDuration;
		timingInfo.presentationTimeStamp = nextPresentationTime;
		CMSampleBufferRef sbufWithNewTiming = NULL;
		OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, 
															 imageDataSampleBuffer, 
															 1, // numSampleTimingEntries
															 &timingInfo, 
															 &sbufWithNewTiming);
        if (err) {
            NSLog(@"CMSampleBufferCreateCopyWithNewTiming failed with error %d", err);
            return;
        }
		
        // append the sample buffer if we can and increment presnetation time
		if ( [videoInput isReadyForMoreMediaData] ) {
			if ([videoInput appendSampleBuffer:sbufWithNewTiming]) {
				nextPresentationTime = CMTimeAdd(frameDuration, nextPresentationTime);
			}
			else {
				NSError *error = [assetWriter error];
				NSLog(@"failed to append sbuf: %@", [error localizedDescription]);
			}
		}
		
        // release the copy of the sample buffer we made
		CFRelease(sbufWithNewTiming);
	}];
}

- (void)teardownAssetWriter
{
	if (assetWriter) {
		[videoInput markAsFinished];
		[assetWriter finishWriting];
		[[NSWorkspace sharedWorkspace] openURL:[assetWriter outputURL]];
        [videoInput release];
        [assetWriter release];
		videoInput = nil;
		assetWriter = nil;
	}
	self.outputURL = nil;
}

- (IBAction)startStop:(id)sender
{
	if (started) {
		// finish
		[self teardownAssetWriter];
		[takePictureButton setEnabled:NO];
		[sender setTitle:@"Start"];
	}
	else {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setTitle:@"Choose QuickTime movie location..."];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]];
		NSInteger result = [savePanel runModal];
		if ( result != NSFileHandlingPanelOKButton )
			return;
		
		self.outputURL = [savePanel URL];
		[[NSFileManager defaultManager] removeItemAtURL:self.outputURL error:nil];
		
		[takePictureButton setEnabled:YES];
		[sender setTitle:@"Stop"];
	}
	started = !started;
}

- (void)close
{
	[self teardownAssetWriter];
    [session stopRunning];
	[previewLayer removeFromSuperlayer];
	[previewLayer setSession:nil];
    [previewLayer release];
    [stillImageOutput release];
    [session release];
	[super close];
}

- (float)framesPerSecond
{
	return (float)((1.0 / CMTimeGetSeconds(frameDuration)));
}

- (void)setFramesPerSecond:(float)framesPerSecond
{
	frameDuration = CMTimeMakeWithSeconds( 1.0 / framesPerSecond, 90000);
}

- (IBAction)togglePreviewMirrored:(id)sender
{
	[[previewLayer connection] setVideoMirrored:[(NSButton *)sender state]];
}

- (id)init
{
    self = [super init];
    if (self) {
		frameDuration = CMTimeMakeWithSeconds(1. / DEFAULT_FRAMES_PER_SECOND, 90000);
    }
    
    return self;
}

- (NSString *)windowNibName
{
	return @"StopNGoDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	[self setupAVCapture];
}

@end
