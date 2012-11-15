/*
     File: AppController.h
 Abstract: Use the ImageCaptureCore framework to create a simple scanner application.
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

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

//------------------------------------------------------------------------------------------------------------------------------

@interface AppController : NSObject <ICDeviceBrowserDelegate, ICScannerDeviceDelegate>
{
    
    ICDeviceBrowser*                mDeviceBrowser;
    NSMutableArray*                 mScanners;
    IBOutlet  NSWindow*             mWindow;
    IBOutlet  NSTableView*          mScannersTableView;
    IBOutlet  NSArrayController*    mScannersController;
    IBOutlet  NSPopUpButton*        mFunctionalUnitMenu;
    IBOutlet  NSProgressIndicator*  mProgressIndicator;
    IBOutlet  NSTextField*          mStatusText;
}

@property(retain)   NSMutableArray* scanners;

// ICDeviceBrowser delegate methods
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device;
- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeSharingState:(ICDevice*)device;
- (void)deviceBrowser:(ICDeviceBrowser*)browser requestsSelectDevice:(ICDevice*)device;

// ICDevice and ICScannerDevice delegate methods
- (void)didRemoveDevice:(ICDevice*)removedDevice;
- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error;
- (void)deviceDidBecomeReady:(ICScannerDevice*)device;
- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error;
- (void)deviceDidChangeName:(ICDevice*)device;
- (void)deviceDidChangeSharingState:(ICDevice*)device;
- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status;
- (void)device:(ICDevice*)device didEncounterError:(NSError*)error;
- (void)device:(ICDevice*)device didReceiveButtonPress:(NSString*)button;

- (void)scannerDeviceDidBecomeAvailable:(ICScannerDevice*)scanner;
- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error;
- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data;
- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteOverviewScanWithError:(NSError*)error;
- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteScanWithError:(NSError*)error;

- (ICScannerDevice*)selectedScanner;
- (IBAction)openCloseSession:(id)sender;
- (IBAction)selectFunctionalUnit:(id)sender;
- (IBAction)startOverviewScan:(id)sender;
- (IBAction)startScan:(id)sender;
@end

//------------------------------------------------------------------------------------------------------------------------------
