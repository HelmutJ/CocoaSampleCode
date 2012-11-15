/*
     File: AppleDemoFilter_UIView.m 
 Abstract:  AppleDemoFilter_UIView.m  
  Version: 1.01 
  
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
#import "AppleDemoFilter_UIView.h"

enum
{
	kFilterParam_CutoffFrequency = 0,
	kFilterParam_Resonance = 1
};

extern NSString *kGraphViewDataChangedNotification;	// notification broadcast by the view when the user has changed the resonance 
													// or cutoff values via directly mousing in the graph view

extern NSString *kGraphViewBeginGestureNotification;// notification broadcast by the view when the user has started a gesture
extern NSString *kGraphViewEndGestureNotification;	// notification broadcast by the view when the user has finished a gesture

#pragma mark ____ LISTENER CALLBACK DISPATCHER ____

// This listener responds to parameter changes, gestures, and property notifications
void EventListenerDispatcher (void *inRefCon, void *inObject, const AudioUnitEvent *inEvent, UInt64 inHostTime, Float32 inValue)
{
	AppleDemoFilter_UIView *SELF = (AppleDemoFilter_UIView *)inRefCon;
	[SELF priv_eventListener:inObject event: inEvent value: inValue];
}

@implementation AppleDemoFilter_UIView

-(void) awakeFromNib {
	NSString *path = [[NSBundle bundleForClass: [AppleDemoFilter_UIView class]] pathForImageResource: @"SectionPatternLight"];
	NSImage *pattern = [[NSImage alloc] initByReferencingFile: path];
	mBackgroundColor = [[NSColor colorWithPatternImage: [pattern autorelease]] retain];
}

#pragma mark ____ (INIT /) DEALLOC ____
- (void)dealloc {
    [self priv_removeListeners];
	[mBackgroundColor release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
		
	free (mData);
	
    [super dealloc];
}

#pragma mark ____ PUBLIC FUNCTIONS ____
- (void)setAU:(AudioUnit)inAU {
	// remove previous listeners
	if (mAU) 
		[self priv_removeListeners];
	
	if (!mData)											// only allocate the data once
		mData = malloc(kNumberOfResponseFrequencies * sizeof(FrequencyResponse));
	
	mData = [graphView prepareDataForDrawing: mData];	// fill out the initial frequency values for the data displayed by the graph

	// register for resize notification and data changes for the graph view
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleGraphDataChanged:) name: kGraphViewDataChangedNotification object: graphView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleGraphSizeChanged:) name: NSViewFrameDidChangeNotification  object: graphView];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(beginGesture:) name: kGraphViewBeginGestureNotification object: graphView];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endGesture:) name: kGraphViewEndGestureNotification object: graphView];

	mAU = inAU;
    
	// add new listeners
	[self priv_addListeners];
	
	// initial setup
	[self priv_synchronizeUIWithParameterValues];
}

- (void)drawRect:(NSRect)rect
{
	[mBackgroundColor set];
	NSRectFill(rect);		// this call is much faster than using NSBezierPath, but it doesn't handle non-opaque colors
	
	[super drawRect: rect];	// we call super to draw all other controls after we have filled the background
}

#pragma mark ____ INTERFACE ACTIONS ____

- (IBAction) cutoffFrequencyChanged:(id)sender {
	float floatValue = [sender floatValue];
	AudioUnitParameter cutoffParameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	
	NSAssert(	AUParameterSet(mAUEventListener, sender, &cutoffParameter, (Float32)floatValue, 0) == noErr,
                @"[AppleDemoFilter_UIView cutoffFrequencyChanged:] AUParameterSet()");
}

- (IBAction) resonanceChanged:(id)sender {
	float floatValue = [sender floatValue];
	AudioUnitParameter resonanceParameter = {mAU, kFilterParam_Resonance, kAudioUnitScope_Global, 0 };

	NSAssert(	AUParameterSet(mAUEventListener, sender, &resonanceParameter, (Float32)floatValue, 0) == noErr,
                @"[AppleDemoFilter_UIView resonanceChanged:] AUParameterSet()");
}

- (void) handleGraphDataChanged:(NSNotification *) aNotification {
	float resonance = [graphView getRes];
	float cutoff	= [graphView getFreq];
	
	AudioUnitParameter cutoffParameter		= {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	AudioUnitParameter resonanceParameter	= {mAU, kFilterParam_Resonance, kAudioUnitScope_Global, 0 };
	
	NSAssert(	AUParameterSet(mAUEventListener, cutoffFrequencyField, &cutoffParameter, (Float32)cutoff, 0) == noErr,
                @"[AppleDemoFilter_UIView cutoffFrequencyChanged:] AUParameterSet()");

	NSAssert(	AUParameterSet(mAUEventListener, resonanceField, &resonanceParameter, (Float32)resonance, 0) == noErr,
                @"[AppleDemoFilter_UIView resonanceChanged:] AUParameterSet()");
}

- (void) handleGraphSizeChanged:(NSNotification *) aNotification {
	mData = [graphView prepareDataForDrawing: mData];	// the size of the graph has changed so we need the graph to reconfigure the data frequencies that it needs to draw
	
	// get the curve data from the audio unit
	UInt32 dataSize = kNumberOfResponseFrequencies * sizeof(FrequencyResponse);
	ComponentResult result = AudioUnitGetProperty(	mAU,
													kAudioUnitCustomProperty_FilterFrequencyResponse,
													kAudioUnitScope_Global,
													0,
													mData,
													&dataSize);
	if (result == noErr)
		[graphView plotData: mData];	// ask the graph view to plot the new data
	else if (result == kAudioUnitErr_Uninitialized)
		[graphView disableGraphCurve];
}

- (void) beginGesture:(NSNotification *) aNotification {
	AudioUnitEvent event;
	AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	event.mArgument.mParameter = parameter;
	event.mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
	
	AUEventListenerNotify (mAUEventListener, self, &event);
		
	event.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
	AUEventListenerNotify (mAUEventListener, self, &event);
}

- (void) endGesture:(NSNotification *) aNotification {
	AudioUnitEvent event;
	AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	event.mArgument.mParameter = parameter;
	event.mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	
	AUEventListenerNotify (mAUEventListener, self, &event);
	
	event.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
	AUEventListenerNotify (mAUEventListener, self, &event);	
}

void addParamListener (AUEventListenerRef listener, void* refCon, AudioUnitEvent *inEvent)
{
	inEvent->mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));
	
	inEvent->mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));
	
	inEvent->mEventType = kAudioUnitEvent_ParameterValueChange;
	verify_noerr ( AUEventListenerAddEventType(	listener, refCon, inEvent));	
}

#pragma mark ____ PRIVATE FUNCTIONS ____
- (void)priv_addListeners 
{
	if (mAU) {
		verify_noerr( AUEventListenerCreate(EventListenerDispatcher, self,
											CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0.05, 0.05, 
											&mAUEventListener));
		
		AudioUnitEvent auEvent;
		AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
		auEvent.mArgument.mParameter = parameter;		
			
		addParamListener (mAUEventListener, self, &auEvent);
		
		auEvent.mArgument.mParameter.mParameterID = kFilterParam_Resonance;
		addParamListener (mAUEventListener, self, &auEvent);
		
		/* Add a listener for the changes in our custom property */
		/* The Audio unit will send a property change when the unit is intialized */		
		auEvent.mEventType = kAudioUnitEvent_PropertyChange;
		auEvent.mArgument.mProperty.mAudioUnit = mAU;
		auEvent.mArgument.mProperty.mPropertyID = kAudioUnitCustomProperty_FilterFrequencyResponse;
		auEvent.mArgument.mProperty.mScope = kAudioUnitScope_Global;
		auEvent.mArgument.mProperty.mElement = 0;		
		verify_noerr (AUEventListenerAddEventType (mAUEventListener, self, &auEvent));
	}
}

- (void)priv_removeListeners 
{
	if (mAUEventListener) verify_noerr (AUListenerDispose(mAUEventListener));
	mAUEventListener = NULL;
	mAU = NULL;
}


- (void) updateCurve {
	UInt32 dataSize = kNumberOfResponseFrequencies * sizeof(FrequencyResponse);
	ComponentResult result = AudioUnitGetProperty(	mAU,
													kAudioUnitCustomProperty_FilterFrequencyResponse,
													kAudioUnitScope_Global,
													0,
													mData,
													&dataSize);
	if (result == noErr)
		[graphView plotData: mData];	// plot the new curve data and redraw the graph
	else if (result == kAudioUnitErr_Uninitialized)
		[graphView disableGraphCurve];
}

- (void)priv_synchronizeUIWithParameterValues {
	Float32 freqValue, resValue;
	AudioUnitParameter parameter = {mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0 };
	
	NSAssert (	AudioUnitGetParameter(mAU, kFilterParam_CutoffFrequency, kAudioUnitScope_Global, 0, &freqValue) == noErr,
				@"[AppleDemoFilter_UIView priv_synchronizeUIWithParameterValues] (x.1)");

	parameter.mParameterID = kFilterParam_Resonance;
	NSAssert (	AudioUnitGetParameter(mAU, kFilterParam_Resonance, kAudioUnitScope_Global, 0, &resValue) == noErr,
				@"[AppleDemoFilter_UIView priv_synchronizeUIWithParameterValues] (x.1)");
	
	[cutoffFrequencyField setFloatValue: freqValue];	// update the frequency text field
	[graphView setFreq: freqValue];					// update the graph's frequency visual state
	[resonanceField setFloatValue: resValue];		// update the resonance text field
	[graphView setRes: resValue];					// update the graph's gain visual state
	[self updateCurve];
}

#pragma mark ____ LISTENER CALLBACK DISPATCHEE ____
// Handle kAudioUnitProperty_PresentPreset event
- (void)priv_eventListener:(void *) inObject event:(const AudioUnitEvent *)inEvent value:(Float32)inValue {
	switch (inEvent->mEventType) {
		case kAudioUnitEvent_ParameterValueChange:					// Parameter Changes
			switch (inEvent->mArgument.mParameter.mParameterID) {
				case kFilterParam_CutoffFrequency:					// handle cutoff frequency parameter
					[cutoffFrequencyField setFloatValue: inValue];	// update the frequency text field
					[graphView setFreq: inValue];					// update the graph's frequency visual state
					break;
				case kFilterParam_Resonance:						// handle resonance parameter
					[resonanceField setFloatValue: inValue];		// update the resonance text field
					[graphView setRes: inValue];					// update the graph's gain visual state
					break;					
			}
			// get the curve data from the audio unit
			[self updateCurve];
			break;
		case kAudioUnitEvent_BeginParameterChangeGesture:			// Begin gesture
			[graphView handleBeginGesture];							// notify graph view to update visual state
			break;
		case kAudioUnitEvent_EndParameterChangeGesture:				// End gesture
			[graphView handleEndGesture];							// notify graph view to update visual state
			break;
		case kAudioUnitEvent_PropertyChange:						// custom property changed
			if (inEvent->mArgument.mProperty.mPropertyID == kAudioUnitCustomProperty_FilterFrequencyResponse)
				[self updateCurve];
			break;
	}
}

/* If we get a mouseDown, that means it was not in the graph view, or one of the text fields. 
   In this case, we should make the window the first responder. This will deselect our text fields if they are active. */
- (void) mouseDown: (NSEvent *) theEvent {
	[super mouseDown: theEvent];
	[[self window] makeFirstResponder: self];
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL) becomeFirstResponder {	
	return YES;
}

- (BOOL) isOpaque {
	return YES;
}

@end
