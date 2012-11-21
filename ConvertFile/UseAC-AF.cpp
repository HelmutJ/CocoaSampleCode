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
	#include <CoreFoundation/CoreFoundation.h>
#else
	#include "AudioToolbox.h"
	#include "CoreFoundation.h"
#endif

#include "CAStreamBasicDescription.h"
#include "CAXException.h"


// a struct to hold info for the input data proc

struct AudioFileIO
{
	AudioFileID		afid;
	SInt64			pos;
	char *			srcBuffer;
	UInt32			srcBufferSize;
	CAStreamBasicDescription srcFormat;
	UInt32			srcSizePerPacket;
	UInt32			numPacketsPerRead;
	AudioStreamPacketDescription * pktDescs;
};

// input data proc callback

OSStatus EncoderDataProc(		AudioConverterRef				inAudioConverter, 
								UInt32*							ioNumberDataPackets,
								AudioBufferList*				ioData,
								AudioStreamPacketDescription**	outDataPacketDescription,
								void*							inUserData)
{
	AudioFileIO* afio = (AudioFileIO*)inUserData;
	
	// figure out how much to read
	if (*ioNumberDataPackets > afio->numPacketsPerRead) *ioNumberDataPackets = afio->numPacketsPerRead;

// read from the file

	UInt32 outNumBytes;
	OSStatus err = AudioFileReadPackets(afio->afid, false, &outNumBytes, afio->pktDescs, 
												afio->pos, ioNumberDataPackets, afio->srcBuffer);
	if (err) {
		printf ("Input Proc Read error: %d (%4.4s)\n", (int)err, (char*)&err);
		return err;
	}
	
//	printf ("Input Proc: Read %ld packets, size: %ld\n", *ioNumberDataPackets, afio->pos, outNumBytes);
	
// advance input file packet position

	afio->pos += *ioNumberDataPackets;

// put the data pointer into the buffer list

	ioData->mBuffers[0].mData = afio->srcBuffer;
	ioData->mBuffers[0].mDataByteSize = outNumBytes;
	ioData->mBuffers[0].mNumberChannels = afio->srcFormat.mChannelsPerFrame;

	if (outDataPacketDescription) {
		if (afio->pktDescs)
			*outDataPacketDescription = afio->pktDescs;
		else
			*outDataPacketDescription = NULL;
	}
		
	return err;
}

void	ReadCookie (AudioConverterRef converter, AudioFileID infile)
{
	// for decoding, grab the cookie from the file and write it to the converter
	UInt32 cookieSize = 0;
	OSStatus err = AudioFileGetPropertyInfo(infile, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
	// if there is an error here, then the format doesn't have a cookie, so on we go
	if (!err && cookieSize) {
		char* cookie = new char [cookieSize];
		
		err = AudioFileGetProperty(infile, kAudioFilePropertyMagicCookieData, &cookieSize, cookie);
		XThrowIfError (err, "Get Cookie From File");
		
		err = AudioConverterSetProperty (converter, kAudioConverterDecompressionMagicCookie, cookieSize, cookie);
		XThrowIfError (err, "Set Cookie To AudioConverter");
		
		delete [] cookie;
	}
}


void	WriteCookie (AudioConverterRef converter, AudioFileID outfile)
{
// grab the cookie from the converter and write it to the file
	UInt32 cookieSize = 0;
	OSStatus err = AudioConverterGetPropertyInfo(converter, kAudioConverterCompressionMagicCookie, &cookieSize, NULL);
		// if there is an error here, then the format doesn't have a cookie, so on we go
	if (!err && cookieSize) {
		char* cookie = new char [cookieSize];
		
		err = AudioConverterGetProperty(converter, kAudioConverterCompressionMagicCookie, &cookieSize, cookie);
		XThrowIfError (err, "Get Cookie From AudioConverter");
	
		/*err =*/ AudioFileSetProperty (outfile, kAudioFilePropertyMagicCookieData, cookieSize, cookie);
		// even though some formats have cookies, some files don't take them, so we ignore the error
		delete [] cookie;
	}
}

int ConvertFile (CFURLRef					inputFileURL, 
				CAStreamBasicDescription	&inputFormat,
				CFURLRef					outputFileURL,
				AudioFileTypeID				outputFileType, 
				CAStreamBasicDescription	&outputFormat,
				UInt32                      outputBitRate)
{
	AudioFileID infile, outfile;
	
	OSStatus err = AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &infile);
	XThrowIfError (err, "AudioFileOpen");
		
	// create the AudioConverter
	AudioConverterRef converter;
	err = AudioConverterNew(&inputFormat, &outputFormat, &converter);
	XThrowIfError (err, "AudioConverterNew");

	ReadCookie (converter, infile);
	
	// get the actual output format
	UInt32 size = sizeof(inputFormat);
	err = AudioConverterGetProperty(converter, kAudioConverterCurrentInputStreamDescription, &size, &inputFormat);
	XThrowIfError (err, "get kAudioConverterCurrentInputStreamDescription");

	size = sizeof(outputFormat);
	err = AudioConverterGetProperty(converter, kAudioConverterCurrentOutputStreamDescription, &size, &outputFormat);
	XThrowIfError (err, "get kAudioConverterCurrentOutputStreamDescription");

    if( outputBitRate > 0 ) {
        printf ("Dest bit rate: %d\n", (int)outputBitRate);
        err = AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate, 
                                        sizeof(outputBitRate), &outputBitRate);
        XThrowIfError (err, "AudioConverterSetProperty, kAudioConverterEncodeBitRate");
	}

	// create the output file (this will erase an existing file)
	err = AudioFileCreateWithURL(outputFileURL, outputFileType, &outputFormat, kAudioFileFlags_EraseFile, &outfile);
	XThrowIfError (err, "AudioFileCreate");
	
	// mActualToBaseSampleRateRatio is just for aach, since aach has two layers
	// the basic aac layer is of half sample rate of the aach layer
	double mActualToBaseSampleRateRatio = 1.0; // for aach
	CAStreamBasicDescription baseFormat;
	UInt32 propertySize = sizeof(AudioStreamBasicDescription);
	AudioFileGetProperty(infile, kAudioFilePropertyDataFormat, &propertySize, &baseFormat);
	
	if (inputFormat.mSampleRate != baseFormat.mSampleRate && inputFormat.mSampleRate != 0. && baseFormat.mSampleRate != 0.)
		mActualToBaseSampleRateRatio = inputFormat.mSampleRate / baseFormat.mSampleRate; // should be 2.0 for aach
	else
		mActualToBaseSampleRateRatio = 1.0;
	
	double srcRatio;
	if (outputFormat.mSampleRate != 0 && inputFormat.mSampleRate != 0) {
		srcRatio = outputFormat.mSampleRate / inputFormat.mSampleRate;
	} else {
		srcRatio = 1.0;
	}
	
	// if the bitstream file contains priming info, overwrite the audio converter's
	// priming info with the one got from the bitstream to do correct trimming
	SInt64 mDecodeValidFrames = 0;
	AudioFilePacketTableInfo srcPti;
	if (inputFormat.mBitsPerChannel == 0) { // input is compressed, decode to linear PCM
		size = sizeof(srcPti);
		err = AudioFileGetProperty(infile, kAudioFilePropertyPacketTableInfo, &size, &srcPti); // try to get priming info from bitstream file
		if (err == noErr) { // has priming info
			mDecodeValidFrames = (SInt64)(mActualToBaseSampleRateRatio * srcRatio * srcPti.mNumberValidFrames + 0.5);

			AudioConverterPrimeInfo primeInfo; // overwrite audio converter's priming info
			primeInfo.leadingFrames = (SInt32)(srcPti.mPrimingFrames * mActualToBaseSampleRateRatio + 0.5); // overwrite the audio converter's prime info
			primeInfo.trailingFrames = 0; // since the audio converter does not cut off trailing zeros
			err = AudioConverterSetProperty(converter, kAudioConverterPrimeInfo, sizeof(primeInfo), &primeInfo);
			XThrowIfError (err, "AudioConverterSetProperty, kAudioConverterPrimeInfo");
		}
	}
	
	// set up buffers and data proc info struct
	AudioFileIO afio;
	afio.afid = infile;
	afio.srcBufferSize = 32768;
	afio.srcBuffer = new char [ afio.srcBufferSize ];
	afio.pos = 0;
	afio.srcFormat = inputFormat;
		
	if (inputFormat.mBytesPerPacket == 0) {
		// format is VBR, so we need to get max size per packet
		size = sizeof(afio.srcSizePerPacket);
		err = AudioFileGetProperty(infile, kAudioFilePropertyPacketSizeUpperBound, &size, &afio.srcSizePerPacket);
		XThrowIfError (err, "kAudioFilePropertyPacketSizeUpperBound");
		afio.numPacketsPerRead = afio.srcBufferSize / afio.srcSizePerPacket;
		afio.pktDescs = new AudioStreamPacketDescription [afio.numPacketsPerRead];
	}
	else {
		afio.srcSizePerPacket = inputFormat.mBytesPerPacket;
		afio.numPacketsPerRead = afio.srcBufferSize / afio.srcSizePerPacket;
		afio.pktDescs = NULL;
	}

	// set up our output buffers
	AudioStreamPacketDescription* outputPktDescs = NULL;
	int outputSizePerPacket = outputFormat.mBytesPerPacket; // this will be non-zero if the format is CBR
	UInt32 theOutputBufSize = 32768;
	char* outputBuffer = new char[theOutputBufSize];
	
	if (outputSizePerPacket == 0) {
		UInt32 size = sizeof(outputSizePerPacket);
		err = AudioConverterGetProperty(converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &outputSizePerPacket);
		XThrowIfError (err, "Get Max Packet Size");
					
		outputPktDescs = new AudioStreamPacketDescription [theOutputBufSize / outputSizePerPacket];
	}
	UInt32 numOutputPackets = theOutputBufSize / outputSizePerPacket;

	WriteCookie (converter, outfile);
	
	// write dest channel layout
	if (inputFormat.mChannelsPerFrame > 2) {
		UInt32 layoutSize = 0;
		bool layoutFromConverter = true;
		err = AudioConverterGetPropertyInfo(converter, kAudioConverterOutputChannelLayout, &layoutSize, NULL);
			
			// if the converter doesn't have a layout does the input file?
		if (err || !layoutSize) {
			err = AudioFileGetPropertyInfo (infile, kAudioFilePropertyChannelLayout, &layoutSize, NULL);
			layoutFromConverter = false;
		}
		
		if (!err && layoutSize) {
			char* layout = new char[layoutSize];
			
			if (layoutFromConverter) {
				err = AudioConverterGetProperty(converter, kAudioConverterOutputChannelLayout, &layoutSize, layout);
				XThrowIfError (err, "Get Layout From AudioConverter");
			} else {
				err = AudioFileGetProperty(infile, kAudioFilePropertyChannelLayout, &layoutSize, layout);
				XThrowIfError (err, "Get Layout From AudioFile");
			}
			
			err = AudioFileSetProperty (outfile, kAudioFilePropertyChannelLayout, layoutSize, layout);
				// even though some formats have layouts, some files don't take them
			if (!err)
				printf ("write channel layout to file: %d\n", (int)layoutSize);
			
			delete [] layout;
		}
	}
	
	// loop to convert data
	SInt64 outputPos = 0;
	
	while (1) {

		// set up output buffer list
		AudioBufferList fillBufList;
		fillBufList.mNumberBuffers = 1;
		fillBufList.mBuffers[0].mNumberChannels = inputFormat.mChannelsPerFrame;
		fillBufList.mBuffers[0].mDataByteSize = theOutputBufSize;
		fillBufList.mBuffers[0].mData = outputBuffer;

		// convert data
		UInt32 ioOutputDataPackets = numOutputPackets;
		err = AudioConverterFillComplexBuffer(converter, EncoderDataProc, &afio, &ioOutputDataPackets, &fillBufList, outputPktDescs);
		XThrowIfError (err, "AudioConverterFillComplexBuffer");	
		if (ioOutputDataPackets == 0) {
			// this is the EOF conditon
			break;
		}
		
		SInt64 frame1 = outputPos + ioOutputDataPackets;
		if (mDecodeValidFrames != 0 && frame1 > mDecodeValidFrames) {
			SInt64 framesToTrim64 = frame1 - mDecodeValidFrames;
			UInt32 framesToTrim = (framesToTrim64 > ioOutputDataPackets) ? ioOutputDataPackets : UInt32(framesToTrim64);
			int bytesToTrim = framesToTrim * outputFormat.mBytesPerFrame;
			fillBufList.mBuffers[0].mDataByteSize -= bytesToTrim;
			ioOutputDataPackets -= framesToTrim;
		}
		
		// write to output file
		UInt32 inNumBytes = fillBufList.mBuffers[0].mDataByteSize;
		err = AudioFileWritePackets(outfile, false, inNumBytes, outputPktDescs, outputPos, &ioOutputDataPackets, outputBuffer);
		XThrowIfError (err, "AudioFileWritePackets");	
		
		// advance output file packet position
		outputPos += ioOutputDataPackets;

		// printf ("Convert Output: Write %ld packets, size: %ld\n", ioOutputDataPackets, inNumBytes);
	}

	// we write out any of the leading and trailing frames for compressed formats only	
	if (outputFormat.mBitsPerChannel == 0) {
		UInt32 isWritable;
		err = AudioFileGetPropertyInfo(outfile, kAudioFilePropertyPacketTableInfo, &size, &isWritable);
		if (err == noErr && isWritable) {
			// last job is to make sure we write out the priming and remainder details to the file
			AudioConverterPrimeInfo primeInfo;
			UInt32 primeSize = sizeof(primeInfo);
			
			err = AudioConverterGetProperty(converter, kAudioConverterPrimeInfo, &primeSize, &primeInfo);
			// if there's an error we don't care
			if (err == noErr) {
				AudioFilePacketTableInfo pti;
				size = sizeof(pti);
				err = AudioFileGetProperty(outfile, kAudioFilePropertyPacketTableInfo, &size, &pti);
				if (err == noErr) {
					// there's priming to write out to the file
					UInt64 totalFrames = pti.mNumberValidFrames + pti.mPrimingFrames + pti.mRemainderFrames; // get the total number of frames from the output file
					pti.mPrimingFrames = primeInfo.leadingFrames;
					pti.mRemainderFrames = primeInfo.trailingFrames;
					pti.mNumberValidFrames = totalFrames - pti.mPrimingFrames - pti.mRemainderFrames; // update number of valid frames
					err = AudioFileSetProperty(outfile, kAudioFilePropertyPacketTableInfo, sizeof(pti), &pti);
					XThrowIfError (err, "AudioFileSetProperty, kAudioFilePropertyPacketTableInfo");
				}
			}
		}
	}
	
	// write the cookie again - sometimes codecs will
	// update cookies at the end of a conversion
	WriteCookie (converter, outfile);

	// cleanup
	delete [] afio.srcBuffer;
	if (inputFormat.mBytesPerPacket == 0) {
		delete afio.pktDescs;
	}
	
	delete [] outputPktDescs;
	delete [] outputBuffer;

	AudioConverterDispose(converter);
	AudioFileClose(outfile);
	AudioFileClose(infile);
	
    return 0;
}
