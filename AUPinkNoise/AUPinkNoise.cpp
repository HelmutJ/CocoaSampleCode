/*
 <codex>
 <abstract>AUPinkNoise.h</abstract>
 <\codex>
*/
#include "AUPinkNoise.h"
#include "AUBaseHelper.h"

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AUDIOCOMPONENT_ENTRY(AUBaseFactory, AUPinkNoise)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AUPinkNoise::AUPinkNoise(AudioUnit component)
	: AUBase(component, 0, 1),
	  mPink (NULL)
{
	CreateElements();
	Globals()->UseIndexedParameters(kNumberOfParameters);
	SetParameter(kParam_Volume, kAudioUnitScope_Global, 0, kDefaultValue_Volume, 0);
	SetParameter(kParam_On, kAudioUnitScope_Global, 0, 1, 0);
}

void				AUPinkNoise::Cleanup()
{
	delete mPink;
	mPink = NULL;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::Initialize()
{
	const CAStreamBasicDescription & theDesc = GetStreamFormat(kAudioUnitScope_Output, 0);
	
	mPink = new PinkNoiseGenerator::PinkNoiseGenerator(theDesc.mSampleRate);
	
	return noErr;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::GetPropertyInfo (	AudioUnitPropertyID				inID,
															AudioUnitScope					inScope,
															AudioUnitElement				inElement,
															UInt32 &						outDataSize,
															Boolean &						outWritable)
{
	if (inScope == kAudioUnitScope_Global)
	{
		switch (inID)
		{
			case kAudioUnitProperty_CocoaUI:
					outWritable = false;
					outDataSize = sizeof(AudioUnitCocoaViewInfo);
					return noErr;
									
			default:
				return kAudioUnitErr_InvalidProperty;				
		}
	}

	return AUBase::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::GetProperty (	AudioUnitPropertyID 		inID,
														AudioUnitScope 				inScope,
														AudioUnitElement			inElement,
														void *						outData)
{
	if (inScope == kAudioUnitScope_Global)
	{
		switch (inID)
		{
			case kAudioUnitProperty_CocoaUI:
			{
				CFURLRef bundleURL = CFURLCreateWithFileSystemPath(	kCFAllocatorDefault, 
																	CFSTR("/System/Library/Frameworks/CoreAudioKit.framework"), 
																	kCFURLPOSIXPathStyle, 
																	TRUE);
				if (bundleURL == NULL) return fnfErr;
		
				CFStringRef className = CFSTR("AUGenericViewFactory");
				AudioUnitCocoaViewInfo cocoaInfo = { bundleURL, {className} };
				*((AudioUnitCocoaViewInfo *)outData) = cocoaInfo;
				
				return noErr;
			}
		}
	}
	
	return AUBase::GetProperty (inID, inScope, inElement, outData);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::GetParameterInfo(AudioUnitScope		inScope,
                                                        AudioUnitParameterID	inParameterID,
                                                        AudioUnitParameterInfo	&outParameterInfo )
{
	OSStatus result = noErr;

	outParameterInfo.flags = 	kAudioUnitParameterFlag_IsWritable
						|		kAudioUnitParameterFlag_IsReadable;
    
    if (inScope == kAudioUnitScope_Global) {
        switch(inParameterID)
        {
            case kParam_Volume:
                AUBase::FillInParameterName (outParameterInfo, kParameterVolumeName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_LinearGain;
                outParameterInfo.minValue = 0.0;
                outParameterInfo.maxValue = 1;
                outParameterInfo.defaultValue = kDefaultValue_Volume;
				outParameterInfo.flags |= kAudioUnitParameterFlag_DisplaySquareRoot;
                break;
            case kParam_On:
                AUBase::FillInParameterName (outParameterInfo, kParameterOnName, false);
                outParameterInfo.unit = kAudioUnitParameterUnit_Boolean;
                outParameterInfo.minValue = 0.0;
                outParameterInfo.maxValue = 1;
                outParameterInfo.defaultValue = 1;
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

bool				AUPinkNoise::StreamFormatWritable(	AudioUnitScope					scope,
																AudioUnitElement				element)
{
	return IsInitialized() ? false : true;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

UInt32				AUPinkNoise::SupportedNumChannels (	const AUChannelInfo** 			outInfo)
{
	static const AUChannelInfo sChannels[1] = { {0, -1} };
	if (outInfo) *outInfo = sChannels;
	return sizeof (sChannels) / sizeof (AUChannelInfo);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

UInt32				AUPinkNoise::GetChannelLayoutTags(	AudioUnitScope				scope,
														AudioUnitElement 			element,
														AudioChannelLayoutTag *		outLayoutTags)
{
	if (scope != kAudioUnitScope_Output) COMPONENT_THROW(kAudioUnitErr_InvalidScope);
	if (element != 0) COMPONENT_THROW(kAudioUnitErr_InvalidElement);
	
	if (outLayoutTags)
	{
		UInt32 numChannels = GetOutput(element)->GetStreamFormat().NumberChannels();
		if(numChannels == 1)
			outLayoutTags[0] = kAudioChannelLayoutTag_Mono;
		else if(numChannels == 2)
			outLayoutTags[0] = kAudioChannelLayoutTag_Stereo;
		else if(numChannels == 4)
			outLayoutTags[0] = kAudioChannelLayoutTag_Quadraphonic;
		else if(numChannels == 5)
			outLayoutTags[0] = kAudioChannelLayoutTag_Pentagonal;
		else if(numChannels == 6)
			outLayoutTags[0] = kAudioChannelLayoutTag_Hexagonal;
		else if(numChannels == 8)
			outLayoutTags[0] = kAudioChannelLayoutTag_Octagonal;
		else
			COMPONENT_THROW(kAudioUnitErr_InvalidPropertyValue);
	}
	
	return 1;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
														
UInt32				AUPinkNoise::GetAudioChannelLayout(	AudioUnitScope				scope,
														AudioUnitElement 			element,
														AudioChannelLayout *		outLayoutPtr,
														Boolean &					outWritable)
{
	if (scope != kAudioUnitScope_Output) COMPONENT_THROW(kAudioUnitErr_InvalidScope);
	if (element != 0) COMPONENT_THROW(kAudioUnitErr_InvalidElement);		

	UInt32 size = mOutputChannelLayout.IsValid() ? mOutputChannelLayout.Size() : 0;
	if (size > 0 && outLayoutPtr)
		memcpy(outLayoutPtr, mOutputChannelLayout, size);
	outWritable = true;
	return size;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::SetAudioChannelLayout(	AudioUnitScope 				scope, 
														AudioUnitElement 			element,
														const AudioChannelLayout *	inLayout)
{
	if (scope != kAudioUnitScope_Output) return kAudioUnitErr_InvalidScope;
	if (element != 0) return kAudioUnitErr_InvalidElement;	

	UInt32 layoutChannels = inLayout ? CAAudioChannelLayout::NumberChannels(*inLayout) : 0;
	
	if (inLayout != NULL && GetOutput(element)->GetStreamFormat().NumberChannels() != layoutChannels)
		return kAudioUnitErr_InvalidPropertyValue;

	if (inLayout)
		mOutputChannelLayout = inLayout;
	else
		mOutputChannelLayout = CAAudioChannelLayout();
		
	return noErr;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus			AUPinkNoise::RemoveAudioChannelLayout(AudioUnitScope scope, AudioUnitElement element)
{
	if (scope != kAudioUnitScope_Output) return kAudioUnitErr_InvalidScope;
	if (element != 0) return kAudioUnitErr_InvalidElement;		
	mOutputChannelLayout = CAAudioChannelLayout();

	return noErr;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OSStatus 	AUPinkNoise::Render(		AudioUnitRenderActionFlags &ioActionFlags,
												const AudioTimeStamp &		inTimeStamp,
												UInt32						nFrames)
{		
	AUOutputElement* outputBus = GetOutput(0);
	outputBus->PrepareBuffer(nFrames); // prepare the output buffer list
	
	AudioBufferList& outputBufList = outputBus->GetBufferList();
	AUBufferList::ZeroBuffer(outputBufList);	
	
	// only render if the on parameter is true. Otherwise send the zeroed buffer
	if (Globals()->GetParameter(kParam_On))
	{
		for (UInt32 i=0; i < outputBufList.mNumberBuffers; i++)
			mPink->Render((Float32*)outputBufList.mBuffers[i].mData, nFrames, Globals()->GetParameter(kParam_Volume));
	}	
	return noErr;
}

