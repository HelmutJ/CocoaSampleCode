/*
     File: Controller.m
 Abstract: Controller.h
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
#import "Controller.h"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Extension API Procs
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef OSStatus	(*alcASAGetListenerProcPtr)	(const ALuint property, ALvoid *data, ALuint *dataSize);
OSStatus  alcASAGetListenerProc(const ALuint property, ALvoid *data, ALuint *dataSize)
{
    OSStatus	err = noErr;
	static	alcASAGetListenerProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcASAGetListenerProcPtr) alcGetProcAddress(NULL, "alcASAGetListener");
    }
    
    if (proc)
        err = proc(property, data, dataSize);
    return (err);
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

@implementation Controller

- (void)myObserver:(NSNotification *)inNotification
{
	float	x,z;
	int		objIndex;
	[[view scene]	getCurrentObjectPosition: &objIndex : &x : &z];
	
	switch(objIndex)
	{
		case kSourceOneIndex:
			[mSourceOneXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
			[mSourceOneZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			break;

		case kSourceTwoIndex:
			[mSourceTwoXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
			[mSourceTwoZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			break;

		case kSourceThreeIndex:
			[mSourceThreeXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
			[mSourceThreeZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			break;

		case kSourceFourIndex:
			[mSourceFourXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
			[mSourceFourZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			break;

		case kCaptureSourceIndex:
			if ([[view scene] hasInput])
			{
				[mCaptureSourceXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
				[mCaptureSourceZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			}
			break;

		case kListenerIndex:
			[mListenerXPos setStringValue: [NSString stringWithFormat: @"%.1f", x]];
			[mListenerZPos setStringValue: [NSString stringWithFormat: @"%.1f", z]];
			break;
	}
	
	
	//NSLog(@"Message recieved");
}

- (void) awakeFromNib
{
	float	x, z;
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(myObserver:) name: @"OALNotify" object: NULL];

	[mainWindow setDelegate:(id) self];

	// only enable the capture source if capture is available
	if ([[view scene] hasInput])
	{
		// enable the capture controls
		[mCaptureSourceGainSlider setEnabled: true];
		[mCaptureSourcePitchSlider setEnabled: true];
		[mCaptureSourceOnCheckbox setEnabled: true];
		[mCaptureSourceCaptureSamplesButton setEnabled: true];

		[mCaptureSourceConesCheckbox setEnabled: true];
		[mCaptureSourceAngleSlider setEnabled: true];
		[mCaptureSourceVelocitySlider setEnabled: true];
		[mCaptureSourceInnerConeAngleSlider setEnabled: true];
		[mCaptureSourceOuterConeAngleSlider setEnabled: true];
		[mCaptureSourceOuterConeGainSlider setEnabled: true];

		[mCaptureSourceXPosition setEnabled: true];
		[mCaptureSourceZPosition setEnabled: true];
		[mCaptureSourceYPosition setEnabled: true];
		[mCaptureSourceReferenceDistance setEnabled: true];
		[mCaptureSourceMaxDistance setEnabled: true];
		[mCaptureSourceRolloffFactor setEnabled: true];

		[[view scene]	getObjectPosition: kCaptureSourceIndex : &x : &z];

		[mCaptureSourceXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
		[mCaptureSourceYPosition setStringValue: [NSString stringWithFormat: @"%.1f", 0.0]];
		[mCaptureSourceZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];

		[mCaptureSourceGain setStringValue: [NSString stringWithFormat: @"%.1f", 1.0]];
		[mCaptureSourcePitch setStringValue: [NSString stringWithFormat: @"%.1f", 1.0]];

		[mCaptureSourceXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", 0.0]];
		[mCaptureSourceZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", 0.0]];
		[mCaptureSourceVelocity setStringValue: [NSString stringWithFormat: @"%.1f", 0.0]];

		[mCaptureSourceInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", 90.0]];
		[mCaptureSourceOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", 180.0]];
		[mCaptureSourceOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", 0.0]];

		if ([[view scene] hasASAExtension])
		{
			[mCaptureSourceReverbSlider setEnabled: true];
			[mCaptureSourceOcclusionSlider setEnabled: true];
			[mCaptureSourceObstructionSlider setEnabled: true];
			[mCaptureSourceReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", 0.0]];
			[mCaptureSourceOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", 0.0]];
			[mCaptureSourceObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", 0.0]];
		}
	}

	// Enable ASA Features is extension is present
	if ([[view scene] hasASAExtension])
	{
		[mListenerReverbLevel setEnabled: true];
		[mListenerReverbLevelSlider setEnabled: true];
		[mReverbEQFrequency setEnabled: true];
		[mReverbEQFrequencySlider setEnabled: true];
		[mReverbEQBandwidth setEnabled: true];
		[mReverbEQBandwidthSlider setEnabled: true];
		[mReverbEQGain setEnabled: true];
		[mReverbEQGainSlider setEnabled: true];

		[mReverbOnCheckbox setEnabled: true];
		[mReverbQualityPU setEnabled: true];
		[mReverbRoomtypePU setEnabled: true];
		
		// populate the Reverb Room Preset PU (mReverbRoomtypePU) with any aupresets found in Contents/Resources/ReverbPresets of the app bundle
		NSArray*	pathsArray =[[NSBundle mainBundle] pathsForResourcesOfType:@"aupreset" inDirectory:@"ReverbPresets"];
		int	pathCount = [pathsArray count];
		int i;
		NSString*	presetPath = NULL;
		for(i = 0; i < pathCount; i++)
		{
			presetPath = [pathsArray objectAtIndex:i];
			if (presetPath)
			{
				CFURLRef url = CFURLCreateWithString(NULL, (CFStringRef) presetPath, NULL);				
				if (url)
				{
					CFURLRef nuURL = CFURLCreateCopyDeletingPathExtension(kCFAllocatorDefault, url);	// strip the .aupreset extension
					if (nuURL)
					{
						CFStringRef lastPathComponent = CFURLCopyLastPathComponent (nuURL);				// get the preset name
						if (lastPathComponent)
						{
							[mReverbRoomtypePU addItemWithTitle: (NSString*) lastPathComponent];
							CFRelease(lastPathComponent);
						}
						CFRelease(nuURL);
					}
					CFRelease(url);
				}
			}
		}				
	}

	// position text
	[[view scene]	getObjectPosition: kSourceOneIndex : &x : &z];
	[mSourceOneXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
	[mSourceOneZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];

	[[view scene]	getObjectPosition: kSourceTwoIndex : &x : &z];
	[mSourceTwoXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
	[mSourceTwoZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];

	[[view scene]	getObjectPosition: kSourceThreeIndex : &x : &z];
	[mSourceThreeXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
	[mSourceThreeZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];

	[[view scene]	getObjectPosition: kSourceFourIndex : &x : &z];
	[mSourceFourXPosition setStringValue: [NSString stringWithFormat: @"%.1f", x]];
	[mSourceFourZPosition setStringValue: [NSString stringWithFormat: @"%.1f", z]];

	// get current values of source attributes to diplay in UI at start up time
	[mSourceOneReferenceDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceReferenceDistance:0]]];
	[mSourceTwoReferenceDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceReferenceDistance:1]]];
	[mSourceThreeReferenceDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceReferenceDistance:2]]];
	[mSourceFourReferenceDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceReferenceDistance:3]]];
	[mCaptureSourceReferenceDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceReferenceDistance:4]]];

	[mSourceOneMaxDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceMaxDistance:0]]];
	[mSourceTwoMaxDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceMaxDistance:1]]];
	[mSourceThreeMaxDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceMaxDistance:2]]];
	[mSourceFourMaxDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceMaxDistance:3]]];
	[mCaptureSourceMaxDistance setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceMaxDistance:4]]];
	
	[mSourceOneRolloffFactor setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceRolloffFactor:0]]];
	[mSourceTwoRolloffFactor setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceRolloffFactor:1]]];
	[mSourceThreeRolloffFactor setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceRolloffFactor:2]]];
	[mSourceFourRolloffFactor setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceRolloffFactor:3]]];
	[mCaptureSourceRolloffFactor setStringValue: [NSString stringWithFormat: @"%.1f", [[view scene] getSourceRolloffFactor:4]]];
	
	// doppler factor
	float	setting = alGetFloat(AL_DOPPLER_FACTOR);
	[mDopplerFactor setStringValue: [NSString stringWithFormat: @"%.2f", setting]];
	[mDopplerFactorSlider setFloatValue: setting];			// move the corresponding slider

	// speed of sound
	setting = alGetFloat(AL_SPEED_OF_SOUND);
	[mSpeedOfSound setStringValue: [NSString stringWithFormat: @"%.2f", setting]];
	[mSpeedOfSoundSlider setFloatValue: setting];			// move the corresponding slider

	// display some info about the library
	
	// SEE IF STRING IS RETURNED FIRST SO THESE WON'T CRASH ON A NULL STRING
	if (alGetString(AL_EXTENSIONS))
		[mALExtensionList setStringValue: [NSString stringWithUTF8String: (const char *) alGetString(AL_EXTENSIONS)]];
	if ( alcGetString(alcGetContextsDevice(alcGetCurrentContext()), ALC_EXTENSIONS))
		[mALCExtensionList setStringValue: [NSString stringWithUTF8String: (const char *) alcGetString(alcGetContextsDevice(alcGetCurrentContext()), ALC_EXTENSIONS)]];
	if (alcGetString(NULL, ALC_DEFAULT_DEVICE_SPECIFIER))
		[mALCDefaultDeviceName setStringValue: [NSString stringWithUTF8String: (const char *) alcGetString(NULL, ALC_DEFAULT_DEVICE_SPECIFIER)]];

	if (alcGetString(NULL, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER))
		[mALCCaptureDefaultDeviceName setStringValue: [NSString stringWithUTF8String: (const char *) alcGetString(NULL, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER)]];
	if (alGetString(AL_VERSION))
		[mALVersion setStringValue: [NSString stringWithUTF8String: (const char *) alGetString(AL_VERSION)]];	
}


#pragma mark ***** Listener Controls *****
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setListenerDirectionSlider:(id)inSender
{
	// orient the listener and get it x & z velocities
	float	xVelocity, zVelocity;
	[[view scene] setListenerOrientation:[inSender floatValue] : &xVelocity : &zVelocity];

	// update the x & z velocity text
	[mListenerXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", xVelocity]];
	[mListenerZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", zVelocity]];

	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// this is a velocity scaler that is applied to the direction the listener is facing 
- (IBAction)setListenerVelocitySlider:(id)inSender
{
	float	velocity = [inSender floatValue];
	[mListenerVelocityScaler setStringValue: [NSString stringWithFormat: @"%.2f", velocity]];
		
	float	xVelocity, zVelocity;
	[[view scene] setListenerVelocity:velocity : &xVelocity : &zVelocity];
	
	// update the x & z velocity text
	[mListenerXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", xVelocity]];
	[mListenerZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", zVelocity]];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setListenerGainSlider:(id)inSender
{
	float	gain = [inSender floatValue];
	[mListenerGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
		
	[[view scene] setListenerGain:gain];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setListenerElevationSlider:(id)inSender
{
	float	elevation = [inSender floatValue];
	[mListenerElevation setStringValue: [NSString stringWithFormat: @"%.2f", elevation]];
		
	[[view scene] setListenerElevation:elevation];
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setDopplerFactorSlider:(id)inSender
{
	float	setting = [inSender floatValue];
	[mDopplerFactor setStringValue: [NSString stringWithFormat: @"%.2f", setting]];
		
	[[view scene] setDopplerFactor:setting];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSpeedOfSoundSlider:(id)inSender
{
	float	setting = [inSender floatValue];
	[mSpeedOfSound setStringValue: [NSString stringWithFormat: @"%.2f", setting]];
		
	[[view scene] setSpeedOfSound:setting];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setDistanceModelPU:(id)inSender
{
	int		tag = [[inSender selectedItem] tag];
		
	[[view scene] setDistanceModel:tag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setRenderChannelsCheckbox:(id)inSender
{
	int channels = [inSender intValue];
		
	[[view scene] setRenderChannels:channels];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setRenderQualityCheckbox:(id)inSender
{
	int quality = [inSender intValue];
		
	[[view scene] setRenderQuality:quality];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CONTEXT REVERB
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ***** Listener Reverb *****
- (IBAction)	setReverbLevelSlider:(id)inSender
{
	float	level = [inSender floatValue];
	[mListenerReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
		
	[[view scene] setGlobalReverb:level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbEQGainSlider:(id)inSender
{
	float	level = [inSender floatValue];
	[mReverbEQGain setStringValue: [NSString stringWithFormat: @"%.2f", level]];
	[[view scene] setReverbEQGain:level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbEQBandwidthSlider:(id)inSender
{
	float	level = [inSender floatValue];
	[mReverbEQBandwidth setStringValue: [NSString stringWithFormat: @"%.2f", level]];
	[[view scene] setReverbEQBandwidth:level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbEQFrequencySlider:(id)inSender
{
	float	level = [inSender floatValue];
	[mReverbEQFrequency setStringValue: [NSString stringWithFormat: @"%.2f", level]];
	[[view scene] setReverbEQFrequency:level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbOnCheckbox:(id)inSender
{
	int state = [inSender intValue];
		
	[[view scene] setReverbOn:state];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbQualityPU:(id)inSender;
{
	int		tag = [[inSender selectedItem] tag];
		
	[[view scene] setReverbQuality:tag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setReverbRoomTypePU:(id)inSender
{
	int			index = [inSender indexOfSelectedItem];
	int			tag = [[inSender selectedItem] tag];
	NSString*	itemText = [inSender titleOfSelectedItem];
		
	[[view scene] setReverbRoomType:tag controlIndex:index title:itemText];
	
	// get the reverb freq, gain and badwidth and set the sliders and text now..........
	float	gain=0.0, bd=0.0, freq=0.0;
	ALuint	size;
	
	usleep(50000);
	
	// update EQ Bandwidth Controls
	size =  sizeof(bd);
	alcASAGetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_BANDWITH"), &bd, &size);
	[mReverbEQBandwidth setStringValue: [NSString stringWithFormat: @"%.2f", bd]];
	[mReverbEQBandwidthSlider setFloatValue: bd];	// move the corresponding slider
	
	// update EQ Frequency Controls
	size =  sizeof(freq);
	alcASAGetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_FREQ"), &freq, &size);
	[mReverbEQFrequency setStringValue: [NSString stringWithFormat: @"%.2f", freq]];
	[mReverbEQFrequencySlider setFloatValue: freq];	// move the corresponding slider

	// update EQ Gain Controls
	size =  sizeof(gain);
	alcASAGetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_GAIN"), &gain, &size);
	[mReverbEQGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
	[mReverbEQGainSlider setFloatValue: gain];		// move the corresponding slider
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// SOURCE SETTINGS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ***** Source Controls *****
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setSourceGainSlider:(id)inSender
{
	float	gain = [inSender floatValue];
	int		tag = [inSender tag];

	// update the corresponding text field
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceFourIndex:
			[mSourceFourGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
	}
		
	[[view scene] setSourceGain:tag :gain];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setSourcePitchSlider:(id)inSender
{
	float	pitch = [inSender floatValue];
	int		tag = [inSender tag];

	// update the corresponding text field
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOnePitch setStringValue: [NSString stringWithFormat: @"%.2f", pitch]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoPitch setStringValue: [NSString stringWithFormat: @"%.2f", pitch]];
			break;
		case kSourceThreeIndex:
			[mSourceThreePitch setStringValue: [NSString stringWithFormat: @"%.2f", pitch]];
			break;
		case kSourceFourIndex:
			[mSourceFourPitch setStringValue: [NSString stringWithFormat: @"%.2f", pitch]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourcePitch setStringValue: [NSString stringWithFormat: @"%.2f", pitch]];
			break;
	}
		
	[[view scene] setSourcePitch:tag :pitch];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)setSourceAngleSlider:(id)inSender
{
	int		tag = [inSender tag];
	float	outX, outZ;

	[[view scene] setSourceAngle:tag :[inSender floatValue]];	
	[[view scene] getSourceVelocities:tag :&outX : &outZ];

	// update the corresponding text fields
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceOneZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceTwoZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceThreeZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceFourIndex:
			[mSourceFourXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceFourZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mCaptureSourceZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
	}
	
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceVelocitySlider:(id)inSender
{
	float	velocity = [inSender floatValue];
	int		tag = [inSender tag];

	float outX, outZ;
	[[view scene] setSourceVelocity:tag :velocity];
	[[view scene] getSourceVelocities:tag :&outX : &outZ];

	// update the corresponding text fields
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneVelocity setStringValue: [NSString stringWithFormat: @"%.1f", velocity]];
			[mSourceOneXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceOneZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoVelocity setStringValue: [NSString stringWithFormat: @"%.1f", velocity]];
			[mSourceTwoXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceTwoZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeVelocity setStringValue: [NSString stringWithFormat: @"%.1f", velocity]];
			[mSourceThreeXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceThreeZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kSourceFourIndex:
			[mSourceFourVelocity setStringValue: [NSString stringWithFormat: @"%.1f", velocity]];
			[mSourceFourXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mSourceFourZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceVelocity setStringValue: [NSString stringWithFormat: @"%.1f", velocity]];
			[mCaptureSourceXVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outX]];
			[mCaptureSourceZVelocity setStringValue: [NSString stringWithFormat: @"%.1f", outZ]];
			break;
	}
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceOuterConeGainSlider:(id)inSender
{
	float	gain = [inSender floatValue];
	int		tag = [inSender tag];

	[[view scene] setSourceOuterConeGain:tag :gain];

	// update the corresponding text fields
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kSourceFourIndex:
			[mSourceFourOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceOuterConeGain setStringValue: [NSString stringWithFormat: @"%.2f", gain]];
			break;
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceOuterConeAngleSlider:(id)inSender
{
	float	angle = [inSender floatValue];
	int		tag = [inSender tag];

	[[view scene] setSourceOuterConeAngle:tag :angle];

	// update the corresponding text fields
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceFourIndex:
			[mSourceFourOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceOuterConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
	}
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceInnerConeAngleSlider:(id)inSender
{
	float	angle = [inSender floatValue];
	int		tag = [inSender tag];

	[[view scene] setSourceInnerConeAngle:tag :angle];

	// update the corresponding text fields
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kSourceFourIndex:
			[mSourceFourInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceInnerConeAngle setStringValue: [NSString stringWithFormat: @"%.2f", angle]];
			break;
	}
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceUseConesCheckBox:(id)inSender
{
	int		tag = [inSender tag];
	int state = [inSender intValue];

	[[view scene] setSourceDirectionOnOff:tag :state];
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourcePlayStatesCheckBox:(id)inSender
{
	int		tag = [inSender tag];
	int state = [inSender intValue];

	[[view scene] setSourcePlayState:tag :state];
	[view setNeedsDisplay:YES];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ***** Source Effects *****

- (IBAction)	setSourceReverbSlider:(id)inSender
{
	float	level = [inSender floatValue];
	int		tag = [inSender tag];

	// update the corresponding text field
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceFourIndex:
			[mSourceFourReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceReverbLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
	}
		
	[[view scene] setSourceReverb:tag :level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceOcclusionSlider:(id)inSender
{
	float	level = [inSender floatValue];
	int		tag = [inSender tag];

	// update the corresponding text field
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceFourIndex:
			[mSourceFourOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceOcclusionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
	}
		
	[[view scene] setSourceOcclusion:tag :level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	setSourceObstructionSlider:(id)inSender
{
	float	level = [inSender floatValue];
	int		tag = [inSender tag];

	// update the corresponding text field
	switch (tag)
	{
		case kSourceOneIndex:
			[mSourceOneObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceTwoIndex:
			[mSourceTwoObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceThreeIndex:
			[mSourceThreeObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kSourceFourIndex:
			[mSourceFourObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
		case kCaptureSourceIndex:
			[mCaptureSourceObstructionLevel setStringValue: [NSString stringWithFormat: @"%.2f", level]];
			break;
	}
		
	[[view scene] setSourceObstruction:tag :level];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EDIT TEXT
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define	kReferenceDistanceText	4200
#define	kMaxDistanceText		4300
#define	kRolloffFactorText		4400
#define	kSourcePosXText			5000
#define	kSourcePosYText			5100
#define	kSourcePosZText			5200
#define	kListenerPosXText		3000
#define	kListenerPosZText		3002

- (void) controlTextDidEndEditing:(NSNotification *) aNotification {
	NSTextField * obj = [aNotification object];

	// which text field
	switch ([obj tag])
	{
		case kListenerElevation:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	elevation = [obj floatValue];
			[mListenerElevationSlider setFloatValue: elevation];			// move the corresponding slider
			[[view scene] setListenerElevation:elevation];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;

		case kListenerGainEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	gain = [obj floatValue];
			[mListenerGainSlider setFloatValue: gain];				// move the corresponding slider
			[[view scene] setListenerGain:gain];					// Set OpenAL
		}
			break;

		case kDopplerFactorEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	doppler = [obj floatValue];
			[mDopplerFactorSlider setFloatValue: doppler];			// move the corresponding slider
			[[view scene] setDopplerFactor:doppler];				// Set OpenAL
		}
			break;

		case kSpeedOfSoundEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	sos = [obj floatValue];
			[mSpeedOfSoundSlider setFloatValue: sos];				// move the corresponding slider
			[[view scene] setSpeedOfSound:sos];						// Set OpenAL
		}
			break;

		case kVelocitySpeedEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	velocity = [obj floatValue];
			[mListenerVelocityScalerSlider setFloatValue: velocity];		// move the corresponding slider
			[[view scene] setListenerVelocity:velocity : NULL : NULL];		// Set OpenAL
		}
			break;

		case kReverbLevelEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	level = [obj floatValue];
			[mListenerReverbLevelSlider setFloatValue: level];		// move the corresponding slider
			[[view scene] setGlobalReverb:level];					// Set OpenAL
		}
			break;

		case kReverbEQFrequencyEditTextItem:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	frequency = [obj floatValue];
			[mReverbEQFrequencySlider setFloatValue: frequency];	// move the corresponding slider
			[[view scene] setReverbEQFrequency:frequency];			// Set OpenAL
		}
			break;

		case kReverbEQBandwidth:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	bandwidth = [obj floatValue];
			[mReverbEQBandwidthSlider setFloatValue: bandwidth];	// move the corresponding slider
			[[view scene] setReverbEQBandwidth:bandwidth];			// Set OpenAL
		}
			break;

		case kReverbEQGain:
		{	// get the numeric value of  the field string
			// set the slider to this value
			float	gain = [obj floatValue];
			[mReverbEQGainSlider setFloatValue: gain];				// move the corresponding slider
			[[view scene] setReverbEQGain:gain];					// Set OpenAL
		}
			break;

		case kListenerPosXText:
		{
			float	pos = [obj floatValue];
			[[view scene] setListenerPositionX : pos];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;

		case kListenerPosZText:
		{
			float	pos = [obj floatValue];
			[[view scene] setListenerPositionZ : pos];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;


		case kSourcePosXText:
		case kSourcePosXText+1:
		case kSourcePosXText+2:
		case kSourcePosXText+3:
		case kSourcePosXText+4:
		{
			float	pos = [obj floatValue];
			[[view scene] setSourcePositionX:[obj tag] - kSourcePosXText : pos];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;

		case kSourcePosYText:
		case kSourcePosYText+1:
		case kSourcePosYText+2:
		case kSourcePosYText+3:
		case kSourcePosYText+4:
		{
			float	pos = [obj floatValue];
			[[view scene] setSourcePositionY:[obj tag] - kSourcePosYText : pos];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;

		case kSourcePosZText:
		case kSourcePosZText+1:
		case kSourcePosZText+2:
		case kSourcePosZText+3:
		case kSourcePosZText+4:
		{
			float	pos = [obj floatValue];
			[[view scene] setSourcePositionZ:[obj tag] - kSourcePosZText : pos];					// Set OpenAL
			[view setNeedsDisplay:YES];
		}
			break;
			
		case kReferenceDistanceText:
		case kReferenceDistanceText+1:
		case kReferenceDistanceText+2:
		case kReferenceDistanceText+3:
		case kReferenceDistanceText+4:
		{
			float	ro = [obj floatValue];
			[[view scene] setSourceReferenceDistance:[obj tag] - kReferenceDistanceText : ro];					// Set OpenAL
		}
			break;

		case kMaxDistanceText:
		case kMaxDistanceText+1:
		case kMaxDistanceText+2:
		case kMaxDistanceText+3:
		case kMaxDistanceText+4:
		{
			float	ro = [obj floatValue];
			[[view scene] setSourceMaxDistance:[obj tag] - kMaxDistanceText : ro];					// Set OpenAL
		}
			break;

		case kRolloffFactorText:
		case kRolloffFactorText+1:
		case kRolloffFactorText+2:
		case kRolloffFactorText+3:
		case kRolloffFactorText+4:
		{
			float	ro = [obj floatValue];
			[[view scene] setSourceRolloffFactor:[obj tag] - kRolloffFactorText : ro];					// Set OpenAL
		}
			break;
	}
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)	captureSamplesButton:(id)inSender
{
	int		samplesCaptured = 0;
	[[view scene] captureSamples:&samplesCaptured];
	

	float		theValue = samplesCaptured;
	[mSamplesCaptured setStringValue: [NSString stringWithFormat: @"%.1f", theValue]];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

@end
