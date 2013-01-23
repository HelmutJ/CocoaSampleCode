/*
    File: ACAppleIMA4Codec.cpp
Abstract: ACAppleIMA4Codec.cpp file for AudioCodecSDK.
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

#include "ACAppleIMA4Codec.h"
#include "CABundleLocker.h"
#include "ACCompatibility.h"

#if TARGET_OS_WIN32
	#include "CAWin32StringResources.h"
#endif

//=============================================================================
//	ACAppleIMA4Codec
//=============================================================================

ACAppleIMA4Codec::ACAppleIMA4Codec(UInt32 inInputBufferByteSize, OSType theSubType)
:
	ACSimpleCodec(inInputBufferByteSize, theSubType),
	mChannelStateList()
{
}

ACAppleIMA4Codec::~ACAppleIMA4Codec()
{
}

void	ACAppleIMA4Codec::Initialize(const AudioStreamBasicDescription* inInputFormat, const AudioStreamBasicDescription* inOutputFormat, const void* inMagicCookie, UInt32 inMagicCookieByteSize)
{
	//	use the given arguments, if necessary
	if(inInputFormat != NULL)
	{
		SetCurrentInputFormat(*inInputFormat);
	}

	if(inOutputFormat != NULL)
	{
		SetCurrentOutputFormat(*inOutputFormat);
	}
	
	FixFormats();

	//	make sure the sample rate and number of channels match between the input format and the output format
	if( (mInputFormat.mSampleRate != mOutputFormat.mSampleRate) ||
		(mInputFormat.mChannelsPerFrame != mOutputFormat.mChannelsPerFrame))
	{
		CODEC_THROW(kAudioCodecUnsupportedFormatError);
	}

	//	initalize the channel state list
	InitializeChannelStateList();
	
	ACSimpleCodec::Initialize(inInputFormat, inOutputFormat, inMagicCookie, inMagicCookieByteSize);
}

void	ACAppleIMA4Codec::Uninitialize()
{
	//	clean up the internal state
	ResetChannelStateList();
	
	//	let our base class clean up it's internal state
	ACSimpleCodec::Uninitialize();
}

void	ACAppleIMA4Codec::Reset()
{
	//	clean up the internal state
	ResetChannelStateList();
	
	//	let our base class clean up it's internal state
	ACSimpleCodec::Reset();
}

void	ACAppleIMA4Codec::InitializeChannelStateList()
{
	mChannelStateList.clear();
	for(UInt32 theIndex = 0; theIndex < mInputFormat.mChannelsPerFrame; ++theIndex)
	{
		mChannelStateList.push_back(ChannelState());
	}
}

void	ACAppleIMA4Codec::ResetChannelStateList()
{
	ChannelStateList::iterator theIterator = mChannelStateList.begin();
	while(theIterator != mChannelStateList.end())
	{
		theIterator->Reset();
		std::advance(theIterator, 1);
	}
}

void	ACAppleIMA4Codec::GetPropertyInfo(AudioCodecPropertyID inPropertyID, UInt32& outPropertyDataSize, Boolean& outWritable)
{
	switch(inPropertyID)
	{
		case kAudioCodecPropertyMaximumPacketByteSize:
			outPropertyDataSize = SizeOf32(UInt32);
			outWritable = false;
			break;
		
		case kAudioCodecPropertyRequiresPacketDescription:
			outPropertyDataSize = SizeOf32(UInt32);
			outWritable = false;
			break;

		case kAudioCodecPropertyHasVariablePacketByteSizes:
			outPropertyDataSize = SizeOf32(UInt32);
			outWritable = false;
			break;
            
		case kAudioCodecPropertyPacketFrameSize:
			outPropertyDataSize = SizeOf32(UInt32);
			outWritable = false;
			break;
            		
		case kAudioCodecPropertyCurrentInputSampleRate:
			outPropertyDataSize = SizeOf32(Float64);
			outWritable = false;
			break;

 		case kAudioCodecPropertyCurrentOutputSampleRate:
			outPropertyDataSize = SizeOf32(Float64);
			outWritable = false;
			break;

		case kAudioCodecPropertyCurrentInputChannelLayout:
		case kAudioCodecPropertyCurrentOutputChannelLayout:
			outPropertyDataSize = SizeOf32(AudioChannelLayout);
			outWritable = false;
			break;

		case kAudioCodecPropertyAvailableInputChannelLayoutTags:
		case kAudioCodecPropertyAvailableOutputChannelLayoutTags:
			outPropertyDataSize = kMaxIMA4Channels * SizeOf32(AudioChannelLayoutTag);
			outWritable = false;
			break;

		case kAudioCodecPropertyFormatInfo:
			outPropertyDataSize = SizeOf32(AudioFormatInfo);
			outWritable = false;
			break;

		default:
			ACSimpleCodec::GetPropertyInfo(inPropertyID, outPropertyDataSize, outWritable);
			break;
			
	};
}

void	ACAppleIMA4Codec::GetProperty(AudioCodecPropertyID inPropertyID, UInt32& ioPropertyDataSize, void* outPropertyData)
{	
	switch(inPropertyID)
	{
#if !BUILD_ADEC_LIB
		case kAudioCodecPropertyFormatCFString:
		{
			if (ioPropertyDataSize != SizeOf32(CFStringRef))
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
						
			CABundleLocker lock;

			CFStringRef name = CFCopyLocalizedStringFromTableInBundle(CFSTR("Acme IMA4"), CFSTR("CodecNames"), GetCodecBundle(), CFSTR(""));
            
			*(CFStringRef*)outPropertyData = name;
			break; 
		}
#endif
        case kAudioCodecPropertyMaximumPacketByteSize:
  			if(ioPropertyDataSize == SizeOf32(UInt32))
			{
				*reinterpret_cast<UInt32*>(outPropertyData) = kIMA4PacketBytes * mInputFormat.mChannelsPerFrame;
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
            break;
        case kAudioCodecPropertyRequiresPacketDescription:
  			if(ioPropertyDataSize == SizeOf32(UInt32))
			{
                *reinterpret_cast<UInt32*>(outPropertyData) = 0; 
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
            break;
        case kAudioCodecPropertyHasVariablePacketByteSizes:
  			if(ioPropertyDataSize == SizeOf32(UInt32))
			{
                *reinterpret_cast<UInt32*>(outPropertyData) = 0; // We are constant bitrate
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
            break;
		case kAudioCodecPropertyPacketFrameSize:
			if(ioPropertyDataSize == SizeOf32(UInt32))
			{
                *reinterpret_cast<UInt32*>(outPropertyData) = kIMAFramesPerPacket;
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
        case kAudioCodecPropertyCurrentInputSampleRate:
  			if(ioPropertyDataSize == SizeOf32(Float64))
			{
                *reinterpret_cast<Float64*>(outPropertyData) = (Float64)(mInputFormat.mSampleRate);
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
            break;
        case kAudioCodecPropertyCurrentOutputSampleRate:
  			if(ioPropertyDataSize == SizeOf32(Float64))
			{
                *reinterpret_cast<Float64*>(outPropertyData) = (Float64)(mOutputFormat.mSampleRate);
            }
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
            break;
		case kAudioCodecPropertyCurrentInputChannelLayout:
		case kAudioCodecPropertyCurrentOutputChannelLayout:
			AudioChannelLayout temp1AudioChannelLayout;
			memset(&temp1AudioChannelLayout, 0, SizeOf32(AudioChannelLayout));
  			if(ioPropertyDataSize == SizeOf32(AudioChannelLayout))
			{
				if (mInputFormat.mChannelsPerFrame == 1)
				{
					temp1AudioChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
				}
				else
				{
					temp1AudioChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
				}
				memcpy(outPropertyData, &temp1AudioChannelLayout, ioPropertyDataSize);
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;
		case kAudioCodecPropertyAvailableInputChannelLayoutTags:
		case kAudioCodecPropertyAvailableOutputChannelLayoutTags:
  			if(ioPropertyDataSize == kMaxIMA4Channels * SizeOf32(AudioChannelLayoutTag))
			{
				if(mIsInitialized)
				{
					AudioChannelLayoutTag temp2AudioChannelLayoutTag[1];
					if (mInputFormat.mChannelsPerFrame == 1)
					{
						temp2AudioChannelLayoutTag[0] = kAudioChannelLayoutTag_Mono;
					}
					else
					{
						temp2AudioChannelLayoutTag[0] = kAudioChannelLayoutTag_Stereo;
					}
					ioPropertyDataSize = SizeOf32(AudioChannelLayoutTag);
					memcpy(reinterpret_cast<AudioChannelLayoutTag*>(outPropertyData), temp2AudioChannelLayoutTag, ioPropertyDataSize);
				}
				else
				{
					AudioChannelLayoutTag temp2AudioChannelLayoutTag[2];
					temp2AudioChannelLayoutTag[0] = kAudioChannelLayoutTag_Mono;
					temp2AudioChannelLayoutTag[1] = kAudioChannelLayoutTag_Stereo;
					memcpy(reinterpret_cast<AudioChannelLayoutTag*>(outPropertyData), temp2AudioChannelLayoutTag, ioPropertyDataSize);
				}
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;

		case kAudioCodecPropertyFormatInfo:
			if(ioPropertyDataSize == SizeOf32(AudioFormatInfo))
			{
				AudioFormatInfo& formatInfo = *(AudioFormatInfo*)outPropertyData;
                
				// We don't have a cookie, we have to check the ASBD 
				// according to the input formats
				UInt32 i;
				for(i = 0; i < GetNumberSupportedInputFormats(); ++i)
				{
					if(mInputFormatList[i].IsEqual(formatInfo.mASBD))
					{
						// Fill out missing entries
						CAStreamBasicDescription::FillOutFormat(formatInfo.mASBD, mInputFormatList[i]);
						break;
					}
				}
				if(i == GetNumberSupportedInputFormats())
				{
					// No suitable settings found
					CODEC_THROW(kAudioCodecUnsupportedFormatError);
				}
			}
			else
			{
				CODEC_THROW(kAudioCodecBadPropertySizeError);
			}
			break;

		default:
			ACSimpleCodec::GetProperty(inPropertyID, ioPropertyDataSize, outPropertyData);
	}
}

void ACAppleIMA4Codec::SetProperty(AudioCodecPropertyID inPropertyID, UInt32 inPropertyDataSize, const void* inPropertyData)
{
	switch(inPropertyID)
	{
		case kAudioCodecPropertyFormatInfo:
		case kAudioCodecPropertyHasVariablePacketByteSizes:
		case kAudioCodecPropertyCurrentInputChannelLayout:
		case kAudioCodecPropertyCurrentOutputChannelLayout:
		case kAudioCodecPropertyPacketFrameSize:
		case kAudioCodecPropertyAvailableInputChannelLayoutTags:
		case kAudioCodecPropertyAvailableOutputChannelLayoutTags:
		case kAudioCodecDoesSampleRateConversion:
		case kAudioCodecPropertyMaximumPacketByteSize:
		case kAudioCodecPropertyCurrentInputSampleRate:
		case kAudioCodecPropertyCurrentOutputSampleRate:
			CODEC_THROW(kAudioCodecIllegalOperationError);
			break;
		default:
			ACSimpleCodec::SetProperty(inPropertyID, inPropertyDataSize, inPropertyData);
			break;            
    }
}

const UInt16	ACAppleIMA4Codec::kPredictorMask = 0xFF80;
const UInt16	ACAppleIMA4Codec::kStepTableIndexMask = 0x007F;
const SInt32	ACAppleIMA4Codec::kPredictorTolerance = 0x0000007F;
const SInt16	ACAppleIMA4Codec::sIndexTable[16] = { -1,-1,-1,-1, 2, 4, 6, 8, -1,-1,-1,-1, 2, 4, 6, 8 };
const SInt16	ACAppleIMA4Codec::sStepTable[89] = {	    7,     8,     9,    10,    11,    12,    13,    14,    16,    17,
														   19,    21,    23,    25,    28,    31,    34,    37,    41,    45,
														   50,    55,    60,    66,    73,    80,    88,    97,   107,   118,
														  130,   143,   157,   173,   190,   209,   230,   253,   279,   307,
														  337,   371,   408,   449,   494,   544,   598,   658,   724,   796,
														  876,   963,  1060,  1166,  1282,  1411,  1552,  1707,  1878,  2066,
														 2272,  2499,  2749,  3024,  3327,  3660,  4026,  4428,  4871,  5358,
														 5894,  6484,  7132,  7845,  8630,  9493, 10442, 11487, 12635, 13899,
														15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767        };
