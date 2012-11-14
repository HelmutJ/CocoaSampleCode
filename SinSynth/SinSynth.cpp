/*
     File: SinSynth.cpp
 Abstract: SinSynth.h
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
#include "SinSynth.h"
 
static const UInt32 kMaxActiveNotes = 8;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const double twopi = 2.0 * 3.14159265358979;

inline double pow5(double x) { double x2 = x*x; return x2*x2*x; }

#pragma mark SinSynth Methods

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AUDIOCOMPONENT_ENTRY(AUMusicDeviceFactory, SinSynth)

static const AudioUnitParameterID kGlobalVolumeParam = 0;
static const CFStringRef kGlobalVolumeName = CFSTR("global volume");

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SinSynth::SinSynth
//
// This synth has No inputs, One output
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SinSynth::SinSynth(ComponentInstance inComponentInstance)
	: AUMonotimbralInstrumentBase(inComponentInstance, 0, 1)
{
	CreateElements();
	
	Globals()->UseIndexedParameters(1); // we're only defining one param
	Globals()->SetParameter (kGlobalVolumeParam, 1.0);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SinSynth::~SinSynth
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SinSynth::~SinSynth()
{
}


void SinSynth::Cleanup()
{
#if DEBUG_PRINT
	printf("SinSynth::Cleanup\n");
#endif
}

OSStatus SinSynth::Initialize()
{	
#if DEBUG_PRINT
	printf("->SinSynth::Initialize\n");
#endif
	AUMonotimbralInstrumentBase::Initialize();
	
	SetNotes(kNumNotes, kMaxActiveNotes, mTestNotes, sizeof(TestNote));
#if DEBUG_PRINT
	printf("<-SinSynth::Initialize\n");
#endif
	
	return noErr;
}

AUElement* SinSynth::CreateElement(	AudioUnitScope					scope,
									AudioUnitElement				element)
{
	switch (scope)
	{
		case kAudioUnitScope_Group :
			return new SynthGroupElement(this, element, new MidiControls);
		case kAudioUnitScope_Part :
			return new SynthPartElement(this, element);
		default :
			return AUBase::CreateElement(scope, element);
	}
}

OSStatus			SinSynth::GetParameterInfo(		AudioUnitScope					inScope,
														AudioUnitParameterID			inParameterID,
														AudioUnitParameterInfo &		outParameterInfo)
{
	if (inParameterID != kGlobalVolumeParam) return kAudioUnitErr_InvalidParameter;
	if (inScope != kAudioUnitScope_Global) return kAudioUnitErr_InvalidScope;

	outParameterInfo.flags = SetAudioUnitParameterDisplayType (0, kAudioUnitParameterFlag_DisplaySquareRoot);
    outParameterInfo.flags += kAudioUnitParameterFlag_IsWritable;
	outParameterInfo.flags += kAudioUnitParameterFlag_IsReadable;

	AUBase::FillInParameterName (outParameterInfo, kGlobalVolumeName, false);
	outParameterInfo.unit = kAudioUnitParameterUnit_LinearGain;
	outParameterInfo.minValue = 0;
	outParameterInfo.maxValue = 1.0;
	outParameterInfo.defaultValue = 1.0;
	return noErr;
}


#pragma mark TestNote Methods

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void			TestNote::Release(UInt32 inFrame)
{
	SynthNote::Release(inFrame);
#if DEBUG_PRINT
	printf("TestNote::Release %p %d\n", this, GetState());
#endif
}

void			TestNote::FastRelease(UInt32 inFrame) // voice is being stolen.
{
	SynthNote::Release(inFrame);
#if DEBUG_PRINT
	printf("TestNote::Release %p %d\n", this, GetState());
#endif
}

void			TestNote::Kill(UInt32 inFrame) // voice is being stolen.
{
	SynthNote::Kill(inFrame);
#if DEBUG_PRINT
	printf("TestNote::Kill %p %d\n", this, GetState());
#endif
}

OSStatus		TestNote::Render(UInt64 inAbsoluteSampleFrame, UInt32 inNumFrames, AudioBufferList** inBufferList, UInt32 inOutBusCount)
{
	float *left, *right;
/* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~	
	Changes to this parameter (kGlobalVolumeParam) are not being de-zippered; 
	Left as an exercise for the reader
 ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
	float globalVol = GetGlobalParameter(kGlobalVolumeParam);
	
	// TestNote only writes into the first bus regardless of what is handed to us.
	const int bus0 = 0;
	int numChans = inBufferList[bus0]->mNumberBuffers;
	if (numChans > 2) return -1;
	
	left = (float*)inBufferList[bus0]->mBuffers[0].mData;
	right = numChans == 2 ? (float*)inBufferList[bus0]->mBuffers[1].mData : 0;

	double sampleRate = SampleRate();
	double freq = Frequency() * (twopi/sampleRate);

	
#if DEBUG_PRINT_RENDER
	printf("TestNote::Render %p %d %g %g\n", this, GetState(), phase, amp);
#endif
	switch (GetState())
	{
		case kNoteState_Attacked :
		case kNoteState_Sostenutoed :
		case kNoteState_ReleasedButSostenutoed :
		case kNoteState_ReleasedButSustained :
			{
				for (UInt32 frame=0; frame<inNumFrames; ++frame)
				{
					if (amp < maxamp) amp += up_slope;
					float out = pow5(sin(phase)) * amp * globalVol;
					phase += freq;
					if (phase > twopi) phase -= twopi;
					left[frame] += out;
					if (right) right[frame] += out;
				}
			}
			break;
			
		case kNoteState_Released :
			{
				UInt32 endFrame = 0xFFFFFFFF;
				for (UInt32 frame=0; frame<inNumFrames; ++frame)
				{
					if (amp > 0.0) amp += dn_slope;
					else if (endFrame == 0xFFFFFFFF) endFrame = frame;
					float out = pow5(sin(phase)) * amp * globalVol;
					phase += freq;
					left[frame] += out;
					if (right) right[frame] += out;
				}
				if (endFrame != 0xFFFFFFFF) {
#if DEBUG_PRINT
					printf("TestNote::NoteEnded  %p %d %g %g\n", this, GetState(), phase, amp);
#endif
					NoteEnded(endFrame);
				}
			}
			break;
			
		case kNoteState_FastReleased :
			{
				UInt32 endFrame = 0xFFFFFFFF;
				for (UInt32 frame=0; frame<inNumFrames; ++frame)
				{
					if (amp > 0.0) amp += fast_dn_slope;
					else if (endFrame == 0xFFFFFFFF) endFrame = frame;
					float out = pow5(sin(phase)) * amp * globalVol;
					phase += freq;
					left[frame] += out;
					if (right) right[frame] += out;
				}
				if (endFrame != 0xFFFFFFFF) {
#if DEBUG_PRINT
					printf("TestNote::NoteEnded  %p %d %g %g\n", this, GetState(), phase, amp);
#endif
					NoteEnded(endFrame);
				}
			}
			break;
		default :
			break;
	}
	return noErr;
}

