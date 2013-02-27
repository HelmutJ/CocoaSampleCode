/*
 
  File: UIHandling.c
  
  Abstract: Implementation of Carbon UI portion of sample code.
  
  Version: <1.0>
  
  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
  Computer, Inc. ("Apple") in consideration of your agreement to the
  following terms, and your use, installation, modification or
  redistribution of this Apple software constitutes acceptance of these
  terms.  If you do not agree with these terms, please do not use,
  install, modify or redistribute this Apple software.
  
  In consideration of your agreement to abide by the following terms, and
  subject to these terms, Apple grants you a personal, non-exclusive
  license, under Apple's copyrights in this original Apple software (the
  "Apple Software"), to use, reproduce, modify and redistribute the Apple
  Software, with or without modifications, in source and/or binary forms;
  provided that if you redistribute the Apple Software in its entirety and
  without modifications, you must retain this notice and the following
  text and disclaimers in all such redistributions of the Apple Software. 
  Neither the name, trademarks, service marks or logos of Apple Computer,
  Inc. may be used to endorse or promote products derived from the Apple
  Software without specific prior written permission from Apple.  Except
  as expressly stated in this notice, no other rights or licenses, express
  or implied, are granted by Apple herein, including but not limited to
  any patent rights that may be infringed by your derivative works or by
  other works in which the Apple Software may be incorporated.
  
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
  
  Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/  

#include <Carbon/Carbon.h>
#include "UIHandling.h"
#include "NavServicesHandling.h"
#include "AppDrawing.h"
#include "DoPrinting.h"

/* Constants */
#define kMyHIViewSignature 'blDG'
#define kMyHIViewFieldID    128


/* Private Prototypes */
static OSStatus myDrawEventHandler(EventHandlerCallRef myHandler, EventRef event, void *userData);
static OSStatus myDoAppCommandProcess(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData);
static void DoAboutBox();


/* Global Data */
static OSType gCurrentCommand = kCommandStrokedAndFilledRects;
static WindowRef gWindowRef = NULL;
static HIViewRef gMyHIView = NULL;
static PMPageFormat gPageFormat = NULL;

int main(int argc, char* argv[])
{
    IBNibRef 		nibRef;
    
    OSStatus		err;
    static const HIViewID	kMyViewID = { kMyHIViewSignature,  kMyHIViewFieldID };      
    static const EventTypeSpec 	kMyViewEvents[] = { kEventClassControl, kEventControlDraw };	
    static const EventTypeSpec 	kMyCommandEvents[] = { kEventClassCommand, kEventCommandProcess };	

    // Create a Nib reference passing the name of the nib file (without the .nib extension)
    // CreateNibReference only searches into the application bundle.
    err = CreateNibReference(CFSTR("main"), &nibRef);
    require_noerr( err, CantGetNibRef );
    
    // Once the nib reference is created, set the menu bar. "MainMenu" is the name of the menu bar
    // object. This name is set in InterfaceBuilder when the nib is created.
    err = SetMenuBarFromNib(nibRef, CFSTR("MenuBar"));
    require_noerr( err, CantSetMenuBar );
    
    // Then create a window. "MainWindow" is the name of the window object. This name is set in 
    // InterfaceBuilder when the nib is created.
    err = CreateWindowFromNib(nibRef, CFSTR("MainWindow"), &gWindowRef);
    require_noerr( err, CantCreateWindow );

    // We don't need the nib reference anymore.
    DisposeNibReference(nibRef);

    // Get the HIView associated with the window.
    HIViewFindByID( HIViewGetRoot( gWindowRef ), kMyViewID, &gMyHIView );
			     
    // Install the event handler for the HIView.				
    err = HIViewInstallEventHandler(gMyHIView, 
				    NewEventHandlerUPP (myDrawEventHandler), 
				    GetEventTypeCount(kMyViewEvents), 
				    kMyViewEvents, 
				    (void *) gMyHIView, 
				    NULL); 


    // Install the handler for the menu commands.
    InstallApplicationEventHandler(NewEventHandlerUPP(myDoAppCommandProcess), GetEventTypeCount(kMyCommandEvents), 
						kMyCommandEvents, NULL, NULL);

    // Initialize the current drawing command menu item
    SetMenuCommandMark(NULL, gCurrentCommand, checkMark);
        
    // The window was created hidden so show it.
    ShowWindow( gWindowRef );
    
    // Call the event loop
    RunApplicationEventLoop();

CantCreateWindow:
CantSetMenuBar:
CantGetNibRef:
	return err;
}


static OSStatus myDrawEventHandler(EventHandlerCallRef myHandler, EventRef event, void *userData)
{
	OSStatus status = noErr;
	CGContextRef context;
	HIRect		bounds;

	// Get the CGContextRef. This context is only valid to draw to during the execution of this
	// event handler.
	status = GetEventParameter (event, kEventParamCGContextRef, 
					typeCGContextRef, NULL, 
					sizeof (CGContextRef),
					NULL,
					&context);

	if(status != noErr){
	    fprintf(stderr, "Got error %d getting the context!\n", status);
	    return status;
	}		
						
	// Get the bounding rectangle.
	HIViewGetBounds ((HIViewRef) userData, &bounds);
	
	// Flip the coordinates by translating and scaling. This produces a
	// coordinate system that matches the Quartz default coordinate system
	// with the origin in the lower-left corner with the y axis pointing up.
	CGContextTranslateCTM(context, 0, bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	myDispatchDrawing(context, gCurrentCommand);
					
	return status;
   
}

static OSType printableCommandFromCommand(OSType command)
{
    // Don't use pre-rendered drawing when printing or exporting data.
    if(command == kCommandDoCGLayer)
	return kCommandDoUncachedDrawing;
    
    return command;
}

static OSStatus myDoAppCommandProcess(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
{
#pragma unused (nextHandler, userData)
    HICommand  aCommand;
    OSStatus   result = eventNotHandledErr;

    GetEventParameter(theEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(HICommand), NULL, &aCommand);
    
    switch (aCommand.commandID){
	case kCommandStrokedAndFilledRects:
	case kCommandAlphaRects:
	case kCommandSimpleClip:
	case kCommandDrawImageFile:
	case kCommandDoUncachedDrawing:
	case kCommandDoCGLayer:
	
	    SetMenuCommandMark(NULL, gCurrentCommand, noMark);
	    gCurrentCommand = aCommand.commandID;
	    SetMenuCommandMark(NULL, gCurrentCommand, checkMark);
	    if(gMyHIView){
		HIViewSetNeedsDisplay(gMyHIView, true);
	    }
	    result = noErr;
	    break;

	case kHICommandPageSetup:
	    if(gPageFormat == NULL)
		gPageFormat = CreateDefaultPageFormat();
	    
	    if(gPageFormat)
		(void)DoPageSetup(gPageFormat);
	    
	    result = noErr;
	    break;

	case kHICommandPrint:
	    if(gPageFormat == NULL)
		gPageFormat = CreateDefaultPageFormat();
	    
	    if(gPageFormat)
		(void)DoPrint(gPageFormat, printableCommandFromCommand(gCurrentCommand));

	    result = noErr;
	    break;

	case kHICommandAbout:
	    DoAboutBox();
	    result = noErr; 
	    break;

	case kCommandExportPDF:
	    if(gWindowRef) // gUseQTForExport and dpi are ignored for PDF export.
		(void)DoExport(gWindowRef, printableCommandFromCommand(gCurrentCommand), exportTypePDF);
		break;

	case kCommandExportPNG:
		if(gWindowRef)
			(void)DoExport(gWindowRef, printableCommandFromCommand(gCurrentCommand), exportTypePNG);
		break;

	case kHICommandQuit:
		QuitApplicationEventLoop();
		result = noErr;
		break;

	default:
		break;
    }
    HiliteMenu(0);
    return result;
}

static void DoStandardAlert(CFStringRef alertTitle, CFStringRef alertText)
{
    AlertStdCFStringAlertParamRec	param;
    DialogRef			dialog;
    OSStatus			err;
    DialogItemIndex			itemHit;
    
    GetStandardAlertDefaultParams( &param, kStdCFStringAlertVersionOne );
    
    param.movable = true;
    
    err = CreateStandardAlert( kAlertNoteAlert, alertText, NULL, &param, &dialog );
    if(err){
	fprintf(stderr, "Can't create alert!\n");
	    return;
    }

    if(alertTitle)
	SetWindowTitleWithCFString( GetDialogWindow( dialog ), alertTitle);

    RunStandardAlert( dialog, NULL, &itemHit );
    
    return;
}


static void DoAboutBox()
{	
    CFStringRef alertMessage = CFCopyLocalizedString(kAboutBoxStringKey, NULL);
    CFStringRef alertTitle = CFCopyLocalizedString(kAboutBoxTitleKey, NULL);

    if (alertMessage != NULL && alertTitle != NULL)
    {
	DoStandardAlert(alertTitle, alertMessage);
    }
    if(alertMessage)
	CFRelease(alertMessage);
    
    if(alertTitle)
	CFRelease(alertTitle);
}

void DoErrorAlert(OSStatus status, CFStringRef errorFormatString)
{	
    if ((status != noErr) && (status != kPMCancel))           
    {
	CFStringRef formatStr = NULL;
	CFStringRef printErrorMsg = NULL;

        formatStr =  CFCopyLocalizedString(errorFormatString, NULL);	
	if (formatStr != NULL){
            printErrorMsg = CFStringCreateWithFormat(        
				NULL, NULL, 
				formatStr, status);
            if (printErrorMsg != NULL)
            {
		DoStandardAlert(NULL, printErrorMsg);
                CFRelease (printErrorMsg);                     
	    }
	    CFRelease (formatStr);                             
        }
    }
}
