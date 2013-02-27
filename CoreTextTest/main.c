/*
*	File:		main.c of CoreTextTest
* 
*	Contains:	A small Carbon application showing how to use the new CoreText APIs.
*
*  Note:		The project is set up so that the DEBUG macro is set to one when the "Development"
*				build style is chosen and not at all when the "Deployment" build style is chosen.
*				Thus, all the require asserts "fire" only in "Development".
*	
*	Version:	1.0
* 
*	Created:	5/8/06
*
*	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
*				("Apple") in consideration of your agreement to the following terms, and your
*				use, installation, modification or redistribution of this Apple software
*				constitutes acceptance of these terms.  If you do not agree with these terms,
*				please do not use, install, modify or redistribute this Apple software.
*
*				In consideration of your agreement to abide by the following terms, and subject
*				to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
*				copyrights in this original Apple software (the "Apple Software"), to use,
*				reproduce, modify and redistribute the Apple Software, with or without
*				modifications, in source and/or binary forms; provided that if you redistribute
*				the Apple Software in its entirety and without modifications, you must retain
*				this notice and the following text and disclaimers in all such redistributions of
*				the Apple Software.  Neither the name, trademarks, service marks or logos of
*				Apple Computer, Inc. may be used to endorse or promote products derived from the
*				Apple Software without specific prior written permission from Apple.  Except as
*				expressly stated in this notice, no other rights or licenses, express or implied,
*				are granted by Apple herein, including but not limited to any patent rights that
*				may be infringed by your derivative works or by other works in which the Apple
*				Software may be incorporated.
*
*				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
*				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
*				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
*				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
*				COMBINATION WITH YOUR PRODUCTS.
*
*				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
*				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
*				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
*				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
*				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
*				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
*				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*	Copyright:  Copyright © 2006 Apple Computer, Inc, All Rights Reserved
*/
//****************************************************
#pragma mark * compilation directives *

//****************************************************
#pragma mark -
#pragma mark * includes & imports *

#include <Carbon/Carbon.h>

//****************************************************
#pragma mark -
#pragma mark * typedef's, struct's, enums, defines, etc. *

//****************************************************
#pragma mark -
#pragma mark * local (static) function prototypes *

// Functions found in almost all Sample Codes:

static pascal OSErr Handle_OpenApplication(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon);
static pascal OSErr Handle_ReopenApplication(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon);
static pascal OSErr Handle_OpenDocuments(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon);
static pascal OSErr Handle_PrintDocuments(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon);
static void Install_AppleEventHandlers(void);

static pascal OSStatus Handle_CommandUpdateStatus(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData);
static pascal OSStatus Handle_CommandProcess(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData);

static void Do_Preferences(void);
static OSStatus Do_CleanUp(void);

// Functions specific to this Sample Code:

static OSStatus InitializeSampleCodeGlobals(void);

static OSStatus Do_NewWindow(void);
static OSStatus HIViewCoreTextDraw( EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon );

static OSStatus AddingStyleAttributes( CFAttributedStringRef inAttrString, CFMutableAttributedStringRef * outMutAttrString );
static OSStatus AddingOtherStyleAttributes( CFAttributedStringRef inAttrString, CFMutableAttributedStringRef * outMutAttrString );

//****************************************************
#pragma mark -
#pragma mark * exported globals *

//****************************************************
#pragma mark -
#pragma mark * local (static) globals *

static IBNibRef gIBNibRef;
static UInt32 gWindowCount = 0;

static UniChar * gUnicodeText1 = NULL;
static SInt32    gUnicodeTextLength1 = 0;

static UniChar * gUnicodeText2 = NULL;
static SInt32    gUnicodeTextLength2 = 0;

//****************************************************
#pragma mark -
#pragma mark * exported function implementations *

/*****************************************************
*
* main (argc, argv) 
*
* Purpose:  main program entry point
*
* Inputs:   argc     - the number of elements in the argv array
*			argv     - an array of pointers to the parameters to this application
*
* Returns:  int      - error code (0 == no error) 
*/
int main(int argc, char* argv[])
{
	OSStatus status;
	
	// Can we run this particular demo application?
	long response;
	status = Gestalt(gestaltSystemVersion, &response);
	Boolean ok = ((status == noErr) && (response >= 0x00001050));
	if (!ok)
	{
		DialogRef theAlert;
		CreateStandardAlert(kAlertStopAlert, CFSTR("Mac OS X 10.5 (minimum) is required for this application"), NULL, NULL, &theAlert);
		RunStandardAlert(theAlert, NULL, NULL);
		ExitToShell();
	}
	
	// Create a Nib reference passing the name of the nib file (without the .nib extension)
	// CreateNibReference only searches into the application bundle.
	status = CreateNibReference(CFSTR("main"), &gIBNibRef);
	require_noerr(status, CreateNibReference);
	
	// Once the nib reference is created, set the menu bar. "MainMenu" is the name of the menu bar
	// object. This name is set in InterfaceBuilder when the nib is created.
	status = SetMenuBarFromNib(gIBNibRef, CFSTR("MenuBar"));
	require_noerr(status, SetMenuBarFromNib);
	
	// Enabling Preferences menu item
	EnableMenuCommand(NULL, kHICommandPreferences);
	
	// Let's react to User's commands.
	Install_AppleEventHandlers();
	
	EventTypeSpec eventTypeCP = {kEventClassCommand, kEventCommandProcess};
	status = InstallEventHandler(GetApplicationEventTarget(), Handle_CommandProcess, 1, &eventTypeCP, NULL, NULL);
	require_noerr(status, InstallEventHandler);
	
	EventTypeSpec eventTypeCUS = {kEventClassCommand, kEventCommandUpdateStatus};
	status = InstallEventHandler(GetApplicationEventTarget(), Handle_CommandUpdateStatus, 1, &eventTypeCUS, NULL, NULL);
	require_noerr(status, InstallEventHandler);
	
	status = InitializeSampleCodeGlobals();
	require_noerr(status, InitializeSampleCodeGlobals);
	
	// Call the event loop
	RunApplicationEventLoop();
	
InitializeSampleCodeGlobals:
InstallEventHandler:
SetMenuBarFromNib:
CreateNibReference:

	return status;
}   // main

/*****************************************************/
#pragma mark -
#pragma mark * local (static) function implementations *
#pragma mark * AppleEvent Handlers *

/*****************************************************
*
* Handle_OpenApplication(inAppleEvent, reply, inHandlerRefcon) 
*
* Purpose:  AppleEvent handler for the kAEOpenApplication event
*
* Inputs:   inAppleEvent     - the Apple event
*           reply            - our reply to the Apple event
*           inHandlerRefcon  - refcon passed to AEInstallEventHandler when this hander was installed
*
* Returns:  OSErr            - error code (0 == no error) 
*/
static pascal OSErr Handle_OpenApplication(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon)
{
	// we create 2 cascading new windows with different content
	Do_NewWindow();
	Do_NewWindow();
	
	return noErr;
}   // Handle_OpenApplication

/*****************************************************
*
* Handle_ReopenApplication(inAppleEvent, reply, inHandlerRefcon) 
*
* Purpose:  AppleEvent handler for the kAEReopenApplication event
*
* Inputs:   inAppleEvent     - the Apple event
*           reply            - our reply to the Apple event
*           inHandlerRefcon  - refcon passed to AEInstallEventHandler when this hander was installed
*
* Returns:  OSErr            - error code (0 == no error) 
*/
static pascal OSErr Handle_ReopenApplication(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon)
{
	// We were already running but with no windows so we create an empty one.
	WindowRef theWindow = GetFrontWindowOfClass(kDocumentWindowClass, true);
	if (theWindow == NULL)
		return Do_NewWindow();
	else
		return noErr;
}   // Handle_ReopenApplication

/*****************************************************
*
* Handle_OpenDocuments(inAppleEvent, reply, inHandlerRefcon) 
*
* Purpose:  AppleEvent handler for the kAEOpenDocuments event
*
* Inputs:   inAppleEvent     - the Apple event
*           reply            - our reply to the Apple event
*           inHandlerRefcon  - refcon passed to AEInstallEventHandler when this hander was installed
*
* Returns:  OSErr            - error code (0 == no error) 
*/
static pascal OSErr Handle_OpenDocuments(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon)
{
	return errAEEventNotHandled;
}   // Handle_OpenDocuments

/*****************************************************
*
* Handle_PrintDocuments(inAppleEvent, reply, inHandlerRefcon) 
*
* Purpose:  AppleEvent handler for the kAEPrintDocuments event
*
* Inputs:   inAppleEvent     - the Apple event
*           reply            - our reply to the Apple event
*           inHandlerRefcon  - refcon passed to AEInstallEventHandler when this hander was installed
*
* Returns:  OSErr            - error code (0 == no error) 
*/
static pascal OSErr Handle_PrintDocuments(const AppleEvent *inAppleEvent, AppleEvent *outAppleEvent, long inHandlerRefcon)
{
	return errAEEventNotHandled;
}   // Handle_PrintDocuments

/*****************************************************
*
* Install_AppleEventHandlers(void) 
*
* Purpose:  installs the AppleEvent handlers
*
* Inputs:   none
*
* Returns:  none
*/
static void Install_AppleEventHandlers(void)
{
	OSErr	status;
	status = AEInstallEventHandler(kCoreEventClass, kAEOpenApplication, Handle_OpenApplication, 0, false);
	require_noerr(status, CantInstallAppleEventHandlerOpenAppl);
	
	status = AEInstallEventHandler(kCoreEventClass, kAEReopenApplication, Handle_ReopenApplication, 0, false);
	require_noerr(status, CantInstallAppleEventHandlerReOpenAppl);
	
	status = AEInstallEventHandler(kCoreEventClass, kAEOpenDocuments, Handle_OpenDocuments, 0, false);
	require_noerr(status, CantInstallAppleEventHandlerOpenDocs);
	
	status = AEInstallEventHandler(kCoreEventClass, kAEPrintDocuments, Handle_PrintDocuments, 0, false);
	require_noerr(status, CantInstallAppleEventHandlerPrintDocs);
	
	// Note: Since RunApplicationEventLoop installs a Quit AE Handler, there is no need to do it here.
	
CantInstallAppleEventHandlerOpenAppl:
CantInstallAppleEventHandlerReOpenAppl:
CantInstallAppleEventHandlerOpenDocs:
CantInstallAppleEventHandlerPrintDocs:

	return;
}   // Install_AppleEventHandlers

#pragma mark -
#pragma mark * CarbonEvent Handlers *

/*****************************************************
*
* Handle_CommandUpdateStatus(inHandlerCallRef, inEvent, inUserData) 
*
* Purpose:  called to update status of the commands, enabling or disabling the menu items
*
* Inputs:   inHandlerCallRef    - reference to the current handler call chain
*			inEvent             - the event
*           inUserData          - app-specified data you passed in the call to InstallEventHandler
*
* Returns:  OSStatus            - noErr indicates the event was handled
*                                 eventNotHandledErr indicates the event was not handled and the Toolbox should take over
*/
static pascal OSStatus Handle_CommandUpdateStatus(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
	OSStatus status = eventNotHandledErr;
	
	HICommand aCommand;
	GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(HICommand), NULL, &aCommand);
	
	WindowRef aWindowRef = GetFrontWindowOfClass(kDocumentWindowClass, true);
		
	if (aWindowRef == NULL)
	{
		switch (aCommand.commandID)
		{
			case 'SngS':
			case 'DblS':
			case kHICommandClose:
				DisableMenuItem(aCommand.menu.menuRef, aCommand.menu.menuItemIndex);
				break;
		}
	}
	else
	{
		switch (aCommand.commandID)
		{
			case 'SngS':
			case 'DblS':
			{
				Boolean singleSpace = true;
				status = GetWindowProperty(aWindowRef, 'CTTT', 'SBSP', sizeof(singleSpace), NULL, &singleSpace);
				if (status != noErr)
					DisableMenuItem(aCommand.menu.menuRef, aCommand.menu.menuItemIndex);
				else
				{
					EnableMenuItem(aCommand.menu.menuRef, aCommand.menu.menuItemIndex);
					CheckMenuItem(
							aCommand.menu.menuRef, aCommand.menu.menuItemIndex,
							(singleSpace && (aCommand.commandID == 'SngS')) || ((!singleSpace) && (aCommand.commandID == 'DblS'))
							);
				}
				break;
			}

			case kHICommandClose:
				EnableMenuItem(aCommand.menu.menuRef, aCommand.menu.menuItemIndex);
				break;
		}
	}

	return status;
}   // Handle_CommandUpdateStatus

/*****************************************************
*
* Handle_CommandProcess(inHandlerCallRef, inEvent, inUserData) 
*
* Purpose:  called to process commands from Carbon events
*
* Inputs:   inHandlerCallRef    - reference to the current handler call chain
*			inEvent             - the event
*           inUserData          - app-specified data you passed in the call to InstallEventHandler
*
* Returns:  OSStatus            - noErr indicates the event was handled
*                                 eventNotHandledErr indicates the event was not handled and the Toolbox should take over
*/
static pascal OSStatus Handle_CommandProcess(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
	OSStatus status = eventNotHandledErr;
	
	HICommand aCommand;
	GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(HICommand), NULL, &aCommand);
	
	switch (aCommand.commandID)
	{
		case kHICommandPreferences:
			Do_Preferences();
			break;
		case kHICommandNew:
			status = Do_NewWindow();
			break;
		case kHICommandQuit:
			status = Do_CleanUp();
			break;
		case 'SngS':
		case 'DblS':
		{
			WindowRef aWindowRef = GetFrontWindowOfClass(kDocumentWindowClass, true);
			require(aWindowRef != NULL, GetFrontWindowOfClass);
			
			Boolean singleSpace;
			status = GetWindowProperty(aWindowRef, 'CTTT', 'SBSP', sizeof(singleSpace), NULL, &singleSpace);
			
			// we change from single-space to double-space (or vice versa) for the blue gray text
			// we just change the window property and tell the HIView to update its contents.
			
			if (status == noErr)
			{
				singleSpace = !singleSpace;
				status = SetWindowProperty(aWindowRef, 'CTTT', 'SBSP', sizeof(singleSpace), &singleSpace);
				require_noerr(status, SetWindowProperty);
				
				HIViewID baseHIViewID = { 'BLNK', 100 };
				HIViewRef baseView;
				HIViewFindByID(HIViewGetRoot(aWindowRef), baseHIViewID, &baseView);
				require(baseView != NULL, HIViewFindByID);
				
				HIViewSetNeedsDisplay(baseView, true);
			}
		
			break;
		}
	}

HIViewFindByID:
SetWindowProperty:
GetFrontWindowOfClass:

	return status;
}   // Handle_CommandProcess

/*****************************************************
*
* Handle_WindowClosing(inHandlerCallRef, inEvent, inUserData) 
*
* Purpose:  called when the window is closing, time to dispose of the properties
*
* Inputs:   inHandlerCallRef    - reference to the current handler call chain
*			inEvent             - the event
*           inUserData          - app-specified data you passed in the call to InstallEventHandler
*
* Returns:  OSStatus            - noErr indicates the event was handled
*                                 eventNotHandledErr indicates the event was not handled and the Toolbox should take over
*/
static pascal OSStatus Handle_WindowClosing(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
	OSStatus status = eventNotHandledErr;
	WindowRef aWindowRef = (WindowRef)inUserData;

	// cleaning up the storage associated with the window

	CFAttributedStringRef attrString;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CFA1', sizeof(attrString), NULL, &attrString);
	if ((status == noErr) && (attrString != NULL)) CFRelease(attrString);

	status = GetWindowProperty(aWindowRef, 'CTTT', 'CFA2', sizeof(attrString), NULL, &attrString);
	if ((status == noErr) && (attrString != NULL)) CFRelease(attrString);
	
	CTFramesetterRef setter;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CTF1', sizeof(setter), NULL, &setter);
	if ((status == noErr) && (setter != NULL)) CFRelease(setter);

	status = GetWindowProperty(aWindowRef, 'CTTT', 'CTF2', sizeof(setter), NULL, &setter);
	if ((status == noErr) && (setter != NULL)) CFRelease(setter);
	
	return status;
}   // Handle_WindowClosing


#pragma mark -
#pragma mark * Windows *

/*****************************************************
*
* Do_Preferences(void) 
*
* Purpose:  routine to display dialog to set our applications preferences
*
* Inputs:   none
*
* Returns:  none
*/
static void Do_Preferences(void)
{
	DialogRef theAlert;
	CreateStandardAlert(kAlertStopAlert, CFSTR("No Preferences yet!"), NULL, NULL, &theAlert);
	RunStandardAlert(theAlert, NULL, NULL);
}   // Do_Preferences

/*****************************************************
*
* Do_CleanUp(void) 
*
* Purpose:  called when we get the quit event, closes all the windows.
*
* Inputs:   none
*
* Returns:  OSStatus   - eventNotHandledErr indicates that the quit process can continue
*/
static OSStatus Do_CleanUp(void)
{
	WindowRef windowToDispose, aWindowRef = GetFrontWindowOfClass(kDocumentWindowClass, true);

	for ( ; aWindowRef != NULL; )
	{
		windowToDispose = aWindowRef;
		aWindowRef = GetNextWindowOfClass(aWindowRef, kDocumentWindowClass, true);
		
		DisposeWindow(windowToDispose);
	}
	
	return eventNotHandledErr;
}   // Do_CleanUp

#pragma mark -
#pragma mark * Functions specific to this Sample Code *

//--------------------------------------------------------------------------------------------
static OSStatus InitializeSampleCodeGlobals(void)
{
	OSStatus status;
	Boolean ok;

	// we will add the following block of text to the text files we read to explain to the use what's going on
	
	CFStringRef theHeader = CFSTR("The text in black is rendered using CTFrameDraw, the text in blue gray is rendered using CTLineDraw. The latter can also be rendered single-spaced or double-spaced using the Options menu.\r\r");
	CFIndex theLength = CFStringGetLength(theHeader);
	UniChar * headerText = malloc(2 * theLength);
	CFStringGetCharacters(theHeader, CFRangeMake(0, theLength), headerText);
    
	// Get the Unicode Text from our resource file
	CFBundleRef mainBundle = CFBundleGetMainBundle();
    require_action( mainBundle != NULL, CFBundleGetMainBundle, status = coreFoundationUnknownErr );
	
	// first text file
	
	CFURLRef cfurl = CFBundleCopyResourceURL(mainBundle, CFSTR("WorldText Sample File"), CFSTR("utxt"), NULL);
    require_action( cfurl != NULL, CFBundleCopyResourceURL, status = coreFoundationUnknownErr );
	
	FSRef fsRef;
	ok = CFURLGetFSRef(cfurl, &fsRef);
	CFRelease(cfurl);
    require_action( ok, CFURLGetFSRef, status = coreFoundationUnknownErr );
	
	SInt16 refNum;
	status = FSOpenFork(&fsRef, 0, NULL, fsRdPerm, &refNum);
    require_noerr( status, FSOpenFork );
	
	SInt64 forkSize;
	status = FSGetForkSize(refNum, &forkSize);
    require_noerr( status, FSGetForkSize );
	
	gUnicodeTextLength1 = forkSize; // we'll never be that big...
	gUnicodeText1 = malloc(gUnicodeTextLength1 + 2 * theLength);
    require_action( gUnicodeText1 != NULL, malloc, status = memFullErr );
	
	memcpy(gUnicodeText1, headerText, 2 * theLength);
	
	status = FSReadFork(refNum, fsFromStart, 0, gUnicodeTextLength1, &gUnicodeText1[theLength], NULL);
    require_noerr( status, FSReadFork );
	
	FSCloseFork(refNum);
	
	// second test file, bis repetita

	cfurl = CFBundleCopyResourceURL(mainBundle, CFSTR("US Text Sample File"), CFSTR("utxt"), NULL);
    require_action( cfurl != NULL, CFBundleCopyResourceURL, status = coreFoundationUnknownErr );
	
	ok = CFURLGetFSRef(cfurl, &fsRef);
	CFRelease(cfurl);
    require_action( ok, CFURLGetFSRef, status = coreFoundationUnknownErr );
	
	status = FSOpenFork(&fsRef, 0, NULL, fsRdPerm, &refNum);
    require_noerr( status, FSOpenFork );
	
	status = FSGetForkSize(refNum, &forkSize);
    require_noerr( status, FSGetForkSize );
	
	gUnicodeTextLength2 = forkSize; // we'll never be that big...
	gUnicodeText2 = malloc(gUnicodeTextLength2 + 2 * theLength);
    require_action( gUnicodeText2 != NULL, malloc, status = memFullErr );
	
	memcpy(gUnicodeText2, headerText, 2 * theLength);
	
	status = FSReadFork(refNum, fsFromStart, 0, gUnicodeTextLength2, &gUnicodeText2[theLength], NULL);
    require_noerr( status, FSReadFork );
	
	FSCloseFork(refNum);

FSReadFork:
malloc:
FSGetForkSize:
FSOpenFork:
CFURLGetFSRef:
CFBundleCopyResourceURL:
CFBundleGetMainBundle:

	return status;

}   // InitializeSampleCodeGlobals

/*****************************************************
*
* Do_NewWindow() 
*
* Purpose:  called to create a new window, each other window will be created from APIs and the other one from Interface Builder
*
* Notes:    called by Handle_CommandProcess() ("File/New" menu item), Handle_OpenApplication(). Handle_ReopenApplication()
*
* Inputs:   none
*
* Returns:  OSStatus    - error code (0 == no error) 
*/
static OSStatus Do_NewWindow(void)
{
	OSStatus status;
	WindowRef aWindowRef = NULL;
	CFStringRef theTitle = NULL;
	CFMutableStringRef theNewTitle = NULL;
	
	// Create a window. "MainWindow" is the name of the window object. This name is set in 
	// InterfaceBuilder when the nib is created.
	status = CreateWindowFromNib(gIBNibRef, CFSTR("MainWindow"), &aWindowRef);
	require_noerr(status, CreateWindowFromNib);
	require(aWindowRef != NULL, CreateWindowFromNib);
	
	// handling the window title
	
	status = CopyWindowTitleAsCFString(aWindowRef, &theTitle);
	require_noerr(status, CopyWindowTitleAsCFString);
	
	theNewTitle = CFStringCreateMutableCopy(NULL, 0, theTitle);
	require(theNewTitle != NULL, CFStringCreateMutableCopy);
	
	CFStringAppendFormat(theNewTitle, NULL, CFSTR(" %ld"), ++gWindowCount);
	status = SetWindowTitleWithCFString(aWindowRef, theNewTitle);
	require_noerr(status, SetWindowTitleWithCFString);
	
	// making sure we will clean up after ourselves
	EventTypeSpec eventTypeWC = {kEventClassWindow, kEventWindowClosed};
	status = InstallWindowEventHandler(aWindowRef, Handle_WindowClosing, 1, &eventTypeWC, (void *)aWindowRef, NULL);
	require_noerr(status, CantInstallEventHandler);
		
	// installing our custom drawing function to the HIView
	HIViewID baseHIViewID = { 'BLNK', 100 };
	HIViewRef baseView;
	HIViewFindByID(HIViewGetRoot(aWindowRef), baseHIViewID, &baseView);
	require(baseView != NULL, HIViewFindByID);
	
	EventTypeSpec eventTypeCD = {kEventClassControl, kEventControlDraw};
    HIViewInstallEventHandler(baseView, HIViewCoreTextDraw,  1, &eventTypeCD, aWindowRef, NULL);

	// for performance reasons, let's associate the strings and frame setters to the window
	// there are 2 strings and 2 setters, 1 for each flow of text. 1 will be rendered with CTFrameDraw
	// and the other one with CTLineDraw.

	UniChar * unicodeText = (gWindowCount % 2 == 0) ? gUnicodeText1 : gUnicodeText2 ;
	SInt32 unicodeTextLength = (gWindowCount % 2 == 0) ? gUnicodeTextLength1 : gUnicodeTextLength2 ;
	CFIndex unicodeCharLength = unicodeTextLength / sizeof(UniChar);
	CFStringRef uniCFString = CFStringCreateWithCharacters(NULL, unicodeText, unicodeCharLength);
	require(uniCFString != NULL, CFStringCreateWithCharacters);
	
	CFAttributedStringRef attrString;
	attrString = CFAttributedStringCreate(NULL, uniCFString, NULL);
	CFRelease(uniCFString);
	require(attrString != NULL, CFAttributedStringCreate);
	
	CFRetain(attrString);

	CFMutableAttributedStringRef mutAttrString1;
	status = AddingStyleAttributes(attrString, &mutAttrString1);
	require_noerr(status, AddingStyleAttributes);

	CFMutableAttributedStringRef mutAttrString2;
	status = AddingOtherStyleAttributes(attrString, &mutAttrString2);
	require_noerr(status, AddingOtherStyleAttributes);
	
	CTFramesetterRef setter1 = CTFramesetterCreateWithAttributedString(mutAttrString1);
	require(setter1 != NULL, CTFramesetterCreateWithAttributedString);
	
	CTFramesetterRef setter2 = CTFramesetterCreateWithAttributedString(mutAttrString2);
	require(setter2 != NULL, CTFramesetterCreateWithAttributedString);
	
	status = SetWindowProperty(aWindowRef, 'CTTT', 'CFA1', sizeof(mutAttrString1), &mutAttrString1);
	require_noerr(status, SetWindowProperty);
	
	status = SetWindowProperty(aWindowRef, 'CTTT', 'CTF1', sizeof(setter1), &setter1);
	require_noerr(status, SetWindowProperty);
	
	status = SetWindowProperty(aWindowRef, 'CTTT', 'CFA2', sizeof(mutAttrString2), &mutAttrString2);
	require_noerr(status, SetWindowProperty);
	
	status = SetWindowProperty(aWindowRef, 'CTTT', 'CTF2', sizeof(setter2), &setter2);
	require_noerr(status, SetWindowProperty);
	
	Boolean singleSpace = true;
	status = SetWindowProperty(aWindowRef, 'CTTT', 'SBSP', sizeof(singleSpace), &singleSpace);
	require_noerr(status, SetWindowProperty);
    
    // The window was created hidden, so show it
	ShowWindow(aWindowRef);
	
	SetWindowModified(aWindowRef, false);

AddingOtherStyleAttributes:
AddingStyleAttributes:
SetWindowProperty:
CTFramesetterCreateWithAttributedString:
CFAttributedStringCreate:
CFStringCreateWithCharacters:	
CantInstallEventHandler:
SetWindowTitleWithCFString:
CFStringCreateMutableCopy:
CopyWindowTitleAsCFString:

	if (theTitle != NULL)
		CFRelease(theTitle);
	if (theNewTitle != NULL)
		CFRelease(theNewTitle);

HIViewFindByID:
CantAllocateWindowData:
CreateWindowFromNib:
	
	return status;
}   // Do_NewWindow

/*****************************************************
*
* HIViewCoreTextDraw(inCaller, inEvent, inRefcon)
*
* Purpose:  custom drawing using the CoreText APIs
*
* Returns:  OSStatus    - error code (0 == no error) 
*/
static OSStatus HIViewCoreTextDraw( EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon )
{
    OSStatus status;

	// retrieving important items through the event parameters
	
	HIViewRef view;
	status = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, NULL, sizeof(view), NULL, &view);
	require(view != NULL, GetEventParameter);

	CGContextRef context;
	status = GetEventParameter(inEvent, kEventParamCGContextRef, typeCGContextRef, NULL, sizeof(context), NULL, &context);
	require(context != NULL, GetEventParameter);

	HIRect bounds;
	HIViewGetBounds(view, &bounds);

	CGContextScaleCTM(context, 1, -1);

	WindowRef aWindowRef = GetControlOwner(view);
	require(aWindowRef != NULL, GetControlOwner);

	// retrieving important items through the window properties

	CFAttributedStringRef attrString1;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CFA1', sizeof(attrString1), NULL, &attrString1);
	require_noerr(status, GetWindowProperty);
	require(attrString1 != NULL, GetWindowProperty);
	
	CTFramesetterRef setter1;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CTF1', sizeof(setter1), NULL, &setter1);
	require_noerr(status, GetWindowProperty);
	require(setter1 != NULL, GetWindowProperty);

	CFAttributedStringRef attrString2;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CFA2', sizeof(attrString2), NULL, &attrString2);
	require_noerr(status, GetWindowProperty);
	require(attrString2 != NULL, GetWindowProperty);
	
	CTFramesetterRef setter2;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'CTF2', sizeof(setter2), NULL, &setter2);
	require_noerr(status, GetWindowProperty);
	require(setter2 != NULL, GetWindowProperty);

	Boolean singleSpace = true;
	status = GetWindowProperty(aWindowRef, 'CTTT', 'SBSP', sizeof(singleSpace), NULL, &singleSpace);
	require_noerr(status, GetWindowProperty);

	// setting boundaries
	
	CFIndex unicodeCharLength1 = CFAttributedStringGetLength(attrString1);
	CFIndex unicodeCharLength2 = CFAttributedStringGetLength(attrString2);
	HIRect frameBounds[4] =
	{
		{ {									10,									10 }, { (bounds.size.width - 30) / 2, (bounds.size.height - 30) / 2 + 50 } },
		{ { (bounds.size.width - 30) / 2 +	20, (bounds.size.height - 30) / 2 + 70 }, { (bounds.size.width - 30) / 2, (bounds.size.height - 30) / 2 - 50 } },

		{ { (bounds.size.width - 30) / 2 +	20,                                 10 }, { (bounds.size.width - 30) / 2, (bounds.size.height - 30) / 2 + 50 } },
		{ {									10,	(bounds.size.height - 30) / 2 + 70 }, { (bounds.size.width - 30) / 2, (bounds.size.height - 30) / 2 - 50 } }
	};

	int i;
	CGMutablePathRef path = NULL;
	CFRange currentRange;

	CGContextSaveGState(context);

	// first render using CTFrameDraw, that's the easiest way.
	
	currentRange = CFRangeMake(0, 0);
	for (i = 0; i < 2; i++)
	{
		path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, frameBounds[i]);

		CTFrameRef frameRef = CTFramesetterCreateFrame(setter1, currentRange, path, NULL);
		require(frameRef != NULL, CTFramesetterCreateFrame);

		CFRelease(path); path = NULL;

		// CoreText is drawing using the Quartz coordinate system (positive y up)
		// but the HIView architecture has conveniently modified the context matrix so
		// that we live in a HIToolbox coordinate system (positive y down)
		// we thus need to invert once again the context matrix so that CoreText is happy.
		CGContextTranslateCTM(context, 0, -frameBounds[i].origin.y-frameBounds[i].size.height);

		CTFrameDraw(frameRef, context);

		// grab the range that covered the string and create the range
		currentRange = CTFrameGetVisibleStringRange(frameRef);
		currentRange.location += currentRange.length;
		currentRange.length = 0;
		CFRelease(frameRef);
		
		// if we've hit the end of the string, break out early
		if (currentRange.location == unicodeCharLength1) break;
	}

	CGContextRestoreGState(context);

	// second render using CTLineDraw, that's the most flexible way.
	// code below is for handling the single space / double space in blue gray color
	
	currentRange = CFRangeMake(0, 0);
	for (i = 2; i < 4; i++)
	{
		HIRect pathFrame = frameBounds[i];
		if (!singleSpace)
			pathFrame.size.height /= 2;

		path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, pathFrame);

		CTFrameRef frameRef = CTFramesetterCreateFrame(setter2, currentRange, path, NULL);
		require(frameRef != NULL, CTFramesetterCreateFrame);

		CFRelease(path); path = NULL;

		// CoreText is drawing using the Quartz coordinate system (positive y up)
		// but the HIView architecture has conveniently modified the context matrix so
		// that we live in a HIToolbox coordinate system (positive y down)
		// we thus need to invert once again the context matrix so that CoreText is happy.
		CGContextTranslateCTM(context, 0, -frameBounds[i].origin.y-frameBounds[i].size.height);

		// instead of just calling CTFrameDraw, we simply have to iterate over the lines
		// and draw each one. That's not too complicate.
		CGPoint penPosition;
		penPosition.y = frameBounds[i].origin.y + frameBounds[i].size.height;
		
		// grab the lines
		CFArrayRef lineArray = CTFrameGetLines(frameRef);
		require(lineArray != NULL, CTFrameGetLines);
		
		CFIndex j = 0, lineCount = CFArrayGetCount(lineArray);
		for ( ; j < lineCount; j++ )
		{
			CTLineRef currentLine = (CTLineRef)CFArrayGetValueAtIndex(lineArray, j);
			
			CGFloat ascent, descent, leading;
			CTLineGetTypographicBounds(currentLine, &ascent, &descent, &leading);
			double penOffset = CTLineGetPenOffsetForFlush(currentLine, 0, frameBounds[i].size.width);
			penPosition.x = frameBounds[i].origin.x + penOffset;

			if (singleSpace)
				penPosition.y -= ascent;
			else
				penPosition.y -= 2 * ascent;

			CGContextSetTextPosition(context, penPosition.x, penPosition.y);
			CTLineDraw(currentLine, context);			

			if (singleSpace)
				penPosition.y -= ( descent + leading );
			else
				penPosition.y -= 2 * ( descent + leading );
		}

		// grab the range that covered the string and create the range
		currentRange = CTFrameGetVisibleStringRange(frameRef);
		currentRange.location += currentRange.length;
		currentRange.length = 0;
		CFRelease(frameRef);
		
		// if we've hit the end of the string, break out early
		if (currentRange.location == unicodeCharLength2) break;
	}

GetWindowProperty:
GetControlOwner:
CTFrameGetLines:
CTFramesetterCreateFrame:
CTFramesetterCreateWithAttributedString:

	if (path != NULL) CFRelease(path);

GetEventParameter:

	return status;
}

/*****************************************************
*
* AddingStyleAttributes(inAttrString, outMutAttrString)
*
* Purpose:  convenience function to add some styles to an attributed string
*
*    Note:  the attributed string inAttrString is released by this function. Retain it if you want to keep it around.
*
* Returns:  OSStatus    - error code (0 == no error) 
*/
static OSStatus AddingStyleAttributes( CFAttributedStringRef inAttrString, CFMutableAttributedStringRef * outMutAttrString )
{
    OSStatus status = coreFoundationUnknownErr;
	
	CTFontRef times24Font = CTFontCreateWithName(CFSTR("Times"), 24.0, NULL);
	require(times24Font != NULL, CTFontCreateWithName);

	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[] = { 1.0, 0.0, 0.0, 0.8 };
	CGColorRef red = CGColorCreate(rgbColorSpace, components);
	CGColorSpaceRelease(rgbColorSpace);

	SInt32 one = 1;
	CFNumberRef underline = CFNumberCreate(NULL, kCFNumberSInt32Type, &one);	

	float half = 0.5;
	CFNumberRef weight = CFNumberCreate(NULL, kCFNumberFloatType, &half);	

	CFMutableAttributedStringRef mutAttrString = CFAttributedStringCreateMutableCopy(NULL, 0, inAttrString);
	CFRelease(inAttrString);
	require(mutAttrString != NULL, CFAttributedStringCreateMutableCopy);

#if 0
	//
	// First method: adding the styles in a dictionary, applying the dictionary to a range of text
	//
	CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(NULL, 1, NULL, NULL);
	require(styleDict != NULL, CFDictionaryCreateMutable);
	
	CFDictionaryAddValue(styleDict, kCTFontAttributeName, times24Font);

	CFAttributedStringSetAttributes(mutAttrString, CFRangeMake(189+6, 21), styleDict, false);
	CFRelease(styleDict);

#else
	//
	// Second method: adding each style to a range of text
	//
	CFAttributedStringSetAttribute(mutAttrString, CFRangeMake(189+6, 21), kCTFontAttributeName, times24Font);
	CFAttributedStringSetAttribute(mutAttrString, CFRangeMake(189+21, 21), kCTForegroundColorAttributeName, red);
	CFAttributedStringSetAttribute(mutAttrString, CFRangeMake(189+39, 21), kCTUnderlineStyleAttributeName, underline);
	CFAttributedStringSetAttribute(mutAttrString, CFRangeMake(189+39, 21), kCTFontWeightTrait, weight);

#endif
	
	CFRelease(times24Font);
	CFRelease(red);
	CFRelease(underline);
	CFRelease(weight);
	
	status = noErr;

CFAttributedStringCreateMutableCopy:
CFDictionaryCreateMutable:
CTFontCreateWithName:

	if (outMutAttrString != NULL) *outMutAttrString = mutAttrString;

	return status;
}

/*****************************************************
*
* AddingOtherStyleAttributes(inAttrString, outMutAttrString)
*
* Purpose:  convenience function to add some styles (blue gray color) to an attributed string
*
*    Note:  the attributed string inAttrString is released by this function. Retain it if you want to keep it around.
*
* Returns:  OSStatus    - error code (0 == no error) 
*/
static OSStatus AddingOtherStyleAttributes( CFAttributedStringRef inAttrString, CFMutableAttributedStringRef * outMutAttrString )
{
    OSStatus status = coreFoundationUnknownErr;

	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[] = { 0.3, 0.3, 1.0, 1.0 };
	CGColorRef blueGray = CGColorCreate(rgbColorSpace, components);
	CGColorSpaceRelease(rgbColorSpace);

	CFMutableAttributedStringRef mutAttrString = CFAttributedStringCreateMutableCopy(NULL, 0, inAttrString);
	CFRelease(inAttrString);
	require(mutAttrString != NULL, CFAttributedStringCreateMutableCopy);

	CFAttributedStringSetAttribute(mutAttrString, CFRangeMake(0, CFAttributedStringGetLength(mutAttrString)), kCTForegroundColorAttributeName, blueGray);
	CFRelease(blueGray);
	
	status = noErr;

CFAttributedStringCreateMutableCopy:

	if (outMutAttrString != NULL) *outMutAttrString = mutAttrString;

	return status;
}
