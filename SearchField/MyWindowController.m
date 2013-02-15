/*
     File: MyWindowController.m 
 Abstract: Sample's main NSWindowController "TestWindow"
  
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
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"

@implementation MyWindowController

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[builtInKeywords release];
	[allKeywords release];
	
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// add the searchMenu to this control, allowing recent searches to be added.
	//
	// note that we could build this menu inside our nib, but for clarity we're
	// building the menu in code to illustrate the use of tags:
	//		NSSearchFieldRecentsTitleMenuItemTag, NSSearchFieldNoRecentsMenuItemTag, etc.
	//
	if ([searchField respondsToSelector: @selector(setRecentSearches:)])
	{
		NSMenu *searchMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		[searchMenu setAutoenablesItems:YES];
		
		// first add our custom menu item (Important note: "action" MUST be valid or the menu item is disabled)
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Custom" action:@selector(actionMenuItem:) keyEquivalent:@""];
		[item setTarget: self];
		[searchMenu insertItem:item atIndex:0];
		[item release];
		
		// add our own separator to keep our custom menu separate
		NSMenuItem *separator =  [NSMenuItem separatorItem];
		[searchMenu insertItem:separator atIndex:1];

		NSMenuItem *recentsTitleItem = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action:nil keyEquivalent:@""];
		// tag this menu item so NSSearchField can use it and respond to it appropriately
		[recentsTitleItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[searchMenu insertItem:recentsTitleItem atIndex:2];
		[recentsTitleItem release];
		
		NSMenuItem *norecentsTitleItem = [[NSMenuItem alloc] initWithTitle:@"No recent searches" action:nil keyEquivalent:@""];
		// tag this menu item so NSSearchField can use it and respond to it appropriately
		[norecentsTitleItem setTag:NSSearchFieldNoRecentsMenuItemTag];
		[searchMenu insertItem:norecentsTitleItem atIndex:3];
		[norecentsTitleItem release];
		
		NSMenuItem *recentsItem = [[NSMenuItem alloc] initWithTitle:@"Recents" action:nil keyEquivalent:@""];
		// tag this menu item so NSSearchField can use it and respond to it appropriately
		[recentsItem setTag:NSSearchFieldRecentsMenuItemTag];	
		[searchMenu insertItem:recentsItem atIndex:4];
		[recentsItem release];
		
		NSMenuItem *separatorItem = (NSMenuItem*)[NSMenuItem separatorItem];
		// tag this menu item so NSSearchField can use it, by hiding/show it appropriately:
		[separatorItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[searchMenu insertItem:separatorItem atIndex:5];
		
		NSMenuItem *clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear" action:nil keyEquivalent:@""];
		[clearItem setTag:NSSearchFieldClearRecentsMenuItemTag];	// tag this menu item so NSSearchField can use it
		[searchMenu insertItem:clearItem atIndex:6];
		[clearItem release];
		
		id searchCell = [searchField cell];
		[searchCell setMaximumRecents:20];
		[searchCell setSearchMenuTemplate:searchMenu];
	}
	
	// build the list of keyword strings for our type completion dropdown list in NSSearchField
	builtInKeywords = [[NSMutableArray alloc] initWithObjects:
					@"Favorite", @"Favorite1", @"Favorite11", @"Favorite3", @"Vacations1", @"Vacations2",
					@"Hawaii", @"Family", @"Important", @"Important2",@"Personal", nil];
}

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}


#pragma mark -
#pragma mark Custom sheet

// -------------------------------------------------------------------------------
//	sheetDidEnd:sheet:returnCode:returnCode:contextInfo:
// -------------------------------------------------------------------------------
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[sheet orderOut:self];
}

// -------------------------------------------------------------------------------
//	sheetDoneButtonAction:
// -------------------------------------------------------------------------------
- (IBAction)sheetDoneButtonAction:(id)sender
{
	[NSApp endSheet:simpleSheet];
}

// -------------------------------------------------------------------------------
//	actionMenuItem:
// -------------------------------------------------------------------------------
- (IBAction)actionMenuItem:(id)sender
{
	[NSApp beginSheet:simpleSheet modalForWindow:[self window] modalDelegate:self
				didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


#pragma mark -
#pragma mark Keyword search handling

// -------------------------------------------------------------------------------
//	allKeywords:
//
//	This method builds our keyword array for use in type completion (dropdown list
//	in NSSearchField).
// -------------------------------------------------------------------------------
- (NSArray *)allKeywords
{
    NSArray *array = [[[NSArray alloc] init] autorelease];
    unsigned int i,count;

    if (allKeywords == nil)
	{
        allKeywords = [builtInKeywords mutableCopy];

        if (array != nil)
		{
            count = [array count];
            for (i=0; i<count; i++)
			{
                if ([allKeywords indexOfObject:[array objectAtIndex:i]] == NSNotFound)
                    [allKeywords addObject:[array objectAtIndex:i]];
            }
        }
        [allKeywords sortUsingSelector:@selector(compare:)];
    }
    return allKeywords;
}

// -------------------------------------------------------------------------------
//	control:textView:completions:forPartialWordRange:indexOfSelectedItem:
//
//	Use this method to override NSFieldEditor's default matches (which is a much bigger
//	list of keywords).  By not implementing this method, you will then get back
//	NSSearchField's default feature.
// -------------------------------------------------------------------------------
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
							forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int*)index
{
    NSMutableArray*	matches = NULL;
    NSString*		partialString;
    NSArray*		keywords;
    unsigned int	i,count;
    NSString*		string;

    partialString = [[textView string] substringWithRange:charRange];
    keywords      = [self allKeywords];
    count         = [keywords count];
    matches       = [NSMutableArray array];

    // find any match in our keyword array against what was typed -
	for (i=0; i< count; i++)
	{
        string = [keywords objectAtIndex:i];
        if ([string rangeOfString:partialString
						  options:NSAnchoredSearch | NSCaseInsensitiveSearch
							range:NSMakeRange(0, [string length])].location != NSNotFound)
		{
            [matches addObject:string];
        }
    }
    [matches sortUsingSelector:@selector(compare:)];
	
	return matches;
}

// -------------------------------------------------------------------------------
//	controlTextDidChange:
//
//	The text in NSSearchField has changed, try to attempt type completion.
// -------------------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification *)obj
{
	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];

    if (!completePosting && !commandHandling)	// prevent calling "complete" too often
	{
        completePosting = YES;
        [textView complete:nil];
        completePosting = NO;
    }
}
    
// -------------------------------------------------------------------------------
//	control:textView:commandSelector
//
//	Handle all commend selectors that we can handle here
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
	
	if ([textView respondsToSelector:commandSelector])
	{
        commandHandling = YES;
        [textView performSelector:commandSelector withObject:nil];
        commandHandling = NO;
		
		result = YES;
    }
	
    return result;
}

@end
