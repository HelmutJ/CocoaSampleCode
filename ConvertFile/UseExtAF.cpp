/*	Copyright © 2010 Apple Inc. All Rights Reserved.
	
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

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
	#include <AudioToolbox/AudioToolbox.h>
#else
	#include "AudioToolbox.h"
	#include "ExtendedAudioFile.h"
#endif

#include "CAStreamBasicDescription.h"
#include "CAXException.h"

const UInt32 kSrcBufSize = 32768;

int ConvertFile (CFURLRef					inputFileURL, 
				CAStreamBasicDescription	&inputFormat,
				CFURLRef					outputFileURL,
				AudioFileTypeID				outputFileType, 
				CAStreamBasicDescription	&outputFormat,
				UInt32                      outputBitRate)
{
	ExtAudioFileRef infile, outfile;

// first open the input file
	OSStatus err = ExtAudioFileOpenURL (inputFileURL, &infile);
	XThrowIfError (err, "ExtAudioFileOpen");
	
	// if outputBitRate is specified, this can change the sample rate of the output file
	// so we let this "take care of itself"
	if (outputBitRate)
		outputFormat.mSampleRate = 0.;
		
	// create the output file (this will erase an exsiting file)
	err = ExtAudioFileCreateWithURL (outputFileURL, outputFileType, &outputFormat, NULL, kAudioFileFlags_EraseFile, &outfile);
	XThrowIfError (err, "ExtAudioFileCreateNew");
	
	// get and set the client format - it should be lpcm
	CAStreamBasicDescription clientFormat = (inputFormat.mFormatID == kAudioFormatLinearPCM ? inputFormat : outputFormat);
	UInt32 size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(infile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	XThrowIfError (err, "ExtAudioFileSetProperty inFile, kExtAudioFileProperty_ClientDataFormat");
	
	size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	XThrowIfError (err, "ExtAudioFileSetProperty outFile, kExtAudioFileProperty_ClientDataFormat");
	
	if( outputBitRate > 0 ) {
		printf ("Dest bit rate: %d\n", (int)outputBitRate);
		AudioConverterRef outConverter;
		size = sizeof(outConverter);
		err = ExtAudioFileGetProperty(outfile, kExtAudioFileProperty_AudioConverter, &size, &outConverter);
		XThrowIfError (err, "ExtAudioFileGetProperty outFile, kExtAudioFileProperty_AudioConverter");
		
		err = AudioConverterSetProperty(outConverter, kAudioConverterEncodeBitRate, 
										sizeof(outputBitRate), &outputBitRate);
		XThrowIfError (err, "AudioConverterSetProperty, kAudioConverterEncodeBitRate");
		
		// we have changed the converter, so we should do this in case 
		// setting a converter property changes the converter used by ExtAF in some manner
		CFArrayRef config = NULL;
		err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ConverterConfig, sizeof(config), &config);
		XThrowIfError (err, "ExtAudioFileSetProperty outFile, kExtAudioFileProperty_ConverterConfig");
	}
	
	// set up buffers
	char srcBuffer[kSrcBufSize];

	// do the read and write - the conversion is done on and by the write call
	while (1) 
	{	
		AudioBufferList fillBufList;
		fillBufList.mNumberBuffers = 1;
		fillBufList.mBuffers[0].mNumberChannels = inputFormat.mChannelsPerFrame;
		fillBufList.mBuffers[0].mDataByteSize = kSrcBufSize;
		fillBufList.mBuffers[0].mData = srcBuffer;
			
		// client format is always linear PCM - so here we determine how many frames of lpcm
		// we can read/write given our buffer size
		UInt32 numFrames = (kSrcBufSize / clientFormat.mBytesPerFrame);
		
		// printf("test %d\n", numFrames);

		err = ExtAudioFileRead (infile, &numFrames, &fillBufList);
		XThrowIfError (err, "ExtAudioFileRead");	
		if (!numFrames) {
			// this is our termination condition
			break;
		}
		
		err = ExtAudioFileWrite(outfile, numFrames, &fillBufList);	
		XThrowIfError (err, "ExtAudioFileWrite");	
	}
		
// close
	ExtAudioFileDispose(outfile);
	ExtAudioFileDispose(infile);
	
    return 0;
}

