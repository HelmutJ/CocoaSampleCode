/*
     File: TransactionsController_Dragging.m
 Abstract: This category implements tableView data source methods to support dragging.
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

#import "TransactionsController.h"
#import "MyDocument_Pasteboard.h"

@implementation TransactionsController(Dragging)

/* Preliminary registration */

- (void)awakeFromNib {
    [_transactionTable registerForDraggedTypes:[_document readablePasteboardTypes]];
    [_transactionTable setDraggingSourceOperationMask:(NSDragOperationCopy|NSDragOperationGeneric) forLocal:YES];
    [_transactionTable setDraggingSourceOperationMask:(NSDragOperationCopy|NSDragOperationGeneric) forLocal:NO];
}


/* Data source methods for dragging out */

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    // This method will be called before the start of a drag out
    BOOL result = NO;
    if (NSNotFound != [rowIndexes firstIndex]) {
        // We ask the document to write out the selected transactions plus a file promise to the pasteboard
        [self setSelectionIndexes:rowIndexes];
        result = [_document writeSelectionToPasteboard:pboard types:[_document writablePasteboardTypes]];
    }
    return result;
}

- (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes {
    // This method will be called if we need to redeem our file promise
    NSURL *fileURL = nil;
    if (dropDestination && NSNotFound != [rowIndexes firstIndex]) {
        // We ask the document to write out the selected transactions to a file in the specified directory
        [self setSelectionIndexes:rowIndexes];
        fileURL = [_document writeSelectionToDestination:dropDestination];
    }
    return (fileURL ? [NSArray arrayWithObject:[[fileURL path] lastPathComponent]] : nil);
}


/* Data source methods for dragging in */

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // This method will be called repeatedly during a drag in, to validate it and to determine the operation type and drop location
    NSDragOperation result = NSDragOperationNone, mask = [info draggingSourceOperationMask];
    NSArray *availableTypes = [[info draggingPasteboard] types], *readableTypes = [_document readablePasteboardTypes];
    NSEnumerator *enumerator = [readableTypes objectEnumerator];
    NSString *type;

    // We always copy, but if source and destination are the same, then we do not accept the drag unless the user explicitly chooses copy
    if (tv != [info draggingSource] || 0 == (mask & NSDragOperationGeneric)) {
        while (result == NSDragOperationNone && (type = [enumerator nextObject])) {
            // In any case, we accept the drag only if the pasteboard contains one of our desired types
            if ([availableTypes containsObject:type]) {
                // We always place the drop after the last existing row
                [tv setDropRow:[tv numberOfRows] dropOperation:NSTableViewDropAbove];
                result = NSDragOperationCopy;
            }
        }
    }
    return result;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    // This method will be called when a drag in is finally dropped on our table view
    return [_document readSelectionFromPasteboard:[info draggingPasteboard]];
}

@end
