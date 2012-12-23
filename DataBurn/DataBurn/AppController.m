
/*
     File: AppController.m
 Abstract: Application delegate class illustrating how to setup and start a simple single folder data burn.
  Version: 2.0
 
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

#import "AppController.h"

#import <DiscRecording/DiscRecording.h>
#import <DiscRecordingUI/DiscRecordingUI.h>


@interface AppController () <NSWindowDelegate, NSOpenSavePanelDelegate>
@end


@implementation AppController
{
    BOOL burnInProgress;
}

/*
 App's done launching, put up the burn setup panel. If the user chooses burn, we'll start the burn, otherwise, just quit the app.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DRTrack *track = [self createTrack];
    
    if (track)
    {
        DRBurnSetupPanel *setupPanel = [DRBurnSetupPanel setupPanel];
        
        /*
         We'll be the delegate for the setup panel. This allows us to show off some of the customization you can do.
         */
        [setupPanel setDelegate:self];
        
        if ([setupPanel runSetupPanel] == NSOKButton)
        {
            DRBurnProgressPanel *progressPanel = [DRBurnProgressPanel progressPanel];
            
            [progressPanel setDelegate:self];
            
            /*
             Start the burn itself. This will put up the progress dialog and do all the nice pretty things that a happy app does.
             */
            [progressPanel beginProgressPanelForBurn:[setupPanel burnObject] layout:track];
            
            /*
             If you wanted to run this as a sheet you would have sent:
             [progressPanel beginProgressSheetForBurn:[bsp burnObject] layout:tracks modalForWindow:aWindow];
             */
        }
        else
        {
            [NSApp terminate:self];
        }
    }
    else
    {
        [NSApp terminate:self];
    }
}


- (DRTrack *)createTrack
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // Ask the user for the files to burn.
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setDelegate:self];
    [openPanel setTitle:@"Select a folder for your CD content."];
    [openPanel setPrompt:@"Select"];
    
    if ([openPanel runModal] == NSOKButton)
    {
        DRFolder *rootFolder = [DRFolder folderWithPath:[((NSURL *)[[openPanel URLs] objectAtIndex:0]) path]];
        
        return [DRTrack trackForRootFolder:rootFolder];
    }
    
    return nil;
}


- (BOOL) validateMenuItem:(id)sender
{
    if ([sender action] == @selector(terminate:))
    {
        return (burnInProgress == NO);        // No quitting while a burn is in progress.
    }
    else
    {
        return [super validateMenuItem:sender];
    }
}


#pragma mark Setup Panel Delegate Methods
/*
 We're implementing some of these setup panel delegate methods to illustrate what you could do to control a
 burn setup.
 */


/*
 This delegate method is called when a device is plugged in and becomes available for use. It's also called for each device connected to the machine when the panel is first shown.
 
 It's possible to query the device and ask it just about anything to determine if it's a device that should be used.
 
 Just return YES for a device you want and NO for those you don't.
 */
- (BOOL)setupPanel:(DRSetupPanel*)aPanel deviceCouldBeTarget:(DRDevice*)device
{
    if (NO) {
        /*
         This path shows how to filter devices bases on the properties of the device. For example, it's possible to limit the drives displayed to only those hooked up over FireWire, or converesely, you could NOT show drives if there was some reason to.
         */
        NSDictionary *deviceInfo = [device info];
        if ([[deviceInfo objectForKey:DRDevicePhysicalInterconnectKey] isEqualToString:DRDevicePhysicalInterconnectFireWire])
        {
            return YES;
        }
        else
        {
            return NO;
        }
        
    }
    return YES;
}

/*
 This delegate method is called whenever the state of the media changes and the setup panel is being displayed.
 
 When we get sent this we're going to do a little bit of work to try to play nice with the rest of the world, but it essentially comes down to "is it a CDR or CDRW" that we care about. We could also check to see if there's enough room for our data (maybe the user stuck in a mini 2" CD or we need an 80 min CD).
 This allows the delegate to determine if the media inserted in the device is suitable for whatever operation is to be performed. The delegate should return a string to be used in the setup panel to inform the user of the media status. If this method returns NO, the default button will be disabled.
 */
- (BOOL)setupPanel:(DRSetupPanel*)aPanel deviceContainsSuitableMedia:(DRDevice*)device promptString:(NSString**)prompt
{
    if (NO) {
        /*
         This path shows how to check to see what sort of media there is present in the drive. If it's not a CDR or CDRW we reject it. This prevents us from burning to a DVD.
         */
        NSString *mediaType = [[[device status] objectForKey:DRDeviceMediaInfoKey] objectForKey:DRDeviceMediaTypeKey];
        if ([mediaType isEqualToString:DRDeviceMediaTypeCDR] == NO && [mediaType isEqualToString:DRDeviceMediaTypeCDRW] == NO)
        {
            *prompt = @"That's not a writable CD!";
            return NO;
        }
    }
    /*
     OK everyone agrees that this disc is OK to be burned in this drive.
     We could also return our own OK, prompt string here, but we'll let the default all ready string do its job.
     */
    // *prompt = [NSString stringWithCString:"Let's roll!"];
    
    return YES;
}


#pragma mark Progress Panel Delegate Methods

/*
 Here we are setting up this nice little instance variable that prevents the app from quitting while a burn is in progress. This gets checked up in validateMenu: and we'll set it to NO in burnProgressPanelDidFinish:
 */
- (void)burnProgressPanelWillBegin:(NSNotification*)aNotification
{
    burnInProgress = YES;    // Keep the app from being quit from underneath the burn.
}


- (void)burnProgressPanelDidFinish:(NSNotification*)aNotification
{
    burnInProgress = NO;    // OK we can quit now.
}

/*
 Nothing fancy here. we just want to illustrate that it's possible for a delegate of the progress panel to alter how the burn is handled once it completes. You may want to put up your own dialog, sent a notification if you're in the background, or just ignore it no matter what.
 
 We'll just NSLog the fact it finished (for good or bad) and return YES to indicate that we didn't handle it ourselves and that the progress panel should continue on its merry way.
 */
- (BOOL)burnProgressPanel:(DRBurnProgressPanel*)theBurnPanel burnDidFinish:(DRBurn*)burn
{
    NSDictionary *burnStatus = [burn status];
    NSString *state = [burnStatus objectForKey:DRStatusStateKey];
    
    if ([state isEqualToString:DRStatusStateFailed])
    {
        NSDictionary *errorStatus = [burnStatus objectForKey:DRErrorStatusKey];
        NSString *errorString = [errorStatus objectForKey:DRErrorStatusErrorStringKey];
        
        NSLog(@"The burn failed (%@)!", errorString);
    }
    else
    {
        NSLog(@"The burn finished correctly.");
    }
    
    return YES;
}

@end
