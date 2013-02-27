/*
 
 File: main.c
 
 Abstract: //	This has the main function which creates the windows,
		   //   and installs the handlers for drawing and updating the windows.
 
 Version: 1.0
 
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
 
 Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 
 */ 

#include <Carbon/Carbon.h>
#include <DrawProcs.h>



/*
------------------------------------------------------------------------------
    BoundsChangedEventHandler
	If the windows bounds change force a complete re-draw.
------------------------------------------------------------------------------
	*/

static OSStatus BoundsChangedEventHandler (EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData)
{
 	OSStatus err = CallNextEventHandler (inHandler, inEvent);
	
	if(GetEventKind (inEvent) == kEventControlBoundsChanged)
	   {
			// Force a complete redraw
			(void) HIViewSetNeedsDisplay ((HIViewRef)inUserData, TRUE);
	   }

    return err;
}

/*
------------------------------------------------------------------------------
    CreateWindowWithDrawProc
	
------------------------------------------------------------------------------
	*/

static OSStatus  CreateWindowWithDrawProc (IBNibRef nib, CFStringRef title, EventHandlerProcPtr drawProc, Boolean dynamicContent)
{
    WindowRef    window;
    HIViewRef    view;
    CGContextRef context;
	
	// Create the window from the MainWindow in the nib as a template
    OSStatus err = CreateWindowFromNib (
										nib, 
										CFSTR("MainWindow"), 
										&window
										);

    if (!err) 
		 {
		 
        /* Get the window's content view and install its draw handler.
        We assume this is a compositing window. */	
        HIViewFindByID (
						HIViewGetRoot (window), 
						kHIViewWindowContentID, 
						&view
						);
		
		// We have the root view, so setup a content pane's drawing event handler.
        if (!err)  {
						
				// The event to register for is the kEventControlDraw event of the 
				// kEventClassControl class
				static EventTypeSpec drawEvents[] = {
					 { kEventClassControl, kEventControlDraw },
            };
			
			
			//  Install the draw event handler that will re-draw the windows content if necessary
            InstallEventHandler (
								 GetControlEventTarget (view),
								 NewEventHandlerUPP (drawProc),
								 GetEventTypeCount (drawEvents),
								 drawEvents,
								 (void*)view,
								 NULL
								 );
		}

		// If the content is dynamic based on its bounds
		// then we will setup a handler that causes a redraw
		// when the windows bounds change
		if(dynamicContent && view)  {
				// The event to register for is the kEventControlBoundsChanged event of the 
				// kEventClassControl class
				static EventTypeSpec boundsChangedEvent [] = {
					 { kEventClassControl, kEventControlBoundsChanged },
            };
			
			// Install the bounds changed event handler with an event handler that forces
			// a re-draw of the entire window.
            InstallEventHandler (
								 GetControlEventTarget (view),
								 NewEventHandlerUPP (BoundsChangedEventHandler),
								 GetEventTypeCount (boundsChangedEvent),
								 boundsChangedEvent,
								 (void*)view,
								 NULL
								 );
		}

		//  Set the windows title
        SetWindowTitleWithCFString (window, title);		
		
		// Tile the window releative to the last window
		RepositionWindow(window,NULL,kWindowCascadeOnMainScreen);

		// Show the window
		ShowWindow (window);

	}

    return err;
}

/*
------------------------------------------------------------------------------
    The Samples main entery point.
------------------------------------------------------------------------------
	*/

int main(int argc, char* argv[])
{
    IBNibRef 		nibRef;    
    OSStatus		err;

    // Create a Nib reference passing the name of the nib file (without the .nib extension)
    // CreateNibReference only searches into the application bundle.
    err = CreateNibReference(CFSTR("main"), &nibRef);
    require_noerr( err, CantGetNibRef );
    
    // Once the nib reference is created, set the menu bar. "MainMenu" is the name of the menu bar
    // object. This name is set in InterfaceBuilder when the nib is created.
    err = SetMenuBarFromNib(nibRef, CFSTR("MenuBar"));
    require_noerr( err, CantSetMenuBar );
    
	// Create a window using the ArcsDrawEventHandler HIView draw procedure that doesn't force
	// a redraw if the window is resized.
	err = CreateWindowWithDrawProc (nibRef, CFSTR("Arcs"), ArcsDrawEventHandler, false);
	require_noerr( err, CantCreateWindow );

	// Create a window using the OvalsDrawEventHandler HIView draw procedure that doesn't force
	// a redraw if the window is resized.
	err = CreateWindowWithDrawProc (nibRef, CFSTR("Ovals"), OvalsDrawEventHandler, false);
	require_noerr( err, CantCreateWindow );

	// Create a window using the RectanglesDrawEventHandler HIView draw procedure that doesn't force
	// a redraw if the window is resized.
	err = CreateWindowWithDrawProc (nibRef, CFSTR("Rectangles"), RectanglesDrawEventHandler, false);
	require_noerr( err, CantCreateWindow );

	// Create a window using the OvalTeenDrawEventHandler HIView draw procedure that forces
	// a redraw if the window is resized since the content is dynamic.
	err = CreateWindowWithDrawProc (nibRef, CFSTR("Ovalteen"), OvalTeenDrawEventHandler, true);
	require_noerr( err, CantCreateWindow );
	
    // We don't need the nib reference anymore.
    DisposeNibReference(nibRef);
    
    // Call the event loop
    RunApplicationEventLoop();

CantCreateWindow:
CantSetMenuBar:
CantGetNibRef:
	return err;
}

