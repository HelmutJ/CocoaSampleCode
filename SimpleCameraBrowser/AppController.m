/*
     File: AppController.m
 Abstract: Implements a simple camera browser application using the ImageCaptureCore framework.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "AppController.h"

@interface NSImageFromCGImageRef: NSValueTransformer {}
@end

@implementation NSImageFromCGImageRef
+ (Class)transformedValueClass      { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)item
{
    if ( item )
        return  [[NSImage alloc] initWithCGImage:(CGImageRef)item size:NSZeroSize];
    else
        return nil;
}
@end


@implementation AppController

@synthesize cameras = mCameras;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#pragma mark -
#pragma mark Initialization & Cleanup methods
- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    mCameras = [[NSMutableArray alloc] initWithCapacity:0];

    // Get an instance of ICDeviceBrowser
    mDeviceBrowser = [[ICDeviceBrowser alloc] init];
    // Assign a delegate
    mDeviceBrowser.delegate = self;
    // Look for cameras in all available locations
    mDeviceBrowser.browsedDeviceTypeMask = mDeviceBrowser.browsedDeviceTypeMask | ICDeviceTypeMaskCamera
                                        | ICDeviceLocationTypeMaskLocal
                                        | ICDeviceLocationTypeMaskShared
                                        | ICDeviceLocationTypeMaskBonjour
                                        | ICDeviceLocationTypeMaskBluetooth
                                        | ICDeviceLocationTypeMaskRemote;
    // Start browsing for cameras
    [mDeviceBrowser start];

}


/*---------------------------------------------------------------------------------------------------- applicationWillTerminate: */

- (void)applicationWillTerminate:(NSNotification*)notification
{
    mDeviceBrowser.delegate = NULL;
    
    [mDeviceBrowser stop];
}

#pragma mark -
#pragma mark Getter methods

/*------------------------------------------------------------------------------------------------------------------ canDownload */

/* The canDownload property reports whether or not there are any images available for download. 
 */
- (BOOL)canDownload
{
    if ( [[mMediaFilesController selectedObjects] count] )
        return YES;
    else
        return NO;
}

#pragma mark -
#pragma mark Methods to download media files from the device

/*---------------------------------------------------------------------------------------------------------------- downloadFiles */

/* The downloadFiles method is called when the Download button is pressed to download all available 
 media files from the device. Once a file is successfully downloaded, the didDownloadFile method is also called.
 */
- (void)downloadFiles:(NSArray*)files
{
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSURL fileURLWithPath:[@"~/Pictures" stringByExpandingTildeInPath]] forKey:ICDownloadsDirectoryURL];
    
    for ( ICCameraFile* f in files )
    {
        [f.device requestDownloadFile:f options:options downloadDelegate:self didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:) contextInfo:NULL];
    }
}

/* Once a file is successfully downloaded, the didDownloadFile method is called from the downloadFiles method.
*/
- (void)didDownloadFile:(ICCameraFile*)file error:(NSError*)error options:(NSDictionary*)options contextInfo:(void*)contextInfo
{
    NSLog( @"didDownloadFile called with:\n" );
    NSLog( @"  file:        %@\n", file );
    NSLog( @"  error:       %@\n", error );
    NSLog( @"  options:     %@\n", options );
    NSLog( @"  contextInfo: %p\n", contextInfo );
}

#pragma mark -
#pragma mark ICDeviceBrowser delegate methods
/*--------------------------------------------------------------------------------------- deviceBrowser:didAddDevice:moreComing: */

/* This message is sent to the delegate when a device has been added. This code adds the device to the cameras array. 
 */
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    NSLog( @"deviceBrowser:didAddDevice:moreComing: \n%@\n", addedDevice );
    
    if ( addedDevice.type & ICDeviceTypeCamera )
    {
        addedDevice.delegate = self;

		// This triggers KVO messages to AppController
		// to add the new camera object to the cameras array.
		[[self mutableArrayValueForKey:@"cameras"] addObject:addedDevice];
    }
}


/*----------------------------------------------------------------------------------------------- deviceBrowser:didRemoveDevice: */

/* The required delegate method didRemoveDevice will handle the removal of camera devices. This message is sent to 
 the delegate to inform that a device has been removed.
 */
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing;
{
    NSLog( @"deviceBrowser:didRemoveDevice:moreGoing: \n%@\n", device );
    
    device.delegate = NULL;
    
	// This triggers KVO messages to AppController
	// to remove the camera object from the cameras array.
	[[self mutableArrayValueForKey:@"cameras"] removeObject:device];
}

#pragma mark -
#pragma mark ICDevice & ICCameraDevice delegate methods
/*------------------------------------------------------------------------------------------------------------- didRemoveDevice: */

/* A delegate of ICDevice must conform to ICDeviceDelegate protocol. The required delegate method didRemoveDevice 
 will handle the removal of camera devices. This message is sent to the delegate to inform that a device has been removed.
 */
- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    NSLog( @"didRemoveDevice: \n%@\n", removedDevice );
    [mCamerasController removeObject:removedDevice];
}



@end
