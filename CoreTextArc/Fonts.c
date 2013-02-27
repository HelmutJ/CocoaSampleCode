/*
 
 File: Fonts.h
 
 Abstract: Defines utility functions for interacting with fonts in the
 application.
 
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

#include "Fonts.h"
#include "ArcView.h"

// Change the font based on the font selection event from the Fonts window. 
void ChangeFont(EventRef inEvent, HIWindowRef window)
{
	CTFontDescriptorRef	descriptor, newDescriptor;
	CGFloat				size;
	
	OSStatus			err;
	ArcView				*arcView;
	
	// Use the front window if none specified.
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	arcView = GetArcViewForWindow(window);
	
	// Get the original font descriptor from the view
	descriptor = CTFontCopyFontDescriptor(ArcViewGetFont(arcView));
	size = CTFontGetSize(ArcViewGetFont(arcView));

	err = GetEventParameter(inEvent, kEventParamCTFontDescriptor, typeCTFontDescriptorRef, NULL, sizeof(newDescriptor), NULL, &newDescriptor);
	if (err == noErr && newDescriptor != NULL) {
		CFDictionaryRef newAttributes = CTFontDescriptorCopyAttributes(newDescriptor);
		
		// Merge the changes from the font panel with our current font. The font panel is smart enough to provide the necessary items to update the font correctly, and CoreText merges the necessary attributes such as variations and features.
		newDescriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, newAttributes);
		
		CFRelease(newAttributes);
		CFRelease(descriptor);
		descriptor = newDescriptor;
	}	// Create our new font from the descriptor
    
	if (descriptor != NULL) {
		CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, 0., NULL);
		
		// Set the font to the view
		ArcViewSetFont(arcView, font);
		
		CFRelease(descriptor);
		CFRelease(font);
	}
}

// Toggles the specified trait of the font for the view in the specified window.
void ToggleFontTrait(HIWindowRef window, CTFontSymbolicTraits trait) 
{
	ArcView					*arcView;
	CTFontSymbolicTraits	origTraits;
	CTFontRef				convertedFont;
	CTFontRef				font;
	
	// Use the front window if none specified
	if (window == NULL)
		window = FrontNonFloatingWindow();
	
	arcView = GetArcViewForWindow(window);
	
	// Get the current font and traits
	font = ArcViewGetFont(arcView);
	origTraits = CTFontGetSymbolicTraits(font);
	
	// Add or remove the trait depending on whether the font currently has it or not. Note that the mask is always the trait(s) we are modifying and the trait value is the value we want to assign to the traits. Traits are a bitmask.
	if ((origTraits & trait) == 0) {
		convertedFont = CTFontCreateCopyWithSymbolicTraits(font, 0., NULL,  trait, trait);
	} else {
		convertedFont = CTFontCreateCopyWithSymbolicTraits(font, 0., NULL,  0, trait);
	}
	// If we got a new font, set it to the view
	if (convertedFont != NULL) {
		ArcViewSetFont(arcView, convertedFont);
		
		CFRelease(convertedFont);
	}
}

// Check to see if the font can toggle the specified trait. This is accomplished by attempting to switch the trait's value to the opposite of the current value. 
Boolean CanToggleFontTrait(CTFontRef font, CTFontSymbolicTraits trait) 
{
	Boolean					result = false;
	CTFontSymbolicTraits	origTraits;
	CTFontRef				convertedFont;
	
	// Get the original traits
	origTraits = CTFontGetSymbolicTraits(font);
	
	// Try to add or remove the trait depending on whether the font currently has it or not. Note that the mask is always the trait(s) we are modifying and the trait value is the value we want to assign to the traits. Traits are a bitmask.
	if ((origTraits & trait) == 0) {
		convertedFont = CTFontCreateCopyWithSymbolicTraits(font, 0., NULL,  trait, trait);
	} else {
		convertedFont = CTFontCreateCopyWithSymbolicTraits(font, 0., NULL,  0, trait);
	}
	if (convertedFont != NULL) {
		// Success, release the font and return true
		CFRelease(convertedFont);
		result = true;
	}
	return result;
}


