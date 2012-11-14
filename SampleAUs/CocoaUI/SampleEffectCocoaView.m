/*
     File: SampleEffectCocoaView.m
 Abstract: SampleEffectCocoaView.h
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
/*
    SampleEffectCocoaView.m
    
    View class manufactured by SampleEffectCocoaViewFactory factory class.
    This view is instantiated via nib.
*/

#import "SampleEffectCocoaView.h"

enum {
	kParam_One,
	kParam_Two,
    kParam_Three_Indexed,
	kNumberOfParameters
};

AudioUnitParameter parameter[] = {	{ 0, kParam_One, kAudioUnitScope_Global, 0 },
                                    { 0, kParam_Two, kAudioUnitScope_Global, 0 },
                                    { 0, kParam_Three_Indexed, kAudioUnitScope_Global, 0 }	};

@implementation SampleEffectCocoaView

#pragma mark -
#pragma mark Listener Callback Handling
- (void)_parameterListener:(void *)inObject parameter:(const AudioUnitParameter *)inParameter value:(AudioUnitParameterValue)inValue {
    // inObject ignored in this case.
    
	switch (inParameter->mParameterID) {
		case kParam_One:
            [uiParam1Slider setFloatValue:inValue];
            [uiParam1TextField setStringValue:[[NSNumber numberWithFloat:inValue] stringValue]];
            break;
		case kParam_Two:
            [uiParam2Slider setFloatValue:inValue];
            [uiParam2TextField setStringValue:[[NSNumber numberWithFloat:inValue] stringValue]];
			break;
		case kParam_Three_Indexed:
            [uiParam3Matrix setState:NSOnState atRow:(inValue - 4) column:0];
			break;
	}
}

void ParameterListenerDispatcher (void *inRefCon, void *inObject, const AudioUnitParameter *inParameter, AudioUnitParameterValue inValue) {
	SampleEffectCocoaView *SELF = (SampleEffectCocoaView *)inRefCon;
    
    [SELF _parameterListener:inObject parameter:inParameter value:inValue];
}

#pragma mark -
#pragma mark Private Functions
- (void)_addListeners {
	verify_noerr ( AUListenerCreate (	ParameterListenerDispatcher, self, CFRunLoopGetCurrent(),
										kCFRunLoopDefaultMode, 0.100 /* 100 ms */, &mParameterListener	));
	
    int i;
    for (i = 0; i < kNumberOfParameters; ++i) {
        parameter[i].mAudioUnit = mAU;
        verify_noerr ( AUListenerAddParameter (mParameterListener, NULL, &parameter[i]));
    }
}

- (void)_removeListeners {
    int i;
    for (i = 0; i < kNumberOfParameters; ++i) {
        verify_noerr ( AUListenerRemoveParameter(mParameterListener, NULL, &parameter[i]) );
    }
    
	verify_noerr (	AUListenerDispose(mParameterListener) );
}

- (void)_synchronizeUIWithParameterValues {
	AudioUnitParameterValue value;
    int i;
    
    for (i = 0; i < kNumberOfParameters; ++i) {
        // only has global parameters
        verify_noerr (AudioUnitGetParameter(mAU, parameter[i].mParameterID, kAudioUnitScope_Global, 0, &value));
        verify_noerr (AUParameterSet (mParameterListener, self, &parameter[i], value, 0));
        verify_noerr (AUParameterListenerNotify (mParameterListener, self, &parameter[i]));
    }
}

#pragma mark ____ (INIT /) DEALLOC ____
- (void)dealloc {
    [self _removeListeners];
	
	[super dealloc];
}

#pragma mark ____ PUBLIC FUNCTIONS ____
- (void)setAU:(AudioUnit)inAU {
	// remove previous listeners
	if (mAU)
		[self _removeListeners];
	
	mAU = inAU;
    
	if (mAU) {
		// add new listeners
		[self _addListeners];
		
		// initial setup
		[self _synchronizeUIWithParameterValues];
	}
}

#pragma mark ____ INTERFACE ACTIONS ____
- (IBAction)iaParam1Changed:(id)sender {
    float floatValue = [sender floatValue];
	
	verify_noerr (AUParameterSet(mParameterListener, sender, &parameter[0], floatValue, 0));
	
    if (sender == uiParam1Slider) {
        [uiParam1TextField setFloatValue:floatValue];
    } else {
        [uiParam1Slider setFloatValue:floatValue];
    }
}

- (IBAction)iaParam2Changed:(id)sender {
    float floatValue = [sender floatValue];
	
	verify_noerr (AUParameterSet(mParameterListener, sender, &parameter[1], floatValue, 0));
	
    if (sender == uiParam2Slider) {
        [uiParam2TextField setFloatValue:floatValue];
    } else {
        [uiParam2Slider setFloatValue:floatValue];
    }
}

- (IBAction)iaParam3Changed:(id)sender {
	verify_noerr (AUParameterSet(mParameterListener, sender, &parameter[2], [uiParam3Matrix selectedRow] + 4, 0));
}

@end
