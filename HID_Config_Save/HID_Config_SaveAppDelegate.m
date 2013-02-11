//     File: HID_Config_SaveAppDelegate.m
// Abstract: Implementation file for HID_Config_SaveAppDelegate class of HID_Config_Save project
//  Version: 5.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 
#import "PlayView.h"
#import "HID_Config_SaveAppDelegate.h"
// ****************************************************
#pragma mark -
#pragma mark * (private) @interface *
// ----------------------------------------------------
@interface HID_Config_SaveAppDelegate (private)
- (OSStatus) initHID;
- (OSStatus) termHID;
- (void) deviceMatchingResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef;
- (void) deviceRemovalResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef;
#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
- (void) valueAvailableResult: (IOReturn) inResult sender: (void *) inSender;
#elif USE_INPUT_VALUE_CALLBACK
- (void) inputValueResult: (IOReturn) inResult sender: (void *) inSender value: (IOHIDValueRef) inIOHIDValueRef;
#else // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
- (void) idleTimer: (NSTimer *) inTimer;
#endif // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
- (double) calibrateElementValue: (IOHIDValueRef) inIOHIDValueRef;
@end;

// ****************************************************
#pragma mark -
#pragma mark * static (local) function prototypes *
// ----------------------------------------------------
static CFStringRef Copy_DeviceName(IOHIDDeviceRef inIOHIDDeviceRef);
static NSString *Copy_DeviceElementNameString(IOHIDDeviceRef inIOHIDDeviceRef, IOHIDElementRef inIOHIDElementRef);
static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);

static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);

#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
static void Handle_ValueAvailableCallback(void *inContext, IOReturn inResult, void *inSender);
#elif USE_INPUT_VALUE_CALLBACK
static void Handle_InputValueCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDValueRef inIOHIDValueRef);
#endif // USE_INPUT_VALUE_CALLBACK
// ****************************************************
#pragma mark -
#pragma mark * @implementation *
// ----------------------------------------------------

@implementation HID_Config_SaveAppDelegate
// ****************************************************
#pragma mark -
#pragma mark * public class methods *
// ----------------------------------------------------

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) configureXAxis: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	IOHIDDeviceRef tIOHIDDeviceRef = NULL;
	IOHIDElementRef tIOHIDElementRef = NULL;
	if (HIDConfigureActionOfType(kActionTypeAxis, 10.0, &tIOHIDDeviceRef, &tIOHIDElementRef)) {
		actionRecs[kActionXAxis].fDeviceRef = tIOHIDDeviceRef;
		actionRecs[kActionXAxis].fElementRef = tIOHIDElementRef;
		NSString *devEleName = Copy_DeviceElementNameString(tIOHIDDeviceRef, tIOHIDElementRef);
		if (devEleName) {
			[xAxisTextField setStringValue:devEleName];
		}
		
		// if the calibration parameters haven't been set yet…
		double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
		if (granularity < 0) {
			// … do it now
			HIDSetupElementCalibration(tIOHIDElementRef);
		}
		
		IOHIDValueRef tIOHIDValueRef;
		if (kIOReturnSuccess ==
		    IOHIDDeviceGetValue(IOHIDElementGetDevice(tIOHIDElementRef), tIOHIDElementRef, &tIOHIDValueRef))
		{
			actionRecs[kActionXAxis].fValue = [self calibrateElementValue:tIOHIDValueRef];
		}
		
		playView.x = actionRecs[kActionXAxis].fValue;
	}
} // configureXAxis
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) configureYAxis: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	IOHIDDeviceRef tIOHIDDeviceRef = NULL;
	IOHIDElementRef tIOHIDElementRef = NULL;
	if (HIDConfigureActionOfType(kActionTypeAxis, 10.0, &tIOHIDDeviceRef, &tIOHIDElementRef)) {
		actionRecs[kActionYAxis].fDeviceRef = tIOHIDDeviceRef;
		actionRecs[kActionYAxis].fElementRef = tIOHIDElementRef;
		NSString *devEleName = Copy_DeviceElementNameString(tIOHIDDeviceRef, tIOHIDElementRef);
		if (devEleName) {
			[yAxisTextField setStringValue:devEleName];
		}
		
		// if the calibration parameters haven't been set yet…
		double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
		if (granularity < 0) {
			// … do it now
			HIDSetupElementCalibration(tIOHIDElementRef);
		}
		
		IOHIDValueRef tIOHIDValueRef;
		if (kIOReturnSuccess ==
		    IOHIDDeviceGetValue(IOHIDElementGetDevice(tIOHIDElementRef), tIOHIDElementRef, &tIOHIDValueRef))
		{
			actionRecs[kActionYAxis].fValue = [self calibrateElementValue:tIOHIDValueRef];
		}
		
		playView.y = actionRecs[kActionYAxis].fValue;
	}
} // configureYAxis
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) configureThrust: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	IOHIDDeviceRef tIOHIDDeviceRef = NULL;
	IOHIDElementRef tIOHIDElementRef = NULL;
	if (HIDConfigureActionOfType(kActionTypeButton, 10.0, &tIOHIDDeviceRef, &tIOHIDElementRef)) {
		actionRecs[kActionThrust].fDeviceRef = tIOHIDDeviceRef;
		actionRecs[kActionThrust].fElementRef = tIOHIDElementRef;
		NSString *devEleName = Copy_DeviceElementNameString(tIOHIDDeviceRef, tIOHIDElementRef);
		if (devEleName) {
			[thrustTextField setStringValue:devEleName];
		}
		
		// if the calibration parameters haven't been set yet…
		double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
		if (granularity < 0) {
			// … do it now
			HIDSetupElementCalibration(tIOHIDElementRef);
		}
		
		IOHIDValueRef tIOHIDValueRef;
		if (kIOReturnSuccess ==
		    IOHIDDeviceGetValue(IOHIDElementGetDevice(tIOHIDElementRef), tIOHIDElementRef, &tIOHIDValueRef))
		{
			actionRecs[kActionThrust].fValue = [self calibrateElementValue:tIOHIDValueRef];
		}
		
		playView.thrust = actionRecs[kActionThrust].fValue;
	}
} // configureThrust
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) configureFire: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	IOHIDDeviceRef tIOHIDDeviceRef = NULL;
	IOHIDElementRef tIOHIDElementRef = NULL;
	if (HIDConfigureActionOfType(kActionTypeButton, 10.0, &tIOHIDDeviceRef, &tIOHIDElementRef)) {
		actionRecs[kActionFire].fDeviceRef = tIOHIDDeviceRef;
		actionRecs[kActionFire].fElementRef = tIOHIDElementRef;
		NSString *devEleName = Copy_DeviceElementNameString(tIOHIDDeviceRef, tIOHIDElementRef);
		if (devEleName) {
			[fireTextField setStringValue:devEleName];
		}
		
		// if the calibration parameters haven't been set yet…
		double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
		if (granularity < 0) {
			// … do it now
			HIDSetupElementCalibration(tIOHIDElementRef);
		}
		
		IOHIDValueRef tIOHIDValueRef;
		if (kIOReturnSuccess ==
		    IOHIDDeviceGetValue(IOHIDElementGetDevice(tIOHIDElementRef), tIOHIDElementRef, &tIOHIDValueRef))
		{
			actionRecs[kActionFire].fValue = [self calibrateElementValue:tIOHIDValueRef];
		}
		
		playView.fire = actionRecs[kActionFire].fValue;
	}
} // configureFire
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) saveConfiguration: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	
	Boolean syncFlag = false;
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		CFStringRef keyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("HID Action #%d"), actionIndex);
		if (keyCFStringRef) {
			syncFlag |= HIDSaveElementPref(keyCFStringRef,
			                               kCFPreferencesCurrentApplication,
			                               actionRecs[actionIndex].fDeviceRef,
			                               actionRecs[actionIndex].fElementRef);
			CFRelease(keyCFStringRef);
		}
	}
	if (syncFlag) {
		CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
	}
} // saveConfiguration
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) restoreConfiguration: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		CFStringRef keyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("HID Action #%d"), actionIndex);
		if (keyCFStringRef) {
			bzero(&actionRecs[actionIndex], sizeof(actionRecs[actionIndex]));
			if (HIDRestoreElementPref(keyCFStringRef, kCFPreferencesCurrentApplication, &actionRecs[actionIndex].fDeviceRef,
			                          &actionRecs[actionIndex].fElementRef))
			{
				// if the calibration parameters haven't been set yet…
				double_t granularity = IOHIDElement_GetCalibrationGranularity(actionRecs[actionIndex].fElementRef);
				if (granularity < 0.0) {
					// … do it now
					HIDSetupElementCalibration(actionRecs[actionIndex].fElementRef);
				}
				
				NSString *devEleName = Copy_DeviceElementNameString(actionRecs[actionIndex].fDeviceRef,
				                                                    actionRecs[actionIndex].fElementRef);
				if (devEleName) {
					switch (actionIndex) {
						case kActionXAxis:
						{
							[xAxisTextField setStringValue:devEleName];
							break;
						}
							
						case kActionYAxis:
						{
							[yAxisTextField setStringValue:devEleName];
							break;
						}
							
						case kActionThrust:
						{
							[thrustTextField setStringValue:devEleName];
							break;
						}
							
						case kActionFire:
						{
							[fireTextField setStringValue:devEleName];
							break;
						}
							
						default:
						{
							break;
						}
					} // switch
				}
			} // if HIDRestoreElementPref…
			CFRelease(keyCFStringRef);
		}   // if (keyCFStringRef)
	}   // for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++)
	
} // restoreConfiguration
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) rebuild: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	(void) HIDBuildMultiDeviceList(nil, nil, 0);
	[self restoreConfiguration:nil];
} // rebuild
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) test: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
}
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) poll: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
}
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) ping: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
}

// ****************************************************
#pragma mark * delegate methods *
// ----------------------------------------------------

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	NSLogDebug(@"aNotification: <%@>", aNotification);
	
	bzero(actionRecs, sizeof(actionRecs));
	
	playView.minX = playView.minY = 0.0;
	playView.maxX = playView.maxY = 255.0;
	
	[tabView selectFirstTabViewItem:NULL];
	
	[self initHID];
} // applicationDidFinishLaunching

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) applicationWillTerminate: (NSNotification *) aNotification {
	NSLogDebug(@"aNotification: <%@>", aNotification);
	
	[self termHID];
}   // applicationWillTerminate

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) tabView: (NSTabView *) inTabView didSelectTabViewItem: (NSTabViewItem *) inTabViewItem {
	NSLogDebug(@"tabView: <%@>, tabViewItem: <%@>", inTabView, inTabViewItem);
	if (gIOHIDManagerRef) {
		if ([[inTabViewItem label] isEqualToString:@"Configure"]) {
			NSLogDebug(@"Configure!");
#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
			if (ioHIDQueueRefsCFArrayRef) {
				CFIndex idx, cnt = CFArrayGetCount(ioHIDQueueRefsCFArrayRef);
				for (idx = 0; idx < cnt; idx++) {
					IOHIDQueueRef tIOHIDQueueRef = (IOHIDQueueRef) CFArrayGetValueAtIndex(ioHIDQueueRefsCFArrayRef, idx);
					if (!tIOHIDQueueRef) {
						continue;
					}
					
					IOHIDQueueStop(tIOHIDQueueRef);
					IOHIDQueueRegisterValueAvailableCallback(tIOHIDQueueRef, NULL, NULL);
					IOHIDQueueUnscheduleFromRunLoop(tIOHIDQueueRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
				}
				
				CFRelease(ioHIDQueueRefsCFArrayRef);
				ioHIDQueueRefsCFArrayRef = NULL;
			}
			
#elif USE_INPUT_VALUE_CALLBACK
			for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
				if (actionRecs[actionIndex].fDeviceRef) {
					// unschedule us from runloop
					IOHIDDeviceUnscheduleFromRunLoop(actionRecs[actionIndex].fDeviceRef,
					                                 CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
					// unregister input value callback for this device (dups don't hurt)
					IOHIDDeviceRegisterInputValueCallback(actionRecs[actionIndex].fDeviceRef, NULL, NULL);
				}
			}
			
#else // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
			if (timer) {
				[timer invalidate];
				[timer release];
				timer = nil;
			}
			
#endif // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
		} else if ([[inTabViewItem label] isEqualToString:@"Play"]) {
			NSLogDebug(@"Play!");
			
#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
			if (ioHIDQueueRefsCFArrayRef) {
				CFRelease(ioHIDQueueRefsCFArrayRef);
			}
			
			ioHIDQueueRefsCFArrayRef = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
			for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
				if (actionRecs[actionIndex].fDeviceRef) {
					IOHIDQueueRef tIOHIDQueueRef = NULL;
					
					// see if we already have a queue for this device
					int idx, cnt = CFArrayGetCount(ioHIDQueueRefsCFArrayRef);
					for (idx = 0; idx < cnt; idx++) {
						IOHIDQueueRef tempIOHIDQueueRef = (IOHIDQueueRef) CFArrayGetValueAtIndex(ioHIDQueueRefsCFArrayRef, idx);
						if (!tempIOHIDQueueRef) {
							continue;
						}
						if (actionRecs[actionIndex].fDeviceRef == IOHIDQueueGetDevice(tempIOHIDQueueRef)) {
							tIOHIDQueueRef = tempIOHIDQueueRef; // Found one!
							IOHIDQueueStop(tIOHIDQueueRef);     // (we'll restart it below)
							break;
						}
					}
					if (!tIOHIDQueueRef) {      // nope, create one
						tIOHIDQueueRef = IOHIDQueueCreate(kCFAllocatorDefault, actionRecs[actionIndex].fDeviceRef, 256, 0);
						if (tIOHIDQueueRef) {   // and add it to our array of queues
							CFArrayAppendValue(ioHIDQueueRefsCFArrayRef, tIOHIDQueueRef);
						}
					}
					if (tIOHIDQueueRef) {
						IOHIDQueueAddElement(tIOHIDQueueRef, actionRecs[actionIndex].fElementRef);
						IOHIDQueueRegisterValueAvailableCallback(tIOHIDQueueRef, Handle_ValueAvailableCallback, self);
						IOHIDQueueScheduleWithRunLoop(tIOHIDQueueRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
						IOHIDQueueStart(tIOHIDQueueRef);    // (re?)start it
					}
				}
			}
			
#elif USE_INPUT_VALUE_CALLBACK
			// collect matching dictionarys for up to four devices
			CFMutableArrayRef inputValueMatchingArrays[kNumActions] = {NULL, NULL, NULL, NULL};
			for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
				// register input value callback for this device (dups don't hurt)
				IOHIDDeviceRegisterInputValueCallback(actionRecs[actionIndex].fDeviceRef, Handle_InputValueCallback, self);
				
				// Now create a matching dictionary for this element
				IOHIDElementCookie cookie = IOHIDElementGetCookie(actionRecs[actionIndex].fElementRef);
				uint32_t usagePage = IOHIDElementGetUsagePage(actionRecs[actionIndex].fElementRef);
				uint32_t usage = IOHIDElementGetUsage(actionRecs[actionIndex].fElementRef);
				
				const void *keys[] = {
					CFSTR(kIOHIDElementCookieKey),
					CFSTR(kIOHIDElementUsagePageKey),
					CFSTR(kIOHIDElementUsageKey)
				};
				const void *vals[] = {
					CFNumberCreate(kCFAllocatorDefault,
								   kCFNumberSInt32Type,
								   &cookie),
					CFNumberCreate(kCFAllocatorDefault,
								   kCFNumberSInt32Type,
								   &usagePage),
					CFNumberCreate(kCFAllocatorDefault,
								   kCFNumberSInt32Type,
								   &usage)
				};
				CFDictionaryRef elementMatchingDict = CFDictionaryCreate(kCFAllocatorDefault,
																		 keys,
																		 vals,
																		 3,
																		 &kCFTypeDictionaryKeyCallBacks,
																		 &kCFTypeDictionaryValueCallBacks);
				
				int i;  // append this matching dict to the first matching arrays for the same device
				for (i = 0; i <= actionIndex; i++) {
					if (actionRecs[actionIndex].fDeviceRef == actionRecs[i].fDeviceRef) {
						if (!inputValueMatchingArrays[i]) {
							inputValueMatchingArrays[i] = CFArrayCreateMutable(kCFAllocatorDefault,
							                                                   kNumActions,
							                                                   &kCFTypeArrayCallBacks);
						}
						
						CFArrayAppendValue(inputValueMatchingArrays[i], elementMatchingDict);
						break;
					}
				}
				
				// release everything were done with
				CFRelease(elementMatchingDict);
				CFRelease(vals[0]);
				CFRelease(vals[1]);
				CFRelease(vals[2]);
			}
			for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
				if (inputValueMatchingArrays[actionIndex]) {
					IOHIDDeviceSetInputValueMatchingMultiple(actionRecs[actionIndex].fDeviceRef,
					                                         inputValueMatchingArrays[actionIndex]);
					CFRelease(inputValueMatchingArrays[actionIndex]);
				}
			}
			
#else // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
			timer = [[NSTimer alloc] initWithFireDate:[NSDate date]
											 interval:0.1
											   target:self
											 selector:@selector(idleTimer:)
											 userInfo:nil
											  repeats:YES
					 ];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
#endif // USE_QUEUE_VALUE_AVAILABLE_CALLBACK
		}
	}
}   // tabView:didSelectTabViewItem:

// ****************************************************
#pragma mark * private class methods *
// ----------------------------------------------------

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (OSStatus) initHID {
	OSStatus result = -1;
	
	// create the manager
	gIOHIDManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
	if (gIOHIDManagerRef) {
		// open it
		IOReturn tIOReturn = IOHIDManagerOpen(gIOHIDManagerRef, kIOHIDOptionsTypeNone);
		if (kIOReturnSuccess == tIOReturn) {
			NSLogDebug(@"IOHIDManager (%p) creaded and opened!\n", (void *) gIOHIDManagerRef);
		} else {
			NSLog(@"%Couldn’t open IOHIDManager.");
		}
	} else {
		NSLog(@"%Couldn’t create a IOHIDManager.");
	}
	if (gIOHIDManagerRef) {
		// schedule with runloop
		IOHIDManagerScheduleWithRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		// register callbacks
		IOHIDManagerRegisterDeviceMatchingCallback(gIOHIDManagerRef, Handle_DeviceMatchingCallback, self);
		IOHIDManagerRegisterDeviceRemovalCallback(gIOHIDManagerRef, Handle_DeviceRemovalCallback, self);
	}
	
	require(HIDBuildMultiDeviceList(nil, nil, 0), Oops);
	
#if FALSE // set true to log devices
	{
		CFIndex idx, cnt = CFArrayGetCount(gDeviceCFArrayRef);
		for (idx = 0; idx < cnt; idx++) {
			IOHIDDeviceRef tIOHIDDeviceRef = (IOHIDDeviceRef) CFArrayGetValueAtIndex(gDeviceCFArrayRef, idx);
			if (!tIOHIDDeviceRef) {
				continue;
			}
			if (CFGetTypeID(tIOHIDDeviceRef) != IOHIDDeviceGetTypeID()) {
				continue;
			}
			
			HIDDumpDeviceInfo(tIOHIDDeviceRef);
		}
		
		fflush(stdout);
	}
#endif // if TRUE
	
	[self restoreConfiguration:nil];
	
Oops:;
	return (result);
}   // initHID
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

- (OSStatus) termHID {
	if (gIOHIDManagerRef) {
#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
		if (ioHIDQueueRefsCFArrayRef) {
			CFRelease(ioHIDQueueRefsCFArrayRef);
			ioHIDQueueRefsCFArrayRef = NULL;
		}
		
#elif USE_INPUT_VALUE_CALLBACK
		for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
			if (actionRecs[actionIndex].fDeviceRef) {
				IOHIDDeviceUnscheduleFromRunLoop(actionRecs[actionIndex].fDeviceRef,
				                                 CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
				IOHIDDeviceRegisterInputValueCallback(actionRecs[actionIndex].fDeviceRef, NULL, NULL);
			}
		}
		
#else // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
		[timer release];
#endif  // USE_QUEUE_VALUE_AVAILABLE_CALLBACK
		IOHIDManagerRegisterDeviceMatchingCallback(gIOHIDManagerRef, NULL, NULL);
		IOHIDManagerRegisterDeviceRemovalCallback(gIOHIDManagerRef, NULL, NULL);
		IOHIDManagerUnscheduleFromRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
	if (gElementCFArrayRef) {
		CFRelease(gElementCFArrayRef);
		gElementCFArrayRef = NULL;
	}
	if (gDeviceCFArrayRef) {
		CFRelease(gDeviceCFArrayRef);
		gDeviceCFArrayRef = NULL;
	}
	if (gIOHIDManagerRef) {
		IOHIDManagerClose(gIOHIDManagerRef, 0);
		gIOHIDManagerRef = NULL;
	}
	
	return (noErr);
}   // termHID

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

- (void) deviceMatchingResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef {
#pragma unused (inResult, inSender, inIOHIDDeviceRef)
	NSLogDebug(@"result: %p, sender: %p, device %p", inResult, inSender, inIOHIDDeviceRef);
#if DEBUG
	HIDDumpDeviceInfo(inIOHIDDeviceRef);
#endif // DEBUG
	
	HIDRebuildDevices();
	[self restoreConfiguration:nil];
} // deviceMatchingResult

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) deviceRemovalResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef {
#pragma unused (inResult, inSender, inIOHIDDeviceRef)
	NSLogDebug(@"result: %p, sender: %p, device %p", inResult, inSender, inIOHIDDeviceRef);
#if DEBUG
	HIDDumpDeviceInfo(inIOHIDDeviceRef);
#endif // DEBUG
	
	HIDRebuildDevices();
	[self restoreConfiguration:nil];
} // deviceRemovalResult

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
- (void) valueAvailableResult: (IOReturn) inResult sender: (void *) inSender {
#pragma unused (inResult, inSender, inIOHIDDeviceRef)
	NSLogDebug(@"result: %p, sender: %p", inResult, inSender);
	
	while (TRUE) {
		IOHIDValueRef tIOHIDValueRef = IOHIDQueueCopyNextValue((IOHIDQueueRef) inSender);
		if (!tIOHIDValueRef) {
			break;                        // no more data
		}
		for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
			if (!actionRecs[actionIndex].fDeviceRef || !actionRecs[actionIndex].fElementRef) {
				continue;
			}
			if (actionRecs[actionIndex].fElementRef != IOHIDValueGetElement(tIOHIDValueRef)) {
				continue;
			}
			
			actionRecs[actionIndex].fValue = [self calibrateElementValue:tIOHIDValueRef];
			
			switch (actionIndex) {
				case kActionXAxis:
				{
					playView.x = actionRecs[kActionXAxis].fValue;
					break;
				}
					
				case kActionYAxis:
				{
					playView.y = actionRecs[kActionYAxis].fValue;
					break;
				}
					
				case kActionThrust:
				{
					playView.thrust = actionRecs[kActionThrust].fValue;
					break;
				}
					
				case kActionFire:
				{
					playView.fire = actionRecs[kActionFire].fValue;
					break;
				}
					
				default:
				{
					break;
				}
			} // switch
			
			NSLogDebug(@"element # %d = { value: %6.2f }.\n", actionIndex, actionRecs[actionIndex].fValue);
		}
		
		// fflush( stdout );
	}
}   // valueAvailableResult:sender
#elif USE_INPUT_VALUE_CALLBACK
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) inputValueResult: (IOReturn) inResult sender: (void *) inSender value: (IOHIDValueRef) inIOHIDValueRef {
#pragma unused (inResult, inSender, inIOHIDValueRef)
	NSLogDebug(@"result: %p, sender: %p, value %p", inResult, inSender, inIOHIDValueRef);
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		if (!actionRecs[actionIndex].fDeviceRef || !actionRecs[actionIndex].fElementRef) {
			continue;
		}
		if (actionRecs[actionIndex].fElementRef != IOHIDValueGetElement(inIOHIDValueRef)) {
			continue;
		}
		
		actionRecs[actionIndex].fValue = [self calibrateElementValue:inIOHIDValueRef];
		
		switch (actionIndex) {
			case kActionXAxis:
			{
				playView.x = actionRecs[kActionXAxis].fValue;
				break;
			}
				
			case kActionYAxis:
			{
				playView.y = actionRecs[kActionYAxis].fValue;
				break;
			}
				
			case kActionThrust:
			{
				playView.thrust = actionRecs[kActionThrust].fValue;
				break;
			}
				
			case kActionFire:
			{
				playView.fire = actionRecs[kActionFire].fValue;
				break;
			}
				
			default:
			{
				break;
			}
		} // switch
		
		NSLogDebug(@"element # %d = { value: %6.2f }.\n", actionIndex, actionRecs[actionIndex].fValue);
	}
	
	inResult = kIOReturnSuccess;
}       // inputValueResult
#else   // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) idleTimer: (NSTimer *) inTimer {
	NSLogDebug(@"timer: <%@>", inTimer);
	// get input values
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		actionRecs[actionIndex].fValue = 0.0;
		if (actionRecs[actionIndex].fDeviceRef && actionRecs[actionIndex].fElementRef) {
			IOHIDValueRef tIOHIDValueRef;
			if (kIOReturnSuccess ==
			    IOHIDDeviceGetValue(actionRecs[actionIndex].fDeviceRef, actionRecs[actionIndex].fElementRef, &tIOHIDValueRef))
			{
				actionRecs[actionIndex].fValue = [self calibrateElementValue:tIOHIDValueRef];
				
				switch (actionIndex) {
					case kActionXAxis:
					{
						playView.x = actionRecs[kActionXAxis].fValue;
						break;
					}
						
					case kActionYAxis:
					{
						playView.y = actionRecs[kActionYAxis].fValue;
						break;
					}
						
					case kActionThrust:
					{
						playView.thrust = actionRecs[kActionThrust].fValue;
						break;
					}
						
					case kActionFire:
					{
						playView.fire = actionRecs[kActionFire].fValue;
						break;
					}
						
					default:
					{
						break;
					}
				} // switch
				
				NSLogDebug(@"element # %d = { value: %6.2f }.\n", actionIndex, actionRecs[actionIndex].fValue);
			}
		}
	}
}   // idleTimer:
#endif // if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
// ----------------------------------------------------
// ----------------------------------------------------
- (double) calibrateElementValue: (IOHIDValueRef) inIOHIDValueRef {
	double result = 0.;
	if (inIOHIDValueRef) {
		result = IOHIDValueGetScaledValue(inIOHIDValueRef, kIOHIDValueScaleTypePhysical);
		
		IOHIDElementRef tIOHIDElementRef = IOHIDValueGetElement(inIOHIDValueRef);
		if (tIOHIDElementRef) {
#if 0
			double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
			if (granularity < 0.0) {
				printf("%s, BAD granularity!\n", __PRETTY_FUNCTION__);
				HIDSetupElementCalibration(tIOHIDElementRef);
				granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
				if (granularity < 0.0) {
					printf("%s, VERY BAD granularity!\n", __PRETTY_FUNCTION__);
				}
			}
			
#endif      // if 0
			if (result < IOHIDElement_GetCalibrationSaturationMin(tIOHIDElementRef)) {
				IOHIDElement_SetCalibrationSaturationMin(tIOHIDElementRef, result);
			}
			if (result > IOHIDElement_GetCalibrationSaturationMax(tIOHIDElementRef)) {
				IOHIDElement_SetCalibrationSaturationMax(tIOHIDElementRef, result);
			}
			
			result = IOHIDValueGetScaledValue(inIOHIDValueRef, kIOHIDValueScaleTypeCalibrated);
		}
	}
	
	return (result);
} /* Do_Element_Calibration */

// ****************************************************
#pragma mark * @synthesize properties *
// ----------------------------------------------------

@synthesize window;
@synthesize tabView;

@synthesize  xAxisTextField;
@synthesize  yAxisTextField;
@synthesize  thrustTextField;
@synthesize  fireTextField;

@synthesize  playView;

@end

// ****************************************************
#pragma mark -
#pragma mark * static functions *
// ----------------------------------------------------
// get name of device
// ----------------------------------------------------
static CFStringRef Copy_DeviceName(IOHIDDeviceRef inIOHIDDeviceRef) {
	CFStringRef result = NULL;
	if (inIOHIDDeviceRef) {
		CFStringRef manCFStringRef = IOHIDDevice_GetManufacturer(inIOHIDDeviceRef);
		if (manCFStringRef) {
			// make a copy that we can CFRelease later
			CFMutableStringRef tCFStringRef = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, manCFStringRef);
			
			// trim off any trailing spaces
			while (CFStringHasSuffix(tCFStringRef, CFSTR(" "))) {
				CFIndex cnt = CFStringGetLength(tCFStringRef);
				if (!cnt) {
					break;
				}
				
				CFStringDelete(tCFStringRef, CFRangeMake(cnt - 1, 1));
			}
			
			manCFStringRef = tCFStringRef;
		}
		if (!manCFStringRef) {
			// use the vendor ID to make a manufacturer string
			long vendorID = IOHIDDevice_GetVendorID(inIOHIDDeviceRef);
			manCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("vendor: %d"), vendorID);
		}
		
		CFStringRef prodCFStringRef = IOHIDDevice_GetProduct(inIOHIDDeviceRef);
		if (prodCFStringRef) {
			// make a copy that we can CFRelease later
			prodCFStringRef = CFStringCreateCopy(kCFAllocatorDefault, prodCFStringRef);
		} else {
			// use the product ID
			long productID = IOHIDDevice_GetProductID(inIOHIDDeviceRef);
			
			// to make a product string
			prodCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
			                                           CFSTR("%@ - product id %d"), manCFStringRef, productID);
		}
		
		assert(prodCFStringRef);
		// if the product name begins with the manufacturer string...
		if (CFStringHasPrefix(prodCFStringRef, manCFStringRef)) {
			// then just use the product name
			result = CFStringCreateCopy(kCFAllocatorDefault, prodCFStringRef);
		} else {    // otherwise
			// append the product name to the manufacturer
			result = CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
			                                  CFSTR("%@ - %@"), manCFStringRef, prodCFStringRef);
		}
		if (manCFStringRef) {
			CFRelease(manCFStringRef);
		}
		if (prodCFStringRef) {
			CFRelease(prodCFStringRef);
		}
	}
	
	return (result);
}   // Copy_DeviceName

// ----------------------------------------------------
// get name of element for display in window;
// try names first then default to more generic derived names if device does not provide explicit names
// ----------------------------------------------------
static NSString *Copy_DeviceElementNameString(IOHIDDeviceRef inIOHIDDeviceRef, IOHIDElementRef inIOHIDElementRef) {
	NSString *result = NULL;
	if (inIOHIDDeviceRef && inIOHIDElementRef) {
		char cstrDevice[256] = "----", cstrElement[256] = "----";
		// if this is not a valid device
		if (CFGetTypeID(inIOHIDDeviceRef) != IOHIDDeviceGetTypeID()) {
			return (result);
		}
		// if this is not a valid element
		if (CFGetTypeID(inIOHIDElementRef) != IOHIDElementGetTypeID()) {
			return (result);
		}
		
		CFStringRef devCFStringRef = Copy_DeviceName(inIOHIDDeviceRef);
		if (devCFStringRef) {
			(void) CFStringGetCString(devCFStringRef, cstrDevice, sizeof(cstrDevice), kCFStringEncodingUTF8);
			CFRelease(devCFStringRef);
		}
		
		CFStringRef eleCFStringRef = IOHIDElementGetName(inIOHIDElementRef);
		if (eleCFStringRef) {
			(void) CFStringGetCString(eleCFStringRef, cstrElement, sizeof(cstrElement), kCFStringEncodingUTF8);
		} else {
			long vendorID = IOHIDDevice_GetVendorID(inIOHIDDeviceRef);
			long productID = IOHIDDevice_GetProductID(inIOHIDDeviceRef);
			if (!HIDGetElementNameFromVendorProductCookie(vendorID, productID,
			                                              IOHIDElementGetCookie(inIOHIDElementRef),
			                                              cstrElement))
			{
				long usagePage = IOHIDElementGetUsagePage(inIOHIDElementRef);
				long usage = IOHIDElementGetUsage(inIOHIDElementRef);
				if (!HIDGetElementNameFromVendorProductUsage(vendorID, productID, usagePage, usage, cstrElement)) {
					eleCFStringRef = HIDCopyUsageName(usagePage, usage);
					if (eleCFStringRef) {
						(void) CFStringGetCString(eleCFStringRef, cstrElement, sizeof(cstrElement), kCFStringEncodingUTF8);
						CFRelease(eleCFStringRef);
					} else {
						sprintf(cstrElement, "ele: %08lX:%08lX", usagePage, usage);
					}
				}   // if ( !HIDGetElementNameFromVendorProductUsage(...) )
				
			}       // if ( !HIDGetElementNameFromVendorProductCookie(...) )
			
		}           // if ( eleCFStringRef )
		
		result = [NSString stringWithFormat:@"%s, %s", cstrDevice, cstrElement];
	}
	
	return (result);
}   // Copy_DeviceElementNameString
// ****************************************************
#pragma mark *	IOHID Callbacks *
// ----------------------------------------------------

static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
	// NSLogDebug();
	// call the class method
	[(HID_Config_SaveAppDelegate *) inContext deviceMatchingResult:inResult
															sender:inSender
															device:inIOHIDDeviceRef];
}   // Handle_DeviceMatchingCallback

static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
	// NSLogDebug();
	// call the class method
	[(HID_Config_SaveAppDelegate *) inContext deviceRemovalResult:inResult
														   sender:inSender
														   device:inIOHIDDeviceRef];
}   // Handle_DeviceRemovalCallback

#if USE_QUEUE_VALUE_AVAILABLE_CALLBACK
static void Handle_ValueAvailableCallback(void *inContext, IOReturn inResult, void *inSender) {
	// NSLogDebug();
	// call the class method
	[(HID_Config_SaveAppDelegate *) inContext valueAvailableResult:inResult sender:inSender];
}   // Handle_ValueAvailableCallback
#elif USE_INPUT_VALUE_CALLBACK
static void Handle_InputValueCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDValueRef inIOHIDValueRef) {
	// NSLogDebug();
	// call the class method
	[(HID_Config_SaveAppDelegate *) inContext inputValueResult:inResult sender:inSender value:inIOHIDValueRef];
} // Handle_InputValueCallback
#endif // USE_INPUT_VALUE_CALLBACK
