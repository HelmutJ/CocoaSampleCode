/*
     File: HoverTableDemoAppDelegate.m 
 Abstract: The NSApplication delegate class used as the NSTableViewDelegate to manage the table's content. 
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

#import "HoverTableDemoAppDelegate.h"

NSString *kIconKey = @"icon";
NSString *kNameKey = @"name";

@implementation HoverTableDemoAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Ensure the table has some initial state by "touching" the number of rows
    [tableView numberOfRows];
    
    images = [[NSArray alloc] initWithObjects:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameMobileMe], kIconKey,
                    NSImageNameMobileMe, kNameKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameUserAccounts], kIconKey,
                    NSImageNameUserAccounts, kNameKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameColorPanel], kIconKey,
                    NSImageNameColorPanel, kNameKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameApplicationIcon], kIconKey,
                    NSImageNameApplicationIcon, kNameKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameFolderSmart], kIconKey,
                    NSImageNameFolderSmart, kNameKey, nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSImage imageNamed:NSImageNameFontPanel], kIconKey,
                    NSImageNameFontPanel, kNameKey, nil], nil,
              nil];

    [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, images.count)]
                     withAnimation:NSTableViewAnimationEffectFade];
}

- (void)dealloc {
    [images release];
    [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [images count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Used by bindings on the NSTableCellView's objectValue
    NSDictionary *item = [images objectAtIndex:row];
    return item;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Bold the text in the selected items, and unbold non-selected items
    [tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        // Enumerate all the views, and find the NSTableCellViews.
        // This demo could hard-code things, as it knows that the first cell is always an
        // NSTableCellView, but it is better to have more abstract code that works
        // in more locations.
        //
        for (NSInteger column = 0; column < rowView.numberOfColumns; column++) {
            NSView *cellView = [rowView viewAtColumn:column];
            // Is this an NSTableCellView?
            if ([cellView isKindOfClass:[NSTableCellView class]]) {
                NSTableCellView *tableCellView = (NSTableCellView *)cellView;
                // It is -- grab the text field and bold the font if selected
                NSTextField *textField = tableCellView.textField;
                NSInteger fontSize = [textField.font pointSize];
                if (rowView.selected) {
                    textField.font = [NSFont boldSystemFontOfSize:fontSize];
                } else {
                    textField.font = [NSFont systemFontOfSize:fontSize];
                }
            }
        }
    }];
}

@end
