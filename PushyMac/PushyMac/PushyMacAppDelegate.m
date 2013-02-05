/*
     File: PushyMacAppDelegate.m
 Abstract: Demonstrates registering for and receiving push notifications.
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

#include <AudioToolbox/AudioToolbox.h>
#import "PushyMacAppDelegate.h"

@implementation PushyMacAppDelegate

@synthesize window;

- (void)downloadDataFromProvider
{
	// Real apps would connect to the provider and download any waiting data.
	
	// Apps typically check in with the provider when first launched and
	// again when a push notification is received.
}


- (void)sendToProvider:(NSData *)message
{
	// Real apps would connect to the provider and send it the deviceToken.	
}


static void soundCompleted(SystemSoundID soundFileObject, void *clientData)
{
    // Clean up.
    if (soundFileObject != kSystemSoundID_UserPreferredAlert) {
        AudioServicesDisposeSystemSoundID(soundFileObject);
    }
}


- (void)playNotificationSound:(NSDictionary *)apsDictionary
{
    // App could implement its own preferences so the user could specify if they want sounds or alerts.
    // if (userEnabledSounds) 
    
    NSString *soundName = (NSString *)[apsDictionary valueForKey:(id)@"sound"];
    if (soundName != nil) {
        SystemSoundID soundFileObject   = kSystemSoundID_UserPreferredAlert;
        CFURLRef soundFileURLRef        = NULL;
        
        if ([soundName compare:@"default"] != NSOrderedSame) {
            // Get the main bundle for the app.
            CFBundleRef mainBundle = CFBundleGetMainBundle();
            
            // Get the URL to the sound file to play. The sound property's value is the full filename including the extension.
            soundFileURLRef = CFBundleCopyResourceURL(mainBundle,
                                                      (CFStringRef)soundName,
                                                      NULL,
                                                      NULL);
            
            // Create a system sound object representing the sound file.
            AudioServicesCreateSystemSoundID(soundFileURLRef,
                                             &soundFileObject);
            
            CFRelease(soundFileURLRef);
        }
        
        // Register a function to be called when the sound is done playing.
        AudioServicesAddSystemSoundCompletion(soundFileObject, NULL, NULL, soundCompleted, NULL);        
       
        // Play the sound.
        AudioServicesPlaySystemSound(soundFileObject);
    }
}


- (void)badgeApplicationIcon:(NSDictionary *)apsDictionary
{
    id badge = [apsDictionary valueForKey:@"badge"];
    NSDockTile *dockTile = [NSApp dockTile];
        
    if (badge != nil) {
        NSString *label = [NSString stringWithFormat:@"%@", badge];
        [dockTile setBadgeLabel:label];
    }
    else {
        [dockTile setBadgeLabel:nil];
    }
}


- (void)showNotificationAlert:(NSDictionary *)apsDictionary
{
    // App could implement its own preferences so the user could specify if they want sounds or alerts.
    // if (userEnabledAlerts) 

    // Only handles the simple case of the alert property having a simple string value.
    NSString *message = (NSString *)[apsDictionary valueForKey:(id)@"alert"];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // Do any desired processing here when the OK button is clicked.
    }

    [alert release];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // Register for push notifications.
    [NSApp registerForRemoteNotificationTypes:NSRemoteNotificationTypeBadge];
    
    NSString *name = [aNotification name];
    NSLog(@"didFinishLaunchingWithOptions: notification name %@", name);
        
    // Contact the provider and download the latest data.
    [self downloadDataFromProvider];
    
    // All items should now be downloaded from the provider, so reset the icon badge.
    // This assumes the badge is being used to show the number of new items not yet downloaded from the provider.
    //
    // If you're using the badge to show something else like the number of unread items, you might not want to
    // reset the badge here.
    [[NSApp dockTile] setBadgeLabel:nil];
}


- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"%@ with token = %@", NSStringFromSelector(_cmd), deviceToken);
    
    // Send the device token to the provider so it knows the app is ready to receive notifications.
    [self sendToProvider:deviceToken];
}


- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@ with error = %@", NSStringFromSelector(_cmd), error);
}


- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSDictionary *apsDictionary = [userInfo valueForKey:@"aps"];
    
    if (apsDictionary != nil) {
        // A notification arrived while the app was frontmost.
        
        // Play the sound.
        [self playNotificationSound:apsDictionary];
        
        // Badge the icon.
        [self badgeApplicationIcon:apsDictionary];
        
        // Show the alert.
        [self showNotificationAlert:apsDictionary];
        
        // Get updated content from provider.
        [self downloadDataFromProvider];
    }
}

@end
