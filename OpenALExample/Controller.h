/*
     File: Controller.h
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
#import <Cocoa/Cocoa.h>
#import "MyOpenGLView.h"

enum	{
			kSourceOneIndex	= 0,
			kSourceTwoIndex,
			kSourceThreeIndex,
			kSourceFourIndex,
			kCaptureSourceIndex,
			kListenerIndex
};


enum	{
			kListenerGainEditTextItem	= 1000,
			kDopplerFactorEditTextItem,
			kSpeedOfSoundEditTextItem,
			kVelocitySpeedEditTextItem,
			kReverbLevelEditTextItem,
			kReverbEQFrequencyEditTextItem,
			kReverbEQBandwidth,
			kReverbEQGain,
			kListenerElevation,			// ListenerPosY
			kListenerPosX				= 3000,
			kListenerPosZ				= 3002
};


@interface Controller : NSObject {
	IBOutlet NSWindow*				mainWindow;
    IBOutlet MyOpenGLView*			view;

	// Slider Outlets

	IBOutlet NSSlider*				mListenerGainSlider;
	IBOutlet NSSlider*				mDopplerFactorSlider;
	IBOutlet NSSlider*				mSpeedOfSoundSlider;
	IBOutlet NSSlider*				mListenerVelocityScalerSlider;
	IBOutlet NSSlider*				mListenerReverbLevelSlider;
	IBOutlet NSSlider*				mReverbEQFrequencySlider;
	IBOutlet NSSlider*				mReverbEQGainSlider;
	IBOutlet NSSlider*				mReverbEQBandwidthSlider;
	IBOutlet NSSlider*				mListenerElevationSlider;	// 1008
	IBOutlet NSButton*				mReverbOnCheckbox;
	IBOutlet NSPopUpButton*			mReverbQualityPU;
	IBOutlet NSPopUpButton*			mReverbRoomtypePU;

	IBOutlet NSSlider*				mCaptureSourceGainSlider;
	IBOutlet NSSlider*				mCaptureSourcePitchSlider;
	IBOutlet NSButton*				mCaptureSourceOnCheckbox;
	IBOutlet NSButton*				mCaptureSourceCaptureSamplesButton;
	
	IBOutlet NSSlider*				mCaptureSourceReverbSlider;
	IBOutlet NSSlider*				mCaptureSourceOcclusionSlider;
	IBOutlet NSSlider*				mCaptureSourceObstructionSlider;
	IBOutlet NSButton*				mCaptureSourceConesCheckbox;
	IBOutlet NSSlider*				mCaptureSourceAngleSlider;
	IBOutlet NSSlider*				mCaptureSourceVelocitySlider;
	IBOutlet NSSlider*				mCaptureSourceInnerConeAngleSlider;
	IBOutlet NSSlider*				mCaptureSourceOuterConeAngleSlider;
	IBOutlet NSSlider*				mCaptureSourceOuterConeGainSlider;

	// Text Field Outlets
	
	IBOutlet NSTextField*			mListenerGain;
	IBOutlet NSTextField*			mListenerElevation;
	IBOutlet NSTextField*			mDopplerFactor;
	IBOutlet NSTextField*			mSpeedOfSound;
	IBOutlet NSTextField*			mListenerVelocityScaler;
	IBOutlet NSTextField*			mListenerReverbLevel;
	IBOutlet NSTextField*			mReverbEQFrequency;
	IBOutlet NSTextField*			mReverbEQGain;
	IBOutlet NSTextField*			mReverbEQBandwidth;

	IBOutlet NSTextField*			mListenerXPos;
	IBOutlet NSTextField*			mListenerZPos;
	IBOutlet NSTextField*			mListenerXVelocity;
	IBOutlet NSTextField*			mListenerZVelocity;
	
	IBOutlet NSTextField*			mSourceOnePitch;
	IBOutlet NSTextField*			mSourceTwoPitch;
	IBOutlet NSTextField*			mSourceThreePitch;
	IBOutlet NSTextField*			mSourceFourPitch;
	IBOutlet NSTextField*			mCaptureSourcePitch;
	
	IBOutlet NSTextField*			mSourceOneGain;
	IBOutlet NSTextField*			mSourceTwoGain;
	IBOutlet NSTextField*			mSourceThreeGain;
	IBOutlet NSTextField*			mSourceFourGain;
	IBOutlet NSTextField*			mCaptureSourceGain;

	IBOutlet NSTextField*			mSourceOneReferenceDistance;
	IBOutlet NSTextField*			mSourceTwoReferenceDistance;
	IBOutlet NSTextField*			mSourceThreeReferenceDistance;
	IBOutlet NSTextField*			mSourceFourReferenceDistance;
	IBOutlet NSTextField*			mCaptureSourceReferenceDistance;

	IBOutlet NSTextField*			mSourceOneMaxDistance;
	IBOutlet NSTextField*			mSourceTwoMaxDistance;
	IBOutlet NSTextField*			mSourceThreeMaxDistance;
	IBOutlet NSTextField*			mSourceFourMaxDistance;
	IBOutlet NSTextField*			mCaptureSourceMaxDistance;

	IBOutlet NSTextField*			mSourceOneRolloffFactor;
	IBOutlet NSTextField*			mSourceTwoRolloffFactor;
	IBOutlet NSTextField*			mSourceThreeRolloffFactor;
	IBOutlet NSTextField*			mSourceFourRolloffFactor;
	IBOutlet NSTextField*			mCaptureSourceRolloffFactor;
	
	IBOutlet NSTextField*			mSourceOneInnerConeAngle;
	IBOutlet NSTextField*			mSourceTwoInnerConeAngle;
	IBOutlet NSTextField*			mSourceThreeInnerConeAngle;
	IBOutlet NSTextField*			mSourceFourInnerConeAngle;
	IBOutlet NSTextField*			mCaptureSourceInnerConeAngle;

	IBOutlet NSTextField*			mSourceOneOuterConeAngle;
	IBOutlet NSTextField*			mSourceTwoOuterConeAngle;
	IBOutlet NSTextField*			mSourceThreeOuterConeAngle;
	IBOutlet NSTextField*			mSourceFourOuterConeAngle;
	IBOutlet NSTextField*			mCaptureSourceOuterConeAngle;

	IBOutlet NSTextField*			mSourceOneOuterConeGain;
	IBOutlet NSTextField*			mSourceTwoOuterConeGain;
	IBOutlet NSTextField*			mSourceThreeOuterConeGain;
	IBOutlet NSTextField*			mSourceFourOuterConeGain;
	IBOutlet NSTextField*			mCaptureSourceOuterConeGain;

	IBOutlet NSTextField*			mSourceOneReverbLevel;
	IBOutlet NSTextField*			mSourceTwoReverbLevel;
	IBOutlet NSTextField*			mSourceThreeReverbLevel;
	IBOutlet NSTextField*			mSourceFourReverbLevel;
	IBOutlet NSTextField*			mCaptureSourceReverbLevel;
	
	IBOutlet NSTextField*			mSourceOneOcclusionLevel;
	IBOutlet NSTextField*			mSourceTwoOcclusionLevel;
	IBOutlet NSTextField*			mSourceThreeOcclusionLevel;
	IBOutlet NSTextField*			mSourceFourOcclusionLevel;
	IBOutlet NSTextField*			mCaptureSourceOcclusionLevel;
	
	IBOutlet NSTextField*			mSourceOneObstructionLevel;
	IBOutlet NSTextField*			mSourceTwoObstructionLevel;
	IBOutlet NSTextField*			mSourceThreeObstructionLevel;
	IBOutlet NSTextField*			mSourceFourObstructionLevel;
	IBOutlet NSTextField*			mCaptureSourceObstructionLevel;

	IBOutlet NSTextField*			mSourceOneVelocity;
	IBOutlet NSTextField*			mSourceTwoVelocity;
	IBOutlet NSTextField*			mSourceThreeVelocity;
	IBOutlet NSTextField*			mSourceFourVelocity;
	IBOutlet NSTextField*			mCaptureSourceVelocity;

	IBOutlet NSTextField*			mSourceOneXVelocity;
	IBOutlet NSTextField*			mSourceTwoXVelocity;
	IBOutlet NSTextField*			mSourceThreeXVelocity;
	IBOutlet NSTextField*			mSourceFourXVelocity;
	IBOutlet NSTextField*			mCaptureSourceXVelocity;
	
	IBOutlet NSTextField*			mSourceOneZVelocity;
	IBOutlet NSTextField*			mSourceTwoZVelocity;
	IBOutlet NSTextField*			mSourceThreeZVelocity;
	IBOutlet NSTextField*			mSourceFourZVelocity;
	IBOutlet NSTextField*			mCaptureSourceZVelocity;

	IBOutlet NSTextField*			mSourceOneXPosition;
	IBOutlet NSTextField*			mSourceTwoXPosition;
	IBOutlet NSTextField*			mSourceThreeXPosition;
	IBOutlet NSTextField*			mSourceFourXPosition;
	IBOutlet NSTextField*			mCaptureSourceXPosition;
	
	IBOutlet NSTextField*			mCaptureSourceYPosition;

	IBOutlet NSTextField*			mSourceOneZPosition;
	IBOutlet NSTextField*			mSourceTwoZPosition;
	IBOutlet NSTextField*			mSourceThreeZPosition;
	IBOutlet NSTextField*			mSourceFourZPosition;
	IBOutlet NSTextField*			mCaptureSourceZPosition;
	
	IBOutlet NSTextField*			mALExtensionList;
	IBOutlet NSTextField*			mALCExtensionList;
	IBOutlet NSTextField*			mALCDefaultDeviceName;
	IBOutlet NSTextField*			mALCCaptureDefaultDeviceName;
	IBOutlet NSTextField*			mALVersion;
	
	IBOutlet NSTextField*			mSamplesCaptured;
}

// Context/Listener
- (IBAction)	setListenerGainSlider:(id)inSender;
- (IBAction)	setListenerDirectionSlider:(id)inSender;
- (IBAction)	setListenerVelocitySlider:(id)inSender;
- (IBAction)	setListenerElevationSlider:(id)inSender;
- (IBAction)	setDopplerFactorSlider:(id)inSender;
- (IBAction)	setSpeedOfSoundSlider:(id)inSender;

- (IBAction)	setReverbLevelSlider:(id)inSender;
- (IBAction)	setReverbEQGainSlider:(id)inSender;
- (IBAction)	setReverbEQBandwidthSlider:(id)inSender;
- (IBAction)	setReverbEQFrequencySlider:(id)inSender;

- (IBAction)	setReverbQualityPU:(id)inSender;
- (IBAction)	setDistanceModelPU:(id)inSender;
- (IBAction)	setReverbRoomTypePU:(id)inSender;

- (IBAction)	setRenderChannelsCheckbox:(id)inSender;
- (IBAction)	setRenderQualityCheckbox:(id)inSender;
- (IBAction)	setReverbOnCheckbox:(id)inSender;

// Source

- (IBAction)	setSourcePitchSlider:(id)inSender;
- (IBAction)	setSourceGainSlider:(id)inSender;
- (IBAction)	setSourceAngleSlider:(id)inSender;
- (IBAction)	setSourceVelocitySlider:(id)inSender;
- (IBAction)	setSourceOuterConeGainSlider:(id)inSender;
- (IBAction)	setSourceOuterConeAngleSlider:(id)inSender;
- (IBAction)	setSourceInnerConeAngleSlider:(id)inSender;

- (IBAction)	setSourceReverbSlider:(id)inSender;
- (IBAction)	setSourceOcclusionSlider:(id)inSender;
- (IBAction)	setSourceObstructionSlider:(id)inSender;

- (IBAction)	setSourceUseConesCheckBox:(id)inSender;
- (IBAction)	setSourcePlayStatesCheckBox:(id)inSender;

- (IBAction)	captureSamplesButton:(id)inSender;


- (void) controlTextDidEndEditing:(NSNotification *) aNotification;
- (void) myObserver:(NSNotification *)inNotification;
- (void) awakeFromNib;

@end
