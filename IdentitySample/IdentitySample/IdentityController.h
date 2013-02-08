/*
     File: IdentityController.h
 Abstract: n/a
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

#import <Cocoa/Cocoa.h>


@interface IdentityController : NSObject {
	IBOutlet NSWindow *_mainWindow;
	IBOutlet NSTableView *_identityTableView;
	IBOutlet NSTableView *_aliasesTableView;
	IBOutlet NSSearchField *_searchText;
	IBOutlet NSTextField *_fullName;
	IBOutlet NSTextField *_posixName;
	IBOutlet NSTextField *_emailAddress;
	IBOutlet NSTextField *_uuid;
	IBOutlet NSTextField *_posixID;
	IBOutlet NSTextField *_imageURL;
	IBOutlet NSTextField *_imageDataType;
	IBOutlet NSImageView *_imageView;
	IBOutlet NSButton *_isEnabled;
	IBOutlet NSButton *_applyNowButton;
	IBOutlet NSButton *_revertButton;
	IBOutlet NSButton *_addAliasButton;
	IBOutlet NSButton *_removeAliasButton;
	IBOutlet NSButton *_addIdentityButton;
	IBOutlet NSButton *_removeIdentityButton;
	IBOutlet NSButton *_generatePosixNameButton;
	IBOutlet NSWindow *_addIdentityWindow;
	IBOutlet NSPopUpButton *_addIdentityClassPopUp;
	IBOutlet NSTextField *_addIdentityFullName;
	IBOutlet NSTextField *_addIdentityPosixName;
	IBOutlet NSTextField *_addIdentityPasswordLabel;
	IBOutlet NSTextField *_addIdentityVerifyLabel;
	IBOutlet NSTextField *_addIdentityPosixNameLabel;
	IBOutlet NSSecureTextField *_addIdentityPassword;
	IBOutlet NSSecureTextField *_addIdentityVerify;
	NSMutableArray *_aliases;
	NSMutableArray *_identities;
	NSImage *_userImage;
	NSImage *_groupImage;
	CSIdentityQueryRef _identityQuery;
	NSTimer *_queryStartTimer;
}

- (IBAction)addIdentity:(id)sender;
- (IBAction)removeIdentity:(id)sender;
- (IBAction)addAlias:(id)sender;
- (IBAction)removeAlias:(id)sender;
- (IBAction)enableToggled:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)revert:(id)sender;

- (IBAction)createIdentity:(id)sender;
- (IBAction)cancelIdentity:(id)sender;
- (IBAction)classPopUpChanged:(id)sender;
- (IBAction)generatePosixNameToggled:(id)sender;

@end
