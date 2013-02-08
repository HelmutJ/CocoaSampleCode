//
//  CoreWLANController.m
//  CoreWLANWirelessManager
//  Copyright 2009 Apple, Inc. All rights reserved.
//

//     File: CoreWLANController.m
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

#import "CoreWLANController.h"
#import <CoreWLAN/CoreWLAN.h>
#import <SecurityInterface/SFAuthorizationView.h>

@implementation CoreWLANController

@synthesize currentInterface;
@synthesize scanResults;
@synthesize selectedNetwork;
@synthesize joinDialogContext;

- (void)dealloc
{
	self.currentInterface = nil;
	self.scanResults = nil;
	self.selectedNetwork = nil;
	self.joinDialogContext = NO;
	[super dealloc];
}

#pragma mark -
#pragma mark Utility Methods
- (NSString*)stringForPHYMode:(NSNumber*)phyMode
{
	NSString *phyModeStr = nil;
	switch( [phyMode intValue] )
	{
		case kCWPHYMode11A:
			phyModeStr = [NSString stringWithString:@"802.11a"];
			break;
		case kCWPHYMode11B:
			phyModeStr = [NSString stringWithString:@"802.11b"];
			break;
		case kCWPHYMode11G:
			phyModeStr = [NSString stringWithString:@"802.11g"];
			break;
		case kCWPHYMode11N:
			phyModeStr = [NSString stringWithString:@"802.11n"];
			break;
	}
	return phyModeStr;
}

- (NSString*)stringForSecurityMode:(NSNumber*)securityMode
{
	NSString *securityModeStr = nil;
	switch( [securityMode intValue] )
	{
		case kCWSecurityModeOpen:
			securityModeStr = [NSString stringWithString:@"Open"];
			break;
		case kCWSecurityModeWEP:
			securityModeStr = [NSString stringWithString:@"WEP"];
			break;
		case kCWSecurityModeWPA_PSK:
			securityModeStr = [NSString stringWithString:@"WPA Personal"];
			break;
		case kCWSecurityModeWPA_Enterprise:
			securityModeStr = [NSString stringWithString:@"WPA Enterprise"];
			break;
		case kCWSecurityModeWPA2_PSK:
			securityModeStr = [NSString stringWithString:@"WPA2 Personal"];
			break;
		case kCWSecurityModeWPA2_Enterprise:
			securityModeStr = [NSString stringWithString:@"WPA2 Enterprise"];
			break;
		case kCWSecurityModeWPS:
			securityModeStr = [NSString stringWithString:@"WiFi Protected Setup"];
			break;
		case kCWSecurityModeDynamicWEP:
			securityModeStr = [NSString stringWithString:@"802.1X WEP"];
			break;
	}
	return securityModeStr;
}

- (CWSecurityMode)securityModeForString:(NSString*)securityMode
{
	if( [securityMode isEqualToString:@"WEP"] )
		return kCWSecurityModeWEP;
	else if( [securityMode isEqualToString:@"WPA Personal"] )
		return kCWSecurityModeWPA_PSK;
	else if( [securityMode isEqualToString:@"WPA2 Personal"] )
		return kCWSecurityModeWPA2_PSK;
	else if( [securityMode isEqualToString:@"WPA Enterprise"] )
		return kCWSecurityModeWPA_Enterprise;
	else if( [securityMode isEqualToString:@"WPA2 Enterprise"] )
		return kCWSecurityModeWPA2_Enterprise;
	else if( [securityMode isEqualToString:@"802.1X WEP"] )
		return kCWSecurityModeDynamicWEP;
	else
		return kCWSecurityModeOpen; 
}

- (NSString*)stringForOpMode:(NSNumber*)opMode
{
	NSString *opModeStr = nil;
	switch( [opMode intValue] )
	{
		case kCWOpModeIBSS:
			opModeStr = [NSString stringWithString:@"IBSS"];
			break;
		case kCWOpModeStation:
			opModeStr = [NSString stringWithString:@"Infrastructure"];
			break;
		case kCWOpModeHostAP:
			opModeStr = [NSString stringWithString:@"Host Access Point"];
			break;
		case kCWOpModeMonitorMode:
			opModeStr = [NSString stringWithString:@"Monitor Mode"];
			break;
	}
	return opModeStr;
}

- (void)updateInterfaceInfoTab
{
	NSNumber *num = nil;
	NSString *str = nil;
	
	BOOL powerState = self.currentInterface.power;	
	[powerStateControl setSelectedSegment:(powerState ? 0 : 1)];
	
	if( [self.currentInterface.interfaceState intValue] == kCWInterfaceStateRunning )
		[disconnectButton setEnabled:YES];
	else
		[disconnectButton setEnabled:NO];
	
	num = [self.currentInterface opMode];
	[opModeField setStringValue:((num && powerState) ? [self stringForOpMode:num] : @"")];
	
	num = [self.currentInterface securityMode];
	[securityModeField setStringValue:((num && powerState) ? [self stringForSecurityMode:num] : @"")];
	
	num = [self.currentInterface phyMode];
	[phyModeField setStringValue:((num && powerState) ? [self stringForPHYMode:num] : @"")];
	
	str = [self.currentInterface ssid];
	[ssidField setStringValue:((str && powerState) ? str : @"")];
	
	str = [self.currentInterface bssid];
	[bssidField setStringValue:((str && powerState) ? str : @"")];
	
	num = [self.currentInterface txRate]; 
	[txRateField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ Mbps",[num stringValue]] : @"")];
	
	num = [self.currentInterface rssi];
	[rssiField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ dBm",[num stringValue]] : @"")];
	
	num = [self.currentInterface noise];
	[noiseField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ dBm",[num stringValue]] : @"")];
	
	num = [self.currentInterface txPower];
	[txPowerField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ mW",[num stringValue]] : @"")];
	
	str = [self.currentInterface countryCode];
	[countryCodeField setStringValue:((str && powerState) ? str : @"")];
	
	NSArray *supportedChannelsArray = [self.currentInterface supportedChannels];
	NSMutableString *supportedChannelsString = [NSMutableString stringWithCapacity:0];
	[channelPopup removeAllItems];
	for( id eachChannel in supportedChannelsArray )
	{
		if( [eachChannel isEqualToNumber:[supportedChannelsArray lastObject]] )
			[supportedChannelsString appendFormat:@"%@",[eachChannel stringValue]];
		else
			[supportedChannelsString appendFormat:@"%@, ",[eachChannel stringValue]];
		
		if( powerState )
			[channelPopup addItemWithTitle:[eachChannel stringValue]];
	}
	[supportedChannelsField setStringValue:supportedChannelsString];
	
	NSArray *supportedPHYModesArray = [self.currentInterface supportedPHYModes];
	NSMutableString *supportedPHYModesString = [NSMutableString stringWithString:@"802.11"];
	for( id eachPHYMode in supportedPHYModesArray )
	{
		switch( [eachPHYMode intValue] )
		{
			case kCWPHYMode11A:
				[supportedPHYModesString appendString:@"a/"];
				break;
			case kCWPHYMode11B:
				[supportedPHYModesString appendString:@"b/"];
				break;
			case kCWPHYMode11G:
				[supportedPHYModesString appendString:@"g/"];
				break;
			case kCWPHYMode11N:
				[supportedPHYModesString appendString:@"n"];
				break;
		}
	}
	if( [supportedPHYModesString hasSuffix:@"/"] )
		[supportedPHYModesString deleteCharactersInRange:NSMakeRange([supportedPHYModesString length] - 1, 1)];
	if( [supportedPHYModesString hasSuffix:@"802.11"] )
		supportedPHYModesString = [NSString stringWithString:@"None"];
	[supportedPHYModesField setStringValue:supportedPHYModesString];
	
	[channelPopup selectItemWithTitle:[[self.currentInterface channel] stringValue]];
	if( ![self.currentInterface power] || [[self.currentInterface interfaceState] intValue] == kCWInterfaceStateRunning )
		[channelPopup setEnabled:NO];
	else
		[channelPopup setEnabled:YES];
}

- (void)updateScanTab
{
	NSError *err = nil;
	NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:([mergeScanResultsCheckbox state] == NSOnState)] forKey:kCWScanKeyMerge];
	
	self.scanResults = [NSMutableArray arrayWithArray:[self.currentInterface scanForNetworksWithParameters:params error:&err]];
	if( err )
		[[NSAlert alertWithError:err] runModal];
	else
		[self.scanResults sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"ssid" ascending:YES selector:@selector	(caseInsensitiveCompare:)] autorelease]]];
	[scanResultsTable reloadData];
}

- (void)resetDialog
{
	[joinNetworkNameField setStringValue:@""];
	[joinNetworkNameField setEnabled:YES];
	[joinUsernameField setStringValue:@""];
	[joinUsernameField setEnabled:YES];
	[joinPassphraseField setStringValue:@""];
	[joinPassphraseField setEnabled:YES];
	
	[joinSecurityPopupButton removeAllItems];
	[joinSecurityPopupButton addItemsWithTitles:[NSArray arrayWithObjects:@"Open", @"WEP", @"WPA Personal", @"WPA2 Personal", @"WPA Enterprise", @"WPA2 Enterprise", @"802.1X WEP", nil]];
	[joinSecurityPopupButton selectItemAtIndex:0];
	[joinSecurityPopupButton setEnabled:YES];
	[joinUser8021XProfilePopupButton removeAllItems];
	[self changeSecurityMode:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	self.joinDialogContext = NO;
}

#pragma mark -
#pragma mark NSNibAwaking Protocol
- (void) awakeFromNib
{	
	// populate interfaces popup with all supported interfaces
	[supportedInterfacesPopup removeAllItems];
	[supportedInterfacesPopup addItemsWithTitles:[CWInterface supportedInterfaces]];
	
	// setup scan results table
	[scanResultsTable setDataSource:self];
	[scanResultsTable setDelegate:self];
	ssidColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"NETWORK_NAME"];
	bssidColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"BSSID"];
	channelColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"CHANNEL"];
	phyModeColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"PHY_MODE"];
	ibssColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"NETWORK_MODE"];
	rssiColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"RSSI"];
	securityModeColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"SECURITY_MODE"];
	
	// hide progress indicators 
	[refreshSpinner setHidden:YES];
	[joinSpinner setHidden:YES];
	[ibssSpinner setHidden:YES];
	
	// register for notifcations
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification::) name:kCWModeDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCWSSIDDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCWBSSIDDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCWCountryCodeDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCWLinkDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCWPowerDidChangeNotification object:nil];
}

#pragma mark -
#pragma mark NSApplicationDelegate Protocol
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[supportedInterfacesPopup selectItemAtIndex:0];
	[self interfaceSelected:nil];
}

#pragma mark -
#pragma mark IBAction Methods
- (IBAction)interfaceSelected:(id)sender
{
	self.currentInterface = [CWInterface interfaceWithName:[[supportedInterfacesPopup selectedItem] title]];
	[self updateInterfaceInfoTab];
}

- (IBAction)refreshPressed:(id)sender
{
	[refreshSpinner setHidden:NO];
	[refreshSpinner startAnimation:self];
	
	if( [[[tabView selectedTabViewItem] label] isEqualToString:@"Interface Info"] )
		[self updateInterfaceInfoTab];
	else if( [[[tabView selectedTabViewItem] label] isEqualToString:@"Scan"] )
		[self updateScanTab];
	[refreshSpinner stopAnimation:self];
	[refreshSpinner setHidden:YES];
}

- (IBAction)changePower:(id)sender
{
	NSError *err = nil;
	BOOL result = [self.currentInterface setPower:([powerStateControl selectedSegment] ? NO : YES) error:&err];
	if( !result )
		[[NSAlert alertWithError:err] runModal];
	[self updateInterfaceInfoTab];
}

- (IBAction)changeChannel:(id)sender
{
	NSError *err = nil;
	BOOL result = [self.currentInterface setChannel:[[NSNumber numberWithInt:[[[channelPopup selectedItem] title] intValue]] unsignedIntegerValue] error:&err];
	if( !result )
		[[NSAlert alertWithError:err] runModal];
	[self updateInterfaceInfoTab];
}

- (IBAction)disconnect:(id)sender
{
	[self.currentInterface disassociate];
	[self updateInterfaceInfoTab];
}

- (IBAction)changeSecurityMode:(id)sender
{	
	if( [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA Enterprise"] ||
	   [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA2 Enterprise"] ||
	   [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"802.1X WEP"] )
	{
		[joinUsernameField setEnabled:YES];
		[joinUser8021XProfilePopupButton setEnabled:YES];
		[joinPassphraseField setEnabled:YES];
		
		[joinUser8021XProfilePopupButton addItemWithTitle:@"Default"];
		for( CW8021XProfile *each8021XProfile in [CW8021XProfile allUser8021XProfiles] )
		{
			[joinUser8021XProfilePopupButton addItemWithTitle:[each8021XProfile userDefinedName]];
		}
		[joinUser8021XProfilePopupButton selectItemAtIndex:0];
	}
	else if( [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA Personal"] ||
			[[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA2 Personal"] || 
			[[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WEP"] )
	{
		[joinUser8021XProfilePopupButton removeAllItems];
		[joinUser8021XProfilePopupButton setEnabled:NO];
		[joinUsernameField setEnabled:NO];
		[joinPassphraseField setEnabled:YES];
	}
	else
	{
		[joinUser8021XProfilePopupButton removeAllItems];
		[joinPassphraseField setEnabled:NO];
		[joinUsernameField setEnabled:NO];
		[joinUser8021XProfilePopupButton setEnabled:NO];
	}
}

- (IBAction)change8021XProfile:(id)sender
{
	CW8021XProfile *tmp = [[CW8021XProfile allUser8021XProfiles] objectAtIndex:[joinUser8021XProfilePopupButton indexOfSelectedItem] -1];
	if( tmp )
	{
		if( [[[joinUser8021XProfilePopupButton selectedItem] title] isEqualToString:@"Default"] )
		{
			[joinUsernameField setStringValue:@""];
			[joinUsernameField setEnabled:YES];
			[joinPassphraseField setStringValue:@""];
			[joinPassphraseField setEnabled:YES];
		}
		else
		{
			[joinUsernameField setStringValue:tmp.username];
			[joinUsernameField setEnabled:NO];
			[joinPassphraseField setStringValue:tmp.password];
			[joinPassphraseField setEnabled:NO];
		}
	}
}

- (IBAction)joinOKButtonPressed:(id)sender
{
	CW8021XProfile *user8021XProfile = nil;
	
	[joinSpinner setHidden:NO];
	[joinSpinner startAnimation:self];
	
	if( [joinUser8021XProfilePopupButton isEnabled] )
	{
		if( [[[joinUser8021XProfilePopupButton selectedItem] title] isEqualToString:@"Default"] )
		{
			user8021XProfile = [CW8021XProfile profile];
			user8021XProfile.ssid = [joinNetworkNameField stringValue];
			user8021XProfile.userDefinedName = [joinNetworkNameField stringValue];
			user8021XProfile.username = ([[joinUsernameField stringValue] length] ? [joinUsernameField stringValue] : nil);
			user8021XProfile.password = ([[joinPassphraseField stringValue] length] ? [joinPassphraseField stringValue] : nil);
		}
		else
		{
			user8021XProfile = [[CW8021XProfile allUser8021XProfiles] objectAtIndex:[joinUser8021XProfilePopupButton indexOfSelectedItem]-1];
		}
	}
	
	if( self.joinDialogContext )
	{
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
		if( user8021XProfile )
			[params setValue:user8021XProfile forKey:kCWAssocKey8021XProfile];
		else
			[params setValue:([[joinPassphraseField stringValue] length] ? [joinPassphraseField stringValue] : nil) forKey:kCWAssocKeyPassphrase];
		NSError *err = nil;
		BOOL result = [self.currentInterface associateToNetwork:self.selectedNetwork parameters:[NSDictionary dictionaryWithDictionary:params] error:&err];
		
		[joinSpinner stopAnimation:self];
		[joinSpinner setHidden:YES];
		
		if( !result )
			[[NSAlert alertWithError:err] runModal];
		else
			[self joinCancelButtonPressed:nil];
	}
}

- (IBAction)joinCancelButtonPressed:(id)sender
{
	[(NSApplication*)NSApp endSheet:joinDialogWindow];
	[joinDialogWindow orderOut:sender];
}

- (IBAction)joinButtonPressed:(id)sender
{
	NSInteger index = [scanResultsTable selectedRow];
	if( index >= 0 )
	{
		[self resetDialog];
		self.selectedNetwork = [self.scanResults objectAtIndex:index];
		
		[joinNetworkNameField setStringValue:self.selectedNetwork.ssid];
		[joinNetworkNameField setEnabled:NO];
		[joinSecurityPopupButton selectItemWithTitle:[self stringForSecurityMode:self.selectedNetwork.securityMode]];
		[joinSecurityPopupButton setEnabled:NO];
		[self changeSecurityMode:nil];
		
		CWWirelessProfile *wp = self.selectedNetwork.wirelessProfile;
		CW8021XProfile *xp = wp.user8021XProfile;
		switch( [self.selectedNetwork.securityMode intValue] )
		{
			case kCWSecurityModeWPA_PSK:
			case kCWSecurityModeWPA2_PSK:
			case kCWSecurityModeWEP:
				if( wp.passphrase )
				{
					[joinPassphraseField setStringValue:wp.passphrase];
				}
				break;
			case kCWSecurityModeOpen:
				break;
			case kCWSecurityModeWPA_Enterprise:
			case kCWSecurityModeWPA2_Enterprise:
				if( xp )
				{
					[joinUser8021XProfilePopupButton selectItemWithTitle:xp.userDefinedName];
					[joinUsernameField setStringValue:xp.username];
					[joinUsernameField setEnabled:NO];
					[joinPassphraseField setStringValue:xp.password];
					[joinPassphraseField setEnabled:NO];
				}
				break;
		}
		
		// reset first repsponder
		[joinDialogWindow makeFirstResponder:joinNetworkNameField];
		
		self.joinDialogContext = YES;
		[NSApp beginSheet:joinDialogWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (IBAction)ibssOKButtonPressed:(id)sender
{
	[ibssSpinner setHidden:NO];
	[ibssSpinner startAnimation:self];
	
	NSString *networkName = [ibssNetworkNameField stringValue];
	NSNumber *channel = [NSNumber numberWithInt:[[[ibssChannelPopupButton selectedItem] title] intValue]];
	NSString *passphrase = [ibssPassphraseField stringValue];
	
	NSMutableDictionary *ibssParams = [NSMutableDictionary dictionaryWithCapacity:0];
	if( networkName && [networkName length] )
		[ibssParams setValue:networkName forKey:kCWIBSSKeySSID];
	if( channel && [channel intValue] > 0 )
		[ibssParams setValue:channel forKey:kCWIBSSKeyChannel];
	if( passphrase && [passphrase length] )
		[ibssParams setValue:passphrase forKey:kCWIBSSKeyPassphrase];
	
	NSError *error = nil;
	BOOL created = [self.currentInterface enableIBSSWithParameters:[NSDictionary dictionaryWithDictionary:ibssParams] error:&error];
	
	[ibssSpinner stopAnimation:self];
	[ibssSpinner setHidden:YES];
	
	if( !created )
	{
		[[NSAlert alertWithError:error] runModal];
	}
	else
	{
		[self ibssCancelButtonPressed:nil];
	}
}

- (IBAction)ibssCancelButtonPressed:(id)sender
{
	[(NSApplication*)NSApp endSheet:ibssDialogWindow];
	[ibssDialogWindow orderOut:sender];
}

- (IBAction)createIBSSButtonPressed:(id)sender
{
	// add machine name as default SSID
	CFStringRef machineName = CSCopyMachineName();
	if( machineName )
	{
		[ibssNetworkNameField setStringValue:(id)machineName];
		CFRelease(machineName);
	}

	// hard code IBSS channel for now
	[ibssChannelPopupButton addItemWithTitle:@"11"];
	[ibssChannelPopupButton setEnabled:NO];
	
	// select channel 11 as default channel
	[ibssChannelPopupButton selectItemWithTitle:@"11"];
	
	// reset passphrase
	[ibssPassphraseField setStringValue:@""];
	
	// reset first responder
	[ibssDialogWindow makeFirstResponder:ibssNetworkNameField];
	
	[NSApp beginSheet:ibssDialogWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#pragma mark -
#pragma mark NSTableDataSource Protocol
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	if( tableView == scanResultsTable )
	{
		if( row < [self.scanResults count] )
		{
			CWNetwork *network = [self.scanResults objectAtIndex:row];
			if( tableColumn == ssidColumn )
				return [network ssid];
			if( tableColumn == bssidColumn )
				return [network bssid];
			if( tableColumn == channelColumn )
				return [[network channel] stringValue];
			if( tableColumn == phyModeColumn )
				return [self stringForPHYMode:[network phyMode]];
			if( tableColumn == securityModeColumn )
				return [self stringForSecurityMode:[network securityMode]];
			if( tableColumn == rssiColumn )
				return [[network rssi] stringValue];
			if( tableColumn == ibssColumn )
				return ([network isIBSS] ? [NSString stringWithString:@"Yes"] : [NSString stringWithString:@"No"]);
		}
	}
	return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{	
	return (self.scanResults ? [self.scanResults count] : 0);
}

#pragma mark -
#pragma mark Notification Handler
- (void)handleNotification:(NSNotification*)note
{
	[self updateInterfaceInfoTab];
}
@end
