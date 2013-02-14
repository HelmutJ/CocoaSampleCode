/*
     File: TableViewLinksAppDelegate.m 
 Abstract: The sample's application delegate used to manage its primary window and table view. 
  Version: 1.0 
  
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

#import "TableViewLinksAppDelegate.h"
#import "NSAttributedStringAdditions.h"
#import "LinkTextFieldCell.h"

#define COLUMN_ID_TITLE @"Title"
#define COLUMN_ID_URL @"URL"
#define COLUMN_ID_ATTR_URL @"AttributedURL"

#pragma mark -
#pragma mark Implementation
#pragma mark -

@implementation TableViewLinksAppDelegate

@synthesize window = _window;
@synthesize tableView = _tableView;

- (void)_addObjectWithTitle:(NSString *)title urlAsString:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    // Create the an attributed string with the URL
    NSAttributedString *attrStr = [NSAttributedString attributedStringWithLinkToURL:url title:urlStr];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:url, COLUMN_ID_URL, title, COLUMN_ID_TITLE, attrStr, COLUMN_ID_ATTR_URL, nil];
    [_tableViewContents addObject:dictionary];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _tableViewContents = [NSMutableArray new];

    // Use dictionaries to store our table contents. The dictionary is a simple model object.
    [self _addObjectWithTitle:@"Apple" urlAsString:@"http://www.apple.com"];
    [self _addObjectWithTitle:@"Cocoa" urlAsString:@"http://developer.apple.com/cocoa"];
    [self _addObjectWithTitle:@"AppKit Release Notes (read these today!)" urlAsString:@"http://developer.apple.com/mac/library/releasenotes/cocoa/appkit.html"];
    [self _addObjectWithTitle:@"Xcode Developer Technologies Website" urlAsString:@"http://developer.apple.com/technologies/xcode.html"];
    [self _addObjectWithTitle:@"Developer Website" urlAsString:@"http://developer.apple.com/"];
    [self _addObjectWithTitle:@"WWDC Page" urlAsString:@"http://developer.apple.com/wwdc/"];
    [self _addObjectWithTitle:@"MobileMe" urlAsString:@"http://me.com"];
    
    [_tableView reloadData];
}

- (void)dealloc {
    [_tableViewContents release];
    [super dealloc];
}


#pragma mark -
#pragma mark NSTableView delegate/datasource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_tableViewContents count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *dictionary = [_tableViewContents objectAtIndex:row];
    return [dictionary objectForKey:[tableColumn identifier]];
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([cell isKindOfClass:[LinkTextFieldCell class]]) {
        LinkTextFieldCell *linkCell = (LinkTextFieldCell *)cell;
        // Setup the work to be done when a link is clicked
        linkCell.linkClickedHandler = ^(NSURL *url, id sender) {
            [[NSWorkspace sharedWorkspace] openURL:url];
        };
    }
}

@end
