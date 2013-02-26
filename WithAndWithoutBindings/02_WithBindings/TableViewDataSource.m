/*
 
 File: TableViewDataSource.m
 
 Abstract: Contains the implementation of the data source methods for NSTableView.
 Note that this implementation is as a subclass of NSArrayController.

 Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by  Apple Inc. ("Apple") in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this Apple software constitutes acceptance of these terms.  If you do not agree with these terms, please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in this original Apple software (the "Apple Software"), to use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the Apple Software.  Neither the name, trademarks, service marks or logos of Apple Inc.  may be used to endorse or promote products derived from the Apple Software without specific prior written permission from Apple.  Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */


#import "TableViewDataSource.h"
#import "Bookmark.h"


@implementation MyArrayController


#pragma mark ======== drag and drop methods =========
/* 
 ** --------------------------------------------------------
 **   Standard table view data source drag and drop methods
 ** --------------------------------------------------------
 
 These methods implement support for drag and drop for table views.
 
 These methods are described in
 - NSTableDataSource Protocol Objective-C Reference 
 - Table View Programming Guide
 */

- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard*)pboard
{
	/*
	 If copied row has an URL, add NSURLPboardType to the declared types and write the URL to the pasteboard
	 */
	
	/*
	 For convenience, conciseness, and clarity, assume here that multiple selections are not allowed.
	 */
	unsigned int row = [rowIndexes firstIndex];
	
	/*
	 The objects display in the table view may be in a different order than they appear in the original collection.  The content may even be filtered.  The arrangedObjects method returns the objects the table view displays, in the order in which it displays them.
	 */
	NSURL *url = [[[self arrangedObjects] objectAtIndex:row] URL];
	
	/*
	 If the copied row does not have an URL, then exit
	 */
	if (url == nil)
	{
		return NO;
	}
	
	/*
	 Declare the pastboard types and write the corresponding data
	 */
	NSArray *pboardTypes = [NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil];
	[pboard declareTypes:pboardTypes owner:self];
	
    [pboard setString:[url absoluteString] forType:NSStringPboardType];
	[url writeToPasteboard:pboard];
	
	return YES;
}




- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
	if ([info draggingSource] == tableView)
	{
		return NSDragOperationNone;
    }
	
	NSDragOperation dragOp = NSDragOperationNone;
	
	NSURL *url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	
	if (url != nil)
	{
		dragOp = NSDragOperationCopy;
		/*
		 we want to put the object at, not over, the current row (contrast NSTableViewDropOn) 
		 */
		[tv setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
    return dragOp;
}


- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0)
	{
		row = 0;
	}
    
	// Can we get an URL?  If not, return NO.
	NSURL *url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	
	if (url == nil)
	{
		return NO;
	}
	
	// create and configure a new Bookmark
	Bookmark *newBookmark = [self newObject];
	[newBookmark setURL:url];
	[newBookmark setTitle:[url absoluteString]];

	/*
	 The objects display in the table view may be in a different order than they appear in the original collection.  The content may even be filtered.  Using insertObject:atArrangedObjectIndex: inserts the object at the right place, taking sort orderings and filters into account.

	 */
	[self insertObject:newBookmark atArrangedObjectIndex:row];
	[newBookmark release];

	/*
	 There is no need to update the selection detail fields etc.
	 The values of the detail fields are bound to properties of the array controller's selection. As the selection changes, the fields are updated automatically through KVO.
	 */
	return YES;		
}



#pragma mark ======== awakeFromNib =========
/* 
 ** --------------------------------------------------------
 **    awakeFromNib
 ** --------------------------------------------------------
 
 Here awakeFromNib is used to register the table view for dragged types an set the drag mask
 */

- (void)awakeFromNib
{
	[tableView setDraggingSourceOperationMask:NSDragOperationLink
									 forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationMove
									 forLocal:YES];
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
}


@end

