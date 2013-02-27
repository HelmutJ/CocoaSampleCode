/*
 
 File: Controls.c
 
 Abstract: Defines utility functions for managing controls in the 
 application user interface.
 
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

#include "Controls.h"
#include "ArcView.h"

// Initializes the text field with the default localized string
void InitializeTextField(HIWindowRef window)
{
	CFStringRef string = CFCopyLocalizedString(CFSTR("Curvaceous Type"), CFSTR("Default string"));
	static HIViewID		viewID = { kEditTextControlSignature, kEditTextControlID };
	HIViewRef			view;
	OSStatus			err;
	
	// Use the front window if none specified
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	// Get the control
	err = HIViewFindByID(HIViewGetRoot(window), viewID, &view);
    require_noerr(err, CantGetControl);

	// Get the text from the control
	verify_noerr(HIViewSetText(view, string));

CantGetControl: ;
}

// Gets the current text from the edit text control in the specified window and sets it to the arc view. 
void UpdateText(HIWindowRef window) 
{
	static HIViewID		viewID = { kEditTextControlSignature, kEditTextControlID };
	HIViewRef			view;
	OSStatus			err;
	CFStringRef			string;
	
	// Use the front window if none specified
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	// Get the control
	err = HIViewFindByID(HIViewGetRoot(window), viewID, &view);
    require_noerr(err, CantGetControl);
	
	// Get the text from the control
	string = HIViewCopyText(view);
	
	if (string != NULL) {
		// Set the text to the arc view of the same window
		ArcView *arcView = GetArcViewForWindow(window);
		ArcViewSetString(arcView, string);
		
		CFRelease(string);
	}
	
CantGetControl: ;
}

// Keeps the font controls in sync with the current font. It's important when provided style controls (eg. Bold, Italic) as we are, that they are kept in sync with the font. If the current font cannot be made bold, then the bold control should be disabled. If it is bold, the control should be checked. Likewise for italic. We leave updates of the menu items to another function.
void UpdateFontControls(HIWindowRef window) 
{
	ArcView					*arcView;
	CTFontRef				font;
	CTFontSymbolicTraits	traits;
	HIViewRef				view;
	HIViewID				viewID;
	
	// If we weren't passed a window, use the front window
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	// Get the view for the window
	arcView = GetArcViewForWindow(window);
	
	// Get the current font and traits
	font = ArcViewGetFont(arcView);
	traits = CTFontGetSymbolicTraits(font);
	
	// Get the bold font checkbox control
	viewID.signature = kBoldFontControlSignature;
	viewID.id = kBoldFontControlID;
	verify_noerr(HIViewFindByID(HIViewGetRoot(window), viewID, &view));
	
	// Disable the bold checkbox if we can't toggle the trait
	HIViewSetEnabled(view, CanToggleFontTrait(font, kCTFontBoldTrait));

	// Set the value for the checkbox based on the current traits
	if ((traits & kCTFontBoldTrait) != 0)
		HIViewSetValue(view, kControlCheckBoxCheckedValue);
	else 
		HIViewSetValue(view, kControlCheckBoxUncheckedValue);
	
	// Get the italic font checkbox control
	viewID.signature = kItalicFontControlSignature;
	viewID.id = kItalicFontControlID;
	verify_noerr(HIViewFindByID(HIViewGetRoot(window), viewID, &view));
	
	// Disable the bold checkbox if we can't toggle the trait
	HIViewSetEnabled(view, CanToggleFontTrait(font, kCTFontItalicTrait));

	// Set the value for the checkbox based on the current traits
	if ((traits & kCTFontItalicTrait) != 0)
		HIViewSetValue(view, kControlCheckBoxCheckedValue);
	else 
		HIViewSetValue(view, kControlCheckBoxUncheckedValue);
}

enum {
	kShowFontsMenuItemIndex		= 1,
	kHideFontsMenuItemIndex		= 2,
	kBoldMenuItemIndex			= 3,
	kItalicMenuItemIndex		= 4
};

// Updates the font menu items in the Format menu to keep them in sync with the current font selection. We use two individual menu items to show and hide the Fonts window. Based on the visibility of the fonts window we hide one of thse items. Like UpdateFontControls we need to keep the bold and italic menu items in sync with the capabilities of the font.
void UpdateFormatMenu(MenuRef menu) 
{
	CTFontRef				font;
	ArcView *				arcView;
	CTFontSymbolicTraits	traits;
	
	// The menu is always based on the front most window
	arcView = GetArcViewForWindow(FrontNonFloatingWindow());
	assert(arcView != NULL);
	
	// Get the current font and traits
	font = ArcViewGetFont(arcView);
	traits = CTFontGetSymbolicTraits(font);
	
	if (FPIsFontPanelVisible()) {
		// Fonts window is visible. Hide "Show Fonts" and show "Hide Fonts"
		ChangeMenuItemAttributes(menu, kShowFontsMenuItemIndex, kMenuItemAttrHidden, 0);
		ChangeMenuItemAttributes(menu, kHideFontsMenuItemIndex, 0, kMenuItemAttrHidden);
	} else {
		// Fonts window is not visible. Show "Show Fonts" and hide "Hide Fonts"
		ChangeMenuItemAttributes(menu, kShowFontsMenuItemIndex, 0, kMenuItemAttrHidden);
		ChangeMenuItemAttributes(menu, kHideFontsMenuItemIndex, kMenuItemAttrHidden, 0);
	}
	
	// Check the menu item if the font has the bold trait
	CheckMenuItem(menu, kBoldMenuItemIndex, ((traits & kCTFontBoldTrait) != 0));

	// Disable the item if we can't toggle the bold trait
	if (!CanToggleFontTrait(font, kCTFontBoldTrait)) {
		ChangeMenuItemAttributes(menu, kBoldMenuItemIndex, kMenuItemAttrDisabled, 0);
	} else {
		ChangeMenuItemAttributes(menu, kBoldMenuItemIndex, 0, kMenuItemAttrDisabled);
	}
	
	// Check the menu item if the font has the italic trait
	CheckMenuItem(menu, kItalicMenuItemIndex, ((traits & kCTFontItalicTrait) != 0));

	// Disable the item if we can't toggle the italic trait
	if (!CanToggleFontTrait(font, kCTFontItalicTrait)) {
		ChangeMenuItemAttributes(menu, kItalicMenuItemIndex, kMenuItemAttrDisabled, 0);
	} else {
		ChangeMenuItemAttributes(menu, kItalicMenuItemIndex, 0, kMenuItemAttrDisabled);
	}
}

// Update the font panel with the currently selected font. It's important to do this when we activate the window and display the font panel. The act of calling SetFontInfoForSelection with the event target of the specified window is important to direct future font selection events to that window. This could be a specific control if we wanted to handle font selections on a control by control basis.
void UpdateFontPanel(HIWindowRef window)
{
	ArcView					*arcView;
	CTFontRef				font;
	CTFontDescriptorRef		descriptor;
	
	// Use the front window if none specified
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	// Get the arc view
	arcView = GetArcViewForWindow(window);
	
	// Get the current font
	font = ArcViewGetFont(arcView);
	
	descriptor = CTFontCopyFontDescriptor(font);
	verify(descriptor != NULL);
	
	// Set the font to the font panel, specifying the window as the event target
	verify_noerr(SetFontInfoForSelection(kFontSelectionCoreTextType, 1, (void *)&descriptor, GetWindowEventTarget(window)));
	CFRelease(descriptor);
}

