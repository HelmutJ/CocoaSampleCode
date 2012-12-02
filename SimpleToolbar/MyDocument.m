/*
     File: MyDocument.m
 Abstract: Document and Toolbar Controller Object.
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


#import "MyDocument.h"

    
static NSString* 	MyDocToolbarIdentifier 		= @"My Document Toolbar Identifier";
static NSString*	SaveDocToolbarItemIdentifier 	= @"Save Document Item Identifier";
static NSString*	SearchDocToolbarItemIdentifier 	= @"Search Document Item Identifier";

// This class knows how to validate "most" custom views.  Useful for view items we need to validate.
@interface ValidatedViewToolbarItem : NSToolbarItem
@end

@interface MyDocument (Private)
- (void)loadTextViewWithInitialData:(NSData *)data;
- (void)setupToolbar;
- (NSRange)rangeOfEntireDocument;
@end

@implementation MyDocument

- (void)dealloc {
    [activeSearchItem release];
    activeSearchItem = nil;
    [searchFieldOutlet release];
    searchFieldOutlet = nil;
    [dataFromFile release];
    dataFromFile = nil;
    [super dealloc];
}

// ==========================================================
// Standard NSDocument methods
// ==========================================================

- (NSString *)windowNibName {
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    // The search field outlet may eventually end up in the toolbar hierarchy.  If it does, it will be removed from it's current view hierarchy.
    // We need to retain it ourself to make sure it doesn't go away if it is removed from the toolbar view hierarchy.
    [searchFieldOutlet retain];
    [searchFieldOutlet removeFromSuperview];
    
    [documentWindow makeFirstResponder: documentTextView];
    [documentWindow setFrameUsingName: @"MyDocumentWindow"];
    [documentWindow setFrameAutosaveName: @"MyDocumentWindow"];

    // Do the standard thing of loading in data we may have gotten if loadDataRepresentation: was used.
    if (dataFromFile!=nil) {
	[self loadTextViewWithInitialData: dataFromFile];
	[dataFromFile autorelease];
	dataFromFile = nil;
    }
    
    // Set up the toolbar after the document nib has been loaded 
    [self setupToolbar];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Archive data in the format loadDocumentWithInitialData expects.
    NSData *dataRepresentation = nil;
    if ([aType isEqual: @"My Document Type"]) {
	dataRepresentation = [documentTextView RTFDFromRange: [self rangeOfEntireDocument]];
    }
    return dataRepresentation;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
    BOOL success = NO;
    if ([aType isEqual: @"My Document Type"]) {
	if (documentTextView!=nil) {
	    [self loadTextViewWithInitialData: data];
	} else {
	    dataFromFile = [data retain];
	}
	success = YES;
    }
    return success;
}

- (void) loadTextViewWithInitialData: (NSData *) data {
    [documentTextView replaceCharactersInRange: [self rangeOfEntireDocument] withRTFD: data];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: MyDocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [documentWindow setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = nil;
    
    if ([itemIdent isEqual: SaveDocToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
        // Set the text label to be displayed in the toolbar and customization palette 
	[toolbarItem setLabel: @"Save"];
	[toolbarItem setPaletteLabel: @"Save"];
	
	// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
	[toolbarItem setToolTip: @"Save Your Document"];
	[toolbarItem setImage: [NSImage imageNamed: @"SaveDocumentItemImage"]];
	
	// Tell the item what message to send when it is clicked 
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(saveDocument:)];
    } else if([itemIdent isEqual: SearchDocToolbarItemIdentifier]) {
        // NSToolbarItem doens't normally autovalidate items that hold custom views, but we want this guy to be disabled when there is no text to search.
        toolbarItem = [[[ValidatedViewToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];

	NSMenu *submenu = nil;
	NSMenuItem *submenuItem = nil, *menuFormRep = nil;
	
	// Set up the standard properties 
	[toolbarItem setLabel: @"Search"];
	[toolbarItem setPaletteLabel: @"Search"];
	[toolbarItem setToolTip: @"Search Your Document"];
	
        searchFieldOutlet = [[NSSearchField alloc] initWithFrame:[searchFieldOutlet frame]];
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: searchFieldOutlet];
	[toolbarItem setMinSize:NSMakeSize(30, NSHeight([searchFieldOutlet frame]))];
	[toolbarItem setMaxSize:NSMakeSize(400,NSHeight([searchFieldOutlet frame]))];

	// By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a 
	// custom menu of your own by using <item> setMenuFormRepresentation] 
	submenu = [[[NSMenu alloc] init] autorelease];
	submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

	[submenu addItem: submenuItem];
	[submenuItem setTarget: self];
	[menuFormRep setSubmenu: submenu];
	[menuFormRep setTitle: [toolbarItem label]];

        // Normally, a menuFormRep with a submenu should just act like a pull down.  However, in 10.4 and later, the menuFormRep can have its own target / action.  If it does, on click and hold (or if the user clicks and drags down), the submenu will appear.  However, on just a click, the menuFormRep will fire its own action.
        [menuFormRep setTarget: self];
        [menuFormRep setAction: @selector(searchMenuFormRepresentationClicked:)];

        // Please note, from a user experience perspective, you wouldn't set up your search field and menuFormRep like we do here.  This is simply an example which shows you all of the features you could use.
	[toolbarItem setMenuFormRepresentation: menuFormRep];
    } else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	SaveDocToolbarItemIdentifier, NSToolbarPrintItemIdentifier, NSToolbarSeparatorItemIdentifier, 
					NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
					NSToolbarSpaceItemIdentifier, SearchDocToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	SearchDocToolbarItemIdentifier, SaveDocToolbarItemIdentifier, NSToolbarPrintItemIdentifier, 
					NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if([[addedItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
	activeSearchItem = [addedItem retain];
	[activeSearchItem setTarget: self];
	[activeSearchItem setAction: @selector(searchUsingToolbarSearchField:)];
    } else if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
	[addedItem setToolTip: @"Print Your Document"];
	[addedItem setTarget: self];
    }
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
    if (removedItem==activeSearchItem) {
	[activeSearchItem autorelease];
	activeSearchItem = nil;    
    }
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual: SaveDocToolbarItemIdentifier]) {
	// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
	enable = [self isDocumentEdited];
    } else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
	enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
	enable = [[[documentTextView textStorage] string] length]>0;
    }	
    return enable;
}

- (BOOL) validateMenuItem: (NSMenuItem *) item {
    BOOL enabled = YES;
    
    if ([item action]==@selector(searchMenuFormRepresentationClicked:) || [item action]==@selector(searchUsingSearchPanel:)) {
        enabled = [self validateToolbarItem: activeSearchItem];
    }

    return enabled;
}

// ============================================================
// Utility Methods : Misc, and Target/Actions Methods
// ============================================================

- (NSRange) rangeOfEntireDocument {
    // Convenience method: Compute and return the range that encompasses the entire document 
    NSInteger length = 0;
    if ([documentTextView string]!=nil) {
	length = [[documentTextView string] length];
    }
    return NSMakeRange(0,length);
}

- (void) printDocument:(id) sender {
    // This message is send by the print toolbar item 
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView: documentTextView];
    [printOperation runOperationModalForWindow: documentWindow delegate: nil didRunSelector: NULL contextInfo: NULL];
}

- (NSArray *)rangesOfStringInDocument:(NSString *)searchString {
    NSString *string = [[documentTextView textStorage] string];
    NSMutableArray *ranges = [NSMutableArray array];
    
    NSRange thisCharRange, searchCharRange;
    searchCharRange = NSMakeRange(0, [string length]);
    while (searchCharRange.length>0) {
        thisCharRange = [string rangeOfString:searchString options:0 range:searchCharRange];
        if (thisCharRange.length>0) {
            searchCharRange.location = NSMaxRange(thisCharRange);
            searchCharRange.length = [string length] - NSMaxRange(thisCharRange);
            [ranges addObject: [NSValue valueWithRange:thisCharRange]];
        } else {
            searchCharRange = NSMakeRange(NSNotFound, 0);
        }
    }
    return ranges;
}

- (void) searchUsingToolbarSearchField:(id) sender {
    // This message is sent when the user strikes return in the search field in the toolbar 
    NSString *searchString = [(NSTextField *)[activeSearchItem view] stringValue];
    NSArray *rangesOfString = [self rangesOfStringInDocument:searchString];
    if ([rangesOfString count]) {
        if ([documentTextView respondsToSelector:@selector(setSelectedRanges:)]) {
            // NSTextView can handle multiple selections in 10.4 and later.
            [documentTextView setSelectedRanges: rangesOfString];
        } else {
            // If we can't do multiple selection, just select the first range.
            [documentTextView setSelectedRange: [[rangesOfString objectAtIndex:0] rangeValue]];
        }
    }
}

- (void) searchMenuFormRepresentationClicked:(id) sender {
    [[documentWindow toolbar] setDisplayMode: NSToolbarDisplayModeIconOnly];
    [documentWindow makeFirstResponder:[activeSearchItem view]];
}

- (void) searchUsingSearchPanel:(id) sender {
    // This message is sent from the search items custom menu representation 
    NSBeginInformationalAlertSheet ( @"searchUsingSearchPanel is not implemented (left as an exercise to the reader   )",@"",@"",@"",documentWindow,nil,nil,nil,nil,@"");
}

@end

@implementation ValidatedViewToolbarItem

- (void)validate {
    [super validate]; // Let super take care of validating the menuFormRep, etc.

    if ([[self view] isKindOfClass:[NSControl class]]) {
        NSControl *control = (NSControl *)[self view];
        id target = [control target];
        SEL action = [control action];
        
        if ([target respondsToSelector:action]) {
            BOOL enable = YES;
            if ([target respondsToSelector:@selector(validateToolbarItem:)]) {
                enable = [target validateToolbarItem:self];
            }
            [self setEnabled:enable];
            [control setEnabled:enable];
        }
    }
}

@end
