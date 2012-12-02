/*
     File: Controller.m
 Abstract: Controller for the application
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

#define EmptyTrashItemTag 56433
#define ReallyEmptyTrashItemTag 56434

#define Radio1Tag 56533
#define Radio2Tag 56534
#define Radio3Tag 56535

#define Switch1Tag 56633
#define Switch2Tag 56634

@implementation Controller

- (void)noopAction:(id)sender {
    // nothing
}

- (void)emptyTrash:(id)sender {
    if (NSRunAlertPanel(@"Warning", @"Do you really want to yada yada yada?", @"Yada?", @"No", NULL) == NSOKButton) {
        NSLog(@"Yada.");
    }
}

- (void)reallyEmptyTrash:(id)sender {
    NSLog(@"Yada.");
}

- (void)radioAction:(id)sender {
    currentRadioSetting = [sender tag];
}

- (void)switch1Action:(id)sender {
    currentSwitch1Setting = (currentSwitch1Setting ? NO : YES);
}

- (void)switch2Action:(id)sender {
    currentSwitch2Setting = (currentSwitch2Setting ? NO : YES);
}

- (void)createFlashyMenu {
    // Since IB is slightly behind the current state of the art of menu capabilities, we need to create some of the fancier examples by hand.
    NSMenu *newMenu;
    NSMenuItem *newItem;

    // Add the submenu
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Flashy" action:NULL keyEquivalent:@""];
    newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Flashy"];
    [newItem setSubmenu:newMenu];
    [newMenu release];
    [[NSApp mainMenu] addItem:newItem];
    [newItem release];

    // Add some cool items
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Images Used" action:NULL keyEquivalent:@""];
    [newItem setImage:[NSImage imageNamed:@"eomt_browsedata"]];
    [newItem setTarget:self];
    [newItem setAction:@selector(noopAction:)];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"In This Menu" action:NULL keyEquivalent:@""];
    [newItem setImage:[NSImage imageNamed:@"eomt_copy"]];
    [newItem setTarget:self];
    [newItem setAction:@selector(noopAction:)];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Were Stolen" action:NULL keyEquivalent:@""];
    [newItem setTarget:self];
    [newItem setAction:@selector(noopAction:)];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"From EOModeler" action:NULL keyEquivalent:@""];
    [newItem setImage:[NSImage imageNamed:@"eomt_cut"]];
    [newItem setTarget:self];
    [newItem setAction:@selector(noopAction:)];
    [newMenu addItem:newItem];
    [newItem release];
    
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"With no shame" action:NULL keyEquivalent:@""];
    [newItem setImage:[NSImage imageNamed:@"eomt_delete"]];
    [newItem setTarget:self];
    [newItem setAction:@selector(noopAction:)];
    [newMenu addItem:newItem];
    [newItem release];
}

- (void)createTrickyMenu {
    // There's really no need for this menu to be created programatically.  It could just as easily be created in IB.  I'm creating it here just to make it clear there's no special magic going on to get these slightly trickier features to work.
    NSMenu *newMenu;
    NSMenuItem *newItem;

    // Add the submenu
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Tricky" action:NULL keyEquivalent:@""];
    newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Tricky"];
    [newItem setSubmenu:newMenu];
    [newMenu release];
    [[NSApp mainMenu] addItem:newItem];
    [newItem release];

    // Add some tricky items
    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Empty Trash..." action:NULL keyEquivalent:@"T"];
    [newItem setTag:EmptyTrashItemTag];
    [newItem setTarget:self];
    [newItem setAction:@selector(emptyTrash:)];
    [newMenu addItem:newItem];
    [newItem release];

    [newMenu addItem:[NSMenuItem separatorItem]];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Radio 1" action:NULL keyEquivalent:@""];
    [newItem setTag:Radio1Tag];
    [newItem setTarget:self];
    [newItem setAction:@selector(radioAction:)];
    [newItem setOnStateImage:[NSImage imageNamed:@"NSMenuRadio"]];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Radio 2" action:NULL keyEquivalent:@""];
    [newItem setTag:Radio2Tag];
    [newItem setTarget:self];
    [newItem setAction:@selector(radioAction:)];
    [newItem setOnStateImage:[NSImage imageNamed:@"NSMenuRadio"]];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Radio 3" action:NULL keyEquivalent:@""];
    [newItem setTag:Radio3Tag];
    [newItem setTarget:self];
    [newItem setAction:@selector(radioAction:)];
    [newItem setOnStateImage:[NSImage imageNamed:@"NSMenuRadio"]];
    [newMenu addItem:newItem];
    [newItem release];

    [newMenu addItem:[NSMenuItem separatorItem]];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Switch1" action:NULL keyEquivalent:@""];
    [newItem setTag:Switch1Tag];
    [newItem setTarget:self];
    [newItem setAction:@selector(switch1Action:)];
    [newMenu addItem:newItem];
    [newItem release];

    newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Show Something" action:NULL keyEquivalent:@""];
    [newItem setTag:Switch2Tag];
    [newItem setTarget:self];
    [newItem setAction:@selector(switch2Action:)];
    [newMenu addItem:newItem];
    [newItem release];
}

- (void)createPopUps {
    NSView *contentView = [window contentView];
    id item;

    // Normal popup
    normalPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20.0, 20.0, 150.0, 20.0) pullsDown:NO];
    [normalPopUp addItemsWithTitles:[NSArray arrayWithObjects:@"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", @"Eleven", @"Twelve", @"Thirteen", @"Fourteen", @"Fifteen", nil]];
    [normalPopUp sizeToFit];
    [contentView addSubview:normalPopUp];

    // Normal pulldown
    normalPullDown = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20.0, 50.0, 150.0, 20.0) pullsDown:YES];
    [normalPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"Title", @"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", nil]];
    [normalPullDown sizeToFit];
    [contentView addSubview:normalPullDown];

    // Small normal popup
    smallNormalPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(200.0, 20.0, 100.0, 16.0) pullsDown:NO];
    [smallNormalPopUp addItemsWithTitles:[NSArray arrayWithObjects:@"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", @"Eleven", @"Twelve", @"Thirteen", @"Fourteen", @"Fifteen", nil]];
    [smallNormalPopUp setFont:[NSFont messageFontOfSize:10.0]];
    [smallNormalPopUp sizeToFit];
    [contentView addSubview:smallNormalPopUp];

    // Small normal pulldown
    smallNormalPullDown = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(200.0, 50.0, 100.0, 16.0) pullsDown:YES];
    [smallNormalPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"Title", @"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", nil]];
    [smallNormalPullDown setFont:[NSFont messageFontOfSize:10.0]];
    [smallNormalPullDown sizeToFit];
    [contentView addSubview:smallNormalPullDown];

    // Image popup
    imagePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20.0, 80.0, 42.0, 42.0) pullsDown:NO];
    [(NSPopUpButtonCell *)[imagePopUp cell] setBezelStyle:NSSmallIconButtonBezelStyle];
    [[imagePopUp cell] setArrowPosition:NSPopUpArrowAtBottom];

    [imagePopUp addItemWithTitle:@""];
    item = [imagePopUp itemAtIndex:0];
    [item setImage:[NSImage imageNamed:@"mailTypeASCII.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePopUp addItemWithTitle:@""];
    item = [imagePopUp itemAtIndex:1];
    [item setImage:[NSImage imageNamed:@"mailTypeMIME.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePopUp addItemWithTitle:@""];
    item = [imagePopUp itemAtIndex:2];
    [item setImage:[NSImage imageNamed:@"mailTypeNeXT.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePopUp sizeToFit];
    [contentView addSubview:imagePopUp];

    // Image pulldown
    imagePullDown = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(80.0, 80.0, 42.0, 42.0) pullsDown:YES];
    [(NSPopUpButtonCell *)[imagePullDown cell] setBezelStyle:NSSmallIconButtonBezelStyle];
    [[imagePullDown cell] setArrowPosition:NSPopUpArrowAtBottom];

    [imagePullDown addItemWithTitle:@""];
    item = [imagePullDown itemAtIndex:0];
    [item setImage:[NSImage imageNamed:@"mailTypeASCII.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePullDown addItemWithTitle:@""];
    item = [imagePullDown itemAtIndex:1];
    [item setImage:[NSImage imageNamed:@"mailTypeMIME.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePullDown addItemWithTitle:@""];
    item = [imagePullDown itemAtIndex:2];
    [item setImage:[NSImage imageNamed:@"mailTypeNeXT.tiff"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];

    [imagePullDown sizeToFit];
    [contentView addSubview:imagePullDown];

    // Popup that doesnt change item
    noSelPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(200.0, 80.0, 29.0, 29.0) pullsDown:NO];
    [(NSPopUpButtonCell *)[noSelPopUp cell] setBezelStyle:NSSmallIconButtonBezelStyle];
    [[noSelPopUp cell] setArrowPosition:NSPopUpArrowAtBottom];

    [noSelPopUp addItemsWithTitles:[NSArray arrayWithObjects:@"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", @"Eleven", @"Twelve", @"Thirteen", @"Fourteen", @"Fifteen", nil]];
    [[noSelPopUp cell] setUsesItemFromMenu:NO];
    item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"EOEntity"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[noSelPopUp cell] setMenuItem:item];
    [item release];
    [noSelPopUp setPreferredEdge:NSMaxXEdge];
    [contentView addSubview:noSelPopUp];

    // Pulldown that doesnt change item
    noSelPullDown = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(250.0, 80.0, 29.0, 29.0) pullsDown:YES];
    [(NSPopUpButtonCell *)[noSelPullDown cell] setBezelStyle:NSSmallIconButtonBezelStyle];
    [[noSelPullDown cell] setArrowPosition:NSPopUpArrowAtBottom];

    [noSelPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"title", @"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine", @"Ten", @"Eleven", @"Twelve", @"Thirteen", @"Fourteen", @"Fifteen", nil]];
    [[noSelPullDown cell] setUsesItemFromMenu:NO];
    item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"EOModel"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[noSelPullDown cell] setMenuItem:item];
    [item release];
    [noSelPullDown setPreferredEdge:NSMinXEdge];
    [contentView addSubview:noSelPullDown];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // The creation of new menus for the menu bar should be done in applicationWillFinishLaunching.
    [self createFlashyMenu];
    [self createTrickyMenu];
    [self createPopUps];
    currentRadioSetting = Radio1Tag;
    currentSwitch1Setting = NO;
    currentSwitch2Setting = NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger tag = [item tag];
    if ((tag == EmptyTrashItemTag) || (tag == ReallyEmptyTrashItemTag)) {
        BOOL shouldBeReally = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? YES : NO);
        if (shouldBeReally && (tag == EmptyTrashItemTag)) {
            [item setTitle:@"Really Empty Trash"];
            [item setKeyEquivalentModifierMask:(NSAlternateKeyMask | NSCommandKeyMask)];
            [item setAction:@selector(reallyEmptyTrash:)];
            [item setTag:ReallyEmptyTrashItemTag];
        } else if (!shouldBeReally && (tag == ReallyEmptyTrashItemTag)) {
            [item setTitle:@"Empty Trash..."];
            [item setKeyEquivalentModifierMask:NSCommandKeyMask];
            [item setAction:@selector(emptyTrash:)];
            [item setTag:EmptyTrashItemTag];
        }
        return YES;
    } else if ((tag == Radio1Tag) || (tag == Radio2Tag) || (tag == Radio3Tag)) {
        [item setState:((tag == currentRadioSetting) ? NSOnState : NSOffState)];
        return YES;
    } else if (tag == Switch1Tag) {
        [item setState:(currentSwitch1Setting ? NSOnState : NSOffState)];
        return YES;
    } else if (tag == Switch2Tag) {
        [item setTitle:(currentSwitch2Setting ? @"Hide Something" : @"Show Something")];
        return YES;
    } else {
        return YES;
    }
}

@end
