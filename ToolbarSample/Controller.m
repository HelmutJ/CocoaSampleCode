/*
     File: Controller.m
 Abstract: The controller class, which implements the object used to control and initialize this
 application and as the NSToolbar delegate.
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "Controller.h"

#define kFontSizeToolbarItemID      @"FontSize"
#define kFontStyleToolbarItemID     @"FontStyle"
#define kBlueLetterToolbarItemID    @"BlueLetter"

#pragma mark -

@implementation Controller

//--------------------------------------------------------------------------------------------------
// Setup our toolbar at launch time.
// Create the toolbar and add all the NSToolbarItems, and installing the toolbar in our window.
//--------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // configure our toolbar (note: this can also be done in Interface Builder)
    
    // If you pass NO here, you turn off the customization palette.  The palette is normally handled
    // automatically for you by NSWindow's -runToolbarCustomizationPalette: method; you'll notice
    // that the "Customize Toolbar" menu item is hooked up to that method in Interface Builder.
    // Interface Builder currently doesn't automatically show this action (or the -toggleToolbarShown: action)
    // for First Responder/NSWindow (this is a bug), so you have to manually add those methods to the
    // First Responder in Interface Builder (by hitting return on the First Responder and adding the
    // new actions in the usual way) if you want to wire up menus to them.
    //
    [toolbar setAllowsUserCustomization:YES];

    // tell the toolbar that it should save any configuration changes to user defaults.  ie. mode
    // changes, or reordering will persist.  Specifically they will be written in the app domain using
    // the toolbar identifier as the key. 
    //
    [toolbar setAutosavesConfiguration:YES]; 
    
    // tell the toolbar to show icons only by default
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    
    // initialize our font size control here to 12-point font, and set our contentView (an NSTextView) to that size
    [fontSizeStepper setIntegerValue:12];
    NSFont *theFont = [NSFont fontWithName:@"Helvetica" size:12];
    [contentView setFont:theFont];
    
    // this is a state variable that keeps track of whether we're set to plain-text, bold, or italic font
    fontStylePicked = 1;
}

//--------------------------------------------------------------------------------------------------
- (void)dealloc
{
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------
// Factory method to create autoreleased NSToolbarItems.
//
// All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller
// what toolbar items to initialize and return at various points.  Typically, for a given identifier,
// you need to generate a copy of your "master" toolbar item, and return it autoreleased.  The function
// creates an NSToolbarItem with a bunch of NSToolbarItem paramenters.
//
// It's easy to call this function repeatedly to generate lots of NSToolbarItems for your toolbar.
// 
// The label, palettelabel, toolTip, action, and menu can all be nil, depending upon what you want
// the item to do.
//--------------------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
                                       label:(NSString *)label
                                 paleteLabel:(NSString *)paletteLabel
                                     toolTip:(NSString *)toolTip
                                      target:(id)target
                                 itemContent:(id)imageOrView
                                      action:(SEL)action
                                        menu:(NSMenu *)menu
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    [item setAction:action];
    
    // Set the right attribute, depending on if we were given an image or a view
    if([imageOrView isKindOfClass:[NSImage class]]){
        [item setImage:imageOrView];
    } else if ([imageOrView isKindOfClass:[NSView class]]){
        [item setView:imageOrView];
    }else {
        assert(!"Invalid itemContent: object");
    }
    
    
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it
    // (for text-only mode), we set it up here.  Actually, you have to hand an NSMenuItem
    // (not a complete NSMenu) to the toolbar item, so we create a dummy NSMenuItem that has our real
    // menu as a submenu.
    //
    if (menu != nil)
    {
        // we actually need an NSMenuItem here, so we construct one
        NSMenuItem *mItem = [[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu:menu];
        [mItem setTitle:label];
        [item setMenuFormRepresentation:mItem];
    }
    
    return item;
}


#pragma mark -
#pragma mark Actions

//--------------------------------------------------------------------------------------------------
// When you have the toolbar in text-only mode, this action is called
// by the toolbar item's menu to make the font bigger.  We just change the stepper control and
// call our -changeFontSize: action.
//--------------------------------------------------------------------------------------------------
- (IBAction)fontSizeBigger:(id)sender
{
    [fontSizeStepper setIntegerValue:[fontSizeStepper integerValue]+1];
    [self changeFontSize:nil];
}

//--------------------------------------------------------------------------------------------------
// When you have the toolbar in text-only mode, this action is called
// by the toolbar item's menu to make the font smaller.  We just change the stepper control and
// call our -changeFontSize: action.
//--------------------------------------------------------------------------------------------------
- (IBAction)fontSizeSmaller:(id)sender
{
    [fontSizeStepper setIntegerValue:[fontSizeStepper integerValue]-1];
    [self changeFontSize:nil];
}

//--------------------------------------------------------------------------------------------------
// This action is called to change the font size.  It's called by the NSPopUpButton in the toolbar item's 
// custom view, and also by the above routines called from the toolbar item's menu (in text-only mode).
//--------------------------------------------------------------------------------------------------
- (IBAction)changeFontSize:(id)sender
{
    [fontSizeField takeIntegerValueFrom:fontSizeStepper];
    
    NSFont *theFont = [contentView font];
    theFont = [[NSFontManager sharedFontManager] convertFont:theFont toSize:[fontSizeStepper integerValue]];
    [contentView setFont:theFont range:[contentView selectedRange]];
}

//--------------------------------------------------------------------------------------------------
// This action is called from the change font style toolbar item, both from the NSPopUpButton in the
// custom view, and from the menuFormRepresentation menu.
//--------------------------------------------------------------------------------------------------
- (IBAction)changeFontStyle:(id)sender
{
    NSFont *theFont;
    NSInteger itemIndex;
    
    // If the sender is an NSMenuItem then this is the menuFormRepresentation.  Otherwise, we are
    // being called from the NSPopUpButton.  We need to check this to find out how to calculate the
    // index of the picked menu item.
    //
    if ([NSStringFromClass([sender class]) isEqual:@"NSMenuItem"])
    {
        // for ordinary NSMenus, the title is item #0, so we have to offset things
        itemIndex = [[sender menu] indexOfItem:sender];
    }
    else
    {
        // this is an NSPopUpButton, so the first useful item really is #0
        itemIndex = [sender indexOfSelectedItem];
    }
    
    [fontSizeField takeIntegerValueFrom:fontSizeStepper];
    theFont = [contentView font];
    
    // set the font properties depending upon what was selected
    switch (itemIndex)
    {
        case 0:
        {
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toNotHaveTrait:NSItalicFontMask];
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toNotHaveTrait:NSBoldFontMask];
            break;
        }
        case 1:
        {
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toNotHaveTrait:NSItalicFontMask];
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toHaveTrait:NSBoldFontMask];
            break;
        }
        case 2:
        {
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toNotHaveTrait:NSBoldFontMask];
            theFont = [[NSFontManager sharedFontManager] convertFont:theFont toHaveTrait:NSItalicFontMask];
            break;
        }
    }
    
    // make sure the fontStylePicked variable matches the menu selection plus 1, which also matches
    // the menu item tags in the menuFormRepresentation (see the menu in Interface Builder), so
    // that -validateMenuItem: can do its work. 
    //
    fontStylePicked = itemIndex + 1;
    [contentView setFont:theFont range:[contentView selectedRange]];
}

//--------------------------------------------------------------------------------------------------
// This is called by the appropriate toolbar item to toggle blue text on/off.
//--------------------------------------------------------------------------------------------------
- (IBAction)blueText:(id)sender
{
    if (![[contentView textColor] isEqual:[NSColor blueColor]])
    {
        [contentView setTextColor:[NSColor blueColor] range:[contentView selectedRange]];
    }
    else
    {
        [contentView setTextColor:[NSColor controlTextColor] range:[contentView selectedRange]];
    }
}

//--------------------------------------------------------------------------------------------------
// The NSToolbarPrintItem NSToolbarItem will sent the -printDocument: message to its target.
// Since we wired its target to be ourselves in -toolbarWillAddItem:, we get called here when
// the user tries to print by clicking the toolbar item.
//--------------------------------------------------------------------------------------------------
- (void)printDocument:(id)sender
{
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView: contentView];
    [printOperation runOperationModalForWindow: [contentView window] delegate:nil didRunSelector:nil contextInfo:nil];
}


#pragma mark -
#pragma mark Menu Item Validation

//--------------------------------------------------------------------------------------------------
// Update or validate our menu items
//--------------------------------------------------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // find out which menu item we are attempting to update by examining it's action selector
    //
    if ([menuItem action] == @selector(changeFontStyle:))
    {
        // update the menu item's checkmark state if the menu matches are tracked chosen menu item
        if ([menuItem tag] == fontStylePicked)
        {
            [menuItem setState:NSOnState];
        }
        else
        {
            [menuItem setState:NSOffState];
        }

    }
    return YES;
}


#pragma mark -
#pragma mark NSToolbarItemValidation

//--------------------------------------------------------------------------------------------------
// We don't do anything useful here (and we don't really have to implement this method) but you could
// if you wanted to. If, however, you want to have validation checks on your standard NSToolbarItems
// (with images) and have inactive ones grayed out, then this is the method for you.
// It isn't called for custom NSToolbarItems (with custom views); you'd have to override -validate:
// (see NSToolbarItem.h for a discussion) to get it to do so if you wanted it to.
// If you don't implement this method, the NSToolbarItems are enabled by default.
//--------------------------------------------------------------------------------------------------
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    // You could check [theItem itemIdentifier] here and take appropriate action if you wanted to
    return YES;
}


#pragma mark -
#pragma mark NSToolbarDelegate

//--------------------------------------------------------------------------------------------------
// This is an optional delegate method, called when a new item is about to be added to the toolbar.
// This is a good spot to set up initial state information for toolbar items, particularly ones
// that you don't directly control yourself (like with NSToolbarPrintItemIdentifier here).
// The notification's object is the toolbar, and the @"item" key in the userInfo is the toolbar item
// being added.
//--------------------------------------------------------------------------------------------------
- (void)toolbarWillAddItem:(NSNotification *)notif
{
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey:@"item"];
    
    // Is this the printing toolbar item?  If so, then we want to redirect it's action to ourselves
    // so we can handle the printing properly; hence, we give it a new target.
    //
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier])
    {
        [addedItem setToolTip:@"Print your document"];
        [addedItem setTarget:self];
    }
}  

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.
// It takes an identifier, and returns the matching NSToolbarItem. It also takes a parameter telling
// whether this toolbar item is going into an actual toolbar, or whether it's going to be displayed
// in a customization palette.
//--------------------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = nil;

    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    if ([itemIdentifier isEqualToString:kFontStyleToolbarItemID])
    {
        // 1) Font style toolbar item
        toolbarItem = [self toolbarItemWithIdentifier:kFontStyleToolbarItemID
                                                               label:@"Font Style"
                                                         paleteLabel:@"Font Style"
                                                             toolTip:@"Change your font style"
                                                              target:self
                                                         itemContent:stylePopUpView
                                                              action:nil
                                                                menu:fontStyleMenu];
    }  
    else if ([itemIdentifier isEqualToString:kFontSizeToolbarItemID])
    {   
        // 2) Font size toolbar item
        toolbarItem = [self toolbarItemWithIdentifier:kFontSizeToolbarItemID
                                                label:@"Font Size"
                                          paleteLabel:@"Font Size"
                                              toolTip:@"Grow or shrink the size of your font"
                                               target:self
                                          itemContent:fontSizeView
                                               action:nil
                                                 menu:fontSizeMenu];
    }   
    else if ([itemIdentifier isEqualToString:kBlueLetterToolbarItemID])
    {    
        // 3) Blue text toolbar item
        // often using an image will be your standard case.  You'll notice that a selector is passed
        // for the action (blueText:), which will be called when the image-containing toolbar item is clicked.
        //
        toolbarItem = [self toolbarItemWithIdentifier:kBlueLetterToolbarItemID
                                                label:@"Blue Text"
                                          paleteLabel:@"Blue Text"
                                              toolTip:@"This toggles blue text on/off"
                                               target:self
                                          itemContent:[NSImage imageNamed:@"blueLetter.tif"]
                                               action:@selector(blueText:)
                                                 menu:nil];        
    }
    
    return toolbarItem;
}

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.  
//--------------------------------------------------------------------------------------------------
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:   kFontStyleToolbarItemID,
                                        kFontSizeToolbarItemID,
                                        kBlueLetterToolbarItemID,
                                        NSToolbarPrintItemIdentifier,
                                        nil];
    // note:
    // that since our toolbar is defined from Interface Builder, an additional separator and customize
    // toolbar items will be automatically added to the "default" list of items.
}

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
//--------------------------------------------------------------------------------------------------
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:   kFontStyleToolbarItemID,
                                        kFontSizeToolbarItemID,
                                        kBlueLetterToolbarItemID,
                                        NSToolbarSpaceItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier,
                                        NSToolbarPrintItemIdentifier,
                                        nil];
    // note:
    // that since our toolbar is defined from Interface Builder, an additional separator and customize
    // toolbar items will be automatically added to the "default" list of items.
}

@end
