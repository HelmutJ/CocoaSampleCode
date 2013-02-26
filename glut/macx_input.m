
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"
#import <IOKit/hid/IOHIDLib.h>
#import <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>


static int	__glutNumMouseButtons = 0;
static BOOL	__glutHaveInputDevices = NO;


void __glutForgetInputDevices(void)
{
   // ensure HID stuff is torn down on app exit
	HIDReleaseDeviceList();
}

/**
 * Builds the global HID list. This list contains all input devices of the
 * following classes:
 *		Mouse
 *		Keyboard / Keypad
 *		Joystick / Gamepad
 * NOTE: This function must be called before any other HID related one.
 */
void __glutCollectInputDevices(void)
{
	UInt32	aUsage[5];
	UInt32	aUsagePage[5];

	// find all
	aUsagePage[0] = 0;
	aUsage[0] = 0;

	HIDUpdateDeviceList(aUsagePage, aUsage, 1); // will do the right thing the first time
}

// This function will set up the input devices only the first time it is called.
void __glutCollectInputDevicesOnce(void)
{
	if(!__glutHaveInputDevices) {
		__glutCollectInputDevices();
		__glutHaveInputDevices = YES;
	}
}

void __glutGetInputDeviceEnumeratorOfClass(int cl, GLUTDeviceEnumerator *enumer)
{
	__glutCollectInputDevicesOnce();

	enumer->typeDevice = cl; // will sort later
	enumer->curDevice = HIDGetFirstDevice();
	enumer->done = (enumer->curDevice == NULL);
}

pRecDevice __glutGetNextInputDevice(GLUTDeviceEnumerator *enumer)
{
	pRecDevice	dev = enumer->curDevice;
	UInt32		foundIt = NO;
	SInt32		usagePage[2], usage[2];
	SInt32		numTypes = 0, i;
	if(enumer->done)
		return NULL;
	
	// scan device list for next device matching the required
	// usage page and usage values
	while(dev) {
		switch (enumer->typeDevice) {
			case GLUT_MOUSE_DEVICE:
				// find pointing devices
				usagePage[0] = kHIDPage_GenericDesktop;
				usage[0] = kHIDUsage_GD_Mouse;
				numTypes = 1;
				break;
				
			case GLUT_KEYBOARD_DEVICE:
				// find keyboards and keypads
				usagePage[0] = kHIDPage_GenericDesktop;
				usage[0] = kHIDUsage_GD_Keyboard;
				usagePage[1] = kHIDPage_GenericDesktop;
				usage[1] = kHIDUsage_GD_Keypad;
				numTypes = 2;
				break;
				
			case GLUT_JOYSTICK_DEVICE: // ggs: fix me, find all two axis non-relative devices
				// find joysicks and gamepads
				usagePage[0] = kHIDPage_GenericDesktop;
				usage[0] = kHIDUsage_GD_Joystick;
				usagePage[1] = kHIDPage_GenericDesktop;
				usage[1] = kHIDUsage_GD_GamePad;
				numTypes = 2;
				break;
			case GLUT_SPACEBALL_DEVICE:// ggs: fix me, find all 6 axis x, y, z, rx, ry, rz devices
				numTypes = 0;
				break;
   
		}
		for(i = 0; i < numTypes; i++) {
			if((usagePage[i] == dev->usagePage) &&
			   (usage[i] == dev->usage)) {
			foundIt = YES;
			break;
			}
		}
		// additional check for joysticks
		if ((enumer->typeDevice == GLUT_JOYSTICK_DEVICE) && // look also for 2 axis, non-mouse axis devices
			!((kHIDPage_GenericDesktop == dev->usagePage) &&
			(kHIDUsage_GD_Mouse == dev->usage)) &&
			(2 <= dev->axis))
			foundIt = YES;
		// addtional check for spaceballs (note this is only thing that find spaceballs (since above numTypes is 0)
		if ((enumer->typeDevice == GLUT_SPACEBALL_DEVICE) && // look only for device with 6 axis or more
			(6 <= dev->axis))
			foundIt = YES;
		
		// have we found one of the required devices ?
		if(foundIt) {
			enumer->curDevice = HIDGetNextDevice(dev);
			enumer->done = (enumer->curDevice == NULL);
			return dev;
		}
		
		dev = HIDGetNextDevice(dev);
	}
	
	// haven't found any suitable device, though checked all devices
	enumer->done = YES;
	enumer->curDevice = NULL;
	return NULL;
}

BOOL __glutIsInputDeviceConnected(pRecDevice device)
{
   pRecDevice pDevice = HIDGetFirstDevice(); // get the first device

   while(pDevice) {
      if(device == pDevice)
         return YES;
      
      pDevice = HIDGetNextDevice(pDevice); // check next device
   }
   return NO;
}

void HIDReportError (char * strError);
void HIDReportErrorNum (char * strError, int numError);

int GetHighestMouseButtonCount ()
{
	int highestButtonCount;
	IOReturn result = kIOReturnSuccess;
	mach_port_t masterPort = 0;
	CFMutableDictionaryRef hiPointingDictionary = NULL;
	io_iterator_t hidObjectIterator = 0;
	io_object_t ioHIDDeviceObject = 0;
	highestButtonCount = 0;

	if (kIOReturnSuccess != IOMasterPort (bootstrap_port, &masterPort))
		HIDReportError ("HIDCreateMultiTypeDeviceList: IOMasterPort error with bootstrap_port.");
	else
	{
		hiPointingDictionary = IOServiceMatching ("IOHIPointing");
		result = IOServiceGetMatchingServices (masterPort, hiPointingDictionary, &hidObjectIterator);

		if (0 != hidObjectIterator) 
		{
			while ((ioHIDDeviceObject = IOIteratorNext (hidObjectIterator)))
			{
				int currDeviceButtonCount;
				
				CFTypeRef property = IORegistryEntryCreateCFProperty (ioHIDDeviceObject, CFSTR(kIOHIDPointerButtonCountKey), kCFAllocatorDefault, kNilOptions);
				if (NULL != property)
				{
					CFNumberGetValue(property, kCFNumberIntType, &currDeviceButtonCount);
					CFRelease(property);
				
					if (currDeviceButtonCount > highestButtonCount)
						highestButtonCount = currDeviceButtonCount;
				}
				
				// dump device object, it is no longer needed
				result = IOObjectRelease (ioHIDDeviceObject);
				if (KERN_SUCCESS != result)
					HIDReportErrorNum ("IOObjectRelease error with ioHIDDeviceObject.", result);
			}
			result = IOObjectRelease (hidObjectIterator); // release the iterator
			if (kIOReturnSuccess != result) 
				HIDReportErrorNum ("IOObjectRelease error with hidObjectIterator.", result);
		}
	}
	
	return highestButtonCount;
}

int __glutGetNumberOfMouseButtons(void)
{
	__glutNumMouseButtons = GetHighestMouseButtonCount();
   
	if(__glutNumMouseButtons == 0) {
		// some pointer devices i.e. some touchpads shipped with laptops don't
		// have a button count property and can return 0 so return 1 in that case
		__glutNumMouseButtons = 1;
	}

	return __glutNumMouseButtons;
}


  /* CENTRY */
  int APIENTRY glutDeviceGet(GLenum param)
  {
    int	ival = 0;
    GLUTAPI_DECLARATIONS
    
    GLUTAPI_BEGIN
  	switch(param) {
  		case GLUT_HAS_KEYBOARD:
  		case GLUT_HAS_MOUSE:
 			ival = 1;
          break;
  		case GLUT_HAS_JOYSTICK:
  			if (__glutGetJoystickNumButtons() || (__glutGetJoystickNumAxis() >= 2)) // if we have buttons or axis
 				ival = 1;
          break;
  		case GLUT_NUM_MOUSE_BUTTONS:
 				ival = __glutGetNumberOfMouseButtons();
             break;
  		case GLUT_HAS_SPACEBALL:
  			if (__glutGetSpaceballNumButtons() || (__glutGetSpaceballNumAxis() == 6)) // if we have buttons or 
 				ival = 1;
          break;
		case GLUT_NUM_SPACEBALL_BUTTONS:
  			ival = __glutGetSpaceballNumButtons();
          break;
  		case GLUT_HAS_DIAL_AND_BUTTON_BOX:
  		case GLUT_HAS_TABLET:
  		case GLUT_NUM_BUTTON_BOX_BUTTONS:
  		case GLUT_NUM_DIALS:
  		case GLUT_NUM_TABLET_BUTTONS:
 			ival =  0;
          break;
  		case GLUT_JOYSTICK_BUTTONS:
 			ival = __glutGetJoystickNumButtons ();
          break;
  		case GLUT_JOYSTICK_AXES:
 			ival = __glutGetJoystickNumAxis ();
          break;
  		case GLUT_DEVICE_IGNORE_KEY_REPEAT:
 			ival = [__glutCurrentView ignoreKeyRepeats];
          break;
  		case GLUT_DEVICE_KEY_REPEAT:
         ival = __glutGetDeviceKeyRepeat();
          break;
  		case GLUT_JOYSTICK_POLL_RATE:
 			ival = (int)([__glutCurrentView joystickPollInterval] * 1000.0);
          break;
  		default:
  			__glutWarning("invalid glutDeviceGet parameter: %d", param);
 			ival = -1;
          break;
  	}
    GLUTAPI_END
    
    return ival;
  }
  /* ENDCENTRY */
