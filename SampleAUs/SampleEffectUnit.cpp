/*
     File: SampleEffectUnit.cpp
 Abstract: SampleEffectUnit.h
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
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit.cpp
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "AUEffectBase.h"
#include "SampleEffectUnitVersion.h"

#include <AudioUnit/AudioUnitProperties.h>

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ____SampleEffectUnit

// Setup unit presets
static const int kPreset_One = 0;
static const int kPreset_Two = 1;
static const int kNumberPresets = 2;

static AUPreset kPresets[kNumberPresets] = 
    {
        { kPreset_One, CFSTR("Preset One") },		
        { kPreset_Two, CFSTR("Preset Two") }		
	};
	
static const int kPresetDefault = kPreset_One;
static const int kPresetDefaultIndex = 0;

static bool sLocalized = false;

class SampleEffectUnit : public AUEffectBase
{
public:
								SampleEffectUnit(AudioUnit component);
	
	virtual AUKernelBase *		NewKernel() { return new SampleEffectKernel(this); }
	
    virtual	OSStatus			GetParameterValueStrings(	AudioUnitScope			inScope,
                                                            AudioUnitParameterID	inParameterID,
                                                            CFArrayRef *			outStrings	);
    
	virtual	OSStatus			GetParameterInfo(	AudioUnitScope			inScope,
                                                    AudioUnitParameterID	inParameterID,
													AudioUnitParameterInfo	&outParameterInfo	);
    
	virtual OSStatus			GetPropertyInfo(	AudioUnitPropertyID		inID,
													AudioUnitScope			inScope,
													AudioUnitElement		inElement,
													UInt32 &				outDataSize,
													Boolean	&				outWritable );

	virtual OSStatus			GetProperty(		AudioUnitPropertyID inID,
													AudioUnitScope 		inScope,
													AudioUnitElement 	inElement,
													void *				outData );
    
    // handle presets:
    virtual OSStatus			GetPresets(	CFArrayRef	*outData	)	const;
    
    virtual OSStatus			NewFactoryPresetSet (	const AUPreset & inNewFactoryPreset	);

    // Some hosting apps will REQUIRE that you support this property (and others won't), but
    // it is advisable for maximal compatibility that you do support this (and report a conservative
    // but reasonable value.)
	virtual	bool				SupportsTail () { return true; }

		/*! @method Version */
	virtual OSStatus		Version() { return kSampleEffectUnitVersion; }


protected:
	class SampleEffectKernel : public AUKernelBase		// most real work happens here
	{
	public:
		SampleEffectKernel(AUEffectBase *inAudioUnit )
			: AUKernelBase(inAudioUnit)
		{
// Initialize per-channel state of this effect processor
		}

// Required overides for the process method for this effect
		// processes one channel of interleaved samples
		virtual void 		Process(	const AudioUnitSampleType *	inSourceP,
										AudioUnitSampleType *		inDestP,
										UInt32						inFramesToProcess,
										UInt32						inNumChannels,
                                        bool &						ioSilence);

        virtual void		Reset();

	//private: //state variables...
	};
    
};

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AUDIOCOMPONENT_ENTRY(AUBaseFactory, SampleEffectUnit)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Unique constants for this effect

// parameters
static const float kDefaultValue_ParamOne = 0.5;
static const float kDefaultValue_ParamTwo = 50;
static const float kDefaultValue_ParamThree_Indexed = 5;
static const float kDefaultValue_ParamFour = 0;

static CFStringRef kParameterOneName = CFSTR("Parameter One");
static CFStringRef kParameterTwoName = CFSTR("Parameter Two");
static CFStringRef kParameterThree_IndexedName = CFSTR("Indexed Parameter");
static CFStringRef kParameterFourName = CFSTR("Parameter Four");

// here are the value names for parameter THREE!
static CFStringRef kParameterValueStringsOne   = CFSTR( "First Value" );
static CFStringRef kParameterValueStringsTwo   = CFSTR( "Second Value" );
static CFStringRef kParameterValueStringsThree = CFSTR( "Third Value" );


enum {
	kParam_One,
	kParam_Two,
    kParam_Three_Indexed,
	kParam_Four,
	kNumberOfParameters
};

//	Paramter 3 (index #2) is an indexed parameter, and implements
//	the kAudioUnitProperty_ParameterValueStrings property.
static const AudioUnitParameterID kEffectParam_TestIndex = kParam_One;

// parameter four has a name for values <= its minimum value
// it implements the kAudioUnitProperty_ParameterStringFromValue property
// param 4 will return a name string of "- infinity" for values <= -120
static const AudioUnitParameterValue kMinValue_ParamFour = -120;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::SampleEffectUnit
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SampleEffectUnit::SampleEffectUnit(AudioUnit component)
	: AUEffectBase(component)
{
	CreateElements();

	if (!sLocalized) {		
		// Because we are in a component, we need to load our bundle by identifier so we can access our localized strings
		// It is important that the string passed here exactly matches that in the Info.plist Identifier string
		CFBundleRef bundle = CFBundleGetBundleWithIdentifier( CFSTR("com.acme.audiounit.passthrough") );
		
		if (bundle != NULL) {
			for (int i = 0; i < kNumberPresets; i++ ) {
				kPresets[i].presetName = CFCopyLocalizedStringFromTableInBundle(
					kPresets[i].presetName, 	// string to localize
					CFSTR("Localizable"),   		// strings file to search
					bundle, 					// bundle to search
					CFSTR(""));						// no comment
			}
			
			kParameterValueStringsOne = CFCopyLocalizedStringFromTableInBundle(kParameterValueStringsOne,     CFSTR("Localizable"), bundle, CFSTR(""));
			kParameterValueStringsTwo = CFCopyLocalizedStringFromTableInBundle(kParameterValueStringsTwo,     CFSTR("Localizable"), bundle, CFSTR(""));
			kParameterValueStringsThree = CFCopyLocalizedStringFromTableInBundle(kParameterValueStringsThree, CFSTR("Localizable"), bundle, CFSTR(""));
	
			kParameterOneName = CFCopyLocalizedStringFromTableInBundle(kParameterOneName, CFSTR("Localizable"), bundle, CFSTR(""));
			kParameterTwoName = CFCopyLocalizedStringFromTableInBundle(kParameterTwoName, CFSTR("Localizable"), bundle, CFSTR(""));
			
			kParameterThree_IndexedName = CFCopyLocalizedStringFromTableInBundle(kParameterThree_IndexedName, CFSTR("Localizable"), bundle, CFSTR(""));	
			kParameterFourName = CFCopyLocalizedStringFromTableInBundle(kParameterFourName, CFSTR("Localizable"), bundle, CFSTR(""));	
		}
		sLocalized = true; //so never pass the test again...
	}

// example of setting up params...	

	SetParameter(kParam_One, 				kDefaultValue_ParamOne );
	SetParameter(kParam_Two, 				kDefaultValue_ParamTwo );
	SetParameter(kParam_Three_Indexed, 		kDefaultValue_ParamThree_Indexed );
	SetParameter(kParam_Four,				kDefaultValue_ParamFour );
        
    SetAFactoryPresetAsCurrent (kPresets[kPresetDefaultIndex]);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::GetParameterValueStrings
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OSStatus			SampleEffectUnit::GetParameterValueStrings(	AudioUnitScope			inScope,
                                                                AudioUnitParameterID	inParameterID,
                                                                CFArrayRef *			outStrings)
{
    if ( (inScope == kAudioUnitScope_Global) && (inParameterID == kParam_Three_Indexed) ) {
        if (outStrings == NULL) return noErr; //called by GetPropInfo
		
		CFStringRef	strings[] = {	kParameterValueStringsOne, kParameterValueStringsTwo, kParameterValueStringsThree };
	   
		*outStrings = CFArrayCreate( NULL, (const void **)strings, 3, NULL);
        
        return noErr;
    }
    
    return kAudioUnitErr_InvalidProperty;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::GetParameterInfo
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OSStatus			SampleEffectUnit::GetParameterInfo(	AudioUnitScope			inScope,
                                                        AudioUnitParameterID	inParameterID,
                                                        AudioUnitParameterInfo	&outParameterInfo )
{
	OSStatus result = noErr;

	outParameterInfo.flags = 	kAudioUnitParameterFlag_IsWritable
						|		kAudioUnitParameterFlag_IsReadable;
    
    if (inScope == kAudioUnitScope_Global) {
        switch(inParameterID)
        {
            case kParam_One:
                AUBase::FillInParameterName (outParameterInfo, kParameterOneName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_CustomUnit;
                outParameterInfo.minValue = 0.0;
                outParameterInfo.maxValue = 1;
				outParameterInfo.unitName = CFStringCreateWithCString (kCFAllocatorDefault, "custom", kCFStringEncodingASCII);
                outParameterInfo.defaultValue = kDefaultValue_ParamOne;
                break;
    
            case kParam_Two:
                AUBase::FillInParameterName (outParameterInfo, kParameterTwoName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_Seconds;
                outParameterInfo.minValue = 0.0;
                outParameterInfo.maxValue = 75.0;
                outParameterInfo.defaultValue = kDefaultValue_ParamTwo;
                break;
            
            case kParam_Three_Indexed:
                AUBase::FillInParameterName (outParameterInfo, kParameterThree_IndexedName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_Indexed;
                outParameterInfo.minValue = 4;
                outParameterInfo.maxValue = 6;
                outParameterInfo.defaultValue = kDefaultValue_ParamThree_Indexed;
                break;
 
			case kParam_Four:
                AUBase::FillInParameterName (outParameterInfo, kParameterFourName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_Decibels;
                outParameterInfo.minValue = kMinValue_ParamFour;
                outParameterInfo.maxValue = 6.0;
                outParameterInfo.defaultValue = kDefaultValue_ParamFour;
				outParameterInfo.flags |= kAudioUnitParameterFlag_ValuesHaveStrings;
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
//	SampleEffectUnit::GetPropertyInfo
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OSStatus			SampleEffectUnit::GetPropertyInfo (AudioUnitPropertyID	inID,
												AudioUnitScope					inScope,
												AudioUnitElement				inElement,
												UInt32 &						outDataSize,
												Boolean &						outWritable)
{
	if (inScope == kAudioUnitScope_Global) {
		switch (inID) {
			case kAudioUnitProperty_ParameterStringFromValue:
				outWritable = false;
				outDataSize = sizeof (AudioUnitParameterStringFromValue);
				return noErr;
            
			case kAudioUnitProperty_ParameterValueFromString:
				outWritable = false;
				outDataSize = sizeof (AudioUnitParameterValueFromString);
				return noErr;
		}
	}
	return AUEffectBase::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::GetProperty
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OSStatus			SampleEffectUnit::GetProperty (AudioUnitPropertyID 		inID,
									  AudioUnitScope 					inScope,
									  AudioUnitElement			 		inElement,
									  void *							outData)
{
	if (inScope == kAudioUnitScope_Global) {
		switch (inID) {            
			case kAudioUnitProperty_ParameterValueFromString:
			{
                OSStatus retVal = kAudioUnitErr_InvalidPropertyValue;
				AudioUnitParameterValueFromString &name = *(AudioUnitParameterValueFromString*)outData;
				if (name.inParamID != kParam_Four)
					return kAudioUnitErr_InvalidParameter;
				if (name.inString == NULL)
                    return kAudioUnitErr_InvalidPropertyValue;
                
                UniChar chars[2];
                chars[0] = '-';
                chars[1] = 0x221e; // this is the unicode symbol for infinity
                CFStringRef comparisonString = CFStringCreateWithCharacters (NULL, chars, 2);
                
                if ( CFStringCompare(comparisonString, name.inString, 0) == kCFCompareEqualTo ) {
                    name.outValue = kMinValue_ParamFour;
                    retVal = noErr;
                }
                
                if (comparisonString) CFRelease(comparisonString);
                
				return retVal;
			}
			case kAudioUnitProperty_ParameterStringFromValue:
			{
				AudioUnitParameterStringFromValue &name = *(AudioUnitParameterStringFromValue*)outData;
				if (name.inParamID != kParam_Four)
					return kAudioUnitErr_InvalidParameter;
				
				AudioUnitParameterValue paramValue = (name.inValue == NULL
													? GetParameter (kParam_Four)
													: *(name.inValue));
										
				// for this usage only values <= -120 dB (the min value) have
				// a special name "-infinity"
				if (paramValue <= kMinValue_ParamFour) {
					UniChar chars[2];
					chars[0] = '-';
					chars[1] = 0x221e; // this is the unicode symbol for infinity
					name.outString = CFStringCreateWithCharacters (NULL, chars, 2);
				} else
					name.outString = NULL;

				return noErr;
			}
		}
	}
	return AUEffectBase::GetProperty (inID, inScope, inElement, outData);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::GetPresets
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OSStatus			SampleEffectUnit::GetPresets (		CFArrayRef * 					outData) const
{
		// this is now used to determine if presets are supported 
		// (which in this unit they are so we implement this method!
	if (outData == NULL) return noErr;
	
	CFMutableArrayRef theArray = CFArrayCreateMutable (NULL, kNumberPresets, NULL);
	for (int i = 0; i < kNumberPresets; ++i) {
		CFArrayAppendValue (theArray, &kPresets[i]);
    }
    
	*outData = (CFArrayRef)theArray;
	return noErr;
}

OSStatus			SampleEffectUnit::NewFactoryPresetSet (const AUPreset & inNewFactoryPreset)
{
	SInt32 chosenPreset = inNewFactoryPreset.presetNumber;
	for (int i = 0; i < kNumberPresets; ++i) {
		if (chosenPreset == kPresets[i].presetNumber) {
            
            // set whatever state you need to based on this preset's selection
            
            SetAFactoryPresetAsCurrent (kPresets[i]);
			return noErr;
		}
	}
	
	return kAudioUnitErr_InvalidPropertyValue;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ____SampleEffectKernel


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::SampleEffectKernel::Reset()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void		SampleEffectUnit::SampleEffectKernel::Reset()
{
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	SampleEffectUnit::SampleEffectKernel::Process
//
//		pass-through unit
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void SampleEffectUnit::SampleEffectKernel::Process(	const AudioUnitSampleType *			inSourceP,
                                                    AudioUnitSampleType *				inDestP,
                                                    UInt32							inFramesToProcess,
                                                    UInt32							inNumChannels,
                                                    bool &							ioSilence )
{
// we should be doing something with the silence flag if it is true
// like not doing any work because:
// (1) we would only be processing silence and
// (2) we don't have any latency or tail times to worry about here
//
// So, we don't reset this flag, because it is true on input and we're not doing anything
// to it so we want it to be true on output.


// BUT: your code probably will need to take into account tail processing (or latency) that 
// it has once its input becomes silent... then at some point in the future, your output
// will also be silent.
    
	
	UInt32 nSampleFrames = inFramesToProcess;
	const AudioUnitSampleType *sourceP = inSourceP;
	AudioUnitSampleType *destP = inDestP;
		
	while (nSampleFrames-- > 0) {
		AudioUnitSampleType inputSample = *sourceP;
		sourceP += inNumChannels;	// advance to next frame (e.g. if stereo, we're advancing 2 samples);
									// we're only processing one of an arbitrary number of interleaved channels

			// memcpy is really better at doing this!!!!!
			// here's where you do your DSP work
		AudioUnitSampleType outputSample = inputSample;
		
		*destP = outputSample;
		destP += inNumChannels;
	}
}
