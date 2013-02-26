/* This program is freely distributable without licensing fees
   and is provided without guarantee or warrantee expressed or
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTPreferencesController.h"

// preferences dictionary keys
NSString *GLUTUseMacOSXCoordsKey = @"GLUTUseMacOSXCoordsKey";
NSString *GLUTUseCurrWDKey = @"GLUTUseCurrWDKey";
NSString *GLUTUseExtendedDesktopKey = @"GLUTUseExtendedDesktopKey";
NSString *GLUTIconicKey = @"GLUTIconicKey";
NSString *GLUTDebugModeKey = @"GLUTDebugModeKey";
NSString *GLUTInitWidthKey = @"GLUTInitWidthKey";
NSString *GLUTInitHeightKey = @"GLUTInitHeightKey";
NSString *GLUTInitXKey = @"GLUTInitXKey";
NSString *GLUTInitYKey = @"GLUTInitYKey";
NSString *GLUTIdleTimeIntervalKey = @"GLUTIdleTimeIntervalKey";
NSString *GLUTGameModeFadeIntervalKey = @"GLUTGameModeFadeIntervalKey";
NSString *GLUTGamemodeCaptureSingleKey = @"GLUTGamemodeCaptureSingleKey";
NSString *GLUTSyncToVBLKey = @"GLUTSyncToVBLKey";
NSString *GLUTEmulateMouseButtonsKey = @"GLUTEmulateMouseButtonsKey";
NSString *GLUTMouseFirstModifiersKey = @"GLUTMouseFirstModifiersKey";
NSString *GLUTMouseSecondModifiersKey = @"GLUTMouseSecondModifiersKey";
NSString *GLUTDeviceActionKey = @"GLUTDeviceActionKey";
NSString *GLUTDeviceVendorIDKey = @"GLUTDeviceVendorIDKey";
NSString *GLUTDeviceProductIDKey = @"GLUTDeviceProductIDKey";
NSString *GLUTDeviceLocIDKey = @"GLUTDeviceLocIDKey";
NSString *GLUTDeviceUsageKey = @"GLUTDeviceUsageKey";
NSString *GLUTDeviceUsagePageKey = @"GLUTDeviceUsagePageKey";
NSString *GLUTDeviceUsageEKey = @"GLUTDeviceUsageEKey";
NSString *GLUTDeviceUsagePageEKey = @"GLUTDeviceUsagePageEKey";
NSString *GLUTDeviceCookieKey = @"GLUTDeviceCookieKey";
NSString *GLUTDeviceMinReportKey = @"GLUTDeviceMinReportKey";
NSString *GLUTDeviceMaxReportKey = @"GLUTDeviceMaxReportKey";
NSString *GLUTDeviceInvertMulKey = @"GLUTDeviceInvertMulKey";
NSString *GLUTJoystickDeviceKey = @"GLUTJoystickDeviceKey";
NSString *GLUTSpaceballDeviceKey = @"GLUTSpaceballDeviceKey";
NSString *GLUTPreferencesName = @"com.apple.glut";

enum {
   kGLUTAlternateTag,
   kGLUTControlTag,
   kGLUTShiftTag,
   kGLUTCommandTag
};


NSDictionary *	defaults;
int hidDevicesMatchedFlag = 0;

// utility routine to load prefs at start
void __glutLoadPrefs (void)
{
	 defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName: GLUTPreferencesName];
	 
	 [defaults retain];
	
	// set values and re-init (ensure to check to see if keyed object exists)
	if ([defaults objectForKey: GLUTUseMacOSXCoordsKey])
		__glutUseMacOSCoords = [[defaults objectForKey: GLUTUseMacOSXCoordsKey] boolValue];
	if ([defaults objectForKey: GLUTUseCurrWDKey])
		__glutUseInitWD = [[defaults objectForKey: GLUTUseCurrWDKey] boolValue];
	if ([defaults objectForKey: GLUTUseExtendedDesktopKey])
		__glutUseExtendedDesktop = [[defaults objectForKey: GLUTUseExtendedDesktopKey] boolValue];
	if ([defaults objectForKey: GLUTIconicKey])
		__glutIconic = [[defaults objectForKey: GLUTIconicKey] boolValue];
	if ([defaults objectForKey: GLUTDebugModeKey])
		__glutDebug = [[defaults objectForKey: GLUTDebugModeKey] boolValue];
	if ([defaults objectForKey: GLUTInitWidthKey])
		__glutInitWidth = [[defaults objectForKey: GLUTInitWidthKey] intValue];
	if ([defaults objectForKey: GLUTInitHeightKey])
		__glutInitHeight = [[defaults objectForKey: GLUTInitHeightKey] intValue];
	if ([defaults objectForKey: GLUTInitXKey])
		__glutInitX = [[defaults objectForKey: GLUTInitXKey] intValue];
	if ([defaults objectForKey: GLUTInitYKey])
		__glutInitY = [[defaults objectForKey: GLUTInitYKey] intValue];
	if ([defaults objectForKey: GLUTIdleTimeIntervalKey])
		__glutIdleTimeInterval = [[defaults objectForKey: GLUTIdleTimeIntervalKey] floatValue];
	if ([defaults objectForKey: GLUTGameModeFadeIntervalKey])
		__glutGameModeFadeInterval = [[defaults objectForKey: GLUTGameModeFadeIntervalKey] floatValue];
	if ([defaults objectForKey: GLUTGamemodeCaptureSingleKey])
		__glutCaptureAllDisplays = 1 - [[defaults objectForKey: GLUTGamemodeCaptureSingleKey] boolValue];
	if ([defaults objectForKey: GLUTSyncToVBLKey])
		__glutSyncToVBL = [[defaults objectForKey: GLUTSyncToVBLKey] boolValue];
	
	if ([defaults objectForKey: GLUTEmulateMouseButtonsKey])
		__glutEmulateMouseButtons = [[defaults objectForKey: GLUTEmulateMouseButtonsKey] boolValue];
	if ([defaults objectForKey: GLUTMouseFirstModifiersKey])
		__glutMouseFirstModifiers = [[defaults objectForKey: GLUTMouseFirstModifiersKey] intValue];
	if ([defaults objectForKey: GLUTMouseSecondModifiersKey])
		__glutMouseSecondModifiers = [[defaults objectForKey: GLUTMouseSecondModifiersKey] intValue];
}


// This function looks for the devices specified in the preferences file.  If it finds them, it uses them,
// otherwise those preferences are ignored, but not deleted.

void __glutMatchHIDPrefsToDevices (void)
{
	if (hidDevicesMatchedFlag == 1)
	{
		return;
	}
	
	hidDevicesMatchedFlag = 1;
	
	// read pref array
	// note: this modifies glut settings directly (we do not dup settings for cancel for joystick and spaceball yet.
	if ([defaults objectForKey: GLUTJoystickDeviceKey]) {
		id actionDict = nil;
		pRecDevice pFirstDevice = NULL;
		NSEnumerator * enumer = [[defaults objectForKey: GLUTJoystickDeviceKey] objectEnumerator];
		// while array entries
		while (nil != (actionDict = [enumer nextObject])) {
			pRecElement pElement = NULL;
			pRecDevice pDevice = NULL;
			int action = 0;
			recSaveHID configRec;
			
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.actionCookie = [[actionDict objectForKey: GLUTDeviceActionKey] longValue];
			else 
				configRec.actionCookie = 0;
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.vendorID = [[actionDict objectForKey: GLUTDeviceVendorIDKey] longValue];
			else 
				configRec.vendorID = 0;
			if ([actionDict objectForKey: GLUTDeviceProductIDKey])
				configRec.productID = [[actionDict objectForKey: GLUTDeviceProductIDKey] longValue];
			else 
				configRec.productID = 0;
			if ([actionDict objectForKey: GLUTDeviceLocIDKey])
				configRec.locID = [[actionDict objectForKey: GLUTDeviceLocIDKey] longValue];
			else 
				configRec.locID = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageKey])
				configRec.usage = [[actionDict objectForKey: GLUTDeviceUsageKey] longValue];
			else 
				configRec.usage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageKey])
				configRec.usagePage = [[actionDict objectForKey: GLUTDeviceUsagePageKey] longValue];
			else 
				configRec.usagePage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageEKey])
				configRec.usageE = [[actionDict objectForKey: GLUTDeviceUsageEKey] longValue];
			else 
				configRec.usageE = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageEKey])
				configRec.usagePageE = [[actionDict objectForKey: GLUTDeviceUsagePageEKey] longValue];
			else 
				configRec.usagePageE = 0;
			if ([actionDict objectForKey: GLUTDeviceMinReportKey])
				configRec.minReport = [[actionDict objectForKey: GLUTDeviceMinReportKey] longValue];
			else 
				configRec.minReport = 0;
			if ([actionDict objectForKey: GLUTDeviceMaxReportKey])
				configRec.maxReport = [[actionDict objectForKey: GLUTDeviceMaxReportKey] longValue];
			else 
				configRec.maxReport = 0;
			if ([actionDict objectForKey: GLUTDeviceCookieKey])
				configRec.cookie = (IOHIDElementCookie)[[actionDict objectForKey: GLUTDeviceCookieKey] unsignedLongValue];
			else 
				configRec.cookie = 0;

			// find device and element for configRec and find controlling action
			action = HIDGetElementConfig (&configRec, &pDevice, &pElement);
			struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement (action);
			if (NULL == pFirstDevice)
				pFirstDevice = pDevice;
			if (pDevice && pElement && (pFirstDevice == pDevice)) { // valid device and element  and we match the same device
				// fill information in
				inputARec->pDevice = pDevice;
				inputARec->pElement = pElement;
				if ([actionDict objectForKey: GLUTDeviceInvertMulKey])
					inputARec->invertMul = [[actionDict objectForKey: GLUTDeviceInvertMulKey] longValue];
				else 
					inputARec->invertMul = 1;
			} else { // device for action not found so blank current device
				inputARec->pDevice = NULL;
				inputARec->pElement = NULL;
				inputARec->invertMul = 1;
			}
		}
	}
	if ([defaults objectForKey: GLUTSpaceballDeviceKey]) {
		id actionDict = nil;
		pRecDevice pFirstDevice = NULL;
		NSEnumerator * enumer = [[defaults objectForKey: GLUTSpaceballDeviceKey] objectEnumerator];
		// while array entries
		while (nil != (actionDict = [enumer nextObject])) {
			pRecElement pElement = NULL;
			pRecDevice pDevice = NULL;
			int action = 0;
			recSaveHID configRec;
			
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.actionCookie = [[actionDict objectForKey: GLUTDeviceActionKey] longValue];
			else 
				configRec.actionCookie = 0;
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.vendorID = [[actionDict objectForKey: GLUTDeviceVendorIDKey] longValue];
			else 
				configRec.vendorID = 0;
			if ([actionDict objectForKey: GLUTDeviceProductIDKey])
				configRec.productID = [[actionDict objectForKey: GLUTDeviceProductIDKey] longValue];
			else 
				configRec.productID = 0;
			if ([actionDict objectForKey: GLUTDeviceLocIDKey])
				configRec.locID = [[actionDict objectForKey: GLUTDeviceLocIDKey] longValue];
			else 
				configRec.locID = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageKey])
				configRec.usage = [[actionDict objectForKey: GLUTDeviceUsageKey] longValue];
			else 
				configRec.usage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageKey])
				configRec.usagePage = [[actionDict objectForKey: GLUTDeviceUsagePageKey] longValue];
			else 
				configRec.usagePage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageEKey])
				configRec.usageE = [[actionDict objectForKey: GLUTDeviceUsageEKey] longValue];
			else 
				configRec.usageE = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageEKey])
				configRec.usagePageE = [[actionDict objectForKey: GLUTDeviceUsagePageEKey] longValue];
			else 
				configRec.usagePageE = 0;
			if ([actionDict objectForKey: GLUTDeviceMinReportKey])
				configRec.minReport = [[actionDict objectForKey: GLUTDeviceMinReportKey] longValue];
			else 
				configRec.minReport = 0;
			if ([actionDict objectForKey: GLUTDeviceMaxReportKey])
				configRec.maxReport = [[actionDict objectForKey: GLUTDeviceMaxReportKey] longValue];
			else 
				configRec.maxReport = 0;
			if ([actionDict objectForKey: GLUTDeviceCookieKey])
				configRec.cookie = (IOHIDElementCookie)[[actionDict objectForKey: GLUTDeviceCookieKey] unsignedLongValue];
			else 
				configRec.cookie = 0;

			// find device and element for configRec and find controling action
			action = HIDGetElementConfig (&configRec, &pDevice, &pElement);
			struct _GLUTinputActionRec * inputARec = __glutGetSpaceballDeviceElement (action); // get pointer to record
			if (NULL == pFirstDevice)
				pFirstDevice = pDevice;
			if (pDevice && pElement && (pFirstDevice == pDevice)) { // valid device and element  and we match the same device
				// fill information in
				inputARec->pDevice = pDevice;
				inputARec->pElement = pElement;
				if ([actionDict objectForKey: GLUTDeviceInvertMulKey])
					inputARec->invertMul = [[actionDict objectForKey: GLUTDeviceInvertMulKey] longValue];
				else 
					inputARec->invertMul = 1;
			} else { // device for action not found so blank current device
				inputARec->pDevice = NULL;
				inputARec->pElement = NULL;
				inputARec->invertMul = 1;
			}
		}
	}
	
	// we have done our matching, and no longer need the prefs dictionary
	[defaults release];
	
	// do not save prefs here so if a device is missing and on a later run returned their saved prefs are not hosed...
}

@interface GLUTPreferencesController(GLUTPrivate)
- (void)updateLaunchUI:(NSDictionary *)defaults;
- (void)updateDevicesUI:(NSDictionary *)defaults;
- (void)updateUI:(NSDictionary *)defaults;
        
- (void)updateObjectState;
- (void)updateLaunchState;
- (void)updateMouseState;
- (int) modifierToIndex:(unsigned int)modifier; // converts a key modifier to the index of the menu item
- (unsigned int) indexToModifier:(int)index; // does the opposite

- (void)updateDevicesThread:(id)object;
- (void)waitForDevicesThread;
@end


/////////////////////////////////////////////
#pragma mark -


@implementation GLUTPreferencesController

- (id)init
{
	if((self = [self initWithWindowNibName: @"GLUTPreferences"]) != nil) {
		[self setWindowFrameAutosaveName: @""];
		[self setShouldCascadeWindows: NO];
		updatingDevices = NO;
		return self;
	}
	return nil;
}

- (void)dealloc
{
   [self waitForDevicesThread];
   [mouseAssignWarningIcon release];
   [joyAssignWarningIcon release];
   [spaceAssignWarningIcon release];
   [super dealloc];
}

- (void)finalize
{
   [self waitForDevicesThread];
   [super finalize];
}

- (void)windowDidLoad
{
	NSImage *	cautionIcon;
	NSString *	path;

	[[self window] center];
	[super windowDidLoad];

	// fix for default button
	NSEnumerator * enumer = [[[[self window] contentView] subviews] objectEnumerator];
	id object = nil;
	while (nil != (object = [enumer nextObject]))
		if (([object isKindOfClass:[NSButton class]]) &&
			([[object title] isEqual:@"Set Defaults"])) {
			[object setAction: @selector(setDefault:)];
			[object setTarget: self];
		}

	// launch
	[launchUseMacOSXCoords setState: __glutUseMacOSCoords];
	[launchUseCurrWD setState: __glutUseInitWD];
	[launchUseExtendedDesktop setState: __glutUseExtendedDesktop];
	[launchIconic setState: __glutIconic];
	[launchDebugMode setState: __glutDebug];
	[launchInitWidth setIntValue: __glutInitWidth];
	[launchInitHeight setIntValue: __glutInitHeight];
	[launchInitX setIntValue: __glutInitX];
	[launchInitY setIntValue: __glutInitY];
	[launchMenuIdle setFloatValue: __glutIdleTimeInterval];
	[launchFadeTime setFloatValue: __glutGameModeFadeInterval];
	[launchGamemodeCaptureSingle setState: (1 - __glutCaptureAllDisplays)];
	[launchSyncToVBL setState: __glutSyncToVBL];
	
	/* Mouse */
	[mouseDetected setStringValue:[NSString stringWithFormat:@"%d %@", __glutGetNumberOfMouseButtons(),
								   NSLocalizedStringFromTableInBundle(@" button mouse detected.", @"GLUTUI", __glutGetFrameworkBundle(), @" button mouse detected.")]];
	[mouseAssignWarningText setStringValue: @""];
	[mouseEmulation setState: __glutEmulateMouseButtons];
	[mouseRightConfigMenu selectItemAtIndex:[self modifierToIndex:__glutMouseFirstModifiers]];
	[mouseMiddleConfigMenu selectItemAtIndex:[self modifierToIndex:__glutMouseSecondModifiers]];
	
	
	/* Joystick */
	// joyInputMenu will be left as it is in the nib
	struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement ([joyInputMenu indexOfSelectedItem]);
	[joyInverted setState:inputARec->invertMul];
	if (inputARec->pElement && inputARec->pElement->name)
		[joyElement setStringValue:[NSString stringWithFormat:@"%s", inputARec->pElement->name]];
	else
		[joyElement setStringValue:NSLocalizedStringFromTableInBundle(@"Not assigned.", @"GLUTUI", __glutGetFrameworkBundle(), @"Not assigned.")];
	[joyAssignNote setStringValue: @""];
	
	/* Spaceball */
	// spaceInputMenu will be left as it is in the nib
	inputARec = __glutGetSpaceballDeviceElement ([joyInputMenu indexOfSelectedItem]);
	[spaceInverted setState:inputARec->invertMul];
	if (inputARec->pElement && inputARec->pElement->name)
		[spaceElement setStringValue:[NSString stringWithFormat:@"%s", inputARec->pElement->name]];
	else
		[spaceElement setStringValue:NSLocalizedStringFromTableInBundle(@"Not assigned.", @"GLUTUI", __glutGetFrameworkBundle(), @"Not assigned.")];
	[spaceAssignNote setStringValue: @""];
	
	mouseTabItemView = [mouseAssignWarningIcon superview];
	joyTabItemView = [joyAssignWarningIcon superview];
	spaceTabItemView = [spaceAssignWarningIcon superview];
	path = [__glutGetFrameworkBundle() pathForImageResource: @"Caution.tiff"];
	cautionIcon = [[[NSImage alloc] initWithContentsOfFile: path] autorelease];
	[mouseAssignWarningIcon setImage: cautionIcon];
	[mouseAssignWarningIcon retain];
	[mouseAssignWarningIcon removeFromSuperview];
	[joyAssignWarningIcon setImage: cautionIcon];
	[joyAssignWarningIcon retain];
	[joyAssignWarningIcon removeFromSuperview];
	[spaceAssignWarningIcon setImage: cautionIcon];
	[spaceAssignWarningIcon retain];
	[spaceAssignWarningIcon removeFromSuperview];
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	// Make sure that the threads are synced up before switching off first tab
	if([tabView indexOfTabViewItem:tabViewItem] > 0)
		[self waitForDevicesThread];

	[self joyElement:self];
	[self spaceElement:self];
	[self mouseEanbleEmulation:self]; // update display
}


- (IBAction)setDefault:(id)sender
{
   [self waitForDevicesThread];
   NSDictionary * prefsDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithBool: kUseMacOSCoords], GLUTUseMacOSXCoordsKey,
                     [NSNumber numberWithBool: kUseInitWD], GLUTUseCurrWDKey,
                     [NSNumber numberWithBool: kUseExtendedDesktop], GLUTUseExtendedDesktopKey,
                     [NSNumber numberWithBool: kIconic], GLUTIconicKey,
                     [NSNumber numberWithBool: kDebug], GLUTDebugModeKey,
                     [NSNumber numberWithInt: kInitWidth], GLUTInitWidthKey,
                     [NSNumber numberWithInt: kInitHeight], GLUTInitHeightKey,
                     [NSNumber numberWithInt: kInitX], GLUTInitXKey,
                     [NSNumber numberWithInt: kInitY], GLUTInitYKey,
                     [NSNumber numberWithFloat: GLUT_DEFAULT_IDLE_INTERVAL], GLUTIdleTimeIntervalKey,
                     [NSNumber numberWithFloat: GLUT_DEFAULT_FADE_INTERVAL], GLUTGameModeFadeIntervalKey,
                     [NSNumber numberWithBool: (1 - kCaptureAllDisplays)], GLUTGamemodeCaptureSingleKey,
                     [NSNumber numberWithBool: kSyncToVBL], GLUTSyncToVBLKey,
                     [NSNumber numberWithBool: kEmulateMouseButtons], GLUTEmulateMouseButtonsKey,
                     [NSNumber numberWithInt: kMouseFirstModifiers], GLUTMouseFirstModifiersKey,
                     [NSNumber numberWithInt: kMouseSecondModifiers], GLUTMouseSecondModifiersKey,
                     nil];

	// no joystick or spaceball defaults
	__glutInitJoystickInput(NULL); // reset to default
	__glutInitSpaceballInput(NULL);
	[self updateUI:prefsDefaults];
}

- (IBAction)showWindow:(id)sender
{
   (void) [self window];	// make sure that the window is loaded

#if GLUT_DEFER_PREFS_DEVICE_QUERY
	// Select the first tab (launch tab) each time the prefs window is opened.
	// This allows for the device information to be gathered via a seperate thread.
	[prefsTabView selectTabViewItemAtIndex:0];
#endif
	[self updateLaunchUI:[[NSUserDefaults standardUserDefaults] persistentDomainForName: GLUTPreferencesName]];

	// update HID list on every show
	if( !updatingDevices )
	{
		updatingDevices = YES;
		[NSThread detachNewThreadSelector:@selector(updateDevicesThread:)
				  toTarget:self withObject:nil];
	}

#if !GLUT_DEFER_PREFS_DEVICE_QUERY
	// We have to wait for this to finish when we can't guarantee
	// that the prefs tab opens up to the launch tab.
	[self waitForDevicesThread];
#endif

	[super showWindow:sender];
}

- (IBAction)ok:(id)sender
{
	int i;
	struct _GLUTinputActionRec * inputARec = NULL;
	recSaveHID configRec;

	[self waitForDevicesThread];

	NSMutableArray * JoyActionArray = [NSMutableArray arrayWithCapacity: kNumJoystickActions];
	NSMutableArray * SBActionArray = [NSMutableArray arrayWithCapacity: kNumSpaceballActions];

	NSMutableDictionary * prefsDefaults = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithBool: [launchUseMacOSXCoords state]], GLUTUseMacOSXCoordsKey,
                     [NSNumber numberWithBool: [launchUseCurrWD state]], GLUTUseCurrWDKey,
                     [NSNumber numberWithBool: [launchUseExtendedDesktop state]], GLUTUseExtendedDesktopKey,
                     [NSNumber numberWithBool: [launchIconic state]], GLUTIconicKey,
                     [NSNumber numberWithBool: [launchDebugMode state]], GLUTDebugModeKey,
                     [NSNumber numberWithInt: [launchInitWidth intValue]], GLUTInitWidthKey,
                     [NSNumber numberWithInt: [launchInitHeight intValue]], GLUTInitHeightKey,
                     [NSNumber numberWithInt: [launchInitX intValue]], GLUTInitXKey,
                     [NSNumber numberWithInt: [launchInitY intValue]], GLUTInitYKey,
                     [NSNumber numberWithFloat: [launchMenuIdle floatValue]], GLUTIdleTimeIntervalKey,
                     [NSNumber numberWithFloat: [launchFadeTime floatValue]], GLUTGameModeFadeIntervalKey,
                     [NSNumber numberWithBool: [launchGamemodeCaptureSingle state]], GLUTGamemodeCaptureSingleKey,
                     [NSNumber numberWithBool: [launchSyncToVBL state]], GLUTSyncToVBLKey,
                     [NSNumber numberWithBool: [mouseEmulation state]], GLUTEmulateMouseButtonsKey,
                     [NSNumber numberWithInt: [self indexToModifier:[mouseRightConfigMenu indexOfSelectedItem]]], GLUTMouseFirstModifiersKey,
                     [NSNumber numberWithInt: [self indexToModifier:[mouseMiddleConfigMenu indexOfSelectedItem]]], GLUTMouseSecondModifiersKey,
                     nil];

	for (i = 0; i < kNumJoystickActions; i++) {
		inputARec = __glutGetJoystickDeviceElement (i);
		HIDSetElementConfig (&configRec, inputARec->pDevice, inputARec->pElement, i);
		NSDictionary * deviceDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt: configRec.actionCookie], GLUTDeviceActionKey,
			[NSNumber numberWithInt: configRec.vendorID], GLUTDeviceVendorIDKey,
			[NSNumber numberWithInt: configRec.productID], GLUTDeviceProductIDKey,
			[NSNumber numberWithInt: configRec.locID], GLUTDeviceLocIDKey,
			[NSNumber numberWithInt: configRec.usage], GLUTDeviceUsageKey,
			[NSNumber numberWithInt: configRec.usagePage], GLUTDeviceUsagePageKey,
			[NSNumber numberWithInt: configRec.usageE], GLUTDeviceUsageEKey,
			[NSNumber numberWithInt: configRec.usagePageE], GLUTDeviceUsagePageEKey,
			[NSNumber numberWithInt: configRec.minReport], GLUTDeviceMinReportKey,
			[NSNumber numberWithInt: configRec.maxReport], GLUTDeviceMaxReportKey,
			[NSNumber numberWithUnsignedInt: (unsigned int)((long)configRec.cookie)], GLUTDeviceCookieKey,
			[NSNumber numberWithInt: inputARec->invertMul], GLUTDeviceInvertMulKey,
			nil];
		[JoyActionArray addObject:deviceDict];
	}
	[prefsDefaults setObject:JoyActionArray forKey:GLUTJoystickDeviceKey];
	
	for (i = 0; i < kNumSpaceballActions; i++) {
		inputARec = __glutGetSpaceballDeviceElement (i);
		HIDSetElementConfig (&configRec, inputARec->pDevice, inputARec->pElement, i);
		NSDictionary * deviceDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt: configRec.actionCookie], GLUTDeviceActionKey,
			[NSNumber numberWithInt: configRec.vendorID], GLUTDeviceVendorIDKey,
			[NSNumber numberWithInt: configRec.productID], GLUTDeviceProductIDKey,
			[NSNumber numberWithInt: configRec.locID], GLUTDeviceLocIDKey,
			[NSNumber numberWithInt: configRec.usage], GLUTDeviceUsageKey,
			[NSNumber numberWithInt: configRec.usagePage], GLUTDeviceUsagePageKey,
			[NSNumber numberWithInt: configRec.usageE], GLUTDeviceUsageEKey,
			[NSNumber numberWithInt: configRec.usagePageE], GLUTDeviceUsagePageEKey,
			[NSNumber numberWithUnsignedInt: configRec.minReport], GLUTDeviceMinReportKey,
			[NSNumber numberWithUnsignedInt: configRec.maxReport], GLUTDeviceMaxReportKey,
			[NSNumber numberWithUnsignedInt: (unsigned int)((long)configRec.cookie)], GLUTDeviceCookieKey,
			[NSNumber numberWithUnsignedInt: inputARec->invertMul], GLUTDeviceInvertMulKey,
			nil];
		[SBActionArray addObject:deviceDict];
	}
	[prefsDefaults setObject:SBActionArray forKey:GLUTSpaceballDeviceKey];
	
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: prefsDefaults forName: GLUTPreferencesName];

	[self updateObjectState]; // update all glut objects from window
	[super close];
}

- (IBAction)cancel:(id)sender
{
	[super close];
}

- (void)updateLaunchUI: (NSDictionary *)prefsDefaults
{
	if ([prefsDefaults objectForKey: GLUTUseMacOSXCoordsKey])
		[launchUseMacOSXCoords setState: [[prefsDefaults objectForKey: GLUTUseMacOSXCoordsKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTUseCurrWDKey])
		[launchUseCurrWD setState: [[prefsDefaults objectForKey: GLUTUseCurrWDKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTUseExtendedDesktopKey])
		[launchUseExtendedDesktop setState: [[prefsDefaults objectForKey: GLUTUseExtendedDesktopKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTIconicKey])
		[launchIconic setState: [[prefsDefaults objectForKey: GLUTIconicKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTDebugModeKey])
		[launchDebugMode setState: [[prefsDefaults objectForKey: GLUTDebugModeKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTInitWidthKey])
		[launchInitWidth setIntValue: [[prefsDefaults objectForKey: GLUTInitWidthKey] intValue]];
	if ([prefsDefaults objectForKey: GLUTInitHeightKey])
		[launchInitHeight setIntValue: [[prefsDefaults objectForKey: GLUTInitHeightKey] intValue]];
	if ([prefsDefaults objectForKey: GLUTInitXKey])
		[launchInitX setIntValue: [[prefsDefaults objectForKey: GLUTInitXKey] intValue]];
	if ([prefsDefaults objectForKey: GLUTInitYKey])
		[launchInitY setIntValue: [[prefsDefaults objectForKey: GLUTInitYKey] intValue]];
	if ([prefsDefaults objectForKey: GLUTIdleTimeIntervalKey])
		[launchMenuIdle setFloatValue: [[prefsDefaults objectForKey: GLUTIdleTimeIntervalKey] floatValue]];
	if ([prefsDefaults objectForKey: GLUTGameModeFadeIntervalKey])
		[launchFadeTime setFloatValue: [[prefsDefaults objectForKey: GLUTGameModeFadeIntervalKey] floatValue]];
	if ([prefsDefaults objectForKey: GLUTGamemodeCaptureSingleKey])
		[launchGamemodeCaptureSingle setState: [[prefsDefaults objectForKey: GLUTGamemodeCaptureSingleKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTSyncToVBLKey])
		[launchSyncToVBL setState: [[prefsDefaults objectForKey: GLUTSyncToVBLKey] boolValue]];

	// force view/control update
	[launchInitWidth setNeedsDisplay];
	[launchInitHeight setNeedsDisplay];
	[launchInitX setNeedsDisplay];
	[launchInitY setNeedsDisplay];
	[launchMenuIdle setNeedsDisplay];
	[launchFadeTime setNeedsDisplay];
}

- (void)updateDevicesUI: (NSDictionary *)prefsDefaults
{
	if ([prefsDefaults objectForKey: GLUTEmulateMouseButtonsKey])
		[mouseEmulation setState: [[prefsDefaults objectForKey: GLUTEmulateMouseButtonsKey] boolValue]];
	if ([prefsDefaults objectForKey: GLUTMouseFirstModifiersKey])
		[mouseRightConfigMenu selectItemAtIndex: [self modifierToIndex:[[prefsDefaults objectForKey: GLUTMouseFirstModifiersKey] intValue]]];
	if ([prefsDefaults objectForKey: GLUTMouseSecondModifiersKey])
		[mouseMiddleConfigMenu selectItemAtIndex: [self modifierToIndex:[[prefsDefaults objectForKey: GLUTMouseSecondModifiersKey] intValue]]];

	// read pref array
	// note: this modifies glut settings directly (we do not dup settings for cancel for joystick and spaceball yet.
	if ([prefsDefaults objectForKey: GLUTJoystickDeviceKey]) {
		id actionDict = nil;
		pRecDevice pFirstDevice = NULL;
		NSEnumerator * enumer = [[prefsDefaults objectForKey: GLUTJoystickDeviceKey] objectEnumerator];
		// while array entries
		while (nil != (actionDict = [enumer nextObject])) {
			pRecElement pElement = NULL;
			pRecDevice pDevice = NULL;
			int action = 0;
			recSaveHID configRec;
			
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.actionCookie = [[actionDict objectForKey: GLUTDeviceActionKey] longValue];
			else 
				configRec.actionCookie = 0;
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.vendorID = [[actionDict objectForKey: GLUTDeviceVendorIDKey] longValue];
			else 
				configRec.vendorID = 0;
			if ([actionDict objectForKey: GLUTDeviceProductIDKey])
				configRec.productID = [[actionDict objectForKey: GLUTDeviceProductIDKey] longValue];
			else 
				configRec.productID = 0;
			if ([actionDict objectForKey: GLUTDeviceLocIDKey])
				configRec.locID = [[actionDict objectForKey: GLUTDeviceLocIDKey] longValue];
			else 
				configRec.locID = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageKey])
				configRec.usage = [[actionDict objectForKey: GLUTDeviceUsageKey] longValue];
			else 
				configRec.usage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageKey])
				configRec.usagePage = [[actionDict objectForKey: GLUTDeviceUsagePageKey] longValue];
			else 
				configRec.usagePage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageEKey])
				configRec.usageE = [[actionDict objectForKey: GLUTDeviceUsageEKey] longValue];
			else 
				configRec.usageE = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageEKey])
				configRec.usagePageE = [[actionDict objectForKey: GLUTDeviceUsagePageEKey] longValue];
			else 
				configRec.usagePageE = 0;
			if ([actionDict objectForKey: GLUTDeviceMinReportKey])
				configRec.minReport = [[actionDict objectForKey: GLUTDeviceMinReportKey] longValue];
			else 
				configRec.minReport = 0;
			if ([actionDict objectForKey: GLUTDeviceMaxReportKey])
				configRec.maxReport = [[actionDict objectForKey: GLUTDeviceMaxReportKey] longValue];
			else 
				configRec.maxReport = 0;
			if ([actionDict objectForKey: GLUTDeviceCookieKey])
				configRec.cookie = (IOHIDElementCookie)[[actionDict objectForKey: GLUTDeviceCookieKey] unsignedLongValue];
			else 
				configRec.cookie = 0;

			// find device and element for configRec and find controling action
			action = HIDGetElementConfig (&configRec, &pDevice, &pElement);
			struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement (action);
			if (NULL == pFirstDevice)
				pFirstDevice = pDevice;
			if (pDevice && pElement && (pFirstDevice == pDevice)) { // valid device and element  and we match the same device
				// fill information in
				inputARec->pDevice = pDevice;
				inputARec->pElement = pElement;
				if ([actionDict objectForKey: GLUTDeviceInvertMulKey])
					inputARec->invertMul = [[actionDict objectForKey: GLUTDeviceInvertMulKey] longValue];
				else 
					inputARec->invertMul = 1;
			} else { // device for action not found so blank current device
				inputARec->pDevice = NULL;
				inputARec->pElement = NULL;
				inputARec->invertMul = 1;
			}
		}
	}
	if ([prefsDefaults objectForKey: GLUTSpaceballDeviceKey]) {
		id actionDict = nil;
		pRecDevice pFirstDevice = NULL;
		NSEnumerator * enumer = [[prefsDefaults objectForKey: GLUTSpaceballDeviceKey] objectEnumerator];
		// while array entries
		while (nil != (actionDict = [enumer nextObject])) {
			pRecElement pElement = NULL;
			pRecDevice pDevice = NULL;
			int action = 0;
			recSaveHID configRec;
			
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.actionCookie = [[actionDict objectForKey: GLUTDeviceActionKey] longValue];
			else 
				configRec.actionCookie = 0;
			if ([actionDict objectForKey: GLUTDeviceActionKey])
				configRec.vendorID = [[actionDict objectForKey: GLUTDeviceVendorIDKey] longValue];
			else 
				configRec.vendorID = 0;
			if ([actionDict objectForKey: GLUTDeviceProductIDKey])
				configRec.productID = [[actionDict objectForKey: GLUTDeviceProductIDKey] longValue];
			else 
				configRec.productID = 0;
			if ([actionDict objectForKey: GLUTDeviceLocIDKey])
				configRec.locID = [[actionDict objectForKey: GLUTDeviceLocIDKey] longValue];
			else 
				configRec.locID = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageKey])
				configRec.usage = [[actionDict objectForKey: GLUTDeviceUsageKey] longValue];
			else 
				configRec.usage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageKey])
				configRec.usagePage = [[actionDict objectForKey: GLUTDeviceUsagePageKey] longValue];
			else 
				configRec.usagePage = 0;
			if ([actionDict objectForKey: GLUTDeviceUsageEKey])
				configRec.usageE = [[actionDict objectForKey: GLUTDeviceUsageEKey] longValue];
			else 
				configRec.usageE = 0;
			if ([actionDict objectForKey: GLUTDeviceUsagePageEKey])
				configRec.usagePageE = [[actionDict objectForKey: GLUTDeviceUsagePageEKey] longValue];
			else 
				configRec.usagePageE = 0;
			if ([actionDict objectForKey: GLUTDeviceMinReportKey])
				configRec.minReport = [[actionDict objectForKey: GLUTDeviceMinReportKey] longValue];
			else 
				configRec.minReport = 0;
			if ([actionDict objectForKey: GLUTDeviceMaxReportKey])
				configRec.maxReport = [[actionDict objectForKey: GLUTDeviceMaxReportKey] longValue];
			else 
				configRec.maxReport = 0;
			if ([actionDict objectForKey: GLUTDeviceCookieKey])
				configRec.cookie = (IOHIDElementCookie)[[actionDict objectForKey: GLUTDeviceCookieKey] unsignedLongValue];
			else 
				configRec.cookie = 0;

			// find device and element for configRec and find controling action
			action = HIDGetElementConfig (&configRec, &pDevice, &pElement);
			struct _GLUTinputActionRec * inputARec = __glutGetSpaceballDeviceElement (action);
			if (NULL == pFirstDevice)
				pFirstDevice = pDevice;
			if (pDevice && pElement && (pFirstDevice == pDevice)) { // valid device and element  and we match the same device
				// fill information in
				inputARec->pDevice = pDevice;
				inputARec->pElement = pElement;
				if ([actionDict objectForKey: GLUTDeviceInvertMulKey])
					inputARec->invertMul = [[actionDict objectForKey: GLUTDeviceInvertMulKey] longValue];
				else 
					inputARec->invertMul = 1;
			} else { // device for action not found so blank current device
				inputARec->pDevice = NULL;
				inputARec->pElement = NULL;
				inputARec->invertMul = 1;
			}
		}
	}

	// ensure joystick and spaceball displays are set up
	[self joyElement:self];
	[self spaceElement:self];
	[self mouseEanbleEmulation:self]; // update display
}

- (void)updateUI: (NSDictionary *)prefsDefaults
{
	// read dictionanary and set as appropriate
	// set values and re-init (ensure to check to see if keyed object exists)
	[self updateLaunchUI:prefsDefaults];
	[self updateDevicesUI:prefsDefaults];
}

- (void)updateDevicesThread:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	GLUTDeviceEnumerator enumer;

	__glutCollectInputDevices();

	// update joystick menu
	[joyDeviceMenu removeAllItems];
	__glutGetInputDeviceEnumeratorOfClass (GLUT_JOYSTICK_DEVICE, &enumer);
	pRecDevice pDevice = __glutGetNextInputDevice (&enumer);
	while (pDevice) {
		[joyDeviceMenu addItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];
		pDevice = __glutGetNextInputDevice (&enumer);
	}
	if (0 == [joyDeviceMenu numberOfItems]) // no devices found
		[joyDeviceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"No devices with 2+ axis found.", @"GLUTUI", __glutGetFrameworkBundle(), @"No devices with 2+ axis found.")];

	// update spaceball menu
	[spaceDeviceMenu removeAllItems];
	__glutGetInputDeviceEnumeratorOfClass (GLUT_SPACEBALL_DEVICE, &enumer);
	pDevice = __glutGetNextInputDevice (&enumer);
	while (pDevice) {
		[spaceDeviceMenu addItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];
		pDevice = __glutGetNextInputDevice (&enumer);
	}
	if (0 == [spaceDeviceMenu numberOfItems]) // no devices found
		[spaceDeviceMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"No devices with 6+ axis found.", @"GLUTUI", __glutGetFrameworkBundle(), @"No devices with 6+ axis found.")];
		
	// ensure the device list and assignments are up to date
	[self updateDevicesUI:[[NSUserDefaults standardUserDefaults] persistentDomainForName: GLUTPreferencesName]];
	__glutUpdateJoystickInput (); 
	pDevice = __glutGetJoystickDevice ();
	if (pDevice)
		[joyDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];

	__glutUpdateSpaceballInput (); 
	pDevice = __glutGetSpaceballDevice ();
	if (pDevice)
		[spaceDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];

	updatingDevices = NO;
	[pool drain];
}

- (void)waitForDevicesThread
{
	while( YES == updatingDevices )
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05f]];
}

- (void)updateObjectState // after OK
{
	// everything joystick related is already set  //ggs: fix me
	[self updateLaunchState];
	[self updateMouseState];
}

/////////////////////////////////////////////
#pragma mark -
#pragma mark Launch Section
#pragma mark -

- (IBAction)launchUseMacOSCoords:(id)sender
{
// no action required
}

- (IBAction)launchUseCurrWD:(id)sender
{
// no action required
}

- (IBAction)launchUseExtDesktop:(id)sender
{
// no action required
}

- (IBAction)launchIconic:(id)sender
{
// no action required
}

- (IBAction)launchDebugMode:(id)sender
{
// no action required
}

- (IBAction)launchGamemodeCaptureSingle:(id)sender
{
// no action required
}

- (void)updateLaunchState // after OK
{
	// set values and re-init
	__glutUseMacOSCoords = [launchUseMacOSXCoords state];
	__glutUseInitWD = [launchUseCurrWD state];
	__glutUseExtendedDesktop = [launchUseExtendedDesktop state];
	// reset width and height in __glutEngineInit below
	__glutIconic = [launchIconic state];
	__glutDebug = [launchDebugMode state];
	if ([launchInitWidth intValue] > 0)
		__glutInitWidth = [launchInitWidth intValue];
	if ([launchInitHeight intValue] > 0)
		__glutInitHeight = [launchInitHeight intValue];
	if (NO == __glutUseMacOSCoords) {
		if([launchInitX intValue] >= 0)
			__glutInitX = [launchInitX intValue];
	} else
		__glutInitX = [launchInitX intValue];
	if (NO == __glutUseMacOSCoords) {
		if([launchInitY intValue] >= 0)
			__glutInitY = [launchInitY intValue];
	} else
		__glutInitY = [launchInitY intValue];
	__glutIdleTimeInterval = [launchMenuIdle floatValue];
	__glutGameModeFadeInterval = [launchFadeTime floatValue];
	__glutCaptureAllDisplays = 1 - [launchGamemodeCaptureSingle state];
	__glutSyncToVBL = [launchSyncToVBL state];
	
	__glutEngineInit (); // handles any set up glut engine needs
}

/////////////////////////////////////////////
#pragma mark -
#pragma mark Joystick Section
#pragma mark -

- (IBAction)joyDevice:(id)sender
{
	[joyAssignNote setStringValue:@" "];
	[joyAssignNote display];
	[joyAssignWarningIcon removeFromSuperview];

	// reset all inputs for new device put up warning
	// find name and compare to current
	// if found slect and reset inputs
	// if not found post error and reset to default
	
	GLUTDeviceEnumerator enumer;
	NSString * title = [joyDeviceMenu titleOfSelectedItem];
	__glutGetInputDeviceEnumeratorOfClass (GLUT_JOYSTICK_DEVICE, &enumer);
	pRecDevice pCurrentDevice = __glutGetJoystickDevice(), pFoundDevice = NULL, pDevice = __glutGetNextInputDevice (&enumer);
	while (pDevice && !pFoundDevice) {
		if (NSOrderedSame == [title compare:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]])
			pFoundDevice = pDevice;
		pDevice = __glutGetNextInputDevice (&enumer);
	}
	if (pCurrentDevice != pFoundDevice) {
		if (pFoundDevice) {
			__glutInitJoystickInput (pFoundDevice);
			[joyInputMenu selectItemAtIndex:0]; // reset position 
			[self joyElement:self]; // force assigment update
			[joyDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pFoundDevice->manufacturer, pFoundDevice->product]];
			[joyAssignNote setStringValue: NSLocalizedStringFromTableInBundle(@"New device select, all inputs reset.", @"GLUTUI",
										__glutGetFrameworkBundle(),
										@"New device select, all inputs reset.")];
			
		} else { // reset
			__glutInitJoystickInput (NULL);
			[joyInputMenu selectItemAtIndex:0]; // reset position 
			[self joyElement:self]; // force assigment update
			pDevice = __glutGetJoystickDevice ();
			if (pDevice)
				[joyDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];
				[joyAssignNote setStringValue: NSLocalizedStringFromTableInBundle(@"Selected device not found.", @"GLUTUI",
											__glutGetFrameworkBundle(),
											@"Selected device not found.")];
		}
		[joyAssignNote display];
		[joyTabItemView addSubview: joyAssignWarningIcon];
	}
}

- (IBAction)joyAssign:(id)sender
{
	[joyAssignNote setStringValue:@" "];
	[joyAssignNote display];
	[joyAssignWarningIcon removeFromSuperview];

	pRecDevice pDevice = NULL;
	pRecElement pElement = NULL;
	struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement ([joyInputMenu indexOfSelectedItem]);
	if (inputARec && inputARec->pDevice)
		pDevice = inputARec->pDevice;
	else
		pDevice = __glutGetJoystickDevice ();
	// this currently does not accunt for restricting the input to axis or buttons
	if ([joyInputMenu indexOfSelectedItem] < kActionButton1) {
		[joyAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s %@", 
												NSLocalizedStringFromTableInBundle(@"Move", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Move"), 
												pDevice->product, 
												NSLocalizedStringFromTableInBundle(@"axis to assign.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"axis to assign.")]];
	} else {
		[joyAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s %@", 
												NSLocalizedStringFromTableInBundle(@"Press", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Press"), 
												pDevice->product, 
												NSLocalizedStringFromTableInBundle(@"button to assign.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"button to assign.")]];
	}
	[joyAssignNote display];
	[joyAssignWarningIcon removeFromSuperview];
	[joyElement setStringValue:NSLocalizedStringFromTableInBundle(@"Unassigned", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Unassigned")];
	[joyElement display];
	// assign to next input that moves on chosen device
	if (HIDConfigureSingleDeviceAction (pDevice, &pElement, 5.0)) {
		if (pElement) {
			inputARec->pDevice = pDevice; // ensure device is set
			inputARec->pElement = pElement;
			if ([joyInputMenu indexOfSelectedItem] < kActionButton1) {
				pElement->userMin = -1000;
				pElement->userMax = 1000;
			} else {
				pElement->userMin = 0;
				pElement->userMax = 1;
			}
		}
		[self joyElement:self]; // force assigment update
	} else {
		[self joyElement:self]; // force assigment update
		[joyAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s", 
												NSLocalizedStringFromTableInBundle(@"Please choose input on", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Please choose input on"), 
												pDevice->product]];
		[joyAssignNote display];
		[joyTabItemView addSubview: joyAssignWarningIcon];
	}
}

- (IBAction)joyElement:(id)sender
{
	[joyAssignNote setStringValue:@" "];
	[joyAssignNote display];
	[joyAssignWarningIcon removeFromSuperview];

	// get menu item and update string
	NSString * outString;
	struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement ([joyInputMenu indexOfSelectedItem]);
	if (inputARec && inputARec->pDevice) {
		[joyInverted setEnabled:YES];
		[joyElement setEnabled:YES];
		[joyInputMenu setEnabled:YES];
		[joyAssign setEnabled:YES];
		if (inputARec->pElement) {
			outString = [[NSString alloc] initWithFormat: @"%s",inputARec->pElement->name];
			// this is normally supplied by the device and cannot be simply localized
			// set inverted check
			[joyInverted setIntValue: ((-inputARec->invertMul + 1) / 2)]; // so -1 = checked and 1 = not checked
		} else {
			outString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"No device input assigned.", @"GLUTUI",
								__glutGetFrameworkBundle(),
								@"No device input assigned.")];
		}
	} else {
		outString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"No device.", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"No device.")];
		[joyInverted setEnabled:NO];
		[joyElement setEnabled:NO];
		[joyInputMenu setEnabled:NO];
		[joyAssign setEnabled:NO];
	}
	[joyElement setStringValue:outString];
}

- (IBAction)joyInvert:(id)sender
{
	struct _GLUTinputActionRec * inputARec = __glutGetJoystickDeviceElement ([joyInputMenu indexOfSelectedItem]);
	inputARec->invertMul = -[joyInverted intValue] * 2 + 1; // so checked = -1 and not checked = 1
}

/////////////////////////////////////////////
#pragma mark -
#pragma mark Spaceball Section
#pragma mark -

- (IBAction)spaceDevice:(id)sender
{
	[spaceAssignNote setStringValue:@" "];
	[spaceAssignNote display];
	[spaceAssignWarningIcon removeFromSuperview];

	// reset all inputs for new device put up warning
	// find name and compare to current
	// if found slect and reset inputs
	// if not found post error and reset to default
	
	GLUTDeviceEnumerator enumer;
	NSString * title = [spaceDeviceMenu titleOfSelectedItem];
	__glutGetInputDeviceEnumeratorOfClass (GLUT_SPACEBALL_DEVICE, &enumer);
	pRecDevice pCurrentDevice = __glutGetSpaceballDevice(), pFoundDevice = NULL, pDevice = __glutGetNextInputDevice (&enumer);
	while (pDevice && !pFoundDevice) {
		if (NSOrderedSame == [title compare:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]])
			pFoundDevice = pDevice;
		pDevice = __glutGetNextInputDevice (&enumer);
	}
	if (pCurrentDevice != pFoundDevice) {
		if (pFoundDevice) {
			__glutInitSpaceballInput (pFoundDevice);
			[spaceInputMenu selectItemAtIndex:0]; // reset position 
			[self spaceElement:self]; // force assigment update
			[spaceDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pFoundDevice->manufacturer, pFoundDevice->product]];
			[spaceAssignNote setStringValue: NSLocalizedStringFromTableInBundle(@"New device select, all inputs reset.", @"GLUTUI",
										__glutGetFrameworkBundle(),
										@"New device select, all inputs reset.")];
			
		} else { // reset
			__glutInitSpaceballInput (NULL);
			[spaceInputMenu selectItemAtIndex:0]; // reset position 
			[self spaceElement:self]; // force assigment update
			pDevice = __glutGetSpaceballDevice ();
			if (pDevice)
				[spaceDeviceMenu selectItemWithTitle:[NSString stringWithFormat:@"%s %s",pDevice->manufacturer, pDevice->product]];
				[spaceAssignNote setStringValue: NSLocalizedStringFromTableInBundle(@"Selected device not found.", @"GLUTUI",
											__glutGetFrameworkBundle(),
											@"Selected device not found.")];
		}
		[spaceAssignNote display];
		[spaceTabItemView addSubview: spaceAssignWarningIcon];
	}
}


- (IBAction)spaceAssign:(id)sender
{
	[spaceAssignNote setStringValue:@" "];
	[spaceAssignNote display];
	[spaceAssignWarningIcon removeFromSuperview];

	pRecDevice pDevice = NULL;
	pRecElement pElement = NULL;
	struct _GLUTinputActionRec * inputARec = __glutGetSpaceballDeviceElement ([spaceInputMenu indexOfSelectedItem]);
	if (inputARec && inputARec->pDevice)
		pDevice = inputARec->pDevice;
	else
		pDevice = __glutGetSpaceballDevice ();
	// this currently does not accunt for restricting the input to axis or buttons
	if ([spaceInputMenu indexOfSelectedItem] < kActionButton1) {
		[spaceAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s %@", 
												NSLocalizedStringFromTableInBundle(@"Move", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Move"), 
												pDevice->product, 
												NSLocalizedStringFromTableInBundle(@"axis to assign.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"axis to assign.")]];
	} else {
		[spaceAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s %@", 
												NSLocalizedStringFromTableInBundle(@"Press", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Press"), 
												pDevice->product, 
												NSLocalizedStringFromTableInBundle(@"button to assign.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"button to assign.")]];
	}
	[spaceAssignNote display];
	[spaceAssignWarningIcon removeFromSuperview];
	[spaceElement setStringValue:NSLocalizedStringFromTableInBundle(@"Unassigned", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Unassigned")];
	[spaceElement display];
	// assign to next input that moves on chosen device
	if (HIDConfigureSingleDeviceAction (pDevice, &pElement, 5.0)) {
		if (pElement) {
			inputARec->pDevice = pDevice; // ensure device is set
			inputARec->pElement = pElement;
			if ([spaceInputMenu indexOfSelectedItem] < kSBActionXRotation) {
				pElement->userMin = -1000;
				pElement->userMax = 1000;
			} else if ([spaceInputMenu indexOfSelectedItem] < kSBActionButton1) {
				pElement->userMin = -1800;
				pElement->userMax = 1800;
			} else {
				pElement->userMin = 0;
				pElement->userMax = 1;
			}
		}
		[self spaceElement:self]; // force assigment update
	} else {
		[self spaceElement:self]; // force assigment update
		[spaceAssignNote setStringValue: [NSString stringWithFormat:@"%@ %s", 
												NSLocalizedStringFromTableInBundle(@"Please choose input on", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Please choose input on"), 
												pDevice->product]];
		[spaceAssignNote display];
		[spaceTabItemView addSubview: spaceAssignWarningIcon];
	}
	
}

- (IBAction)spaceElement:(id)sender
{
	[spaceAssignNote setStringValue:@" "];
	[spaceAssignNote display];
	[spaceAssignWarningIcon removeFromSuperview];

	// get menu item and update string
	NSString * outString;
	struct _GLUTinputActionRec * inputARec = __glutGetSpaceballDeviceElement ([spaceInputMenu indexOfSelectedItem]);
	if (inputARec && inputARec->pDevice) {
		[spaceInverted setEnabled:YES];
		[spaceElement setEnabled:YES];
		[spaceInputMenu setEnabled:YES];
		[spaceAssign setEnabled:YES];
		if (inputARec->pElement) {
			outString = [[NSString alloc] initWithFormat: @"%s",inputARec->pElement->name];
			// this is normally supplied by the device and cannot be simply localized
			// set inverted check
			[spaceInverted setIntValue: ((-inputARec->invertMul + 1) / 2)]; // so -1 = checked and 1 = not checked
		} else {
			outString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"No device input assigned.", @"GLUTUI",
								__glutGetFrameworkBundle(),
								@"No device input assigned.")];
		}
	} else {
		outString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"No device.", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"No device.")];
		[spaceInverted setEnabled:NO];
		[spaceElement setEnabled:NO];
		[spaceInputMenu setEnabled:NO];
		[spaceAssign setEnabled:NO];
	}
	[spaceElement setStringValue:outString];
}

- (IBAction)spaceInvert:(id)sender
{
	struct _GLUTinputActionRec * inputARec = __glutGetSpaceballDeviceElement ([spaceInputMenu indexOfSelectedItem]);
	if (inputARec)
		inputARec->invertMul = -[spaceInverted intValue] * 2 + 1; // so checked = -1 and not checked = 1
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Mouse Section
#pragma mark -

- (IBAction)mouseEanbleEmulation:(id)sender
{
	[mouseAssignWarningText setStringValue: @" "];
	[mouseAssignWarningText display];
	[mouseAssignWarningIcon removeFromSuperview];
	if ([mouseEmulation state]) {
		[mouseRightConfigMenu setEnabled:YES];
		[mouseMiddleConfigMenu setEnabled:YES];
	} else {
		[mouseRightConfigMenu setEnabled:NO];
		[mouseMiddleConfigMenu setEnabled:NO];
	}
}

- (IBAction)mouseMiddleMenu:(id)sender
{
	[mouseAssignWarningText setStringValue: @" "];
	[mouseAssignWarningText display];
	[mouseAssignWarningIcon removeFromSuperview];
	if ([mouseRightConfigMenu indexOfSelectedItem] == [mouseMiddleConfigMenu indexOfSelectedItem]) {
		// can't be the same
		[mouseAssignWarningText setStringValue: [NSString stringWithFormat:@"%@", 
												NSLocalizedStringFromTableInBundle(@"Button modifiers must not be the same.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Button modifiers must not be the same.")]];
		[mouseAssignWarningText display];
		[mouseTabItemView addSubview: mouseAssignWarningIcon];
		[mouseMiddleConfigMenu selectItemAtIndex: (([mouseRightConfigMenu indexOfSelectedItem] + 1) % 4)];
	}
}

- (IBAction)mouseRightMenu:(id)sender
{
	[mouseAssignWarningText setStringValue: @" "];
	[mouseAssignWarningText display];
	[mouseAssignWarningIcon removeFromSuperview];
	if ([mouseRightConfigMenu indexOfSelectedItem] == [mouseMiddleConfigMenu indexOfSelectedItem]) {
		// can't be the same
		[mouseAssignWarningText setStringValue: [NSString stringWithFormat:@"%@", 
												NSLocalizedStringFromTableInBundle(@"Button modifiers must not be the same.", @"GLUTUI",
												__glutGetFrameworkBundle(),
												@"Button modifiers must not be the same.")]];
		[mouseAssignWarningText display];
		[mouseTabItemView addSubview: mouseAssignWarningIcon];
		[mouseRightConfigMenu selectItemAtIndex: (([mouseMiddleConfigMenu indexOfSelectedItem] + 1) % 4)];
	}
}

- (void)updateMouseState
{
	__glutEmulateMouseButtons = [mouseEmulation state];
	__glutMouseFirstModifiers = [self indexToModifier:[mouseRightConfigMenu indexOfSelectedItem]];
	__glutMouseSecondModifiers = [self indexToModifier:[mouseMiddleConfigMenu indexOfSelectedItem]];
}

- (int) modifierToIndex:(unsigned int)modifier
{
// dialog order Control Option Command Shift
	switch (modifier) {
		case NSControlKeyMask:
			return 0;
			break;
		case NSAlternateKeyMask:
			return 1;
			break;
		case NSCommandKeyMask:
			return 2;
			break;
		case NSShiftKeyMask:
			return 3;
			break;
		default:
			return 0;
	}
}

- (unsigned int) indexToModifier:(int)buttonIndex
{
// dialog order Control Option Command Shift
	switch (buttonIndex) {
		case 0:
			return NSControlKeyMask;
			break;
		case 1:
			return NSAlternateKeyMask;
			break;
		case 2:
			return NSCommandKeyMask;
			break;
		case 3:
			return NSShiftKeyMask;
			break;
		default:
			return 0;
	}
}

@end
