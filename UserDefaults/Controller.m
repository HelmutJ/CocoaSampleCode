/*
     File: Controller.m
 Abstract:  Simple NSUserDefaults example program that reads/writes a preference and shows how to make a window's position and size persistent.
  Version: 1.2
 
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


#import "Controller.h"


@implementation Controller

#define defaultValue @"Default"
#define myKey @"My String"

/* Called when the app has finished launching and is ready to start running.
   This happens because in IB the delegate of the app is set to be this object.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    // One of the things we do is to read the last value recorded from userdefaults
    // and set that as the value of the textfield. We have a handle to the textfield
    // (myTextField) because it is set up as an outlet in InterfaceBuilder.

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults stringForKey:myKey];
    if (val == nil) val = defaultValue;
    [myTextField setStringValue:val];
    
    // Another thing we do is make the location of the default window also
    // get stored in defaults. This is handled simply handled by telling the window
    // what key to look for, and everything else is automatic!

    [myWindow setFrameAutosaveName:@"My Window"];
    
    // Now show the window... (By default we've set it in IB not to be visible at start)

    [myWindow makeKeyAndOrderFront:nil];
}


/* This method is called when a new value is entered into the textfield.
*/
- (void)textFieldAction:(id)sender {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val;

    // Get the new value from the textfield
    
    val = [myTextField stringValue];

    // If it's the default value, remove from preferences; otherwise set the new value
    // We don't need to do this, but it keeps preferences cleaner, and the default value
    // is more implicit this way (in case it ever changes, the old default value won't
    // have been hardwired).

    if ([val isEqualToString:defaultValue]) {
        [defaults removeObjectForKey:myKey];
    } else {
        [defaults setObject:val forKey:myKey];
    }

    // Note that we don't synchronize with the file system or anything; this will happen
    // when the app quits. There are times when an explicit synchronize might be necessary,
    // but often it's not. Synchronizing unecessarily can also be a performance issue.
}

@end
