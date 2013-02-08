/*
     File: PreferencesExample.c
 Abstract: Simple CFPreferences example program; reads/writes a preference.
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdlib.h>


// This function will print the provided arguments (printf style varargs) out to the console.
// Note that the CFString formatting function accepts "%@" as a way to display CF types.
// For types other than CFString and CFNumber, the result of %@ is mostly for debugging
// and can differ between releases and different platforms.

void show(CFStringRef formatString, ...) {
    CFStringRef resultString;
    CFDataRef data;
    va_list argList;

    va_start(argList, formatString);
    resultString = CFStringCreateWithFormatAndArguments(NULL, NULL, formatString, argList);
    va_end(argList);

    data = CFStringCreateExternalRepresentation(NULL, resultString, CFStringGetSystemEncoding(), '?');

    if (data != NULL) {
    	printf ("%.*s\n\n", (int)CFDataGetLength(data), CFDataGetBytePtr(data));
    	CFRelease(data);
    }
       
    CFRelease(resultString);
}


/* Read old high score, which is saved as a CFNumber under the key "High Score"; bump it up and save it.
*/
void simplePreferencesExample(void) {
    
    CFStringRef appName = CFSTR("A Game");
    CFStringRef highScoreKey = CFSTR("High Score");
    CFNumberRef value;
    int highScore;

    // First retrieve the previous value...

    // CFPreferencesCopyAppValue() and CFPreferencesSetAppValue() are the most straightforward way
    // for an app to read/write preferences that are per user and per app; they will apply on all 
    // machines (on which this user can log in, of course --- for users who are local to a machine,
    // the preferences will end up being restricted to that host). These functions also do a search 
    // through the various cases; if a preference has been set in a less-specific domain (for 
    // instance, "all apps"), its value will be retrieved with this call. This allows globally 
    // setting some preference values (which makes more sense for some preferences than others).

    // Note that you can read/write any "property list" type in preferences; these are
    // CFArray, CFDictionary, CFNumber, CFBoolean, CFData, and CFString.
    // This example just shows CFNumber.

    value = CFPreferencesCopyAppValue(highScoreKey, appName);   

    if (value) {
	// Numbers come out of preferences as CFNumbers.
	if (!CFNumberGetValue(value, kCFNumberIntType, &highScore)) highScore = 0;
	CFRelease(value);

	show(CFSTR("The old high score was %d."), highScore);
    } else {
	// No previous value
	show(CFSTR("There is no old high score."));
	highScore = 0;
    }

    highScore += 5;

    show(CFSTR("Recording new high score, %d"), highScore);

    value = CFNumberCreate(NULL, kCFNumberIntType, &highScore); 

    CFPreferencesSetAppValue(highScoreKey, value, appName);

    CFRelease(value);

    // Without an explicit synchronize, the saved values actually do not get written out.
    // If you are writing multiple preferences, you might want to sync only after the last one.
    // A preference panel might want to synchronize when the user hits "OK".
    // In some cases you might not want to sync at all until the app quits.
    // The AppKit automatically synchronizes on app termination, so Cocoa apps don't need to do this.

    (void)CFPreferencesAppSynchronize(appName);
}


int main (int argc, const char *argv[]) {
    simplePreferencesExample();
    
    return 0;
}


