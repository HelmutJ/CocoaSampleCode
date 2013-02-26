
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"
#import <IOKit/hid/IOHIDLib.h>
#import <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>

struct _GLUTinputActionRec __glutSBInputActionArray[kNumSpaceballActions];
static Boolean __glutSpaceballList = false;

/* CENTRY */
void APIENTRY glutSpaceballMotionFunc(void (*func)(int x, int y, int z))
{
	GLUTAPI_DECLARATIONS
	__glutCollectInputDevicesOnce();
	__glutMatchHIDPrefsToDevices();
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	GLUTAPI_BEGIN
	[__glutCurrentView	setSpaceballMotionCallback: func];
	GLUTAPI_END
}

void APIENTRY glutSpaceballRotateFunc(void (*func)(int x, int y, int z))
{
	GLUTAPI_DECLARATIONS
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	GLUTAPI_BEGIN
	[__glutCurrentView	setSpaceballRotateCallback: func];
	GLUTAPI_END
}

void APIENTRY glutSpaceballButtonFunc(void (*func)(int button, int state))
{
 	GLUTAPI_DECLARATIONS
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	GLUTAPI_BEGIN
	[__glutCurrentView	setSpaceballButtonCallback: func];
	GLUTAPI_END
}
/* ENDCENTRY */

short __glutGetSpaceballNumButtons (void)
{
	short i, num = 0;
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	for (i = kSBActionButton1; i < kNumSpaceballActions; i++) // for all buttons
		if (__glutSBInputActionArray [i].pDevice != NULL) // if the device exists
			num++; // count
	return num;
}   

short __glutGetSpaceballNumAxis (void)
{
	short i, num = 0;
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	for (i = 0; i < kSBActionButton1; i++) // for all axis
		if (__glutSBInputActionArray [i].pDevice != NULL) // if the device exists
			num++; // count
	return num;
}   

struct _GLUTinputActionRec * __glutGetSpaceballDeviceElement (short inputNum)
{
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	return &__glutSBInputActionArray [inputNum];
}   

// check for attached devices (changes, reset globals if required for missing devices)
void __glutClearMissingDeviceSpaceballInput (void) 
{
	short i;
	if (!__glutSpaceballList)
		return;
	// assumes the list is updated
	for (i = 0; i < kNumSpaceballActions; i++) {
		if (!__glutIsInputDeviceConnected(__glutSBInputActionArray[i].pDevice)) { // if we did not find the device
			__glutSBInputActionArray [i].pElement = NULL;
			__glutSBInputActionArray [i].pDevice = NULL;
			__glutSBInputActionArray [i].invertMul = 1; // not inverted
			__glutSBInputActionArray [i].value = 0;
		}
	}
}

void __glutFillEmptySpaceballInput (pRecDevice pDevice)
{
	short i;
   GLUTDeviceEnumerator	enumer;
	pRecDevice pSelDevice = NULL;
	pRecElement pElement = NULL;
	short selButtonCount = 0, selAxisCount = 0, currButton = 0;
   
   if (NULL == pDevice) { // no preferred device
		__glutGetInputDeviceEnumeratorOfClass(GLUT_SPACEBALL_DEVICE, &enumer);
		while((pDevice = __glutGetNextInputDevice(&enumer)) != NULL) { // while we have valid devices
			bool deviceSelect = NO;
			if (pDevice->axis >= 6) { // if device has at least 3 axis
				if ((selAxisCount < 6) || // previous device has less than 3 axis (select this device)
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

	__glutSpaceballList = true; // set only if we found devices we like
   
	// prefer correct elements, then try any
	// look for x axis	
	if (NULL == __glutSBInputActionArray [kSBActionXAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X == pElement->usage)) { // if it is the x axis
				__glutSBInputActionArray [kSBActionXAxis].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionXAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for y axis
	if (NULL == __glutSBInputActionArray [kSBActionYAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Y == pElement->usage)) { // if it is the y axis
				__glutSBInputActionArray [kSBActionYAxis].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionYAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for z axis
	if (NULL == __glutSBInputActionArray [kSBActionZAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Z == pElement->usage)) { // if it is the y axis
				__glutSBInputActionArray [kSBActionZAxis].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionZAxis].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for x rotation
	if (NULL == __glutSBInputActionArray [kSBActionXRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Rx == pElement->usage)) { // if it is the y axis
				__glutSBInputActionArray [kSBActionXRotation].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionXRotation].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for y rotation
	if (NULL == __glutSBInputActionArray [kSBActionYRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Ry == pElement->usage)) { // if it is the y axis
				__glutSBInputActionArray [kSBActionYRotation].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionYRotation].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	// look for z rotation
	if (NULL == __glutSBInputActionArray [kSBActionZRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_Rz == pElement->usage)) { // if it is the y axis
				__glutSBInputActionArray [kSBActionZRotation].pDevice = pDevice;
				__glutSBInputActionArray [kSBActionZRotation].pElement = pElement;
				// reset user min and max
				pElement->minReport = 0;
				pElement->maxReport = 0;
				break;
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}

	// for any not filled axis find any avialable (that is not already used)
	if (NULL == __glutSBInputActionArray [kSBActionXAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionXAxis].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionXAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutSBInputActionArray [kSBActionYAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionYAxis].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionYAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutSBInputActionArray [kSBActionZAxis].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionZAxis].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionZAxis].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutSBInputActionArray [kSBActionXRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionZRotation].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionZRotation].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutSBInputActionArray [kSBActionYRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionZRotation].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionZRotation].pElement = pElement;
					// reset user min and max
					pElement->minReport = 0;
					pElement->maxReport = 0;
					break;
				}
			}
			pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
		}
	}
	if (NULL == __glutSBInputActionArray [kSBActionZRotation].pElement) { // if axis is empty
		pElement = HIDGetFirstDeviceElement (pDevice, kHIDElementTypeIO); // get first element
		while (pElement) { // for each element
			if  ((kIOHIDElementTypeInput_Axis == pElement->type) || // if it is an axis or
				 ((kHIDPage_GenericDesktop == pElement->usagePage) && (kHIDUsage_GD_X <= pElement->usage) && (kHIDUsage_GD_Wheel >= pElement->usage))) { // it is an axis type usage
				if ((pElement != __glutSBInputActionArray [kSBActionXAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZAxis].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionXRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionYRotation].pElement) &&
				    (pElement != __glutSBInputActionArray [kSBActionZRotation].pElement)) { // not already used
					__glutSBInputActionArray [kSBActionZRotation].pDevice = pDevice;
					__glutSBInputActionArray [kSBActionZRotation].pElement = pElement;
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
			for (a = kSBActionButton1; a < kNumSpaceballActions; a++) // check all buttons
				if (__glutSBInputActionArray [a].pElement == pElement) // is element used already
					found = true; // mark as such
			if (!found) { // if not used already
				while (NULL != __glutSBInputActionArray [kSBActionButton1 + currButton].pElement) // find first empty button
					currButton++; // advance until empty one since we can have a sparse array
				__glutSBInputActionArray [kSBActionButton1 + currButton].pDevice = pDevice; // assign button
				__glutSBInputActionArray [kSBActionButton1 + currButton].pElement = pElement;
			}
		}
		pElement = HIDGetNextDeviceElement (pElement, kHIDElementTypeIO); // get next element
	}

	// set device limits
	for (i = 0; i < kNumSpaceballActions; i++)
	{
		if (__glutSBInputActionArray [i].pElement) {
			if (i < kSBActionXRotation) { // translations
				(__glutSBInputActionArray [i].pElement)->userMin = -1000;
				(__glutSBInputActionArray [i].pElement)->userMax = 1000;
			} else if (i < kSBActionButton1) { // rotations
				(__glutSBInputActionArray [i].pElement)->userMin = -1800;
				(__glutSBInputActionArray [i].pElement)->userMax = 1800;
			} else { // buttons
				(__glutSBInputActionArray [i].pElement)->userMin = 0;
				(__glutSBInputActionArray [i].pElement)->userMax = 1;
			}
		}
	}
}

// assumes __glutCollectInputDevices already called
// check for atttached devices, set globals if required, enables/disblaes setup menu
void __glutInitSpaceballInput (pRecDevice pDevice)
{
	int i;
	// zero all actions
	__glutSpaceballList = false;
	for (i = 0; i < kNumSpaceballActions; i++) {
		__glutSBInputActionArray [i].pElement = NULL;
		__glutSBInputActionArray [i].pDevice = NULL;
		__glutSBInputActionArray [i].invertMul = 1; // not inverted
		__glutSBInputActionArray [i].value = 0;
	}
	// find device with max (up to three) axis
	if (HIDCountDevices()) {
		__glutFillEmptySpaceballInput (pDevice);
	}
}

// return the device of first assigned input which will be the same for all inputs
pRecDevice __glutGetSpaceballDevice (void)
{
	int i = 0;
	while ((NULL == __glutSBInputActionArray [i].pDevice) && (i < kNumSpaceballActions))
		i++;
	if (i < kNumSpaceballActions)
		return __glutSBInputActionArray [i].pDevice;
	else
		return NULL;
} 

// assumes __glutCollectInputDevices already called
// check for attached devices (changes, reset globals if required for missing devices)
// sets to device with at least 6 axis (or most if less) and most buttons is current device does not exist
void __glutUpdateSpaceballInput (void) 
{
	if (!__glutSpaceballList)
		__glutInitSpaceballInput (NULL);
	else {
		// check for device ensure inputs are clear if device is not present
		if (NULL != __glutGetSpaceballDevice()) // if we found a assigned input
			__glutClearMissingDeviceSpaceballInput (); // check to ensure device is attached
		if (NULL == __glutGetSpaceballDevice()) // if we cleared the input or if we found no assigned inputs
			__glutInitSpaceballInput (NULL); // init the list
	}
}

// returns current polled values of first gamepad or Spaceball found
void __glutGetSpaceballInput (int *pButtonMask, int *pX,  int *pY,  int *pZ, int *pRX,  int *pRY,  int *pRZ)
{
    short a;
	*pButtonMask = 0;
	if (!__glutSpaceballList) {
		*pX = 0;
		*pY = 0;
		*pZ = 0;
		*pRX = 0;
		*pRY = 0;
		*pRZ = 0;
		return;
	}
    for (a = 0; a < kNumSpaceballActions; a++)
    {
		__glutSBInputActionArray [a].value = 0;
		if (__glutSBInputActionArray [a].pDevice && __glutSBInputActionArray [a].pElement) { // handle device input
			__glutSBInputActionArray [a].value = HIDGetElementValue (__glutSBInputActionArray [a].pDevice, __glutSBInputActionArray [a].pElement);
			switch (a) {
				case kSBActionXAxis:
					*pX = __glutSBInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				case kSBActionYAxis:
					*pY = __glutSBInputActionArray [a].invertMul * 
					      HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//					      HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				case kSBActionZAxis:
					*pZ = __glutSBInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				case kSBActionXRotation:
					*pRX = __glutSBInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				case kSBActionYRotation:
					*pRY = __glutSBInputActionArray [a].invertMul * 
					      HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//					      HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				case kSBActionZRotation:
					*pRZ = __glutSBInputActionArray [a].invertMul * 
						  HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement);
//						  HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement);
					break;
				default:
					if (__glutSBInputActionArray [a].invertMul == 1)
//						*pButtonMask += HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement) << 
						*pButtonMask += HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement) << 
									    (a - kSBActionButton1);
					else
//						*pButtonMask += (1 - HIDScaleValue (HIDCalibrateValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement), __glutSBInputActionArray [a].pElement)) << 
						*pButtonMask += (1 - HIDScaleValue (__glutSBInputActionArray [a].value, __glutSBInputActionArray [a].pElement)) << 
									    (a - kSBActionButton1);
					break;
			}
		}
    }
// printf ("__glutGetSpaceballInput: BM:0x%X, x:%d, y:%d, z:%d, rx:%d, ry:%d, rz:%d\n", *pButtonMask, *pX, *pY, *pZ, *pRX, *pRY, *pRZ); 
}
