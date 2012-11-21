/*	Copyright © 2007 Apple Inc. All Rights Reserved.
	
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
// TODO: CoreFlat include defines...
#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <AudioToolbox/AudioQueue.h>
	#include <AudioToolbox/AudioFile.h>
	#include <AudioToolbox/AudioFormat.h>
#else
	#include "AudioQueue.h"
	#include "AudioFile.h"
	#include "AudioFormat.h"
#endif
#if TARGET_OS_WIN32
	#include "QTML.h"
#endif
// helpers
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "CAAudioFileFormats.h"

static const int kNumberBuffers = 3;
static UInt32 gIsRunning = 0;

struct AQTestInfo {
	AudioFileID						mAudioFile;
	CAStreamBasicDescription		mDataFormat;
	AudioChannelLayout *			mChannelLayout;
	UInt32							mChannelLayoutSize;
	AudioQueueRef					mQueue;
	AudioQueueBufferRef				mBuffers[kNumberBuffers];
	SInt64							mCurrentPacket;
	UInt32							mNumPacketsToRead;
	AudioStreamPacketDescription *	mPacketDescs;
	bool							mDone;
	
	AQTestInfo ()
		: mChannelLayout (NULL),
		  mPacketDescs(NULL)
		  {}
	
	~AQTestInfo ()
	{
		delete [] mChannelLayout;
		delete [] mPacketDescs;
	}
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

		AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, (myInfo->mPacketDescs ? nPackets : 0), myInfo->mPacketDescs);
		
		myInfo->mCurrentPacket += nPackets;
	} else {
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
#if !TARGET_OS_WIN32
	const char *progname = getprogname();
#else
	const char *progname = "aqplay";
#endif
	fprintf(stderr,
			"Usage:\n"
			"%s [option...] audio_file\n\n"
			"Options: (may appear before or after arguments)\n"
			"  {-v | --volume} VOLUME\n"
			"    set the volume for playback of the file\n"
			"  {-h | --help}\n"
			"    print help\n"
			"  {-t | --time} TIME\n"
			"    play for TIME seconds\n"
			"  {-r | --rate} RATE\n"
			"    play at playback rate\n"
			"  {-q | --rQuality} QUALITY\n"
			"    set the quality used for rate-scaled playback (default is 0 - low quality, 1 - high quality)\n"
			"  {-d | --debug}\n"
			"    debug print output\n"			
			, progname);
	exit(1);
}

void	MissingArgument()
{
	fprintf(stderr, "Missing argument\n");
	usage();
}

void	MyAudioQueuePropertyListenerProc (  void *              inUserData,
										AudioQueueRef           inAQ,
										AudioQueuePropertyID    inID)
{
	UInt32 size = sizeof(gIsRunning);
	OSStatus err = AudioQueueGetProperty (inAQ, kAudioQueueProperty_IsRunning, &gIsRunning, &size);
	if (err) 
		gIsRunning = 0;
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
#if TARGET_OS_WIN32
	InitializeQTML(0L);
#endif
	const char *fpath = NULL;
	Float32 volume = 1;
	Float32 duration = -1;
	Float32 currentTime = 0.0;
	Float32 rate = 0;
	int rQuality = 0;
	
	bool doPrint = false;
	for (int i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		if (arg[0] != '-') {
			if (fpath != NULL) {
				fprintf(stderr, "may only specify one file to play\n");
				usage();
			}
			fpath = arg;
		} else {
			arg += 1;
			if (arg[0] == 'v' || !strcmp(arg, "-volume")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];
				sscanf(arg, "%f", &volume);
			} else if (arg[0] == 't' || !strcmp(arg, "-time")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];				
				sscanf(arg, "%f", &duration);
			} else if (arg[0] == 'r' || !strcmp(arg, "-rate")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];				
				sscanf(arg, "%f", &rate);
			} else if (arg[0] == 'q' || !strcmp(arg, "-rQuality")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];				
				sscanf(arg, "%d", &rQuality);
			} else if (arg[0] == 'h' || !strcmp(arg, "-help")) {
				usage();
			} else if (arg[0] == 'd' || !strcmp(arg, "-debug")) {
				doPrint = true;
			} else {
				fprintf(stderr, "unknown argument: %s\n\n", arg - 1);
				usage();
			}
		}
	}

	if (fpath == NULL)
		usage();
	
	if (doPrint)
		printf ("Playing file: %s\n", fpath);
	
	try {
		AQTestInfo myInfo;
		
		CFURLRef sndFile = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)fpath, strlen(fpath), false);
		if (!sndFile) XThrowIfError (!sndFile, "can't parse file path");
			
		OSStatus result = AudioFileOpenURL (sndFile, 0x1/*fsRdPerm*/, 0/*inFileTypeHint*/, &myInfo.mAudioFile);
		CFRelease (sndFile);
						
		XThrowIfError(result, "AudioFileOpen failed");
		
		UInt32 size;
		XThrowIfError(AudioFileGetPropertyInfo(myInfo.mAudioFile, 
									kAudioFilePropertyFormatList, &size, NULL), "couldn't get file's format list info");
		UInt32 numFormats = size / sizeof(AudioFormatListItem);
		AudioFormatListItem *formatList = new AudioFormatListItem [ numFormats ];

		XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, 
									kAudioFilePropertyFormatList, &size, formatList), "couldn't get file's data format");
		numFormats = size / sizeof(AudioFormatListItem); // we need to reassess the actual number of formats when we get it
		if (numFormats == 1) {
				// this is the common case
			myInfo.mDataFormat = formatList[0].mASBD;
			
				// see if there is a channel layout (multichannel file)
			result = AudioFileGetPropertyInfo(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &myInfo.mChannelLayoutSize, NULL);
			if (result == noErr && myInfo.mChannelLayoutSize > 0) {
				myInfo.mChannelLayout = (AudioChannelLayout *)new char [myInfo.mChannelLayoutSize];
				XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &myInfo.mChannelLayoutSize, myInfo.mChannelLayout), "get audio file's channel layout");
			}
		} else {
			if (doPrint) {
				printf ("File has a %d layered data format:\n", (int)numFormats);
				for (unsigned int i = 0; i < numFormats; ++i)
					CAStreamBasicDescription(formatList[i].mASBD).Print();
			}
			// now we should look to see which decoders we have on the system
			XThrowIfError(AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size), "couldn't get decoder id's");
			UInt32 numDecoders = size / sizeof(OSType);
			OSType *decoderIDs = new OSType [ numDecoders ];
			XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDs), "couldn't get decoder id's");			
			unsigned int i = 0;
			for (; i < numFormats; ++i) {
				OSType decoderID = formatList[i].mASBD.mFormatID;
				bool found = false;
				for (unsigned int j = 0; j < numDecoders; ++j) {
					if (decoderID == decoderIDs[j]) {
						found = true;
						break;
					}
				}
				if (found) break;
			}
			delete [] decoderIDs;
			
			if (i >= numFormats) {
				fprintf (stderr, "Cannot play any of the formats in this file\n");
				throw kAudioFileUnsupportedDataFormatError;
			}
			myInfo.mDataFormat = formatList[i].mASBD;
			myInfo.mChannelLayoutSize = sizeof(AudioChannelLayout);
			myInfo.mChannelLayout = (AudioChannelLayout*)new char [myInfo.mChannelLayoutSize];
			myInfo.mChannelLayout->mChannelLayoutTag = formatList[i].mChannelLayoutTag;
			myInfo.mChannelLayout->mChannelBitmap = 0;
			myInfo.mChannelLayout->mNumberChannelDescriptions = 0;
		}
		delete [] formatList;
		
		if (doPrint) {
			printf ("Playing format: "); 
			myInfo.mDataFormat.Print();
		}
		
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
			
			// adjust buffer size to represent about a half second of audio based on this format
			CalculateBytesForTime (myInfo.mDataFormat, maxPacketSize, 0.5/*seconds*/, &bufferByteSize, &myInfo.mNumPacketsToRead);
			
			if (isFormatVBR)
				myInfo.mPacketDescs = new AudioStreamPacketDescription [myInfo.mNumPacketsToRead];
			else
				myInfo.mPacketDescs = NULL; // we don't provide packet descriptions for constant bit rate formats (like linear PCM)
				
			if (doPrint)
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

		// set ACL if there is one
		if (myInfo.mChannelLayout)
			XThrowIfError(AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_ChannelLayout, myInfo.mChannelLayout, myInfo.mChannelLayoutSize), "set channel layout on queue");

		// prime the queue with some data before starting
		myInfo.mDone = false;
		myInfo.mCurrentPacket = 0;
		for (int i = 0; i < kNumberBuffers; ++i) {
			XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, bufferByteSize, &myInfo.mBuffers[i]), "AudioQueueAllocateBuffer failed");

			AQTestBufferCallback (&myInfo, myInfo.mQueue, myInfo.mBuffers[i]);
			
			if (myInfo.mDone) break;
		}	
			// set the volume of the queue
		XThrowIfError (AudioQueueSetParameter(myInfo.mQueue, kAudioQueueParam_Volume, volume), "set queue volume");
		
		XThrowIfError (AudioQueueAddPropertyListener (myInfo.mQueue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, NULL), "add listener");
		
#if !TARGET_OS_IPHONE
		if (rate > 0) {
			UInt32 propValue = 1;
			XThrowIfError (AudioQueueSetProperty (myInfo.mQueue, kAudioQueueProperty_EnableTimePitch, &propValue, sizeof(propValue)), "enable time pitch");
			
			propValue = rQuality ? kAudioQueueTimePitchAlgorithm_Spectral : kAudioQueueTimePitchAlgorithm_TimeDomain;
			XThrowIfError (AudioQueueSetProperty (myInfo.mQueue, kAudioQueueProperty_TimePitchAlgorithm, &propValue, sizeof(propValue)), "time pitch algorithm");
			
			propValue = (rate == 1.0f ? 1 : 0); // bypass rate if 1.0
			XThrowIfError (AudioQueueSetProperty (myInfo.mQueue, kAudioQueueProperty_TimePitchBypass, &propValue, sizeof(propValue)), "bypass time pitch");
			if (rate != 1) {
				XThrowIfError (AudioQueueSetParameter (myInfo.mQueue, kAudioQueueParam_PlayRate, rate), "set playback rate");
			}
			
			if (doPrint) {
				printf ("Enable rate-scaled playback (rate = %.2f) using %s algorithm\n", rate, (rQuality ? "Spectral": "Time Domain"));
			}
		}
#endif
			// lets start playing now - stop is called in the AQTestBufferCallback when there's
			// no more to read from the file
		XThrowIfError(AudioQueueStart(myInfo.mQueue, NULL), "AudioQueueStart failed");

		do {
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
			currentTime += .25;
			if (duration > 0 && currentTime >= duration)
				break;
			
		} while (gIsRunning);
			
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

		XThrowIfError(AudioQueueDispose(myInfo.mQueue, true), "AudioQueueDispose(true) failed");
		XThrowIfError(AudioFileClose(myInfo.mAudioFile), "AudioQueueDispose(false) failed");
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	catch (...) {
		fprintf(stderr, "Unspecified exception\n");
	}
	
    return 0;
}
