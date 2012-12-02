
/*
     File: AppDelegate.m
 Abstract: Application delegate that configures the sharing buttons and acts as a controller to manage the sharing services.
 
  Version: 1.0
 
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

#import "AppDelegate.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSImageView *imageView;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

/*
 Outlets to the service buttons so they can be appropriately configured with service images etc.
 Note also that sharing services should be invoked on mouse down, not mouse up.
 */
@property (weak) IBOutlet NSButton *tweetButton;
@property (weak) IBOutlet NSButton *emailButton;
@property (weak) IBOutlet NSButton *chooseServiceButton;
@property (weak) IBOutlet NSButton *chooseFromTextFieldButton;
@property (weak) IBOutlet NSButton *includeImageSwitch;

@property (strong) IBOutlet NSWindow *window;


@property (strong) NSSharingService *tweetSharingService;
@property (strong) NSSharingService *emailSharingService;

@end



@implementation AppDelegate

/*
 Configure the application window and the shaing services.
 */
@synthesize includeImageSwitch;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    /*
     Get the Twitter sharing service.
     Update the tweet button's title and icons to display the name of the service and the corresponding images.
     Set the service's delegate to self.
     
     Use canPerformWithItems: to test whether the service is enabled. If it isn't, disable the button.
    */
    NSSharingService *tweetSharingService = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    self.tweetButton.title = tweetSharingService.title;
    self.tweetButton.image = tweetSharingService.image;
    
    self.tweetButton.alternateImage = tweetSharingService.alternateImage;
    
    if ([tweetSharingService canPerformWithItems:nil]) {
        [self.tweetButton setEnabled:YES];
    }
    else {
        [self.tweetButton setEnabled:NO];
    }

    tweetSharingService.delegate = self;

    self.tweetSharingService = tweetSharingService;
    
    /*
     Get the Email sharing service.
     Update the email button's title and icons to display the name of the service and the corresponding images.
     Set the service's delegate to self.
    */
    NSSharingService *emailSharingService = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    self.emailButton.title = emailSharingService.title;
    self.emailButton.image = emailSharingService.image;
    self.emailButton.alternateImage = emailSharingService.alternateImage;
    
    emailSharingService.delegate = self;
    
    self.emailSharingService = emailSharingService;
    
    self.imageView.image = [NSImage imageNamed:@"egg"];
    self.textView.string = @"Hello, world.";
    
    /*
     Buttongs triggering the Sharing Service Picker should be invoked on mouse down, not mouse up.
     */
    [self.chooseServiceButton sendActionOn:NSLeftMouseDownMask];
    [self.chooseFromTextFieldButton sendActionOn:NSLeftMouseDownMask];
}


- (IBAction)shareUsingEmail:(id)sender
{    
    /*
     Create the array of items to share.
     Start with just the content of the text view. If there's an image, add that too.
     */
    NSMutableArray *shareItems = [[NSMutableArray alloc] initWithObjects:[self.textView string], nil];
    
    NSImage *image = [self.imageView image];
    if (image) {
        [shareItems addObject:image];
    }
    
    /*
     Perform the service using the array of items.
     */
    [self.emailSharingService performWithItems:shareItems];
}


- (IBAction)shareUsingTwitter:(id)sender
{
    /*
     Create the array of items to share.
     Start with just the content of the text view. If there's an image, add that too.
     */
    NSMutableArray *shareItems = [[NSMutableArray alloc] initWithObjects:[self.textView string], nil];
    
    if ([self.includeImageSwitch state] == NSOnState) {
        NSImage *image = [self.imageView image];
        if (image) {
            [shareItems addObject:image];
        }
    }    
    /*
     Perform the service using the array of items.
     */
    [self.tweetSharingService performWithItems:shareItems];
}


- (NSWindow *)sharingService:(NSSharingService *)sharingService sourceWindowForShareItems:(NSArray *)items sharingContentScope:(NSSharingContentScope *)sharingContentScope
{
    /*
     The window for all the services is self's window.
     The other methods are useful if you share an item which already has a representation in the window, typically an image. You give its frame and the sharing service animates from it.
     */
    return self.window;
}



#pragma Sharing service picker

- (IBAction)chooseFromSharingServicePicker:(id)sender
{
    /*
     Create the array of items to share.
     Start with just the content of the text view. If there's an image, add that too.
     */
    NSMutableArray *shareItems = [NSMutableArray arrayWithObject:[self.textView string]];
    
    NSImage *image = [self.imageView image];
    if (image) {
        [shareItems addObject:image];
    }
    
    /*
     Create a sharing service picker using the items.
     Set its delegate to self; the actual services are then set up in sharingServicePicker:sharingServicesForItems:proposedSharingServices:.
     Finally, display the picker.
     */
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:shareItems];
    
    sharingServicePicker.delegate = self;
    [sharingServicePicker showRelativeToRect:[self.chooseServiceButton bounds] ofView:self.chooseServiceButton preferredEdge:NSMaxYEdge];
}



- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices
{
    /*
     If you're only interested in providing your own services, you could ignore the array of proposed services and construct and return your own array. Alternatively, as shown here, you add your service to the list of those offered by the system.
     */
    
    NSArray *services = proposedServices;
    
    /*
     Example of a custom sharing service:
     
     Search the array of items to find the first instance of a string.
     If there is a string, create a new service that simply logs the string.
     */
    NSString *theFirstString;
    
    for (id item in items) {
        if ([item isKindOfClass:[NSString class]]) {
            theFirstString = item;
            break;
        }
    }
    
    /*
     If there is a string in the array of items, create a new service:
     The service is defined as a handler block; in this case, the block simply uses NSLog to print out the string.
     */
    if (theFirstString) {

        NSSharingService *customService = [[NSSharingService alloc] initWithTitle:@"Log the first string" image:[NSImage imageNamed:@"egg16"] alternateImage:nil handler:^{
            
            NSLog(@"The first string: %@", theFirstString);
        }];
        
        services = [services arrayByAddingObject:customService];
    }
    
    return services;
}


- (id <NSSharingServiceDelegate>)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker delegateForSharingService:(NSSharingService *)sharingService
{
    /*
     Implementing this method sets the delegate for the sharing service picker created in chooseSharingService:.
     In this example, it's for illustration only -- the delegate method simply logs which service was chosen. In your application, you might want to use the delegate method for something more useful, like managing resources.
     */
    return self;
}


- (void)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker didChooseSharingService:(NSSharingService *)service
{    
    NSLog(@"Picked this service: %@", service);
}


- (NSRect)sharingService:(NSSharingService *)sharingService sourceFrameOnScreenForShareItem:(id<NSPasteboardWriting>)item
{
    if ([item isKindOfClass:[NSImage class]]) {
        
        NSImageView *imageView = self.imageView;
        NSRect imageViewBounds = [imageView bounds];
        NSSize imageSize = [[imageView image] size];
        NSRect imageFrame = NSMakeRect((NSWidth(imageViewBounds) - imageSize.width) / 2.0, (NSHeight(imageViewBounds) - imageSize.height) / 2.0, imageSize.width, imageSize.height);
        NSRect frame = [imageView convertRect:imageFrame toView:nil];
        frame.origin = [[imageView window] convertBaseToScreen:frame.origin];
        return frame;
    }
    else {
        return NSZeroRect;
    }
}

- (NSImage *)sharingService:(NSSharingService *)sharingService transitionImageForShareItem:(id<NSPasteboardWriting>)item contentRect:(NSRect *)contentRect
{
    if ([item isKindOfClass:[NSImage class]]) {
        return [self.imageView image];
    }
    else {
        return nil;
    }
}

#pragma - Text view delegate

- (NSSharingServicePicker *)textView:(NSTextView *)textView willShowSharingServicePicker:(NSSharingServicePicker *)servicePicker forItems:(NSArray *)items
{
    /*
     Here you could modify the service picker for the given items.
     */
    NSLog(@"Text view using %@ with items: %@", servicePicker, items);
    
    return servicePicker;
}


@end
