/*
    File: AudioOutput.m
Abstract: Send generated audio to a live destination or a file
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

#include "AudioOutput.h"

#include <CoreAudio/CoreAudio.h>
#include <pthread.h>

//
// The format we deliver our samples in
//
static const AudioStreamBasicDescription sAudioFormatMono = {
	22050.0, kAudioFormatLinearPCM, 
	kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
	4, 1, 4, 1, 32, 0
};								   

//////////////// Concrete Subclasses of AudioOutput	/////////////////////////////

enum {kSampleBufferSize = 8192};

@interface AudioOutputLive : AudioOutput {
	pthread_mutex_t		lock;
	pthread_cond_t		bufferFull;
	AUGraph 			audioGraph;
	AudioUnit 			outputUnit;
	bool				offline;

	float				sampleBuffer[kSampleBufferSize];
	size_t				numSamples;
	bool				audioStarting;	// Set true till first render call: Prepend zeros instead of appending.
	bool				audioDone;		// Expect no more samples
}

- (id)init:(BOOL)externalSink withDevice:(AudioDeviceID)device;
- (OSStatus)render:(UInt32)inNumberFrames buffers:(AudioBufferList *)ioData;

@end

@interface AudioOutputFile : AudioOutput {
	ExtAudioFileRef	 	audioFile;
	AudioFileID			audioFileID;
}

- (id)initWithFile:(ExtAudioFileRef)file;
@end

//////////////// Generic Methods	/////////////////////////////

@implementation AudioOutput

+ (AudioOutput *)createLiveAudio:(BOOL)externalSink withDevice:(AudioDeviceID) device
{
	return [[AudioOutputLive alloc] init:externalSink withDevice:device];
}

+ (AudioOutput *)createFileAudio:(ExtAudioFileRef)file
{
	return [[AudioOutputFile alloc] initWithFile:file];
}

+ (AudioOutput *)createIgnoreAudio
{
	return [[AudioOutput alloc] init];
}

- (void)close
{
	[self release];
}

- (size_t)sampleCapacity
{
	return 1024ul;
}

- (void)queueSamples:(const float *)samples count:(size_t)count
{
}

- (void)stopAudio
{
}

- (BOOL)audioDone
{
	return true;
}

- (AudioUnit)getSourceUnit
{
	return 0;
}

- (AUGraph)getSourceGraph
{
    return NULL;
}

- (void)setOfflineProcessing:(BOOL)offline
{
}

- (BOOL)offlineProcessing
{
	return NO;
}

@end

////////////////////////////////////////// Live Audio ///////////////////////////////////

extern OSStatus    
AudioOutputLiveRenderer(void *inRefCon, AudioUnitRenderActionFlags * flags, const AudioTimeStamp * timeStamp, 
						UInt32 busNumber, UInt32 inNumberFrames, AudioBufferList *ioData);

OSStatus    
AudioOutputLiveRenderer(void *inRefCon, AudioUnitRenderActionFlags * flags, const AudioTimeStamp * timeStamp, 
						UInt32 busNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
	return [(AudioOutputLive *)inRefCon render:inNumberFrames buffers:ioData];
}

@implementation AudioOutputLive

- (id)init:(BOOL)externalSink withDevice:(AudioDeviceID)device
{
	audioStarting	= true;
	audioDone		= true;
	/*
	 * Initialize buffers
	 */
	pthread_mutex_init(&lock, NULL);
	pthread_cond_init(&bufferFull, NULL);
	
	//
	// Initialize Audio Graph
	//
	AudioComponentDescription  	cd;
	
	if (NewAUGraph(&audioGraph))
		goto failedGraph;
	
	//
	// Create output
	//
	cd.componentFlags 			= 0;        
	cd.componentFlagsMask 		= 0;     
	if (externalSink) {
		//
		// Will feed into another AudioUnit. Create an AUConverter
		// so we can serve any audio format desired.
		//
		cd.componentType 			= kAudioUnitType_FormatConverter;
		cd.componentSubType 		= kAudioUnitSubType_AUConverter;
	} else {
		//
		// Will feed directly to sound out
		//
		cd.componentType 			= kAudioUnitType_Output;
		cd.componentSubType 		= device ? kAudioUnitSubType_HALOutput : kAudioUnitSubType_DefaultOutput;
	}
	cd.componentManufacturer 	= kAudioUnitManufacturer_Apple; 
	
	AUNode	outputNode;
	if (AUGraphAddNode(audioGraph, &cd, &outputNode))
		goto failedConstruction;

	//
	// Set up our render callback
	//
	AURenderCallbackStruct input;
    input.inputProc			= AudioOutputLiveRenderer;
    input.inputProcRefCon	= self;
	
    if (AUGraphSetNodeInputCallback(audioGraph, outputNode, 0, &input))
		goto failedConstruction;
	
	//
	// Feel free to add more nodes to the graph as you see fit
	//
	
	if (AUGraphOpen(audioGraph))
		goto failedConstruction;

	AUGraphNodeInfo(audioGraph, outputNode, NULL, &outputUnit);
	
	//
	// Define our initial format
	//
	AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input, 0, 
						 &sAudioFormatMono, sizeof(sAudioFormatMono));
	
	if (externalSink) {
		//
		// For the common case that we're used as a stereo source, let's set up a reasonable channel map.
		//
		SInt32 channelMap[2] = { 0, 0 };
		AudioUnitSetProperty(outputUnit, 
							 kAudioOutputUnitProperty_ChannelMap,
							 kAudioUnitScope_Output, 0,
							 channelMap, sizeof(channelMap));
	} else {									 
		if (device)
			if (AudioUnitSetProperty(outputUnit,
									 kAudioOutputUnitProperty_CurrentDevice,
									 kAudioUnitScope_Global, 0,
									 &device, sizeof(AudioDeviceID))
				) 
				goto failedConstruction;
		
		if (AUGraphInitialize(audioGraph))
			goto failedConstruction;
	}
	
	return self;
failedConstruction:
	fprintf(stderr, "Failed AUGraph:\n");
	CAShow(audioGraph);
	DisposeAUGraph(audioGraph);
failedGraph:
	audioGraph	= nil;
	fprintf(stderr, "CoreAudio failure!\n");

	return self;
}

- (void)close
{
	AUGraphStop(audioGraph);
	DisposeAUGraph(audioGraph);
	pthread_mutex_destroy(&lock);
	pthread_cond_destroy(&bufferFull);
}

- (size_t)sampleCapacity
{
	size_t	capacity = kSampleBufferSize;
	pthread_mutex_lock(&lock);
	capacity	-= numSamples;
	pthread_mutex_unlock(&lock);
	
	return capacity;
}

- (void)queueSamples:(const float *)samples count:(size_t)sampleCount
{
	//
	// We assume that the client has confirmed that there is enough
	// capacity to take the samples.
	//
	pthread_mutex_lock(&lock);
	assert(numSamples+sampleCount <= kSampleBufferSize);
	memcpy(sampleBuffer+numSamples, samples, sampleCount*sizeof(float));
	numSamples	   += sampleCount;
	if (audioDone) {
		//
		// Restart after being finished
		//
		audioDone		= false;
		audioStarting	= true;
		AUGraphStart(audioGraph);
	}
	pthread_cond_signal(&bufferFull);
	pthread_mutex_unlock(&lock);	
}

- (BOOL)audioDone
{
	bool isDone;
	
	pthread_mutex_lock(&lock);
	audioDone	= true;
	if ((isDone = !numSamples))
		AUGraphStop(audioGraph);
	pthread_mutex_unlock(&lock);
	
	return isDone;
}

- (void)stopAudio
{
	pthread_mutex_lock(&lock);
	//
	// AudioDone with extreme prejudice: Search for earliest zero crossing 
	// to truncate audio.
	//
	audioDone	= true;
	for (size_t i=0; i<numSamples; ++i)
		if (!sampleBuffer[i]) 
			numSamples = i;	// Truncate here
	pthread_mutex_unlock(&lock);	
}

- (OSStatus)render:(UInt32)inNumberFrames buffers:(AudioBufferList *)ioData
{
	float *	outSamp	= (float *)ioData->mBuffers[0].mData;
	pthread_mutex_lock(&lock);
checkBufferFull:
	if (inNumberFrames > numSamples) {
		//
		// Not enough samples produced yet. In live mode, we pad with zeros,
		// in offline mode, we wait.
		//
		if (offline && !audioDone) {
			pthread_cond_wait(&bufferFull, &lock);
			
			goto checkBufferFull;
		}
		size_t	zeros	= inNumberFrames-numSamples;
		//
		// If we're starting, pad beginning, otherwise, pad end.
		//
		if (audioStarting) {
			memset(outSamp, 0, zeros*sizeof(float));
			memcpy(outSamp+zeros, sampleBuffer, numSamples*sizeof(float));
		} else {
			memcpy(outSamp, sampleBuffer, numSamples*sizeof(float));
			memset(outSamp+numSamples, 0, zeros*sizeof(float));
		}
		numSamples = 0;
	} else {
		memcpy(outSamp, sampleBuffer, inNumberFrames*sizeof(float));
		numSamples -= inNumberFrames;
		memmove(sampleBuffer, sampleBuffer+inNumberFrames, numSamples*sizeof(float));
	}
	audioStarting = false;
	pthread_mutex_unlock(&lock);	
	
	return noErr;
}

- (AudioUnit)getSourceUnit
{ 
	return outputUnit;	
}

- (AUGraph)getSourceGraph
{ 
	return audioGraph;		
}

- (void)setOfflineProcessing:(BOOL)off
{ 
	offline = off; 
}

- (BOOL)offlineProcessing
{ 
	return offline;	  
}

@end

////////////////////////////////////////// File Audio ///////////////////////////////////

@implementation AudioOutputFile

- (id)initWithFile:(ExtAudioFileRef)file
{
	audioFile = file;

	UInt32 		sz = sizeof(AudioFileID);
	ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_AudioFile, 
							&sz, &audioFileID);
	//
	// Try to avoid updating the file size after each write, as this tends to be
	// a very costly operation.
	//
	AudioFileOptimize(audioFileID);
	UInt32 defer = 0;
	AudioFileSetProperty(audioFileID, kAudioFilePropertyDeferSizeUpdates, 
						 sizeof(UInt32), &defer); 	
	ExtAudioFileSetProperty(audioFile, 
							kExtAudioFileProperty_ClientDataFormat,
							sizeof(sAudioFormatMono), &sAudioFormatMono);

	return self;
}

- (void)close
{
	AudioFileOptimize(audioFileID);
}

- (BOOL)audioDone
{
	AudioFileOptimize(audioFileID);
	return true;
}

- (void)queueSamples:(const float *)samples count:(size_t)sampleCount
{
	AudioBufferList buffer;
	buffer.mNumberBuffers				= 1;
	buffer.mBuffers[0].mNumberChannels	= 1;
	buffer.mBuffers[0].mDataByteSize	= (UInt32)(sampleCount*sizeof(float));
	buffer.mBuffers[0].mData			= (float *)samples;
	ExtAudioFileWrite(audioFile, (UInt32)sampleCount, &buffer);	
}

@end

