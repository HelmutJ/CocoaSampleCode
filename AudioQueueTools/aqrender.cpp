/*	Copyright � 2007 Apple Inc. All Rights Reserved.
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
			Apple Inc. ("Apple") in consideration of your agreement to the
			following terms, and your use, installation, modification or
			redistribution of this Apple software constitutes acceptance of these
			terms.  If you do not agree with these terms, please do not use,
			install, modify or redistribute this Apple software.
			
			In consideration of your agreement to abide by the following terms, and
			subject to these terms, Apple grants you a personal, non-exclusive
			license, under Apple's copyrights in this original Apple software (the
			"Apple Software"), to use, reproduce, modify and redistribute the Apple
			Software, with or without modifications, in source and/or binary forms;
			provided that if you redistribute the Apple Software in its entirety and
			without modifications, you must retain this notice and the following
			text and disclaimers in all such redistributions of the Apple Software. 
			Neither the name, trademarks, service marks or logos of Apple Inc. 
			may be used to endorse or promote products derived from the Apple
			Software without specific prior written permission from Apple.  Except
			as expressly stated in this notice, no other rights or licenses, express
			or implied, are granted by Apple herein, including but not limited to
			any patent rights that may be infringed by your derivative works or by
			other works in which the Apple Software may be incorporated.
			
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
*/
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/ExtendedAudioFile.h>

// helpers
#include "CABufferList.h"
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

static const int kNumberBuffers = 3;


struct AQTestInfo {
	AudioFileID						mAudioFile;
	CAStreamBasicDescription		mDataFormat;
	AudioQueueRef					mQueue;
	AudioQueueBufferRef				mBuffer;
	SInt64							mCurrentPacket;
	UInt32							mNumPacketsToRead;
	AudioStreamPacketDescription *	mPacketDescs;
	bool							mFlushed;
	bool							mDone;
};

static void AQTestBufferCallback(void *					inUserData,
								AudioQueueRef			inAQ,
								AudioQueueBufferRef		inCompleteAQBuffer) 
{
	AQTestInfo * myInfo = (AQTestInfo *)inUserData;
	if (myInfo->mDone) return;
		
	UInt32 numBytes;
	UInt32 nPackets = myInfo->mNumPacketsToRead;
	OSStatus result = AudioFileReadPackets(myInfo->mAudioFile, false, &numBytes, myInfo->mPacketDescs, myInfo->mCurrentPacket, &nPackets, 
								inCompleteAQBuffer->mAudioData);
	if (result) {
		DebugMessageN1 ("Error reading from file: %d\n", (int)result);
		exit(1);
	}
	if (nPackets > 0) {
		inCompleteAQBuffer->mAudioDataByteSize = numBytes;
		result = AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, (myInfo->mPacketDescs ? nPackets : 0), myInfo->mPacketDescs);
		if (result) {
			DebugMessageN1 ("Error enqueuing buffer: %d\n", (int)result);
			exit(1);
		}
		myInfo->mCurrentPacket += nPackets;
	} else {
		if (!myInfo->mFlushed) {
			result = AudioQueueFlush(myInfo->mQueue);
			if (result) {
				DebugMessageN1("AudioQueueFlush failed: %d", (int)result);
				exit(1);
			}
			myInfo->mFlushed = true;
		}
		
		result = AudioQueueStop(myInfo->mQueue, false);
		if (result) {
			DebugMessageN1 ("AudioQueueStop(false) failed: %d", (int)result);
			exit(1);
		}
		// reading nPackets == 0 is our EOF condition
		myInfo->mDone = true;
	}
}

static void usage()
{
	fprintf(stderr,
			"Usage:\n"
			"%s [option...] input_file output_file\n\n"
			"Options: (may appear before or after arguments)\n"
			"  {-v | --volume} VOLUME\n"
			"    set the volume for playback of the file\n"
			"  {-h | --help}\n"
			"    print help\n"
			, "aqrender");
	exit(1);
}

void	MissingArgument()
{
	fprintf(stderr, "Missing argument\n");
	usage();
}

	// we only use time here as a guideline
	// we're really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
void CalculateBytesForTime (CAStreamBasicDescription & inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
	static const int maxBufferSize = 0x10000; // limit size to 64K
	static const int minBufferSize = 0x4000; // limit size to 16K

	if (inDesc.mFramesPerPacket) {
		Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
		*outBufferSize = numPacketsForTime * inMaxPacketSize;
	} else {
		// if frames per packet is zero, then the codec has no predictable packet == time
		// so we can't tailor this (we don't know how many Packets represent a time period
		// we'll just return a default buffer size
		*outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
	}
	
		// we're going to limit our size to our default
	if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize)
		*outBufferSize = maxBufferSize;
	else {
		// also make sure we're not too small - we don't want to go the disk for too small chunks
		if (*outBufferSize < minBufferSize)
			*outBufferSize = minBufferSize;
	}
	*outNumPackets = *outBufferSize / inMaxPacketSize;
}


int main (int argc, const char * argv[]) 
{
	const char *inputPath = NULL;
	const char *outputPath = NULL;

	Float32 volume = 1.;
	
	for (int i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		if (arg[0] != '-') {
			if (inputPath != NULL) {
				if (outputPath != NULL)
				{
					fprintf(stderr, "may only specify one file to play\n");
					usage();
				}
				outputPath = arg;
			}
			else
				inputPath = arg;
		} else {
			arg += 1;
			if (arg[0] == 'v' || !strcmp(arg, "-volume")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];
				sscanf(arg, "%f", &volume);
			} else if (arg[0] == 'h' || !strcmp(arg, "-help")) {
				usage();
			} else {
				fprintf(stderr, "unknown argument: %s\n\n", arg - 1);
				usage();
			}
		}
	}

	if ((inputPath == NULL) || (outputPath == NULL))
		usage();
	
	printf ("Rendering file: %s to %s\n", inputPath, outputPath);
	
    AudioChannelLayout *acl = NULL;
	try {
		AQTestInfo myInfo;
		myInfo.mDone = false;
		myInfo.mFlushed = false;
		myInfo.mCurrentPacket = 0;
		
		CFURLRef srcFile = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)inputPath, strlen(inputPath), false);
		if (!srcFile) XThrowIfError (!srcFile, "can't parse file path");
			
		OSStatus result = AudioFileOpenURL (srcFile, 0x1/*fsRdPerm*/, 0/*inFileTypeHint*/, &myInfo.mAudioFile);
		CFRelease (srcFile);
						
		XThrowIfError(result, "AudioFileOpen failed");
			
		UInt32 size = sizeof(myInfo.mDataFormat);
		XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, 
									kAudioFilePropertyDataFormat, &size, &myInfo.mDataFormat), "couldn't get file's data format");
		
		printf ("File format: "); myInfo.mDataFormat.Print();

		XThrowIfError(AudioQueueNewOutput(&myInfo.mDataFormat, AQTestBufferCallback, &myInfo, 
									CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myInfo.mQueue), "AudioQueueNew failed");

		UInt32 bufferByteSize;
		
		// we need to calculate how many packets we read at a time, and how big a buffer we need
		// we base this on the size of the packets in the file and an approximate duration for each buffer
		{
			bool isFormatVBR = (myInfo.mDataFormat.mBytesPerPacket == 0 || myInfo.mDataFormat.mFramesPerPacket == 0);
			
			// first check to see what the max size of a packet is - if it is bigger
			// than our allocation default size, that needs to become larger
			UInt32 maxPacketSize;
			size = sizeof(maxPacketSize);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, 
									kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize), "couldn't get file's max packet size");
			
			// adjust buffer size to represent about a second of audio based on this format
			CalculateBytesForTime (myInfo.mDataFormat, maxPacketSize, 1.0/*seconds*/, &bufferByteSize, &myInfo.mNumPacketsToRead);
			
			if (isFormatVBR)
				myInfo.mPacketDescs = new AudioStreamPacketDescription [myInfo.mNumPacketsToRead];
			else
				myInfo.mPacketDescs = NULL; // we don't provide packet descriptions for constant bit rate formats (like linear PCM)
				
			printf ("Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)myInfo.mNumPacketsToRead);
		}

		// (2) If the file has a cookie, we should get it and set it on the AQ
		size = sizeof(UInt32);
		result = AudioFileGetPropertyInfo (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);

		if (!result && size) {
			char* cookie = new char [size];		
			XThrowIfError (AudioFileGetProperty (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie), "get cookie from file");
			XThrowIfError (AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_MagicCookie, cookie, size), "set cookie on queue");
			delete [] cookie;
		}

		// channel layout?
		OSStatus err = AudioFileGetPropertyInfo(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, NULL);
		if (err == noErr && size > 0) {
			acl = (AudioChannelLayout *)malloc(size);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, acl), "get audio file's channel layout");
			XThrowIfError(AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_ChannelLayout, acl, size), "set channel layout on queue");
		}

		//allocate the read buffer
		XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, bufferByteSize, &myInfo.mBuffer), "AudioQueueAllocateBuffer");

		// prepare a canonical interleaved capture format
		CAStreamBasicDescription captureFormat;
		captureFormat.mSampleRate = myInfo.mDataFormat.mSampleRate;
		captureFormat.SetAUCanonical(myInfo.mDataFormat.mChannelsPerFrame, true);	// interleaved
		XThrowIfError (AudioQueueSetOfflineRenderFormat(myInfo.mQueue, &captureFormat, acl), "set offline render format");			
		
		ExtAudioFileRef captureFile;
		// prepare a 16-bit int file format, sample channel count and sample rate
		CAStreamBasicDescription dstFormat;
		dstFormat.mSampleRate = myInfo.mDataFormat.mSampleRate;
		dstFormat.mChannelsPerFrame = myInfo.mDataFormat.mChannelsPerFrame;
		dstFormat.mFormatID = kAudioFormatLinearPCM;
		dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger; // little-endian
		dstFormat.mBitsPerChannel = 16;
		dstFormat.mBytesPerPacket = dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame;
		dstFormat.mFramesPerPacket = 1;

		
		// create the capture file
		CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (Byte *)outputPath, strlen(outputPath), false);
        XThrowIfError (!url, "can't create capture file");
		result = ExtAudioFileCreateWithURL(url, kAudioFileCAFType, &dstFormat, acl, kAudioFileFlags_EraseFile, &captureFile);
        CFRelease (url);
		XThrowIfError(result, "ExtAudioFileCreateWithURL failed");
        
		// set the capture file's client format to be the canonical format from the queue
		XThrowIfError(ExtAudioFileSetProperty(captureFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &captureFormat), "set ExtAudioFile client format");
		
		// allocate the capture buffer, keep at half the size of the enqueue buffer
		const UInt32 captureBufferByteSize = bufferByteSize / 2;
		AudioQueueBufferRef captureBuffer;
		AudioBufferList captureABL;
		
		XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, captureBufferByteSize, &captureBuffer), "AudioQueueAllocateBuffer");
		captureABL.mNumberBuffers = 1;
		captureABL.mBuffers[0].mData = captureBuffer->mAudioData;
		captureABL.mBuffers[0].mNumberChannels = captureFormat.mChannelsPerFrame;
		
		XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, captureBufferByteSize, &captureBuffer), "AudioQueueAllocateBuffer");		
		
		// set the volume of the queue
		XThrowIfError (AudioQueueSetParameter(myInfo.mQueue, kAudioQueueParam_Volume, volume), "set queue volume");

		// lets start playing now - stop is called in the AQTestBufferCallback when there's
		// no more to read from the file
		XThrowIfError(AudioQueueStart(myInfo.mQueue, NULL), "AudioQueueStart failed");

		AudioTimeStamp ts;
		ts.mFlags = kAudioTimeStampSampleTimeValid;
		ts.mSampleTime = 0;

		// we need to call this once asking for 0 frames
		XThrowIfError(AudioQueueOfflineRender(myInfo.mQueue, &ts, captureBuffer, 0), "AudioQueueOfflineRender");

		// we need to enqueue a buffer after the queue has started
		AQTestBufferCallback (&myInfo, myInfo.mQueue, myInfo.mBuffer);

		while (true) {
			UInt32 reqFrames = captureBufferByteSize / captureFormat.mBytesPerFrame;
			XThrowIfError(AudioQueueOfflineRender(myInfo.mQueue, &ts, captureBuffer, reqFrames), "AudioQueueOfflineRender");
			captureABL.mBuffers[0].mData = captureBuffer->mAudioData;
			captureABL.mBuffers[0].mDataByteSize = captureBuffer->mAudioDataByteSize;
			UInt32 writeFrames = captureABL.mBuffers[0].mDataByteSize / captureFormat.mBytesPerFrame;
			printf("t = %.f: AudioQueueOfflineRender:  req %d fr/%d bytes, got %d fr/%d bytes\n", ts.mSampleTime, (int)reqFrames, (int)captureBufferByteSize, (int)writeFrames, (int)captureABL.mBuffers[0].mDataByteSize);
			if (writeFrames == 0) break;
			XThrowIfError(ExtAudioFileWrite(captureFile, writeFrames, &captureABL), "ExtAudioFileWrite");
			if (myInfo.mFlushed) break;
			
			ts.mSampleTime += writeFrames;
		}

		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

		XThrowIfError(AudioQueueDispose(myInfo.mQueue, true), "AudioQueueDispose(true) failed");
		XThrowIfError(AudioFileClose(myInfo.mAudioFile), "AudioQueueDispose(false) failed");
		XThrowIfError(ExtAudioFileDispose(captureFile), "ExtAudioFileDispose failed");

		delete [] myInfo.mPacketDescs;
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
    catch (...) {
        fprintf(stderr, "Error: Unexpected exception\n");
    }
    
    free(acl); // free channel layout buffer
    	
    return 0;
}


