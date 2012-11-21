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
#include <AudioToolbox/AudioToolbox.h>

#include "CAXException.h"
// ____________________________________________________________________________________
// report a usage error and exit with an error.
static void	usage()
{
	fprintf(stderr,
	"usage: AQRecord [options] <recordfile>\n"
	"options:\n"
	"  -d <format>       specify file audio data format (e.g. 'lpcm', 'aac ' etc.; defaults to 16-bit big endian PCM)\n"
	"  -c <nchannels>    specify number of channels to record (2/stereo is the default)\n"
	"  -r <sample_rate>  specify sample rate; default is to use the hardware rate\n"
	"  -s <seconds>      record for a fixed period of time\n"
	"  -v                show verbose progress\n"
		);
	exit(2);
}

// ____________________________________________________________________________________
// report a missing argument for an option.
static void MissingArgument(const char *opt)
{
	fprintf(stderr, "Missing argument for option '%s'\n\n", opt);
	usage();
}

// ____________________________________________________________________________________
// report an unparseable argument
static void ParseError(const char *opt, const char *val)
{
	fprintf(stderr, "Couldn't parse argument '%s' for option '%s'\n\n", val, opt);
	usage();
}

// ____________________________________________________________________________________
// Convert a C string to a 4-char code.
// interpret hex literals such as "\x00".
// return number of characters parsed.
static int StrTo4CharCode(const char *str, FourCharCode *p4cc)
{
	char buf[4];
	const char *p = str;
	int i, x;
	for (i = 0; i < 4; ++i) {
		if (*p != '\\') {
			if ((buf[i] = *p++) == '\0') {
				// special-case for 'aac ': if we only got three characters, assume the last was a space
				if (i == 3) {
					--p;
					buf[i] = ' ';
					break;
				}
				goto fail;
			}
		} else {
			if (*++p != 'x') goto fail;
			if (sscanf(++p, "%02X", &x) != 1) goto fail;
			buf[i] = x;
			p += 2;
		}
	}
	*p4cc = CFSwapInt32BigToHost(*(UInt32 *)buf);
	return p - str;
fail:
	return 0;
}

// ____________________________________________________________________________________
// return true if testExt (should not include ".") is in the array "extensions".
static Boolean MatchExtension(CFArrayRef extensions, CFStringRef testExt)
{
	CFIndex n = CFArrayGetCount(extensions), i;
	for (i = 0; i < n; ++i) {
		CFStringRef ext = (CFStringRef)CFArrayGetValueAtIndex(extensions, i);
		if (CFStringCompare(testExt, ext, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
			return TRUE;
		}
	}
	return FALSE;
}

// ____________________________________________________________________________________
// Infer an audio file type from a filename's extension.
static Boolean InferAudioFileFormatFromFilename(CFStringRef filename, AudioFileTypeID *outFiletype)
{
	OSStatus err;
	
	// find the extension in the filename.
	CFRange range = CFStringFind(filename, CFSTR("."), kCFCompareBackwards);
	if (range.location == kCFNotFound)
		return FALSE;
	range.location += 1;
	range.length = CFStringGetLength(filename) - range.location;
	CFStringRef extension = CFStringCreateWithSubstring(NULL, filename, range);
	
	UInt32 propertySize = sizeof(AudioFileTypeID);
	err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_TypesForExtension, sizeof(extension), &extension, &propertySize, outFiletype);
	CFRelease(extension);
	
	return (err == noErr && propertySize > 0);
}

static Boolean MyFileFormatRequiresBigEndian(AudioFileTypeID audioFileType, int bitdepth)
{
	AudioFileTypeAndFormatID ftf;
	UInt32 propertySize;
	OSStatus err;
	Boolean requiresBigEndian;
	
	ftf.mFileType = audioFileType;
	ftf.mFormatID = kAudioFormatLinearPCM;
	
	err = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AvailableStreamDescriptionsForFormat, sizeof(ftf), &ftf, &propertySize);
	if (err) return FALSE;

	AudioStreamBasicDescription *formats = (AudioStreamBasicDescription *)malloc(propertySize);
	err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AvailableStreamDescriptionsForFormat, sizeof(ftf), &ftf, &propertySize, formats);
	requiresBigEndian = TRUE;
    if (err == noErr) {
        int i, nFormats = propertySize / sizeof(AudioStreamBasicDescription);
        for (i = 0; i < nFormats; ++i) {
            if (formats[i].mBitsPerChannel == bitdepth
                && !(formats[i].mFormatFlags & kLinearPCMFormatFlagIsBigEndian)) {
                requiresBigEndian = FALSE;
                break;
            }
        }
    }
	free(formats);
	return requiresBigEndian;
}

// ____________________________________________________________________________________
// ____________________________________________________________________________________
// ____________________________________________________________________________________


// custom data structure "MyRecorder"
// data we need during callback functions.

#define kNumberRecordBuffers	3

typedef struct MyRecorder {
	AudioQueueRef				queue;
	
	CFAbsoluteTime				queueStartStopTime;
	AudioFileID					recordFile;
	SInt64						recordPacket; // current packet number in record file
	Boolean						running;
	Boolean						verbose;
} MyRecorder;

// ____________________________________________________________________________________
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
static int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format, AudioQueueRef queue, float seconds)
{
	int packets, frames, bytes;
	
	frames = (int)ceil(seconds * format->mSampleRate);
	
	if (format->mBytesPerFrame > 0)
		bytes = frames * format->mBytesPerFrame;
	else {
		UInt32 maxPacketSize;
		if (format->mBytesPerPacket > 0)
			maxPacketSize = format->mBytesPerPacket;	// constant packet size
		else {
			UInt32 propertySize = sizeof(maxPacketSize); 
			XThrowIfError(AudioQueueGetProperty(queue, kAudioConverterPropertyMaximumOutputPacketSize, &maxPacketSize,
				&propertySize), "couldn't get queue's maximum output packet size");
		}
		if (format->mFramesPerPacket > 0)
			packets = frames / format->mFramesPerPacket;
		else
			packets = frames;	// worst-case scenario: 1 frame in a packet
		if (packets == 0)		// sanity check
			packets = 1;
		bytes = packets * maxPacketSize;
	}
	return bytes;
}

// ____________________________________________________________________________________
// Copy a queue's encoder's magic cookie to an audio file.
static void MyCopyEncoderCookieToFile(AudioQueueRef theQueue, AudioFileID theFile)
{
	OSStatus err;
	UInt32 propertySize;
	
	// get the magic cookie, if any, from the converter		
	err = AudioQueueGetPropertySize(theQueue, kAudioConverterCompressionMagicCookie, &propertySize);
	
	if (err == noErr && propertySize > 0) {
		// there is valid cookie data to be fetched;  get it
		Byte *magicCookie = (Byte *)malloc(propertySize);
		try {
			XThrowIfError(AudioQueueGetProperty(theQueue, kAudioConverterCompressionMagicCookie, magicCookie,
				&propertySize), "get audio converter's magic cookie");
			// now set the magic cookie on the output file
            // even though some formats have cookies, some files don't take them, so we ignore the error
			/*err =*/ AudioFileSetProperty(theFile, kAudioFilePropertyMagicCookieData, propertySize, magicCookie);
		} 
		catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "MyCopyEncoderCookieToFile: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
        catch (...) {
            fprintf(stderr, "MyCopyEncoderCookieToFile: Unexpected exception\n");
        }
		free(magicCookie);
	}
}

// ____________________________________________________________________________________
// AudioQueue callback function, called when a property changes.
static void MyPropertyListener(void *userData, AudioQueueRef queue, AudioQueuePropertyID propertyID)
{
	MyRecorder *aqr = (MyRecorder *)userData;
	if (propertyID == kAudioQueueProperty_IsRunning)
		aqr->queueStartStopTime = CFAbsoluteTimeGetCurrent();
}

// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
static void MyInputBufferHandler(	void *                          inUserData,
									AudioQueueRef                   inAQ,
									AudioQueueBufferRef             inBuffer,
									const AudioTimeStamp *          inStartTime,
									UInt32							inNumPackets,
									const AudioStreamPacketDescription *inPacketDesc)
{
	MyRecorder *aqr = (MyRecorder *)inUserData;

	try {
		if (aqr->verbose) {
			printf("buf data %p, 0x%x bytes, 0x%x packets\n", inBuffer->mAudioData,
				(int)inBuffer->mAudioDataByteSize, (int)inNumPackets);
		}
		
		if (inNumPackets > 0) {
			// write packets to file
			XThrowIfError(AudioFileWritePackets(aqr->recordFile, FALSE, inBuffer->mAudioDataByteSize,
				inPacketDesc, aqr->recordPacket, &inNumPackets, inBuffer->mAudioData),
				"AudioFileWritePackets failed");
			aqr->recordPacket += inNumPackets;
		}

		// if we're not stopping, re-enqueue the buffe so that it gets filled again
		if (aqr->running)
			XThrowIfError(AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
	} 
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "MyInputBufferHandler: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}	
}

// ____________________________________________________________________________________
// get sample rate of the default input device
OSStatus	MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate)
{
	OSStatus err;
	AudioDeviceID deviceID = 0;

	// get the default input device
	AudioObjectPropertyAddress addr;
	UInt32 size;
	addr.mSelector = kAudioHardwarePropertyDefaultInputDevice;
	addr.mScope = kAudioObjectPropertyScopeGlobal;
	addr.mElement = 0;
	size = sizeof(AudioDeviceID);
	err = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &deviceID);
	if (err) return err;

	// get its sample rate
	addr.mSelector = kAudioDevicePropertyNominalSampleRate;
	addr.mScope = kAudioObjectPropertyScopeGlobal;
	addr.mElement = 0;
	size = sizeof(Float64);
	err = AudioHardwareServiceGetPropertyData(deviceID, &addr, 0, NULL, &size, outSampleRate);

	return err;
}

// ____________________________________________________________________________________
// main program
int	main(int argc, const char *argv[])
{
	const char *recordFileName = NULL;
	int i, nchannels, bufferByteSize;
	float seconds = 0;
	AudioStreamBasicDescription recordFormat;
	MyRecorder aqr;
	UInt32 size;
	CFURLRef url;
    OSStatus err = noErr;
	
	// fill structures with 0/NULL
	memset(&recordFormat, 0, sizeof(recordFormat));
	memset(&aqr, 0, sizeof(aqr));
	
	// parse arguments
	for (i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		
		if (arg[0] == '-') {
			switch (arg[1]) {
			case 'c':
				if (++i == argc) MissingArgument(arg);
				if (sscanf(argv[i], "%d", &nchannels) != 1)
					usage();
				recordFormat.mChannelsPerFrame = nchannels;
				break;
			case 'd':
				if (++i == argc) MissingArgument(arg);
				if (StrTo4CharCode(argv[i], &recordFormat.mFormatID) == 0)
					ParseError(arg, argv[i]);
				break;
			case 'r':
				if (++i == argc) MissingArgument(arg);
				if (sscanf(argv[i], "%lf", &recordFormat.mSampleRate) != 1)
					ParseError(arg, argv[i]);
				break;
			case 's':
				if (++i == argc) MissingArgument(arg);
				if (sscanf(argv[i], "%f", &seconds) != 1)
					ParseError(arg, argv[i]);
				break;
			case 'v':
				aqr.verbose = TRUE;
				break;
			default:
				fprintf(stderr, "unknown option: '%s'\n\n", arg);
				usage();
			}
		} else if (recordFileName != NULL) {
			fprintf(stderr, "may only specify one file to record\n\n");
			usage();
		} else
			recordFileName = arg;
	}
	if (recordFileName == NULL) // no record file path provided
		usage();
	
	// determine file format
	AudioFileTypeID audioFileType = kAudioFileCAFType;	// default to CAF
	CFStringRef cfRecordFileName = CFStringCreateWithCString(NULL, recordFileName, kCFStringEncodingUTF8);
	InferAudioFileFormatFromFilename(cfRecordFileName, &audioFileType);
	CFRelease(cfRecordFileName);

	// adapt record format to hardware and apply defaults
	if (recordFormat.mSampleRate == 0.)
		MyGetDefaultInputDeviceSampleRate(&recordFormat.mSampleRate);

	if (recordFormat.mChannelsPerFrame == 0)
		recordFormat.mChannelsPerFrame = 2;
	
	if (recordFormat.mFormatID == 0 || recordFormat.mFormatID == kAudioFormatLinearPCM) {
		// default to PCM, 16 bit int
		recordFormat.mFormatID = kAudioFormatLinearPCM;
		recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		recordFormat.mBitsPerChannel = 16;
		if (MyFileFormatRequiresBigEndian(audioFileType, recordFormat.mBitsPerChannel))
			recordFormat.mFormatFlags |= kLinearPCMFormatFlagIsBigEndian;
		recordFormat.mBytesPerPacket = recordFormat.mBytesPerFrame =
			(recordFormat.mBitsPerChannel / 8) * recordFormat.mChannelsPerFrame;
		recordFormat.mFramesPerPacket = 1;
		recordFormat.mReserved = 0;
	}

	try {
		// create the queue
		XThrowIfError(AudioQueueNewInput(
			&recordFormat,
			MyInputBufferHandler,
			&aqr /* userData */,
			NULL /* run loop */, NULL /* run loop mode */,
			0 /* flags */, &aqr.queue), "AudioQueueNewInput failed");

		// get the record format back from the queue's audio converter --
		// the file may require a more specific stream description than was necessary to create the encoder.
		size = sizeof(recordFormat);
		XThrowIfError(AudioQueueGetProperty(aqr.queue, kAudioConverterCurrentOutputStreamDescription,
			&recordFormat, &size), "couldn't get queue's format");

		// convert recordFileName from C string to CFURL
		url = CFURLCreateFromFileSystemRepresentation(NULL, (Byte *)recordFileName, strlen(recordFileName), FALSE);
		XThrowIfError(!url, "couldn't create record file");
        
		// create the audio file
        err = AudioFileCreateWithURL(url, audioFileType, &recordFormat, kAudioFileFlags_EraseFile,
                                              &aqr.recordFile);
        CFRelease(url); // release first, and then bail out on error
		XThrowIfError(err, "AudioFileCreateWithURL failed");
		

		// copy the cookie first to give the file object as much info as we can about the data going in
		MyCopyEncoderCookieToFile(aqr.queue, aqr.recordFile);

		// allocate and enqueue buffers
		bufferByteSize = MyComputeRecordBufferSize(&recordFormat, aqr.queue, 0.5);	// enough bytes for half a second
		for (i = 0; i < kNumberRecordBuffers; ++i) {
			AudioQueueBufferRef buffer;
			XThrowIfError(AudioQueueAllocateBuffer(aqr.queue, bufferByteSize, &buffer),
				"AudioQueueAllocateBuffer failed");
			XThrowIfError(AudioQueueEnqueueBuffer(aqr.queue, buffer, 0, NULL),
				"AudioQueueEnqueueBuffer failed");
		}
		
		// record
		if (seconds > 0) {
			// user requested a fixed-length recording (specified a duration with -s)
			// to time the recording more accurately, watch the queue's IsRunning property
			XThrowIfError(AudioQueueAddPropertyListener(aqr.queue, kAudioQueueProperty_IsRunning,
				MyPropertyListener, &aqr), "AudioQueueAddPropertyListener failed");
			
			// start the queue
			aqr.running = TRUE;
			XThrowIfError(AudioQueueStart(aqr.queue, NULL), "AudioQueueStart failed");
			CFAbsoluteTime waitUntil = CFAbsoluteTimeGetCurrent() + 10;

			// wait for the started notification
			while (aqr.queueStartStopTime == 0.) {
				CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.010, FALSE);
				if (CFAbsoluteTimeGetCurrent() >= waitUntil) {
					fprintf(stderr, "Timeout waiting for the queue's IsRunning notification\n");
					goto cleanup;
				}
			}
			printf("Recording...\n");
			CFAbsoluteTime stopTime = aqr.queueStartStopTime + seconds;
			CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, stopTime - now, FALSE);
		} else {
			// start the queue
			aqr.running = TRUE;
			XThrowIfError(AudioQueueStart(aqr.queue, NULL), "AudioQueueStart failed");
			
			// and wait
			printf("Recording, press <return> to stop:\n");
			getchar();
		}

		// end recording
		printf("* recording done *\n");
		
		aqr.running = FALSE;
		XThrowIfError(AudioQueueStop(aqr.queue, TRUE), "AudioQueueStop failed");
		
		// a codec may update its cookie at the end of an encoding session, so reapply it to the file now
		MyCopyEncoderCookieToFile(aqr.queue, aqr.recordFile);
		
cleanup:
		AudioQueueDispose(aqr.queue, TRUE);
		AudioFileClose(aqr.recordFile);
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "MyInputBufferHandler: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return e.mError;
	}
		
	return 0;
}
