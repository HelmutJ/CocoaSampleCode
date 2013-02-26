
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"
#import <IOKit/hid/IOHIDLib.h>
#import <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>

struct _GLUTinputActionRec __glutInputActionArray[kNumJoystickActions];
static Boolean __glutJoystickList = false;

/* CENTRY */
void APIENTRY glutJoystickFunc(void (*func)(unsigned int buttonMask, int x, int y, int z), int pollInterval)
{
	GLUTAPI_DECLARATIONS
	__glutCollectInputDevicesOnce();
	__glutMatchHIDPrefsToDevices();
	if (!__glutJoystickList)
		__glutInitJoystickInput (NULL);
	GLUTAPI_BEGIN
	[__glutCurrentView	setJoystickCallback: func
                        pollInterval: ((NSTimeInterval) pollInterval) / 1000.0];
	GLUTAPI_END
}

void APIENTRY glutForceJoystickFunc(void)
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
	[__glutCurrentView	processJoystick: NULL];
   GLUTAPI_END
}
/* ENDCENTRY */

short __glutGetJoystickNumButtons (void)
{
	short i, num = 0;
	if (!__glutJoystickList)
		__glutInitJoystickInput (NULL);
	for (i = kActionButton1; i < kNumJoystickActions; i++) // for all buttons
		if (__glutInputActionArray [i].pDevice != NULL) // if the device exists
			num++; // count
	return num;
}   

short __glutGetJoystickNumAxis (void)
{
	short i, num = 0;
	if (!__glutJoystickList)
	for (i = 0; i < kActionButton1; i++) // for all axis
		if (__glutInputActionArray [i].pDevice != NULL) // if the device exists
			num++; // count
	return num;
}   

struct _GLUTinputActionRec * __glutGetJoystickDeviceElement (short inputNum)
{
	if (!__glutJoystickList)
		__glutInitJoystickInput (NULL);
	return &__glutInputActionArray [inputNum];
}   

// check for attached devices (changes, reset globals if required for missing devices)
void __glutClearMissingDeviceJoystickInput (void) 
{
	short i;
	if (!__glutJoystickList)
		return;
	// assumes the list is updated
	for (i = 0; i < kNumJoystickActions; i++) {
		if (!__glutIsInputDeviceConnected(__glutInputActionArray[i].pDevice)) { // if we did not find the device
			__glutInputActionArray [i].pElement = NULL;
			__glutInputActionArray [i].pDevice = NULL;
			__glutInputActionArray [i].invertMul = 1; // not inverted
			__glutInputActionArray [i].value = 0;
		}
	}
}

void __glutFillEmptyJoystickInput (pRecDevice pDevice)
{
	short i;
   GLUTDeviceEnumerator	enumer;
	pRecDevice pSelDevice = NULL;
	pRecElement pElement = NULL;
	short selButtonCount = 0, selAxisCount = 0, currButton = 0;
   
   if (NULL == pDevice) { // no preferred device
		__glutGetInputDeviceEnumeratorOfClass(GLUT_JOYSTICK_DEVICE, &enumer);
		while((pDevice = __glutGetNextInputDevice(&enumer)) != NULL) { // while we have valid devices
			bool deviceSelect = NO;
			if (pDevice->axis >= 3) { // if device has at least 3 axis
				if ((selAxisCount < 3) || // previous device has less than 3 axis (select this device)
				    (pDevice->buttons > selButtonCount)) // select device has 3 or more axis and we have more buttons (select this device)
					deviceSelect = YES; 
				// else do not select (selected device has at least 3 axis and more buttons)
			} else if (((pDevice->axis == selAxisCount) && (pDevice->buttons > selButtonCount)) || // equal axis but more buttons (select this device)
					   (pDevice->axis == selAxisCount)) // more axis when current axis < 3
				deviceSelect = YES;
			if (YES == deviceSelect) { // if the number meet the min
				selAxisCount = pDevice->axis; // set selected number of axis
				selButtonCount = pDevice->buttons; // set selected number of buttons
				pSelDevice = pDevice; // set device
			}
		}
		pDevice = pSelDevice; // use a single device with the most axis
	}
	
	if (NULL == pDevice)
	{
		//we didn't find a suitable device, so leave things unassigned
		return;
	}

	__glutJoystickList = true; // set only if we found devices we like
   
	// prefer correct elements, then try any
	// look for x axis	
	if (NULL == __glutInputActionArray [kActionXAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X == pElement->usage)) { // if it is the x axis
				__glutInputActionArray [kActionXAxis].pDevice = pDevice;
				__glutInputActionArray [kActionXAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for y axis
	if (NULL == __glutInputActionArray [kActionYAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Y == pElement->usage)) { // if it is the y axis
				__glutInputActionArray [kActionYAxis].pDevice = pDevice;
				__glutInputActionArray [kActionYAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for z axis  (first as a z axis)
	if (NULL == __glutInputActionArray [kActionZAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Z == pElement->usage)) { // if it is the y axis
				__glutInputActionArray [kActionZAxis].pDevice = pDevice;
				__glutInputActionArray [kActionZAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for z axis as a z rotation (since most joysticks and gamepads are configured this way, thanks Windows...)
	if (NULL == __glutInputActionArray [kActionZAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Rz == pElement->usage)) { // if it is the y axis
				__glutInputActionArray [kActionZAxis].pDevice = pDevice;
				__glutInputActionArray [kActionZAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// for any not filled axis find any avialable (that is not already used)
	if (NULL == __glutInputActionArray [kActionXAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
					((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutInputActionArray [kActionYAxis].pElement) && (pElement != __glutInputActionArray [kActionZAxis].pElement)) { // not already used
					__glutInputActionArray [kActionXAxis].pDevice = pDevice;
					__glutInputActionArray [kActionXAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutInputActionArray [kActionYAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
					((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutInputActionArray [kActionXAxis].pElement) && (pElement != __glutInputActionArray [kActionZAxis].pElement)) { // not already used
					__glutInputActionArray [kActionYAxis].pDevice = pDevice;
					__glutInputActionArray [kActionYAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutInputActionArray [kActionZAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
					((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutInputActionArray [kActionXAxis].pElement) && (pElement != __glutInputActionArray [kActionYAxis].pElement)) { // not already used
					__glutInputActionArray [kActionZAxis].pDevice = pDevice;
					__glutInputActionArray [kActionZAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// find buttons (just fill them in order up to 32)
	pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
	while (pElement && (32 > currButton)) { // for each element and up to 32 buttons
		if  (kIOHIDElementTypeInput_Button == pElement->type) { // if it is a button
			Boolean found = false;
			short a;
			for (a = kActionButton1; a < kNumJoystickActions; a++) // check all buttons
				if (__glutInputActionArray [a].pElement == pElement) // is element used already
					found = true; // mark as such
			if (!found) { // if not used already
				while (NULL != __glutInputActionArray [kActionButton1 + currButton].pElement) // find first empty button
					currButton++; // advance until empty one since we can have a sparse array
				__glutInputActionArray [kActionButton1 + currButton].pDevice = pDevice; // assign button
				__glutInputActionArray [kActionButton1 + currButton].pElement = pElement;
			}
		}
		pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
	}
	// set device limits
	for (i = 0; i < kNumJoystickActions; i++)
	{
		if (__glutInputActionArray [i].pElement) {
			if (i < kActionButton1) {
				(__glutInputActionArray [i].pElement)->userMin = -1000;
				(__glutInputActionArray [i].pElement)->userMax = 1000;
			} else {
				(__glutInputActionArray [i].pElement)->userMin = 0;
				(__glutInputActionArray [i].pElement)->userMax = 1;
			}
		}
	}
	// all inputs will have same device
}

// assumes __glutCollectInputDevices already called
// check for atttached devices, set globals if required, enables/disblaes setup menu
void __glutInitJoystickInput (pRecDevice pDevice)
{
	int i;
	// zero all actions
	__glutJoystickList = false;
	for (i = 0; i < kNumJoystickActions; i++) {
		__glutInputActionArray [i].pElement = NULL;
		__glutInputActionArray [i].pDevice = NULL;
		__glutInputActionArray [i].invertMul = 1; // not inverted
		__glutInputActionArray [i].value = 0;
	}
	// find device with max (up to three) axis
	if (HIDCountDevices()) {
		__glutFillEmptyJoystickInput (pDevice);
	}
}

// return the device of first assigned input which will be the same for all inputs
pRecDevice __glutGetJoystickDevice (void)
{
	int i = 0;
	while ((NULL == __glutInputActionArray [i].pDevice) && (i < kNumJoystickActions))
		i++;
	if (i < kNumJoystickActions)
		return __glutInputActionArray [i].pDevice;
	else
		return NULL;
} 

// assumes __glutCollectInputDevices already called
// check for attached devices (changes, reset globals if required for missing devices)
// sets to device with at least 3 axis (or most if less) and most buttons is current device does not exist
void __glutUpdateJoystickInput (void) 
{
	if (!__glutJoystickList)
		__glutInitJoystickInput (NULL);
	else {
		// check for device ensure inputs are clear if device is not present
		if (NULL != __glutGetJoystickDevice()) // if we found a assigned input
			__glutClearMissingDeviceJoystickInput (); // check to ensure device is attached
		if (NULL == __glutGetJoystickDevice()) // if we cleared the input or if we found no assigned inputs
			__glutInitJoystickInput (NULL); // init the list
	}
}

// returns current polled values of first gamepad or joystick found
void __glutGetJoystickInput (int *pButtonMask, int *pX,  int *pY,  int *pZ)
{
    short a;
	*pButtonMask = 0;
	if (!__glutJoystickList) {
		*pX = 0;
		*pY = 0;
		*pZ = 0;
		return;
	}
    for (a = 0; a < kNumJoystickActions; a++)
    {
		__glutInputActionArray [a].value = 0;
		if (__glutInputActionArray [a].pDevice && __glutInputActionArray [a].pElement) { // handle device input
			__glutInputActionArray [a].value = HIDGetElementValue (__glutInputActionArray [a].pDevice, __glutInputActionArray [a].pElement);
			switch (a) {
				case kActionXAxis:
					*pX = __glutInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement), __glutInputActionArray [a].pElement);
					break;
				case kActionYAxis:
					*pY = __glutInputActionArray [a].invertMul * 
					      HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement);
//					      HIDScaleValue (HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement), __glutInputActionArray [a].pElement);
					break;
				case kActionZAxis:
					*pZ = __glutInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement), __glutInputActionArray [a].pElement);
					break;
				default:
					if (__glutInputActionArray [a].invertMul == 1)
//						*pButtonMask += HIDScaleValue (HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement), __glutInputActionArray [a].pElement) << 
						*pButtonMask += HIDScaleValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement) << 
									    (a - kActionButton1);
					else
//						*pButtonMask += (1 - HIDScaleValue (HIDCalibrateValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement), __glutInputActionArray [a].pElement)) << 
						*pButtonMask += (1 - HIDScaleValue (__glutInputActionArray [a].value, __glutInputActionArray [a].pElement)) << 
									    (a - kActionButton1);
					break;
			}
		}
    }
}
