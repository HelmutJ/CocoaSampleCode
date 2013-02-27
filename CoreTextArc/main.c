/*
 
 File: main.c
 
 Abstract: Implements application and window event handlers. Derived from
 Carbon C Application standard project.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
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
 
 Copyright (C) 2007 Apple Inc. All Rights Reserved.
 
 */ 
 
#include <Carbon/Carbon.h>
#include "ArcView.h"
#include "Controls.h"
#include "Fonts.h"

static OSStatus        AppEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon);
static OSStatus        HandleNew();
static OSStatus        WindowEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon);

static IBNibRef        sNibRef;

//--------------------------------------------------------------------------------------------
int main(int argc, char* argv[])
{
    OSStatus                    err;
    static const EventTypeSpec    kAppEvents[] =
    {
        { kEventClassCommand, kEventCommandProcess }
    };
	
	// Register our custom HIObject class before we load the nib
	verify_noerr(ArcViewRegisterClass());

    // Create a Nib reference, passing the name of the nib file (without the .nib extension).
    // CreateNibReference only searches into the application bundle.
    err = CreateNibReference(CFSTR("main"), &sNibRef);
    require_noerr(err, CantGetNibRef);
    
    // Once the nib reference is created, set the menu bar. "MainMenu" is the name of the menu bar
    // object. This name is set in InterfaceBuilder when the nib is created.
    err = SetMenuBarFromNib(sNibRef, CFSTR("MenuBar"));
    require_noerr(err, CantSetMenuBar);
	    
    // Install our handler for common commands on the application target
    InstallApplicationEventHandler(NewEventHandlerUPP(AppEventHandler),
                                    GetEventTypeCount(kAppEvents), kAppEvents,
                                    0, NULL);
    
    // Create a new window. A full-fledged application would do this from an AppleEvent handler
    // for kAEOpenApplication.
    HandleNew();
    
    // Run the event loop
    RunApplicationEventLoop();

CantSetMenuBar:
CantGetNibRef:
    return err;
}

//--------------------------------------------------------------------------------------------
static OSStatus
AppEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon)
{
    OSStatus    result = eventNotHandledErr;
    OSType		class = GetEventClass(inEvent);
	UInt32		kind = GetEventKind(inEvent);
	
    switch (class)
    {
        case kEventClassCommand:
        {
            HICommandExtended cmd;
            verify_noerr(GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(cmd), NULL, &cmd));
            
            switch (kind)
            {
                case kEventCommandProcess:
                    switch (cmd.commandID)
                    {
                        case kHICommandNew:
                            result = HandleNew();
                            break;
						default:
                            break;
                    }
                    break;
				default:
					break;
            }
            break;
        }   
        default:
            break;
    }
    
    return result;
}

//--------------------------------------------------------------------------------------------
DEFINE_ONE_SHOT_HANDLER_GETTER(WindowEventHandler)

//--------------------------------------------------------------------------------------------
static OSStatus
HandleNew()
{
    OSStatus                    err;
    HIWindowRef                 window;
	HIViewRef					view;
	HIViewID					viewID;
	
	// Window events
    static const EventTypeSpec	kWindowEvents[] =
    {
        { kEventClassCommand, kEventCommandProcess },
		{ kEventClassWindow, kEventWindowActivated },
		{ kEventClassMenu, kEventMenuEnableItems },
		{ kEventClassFont, kEventFontSelection }
    };
    
	// Control events
	static const EventTypeSpec kTextFieldEvents[] = 
	{
		{ kEventClassTextField, kEventTextAccepted },
		{ kEventClassTextField, kEventTextDidChange }
	};
	
    // Create a window. "MainWindow" is the name of the window object. This name is set in 
    // InterfaceBuilder when the nib is created.
    err = CreateWindowFromNib(sNibRef, CFSTR("MainWindow"), &window);
    require_noerr(err, CantCreateWindow);

    // Install a window event handler on the window. 
    InstallWindowEventHandler(window, GetWindowEventHandlerUPP(),
                               GetEventTypeCount(kWindowEvents), kWindowEvents,
                               window, (void *)window);
    	
	viewID.signature = kEditTextControlSignature;
	viewID.id = kEditTextControlID;
	
	// Get the control 
	err = HIViewFindByID(HIViewGetRoot(window), viewID, &view);
    require_noerr(err, CantGetControl);

	// Install a control event handler. We use the window handler for convenience as the control
	// is in the window and there is only one event.
	InstallControlEventHandler(view, GetWindowEventHandlerUPP(),
							    GetEventTypeCount(kTextFieldEvents), kTextFieldEvents,
							    view, (void *)view);
	
	// Initialize the text
	InitializeTextField(window);
	
	// Update the text in the window
	UpdateText(window);
	
	// Update the font for the window
	UpdateFontControls(window);
	UpdateFontPanel(window);

CantGetControl:
    // Position new windows in a staggered arrangement on the main screen
    RepositionWindow(window, NULL, kWindowCascadeOnMainScreen);
    
    // The window was created hidden, so show it
    ShowWindow(window);
    
CantCreateWindow:
    return err;
}

//--------------------------------------------------------------------------------------------
static OSStatus
WindowEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon)
{
    OSStatus    err = eventNotHandledErr;
    OSType class = GetEventClass(inEvent);
	UInt32 kind = GetEventKind(inEvent);
	
    switch (class)
    {
        case kEventClassCommand:
        {
            HICommandExtended cmd;
            verify_noerr(GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(cmd), NULL, &cmd));
			
			// Get the window for the control  in the command
			HIWindowRef window = HIViewGetWindow(cmd.source.control);
            
            switch (kind)
            {
                case kEventCommandProcess:
				{
                    switch (cmd.commandID)
                    {
                        // Add your own command-handling cases here
						case kHICommandBoldFont:
						{
							// Make the font bold
							ToggleFontTrait(window, kCTFontBoldTrait);
							// Update the font interface elements
							UpdateFontControls(window);
							UpdateFontPanel(window);
							err = noErr;	// Handled the event
							break;
						}
						case kHICommandItalicFont:
						{
							// Make the font italic
							ToggleFontTrait(window, kCTFontItalicTrait);
							// Update the font interface elements
							UpdateFontControls(window);
							UpdateFontPanel(window);
							err = noErr;	// Handled the event
							break;
						}
                        case kHICommandShowHideFontPanel:
						{
							// Update the font panel when it is displayed
							UpdateFontPanel(window);
							// Don't handle the event
							break;
						}
						// ArcView options
						case kHICommandShowGlyphBounds:
						{
							Boolean state = (HIViewGetValue(cmd.source.control) == kControlCheckBoxCheckedValue);
							ArcViewSetOptions(GetArcViewForWindow(window), kArcViewShowGlyphBoundsOption, state);
							err = noErr;	// Handled the event
							break;
						}
						case kHICommandShowLineMetrics:
						{
							Boolean state = (HIViewGetValue(cmd.source.control) == kControlCheckBoxCheckedValue);
							ArcViewSetOptions(GetArcViewForWindow(window), kArcViewShowLineMetricsOption, state);
							err = noErr;	// Handled the event
							break;
						}
						case kHICommandDimSubstitutedGlyphs:
						{
							Boolean state = (HIViewGetValue(cmd.source.control) == kControlCheckBoxCheckedValue);
							ArcViewSetOptions(GetArcViewForWindow(window), kArcViewDimSubstitutedGlyphsOption, state);
							err = noErr;	// Handled the event
							break;
						}
                        default:
                            break;
                    }
                    break;
				}
				default:
					break;
            }
            break;
        }
		case kEventClassWindow:
		{
			switch (kind) {
				case kEventWindowActivated:
				{
					HIWindowRef window;
					// Get the window from the event
					verify_noerr(GetEventParameter(inEvent, kEventParamDirectObject, typeWindowRef, NULL, sizeof(window), NULL, &window));
					
					// Update the text 
					UpdateText(window);
					// Update the font interfaces
					UpdateFontControls(window);
					UpdateFontPanel(window);
					break;
				}
				default:
					break;
			}
			break;
		}
		case kEventClassMenu:
		{
			switch (kind) {
				case kEventMenuEnableItems:
				{
					MenuRef menu;
					
					// Get the menu for the event
					verify_noerr(GetEventParameter(inEvent, kEventParamDirectObject, typeMenuRef, NULL, sizeof(menu), NULL, &menu));
					// Update the format menu. This will validate the font trait items, and swap the Show/Hide Fonts items.
					if (GetMenuID(menu) == kFormatMenuID) {
						UpdateFormatMenu(menu);
					}
					break;
				}
				default:
					break;
			}
			break;
		}
		case kEventClassFont:
		{
			switch (kind) {
				case kEventFontSelection:
				{
					// Change the font for the event
					ChangeFont(inEvent, (HIWindowRef)inRefcon);
					// Update the font interface
					UpdateFontControls((HIWindowRef)inRefcon);
					break;
				}
				default:
					break;
			}
			break;
		}
		case kEventClassTextField:
		{
			switch (kind) 
			{
				case kEventTextAccepted:
				{
					// Get the window from the control in the refcon
					HIWindowRef window = HIViewGetWindow((HIViewRef)inRefcon);
					// Update text on end editing
					UpdateText(window);
					break;
				}
				case kEventTextDidChange: 
				{
					// Get the window from the control in the refcon
					HIWindowRef window = HIViewGetWindow((HIViewRef)inRefcon);
					CFRange range;
					
					// Check to see if we have an inline hole. If there is an unconfirmed range, we have an inline hole and don't want to update the text until the text is confirmed.
					if (GetEventParameter(inEvent, kEventParamUnconfirmedRange, typeCFRange, NULL, sizeof(CFRange), NULL, &range) != noErr)
						UpdateText(window);
					break;
				}
				default:
					break;
			}
			break;
		}
        default:
            break;
    }
    
    return err;
}

