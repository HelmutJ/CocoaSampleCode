/*
     File: TableViewVariableRowHeightsAppDelegate.m 
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

#import "TableViewVariableRowHeightsAppDelegate.h"
#define WRAPPER_COLUMN_ID @"Wrapper"

@implementation TableViewVariableRowHeightsAppDelegate

@synthesize tableView = _tableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Store off the initial table column width. We use this as a constant for calculating the height of a given row.
    _tableColumnWidth = [[_tableView tableColumnWithIdentifier:WRAPPER_COLUMN_ID] width];
    
    _tableViewContents = [NSMutableArray new];
    
    // Add some short and long strings that we want to wrap
    [_tableViewContents addObject:@"Hello world!\nHello World line two!"];
    [_tableViewContents addObject:@"Let's add some sample text that can wrap and truncate.."];
    [_tableViewContents addObject:@"I think it is time to go outside and ride the unicycle around town for a bit. Maybe down Lombard Street? I bet we could go faster than the cars."];
    [_tableViewContents addObject:@"Well, it turns out going 25 mph down Lombard Street wasn't such a good idea."];
    [_tableViewContents addObject:@"At least I'm still here to give tips and tricks!"];
    [_tableViewContents addObject:@"A few tips, a few tricks, a little bit of Cocoa, and a little bit of caffeine."];
    
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
    // Return the same value for any table column -- it is just a string
    return [_tableViewContents objectAtIndex:row];
}

- (void)tableViewColumnDidResize:(NSNotification *)notification {
    _tableColumnWidth = [[_tableView tableColumnWithIdentifier:WRAPPER_COLUMN_ID] width];
    // Tell the table that we will have changed the row heights
    [_tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _tableView.numberOfRows)]];    
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    // It is important to use a constant value when calculating the height. Querying the tableColumn width will not work, since it dynamically changes as the user resizes -- however, we don't get a notification that the user "did resize" it until after the mouse is let go. We use the latter as a hook for telling the table that the heights changed. We must return the same height from this method every time, until we tell the table the heights have changed. Not doing so will quicly cause drawing problems.
    NSTableColumn *tableColumnToWrap = [_tableView tableColumnWithIdentifier:WRAPPER_COLUMN_ID];
    NSInteger columnToWrap = [_tableView.tableColumns indexOfObject:tableColumnToWrap];

    // Grab the fully prepared cell with our content filled in. Note that in IB the cell's Layout is set to Wraps.
    NSCell *cell = [tableView preparedCellAtColumn:columnToWrap row:row];
    
    // See how tall it naturally would want to be if given a restricted with, but unbound height
    NSRect constrainedBounds = NSMakeRect(0, 0, _tableColumnWidth, CGFLOAT_MAX);
    NSSize naturalSize = [cell cellSizeForBounds:constrainedBounds];

    // Make sure we have a minimum height -- use the table's set height as the minimum.
    if (naturalSize.height > [_tableView rowHeight]) {
        return naturalSize.height;
    } else {
        return [_tableView rowHeight];
    }
}


#pragma mark -

@end