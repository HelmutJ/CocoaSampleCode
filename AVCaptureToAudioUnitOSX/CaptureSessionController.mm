/*

    File: CaptureSessionController.mm
Abstract: Class that sets up a AVCaptureSession that outputs to a
 AVCaptureAudioDataOutput. The output audio samples are passed through
 an effect audio unit and are then written to a file.
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

#import "CaptureSessionController.h"

static OSStatus PushCurrentInputBufferIntoAudioUnit(void                       *inRefCon,
													AudioUnitRenderActionFlags *ioActionFlags,
													const AudioTimeStamp       *inTimeStamp,
													UInt32						inBusNumber,
													UInt32						inNumberFrames,
													AudioBufferList            *ioData);

static void DisplayAlert(NSString *inMessageText)
{
    [[NSAlert alertWithMessageText:inMessageText
                     defaultButton:@"Bummers"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:@""] runModal];
    
}

@implementation CaptureSessionController

#pragma mark ======== Setup and teardown methods =========

- (id)init
{
	self = [super init];
	
	if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        [self setOutputFile:[documentsDirectory stringByAppendingPathComponent:@"Audio Recording.aif"]];
        
        feedbackValue = [[NSNumber alloc] initWithInt:50];
        delayTimeValue = [[NSNumber alloc] initWithInt:1];
	}
	
	return self;
}

- (void)awakeFromNib
{
	// Become the window's delegate so that the capture session can be stopped
    // and cleaned up immediately after the window is closed
	[window setDelegate:self];
    [window setAlphaValue:0.0];
    
    CABasicAnimation *recordingAnimation = [CABasicAnimation animation];
    recordingAnimation.duration = 1.0;
    recordingAnimation.repeatCount = HUGE_VALF;
    recordingAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    recordingAnimation.toValue = [NSNumber numberWithFloat:0.1];
    recordingAnimation.autoreverses = YES;
    
    [[image layer] addAnimation:recordingAnimation forKey:@"opacity"];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
	// Find the current default audio input device
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	
    UInt32 nChannels = 0;
    Float32 deviceSampleRate = 0.0;
    
    if (audioDevice && audioDevice.connected) {
        // Get the device format information we care about
        NSLog(@"Audio Device Name: %@", audioDevice.localizedName);
        
        CAStreamBasicDescription deviceFormat = CAStreamBasicDescription(*CMAudioFormatDescriptionGetStreamBasicDescription(audioDevice.activeFormat.formatDescription));
        
        nChannels = deviceFormat.mChannelsPerFrame;
        deviceSampleRate = deviceFormat.mSampleRate;
        
        NSLog(@"Device Audio Format:");
        deviceFormat.Print();
    } else {
        DisplayAlert(@"AVCaptureDevice defaultDeviceWithMediaType failed or device not connected!");
        [window close];
        return;
    }
	
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
    if (!captureSession) {
        DisplayAlert(@"AVCaptureSession allocation failed!");
        [window close];
        return;
    }
	
	// Create and add a device input for the audio device to the session
    NSError *error = nil;
	captureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!captureAudioDeviceInput) {
		[[NSAlert alertWithError:error] runModal];
        [window close];
		return;
	}
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    } else {
        DisplayAlert(@"Could not addInput to Capture Session!");
        [window close];
        return;
    }
    
    // Create and add a AVCaptureAudioDataOutput object to the session
    captureAudioDataOutput = [AVCaptureAudioDataOutput new];
    
    if (!captureAudioDataOutput) {
        DisplayAlert(@"Could not create AVCaptureAudioDataOutput!");
        [window close];
        return;
    }
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    } else {
        DisplayAlert(@"Could not addOutput to Capture Session!");
        [window close];
		return;
    }

    // Set the output audio settings for the audio data output to AU canonical, this will be the format of the data in the
    // sample buffers provided by AVCapture
    // CAStreamBasicDescription makes it easy to do this correctly
    CAStreamBasicDescription canonicalAUFormat;
    canonicalAUFormat.SetAUCanonical(nChannels, false); // does not set sample rate...
    canonicalAUFormat.mSampleRate = (deviceSampleRate < 48000.0) ? deviceSampleRate : 48000.0; // ...so do it here max 48k or less
    canonicalAUFormat.mChannelsPerFrame = (nChannels > 2) ? 2 : nChannels; // 2 channels max
    
    NSLog(@"AU Canonical Audio Format:");
    canonicalAUFormat.Print();
    
    BOOL isFloat = canonicalAUFormat.mFormatFlags & kAudioFormatFlagIsFloat;
    BOOL isNonInterleaved = canonicalAUFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved;
    BOOL isBigEndian = canonicalAUFormat.mFormatFlags & kAudioFormatFlagIsBigEndian;
    
    // AVCaptureAudioDataOutput will return samples in the device default format unless otherwise specified, this is different than what QTKitCapture did
    // where the Canonical Audio Format was used when no settings were specified. When keys aren't specifically set the device default value is used
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM],                    AVFormatIDKey,
                             [NSNumber numberWithFloat:canonicalAUFormat.mSampleRate],                  AVSampleRateKey,
                             [NSNumber numberWithUnsignedInteger:canonicalAUFormat.mChannelsPerFrame],  AVNumberOfChannelsKey,
                             [NSNumber numberWithInt:canonicalAUFormat.mBitsPerChannel],                AVLinearPCMBitDepthKey,
                             [NSNumber numberWithBool:isFloat],                                         AVLinearPCMIsFloatKey,
                             [NSNumber numberWithBool:isNonInterleaved],                                AVLinearPCMIsNonInterleaved,
                             [NSNumber numberWithBool:isBigEndian],                                     AVLinearPCMIsBigEndianKey,
                              nil];
    
    captureAudioDataOutput.audioSettings = settings;
    
    NSLog(@"AVCaptureAudioDataOutput Audio Settings: %@", captureAudioDataOutput.audioSettings);
    
    // Create a serial dispatch queue and set it on the AVCaptureAudioDataOutput object
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    if (!audioDataOutputQueue){
        DisplayAlert(@"dispatch_queue_create Failed!");
        [window close];
		return;
    }
    
    [captureAudioDataOutput setSampleBufferDelegate:self queue:audioDataOutputQueue];
    dispatch_release(audioDataOutputQueue);
	
	// Create an instance of the delay effect audio unit, this effect is added to the audio when it is written to the file
    
    CAComponentDescription delayEffectAudioUnitDescription(kAudioUnitType_Effect, kAudioUnitSubType_Delay, kAudioUnitManufacturer_Apple);
	AudioComponent effectAudioUnitComponent = AudioComponentFindNext(NULL, &delayEffectAudioUnitDescription);
	OSStatus err = AudioComponentInstanceNew(effectAudioUnitComponent, &effectAudioUnit);

	if (noErr == err) {
		// Set a callback on the effect unit that will supply the audio buffers received from the capture audio data output
		AURenderCallbackStruct renderCallbackStruct;
		renderCallbackStruct.inputProc = PushCurrentInputBufferIntoAudioUnit;
		renderCallbackStruct.inputProcRefCon = self;
		err = AudioUnitSetProperty(effectAudioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(renderCallbackStruct));	    
	}
	
	if (noErr != err) {
		if (effectAudioUnit) {
			AudioComponentInstanceDispose(effectAudioUnit);
			effectAudioUnit = NULL;
		}
        
		[[NSAlert alertWithError:[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]] runModal];
        [window close];
		return;
	}
	
	// Start the capture session - This will cause the audio data output delegate method didOutputSampleBuffer
    // to be called for each new audio buffer recieved from the input device
	[captureSession startRunning];
    
    [window makeKeyAndOrderFront:nil];
    [[window animator] setAlphaValue:1.0];
}

- (BOOL)windowShouldClose:(id)sender
{
    NSTimeInterval delay = [[NSAnimationContext currentContext] duration] + 0.1;
    [window performSelector:@selector(close) withObject:nil afterDelay:delay];
    [[window animator] setAlphaValue:0.0];
    return NO;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self setRecording:NO];
    while (extAudioFile) {
        sleep(1);
    }
    [captureSession stopRunning];
}

- (void)dealloc
{
	[captureSession release];
	[captureAudioDeviceInput release];
    [captureAudioDataOutput setSampleBufferDelegate:nil queue:NULL];
	[captureAudioDataOutput release];
	
	[outputFile release];
	
	if (extAudioFile)
		ExtAudioFileDispose(extAudioFile);
	if (effectAudioUnit) {
		if (didSetUpAudioUnits)
			AudioUnitUninitialize(effectAudioUnit);
		AudioComponentInstanceDispose(effectAudioUnit);
	}
    
    if (currentInputAudioBufferList) free(currentInputAudioBufferList);
    if (outputBufferList) delete outputBufferList;
	
	[super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

#pragma mark ======== Audio capture methods =========

/*
 Called by AVCaptureAudioDataOutput as it receives CMSampleBufferRef objects containing audio frames captured by the AVCaptureSession.
 Each CMSampleBufferRef will contain multiple frames of audio encoded in the set format, in this case the AU canonical non-interleaved
 linear PCM format compatible with AudioUnits. This is where all the work is done, the first time through setting up and initializing the
 AU then continually rendering the provided audio though the audio unit and if we're recording, writing the processed audio out to the file.
*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
	OSStatus err = noErr;
		
	BOOL isRecording = [self isRecording];
	
    // Get the sample buffer's AudioStreamBasicDescription which will be used to set the input format of the audio unit and ExtAudioFile
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *sampleBufferASBD = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (kAudioFormatLinearPCM != sampleBufferASBD->mFormatID) { NSLog(@"Bad format or bogus ASBD!"); return; }
    
    if ((sampleBufferASBD->mChannelsPerFrame != currentInputASBD.mChannelsPerFrame) || (sampleBufferASBD->mSampleRate != currentInputASBD.mSampleRate)) {
        /* 
         Although we told AVCaptureAudioDataOutput to output sample buffers in the canonical AU format, the number of channels or the
         sample rate of the audio can changes at any time while the capture session is running. If this occurs, the audio unit receiving the buffers
         needs to be reconfigured with the new format. This also must be done when a buffer is received for the first time.
        */
        
        currentInputASBD = *sampleBufferASBD;
        
        if (didSetUpAudioUnits) {
            // The audio units were previously set up, so they must be uninitialized now
            AudioUnitUninitialize(effectAudioUnit);
			
			// If recording was in progress, the recording needs to be stopped because the audio format changed
			if (extAudioFile) {
                [self setRecording:NO];
				err = ExtAudioFileDispose(extAudioFile);
				extAudioFile = NULL;
                NSLog(@"Recording Stopped - Audio Format Changed (%ld)", (long)err);
			}
            if (outputBufferList) delete outputBufferList;
            outputBufferList = NULL;
        } else {
            didSetUpAudioUnits = YES;
        }
		
		// Set the input and output formats of the audio unit to match that of the sample buffer
		err = AudioUnitSetProperty(effectAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &currentInputASBD, sizeof(currentInputASBD));
		
		if (noErr == err)
			err = AudioUnitSetProperty(effectAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &currentInputASBD, sizeof(currentInputASBD));
		
        // Initialize the AU
		if (noErr == err)
			err = AudioUnitInitialize(effectAudioUnit);
		
		if (noErr != err) {
			NSLog(@"Failed to set up audio units (%ld)", (long)err);
			
			didSetUpAudioUnits = NO;
			bzero(&currentInputASBD, sizeof(currentInputASBD));
		}
    }
	
	if (isRecording && !extAudioFile) {
        NSLog(@"Recording Started");
        
		/*
         Start recording by creating an ExtAudioFile and configuring it with the same sample rate and channel layout as those of the current sample buffer.
        */
        
        CAStreamBasicDescription recordingFormat(currentInputASBD.mSampleRate, currentInputASBD.mChannelsPerFrame, CAStreamBasicDescription::kPCMFormatInt16, true);
        recordingFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
        
        NSLog(@"Recording Audio Format:");
        recordingFormat.Print();
        
		const AudioChannelLayout *recordedChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, NULL);
		
		err = ExtAudioFileCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[self outputFile]],
										kAudioFileAIFFType,
										&recordingFormat,
										recordedChannelLayout,
										kAudioFileFlags_EraseFile,
										&extAudioFile);
		if (noErr == err) 
			err = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(currentInputASBD), &currentInputASBD);
		
		if (noErr != err) {
			if (extAudioFile) ExtAudioFileDispose(extAudioFile);
			extAudioFile = NULL;
            NSLog(@"Failed to setup audio file! (%ld)", (long)err);
		}
	} else if (!isRecording && extAudioFile) {
		// Stop recording by disposing of the ExtAudioFile
		err = ExtAudioFileDispose(extAudioFile);
		extAudioFile = NULL;
        NSLog(@"Recording Stopped (%ld)", (long)err);
	}
    
    CMItemCount numberOfFrames = CMSampleBufferGetNumSamples(sampleBuffer); // corresponds to the number of CoreAudio audio frames
		
    // In order to render continuously, the effect audio unit needs a new time stamp for each buffer
    // Use the number of frames for each unit of time continuously incrementing
    currentSampleTime += (double)numberOfFrames;
    
    AudioTimeStamp timeStamp;
    memset(&timeStamp, 0, sizeof(AudioTimeStamp));
    timeStamp.mSampleTime = currentSampleTime;
    timeStamp.mFlags |= kAudioTimeStampSampleTimeValid;		
    
    AudioUnitRenderActionFlags flags = 0;
    
    // Create an output AudioBufferList as the destination for the AU rendered audio
    if (NULL == outputBufferList) {
        outputBufferList = new AUOutputBL(currentInputASBD, numberOfFrames);
    }
    outputBufferList->Prepare(numberOfFrames);
    
    /*
     Get an audio buffer list from the sample buffer and assign it to the currentInputAudioBufferList instance variable.
     The the audio unit render callback called PushCurrentInputBufferIntoAudioUnit can access this value by calling the
     currentInputAudioBufferList method.
    */
    
    // CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer requires a properly allocated AudioBufferList struct
    currentInputAudioBufferList = CAAudioBufferList::Create(currentInputASBD.mChannelsPerFrame);
    
    size_t bufferListSizeNeededOut;
    CMBlockBufferRef blockBufferOut = nil;
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                  &bufferListSizeNeededOut,
                                                                  currentInputAudioBufferList,
                                                                  CAAudioBufferList::CalculateByteSize(currentInputASBD.mChannelsPerFrame),
                                                                  kCFAllocatorSystemDefault,
                                                                  kCFAllocatorSystemDefault,
                                                                  kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                  &blockBufferOut);
    
    if (noErr == err) {
        // Tell the effect audio unit to render -- This will synchronously call PushCurrentInputBufferIntoAudioUnit, which will
        // feed currentInputAudioBufferList into the effect audio unit
        
        // set some parameter values to affect the effect (To Hear What Condition My Condition Was In) 
        AudioUnitSetParameter(effectAudioUnit, kDelayParam_Feedback, kAudioUnitScope_Global, 0, [feedbackValue floatValue], 0);
        AudioUnitSetParameter(effectAudioUnit, kDelayParam_DelayTime, kAudioUnitScope_Global, 0, [delayTimeValue floatValue], 0);
        
        err = AudioUnitRender(effectAudioUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        if (err) {
            NSLog(@"AudioUnitRender failed! (%ld)", (long)err);
        }
        
        CFRelease(blockBufferOut);
        CAAudioBufferList::Destroy(currentInputAudioBufferList);
        currentInputAudioBufferList = NULL;
    } else {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed! (%ld)", (long)err);
    }

	if ((noErr == err) && extAudioFile) {
		err = ExtAudioFileWriteAsync(extAudioFile, numberOfFrames, outputBufferList->ABL());
        if (err) {
            NSLog(@"ExtAudioFileWriteAsync failed! (%ld)", (long)err);
        }
	}
}

/*
 Used by PushCurrentInputBufferIntoAudioUnit() to access the current audio buffer list
 that has been output by the AVCaptureAudioDataOutput.
*/
- (AudioBufferList *)currentInputAudioBufferList
{
	return currentInputAudioBufferList;
}

#pragma mark ======== Property and action definitions =========

@synthesize outputFile = outputFile;
@synthesize recording = recording;
@synthesize feedbackValue;
@synthesize delayTimeValue;

- (IBAction)chooseOutputFile:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"aif"]];
	[savePanel setCanSelectHiddenExtension:YES];
	
	NSInteger result = [savePanel runModal];
	if (NSOKButton == result) {
		[self setOutputFile:[[savePanel URL] path]];
	}
}

@end

#pragma mark ======== AudioUnit render callback =========

/*
 Synchronously called by the effect audio unit whenever AudioUnitRender() is called.
 Used to feed the audio samples output by the ATCaptureAudioDataOutput to the AudioUnit.
 */
static OSStatus PushCurrentInputBufferIntoAudioUnit(void *							inRefCon,
													AudioUnitRenderActionFlags *	ioActionFlags,
													const AudioTimeStamp *			inTimeStamp,
													UInt32							inBusNumber,
													UInt32							inNumberFrames,
													AudioBufferList *				ioData)
{
	CaptureSessionController *self = (CaptureSessionController *)inRefCon;
	AudioBufferList *currentInputAudioBufferList = [self currentInputAudioBufferList];
	UInt32 bufferIndex, bufferCount = currentInputAudioBufferList->mNumberBuffers;
	
	if (bufferCount != ioData->mNumberBuffers) return badFormat;
	
	// Fill the provided AudioBufferList with the data from the AudioBufferList output by the audio data output
	for (bufferIndex = 0; bufferIndex < bufferCount; bufferIndex++) {
		ioData->mBuffers[bufferIndex].mDataByteSize = currentInputAudioBufferList->mBuffers[bufferIndex].mDataByteSize;
		ioData->mBuffers[bufferIndex].mData = currentInputAudioBufferList->mBuffers[bufferIndex].mData;
		ioData->mBuffers[bufferIndex].mNumberChannels = currentInputAudioBufferList->mBuffers[bufferIndex].mNumberChannels;
	}
	
	return noErr;
}