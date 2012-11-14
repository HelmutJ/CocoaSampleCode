/*
 
     File: MyGreatAUEffectWithCocoaUI_CocoaView.m
 Abstract: Audio Unit Cocoa View imlementation.
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

#import "MyGreatAUEffectWithCocoaUI_CocoaView.h"

enum {
	kParam_One =0,
	kNumberOfParameters=1
};

#pragma mark ____ LISTENER CALLBACK DISPATCHER ____
void ParameterListenerDispatcher (void *inRefCon, void *inObject, const AudioUnitParameter *inParameter, Float32 inValue) {
	MyGreatAUEffectWithCocoaUI_CocoaView *SELF = (MyGreatAUEffectWithCocoaUI_CocoaView *)inRefCon;
    
    [SELF parameterListener:inObject parameter:inParameter value:inValue];
}

NSString *MyGreatAUEffectWithCocoaUI_GestureSliderMouseDownNotification = @"CAGestureSliderMouseDownNotification";
NSString *MyGreatAUEffectWithCocoaUI_GestureSliderMouseUpNotification = @"CAGestureSliderMouseUpNotification";

@implementation MyGreatAUEffectWithCocoaUI_GestureSlider

/*	We create our own custom subclass of NSSlider so we can do begin/end gesture notification
	We cannot override mouseUp: because it will never be called. Instead we do a clever trick in mouseDown to send mouseUp notifications */
- (void)mouseDown:(NSEvent *)inEvent {
	[[NSNotificationCenter defaultCenter] postNotificationName: MyGreatAUEffectWithCocoaUI_GestureSliderMouseDownNotification object: self];
	
	[super mouseDown: inEvent];	// this call does not return until mouse tracking is complete
								// once tracking is done, we know the mouse has been released, so we can send our mouseup notification

	[[NSNotificationCenter defaultCenter] postNotificationName: MyGreatAUEffectWithCocoaUI_GestureSliderMouseUpNotification object: self];
}
	
@end

@implementation MyGreatAUEffectWithCocoaUI_CocoaView
#pragma mark ____ (INIT /) DEALLOC ____
- (void)dealloc {
    [self removeListeners];
    [super dealloc];
}

#pragma mark ____ PUBLIC FUNCTIONS ____
- (void)setAU:(AudioUnit)inAU {
	// remove previous listeners
	if (mAU) [self removeListeners];
	mAU = inAU;
    
   	mParameter[0].mAudioUnit = inAU;
	mParameter[0].mParameterID = kParam_One;
	mParameter[0].mScope = kAudioUnitScope_Global;
	mParameter[0].mElement = 0;	

	// add new listeners
	[self addListeners];
	
	// initial setup
	[self synchronizeUIWithParameterValues];
}

#pragma mark ____ INTERFACE ACTIONS ____
- (IBAction)iaParam1Changed:(id)sender {
    float floatValue = [sender floatValue];
    
    OSStatus result = AUParameterSet(mParameterListener, sender, &mParameter[0], (Float32)floatValue, 0);
    NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView iaParam1Changed:] AUParameterSet()");
    
    if (sender == uiParam1Slider) {
        [uiParam1TextField setFloatValue:floatValue];
    } else {
        [uiParam1Slider setFloatValue:floatValue];
    }
}

#pragma mark ____ NOTIFICATIONS ____

// This routine is called when the user has clicked on the slider. We need to send a begin parameter change gesture to alert hosts that the parameter may be changing value
-(void) handleMouseDown: (NSNotification *) aNotification {
	if ([aNotification object] == uiParam1Slider) {
		AudioUnitEvent event;
		event.mArgument.mParameter = mParameter[0];
		event.mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
		
		AUEventListenerNotify (NULL, self, &event);		// NOTE, if you have an AUEventListenerRef because you are listening to event notification, 
														// pass that as the first argument to AUEventListenerNotify instead of NULL 
	}
}

-(void) handleMouseUp: (NSNotification *) aNotification {
	if ([aNotification object] == uiParam1Slider) {
		AudioUnitEvent event;
		event.mArgument.mParameter = mParameter[0];
		event.mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	
		AUEventListenerNotify (NULL, self, &event);		// NOTE, if you have an AUEventListenerRef because you are listening to event notification, 
														// pass that as the first argument to AUEventListenerNotify instead of NULL 
	}
}


#pragma mark ____ PRIVATE FUNCTIONS ____
- (void)addListeners {
    OSStatus result = AUListenerCreate(	ParameterListenerDispatcher, self, 
                                    CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.100, // 100 ms
                                    &mParameterListener	);
	NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView _addListeners] AUListenerCreate()");
	
    int i;
    for (i = 0; i < kNumberOfParameters; ++i) {
        mParameter[i].mAudioUnit = mAU;
        result = AUListenerAddParameter (mParameterListener, NULL, &mParameter[i]);
        NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView _addListeners] AUListenerAddParameter()");
    }
    
   	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleMouseDown:) name:MyGreatAUEffectWithCocoaUI_GestureSliderMouseDownNotification object: uiParam1Slider];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleMouseUp:) name:MyGreatAUEffectWithCocoaUI_GestureSliderMouseUpNotification object: uiParam1Slider];
}

- (void)removeListeners {
    OSStatus result;
    int i;
    for (i = 0; i < kNumberOfParameters; ++i) {
        result = AUListenerRemoveParameter(mParameterListener, NULL, &mParameter[i]);
        NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView _removeListeners] AUListenerRemoveParameter()");
    }
    
    result = AUListenerDispose(mParameterListener);
	NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView _removeListeners] AUListenerDispose()");
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name:MyGreatAUEffectWithCocoaUI_GestureSliderMouseDownNotification object: uiParam1Slider];
	[[NSNotificationCenter defaultCenter] removeObserver: self name:MyGreatAUEffectWithCocoaUI_GestureSliderMouseUpNotification object: uiParam1Slider];
}

- (void)synchronizeUIWithParameterValues {
    OSStatus result;
	Float32 value;
    int i;
    
    for (i = 0; i < kNumberOfParameters; ++i) {
        // only has global parameters
        result = AudioUnitGetParameter(mAU, mParameter[i].mParameterID, kAudioUnitScope_Global, 0, &value);
        NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView synchronizeUIWithParameterValues] (x.1)");
        
        result = AUParameterSet (mParameterListener, self, &mParameter[i], value, 0);
        NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView synchronizeUIWithParameterValues] (x.2)");
        
        result = AUParameterListenerNotify (mParameterListener, self, &mParameter[i]);
        NSAssert(result == noErr, @"[MyGreatAUEffectWithCocoaUI_CocoaView synchronizeUIWithParameterValues] (x.3)");
    }
}

#pragma mark ____ LISTENER CALLBACK DISPATCHEE ____
- (void)parameterListener:(void *)inObject parameter:(const AudioUnitParameter *)inParameter value:(Float32)inValue {
    //inObject ignored in this case.
    
	switch (inParameter->mParameterID) {
		case kParam_One:
                    [uiParam1Slider setFloatValue:inValue];
                    [uiParam1TextField setStringValue:[[NSNumber numberWithFloat:inValue] stringValue]];
                    break;
	}
}


@end
