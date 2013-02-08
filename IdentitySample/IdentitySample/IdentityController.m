/*
     File: IdentityController.m
 Abstract: IdentitySample builds a utility which demonstrates how to use the CoreServices Identity API to manage system-wide identities. These identities can then be used by applications to enable secure collaboration among users on a network. The utility allows you to add and delete identities, change identity information as well as query for identities by name.
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

#import "IdentityController.h"
#import <CoreServices/CoreServices.h>


@implementation IdentityController


- (void)setAliases:(NSArray *)aliases
{
	if (_aliases != aliases) {
		[_aliases release];
		_aliases = aliases ? [aliases mutableCopy] : [[NSMutableArray alloc] init];
		[_aliasesTableView reloadData];
	}
}


- (void)setImageWithData:(NSData*)data type:(NSString *)type url:(NSURL *)url
{
	if (data) {
		[_imageView setImage:[[[NSImage alloc] initWithData:data] autorelease]];
	}
	
	[_imageDataType setStringValue:type ? type : @""];
	
	if (url) {
		NSString *imageURLString = [url relativePath];
		[_imageURL setStringValue:imageURLString ? imageURLString : @""];
		if (!data) {
			[_imageView setImage:[[[NSImage alloc] initWithContentsOfURL:url] autorelease]];
		}
	} else {
		[_imageURL setStringValue:@""];
		if (!data) {
			[_imageView setImage:nil];
		}
	}
}


- (void)setIdentityInfoEnabled:(BOOL)enabled
{
	[_fullName setEnabled:enabled];
	[_posixName setEnabled:enabled];
	[_emailAddress setEnabled:enabled];
	[_uuid setEnabled:enabled];
	[_imageURL setEnabled:enabled];
	[_imageDataType setEnabled:enabled];
	[_isEnabled setEnabled:enabled];
	[_posixID setEnabled:enabled];
	[_aliasesTableView setEnabled:enabled];
	[_imageView setEnabled:enabled];
}


- (void)reloadIdentityAtIndex:(NSInteger)currentIndex
{
	if (currentIndex != -1) {
		/* Fetch the CSIdentityRef corresponding to the current sidebar selection */
		CSIdentityRef identity = (CSIdentityRef)[_identities objectAtIndex:currentIndex];

		/* Fetch all the Identity information to update the user interface */
		NSString *fullName = (NSString *)CSIdentityGetFullName(identity);
		NSString *posixName = (NSString *)CSIdentityGetPosixName(identity);
		NSString *emailAddress = (NSString *)CSIdentityGetEmailAddress(identity);
		NSArray *aliases = (NSArray *)CSIdentityGetAliases(identity);
		NSData *imageData = (NSData *)CSIdentityGetImageData(identity);
		NSString *imageDataType = (NSString *)CSIdentityGetImageDataType(identity);
		NSURL *imageURL = (NSURL *)CSIdentityGetImageURL(identity);
		NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, CSIdentityGetUUID(identity));
		BOOL isEnabled = (BOOL)CSIdentityIsEnabled(identity);
		int posixID = (int)CSIdentityGetPosixID(identity);

		/* Enable all the controls */
		[self setIdentityInfoEnabled:YES];
										
		/* Update the user interface with the current info */
		[_fullName setStringValue:fullName ? fullName : @""];
		[_posixName setStringValue:posixName ? posixName : @""];
		[_emailAddress setStringValue:emailAddress ? emailAddress : @""];
		[_uuid setStringValue:uuidString ? [uuidString autorelease] : @""];
		[_isEnabled setState:isEnabled];
		[_posixID setIntValue:posixID];
		[self setAliases:aliases];
		[self setImageWithData:imageData type:imageDataType url:imageURL];

		/* Enable the Add Alias button and disable the Remove Alias button */
		[_addAliasButton setEnabled:YES];
		[_removeAliasButton setEnabled:NO];
	} else {
	
		/* Disable all the controls */
		[self setIdentityInfoEnabled:NO];

		/* Clear all the info */
		[_uuid setStringValue:@""];
		[_posixID setStringValue:@""];
		[_imageURL setStringValue:@""];
		[_fullName setStringValue:@""];
		[_posixName setStringValue:@""];
		[_emailAddress setStringValue:@""];
		[_isEnabled setState:NO];
		[self setAliases:nil];
		[self setImageWithData:nil type:nil url:nil];

		/* Disable the Add/Remove Alias buttons */
		[_addAliasButton setEnabled:NO];
		[_removeAliasButton setEnabled:NO];
	}
	
	/* Disable the Apply and Revert buttons */
	[_applyNowButton setEnabled:NO];
	[_revertButton setEnabled:NO];
}


NSComparisonResult
SortByFirstName(id val1, id val2, void *context)
{   
    NSString *fullName1 = (NSString *)CSIdentityGetFullName((CSIdentityRef)val1);
    NSString *fullName2 = (NSString *)CSIdentityGetFullName((CSIdentityRef)val2);
    return [fullName1 caseInsensitiveCompare:fullName2];
}


- (void)updateIdentities
{
	CSIdentityRef selectedIdentity = NULL;
	NSInteger currentIndex = [_identityTableView selectedRow];

	if (currentIndex != -1) {
		/* Save away the currently selected identity in the sidebar */
		selectedIdentity = (CSIdentityRef)[_identities objectAtIndex:currentIndex];
		if (selectedIdentity) CFRetain(selectedIdentity);
	}

	/* Replace the previous identity list with the latest query results and sort it in alphabetical order */
	NSArray *identities = (NSArray *)CSIdentityQueryCopyResults(_identityQuery);
	[_identities release];
	_identities = [identities mutableCopy];
	[identities release];
	[_identities sortUsingFunction:SortByFirstName context:nil];
	[_identityTableView reloadData];
    
	if (selectedIdentity) {
		/* Reselect the previously selected identity */
		NSUInteger index, count = [_identities count];
		for (index = 0; index < count; index++) {
			if (CFEqual(selectedIdentity, (CSIdentityRef)[_identities objectAtIndex:index])) {
				[_identityTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
				break;
			}
		}
		CFRelease(selectedIdentity);
	}
	
	[self reloadIdentityAtIndex:[_identityTableView selectedRow]];
}


- (void)receiveEvent:(CSIdentityQueryEvent)event fromQuery:(CSIdentityQueryRef)query identities:(NSArray*)identities error:(NSError*)error
{
	/* Our query callback was called so lets update the sidebar */
	[self updateIdentities];
	
	if (event == kCSIdentityQueryEventErrorOccurred) {
		NSLog(@"Query %p error %@, info %@", _identityQuery, error, [error userInfo]);
 	}
}


void
QueryEventCallback(CSIdentityQueryRef query, CSIdentityQueryEvent event, CFArrayRef identities, CFErrorRef error, void *info)
{
    IdentityController *me = (IdentityController *)info;
    [me receiveEvent:event fromQuery:query identities:(NSArray*)identities error:(NSError*)error];
}


- (void)queryForIdentitiesByName:(NSString *)name
{
	if (_identityQuery) {
		CSIdentityQueryStop(_identityQuery);
		CFRelease(_identityQuery);
	}
	CSIdentityQueryClientContext clientContext = { 0, self, NULL, NULL, NULL, QueryEventCallback };

	/* Create a new identity query with the name passed in, most likely taken from the search field */
	_identityQuery = CSIdentityQueryCreateForName(NULL, (CFStringRef)name, kCSIdentityQueryStringBeginsWith, kCSIdentityClassUser, CSGetLocalIdentityAuthority());

	/* Run the query asynchronously and we'll get callbacks sent to our QueryEventCallback function. */
	CSIdentityQueryExecuteAsynchronously(_identityQuery, kCSIdentityQueryGenerateUpdateEvents, &clientContext, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);	
}


- (void)startNewSearchQuery:(NSTimer*)theTimer
{
	[self queryForIdentitiesByName:[_searchText stringValue]];
	[_queryStartTimer invalidate];
	_queryStartTimer = NULL;
}


- (void)searchTextDidChange:(NSNotification *)notification
{
#define QUERY_DELAY 0.25
	if (_queryStartTimer) {
		[_queryStartTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:QUERY_DELAY]];
	} else {
		_queryStartTimer = [NSTimer scheduledTimerWithTimeInterval:QUERY_DELAY target:self selector:@selector(startNewSearchQuery:) userInfo:nil repeats:NO];
	}
}


- (BOOL)wasIdentityChanged
{
	BOOL wasChanged = NO;
	NSInteger currentIndex = [_identityTableView selectedRow];

	if (currentIndex != -1) {
	
		/* Fetch all the actual settable values from the current identity */
		CSIdentityRef identity = (CSIdentityRef)[_identities objectAtIndex:currentIndex];
		NSString *fullName = (NSString *)CSIdentityGetFullName(identity);
		NSString *emailAddress = (NSString *)CSIdentityGetEmailAddress(identity);
		NSArray *aliases = (NSArray *)CSIdentityGetAliases(identity);
		NSURL *imageURL = (NSURL *)CSIdentityGetImageURL(identity);
		BOOL isEnabled = (BOOL)CSIdentityIsEnabled(identity);
		
		/* Fetch all the modified values for the current identity */
		NSString *_newFullName = [_fullName stringValue];
		NSString *_newEmailAddress = [_emailAddress stringValue];
		NSString *imageURLString = [_imageURL stringValue];
		NSURL *_newImageURL = [NSURL fileURLWithPath:imageURLString];
		BOOL _newIsEnabled = [_isEnabled state];
		
		/* If any of these values have changed, then return YES */
		if (![fullName isEqual:_newFullName]) {
			wasChanged = YES;
		} else if (!((!emailAddress && [_newEmailAddress length] == 0) || (emailAddress && [emailAddress isEqual:_newEmailAddress]))) {
			wasChanged = YES;
		} else if (!((!imageURL && !_newImageURL) || (imageURL && [imageURL isEqual:_newImageURL]))) {
			wasChanged = YES;
		} else if (!((!aliases && [_aliases count] == 0) || (aliases && [aliases isEqual:_aliases]))) {
			wasChanged = YES;
		} else if (isEnabled != _newIsEnabled) {
			wasChanged = YES;
		}
	}
	
	return wasChanged;
}


- (void)updateApplyAndRevert
{
	/* If any of the current identity info has changed, enable the Apply and Revert buttons */
	BOOL modified = [self wasIdentityChanged];
	[_applyNowButton setEnabled:modified];
	[_revertButton setEnabled:modified];
}


- (IBAction)generatePosixNameToggled:(id)sender
{
	if ([sender state]) {
		[_addIdentityPosixNameLabel setTextColor:[NSColor lightGrayColor]];
		[_addIdentityPosixName setEnabled:NO];
	} else {
		[_addIdentityPosixNameLabel setTextColor:[NSColor blackColor]];
		[_addIdentityPosixName setEnabled:YES];
	}
}


- (IBAction)enableToggled:(id)sender
{
	[self updateApplyAndRevert];
}


- (void)identityDidChange:(NSNotification *)notification
{
	[self updateApplyAndRevert];
}


- (void)endAliasEditing
{
	[_aliasesTableView deselectAll:self];
	[_aliasesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_aliases count] - 1] byExtendingSelection:NO];
	[self updateApplyAndRevert];
}


- (void)aliasEditingDidEnd:(NSNotification *)notification
{
	[self performSelector:@selector(endAliasEditing) withObject:nil afterDelay:0.0];
}


- (void)identityTableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger currentIndex = [_identityTableView selectedRow];
    
	if (currentIndex == -1) {
		[_removeIdentityButton setEnabled:NO];
	} else {
		[_removeIdentityButton setEnabled:YES];
	}
	
	[self reloadIdentityAtIndex:currentIndex];
}


- (void)aliasesTableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger currentIndex = [_aliasesTableView selectedRow];
	
	if (currentIndex == -1) {
		[_removeAliasButton setEnabled:NO];
	} else {
		[_removeAliasButton setEnabled:YES];
	}
}


- (void)awakeFromNib
{
	_identities = nil;
	_identityQuery = NULL;
	_aliases = [[NSMutableArray alloc] init];
	_userImage = [[NSImage imageNamed:@"User"] retain];
	_groupImage = [[NSImage imageNamed:@"Group"] retain];
	_queryStartTimer = NULL;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identityTableViewSelectionDidChange:)
        name:NSTableViewSelectionDidChangeNotification object:_identityTableView];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identityTableViewSelectionDidChange:)
        name:NSTableViewSelectionIsChangingNotification object:_identityTableView];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aliasesTableViewSelectionDidChange:)
        name:NSTableViewSelectionDidChangeNotification object:_aliasesTableView];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aliasEditingDidEnd:)
        name:NSControlTextDidEndEditingNotification object:_aliasesTableView];
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchTextDidChange:)
		name:NSControlTextDidChangeNotification object:_searchText];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identityDidChange:)
		name:NSControlTextDidChangeNotification object:_fullName];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identityDidChange:)
		name:NSControlTextDidChangeNotification object:_emailAddress];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(identityDidChange:)
		name:NSControlTextDidChangeNotification object:_imageURL];
	
	[_mainWindow makeFirstResponder:_identityTableView];
	
	/* Start a new identity query and search for all identities by passing in empty string */
	[self queryForIdentitiesByName:@""];	
}


- (void)dealloc
{
	[_aliases release];
	[_identities release];
	[_userImage release];
	[_groupImage release];
	[_queryStartTimer invalidate];
	[super dealloc];
}


- (IBAction)classPopUpChanged:(id)sender
{
	BOOL hide = (BOOL)[sender indexOfSelectedItem];
	[_addIdentityPassword setHidden:hide];
	[_addIdentityVerify setHidden:hide];
	[_addIdentityVerify setHidden:hide];
	[_addIdentityPasswordLabel setHidden:hide];
	[_addIdentityVerifyLabel setHidden:hide];
	[_generatePosixNameButton setHidden:hide];
	[_addIdentityPosixNameLabel setHidden:hide];
	[_addIdentityPosixName setHidden:hide];
	
	if (hide) {
		[_addIdentityWindow makeFirstResponder:_addIdentityFullName];
	}
}


- (IBAction)createIdentity:(id)sender
{
	/* Only allow identities to be created if the Full Name is at least one character */
	if ([[_addIdentityFullName stringValue] length]) {
		CSIdentityClass class = [_addIdentityClassPopUp indexOfSelectedItem] + 1;
		if (class == kCSIdentityClassGroup) {
			[[NSApplication sharedApplication] endSheet:_addIdentityWindow returnCode:NSOKButton];
		} else if (class == kCSIdentityClassUser) {

			/* Only proceed if the Password and the Verify field contain the same value */
			 if ([[_addIdentityPassword stringValue] isEqual:[_addIdentityVerify stringValue]]) {
				BOOL generatePosixName = [_generatePosixNameButton state];

				/* Only proceed if Generate Posix Name is set or if Posix name is at least one character */
				if (generatePosixName || (!generatePosixName && [[_addIdentityPosixName stringValue] length])) {
					[[NSApplication sharedApplication] endSheet:_addIdentityWindow returnCode:NSOKButton];
				}
			}
		}
	}
}


- (IBAction)cancelIdentity:(id)sender
{
	[[NSApplication sharedApplication] endSheet:_addIdentityWindow returnCode:NSCancelButton];
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];

	if (returnCode == NSOKButton) {
		NSString *fullName = [_addIdentityFullName stringValue];
		
		if ([fullName length]) {
			CFErrorRef error;
			CSIdentityClass class = [_addIdentityClassPopUp indexOfSelectedItem] + 1;
			CFStringRef posixName = [_generatePosixNameButton state] ? kCSIdentityGeneratePosixName : (CFStringRef)[_addIdentityPosixName stringValue];
			
			/* Create a brand new identity */
			CSIdentityRef identity = CSIdentityCreate(NULL, class, (CFStringRef)fullName, posixName, kCSIdentityFlagNone, CSGetLocalIdentityAuthority());
			if (class == kCSIdentityClassUser) {
				/* If this is a user identity, add a password */
				CSIdentitySetPassword(identity, (CFStringRef)[_addIdentityPassword stringValue]);
			}
			
			/* Commit the new identity to the identity store */
			if (!CSIdentityCommit(identity, NULL, &error)) {
				NSLog(@"CSIdentityCommit returned error %@ userInfo %@)", error, [(NSError*)error userInfo] );
			}
			[self queryForIdentitiesByName:[_searchText stringValue]];
		}
    }
	
	[_addIdentityFullName setStringValue:@""];
	[_addIdentityPosixName setStringValue:@""];
	[_addIdentityPassword setStringValue:@""];
	[_addIdentityVerify setStringValue:@""];
	[_generatePosixNameButton setState:YES];
}


- (IBAction)addIdentity:(id)sender
{
	[_addIdentityWindow makeFirstResponder:_addIdentityFullName];
	[_generatePosixNameButton setState:YES];
	[_addIdentityPosixNameLabel setTextColor:[NSColor lightGrayColor]];
	[_addIdentityPosixName setEnabled:NO];
	
	/* Display a sheet that allows you to add a new user or group identity to the system */
	[[NSApplication sharedApplication] beginSheet:_addIdentityWindow modalForWindow:[sender window]
		modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:self];	
}


- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)info
{
	if (returnCode == NSAlertFirstButtonReturn) {
		NSInteger currentIndex = [_identityTableView selectedRow];

		if (currentIndex != -1) {
			NSUInteger count = [_identities count];
			CSIdentityRef identity = (CSIdentityRef)[_identities objectAtIndex:currentIndex];

			/* Don't allow us to delete the currently logged-in user */
			if (getuid() != CSIdentityGetPosixID(identity)) {
				CFErrorRef error;
				
				/* Delete the currently selected identity */
				CSIdentityDelete(identity);
				
				/* Commit the change back to the identity store */
				if (CSIdentityCommit(identity, NULL, &error)) {
					[self queryForIdentitiesByName:[_searchText stringValue]];
					NSUInteger indexToSelect = ((NSUInteger)currentIndex == count && currentIndex > 0) ? (currentIndex - 1) : currentIndex;
					[_identityTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect] byExtendingSelection:NO];
				} else {
					NSLog(@"CSIdentityCommit returned error %@ userInfo %@)", error, [(NSError*)error userInfo]);
				}
			} else {
				NSLog(@"Deleting the currently logged-in user is a bad idea");
			}
		}
	}
}


- (IBAction)removeIdentity:(id)sender
{
	NSString *currentFullName = (NSString *)CSIdentityGetFullName((CSIdentityRef)[_identities objectAtIndex:[_identityTableView selectedRow]]);
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert addButtonWithTitle:@"Delete"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete the identity \"%@\"?", currentFullName]];
	[alert setInformativeText:@"You better be sure because this can't be undone."];
	[alert beginSheetModalForWindow:_mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:self];
}


- (IBAction)addAlias:(id)sender
{
	NSUInteger lastRow = [_aliases count];
	[_aliases addObject:@""];
	[_aliasesTableView reloadData];
	[_mainWindow makeFirstResponder:_aliasesTableView];
	[_aliasesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
	[_aliasesTableView editColumn:0 row:lastRow withEvent:nil select:YES];
}


- (IBAction)removeAlias:(id)sender
{
	NSIndexSet *selected = [_aliasesTableView selectedRowIndexes];
	NSUInteger lastRow = [selected lastIndex];
	[_aliases removeObjectsAtIndexes:selected];
	[_aliasesTableView reloadData];
	[_aliasesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow - 1] byExtendingSelection:NO];
	[self updateApplyAndRevert];
}


- (void)setAliases:(NSArray *)aliases forIdentity:(CSIdentityRef)identity
{
	CFArrayRef currentAliases = CFArrayCreateCopy(NULL, CSIdentityGetAliases(identity));
	CFIndex index, count = CFArrayGetCount(currentAliases);
	
	/* First remove all the current aliases for this identity */
	for (index = 0; index < count; index++) {
		CSIdentityRemoveAlias(identity, (CFStringRef)CFArrayGetValueAtIndex(currentAliases, index));
	}
	
	/* Then add all the new aliases for this identity */
	count = aliases ? [aliases count] : 0;	
	for (index = 0; index < count; index++) {
		CSIdentityAddAlias(identity, (CFStringRef)[aliases objectAtIndex:index]);
	}
	
	CFRelease(currentAliases);
}


- (IBAction)apply:(id)sender
{
	NSInteger currentIndex = [_identityTableView selectedRow];

	if (currentIndex != -1) {
		CFErrorRef error;
		CSIdentityRef identity = (CSIdentityRef)[_identities objectAtIndex:currentIndex];

		CFStringRef fullName = (CFStringRef)[_fullName stringValue];
		CFStringRef emailAddress = (CFStringRef)[_emailAddress stringValue];
		NSString *imageURLString = [_imageURL stringValue];
		CFURLRef imageURL = (CFURLRef)[NSURL fileURLWithPath:imageURLString];
		Boolean isEnabled = (Boolean)[_isEnabled state];
		
		if (fullName) CSIdentitySetFullName(identity, fullName);
		CSIdentitySetEmailAddress(identity, CFStringGetLength(emailAddress) ? emailAddress : NULL);
		CSIdentitySetImageURL(identity, imageURL);
		[self setAliases:_aliases forIdentity:identity];

		/* Don't allow us to disable the currently logged-in user */
		if (getuid() == CSIdentityGetPosixID(identity) && isEnabled == NO) {
			NSLog(@"Disabling the currently logged-in user is a bad idea");
			[_isEnabled setState:YES];
		} else {
			CSIdentitySetIsEnabled(identity, isEnabled);
		}
		
		/* Commit the changes back to the identity store */
		if (!CSIdentityCommit(identity, NULL, &error)) {
			NSLog(@"CSIdentityCommit returned error %@ userInfo %@)", error, [(NSError*)error userInfo]);
		} else {
			[self updateApplyAndRevert];
		}
	}

	[_mainWindow makeFirstResponder:_identityTableView];
}


- (IBAction)revert:(id)sender
{
	[_mainWindow makeFirstResponder:_identityTableView];
	[self reloadIdentityAtIndex:[_identityTableView selectedRow]];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
	NSInteger count = 0;
	
    if (tv == _identityTableView) {
		count = [_identities count];
	} else if (tv == _aliasesTableView) {
		count = [_aliases count];
	}
	
	return count;
}


- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	id value = nil;
	
    if (tv == _identityTableView) {
		CSIdentityRef identity = (CSIdentityRef)[_identities objectAtIndex:row];
		if ([[tableColumn identifier] isEqual:@"Icon"]) {
			CSIdentityClass class = CSIdentityGetClass(identity);
			if (class == kCSIdentityClassUser) {
				value = _userImage;
			} else if (class == kCSIdentityClassGroup) {
				value = _groupImage;
			}
		} else if ([[tableColumn identifier] isEqual:@"Name"]) {
			value = (NSString *)CSIdentityGetFullName(identity);
		}
	} else if (tv == _aliasesTableView) {
		value = [_aliases objectAtIndex:row];
	}
	
	return [[value retain] autorelease];
}


- (void)removeAliases:(NSIndexSet *)set
{
	[_aliases removeObjectsAtIndexes:set];
	[_aliasesTableView reloadData];
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == _aliasesTableView) {
		if ([object length]) {
			[_aliases replaceObjectAtIndex:row withObject:object];
		} else {
			[self performSelector:@selector(removeAliases:) withObject:[NSIndexSet indexSetWithIndex:row] afterDelay:0.0];
		}
	}
	
	[_aliasesTableView deselectAll:self];
}


- (void)confirmPanelWillClose:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSInteger selectedRow = (NSInteger)contextInfo;
	if (returnCode == NSAlertFirstButtonReturn) {
		[self apply:self];
	}
	if (returnCode != NSAlertSecondButtonReturn) {
		[_identityTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	}
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	BOOL shouldSelect = YES;
	if (tableView == _identityTableView) {
		if ([self wasIdentityChanged] && [_identityTableView selectedRow] != row) {
			NSString *currentFullName = (NSString *)CSIdentityGetFullName((CSIdentityRef)[_identities objectAtIndex:[_identityTableView selectedRow]]);
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert addButtonWithTitle:@"Apply"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Don't Apply"];
			[alert setMessageText:[NSString stringWithFormat:@"Apple changes to identity \"%@\"?", currentFullName]];
			[alert setInformativeText:@"Click Apply if you'd like to save the changes for this identity."];
			[alert beginSheetModalForWindow:_mainWindow modalDelegate:self didEndSelector:@selector(confirmPanelWillClose:returnCode:contextInfo:) contextInfo:(void *)row];
			shouldSelect = NO;
		}
	}
	return shouldSelect;
}


@end
