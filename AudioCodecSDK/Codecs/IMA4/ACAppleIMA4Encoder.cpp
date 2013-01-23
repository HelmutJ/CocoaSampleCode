/*
    File: ACAppleIMA4Encoder.cpp
Abstract: ACAppleIMA4Encoder.cpp file for AudioCodecSDK.
 Version: 1.0.1

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

//=============================================================================
//	Includes
//=============================================================================

#include "ACAppleIMA4Encoder.h"
#include "ACCodecDispatch.h"
#include "CAStreamBasicDescription.h"
#include "CADebugMacros.h"
#include "CABundleLocker.h"

//=============================================================================
//	ACAppleIMA4Encoder
//=============================================================================

ACAppleIMA4Encoder::ACAppleIMA4Encoder(OSType theSubType)
:
	ACAppleIMA4Codec(kInputBufferPackets * kIMAFramesPerPacket * SizeOf32(SInt16), theSubType), 
	mEndOfInput(false), mZeroPaddedOnce(false), mZeroesPadded(0)
{
	//	This encoder only accepts 16 bit native endian signed integer as it's input,
	//	but can handle any sample rate and any number of channels
	CAStreamBasicDescription theInputFormat(kAudioStreamAnyRate, kAudioFormatLinearPCM, 0, 1, 0, 0, 16, kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);
	AddInputFormat(theInputFormat);
	
	//	set our intial input format to mono 16 bit native endian signed integer at a 44100 sample rate
	mInputFormat.mSampleRate = 44100;
	mInputFormat.mFormatID = kAudioFormatLinearPCM;
	mInputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	mInputFormat.mBytesPerPacket = 2;
	mInputFormat.mFramesPerPacket = 1;
	mInputFormat.mBytesPerFrame = 2;
	mInputFormat.mChannelsPerFrame = 1;
	mInputFormat.mBitsPerChannel = 16;
	
	//	This encoder only puts out an Acme IMA4 stream
	CAStreamBasicDescription theOutputFormat(kAudioStreamAnyRate, 'DEMO', 0, kIMAFramesPerPacket, 0, 0, 0, 0);
	AddOutputFormat(theOutputFormat);

	//	set our intial output format to mono Apple IMA4 at a 44100 sample rate
	mOutputFormat.mSampleRate = 44100;
	mOutputFormat.mFormatID = 'DEMO';
	mOutputFormat.mFormatFlags = 0;
	mOutputFormat.mBytesPerPacket = kIMA4PacketBytes;
	mOutputFormat.mFramesPerPacket = kIMAFramesPerPacket;
	mOutputFormat.mBytesPerFrame = 0;
	mOutputFormat.mChannelsPerFrame = 1;
	mOutputFormat.mBitsPerChannel = 0;
	
	mSupportedChannelTotals[0] = 1;
	mSupportedChannelTotals[1] = 2;

	//	initialize our channel state
	InitializeChannelStateList();
}

ACAppleIMA4Encoder::~ACAppleIMA4Encoder()
{
}

void	ACAppleIMA4Encoder::GetPropertyInfo(AudioCodecPropertyID inPropertyID, UInt32& outPropertyDataSize, Boolean& outWritable)
{
	switch(inPropertyID)
	{
		case kAudioCodecPropertyAvailableNumberChannels:
			outPropertyDataSize = SizeOf32(UInt32) * kMaxIMA4Channels;
			outWritable = false;
			break;

		case kAudioCodecPropertyAvailableInputSampleRates:
			outPropertyDataSize = SizeOf32(AudioValueRange);
			outWritable = false;
			break;
			
		case kAudioCodecPropertyAvailableOutputSampleRates:
			outPropertyDataSize = SizeOf32(AudioValueRange);
			outWritable = false;
			break;
			
		case kAudioCodecPropertyZeroFramesPadded:
			outPropertyDataSize = SizeOf32(UInt32);
			outWritable = false;
			break;
			
 		case kAudioCodecPropertyPrimeInfo:
			outPropertyDataSize = SizeOf32(AudioCodecPrimeInfo);
			outWritable = false;
			break;
            		            		
		default:
			ACAppleIMA4Codec::GetPropertyInfo(inPropertyID, outPropertyDataSize, outWritable);
			break;
			
	};
}

void	ACAppleIMA4Encoder::GetProperty(AudioCodecPropertyID inPropertyID, UInt32& ioPropertyDataSize, void* outPropertyData)
{	
	switch(inPropertyID)
	{
#if !BUILD_ADEC_LIB
		case kAudioCodecPropertyNameCFString:
		{
			if (ioPropertyDataSize != sizeof(CFStringRef))
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			CABundleLocker lock;
			CFStringRef name = CFCopyLocalizedStringFromTableInBundle(CFSTR("Acme IMA4 encoder"), CFSTR("CodecNames"), GetCodecBundle(), CFSTR(""));
			*(CFStringRef*)outPropertyData = name;
			break; 
		}
#endif
		case kAudioCodecPropertyAvailableNumberChannels:
  			if(ioPropertyDataSize == sizeof(UInt32) * kMaxIMA4Channels)
			{
				memcpy(reinterpret_cast<UInt32*>(outPropertyData), mSupportedChannelTotals, ioPropertyDataSize);
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		case kAudioCodecPropertyAvailableInputSampleRates:
  			if(ioPropertyDataSize == sizeof(AudioValueRange) )
			{
				(reinterpret_cast<AudioValueRange*>(outPropertyData))->mMinimum = 0.0;
				(reinterpret_cast<AudioValueRange*>(outPropertyData))->mMaximum = 0.0;
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		case kAudioCodecPropertyAvailableOutputSampleRates:
  			if(ioPropertyDataSize == sizeof(AudioValueRange) )
			{
				(reinterpret_cast<AudioValueRange*>(outPropertyData))->mMinimum = 0.0;
				(reinterpret_cast<AudioValueRange*>(outPropertyData))->mMaximum = 0.0;
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		case kAudioCodecPropertyPrimeInfo:
  			if(ioPropertyDataSize == sizeof(AudioCodecPrimeInfo) )
			{
				(reinterpret_cast<AudioCodecPrimeInfo*>(outPropertyData))->leadingFrames = 0;
				(reinterpret_cast<AudioCodecPrimeInfo*>(outPropertyData))->trailingFrames = mZeroesPadded;
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		case kAudioCodecPropertyZeroFramesPadded:
			if(ioPropertyDataSize == sizeof(UInt32))
			{
				*reinterpret_cast<UInt32*>(outPropertyData) = mZeroesPadded;
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		default:
			ACAppleIMA4Codec::GetProperty(inPropertyID, ioPropertyDataSize, outPropertyData);
	}
}

void ACAppleIMA4Encoder::SetProperty(AudioCodecPropertyID inPropertyID, UInt32 inPropertyDataSize, const void* inPropertyData)
{
	switch(inPropertyID)
	{
		case kAudioCodecPropertyAvailableInputSampleRates:
		case kAudioCodecPropertyAvailableOutputSampleRates:
		case kAudioCodecPropertyZeroFramesPadded:
		case kAudioCodecPropertyPrimeInfo:
			CODEC_THROW(kAudioCodecIllegalOperationError);
			break;
		default:
			ACAppleIMA4Codec::SetProperty(inPropertyID, inPropertyDataSize, inPropertyData);
			break;            
	}
}

void	ACAppleIMA4Encoder::SetCurrentInputFormat(const AudioStreamBasicDescription& inInputFormat)
{
	if(!mIsInitialized)
	{
		//	check to make sure the input format is legal
		if(	(inInputFormat.mFormatID != kAudioFormatLinearPCM) ||
			(inInputFormat.mFormatFlags != (kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked)) ||
			(inInputFormat.mBitsPerChannel != 16))
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentInputFormat: only support 16 bit native endian signed integer for input");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}
		
		// Do some basic sanity checking
		if(inInputFormat.mSampleRate < 0.0)
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentInputFormat: input sample rates may not be negative");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}
		
		if(inInputFormat.mChannelsPerFrame > kMaxIMA4Channels)
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentInputFormat: only supports mono or stereo");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}
		
		//	tell our base class about the new format
		ACAppleIMA4Codec::SetCurrentInputFormat(inInputFormat);
		// The encoder does no sample rate conversion nor channel manipulation
		if (inInputFormat.mChannelsPerFrame == 0)
		{
			mInputFormat.mChannelsPerFrame = mOutputFormat.mChannelsPerFrame;
		}
		else
		{
			mOutputFormat.mChannelsPerFrame = mInputFormat.mChannelsPerFrame;
		}
		if (inInputFormat.mSampleRate == 0.0)
		{
			mInputFormat.mSampleRate = mOutputFormat.mSampleRate;
		}
		else
		{
			mOutputFormat.mSampleRate = mInputFormat.mSampleRate;
		}
		// Fix derived values
		mInputFormat.mBytesPerFrame = mInputFormat.mBytesPerPacket = (mInputFormat.mBitsPerChannel >> 3) * mInputFormat.mChannelsPerFrame;
		mInputFormat.mFramesPerPacket = 1;
		
		// Zero out everything that has to be zero
		mInputFormat.mReserved = 0;
	}
	else
	{
		CODEC_THROW(kAudioCodecStateError);
	}
}

void	ACAppleIMA4Encoder::SetCurrentOutputFormat(const AudioStreamBasicDescription& inOutputFormat)
{
	if(!mIsInitialized)
	{
		//	check to make sure the output format is legal
		if(inOutputFormat.mFormatID != mCodecSubType || (inOutputFormat.mFramesPerPacket != kIMAFramesPerPacket && inOutputFormat.mFramesPerPacket != 0) )
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentOutputFormat: only supports Apple IMA at 64 frames per packet for output");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}
		
		// Do some basic sanity checking
		if(inOutputFormat.mSampleRate < 0.0)
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentOutputFormat: output sample rates may not be negative");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}
		if (kMaxIMA4Channels < inOutputFormat.mChannelsPerFrame)
		{
	#if VERBOSE
			DebugMessage("ACAppleIMA4Encoder::SetCurrentOutputFormat: only supports up to 2 channels for output");
	#endif
			CODEC_THROW(kAudioCodecUnsupportedFormatError);
		}

		//	tell our base class about the new format
		ACAppleIMA4Codec::SetCurrentOutputFormat(inOutputFormat);
		// The encoder does no sample rate conversion nor channel manipulation
		if (mOutputFormat.mSampleRate == 0.0)
		{
			mOutputFormat.mSampleRate = mInputFormat.mSampleRate;
		}
		if (mOutputFormat.mChannelsPerFrame == 0)
		{
			mOutputFormat.mChannelsPerFrame = mInputFormat.mChannelsPerFrame;
		}
		if (mOutputFormat.mFramesPerPacket == 0)
		{
			mOutputFormat.mFramesPerPacket = kIMAFramesPerPacket;
		}
		// calculate this out
		mOutputFormat.mBytesPerPacket = kIMA4PacketBytes * mOutputFormat.mChannelsPerFrame;	
		// Zero out everything that has to be zero
		mOutputFormat.mBytesPerFrame = 0;
		mOutputFormat.mBitsPerChannel = 0;
		mOutputFormat.mFormatFlags = 0;
		mOutputFormat.mReserved = 0;
	}
	else
	{
		CODEC_THROW(kAudioCodecStateError);
	}
}

void	ACAppleIMA4Encoder::AppendInputData(const void* inInputData, UInt32& ioInputDataByteSize, UInt32& ioNumberPackets, const AudioStreamPacketDescription* inPacketDescription)
{
	if (ioNumberPackets == 0)
	{
		mEndOfInput = true;
	}
	else
	{
		mEndOfInput = false;
	}
	
	ACAppleIMA4Codec::AppendInputData(inInputData, ioInputDataByteSize, ioNumberPackets, inPacketDescription);
}

UInt32	ACAppleIMA4Encoder::ProduceOutputPackets(
				void* 							outOutputData, 
				UInt32& 						ioOutputDataByteSize, 
				UInt32& 						ioNumberPackets, 
				AudioStreamPacketDescription* 	outPacketDescription)
{
	//	setup the return value, by assuming that everything is going to work
	UInt32 theAnswer = kAudioCodecProduceOutputPacketSuccess;
	
	if(!mIsInitialized)
	{
		CODEC_THROW(kAudioCodecStateError);
	}
		
	//	clamp the number of packets to produce based on what is available in the input buffer
	UInt32 inputPacketSize = mInputFormat.mBytesPerFrame * kIMAFramesPerPacket;
	UInt32 numberOfInputPackets = GetUsedInputBufferByteSize() / inputPacketSize;
	if (ioNumberPackets < numberOfInputPackets)
	{
		numberOfInputPackets = ioNumberPackets;
	}
	else if (ioNumberPackets > numberOfInputPackets)
	{
		UInt32 numberOfInputFrames = GetUsedInputBufferByteSize() / mInputFormat.mBytesPerFrame;
		if (numberOfInputPackets == 0 && mEndOfInput && !mZeroPaddedOnce && numberOfInputFrames != kIMAFramesPerPacket) 
		{
			numberOfInputPackets = ioNumberPackets = 1;
			mZeroesPadded = kIMAFramesPerPacket - numberOfInputFrames;
			ZeroPadInputData(mZeroesPadded, NULL);
			mZeroPaddedOnce = true;
		} else {
			ioNumberPackets = numberOfInputPackets;
		}
		//	this also means we need more input to satisfy the request so set the return value
		theAnswer = kAudioCodecProduceOutputPacketNeedsMoreInputData;
	}

	UInt32 inputByteSize = numberOfInputPackets * inputPacketSize;
	
	if(ioNumberPackets > 0)
	{
		//	make sure that there is enough space in the output buffer for the encoded data
		//	it is an error to ask for more output than you pass in buffer space for
		UInt32	theOutputByteSize = ioNumberPackets * mOutputFormat.mChannelsPerFrame * kIMA4PacketBytes;
		
		ThrowIf(ioOutputDataByteSize < theOutputByteSize, static_cast<OSStatus>(kAudioCodecNotEnoughBufferSpaceError), "ACAppleIMA4Encoder::ProduceOutputPackets: not enough space in the output buffer");
		
		//	set the return value
		ioOutputDataByteSize = theOutputByteSize;
		
		//	encode the input data for each channel
		SInt16* theInputData = reinterpret_cast<SInt16*>(GetBytes(inputByteSize));
		Byte* theOutputData = reinterpret_cast<Byte*>(outOutputData);
		ChannelStateList::iterator theIterator = mChannelStateList.begin();
		for(UInt32 theChannelIndex = 0; theChannelIndex < mOutputFormat.mChannelsPerFrame; ++theChannelIndex)
		{
			EncodeChannel(
				*theIterator, 
				mOutputFormat.mChannelsPerFrame, 
				theChannelIndex, 
				ioNumberPackets, 
				theInputData, 
				theOutputData);
			std::advance(theIterator, 1);
		}

		ConsumeInputData(inputByteSize);
	}
	else
	{
		//	set the return value since we're not actually doing any work
		ioOutputDataByteSize = 0;
	}
	
	if((theAnswer == kAudioCodecProduceOutputPacketSuccess) && (GetUsedInputBufferByteSize() >= inputPacketSize))
	{
		//	we satisfied the request, and there's at least one more full packet of data we can encode
		//	so set the return value
		theAnswer = kAudioCodecProduceOutputPacketSuccessHasMore;
	}
	
	return theAnswer;
}

void	ACAppleIMA4Encoder::EncodeChannel(
					ChannelState& 	ioChannelState, 
					UInt32 			inNumberChannels, 
					UInt32 			inEncodeChannel, 
					UInt32 			inNumberPacketsToEncode, 
					const SInt16* 	inInputData, 
					Byte* 			outOutputData)
{
	//	This encoder can only encode one channel at a time.
	//	Each channel in a packet of frames is encoded separately and
	//	the resulting channel packets are interleaved in channel order.
	
	//	We need to figure out how to skip through the input and output buffers
	//	and point at the appropriate place in the data to start off
	UInt32	theInputStride	= inNumberChannels;
	SInt16*	theInputData	= const_cast<SInt16*>(inInputData) + inEncodeChannel;
	
	UInt32	theOutputStride	= (inNumberChannels - 1) * kIMA4PacketBytes;
					// minus one because we'll already be at the end of what we've done.

	Byte*	theOutputData	= outOutputData + (inEncodeChannel * kIMA4PacketBytes);
	
	//	set up our state
	SInt32	thePredictedSample = ioChannelState.mPredictedSample;
	SInt32	theStepTableIndex = ioChannelState.mStepTableIndex;
	SInt32	theStep = sStepTable[theStepTableIndex];
	
	//	encode the packets
	while(inNumberPacketsToEncode > 0)
	{		
		//	write out the state for this packet
		UInt16 theSavedState = (static_cast<SInt16>(thePredictedSample) & kPredictorMask) | (static_cast<SInt16>(theStepTableIndex) & kStepTableIndexMask);
		*reinterpret_cast<UInt16*>(theOutputData) = CFSwapInt16HostToBig(theSavedState);
		theOutputData += 2;
		
		//	initialize the buffer to cache encoded nibbles
		Byte theTemporaryOutputData = 0;
		
		for(UInt32 theNumberSamplesLeft = kIMAFramesPerPacket; theNumberSamplesLeft > 0; --theNumberSamplesLeft)
		{
			//	calculate the difference between the predicted value and the actual value
			//	note that this calculation may require as many as 17 bits
			SInt32 inputSample = static_cast<SInt32>(*theInputData);
			SInt32	theDifference = inputSample - thePredictedSample;
			
			//	skip to the next sample
			theInputData += theInputStride;
			
			//	set the sign bit
			SInt32 theCode = 0;
			if(theDifference < 0)
			{
				theCode = 8;
				theDifference = -theDifference;
			}
			
			//	quantize the difference
			SInt32 theMask = 4;
			SInt32 theTempStep = theStep;
			for(SInt32 theIndex = 3; theIndex > 0; --theIndex)
			{
				if(theDifference >= theTempStep)
				{
					theCode |= theMask;
					theDifference -= theTempStep;
				}
				theTempStep >>= 1;
				theMask >>= 1;
			}
			
			//	write out the encoded sample
			if(theNumberSamplesLeft & 0x01)
			{
				//	we have a full byte to write, so write it along with the cached nibble
				*theOutputData = (static_cast<Byte>(theCode) << 4) | theTemporaryOutputData;
				
				//	increment the output pointer
				++theOutputData;
			}
			else
			{
				//	we only have a nibble to write, so cache it
				theTemporaryOutputData = static_cast<Byte>(theCode) & 0x0F;
			}
			
			//	predict the next sample
			theDifference = 0;
			if(theCode & 0x04)
			{
				theDifference += theStep;
			}
			if(theCode & 0x02)
			{
				theDifference += theStep >> 1;
			}
			if(theCode & 0x01)
			{
				theDifference += theStep >> 2;
			}
			theDifference += theStep >> 3;
			if(theCode & 0x08)
			{
				theDifference = -theDifference;
			}
			thePredictedSample += theDifference;
			
			//	check for overflow
			if(thePredictedSample > 32767)
			{
				thePredictedSample = 32767;
			}
			else if(thePredictedSample < -32768)
			{
				thePredictedSample = -32768;
			}
			
			//	compute the new step size
			theStepTableIndex += sIndexTable[theCode];
			if(theStepTableIndex < 0)
			{
				theStepTableIndex = 0;
			}
			else if(theStepTableIndex > 88)
			{
				theStepTableIndex = 88;
			}
			theStep = sStepTable[theStepTableIndex];
		}
		
		//	finished with a full packet so stride to the next
		theOutputData += theOutputStride;
		--inNumberPacketsToEncode;
	}
	
	//	finished with all the packets to encode, so update the state that's
	//	passed back to the caller
	ioChannelState.mPredictedSample = thePredictedSample;
	ioChannelState.mStepTableIndex = theStepTableIndex;
}

UInt32	ACAppleIMA4Encoder::GetVersion() const
{
	return kIMA4aencVersion;
}

void ACAppleIMA4Encoder::FixFormats()
{
	mOutputFormat.mFramesPerPacket = 64;
	mOutputFormat.mBytesPerPacket = mOutputFormat.mChannelsPerFrame * 34;
	mOutputFormat.mBytesPerFrame = 0;
}

#if !CA_NO_CORE_SERVICES
extern "C"
OSStatus ACAppleIMA4EncoderEntry(ComponentParameters* inParameters, ACAppleIMA4Encoder* inThis)
{
	return	ACCodecDispatch(inParameters, inThis);
}
#endif
