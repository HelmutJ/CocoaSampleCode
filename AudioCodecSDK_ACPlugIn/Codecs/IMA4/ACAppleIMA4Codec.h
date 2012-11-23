/*
    File: ACAppleIMA4Codec.h
Abstract: ACAppleIMA4Codec.h file for AudioCodecSDK.
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

#if !defined(__ACAppleIMA4Codec_h__)
#define __ACAppleIMA4Codec_h__

//=============================================================================
//	Includes
//=============================================================================

#include "ACSimpleCodec.h"
#include <vector>
#include "ACVersions_IMA.h"

#define kMaxIMA4Channels 2

//=============================================================================
//	ACAppleIMA4Codec
//
//	This class encapsulates the common implementation of an Apple IMA codec.
//=============================================================================

class ACAppleIMA4Codec
:
	public ACSimpleCodec
{

//	Construction/Destruction
public:
						ACAppleIMA4Codec(UInt32 inInputBufferByteSize, AudioComponentInstance inInstance);
	virtual				~ACAppleIMA4Codec();

//	Data Handling
public:
	virtual void		Initialize(const AudioStreamBasicDescription* inInputFormat, const AudioStreamBasicDescription* inOutputFormat, const void* inMagicCookie, UInt32 inMagicCookieByteSize);
	virtual void		Uninitialize();
	virtual void		Reset();
	virtual void		FixFormats()=0;

	virtual void		GetProperty(AudioCodecPropertyID inPropertyID, UInt32& ioPropertyDataSize, void* outPropertyData);
	virtual void		GetPropertyInfo(AudioCodecPropertyID inPropertyID, UInt32& outPropertyDataSize, Boolean& outWritable);
	virtual void		SetProperty(AudioCodecPropertyID inPropertyID, UInt32 inPropertyDataSize, const void* inPropertyData);

//	Implementation
protected:
	void				InitializeChannelStateList();
	void				ResetChannelStateList();

	struct	ChannelState
	{
		SInt32			mPredictedSample;
		SInt16			mStepTableIndex;
		
		ChannelState() : mPredictedSample(0), mStepTableIndex(0) {}
		void Reset() { mPredictedSample = 0; mStepTableIndex = 0; }
	};
	
	typedef std::vector<ChannelState>	ChannelStateList;
	ChannelStateList	mChannelStateList;

//	Implementation Constants
protected:
	enum
	{
		kIMAFramesPerPacket = 64,
		kBytesPerChannelPerPacket = 32,
		kHeaderBytes = 2,
		kInputBufferPackets = 32,
		kIMA4PacketBytes = kHeaderBytes + kBytesPerChannelPerPacket
	};
	static const UInt16	kPredictorMask;
	static const UInt16	kStepTableIndexMask;
	static const SInt32	kPredictorTolerance;
	static const SInt16	sIndexTable[16];
	static const SInt16	sStepTable[89];

};

#endif