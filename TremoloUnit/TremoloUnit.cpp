/*
     File: TremoloUnit.cpp
 Abstract: TremoloUnit.h
  Version: 1.1
 
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
// This file defines the TremoloUnit class, as well as the TremoloUnitEffectKernel
//  helper class.

#include "TremoloUnit.h"

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AUDIOCOMPONENT_ENTRY(AUBaseFactory, TremoloUnit)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// The COMPONENT_ENTRY macro is required for the Mac OS X Component Manager to recognize and 
// use the audio unit

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::TremoloUnit
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// The constructor for new TremoloUnit audio units
TremoloUnit::TremoloUnit (AudioUnit component) : AUEffectBase (component) {

	// This method, defined in the AUBase superclass, ensures that the required audio unit
	//  elements are created and initialized.
	CreateElements ();
	
	// Invokes the use of an STL vector for parameter access.  
	//  See AUBase/AUScopeElement.cpp
	Globals () -> UseIndexedParameters (kNumberOfParameters);

	// During instantiation, sets up the parameters according to their defaults.
	//	The parameter defaults should correspond to the settings for the default preset.
	SetParameter (
		kParameter_Frequency, 
		kDefaultValue_Tremolo_Freq 
	);
        
	SetParameter (
		kParameter_Depth, 
		kDefaultValue_Tremolo_Depth 
	);
        
	SetParameter (
		kParameter_Waveform, 
		kDefaultValue_Tremolo_Waveform 
	);

	// Also during instantiation, sets the preset menu to indicate the default preset,
	//	which corresponds to the default parameters. It's possible to set this so a
	//	fresh audio unit indicates the wrong preset, so be careful to get it right.
	SetAFactoryPresetAsCurrent (
		kPresets [kPreset_Default]
	);
        
	#if AU_DEBUG_DISPATCHER
		mDebugDispatcher = new AUDebugDispatcher (this);
	#endif
}


#pragma mark ____Parameters

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::GetParameterInfo
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Called by the audio unit's view; provides information needed for the view to display the
//  audio unit's parameters
ComponentResult TremoloUnit::GetParameterInfo (
		AudioUnitScope			inScope,
		AudioUnitParameterID	inParameterID,
		AudioUnitParameterInfo	&outParameterInfo
) {
	ComponentResult result = noErr;

	// Adds two flags to all parameters for the audio unit, indicating to the host application 
	// that it should consider all the audio unit’s parameters to be readable and writable.
	outParameterInfo.flags = 	  
		kAudioUnitParameterFlag_IsWritable | kAudioUnitParameterFlag_IsReadable;
    
    // All three parameters for this audio unit are in the "global" scope.
	if (inScope == kAudioUnitScope_Global) {
        switch (inParameterID) {
		
            case kParameter_Frequency:
			// Invoked when the view needs information for the kTremoloParam_Frequency 
			// parameter; defines how to represent this parameter in the user interface.
				AUBase::FillInParameterName (
					outParameterInfo,
					kParamName_Tremolo_Freq,
					false
				);
				outParameterInfo.unit			= kAudioUnitParameterUnit_Hertz;
					// Sets the unit of measurement for the Frequency parameter to Hertz.
				outParameterInfo.minValue		= kMinimumValue_Tremolo_Freq;
					// Sets the minimum value for the Frequency parameter.
				outParameterInfo.maxValue		= kMaximumValue_Tremolo_Freq;
					// Sets the maximum value for the Frequency parameter.
				outParameterInfo.defaultValue	= kDefaultValue_Tremolo_Freq;
					// Sets the default value for the Frequency parameter.
				outParameterInfo.flags			|= kAudioUnitParameterFlag_DisplayLogarithmic;
					// Adds a flag to indicate to the host that it should use a logarithmic 
					// control for the Frequency parameter.
				break;

            case kParameter_Depth:
			// Invoked when the view needs information for the kTremoloParam_Depth parameter.
				AUBase::FillInParameterName (
					outParameterInfo,
					kParamName_Tremolo_Depth,
					false
				);
				outParameterInfo.unit			= kAudioUnitParameterUnit_Percent;
				outParameterInfo.minValue		= kMinimumValue_Tremolo_Depth;
				outParameterInfo.maxValue		= kMaximumValue_Tremolo_Depth;
				outParameterInfo.defaultValue	= kDefaultValue_Tremolo_Depth;
				break;

            case kParameter_Waveform:
			// Invoked when the view needs information for the kTremoloParam_Waveform parameter.
				AUBase::FillInParameterName (
					outParameterInfo,
					kParamName_Tremolo_Waveform,
					false
				);
				outParameterInfo.unit			= kAudioUnitParameterUnit_Indexed;
				// Sets the unit of measurement for the Waveform parameter to "indexed," allowing 
				// it to be displayed as a pop-up menu in the generic view. The following three 
				// statements set the minimum, maximum, and default values for the depth parameter. 
				// All three are required for proper functioning of the parameter's user interface.
				outParameterInfo.minValue		= kSineWave_Tremolo_Waveform;
				outParameterInfo.maxValue		= kSquareWave_Tremolo_Waveform;
				outParameterInfo.defaultValue	= kDefaultValue_Tremolo_Waveform;
				break;

			default:
				result = kAudioUnitErr_InvalidParameter;
				break;
		}
	} else {
        result = kAudioUnitErr_InvalidParameter;
    }
	return result;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::GetParameterValueStrings
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Provides the strings for the Waveform popup menu in the generic view
ComponentResult TremoloUnit::GetParameterValueStrings (
	AudioUnitScope			inScope,
	AudioUnitParameterID	inParameterID,
	CFArrayRef				*outStrings
) {
	if ((inScope == kAudioUnitScope_Global) && (inParameterID == kParameter_Waveform)) {
	// This method applies only to the waveform parameter, which is in the global scope.
	
		// When this method gets called by the AUBase::DispatchGetPropertyInfo method, which 
		// provides a null value for the outStrings parameter, just return without error.
		if (outStrings == NULL) return noErr;
		
		// Defines an array that contains the pop-up menu item names.
		CFStringRef	strings [] = {
			kMenuItem_Tremolo_Sine,
			kMenuItem_Tremolo_Square
		};
   
		// Creates a new immutable array containing the menu item names, and places the array 
		// in the outStrings output parameter.
		*outStrings = CFArrayCreate (
			NULL,
			(const void **) strings,
			(sizeof (strings) / sizeof (strings [0])),
			NULL
		);
		return noErr;
    }
    return kAudioUnitErr_InvalidParameter;
}

#pragma mark ____Properties

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::GetPropertyInfo
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ComponentResult TremoloUnit::GetPropertyInfo (
	// This audio unit doesn't define any custom properties, so it uses this generic code for
	// this method.
	AudioUnitPropertyID	inID,
	AudioUnitScope		inScope,
	AudioUnitElement	inElement,
	UInt32				&outDataSize,
	Boolean				&outWritable
) {
	return AUEffectBase::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::GetProperty
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ComponentResult TremoloUnit::GetProperty (
	// This audio unit doesn't define any custom properties, so it uses this generic code for
	// this method.
	AudioUnitPropertyID inID,
	AudioUnitScope 		inScope,
	AudioUnitElement 	inElement,
	void				*outData
) {
	return AUEffectBase::GetProperty (inID, inScope, inElement, outData);
}

#pragma mark ____Factory Presets

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::GetPresets
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// For users to be able to use the factory presets you define, you must add a generic 
// implementation of the GetPresets method. The code here works for any audio unit that can 
// support factory presets.

// The GetPresets method accepts a single parameter, a pointer to a CFArrayRef object. This 
// object holds the factory presets array generated by this method. The array contains just 
// factory preset numbers and names. The host application uses this array to set up its 
// factory presets menu and when calling the NewFactoryPresetSet method.

ComponentResult TremoloUnit::GetPresets (
	CFArrayRef	*outData
) const {

	// Checks whether factory presets are implemented for this audio unit.
	if (outData == NULL) return noErr;
	
	// Instantiates a mutable Core Foundation array to hold the factory presets.
	CFMutableArrayRef presetsArray = CFArrayCreateMutable (
		NULL,
		kNumberPresets,
		NULL
	);
	
	// Fills the factory presets array with values from the definitions in the TremoloUnit.h 
	// file.
	for (int i = 0; i < kNumberPresets; ++i) {
		CFArrayAppendValue (
			presetsArray,
			&kPresets [i]
		);
    }
    
	// Stores the factory presets array at the outData location.
	*outData = (CFArrayRef) presetsArray;
	return noErr;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::NewFactoryPresetSet
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// The NewFactoryPresetSet method defines all the factory presets for an audio unit. Basically, 
// for each preset, it invokes a series of SetParameter calls.

// This method takes a single argument of type AUPreset, a structure containing a factory
//  preset name and number.
OSStatus TremoloUnit::NewFactoryPresetSet (
	const AUPreset &inNewFactoryPreset
) {
	// Gets the number of the desired factory preset.
	SInt32 chosenPreset = inNewFactoryPreset.presetNumber;
	
	if (
		// Tests whether the desired factory preset is defined.
		chosenPreset == kPreset_Slow ||
		chosenPreset == kPreset_Fast
	) {
		// This 'for' loop, and the 'if' statement that follows it, allow for noncontiguous preset 
		// numbers.
		for (int i = 0; i < kNumberPresets; ++i) {
			if (chosenPreset == kPresets[i].presetNumber) {

				//Selects the appropriate case statement based on the factory preset number.
				switch (chosenPreset) {

					// The settings for the "Slow & Gentle" factory preset.
					case kPreset_Slow:
						SetParameter (
							kParameter_Frequency,
							kParameter_Preset_Frequency_Slow
						);
						SetParameter (
							kParameter_Depth,
							kParameter_Preset_Depth_Slow
						);
						SetParameter (
							kParameter_Waveform,
							kParameter_Preset_Waveform_Slow
						);
						break;
					
					// The settings for the "Fast & Hard" factory preset.
					case kPreset_Fast:
						SetParameter (
							kParameter_Frequency,
							kParameter_Preset_Frequency_Fast
						);
						SetParameter (
							kParameter_Depth,
							kParameter_Preset_Depth_Fast
						);
						SetParameter (
							kParameter_Waveform,
							kParameter_Preset_Waveform_Fast
						);
						break;
				}
				
				// Updates the preset menu in the generic view to display the new factory preset.
				SetAFactoryPresetAsCurrent (
					kPresets [i]
				);
				return noErr;
			}
		}
	}
	return kAudioUnitErr_InvalidProperty;
}



#pragma mark ____TremoloUnitEffectKernel

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::TremoloUnitKernel::TremoloUnitKernel()
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This is the constructor for the TremoloUnitKernel helper class, which holds the DSP code 
//  for the audio unit. TremoloUnit is an n-to-n audio unit; one kernel object gets built for 
//  each channel in the audio unit.
//
// The first line of the method consists of the constructor method declarator and constructor-
//  initializer. In addition to calling the appropriate superclasses, this code initializes two 
//  member variables:
//
// mCurrentScale:		a factor for correlating points in the current wave table to
//						the audio signal sampling frequency. to produce the desired
//						tremolo frequency
// mSamplesProcessed:	a global count of samples processed. it allows the tremolo effect
//						to be continuous over data input buffer boundaries
//
// (In the Xcode template, the header file contains the call to the superclass constructor.)
TremoloUnit::TremoloUnitKernel::TremoloUnitKernel (AUEffectBase *inAudioUnit ) : AUKernelBase (inAudioUnit),
	mSamplesProcessed (0), mCurrentScale (0)
{	
	// Generates a wave table that represents one cycle of a sine wave, normalized so that
	//  it never goes negative and so it ranges between 0 and 1; this sine wave specifies 
	//  how to vary the volume during one cycle of tremolo.
	for (int i = 0; i < kWaveArraySize; ++i) {
		double radians = i * 2.0 * pi / kWaveArraySize;
		mSine [i] = (sin (radians) + 1.0) * 0.5;
	}

	// Does the same for a pseudo square wave, with nice rounded corners to avoid pops.
	for (int i = 0; i < kWaveArraySize; ++i) {
		double radians = i * 2.0 * pi / kWaveArraySize;
		radians = radians + 0.32; // shift the wave over for a smoother start
		mSquare [i] =
			(
				sin (radians) +	// Sums the odd harmonics, scaled for a nice final waveform
				0.3 * sin (3 * radians) +
				0.15 * sin (5 * radians) +
				0.075 * sin (7 * radians) +
				0.0375 * sin (9 * radians) +
				0.01875 * sin (11 * radians) +
				0.009375 * sin (13 * radians) +
				0.8			// Shifts the value so it doesn't go negative.
			) * 0.63;		// Scales the waveform so the peak value is close 
							//  to unity gain.
	}

	// Gets the samples per second of the audio stream provided to the audio unit. 
	// Obtaining this value here in the constructor assumes that the sample rate
	// will not change during one instantiation of the audio unit.
	mSampleFrequency = GetSampleRate ();
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::TremoloUnitKernel::Reset()
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Because we're calculating each output sample based on a unique input sample, there's no 
// need to clear any buffers. We simply reinitialize the variables that were initialized on
// instantiation of the kernel object.
void TremoloUnit::TremoloUnitKernel::Reset() {
	mCurrentScale		= 0;
	mSamplesProcessed	= 0;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TremoloUnit::TremoloUnitKernel::Process
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This method contains the DSP code. 
void TremoloUnit::TremoloUnitKernel::Process (
	const Float32 	*inSourceP,			// The audio sample input buffer.
	Float32		 	*inDestP,			// The audio sample output buffer.
	UInt32 			inSamplesToProcess,	// The number of samples in the input buffer.
	UInt32			inNumChannels,		// The number of input channels. This is always equal to 1 
										//   because there is always one kernel object instantiated
										//   per channel of audio.
	bool			&ioSilence			// A Boolean flag indicating whether the input to the audio 
										//   unit consists of silence, with a TRUE value indicating 
										//   silence.
) {
	// Ignores the request to perform the Process method if the input to the audio unit is silence.
	if (!ioSilence) {

		// Assigns a pointer variable to the start of the audio sample input buffer.
		const Float32 *sourceP = inSourceP;

		// Assigns a pointer variable to the start of the audio sample output buffer.
		Float32	*destP = inDestP,
				inputSample,			// The current audio sample to process.
				outputSample,			// The current audio output sample resulting from one iteration of the
										//   processing loop.
				tremoloFrequency,		// The tremolo frequency requested by the user via the audio unit's view.
				tremoloDepth,			// The tremolo depth requested by the user via the audio unit's view.
				samplesPerTremoloCycle,	// The number of audio samples in one cycle of the tremolo waveform.
				rawTremoloGain,			// The tremolo gain for the current audio sample, as stored in the wave table.
				tremoloGain;			// The adjusted tremolo gain for the current audio sample, considering the 
										//   Depth parameter.
				
		int		tremoloWaveform;		// The tremolo waveform type requested by the user via the audio unit's view.

		
		// Once per input buffer, gets the tremolo frequency (in Hz) from the user 
		//	via the audio unit view.
		tremoloFrequency = GetParameter (kParameter_Frequency);
		
		// Once per input buffer, gets the depth (in percent) from the user via 
		//	the audio unit view.
		tremoloDepth = GetParameter (kParameter_Depth);

		// Once per input buffer, gets the tremolo waveform type from the user via 
		//	the audio unit view.
		tremoloWaveform =  (int) GetParameter (kParameter_Waveform);
        
        if (tremoloWaveform != kSineWave_Tremolo_Waveform
            && tremoloWaveform != kSquareWave_Tremolo_Waveform)
            tremoloWaveform = kSineWave_Tremolo_Waveform;
		
		// Assigns a pointer to the wave table for the user-selected tremolo wave form.
		if (tremoloWaveform == kSineWave_Tremolo_Waveform)  {
			waveArrayPointer = &mSine [0];
		} else {
			waveArrayPointer = &mSquare [0];
		}
		
		// Performs bounds checking on the parameters.
		if (tremoloFrequency	< kMinimumValue_Tremolo_Freq)
			tremoloFrequency	= kMinimumValue_Tremolo_Freq;
		if (tremoloFrequency	> kMaximumValue_Tremolo_Freq)
			tremoloFrequency	= kMaximumValue_Tremolo_Freq;

		if (tremoloDepth		< kMinimumValue_Tremolo_Depth)
			tremoloDepth		= kMinimumValue_Tremolo_Depth;
		if (tremoloDepth		> kMaximumValue_Tremolo_Depth)
			tremoloDepth		= kMaximumValue_Tremolo_Depth;

		// Calculates the number of audio samples per cycle of tremolo frequency.
		samplesPerTremoloCycle	= mSampleFrequency / tremoloFrequency;
		
		// Calculates the scaling factor to use for applying the wave table to the current sampling 
		//  frequency and tremolo frequency.
		mNextScale				= kWaveArraySize / samplesPerTremoloCycle;
		/*
			An explanation of the scaling factor (mNextScale)
			-------------------------------------------------
			Say that the audio sample frequency is 10 kHz and that the tremolo frequency is 
			10.0 Hz. the number of audio samples per tremolo cycle is then 1,000.
			
			For a wave table of length 1,000, the scaling factor is then unity (1.0). This means 
			that the wave table happens to be the exact size needed for each point in the table 
			to correspond to exactly one sample.

			If the tremolo frequency slows to 1.0 Hz, then the number of samples per tremolo 
			cycle rises to 10,000. The scaling factor is then 0.1. This means that every 10th 
			element of the wave table array corresponds to a sample.
			
			If the tremolo frequency increases to 20 Hz, the samples per tremolo cycle lowers to
			500. The scaling factor is then 1,000/500 = 2.0. In this case, two samples in a row 
			need to make use of the same point in the wave table.
		*/
			
		// The sample processing loop: processes the current batch of samples, one sample at a time.
		for (int i = inSamplesToProcess; i > 0; --i) {
		
			// The following statement calculates the position in the wave table ("index") to 
			// use for the current sample. This position, along with the calculation of 
			// mNextScale, is the only subtle math for this audio unit.
			//
			// "index" is the position marker in the wave table. The wave table is an array; 
			//		index varies from 0 to kWaveArraySize.
			//
			//	"index" is also the number of samples processed since the last 
			//	counter reset, divided by the number of samples that play during one pass 
			//	through the wave table, modulo the size of the wave table (see "An explanation...",
			//  above).
			int index = static_cast<long>(mSamplesProcessed * mCurrentScale) % kWaveArraySize;

			// If the user has moved the tremolo frequency slider, changes the scale factor
			// at the next positive zero crossing of the tremolo sine wave and resets the 
			// mSamplesProcessed value so it stays in sync with the index position.
			if ((mNextScale != mCurrentScale) && (index == 0)) {
				mCurrentScale = mNextScale;
				mSamplesProcessed = 0;
			}

			// If the audio unit runs for a long time without the user moving the
			// tremolo frequency slider, resets the mSamplesProcessed value at the 
			// next positive zero crossing of the tremolo sine wave.
			if ((mSamplesProcessed >= sampleLimit) && (index == 0))
				mSamplesProcessed = 0;

			// Gets the raw tremolo gain from the appropriate wave table.
			rawTremoloGain = waveArrayPointer [index];

			// Calculates the final tremolo gain according to the depth setting.
			tremoloGain			= (rawTremoloGain * tremoloDepth - tremoloDepth + 100.0) * 0.01;
			
			// Gets the next input sample.
			inputSample			= *sourceP;
			
			// Calculates the next output sample.
			outputSample		= (inputSample * tremoloGain);
			
			// Stores the output sample in the output buffer.
			*destP				= outputSample;
			
			// Advances to the next sample location in the input and output buffers.
			sourceP				+= 1;
			destP				+= 1;
			
			// Increments the global samples counter.
			mSamplesProcessed	+= 1;
		}
	}
}


