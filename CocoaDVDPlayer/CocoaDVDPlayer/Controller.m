/*
     File: Controller.m
 Abstract: Implementation file for the Controller class in CocoaDVDPlayer, 
 an Apple Developer sample project.
  Version: 1.3
 
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

#import <DVDPlayback/DVDPlayback.h>
#import "Controller.h"


/*
********************************************************************************
**
**		Class: DVDEvent
**
********************************************************************************
*/

/* This is a private class that's used to pass DVD playback event information
from the callback function MyDVDEventHandler (which runs in a thread other than
the main thread) to the method handleDVDEvent, which runs in the main thread and
actually does the work. */

@interface DVDEvent : NSObject
{
	DVDEventCode mEventCode;
	DVDEventValue mEventData1, mEventData2;
}

- (id) initWithData:(DVDEventCode)eventCode 
	data1:(DVDEventValue)eventData1 
	data2:(DVDEventValue)eventData2;

- (DVDEventCode) eventCode;
- (DVDEventValue) eventData1;
- (DVDEventValue) eventData2;

@end


@implementation DVDEvent

- (id) initWithData: (DVDEventCode)eventCode 
	data1:(DVDEventValue)eventData1 
	data2:(DVDEventValue)eventData2 
{
	if ((self = [super init]) != nil) {
		mEventCode = eventCode;
		mEventData1 = eventData1;
		mEventData2 = eventData2;
	}
	return self;
}


- (DVDEventCode) eventCode { return mEventCode; }
- (DVDEventValue) eventData1 { return mEventData1; }
- (DVDEventValue) eventData2 { return mEventData2; }

@end


/*
********************************************************************************
**
**		Class: Controller
**
********************************************************************************
*/

/* These methods are used inside this file only. */

@interface Controller (InternalMethods) <NSApplicationDelegate>

- (BOOL) searchMountedDVDDisc;
- (BOOL) hasMedia;
- (BOOL) isValidMedia:(NSURL *)mediaURL;
- (BOOL) openMedia:(NSString *)inPath isVolume:(BOOL)isVolume;

- (UInt16) setAudioVolume:(BOOL)up;
- (int) displayAlertWithMessage:(NSString *)msgKey withInfo:(NSString *)infoKey;

- (void) beginSession;
- (void) endSession;
- (void) closeMedia;
- (void) deviceDidMount:(NSNotification *)notification;
- (void) handleDVDEvent:(DVDEvent *)event;
- (void) handleDVDError:(DVDErrorCode)errorCode;
- (void) machineDidWake:(NSNotification *)notification;
- (void) machineWillSleep:(NSNotification *)notification;
- (void) logMediaInfo;
- (void) resetUI;

void MyDVDErrorHandler (
	DVDErrorCode inErrorCode, 
	void *inRefCon);

void MyDVDEventHandler (
	DVDEventCode inEventCode, 
	DVDEventValue inEventData1, 
	DVDEventValue inEventData2, 
	void *inRefCon);

@end


@implementation Controller

/* Our init method defines our initial state and registers for
notifications. The DVD playback session is initialized later, in the method
applicationDidFinishLaunching. */

- (id)init
{
	if ((self = [super init]) != nil) {
	
		mBookmarks = [[NSMutableArray alloc] init];
		mDVDState = kDVDStateUnknown;
		mEventCallBackID = 0;
		mVolumePath = nil;

		/* register for several notifications posted to the shared workspace
		notification center */

		NSNotificationCenter *center = 
			[[NSWorkspace sharedWorkspace] notificationCenter];

		[center addObserver:self 
			selector:@selector(deviceDidMount:) 
			name:NSWorkspaceDidMountNotification 
			object:NULL];
			
		[center addObserver:self 
			selector:@selector(machineWillSleep:)
			name:NSWorkspaceWillSleepNotification 
			object:NULL];
			
		[center addObserver:self 
			selector:@selector(machineDidWake:)
			name:NSWorkspaceDidWakeNotification 
			object:NULL];


		/* make sure we're the delegate of the NSApplication instance */
		[[NSApplication sharedApplication] setDelegate:self];
		
	}

	return self;
}


/* The dealloc message is normally received when our creator releases us.
Cocoa doesn't seem to do this automatically when the application terminates,
so we release ourself in the method applicationWillTerminate. */

- (void) dealloc 
{
	[mBookmarks release];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


/* The deviceDidMount notification is received when the system mounts a
removable volume. We registered for this notification in our init method. If no
media is playing, we naively assume the user has inserted a new DVD disc and
respond by sending the openMedia message. No harm is done if the volume is not a
DVD, just a few wasted cycles. */

- (void) deviceDidMount:(NSNotification *)notification 
{
	if (mDVDState != kDVDStatePlaying)
	{
		NSString *devicePath = 
			[[notification userInfo] objectForKey:@"NSDevicePath"];
		NSLog(@"Device did mount: %@", devicePath);

		/* DVD volumes have a VIDEO_TS media folder at the root level */
		NSString *mediaPath = [devicePath stringByAppendingString:@"/VIDEO_TS"];

		[self openMedia:mediaPath isVolume:YES];
	}
}


/* The machineWillSleep notification is received when the system is about to
sleep. We registered for this notification in our init method. We respond
by notifying DVD Playback Services. */

- (void) machineWillSleep:(NSNotification *)notification 
{
	OSStatus result = DVDSleep();
	if (result != noErr) {
		NSLog(@"DVDSleep returned %ld", result);
	}
}


/* The machineDidWake notification is received when the system is no longer 
sleeping. We registered for this notification in our init method. We respond by
notifying DVD Playback Services. */

- (void) machineDidWake:(NSNotification *)notification 
{
	OSStatus result = DVDWakeUp();
	if (result != noErr) {
		NSLog(@"DVDWakeUp returned %ld", result);
	}
}


/* This method is declared in the NSMenuValidation protocol. As the delegate of
the application object, we get a validateMenuItem message whenever the user
displays one of the CocoaDVDPlayer menus. We respond by changing the appearance
of several menu items, based on our state. */

- (BOOL) validateMenuItem:(NSMenuItem *)inItem 
{
	SEL action = [inItem action];
	
	/* File menu */

	if (action == @selector(onMediaFolder:)) {
		if ([self hasMedia] == NO) {
			[inItem setTitle:@"Open Media Folder..."];
			[inItem setKeyEquivalent:@"o"];
		}
		else {
			[inItem setTitle:@"Close Media Folder"];
			[inItem setKeyEquivalent:@"w"];
		}
	}

	/* Controls menu */

	if (action == @selector(onMute:)) {
		Boolean isMuted;
		(void) DVDIsMuted (&isMuted);
		if (isMuted)
			/* display check mark */
			[inItem setState: NSOnState];
		else
			/* hide check mark */
			[inItem setState: NSOffState];
	}

	/* Window menu */

	if (action == @selector(onShowController:)) {
		if ([mControlWindow isVisible]) 
			[inItem setTitle:@"Hide Controller"];
		else 
			[inItem setTitle:@"Show Controller"];
	}

	/* always enable the menu item */
	return YES;
}


/* The setAudioVolume message is sent by the two action methods onVolumeUp
and onVolumeDown, in response to a user request to increase or decrease the
audio level. The audio level is an integer in the range minLevel (0) to maxLevel
(255). We change the level by an increment of 16, which is 1/16 of the total
range. */

- (UInt16) setAudioVolume:(BOOL)up 
{
	/* get range and current audio level */
	UInt16 minLevel, curLevel, maxLevel;
	OSStatus result = DVDGetAudioVolumeInfo (&minLevel, &curLevel, &maxLevel);
	if (result != noErr) {
		NSLog(@"DVDGetAudioVolumeInfo returned %ld", result);
	}

	UInt16 newLevel;

	/* compute how much we are going to change */
	UInt16 delta = (maxLevel - minLevel + 1) / 16;

	if (up) {
		/* compute the next level in the up direction, clamping the value to maxLevel */
		newLevel = MIN(curLevel + delta, maxLevel);
	}
	else {
		/* compute the next level in the down direction, clamping the value to minLevel */
		newLevel = MAX(curLevel - delta, minLevel);
	}

	/* set the new audio level */
	result = DVDSetAudioVolume (newLevel);
	if (result != noErr) {
		NSLog(@"DVDSetAudioVolume returned %ld", result);
	}

	/* return the new level, which we use to adjust the audio slider */
	return newLevel;
}


/* After the application finishes launching, we search for mounted volumes that
might be DVD media. We attempt to open each volume for playback. We can open
only one media folder at a time, so we stop when we succeed. */

- (BOOL) searchMountedDVDDisc
{
	BOOL foundDVD = NO;

	/* get an array of strings containing the full pathnames of all
	currently mounted removable media */
	NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];

	NSInteger i, count = [volumes count];
	for (i = 0; i < count; i++)
	{
		/* get the next volume path, and append the standard name for the
		media folder on a DVD-Video volume */
		NSString *path = [[volumes objectAtIndex:i] stringByAppendingString:@"/VIDEO_TS"];

		foundDVD = [self openMedia:path isVolume:YES];

		if (foundDVD) {
			/* we just opened a DVD volume */
			break;
		}
	}

	return foundDVD;
}


/* This method displays a modal alert panel with a short and long text
message. Both messages should be stored in a Localizable.strings file inside
the application bundle. You pass in the two string keys that correspond to the
text you want to display. */

- (NSInteger) displayAlertWithMessage:(NSString *)msgKey withInfo:(NSString *)infoKey
{
	NSString *messageText = nil;
	NSString *informativeText = nil;
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	if (bundle) {
		messageText = [bundle localizedStringForKey:msgKey 
			value:@"No translation" table:@"Localizable"];
	
		informativeText = [bundle localizedStringForKey:infoKey
			value:@"No translation" table:@"Localizable"];
	}

	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle: NSCriticalAlertStyle];
	[alert setMessageText: messageText];
	[alert setInformativeText: informativeText];
	NSInteger result = [alert runModal];
	[alert release];
	return result;
}


/* This method starts a new playback session, registers our DVD event and DVD
error handlers, and defines the rate at which timer events arrive. */

- (void) beginSession
{
	/* start a new playback session */

	NSLog(@"Step 1: Begin Session");

	OSStatus result = DVDInitialize();
	if (result != noErr) {
		/* we can't do anything useful now, so we handle the error and exit */
		NSLog(@"DVDInitialize returned %ld", result);
		if (result == kDVDErrorInitializingLib) {
			/* notify user that another client is using the framework */
			[self displayAlertWithMessage:@"frameworkBusy" withInfo:@"frameworkBusyInfo"];
		}
		[NSApp terminate:self];
	}

	/* install our handler for playback events */

	DVDEventCode eventCodes[] = {
		kDVDEventDisplayMode, 
		kDVDEventError,
		/* registering for and handling this event makes the use of
		DVDGetState unnecessary */
		kDVDEventPlayback, 
		kDVDEventPTT, 
		kDVDEventTitle, 
		kDVDEventTitleTime,
		kDVDEventVideoStandard, 
	};

	result = DVDRegisterEventCallBack (
		MyDVDEventHandler, 
		eventCodes, 
		sizeof(eventCodes)/sizeof(DVDEventCode), 
		(void *)self, 
		&mEventCallBackID);
	
	if (result != noErr) {
		NSLog(@"DVDRegisterEventCallBack returned %ld", result);
	}

	/* install a handler for unrecoverable errors */

	result = DVDSetFatalErrorCallBack (MyDVDErrorHandler, (void *)self);
	if (result != noErr) {
		NSLog(@"DVDSetFatalErrorCallBack returned %ld", result);
	}

	/* Change the period for the recurring kDVDEventTitleTime event to 1000
	milliseconds. This makes it more likely that the playback time advances at
	least one second on each update. */

	result = DVDSetTimeEventRate (1000);
	if (result != noErr) {
		NSLog(@"DVDSetTimeEventRate returned %ld", result);
	}
}


/* This method determines whether a specified path represents a valid DVD-Video
media folder. */

- (BOOL) isValidMedia:(NSURL *)mediaURL
{
	BOOL isDir;
	Boolean isValid = false;
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:[mediaURL path] isDirectory:&isDir] && isDir)
	{
		OSStatus result = DVDIsValidMediaURL ((CFURLRef)mediaURL, &isValid);
		if (result != noErr) {
			NSLog(@"DVDIsValidMediaURL returned %ld", result);
		}
	}

	return isValid;
}

/* We send ourself the openMedia message: (1) when the application launches and
finds removable media, (2) when the deviceDidMount notification is received, or
(3) when the user chooses the menu item Open Media Folder and selects a folder
to open. In cases 1 and 2, we call DVDOpenMediavolume. In case 3, we always call
DVDOpenMediaFile even if the folder is actually on a DVD disc volume. */

- (BOOL) openMedia:(NSString *)inPath isVolume:(BOOL)isVolume
{
	BOOL mediaIsOpen = NO;

	NSURL *mediaURL = [NSURL URLWithString:inPath];
	
	if ([self isValidMedia:mediaURL])
	{
		OSStatus result;

		if ([self hasMedia] == YES) {
			[self closeMedia];
		}

		if (isVolume) {
			result = DVDOpenMediaVolumeWithURL ((CFURLRef)mediaURL);
			if (result == noErr) {
				mVolumePath = inPath;
				[mVolumePath retain];
			}
		}
		else {
			result = DVDOpenMediaFileWithURL ((CFURLRef)mediaURL);
		}

		if (result == noErr) {
			NSLog(@"Step 5: Open Media");
			NSLog(@"Media Folder: %@", inPath);
			mediaIsOpen = YES;
			[self logMediaInfo];
		}

		if (result == kDVDErrordRegionCodeUninitialized) {
			/* The drive region code has not been initialized. Refer to the
			readme file for information on handling this situation. */
			[self displayAlertWithMessage:@"noRegionCode" withInfo:@"noRegionCodeInfo"];
			[NSApp terminate:self];
		}
	}

	return mediaIsOpen;
}


/* We send ourself the closeMedia message (1) when a media folder is open and
the user closes the folder, (2) when the user selects a new media folder to open
and another media folder is already open, or (3) when the session is ending. */

- (void) closeMedia 
{
	if ([self hasMedia] == NO)
		return;

	NSLog(@"Step 7: Close Media");

	if (mVolumePath) {
		OSStatus result = DVDCloseMediaVolume();
		if (result != noErr) {
			NSLog(@"DVDCloseMediaVolume returned %ld", result);
		}

		[mVolumePath release];
		mVolumePath = nil;
	}
	else {
		OSStatus result = DVDCloseMediaFile();
		if (result != noErr) {
			NSLog(@"DVDCloseMediaFile returned %ld", result);
		}
	} 

	/* clear all information in Controller window */
	[self resetUI];

	/* delete any bookmarks */
	[mBookmarks removeAllObjects];
}


/* If a playback session is active, this method closes media, unregisters the
event callback, and ends the session. We send ourself the endSession message
when the application is about to terminate. */

- (void) endSession
{
	/* mEventCallBackID is non-zero only if a session is active */
	if (mEventCallBackID) 
	{
		[self closeMedia];
		NSLog(@"Step 8: End Session");
		DVDUnregisterEventCallBack (mEventCallBackID);
		OSStatus result = DVDDispose();
		if (result != noErr) {
			NSLog(@"DVDDispose returned %ld", result);
		}
		mEventCallBackID = 0;
	}
}


/* This method clears the title number, scene number, and playing time in the
Controller window. We send ourself the resetUI message (1) when the application
is finished launching, (2) when we close a media folder, or (3) when the user
clicks the Stop button twice in succession. */

- (void) resetUI 
{
	[mTitleText setStringValue:@"-"];
	[mSceneText setStringValue:@"-"];
	[mTimeText setTimeElapsed:0 timeRemaining:0];
}


/* This method shows how to get information about the open media and the DVD
drive. The media ID is generated by DVD Playback Services and is not stored
inside the media itself. CocoaDVDPlayer does not implement the "Change Drive
Region Code" feature, but the user may want to know what the current drive
region code is and how many changes remain. */

- (void) logMediaInfo 
{
	if ([self hasMedia] == NO)
		return;

	/* retrieve and display the 64-bit media ID */

	DVDDiscID id;
	DVDGetMediaUniqueID (id);
	// unsigned long long x = *(unsigned long long *)id;
	// NSLog(@"Media ID: %qx", x);
	NSLog(@"Media ID: %.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x", 
		id[0], id[1], id[2], id[3], id[4], id[5], id[6], id[7]);	

	/* retrieve and display region code information */

	DVDRegionCode discRegions = kDVDRegionCodeUninitialized;
	DVDRegionCode driveRegion = kDVDRegionCodeUninitialized;
	SInt16 numChangesLeft = -1;
	DVDGetDiscRegionCode (&discRegions); 
	DVDGetDriveRegionCode (&driveRegion, &numChangesLeft);
	NSLog(@"Disc Regions: 0x%lx", discRegions);
	NSLog(@"Drive Region: 0x%lx", driveRegion);
	NSLog(@"Changes Left: %d", numChangesLeft);

	/* DVD Playback Services checks for a region match whenever you open
	media, so this code is redundant. The code is included here to show how
	it's done. */

	if ((~driveRegion & ~discRegions) != ~driveRegion) {
		NSLog(@"Warning: region code mismatch");
	}
} 

/* This method is a wrapper around the DVDHasMedia function. */

- (BOOL) hasMedia 
{
	Boolean hasMedia = FALSE;
	OSStatus result = DVDHasMedia (&hasMedia);
	if (result != noErr) {
		NSLog(@"DVDHasMedia returned %ld", result);
	}
	if (hasMedia) { return YES; }
	else { return NO; }
} 


/* This is our DVD event callback function. It's always called in a thread other
than the main thread. We need to handle the event in the main thread because we
may want to update the UI, which involves drawing. Therefore we pass the event
information to the handleDVDEvent method, which runs in the main thread and
actually does the work. Cocoa requires that we package the information inside an
object. */

void MyDVDEventHandler (
	DVDEventCode inEventCode, 
	DVDEventValue inEventData1, 
	DVDEventValue inEventData2, 
	void *inRefCon
) 
{
	Controller *controller = (Controller *)inRefCon;

	/* decouple the event from the callback thread */
	DVDEvent *dvdEvent = [[DVDEvent alloc] initWithData:inEventCode 
		data1:inEventData1 
		data2:inEventData2];

	[controller performSelectorOnMainThread:@selector(handleDVDEvent:) 
		withObject:dvdEvent 
		waitUntilDone:FALSE];

	[dvdEvent release];
}

/* This method does the work of handling the DVD events that we registered to
receive in the beginSession method. */

- (void) handleDVDEvent:(DVDEvent *)event 
{
	[event retain];

	switch ([event eventCode]) {
		case kDVDEventTitleTime: {
			[mTimeText setTimeElapsed:[event eventData1] 
				timeRemaining: ([event eventData2] - [event eventData1])];
			break;
		}
		case kDVDEventTitle: {
			[mTitleText setIntegerValue:[event eventData1]];
			[mVideoWindow setWindowSize:kVideoSizeCurrent];
			break;
		}
		case kDVDEventPTT: {
			[mSceneText setIntegerValue:[event eventData1]];
			// NSLog(@"Scene changed to %d", [event eventData1]);
			break;
		}
		case kDVDEventError:
			[self handleDVDError:(DVDErrorCode)[event eventData1]];
			break;

		case kDVDEventPlayback: {
			mDVDState = (OSStatus)[event eventData1];
			// NSLog(@"DVD state changed to %d", mDVDState);
			break;
		}
		case kDVDEventVideoStandard:
		case kDVDEventDisplayMode: {
			[mVideoWindow setWindowSize:kVideoSizeCurrent];
			break;
		}
	}

	[event release];
}


/* This function and method handle the fatal error event that we registered to
receive in the beginSession method. Typically a fatal error means an I/O problem
such as a damaged disc has made it impossible to continue with playback. You
should always implement this callback and respond by ending the playback
session. */

void MyDVDErrorHandler (DVDErrorCode inErrorCode, void *inRefCon)
{
	Controller *controller = (Controller *)inRefCon;
	[controller handleDVDError:inErrorCode];
}

- (void) handleDVDError:(DVDErrorCode)errorCode
{
	NSLog(@"fatal error %ld", errorCode);
	[NSApp terminate:self];
}


/*
********************************************************************************
**
**		NSApplication delegate methods
**
********************************************************************************
*/

/* As the delegate of NSApp (the NSApplication instance), we're automatically
registered to receive these notifications. We use them to begin and end the
playback session cleanly. */

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
	[self beginSession];
	[self resetUI];
	[mVideoWindow setupVideoWindow];
	[self searchMountedDVDDisc];
}


/* Elsewhere in this file, we send ourself the terminate message when an
unrecoverable error occurs. To ensure that we also receive the
applicationWillTerminate message, we need to indicate that it's all right to
quit immediately. */

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	return NSTerminateNow;
}


/* When this method is called, the application is about to terminate in response
to a user action or because an unrecoverable error occurred. */

- (void)applicationWillTerminate:(NSNotification *)notification
{	
	/* end the playback session */
	[self endSession];

	/* ensure that our dealloc method is called */
	[self release];
}


/*
********************************************************************************
**
**		UI actions
**
********************************************************************************
*/

#pragma mark Controller UI Actions

/* This method implements the actions for Open/Close Media Folder in the File
menu. */

- (IBAction) onMediaFolder:(id)sender
{

	/* If media is currently open, the user wants to close it. */

	if ([self hasMedia] == YES) {
		[self closeMedia];
		return;
	}

	/* The user wants to open a media folder. We display a modal Open dialog
	that's configured to open a single folder. If the user selects a folder and
	clicks the Open button, we attempt to open the media. */

	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	
	if ([panel runModal] == NSOKButton)
	{
		NSURL *folderURL = [[panel URLs] objectAtIndex:0];
		NSString *folderPath = [folderURL path];
		NSLog(@"Opening Media Folder: %@", folderPath);
		[self openMedia:folderPath isVolume:NO];
	}
}


/* This method implements the action for the Play button in the Control window.
It's also invoked in our onKeyDown method if media is paused and the user
presses the space bar. */

- (IBAction) onPlay:(id)sender 
{
	 /* If media is open and not playing, we initiate playback. */

	if ([self hasMedia] == NO) {
		return;
	}

	if (mDVDState != kDVDStatePlaying) {
		NSLog(@"Step 6: Play");
		OSStatus result = DVDPlay();
		if (result != noErr) {
			NSLog(@"DVDPlay returned %ld", result);
		}
	}
}


/* This method implements the action for the Pause button in the Control window.
It's also invoked in our onKeyDown method if media is playing and the user
presses the space bar. */

- (IBAction) onPause:(id)sender 
{
	 /* If media is open and not paused, we pause playback. */

	if ([self hasMedia] == NO) {
		return;
	}

	if (mDVDState != kDVDStatePaused) {
		OSStatus result = DVDPause();
		if (result != noErr) {
			NSLog(@"DVDPause returned %ld", result);
		}
	}
}


/* This method implements the action for the Stop button in the Control window.
If we call DVDStop twice in succession, DVD Playback Services rewinds to the
beginning of the media. */

- (IBAction) onStop:(id)sender 
{
	if ([self hasMedia] == NO) {
		return;
	}

	if (mDVDState == kDVDStateStopped) {
		/* we're going to rewind, so we clear the UI information */
		[self resetUI];
	}

	OSStatus result = DVDStop();
	if (result != noErr) {
		NSLog(@"DVDStop returned %ld", result);
	}
}


/* This method implements the action for the Eject button in the Control window. */

- (IBAction) onEject:(id)sender 
{
	/* if mVolumePath is defined, removable media is open */
	
	if (mVolumePath) {
		NSString *volumePath = [NSString stringWithString:mVolumePath];
		[self closeMedia];
		[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:volumePath];
	}
}


/* This method implements the action for the Scan Forward button in the Control window. */

- (IBAction) onScanForward:(id)sender 
{
	if (mDVDState == kDVDStatePlaying) {
		OSStatus result = DVDScan (kDVDScanRate4x, kDVDScanDirectionForward);
		if (result != noErr) {
			NSLog(@"DVDScan returned %ld", result);
		}
	}
}


/* This method implements the action for the Scan Backward button in the Control window. */

- (IBAction) onScanBackward:(id)sender 
{
	if (mDVDState == kDVDStatePlaying) {
		OSStatus result = DVDScan (kDVDScanRate4x, kDVDScanDirectionBackward);
		if (result != noErr) {
			NSLog(@"DVDScan returned %ld", result);
		}
	}
}


/* This method implements the action for the Previous Scene button in the
Control window. Scene, chapter, and part of title (PTT) all mean the same thing. */

- (IBAction) onPreviousScene:(id)sender 
{
	if (mDVDState == kDVDStatePlaying) {
		OSStatus result = DVDPreviousChapter();
		if (result != noErr) {
			NSLog(@"DVDPreviousChapter returned %ld", result);
		}
	}
}


/* This method implements the action for the Next Scene button in the Control window. */

- (IBAction) onNextScene:(id)sender 
{
	if (mDVDState == kDVDStatePlaying) {
		OSStatus result = DVDNextChapter();
		if (result != noErr) {
			NSLog(@"DVDNextChapter returned %ld", result);
		}
	}
}


/* This method implements the action for the Menu button in the Control window.
If a title is playing, we go to the associated menu. If a menu is displayed, we
go to the associated title. */

- (IBAction) onToggleMenu:(id)sender 
{
	if ((mDVDState == kDVDStatePlaying) || 
		(mDVDState == kDVDStatePlayingStill) || 
		(mDVDState == kDVDStatePaused))
	{
		Boolean onMenu = false;
		DVDMenu whichMenu;
		OSStatus result = DVDIsOnMenu (&onMenu, &whichMenu);
		if (result != noErr) {
			NSLog(@"DVDIsOnMenu returned %ld", result);
		}
		// NSLog(@"onMenu = %d, whichMenu = %d", onMenu, whichMenu);

		if (onMenu) {
			result = DVDReturnToTitle();
			if (result != noErr) {
				NSLog(@"DVDReturnToTitle returned %ld", result);
			}
		} else {
			result = DVDGoToMenu (kDVDMenuRoot);
			if (result != noErr) {
				NSLog(@"DVDGoToMenu returned %ld", result);
			}
		}	
	}
}


/* This method implements the action for the Next Camera Angle button in the
Control window. */

- (IBAction) onNextAngle:(id)sender 
{
	if (mDVDState == kDVDStatePlaying) 
	{
		UInt16 numAngles = 0, angle = 0;
		OSStatus result = DVDGetNumAngles (&numAngles);
		if (result != noErr) {
			NSLog(@"DVDGetNumAngles returned %ld", result);
		}
		
		result = DVDGetAngle (&angle);
		if (result != noErr) {
			NSLog(@"DVDGetAngle returned %ld", result);
		}
		
		if (++angle > numAngles) 
			angle = 1;
		result = DVDSetAngle (angle);
		if (result != noErr) {
			NSLog(@"DVDSetAngle returned %ld", result);
		}
	}
}


/* This method implements the action for the New Bookmark button in the Control
window. Each time the user clicks this button, we add a new bookmark to the
mBookmarks array. To learn how bookmarks are implemented, see the Bookmark
class. */

- (IBAction) onNewBookmark:(id)sender 
{
	/* bookmarks to still or moving frames are ok */
	if ((mDVDState == kDVDStatePlaying) || (mDVDState == kDVDStatePlayingStill)) 
	{
		DVDBookmark *bookmark = [[DVDBookmark alloc] init];
		[mBookmarks addObject:bookmark];
		/* the array retains it, so we can safely release the bookmark now */
		[bookmark release];
	}
}


/* This method implements the action for the Goto Next Bookmark button in the
Control window. It simply cycles though the bookmarks in the mBookmarks array. */

- (IBAction) onNextBookmark:(id)sender 
{
	NSUInteger count = [mBookmarks count];
	if (count) {
		/* index of next bookmark in array */
		static unsigned next;
		[[mBookmarks objectAtIndex:next] gotoBookmark];
		if (++next == count) {
			/* reset to first bookmark */
			next = 0;
		}
	}
}


/* This method implements the action for the (Audio) Volume Down item in the
Controls menu. */

- (IBAction) onVolumeDown:(id)sender 
{
	UInt16 newLevel = [self setAudioVolume:NO];
	[mAudioControl setFloatValue:newLevel];
}


/* This method implements the action for the (Audio) Volume Up item in the
Controls menu. */

- (IBAction) onVolumeUp:(id)sender 
{
	UInt16 newLevel = [self setAudioVolume:YES];
	[mAudioControl setFloatValue:newLevel];
}


/* This method implements the action for the (Audio) Mute item in the Controls
menu. */

- (IBAction) onMute:(id)sender 
{
	Boolean isMuted;

	OSStatus result = DVDIsMuted (&isMuted);
	if (result != noErr) {
		NSLog(@"DVDIsMuted returned %ld", result);
	}

	result = DVDMute (!isMuted);
	if (result != noErr) {
		NSLog(@"DVDMute returned %ld", result);
	}
}


/* This method implements the action for the audio volume slider control in the
Control window. */

- (IBAction) onAudioVolume:(id)sender 
{
	OSStatus result = DVDSetAudioVolume ([sender floatValue]);
	if (result != noErr) {
		NSLog(@"DVDSetAudioVolume returned %ld", result);
	}
}


/* This method implements the action for the Show/Hide Controller item in the Window
menu. */

- (IBAction)onShowController:(id)sender 
{
	if ([mControlWindow isVisible]) {
		[mControlWindow orderOut:self];
	} else {
		[mControlWindow orderFront:self];
	}
}


/* This method implements the action for the Maximum Size item in the Video menu. */

- (IBAction) onVideoMax:(id)sender 
{
	[mVideoWindow setWindowSize:kVideoSizeMax];
}


/* This method implements the action for the Normal Size item in the Video menu. */

- (IBAction) onVideoNormal:(id)sender 
{
	[mVideoWindow setWindowSize:kVideoSizeNormal];
}


/* This method implements the action for the Small Size item in the Video menu. */

- (IBAction) onVideoSmall:(id)sender 
{
	[mVideoWindow setWindowSize:kVideoSizeSmall];
}


/* Both the video window and the control window pass their key down events to
this method. We want to respond to these events in the same manner, regardless
of which window is currently the key window. */

- (BOOL) onKeyDown: (NSEvent *)theEvent 
{
	NSString *keyString = [theEvent characters];
	unichar key = [keyString characterAtIndex:0];
	BOOL keyIsHandled = YES;
	OSStatus result = noErr;
	
	switch (key) {
		case NSUpArrowFunctionKey:
			result = DVDDoUserNavigation (kDVDUserNavigationMoveUp);
			break;
		case NSDownArrowFunctionKey:
			result = DVDDoUserNavigation (kDVDUserNavigationMoveDown);
			break;
		case NSLeftArrowFunctionKey:
			result = DVDDoUserNavigation (kDVDUserNavigationMoveLeft);
			break;
		case NSRightArrowFunctionKey:
			result = DVDDoUserNavigation (kDVDUserNavigationMoveRight);
			break;
		case NSCarriageReturnCharacter:
		case NSEnterCharacter:
			result = DVDDoUserNavigation (kDVDUserNavigationEnter);
			break;
		case ' ':
			/* space bar toggles between play and pause */
			if (mDVDState == kDVDStatePlaying)
				[self onPause:self];
			else if (mDVDState == kDVDStatePaused)
			    [self onPlay:self];
			break;
		default:
			keyIsHandled = NO;
			break;
	}

	if (result != noErr) {
		NSLog(@"DVDDoUserNavigation returned %ld", result);
	}

	return keyIsHandled;
}

@end
