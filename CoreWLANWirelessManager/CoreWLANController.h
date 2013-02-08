//
//  CoreWLANController.h
//  CoreWLANWirelessManager
//  Copyright 2009 Apple, Inc. All rights reserved.
//

//     File: CoreWLANController.h
// Abstract: Controller class for the CoreWLANWirelessManager application.
//  Version: 1.2
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2011 Apple Inc. All Rights Reserved.
// 

@class CWInterface, CWConfiguration, CWNetwork, SFAuthorizationView;
@interface CoreWLANController : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>
{
	CWInterface *currentInterface;
	NSMutableArray *scanResults;
	CWConfiguration *configurationSession;
	BOOL joinDialogContext;
	
	// application window
	IBOutlet NSPopUpButton *supportedInterfacesPopup;
	IBOutlet NSButton *refreshButton;
	IBOutlet NSProgressIndicator *refreshSpinner;
	IBOutlet NSTabView *tabView;
	IBOutlet NSWindow *mainWindow;
	
	// interface info tab
	IBOutlet NSTextField *supportedChannelsField;
	IBOutlet NSTextField *supportedPHYModesField;
	IBOutlet NSTextField *countryCodeField;
	IBOutlet NSSegmentedControl *powerStateControl;
	IBOutlet NSPopUpButton *channelPopup;
	IBOutlet NSTextField *opModeField;
	IBOutlet NSTextField *txPowerField;
	IBOutlet NSTextField *rssiField;
	IBOutlet NSTextField *noiseField;
	IBOutlet NSTextField *ssidField;
	IBOutlet NSTextField *securityModeField;
	IBOutlet NSTextField *bssidField;
	IBOutlet NSTextField *phyModeField;
	IBOutlet NSTextField *txRateField;
	IBOutlet NSButton *disconnectButton;
	
	// scan tab
	IBOutlet NSTableView *scanResultsTable;
	IBOutlet NSButton *joinButton;
	IBOutlet NSButton *mergeScanResultsCheckbox;
	NSTableColumn *ssidColumn;
	NSTableColumn *bssidColumn;
	NSTableColumn *channelColumn;
	NSTableColumn *phyModeColumn;
	NSTableColumn *securityModeColumn;
	NSTableColumn *ibssColumn;
	NSTableColumn *rssiColumn;
	
	// join dialog
	CWNetwork *selectedNetwork;
	IBOutlet NSWindow *joinDialogWindow;
	IBOutlet NSButton *joinOKButton;
	IBOutlet NSButton *joinCancelButton;
	IBOutlet NSPopUpButton *joinSecurityPopupButton;
	IBOutlet NSPopUpButton *joinUser8021XProfilePopupButton;
	IBOutlet NSProgressIndicator *joinSpinner;
	IBOutlet NSTextField *joinNetworkNameField;
	IBOutlet NSTextField *joinUsernameField;
	IBOutlet NSSecureTextField *joinPassphraseField;
	
	// ibss dialog
	IBOutlet NSWindow *ibssDialogWindow;
	IBOutlet NSButton *ibssOKButton;
	IBOutlet NSButton *ibssCancelButton;
	IBOutlet NSTextField *ibssNetworkNameField;
	IBOutlet NSTextField *ibssPassphraseField;
	IBOutlet NSPopUpButton *ibssChannelPopupButton;
	IBOutlet NSProgressIndicator *ibssSpinner;
}
@property(readwrite, retain) CWInterface *currentInterface;
@property(readwrite, retain) NSMutableArray *scanResults;
@property(readwrite, retain) CWNetwork *selectedNetwork;
@property(readwrite, assign) BOOL joinDialogContext;

#pragma mark -
#pragma mark IBAction Methods
// application window
- (IBAction)interfaceSelected:(id)sender; 
- (IBAction)refreshPressed:(id)sender;

// interface info tab
- (IBAction)changePower:(id)sender;
- (IBAction)changeChannel:(id)sender;
- (IBAction)disconnect:(id)sender;

// scan tab
- (IBAction)joinButtonPressed:(id)sender;
- (IBAction)createIBSSButtonPressed:(id)sender;

// join dialog
- (IBAction)changeSecurityMode:(id)sender;
- (IBAction)change8021XProfile:(id)sender;
- (IBAction)joinOKButtonPressed:(id)sender;
- (IBAction)joinCancelButtonPressed:(id)sender;

// ibss dialog
- (IBAction)ibssOKButtonPressed:(id)sender;
- (IBAction)ibssCancelButtonPressed:(id)sender;
@end
