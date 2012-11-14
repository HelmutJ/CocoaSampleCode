/*
     File: SinSynthWithMidi.cpp
 Abstract: SinSynthWithMidi.h
  Version: 1.2
 
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
/*
	This is a subclass of SinSynth that demonstrates how to use the midi output properties kAudioUnitProperty_MIDIOutputCallbackInfo, and kAudioUnitProperty_MIDIOutputCallback
	defined in AudioUnitProperties.h. Using these properties, the SinSynthWithMidi simply passes through the midi data it receives. Use of these properties requires host support.
	
	To build a version of the SinSynth with this functionality, activate the "SinSynth with MIDI Output" target in Xcode.
*/

#include "SinSynth.h"
#include <CoreMidi/MIDIServices.h>
#include <vector>

typedef struct MIDIMessageInfoStruct {
	UInt8	status;
	UInt8	channel;
	UInt8	data1;
	UInt8	data2;
	UInt32	startFrame;
} MIDIMessageInfoStruct;


class MIDIOutputCallbackHelper 
{
	enum  { kSizeofMIDIBuffer = 512 };
	
public:
							MIDIOutputCallbackHelper() 
							{
								mMIDIMessageList.reserve (64); 
								mMIDICallbackStruct.midiOutputCallback = NULL;
								mMIDIBuffer = new Byte[kSizeofMIDIBuffer];
							}

							~MIDIOutputCallbackHelper() 
							{
								delete [] mMIDIBuffer;
							}
							
	void					SetCallbackInfo (AUMIDIOutputCallback & callback, void *userData) 
							{
								mMIDICallbackStruct.midiOutputCallback = callback; 
								mMIDICallbackStruct.userData = userData;
							}
	
	void					AddMIDIEvent (UInt8		status,
										UInt8		channel,
										UInt8		data1,
										UInt8		data2, 
										UInt32		inStartFrame );
							
	void					FireAtTimeStamp(const AudioTimeStamp &inTimeStamp);

	
private:
	MIDIPacketList		  * PacketList() 
							{
								return (MIDIPacketList *)mMIDIBuffer; 
							}

	
	Byte *						mMIDIBuffer;
	
	AUMIDIOutputCallbackStruct	mMIDICallbackStruct;

	typedef std::vector<MIDIMessageInfoStruct> MIDIMessageList;
	MIDIMessageList				mMIDIMessageList;
};

class SinSynthWithMidi : public SinSynth {
public:
								SinSynthWithMidi(ComponentInstance inComponentInstance);
	virtual						~SinSynthWithMidi();
	
	virtual OSStatus			GetPropertyInfo(		AudioUnitPropertyID				inID,
														AudioUnitScope					inScope,
														AudioUnitElement				inElement,
														UInt32 &						outDataSize,
														Boolean &						outWritable);
	
	virtual OSStatus			GetProperty(			AudioUnitPropertyID				inID,
														AudioUnitScope					inScope,
														AudioUnitElement				inElement,
														void *							outData);
														
	virtual OSStatus			SetProperty(			AudioUnitPropertyID 			inID,
														AudioUnitScope 					inScope,
														AudioUnitElement 				inElement,
														const void *					inData,
														UInt32 							inDataSize);
														
			OSStatus			HandleMidiEvent(		UInt8							status, 
														UInt8							channel, 
														UInt8							data1, 
														UInt8							data2, 
														UInt32							inStartFrame);
	
			OSStatus			Render(					AudioUnitRenderActionFlags &	ioActionFlags,
														const AudioTimeStamp &			inTimeStamp,
														UInt32							inNumberFrames);

private:
	MIDIOutputCallbackHelper	mCallbackHelper;
	TestNote					mTestNotes[kNumNotes];
};

#pragma mark MIDIOutputCallbackHelper Methods

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void MIDIOutputCallbackHelper::AddMIDIEvent(UInt8	status, 
										UInt8		channel,
										UInt8		data1, 
										UInt8		data2, 
										UInt32		inStartFrame) 
{
	MIDIMessageInfoStruct info = {status, channel, data1, data2, inStartFrame};	
	mMIDIMessageList.push_back(info);
}

void MIDIOutputCallbackHelper::FireAtTimeStamp(const AudioTimeStamp &inTimeStamp) 
{
	if (!mMIDIMessageList.empty())
	{
		if (mMIDICallbackStruct.midiOutputCallback) 
		{
			// synthesize the packet list and call the MIDIOutputCallback
			// iterate through the vector and get each item
			MIDIPacketList *pktlist = PacketList();

			MIDIPacket *pkt = MIDIPacketListInit(pktlist);
			
			for (MIDIMessageList::iterator iter = mMIDIMessageList.begin(); iter != mMIDIMessageList.end(); iter++) 
			{
				const MIDIMessageInfoStruct & item = *iter;
								
				Byte midiStatusByte = item.status + item.channel;
				const Byte data[3] = { midiStatusByte, item.data1, item.data2 };
				UInt32 midiDataCount = ((item.status == 0xC || item.status == 0xD) ? 2 : 3);
				pkt = MIDIPacketListAdd (pktlist, 
											kSizeofMIDIBuffer, 
											pkt, 
											item.startFrame, 
											midiDataCount, 
											data);
				if (!pkt)
				{
						// send what we have and then clear the buffer and then go through this again
					// issue the callback with what we got
					OSStatus result = (*mMIDICallbackStruct.midiOutputCallback) (mMIDICallbackStruct.userData, &inTimeStamp, 0, pktlist);
					if (result != noErr)
						printf("error calling output callback: %d", (int) result);
					
					// clear stuff we've already processed, and fire again
					mMIDIMessageList.erase (mMIDIMessageList.begin(), iter);
					FireAtTimeStamp(inTimeStamp);
					return;
				}
			}
			
			// fire callback
			OSStatus result = (*mMIDICallbackStruct.midiOutputCallback) (mMIDICallbackStruct.userData, &inTimeStamp, 0, pktlist);
			if (result != noErr)
				printf("error calling output callback: %d", (int) result);
		}
		mMIDIMessageList.clear();
	}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark SinSynthWithMidi Methods

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AUDIOCOMPONENT_ENTRY(AUMusicDeviceFactory, SinSynthWithMidi)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SinSynthWithMidi::SinSynthWithMidi
//
// This synth has No inputs, One output
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SinSynthWithMidi::SinSynthWithMidi(ComponentInstance inComponentInstance)
	: SinSynth(inComponentInstance)
{
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SinSynthWithMidi::~SinSynthWithMidi
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SinSynthWithMidi::~SinSynthWithMidi()
{}

OSStatus			SinSynthWithMidi::GetPropertyInfo(		AudioUnitPropertyID				inID,
													AudioUnitScope					inScope,
													AudioUnitElement				inElement,
													UInt32 &						outDataSize,
													Boolean &						outWritable)
{
	if (inScope == kAudioUnitScope_Global) {
		if (inID == kAudioUnitProperty_MIDIOutputCallbackInfo) {
			outDataSize = sizeof(CFArrayRef);
			outWritable = false;
			return noErr;
		} else if (inID == kAudioUnitProperty_MIDIOutputCallback) {
			outDataSize = sizeof(AUMIDIOutputCallbackStruct);
			outWritable = true;
			return noErr;
		}
	}
	return SinSynth::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

OSStatus			SinSynthWithMidi::GetProperty(	AudioUnitPropertyID		inID,
											AudioUnitScope			inScope,
											AudioUnitElement		inElement,
											void *					outData)
{
	if (inScope == kAudioUnitScope_Global) 
	{
		if (inID == kAudioUnitProperty_MIDIOutputCallbackInfo) {
			CFStringRef strs[1];
			strs[0] = CFSTR("MIDI Callback");
			
			CFArrayRef callbackArray = CFArrayCreate(NULL, (const void **)strs, 1, &kCFTypeArrayCallBacks);
			*(CFArrayRef *)outData = callbackArray;
			return noErr;
		}
	}
	return SinSynth::GetProperty (inID, inScope, inElement, outData);
}

OSStatus			SinSynthWithMidi::SetProperty(	AudioUnitPropertyID 			inID,
													AudioUnitScope 					inScope,
													AudioUnitElement 				inElement,
													const void *					inData,
													UInt32 							inDataSize)
{
	if (inScope == kAudioUnitScope_Global) 
	{
		if (inID == kAudioUnitProperty_MIDIOutputCallback) {
			if (inDataSize < sizeof(AUMIDIOutputCallbackStruct)) return kAudioUnitErr_InvalidPropertyValue;
			
			AUMIDIOutputCallbackStruct *callbackStruct = (AUMIDIOutputCallbackStruct *)inData;
			mCallbackHelper.SetCallbackInfo(callbackStruct->midiOutputCallback, callbackStruct->userData);
			return noErr;
		}
	}
	return SinSynth::SetProperty(inID, inScope, inElement, inData, inDataSize);
}

OSStatus 	SinSynthWithMidi::HandleMidiEvent(UInt8 status, UInt8 channel, UInt8 data1, UInt8 data2, UInt32 inStartFrame) 
{
	// snag the midi event and then store it in a vector	
	mCallbackHelper.AddMIDIEvent(status, channel, data1, data2, inStartFrame);
	
	return AUMIDIBase::HandleMidiEvent(status, channel, data1, data2, inStartFrame);
}

OSStatus	SinSynthWithMidi::Render(   AudioUnitRenderActionFlags &		ioActionFlags,
											const AudioTimeStamp &			inTimeStamp,
											UInt32							inNumberFrames) 
{
	OSStatus result = AUInstrumentBase::Render(ioActionFlags, inTimeStamp, inNumberFrames);
	if (result == noErr) {
		mCallbackHelper.FireAtTimeStamp(inTimeStamp);
	} 
	return result;
}
