/*
     File: ATComplexOutlineController.m 
 Abstract: 
 The main controller for the "Complex Outline View" example window.
  
  Version: 1.3 
  
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

#import "ATComplexOutlineController.h"
#import "ATTableCellView.h"
#import "ATColorView.h"

@implementation ATComplexOutlineController

- (NSString *)windowNibName {
    return @"ATComplexOutlineWindow";
}

- (void)dealloc {
    [_rootContents release];
    _rootContents = nil;
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSURL *url = [NSURL fileURLWithPath:@"/Library/Desktop Pictures"];
    _rootContents = [[ATDesktopFolderEntity alloc] initWithFileURL:url];
    [_outlineView reloadData];
    [_outlineView registerForDraggedTypes:[NSArray arrayWithObjects:(id)kUTTypeURL, nil]];
    [_outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (void)pathCtrlValueChanged:(id)sender {
    NSURL *url = [_pathCtrlRootDirectory objectValue];
    _rootContents = [[ATDesktopFolderEntity alloc] initWithFileURL:url];
    [_outlineView reloadData];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return _rootContents.children.count;
    } else if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        return ((ATDesktopFolderEntity *)item).children.count;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [_rootContents.children objectAtIndex:index];
    } else {
        return [((ATDesktopFolderEntity *)item).children objectAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[ATDesktopFolderEntity class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    // Every regular view uses bindings to the item. The "Date Cell" needs to have the date extracted from the fileURL
    if ([[tableColumn identifier] isEqualToString:@"DateCell"]) {
        id dateValue;
        if ([[item fileURL] getResourceValue:&dateValue forKey:NSURLContentModificationDateKey error:NULL]) {
            return dateValue;
        } else {
            return nil;
        }
    }
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[ATDesktopFolderEntity class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        // Everything is setup in bindings
        return [outlineView makeViewWithIdentifier:@"GroupCell" owner:self];
    } else {
        NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
        if ([result isKindOfClass:[ATTableCellView class]]) {
            ATTableCellView *cellView = (ATTableCellView *)result;
            // setup the color; we can't do this in bindings
            cellView.colorView.drawBorder = YES;
            cellView.colorView.backgroundColor = [item fillColor];
        }
        // Use a shared date formatter on the DateCell for better performance. Otherwise, it is encoded in every NSTextField
        if ([[tableColumn identifier] isEqualToString:@"DateCell"]) {
            [(id)result setFormatter:_sharedDateFormatter];
        }
        return result;
    }
    return nil;
}    

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    return (id <NSPasteboardWriting>)item;
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    [_itemBeingDragged release];
    _itemBeingDragged = nil;

    // If only one item is being dragged, mark it so we can reorder it with a special pboard indicator
    if (draggedItems.count == 1) {
        _itemBeingDragged = [[draggedItems lastObject] retain];
    }
}

- (NSDictionary *)_pasteboardReadingOptions {
    // Only file urls that contain images or folders
    NSMutableArray *fileTypes = [NSMutableArray arrayWithObject:(id)kUTTypeFolder];
    [fileTypes addObjectsFromArray:[NSImage imageTypes]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, fileTypes, NSPasteboardURLReadingContentsConformToTypesKey, nil];
    return options;
}

/* When validating the contents of the pasteboard, it is best practice to use -canReadObjectForClasses:arrayWithObject:options: since it is possible for it to avoid reading and creating objects for every pasteboard item.
 */
- (BOOL)_containsAcceptableURLsFromPasteboard:(NSPasteboard *)draggingPasteboard {
    return [draggingPasteboard canReadObjectForClasses:[NSArray arrayWithObject:[NSURL class]] options:[self _pasteboardReadingOptions]];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    // Only let dropping on the entire table or a folder
    if (item == nil || [item isKindOfClass:[ATDesktopFolderEntity class]]) {
        // If the sender is ourselves, then we accept it as a move or copy, depending on the modifier key
        if ([info draggingSource] == outlineView) {
            BOOL isCopy = [info draggingSourceOperationMask] == NSDragOperationCopy;
            if (isCopy) {
                info.animatesToDestination = YES;
                return NSDragOperationCopy;
            } else {
                if (_itemBeingDragged) {
                    // We have a single item being dragged to move; validate if we can move it or not
                    // A move is only valid if the target isn't a child of the thing being dragged. We validate that now
                    id itemWalker = item;
                    while (itemWalker) {
                        if (itemWalker == _itemBeingDragged) {
                            return NSDragOperationNone; // Can't do it!
                        }
                        itemWalker = [outlineView parentForItem:itemWalker];
                    }
                    return NSDragOperationMove;            
                } else {
                    // For multiple items, we do a copy and don't allow moving
                    info.animatesToDestination = YES;
                    return NSDragOperationCopy;
                }
            }        
        } else {
            // Only accept drops that have at least one URL on the pasteboard which contains an image or a folder
            if ([self _containsAcceptableURLsFromPasteboard:[info draggingPasteboard]]) {
                info.animatesToDestination = YES;
                return NSDragOperationCopy;
            }
        }
    }
    return NSDragOperationNone;
}

// Multiple item dragging support. Implementation of this method is required to change the drag images into what we want them to look like when over our view
- (void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo {
    if ([draggingInfo draggingSource] != outlineView) {
        // The source isn't us, so update the drag images
        // We will be doing an insertion; update the dragging items to have an appropriate image. We also iterate over generic pasteboard items, and set the imageComponentsProvider to nil so they will fade out.
        NSArray *classes = [NSArray arrayWithObjects:[ATDesktopEntity class], [NSPasteboardItem class], nil];
        
        // Create a copied temporary cell to draw to images
        NSTableColumn *tableColumn = [_outlineView outlineTableColumn];
        
        // Create a new cell frame based on the basic attributes
        NSRect cellFrame = NSMakeRect(0, 0, [tableColumn width], [outlineView rowHeight]);
        
        // Subtract out the intercellSpacing from the width only. The rowHeight is sans-spacing
        cellFrame.size.width -= [outlineView intercellSpacing].width;

        // Grab a basic view to use for creating sample images and data; we will reuse it for each dragged item
        ATTableCellView *tableCellView = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
        
        __block NSInteger validCount = 0;
        [draggingInfo enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
            if ([draggingItem.item isKindOfClass:[ATDesktopEntity class]]) {
                ATDesktopEntity *entity = (ATDesktopEntity *)draggingItem.item;
                draggingItem.draggingFrame = cellFrame;
                draggingItem.imageComponentsProvider = ^(void) {
                    // Force the image to be generated right now, instead of lazily doing it
                    if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
                        ((ATDesktopImageEntity *)entity).image = [[[NSImage alloc] initByReferencingURL:entity.fileURL] autorelease];
                    }
                    // Setup the cell with this temporary data
                    tableCellView.objectValue = entity; // This is what bindings normally does for us. Our sub-views are bound to this value.
                    tableCellView.frame = cellFrame;
                    // Ask the cell view for the image components from that cell
                    return [tableCellView draggingImageComponents];
                };
                validCount++;
            } else {
                // Non-valid item (a generic NSPasteboardItem).
                // Make the drag images go away
                draggingItem.imageComponentsProvider = nil;
            }
        }];
        draggingInfo.numberOfValidItemsForDrop = validCount;
    }
}


- (void)_performInsertWithDragInfo:(id <NSDraggingInfo>)info parentItem:(ATDesktopFolderEntity *)destinationFolderEntity childIndex:(NSInteger)childIndex {
    // NSOutlineView's root is nil
    id outlineParentItem = destinationFolderEntity == _rootContents ? nil : destinationFolderEntity;

    NSInteger outlineColumnIndex = [[_outlineView tableColumns] indexOfObject:[_outlineView outlineTableColumn]];
    
    // Enumerate all items dropped on us and create new model objects for them    
    NSArray *classes = [NSArray arrayWithObject:[ATDesktopEntity class]];
    __block NSInteger insertionIndex = childIndex;
    
    [info enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:[self _pasteboardReadingOptions] usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        // the item is our new model object -- created by the classes via the pasteboard reading support
        ATDesktopEntity *entity = (ATDesktopEntity *)draggingItem.item;
        
        // Add it to the model
        [destinationFolderEntity.children insertObject:entity atIndex:insertionIndex];
        
        // Tell the outlineview of the change
        [_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] inParent:outlineParentItem withAnimation:NSTableViewAnimationEffectGap];
        
        // Update the final frame of the dragging item
        NSInteger row = [_outlineView rowForItem:entity];
        draggingItem.draggingFrame = [_outlineView frameOfCellAtColumn:outlineColumnIndex row:row];
        
        // Insert all children one after another
        insertionIndex++;
    }];    
}

- (void)_performDragReorderWithDragInfo:(id <NSDraggingInfo>)info parentItem:(ATDesktopFolderEntity *)destinationFolderEntity childIndex:(NSInteger)childIndex {
    ATDesktopFolderEntity *oldParent = [_outlineView parentForItem:_itemBeingDragged];
    if (oldParent == nil) oldParent = _rootContents;
    NSInteger fromIndex = [oldParent.children indexOfObject:_itemBeingDragged];
    [oldParent.children removeObjectAtIndex:fromIndex];
    if (oldParent == destinationFolderEntity) {
        // Consider the item being deleted before it is being inserted. 
        // This is because we are inserting *before* childIndex, and *not* after it (which is what the move API does).
        if (fromIndex < childIndex) {
            childIndex--;
        }
    }
    
    [destinationFolderEntity.children insertObject:_itemBeingDragged atIndex:childIndex];
    
    // NSOutlineView doesn't have a way of setting the root item
    if (oldParent == _rootContents) oldParent = nil;
    if (destinationFolderEntity == _rootContents) destinationFolderEntity = nil;
    [_outlineView moveItemAtIndex:fromIndex inParent:oldParent toIndex:childIndex inParent:destinationFolderEntity];
}    


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(ATDesktopEntity *)item childIndex:(NSInteger)childIndex {
    ATDesktopFolderEntity *destinationFolderEntity = nil;
    if (item == nil) {
        destinationFolderEntity = _rootContents;
    } else if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        destinationFolderEntity = (ATDesktopFolderEntity *)item;
    } else {
        NSAssert(NO, @"Internal error: expecting a folder entity for dropping onto!");
    }

    // If it was a drop "on", then we add it at the start
    if (childIndex == NSOutlineViewDropOnItemIndex) {
        childIndex = 0;
    }
    
    [_outlineView beginUpdates];
    // Are we copying the data or moving something?
    if (_itemBeingDragged == nil || [info draggingSourceOperationMask] == NSDragOperationCopy) {
        // Yes, this is an insert from the pasteboard (even if it is a copy of _itemBeingDragged)
        [self _performInsertWithDragInfo:info parentItem:destinationFolderEntity childIndex:childIndex];
    } else {
        [self _performDragReorderWithDragInfo:info parentItem:destinationFolderEntity childIndex:childIndex];
    }
    [_outlineView endUpdates];
    
    [_itemBeingDragged release];
    _itemBeingDragged = nil;
    
    return YES;
}

- (void)_removeItemAtRow:(NSInteger)row {
    id item = [_outlineView itemAtRow:row];
    ATDesktopFolderEntity *parent = (ATDesktopFolderEntity *)[_outlineView parentForItem:item];
    if (parent == nil) {
        parent = _rootContents;
    }
    NSInteger indexInParent = [parent.children indexOfObject:item];
    [parent.children removeObjectAtIndex:indexInParent];
    
    if (parent == _rootContents) {
        parent = nil;
    }
    [_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:indexInParent] inParent:parent withAnimation:NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft];    
}

- (IBAction)btnDeleteRowClicked:(id)sender {
    NSInteger row = [_outlineView rowForView:sender];
    if (row != -1) {
        // Take care of the case of the user clicking on a row that was in the middle of being deleted
        [self _removeItemAtRow:row];
    }
}

- (IBAction)btnDeletedSelectedRowsClicked:(id)sender {
    [_outlineView beginUpdates];
    [_outlineView.selectedRowIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
        [self _removeItemAtRow:index];        
    }];
    [_outlineView endUpdates];
}


- (IBAction)btnInCellClicked:(id)sender {
    NSInteger row = [_outlineView rowForView:sender];
    ATDesktopEntity *entity = [_outlineView itemAtRow:row];
    [[NSWorkspace sharedWorkspace] selectFile:[entity.fileURL path] inFileViewerRootedAtPath:nil];
}

- (IBAction)btnDemoMove:(id)sender {
    // Move the selected item down one
    NSInteger selectedRow = [_outlineView selectedRow];
    if (selectedRow != -1) {
        id item = [[[_outlineView itemAtRow:selectedRow] retain] autorelease]; // retain the item as we are removing it from our array
        // Grab the parent for this item
        ATDesktopFolderEntity *parent = [_outlineView parentForItem:item];
        // The parent may be nil, so we use the root if it is
        if (parent == nil) {
            parent = _rootContents;
        }
        // Find out where it currently is
        NSInteger indexInParent = [parent.children indexOfObject:item];
        // Then remove it
        [parent.children removeObjectAtIndex:indexInParent];
        
        // Move it one index further down, or back to the start, if it would already be at the end.
        NSInteger targetIndexInParent = indexInParent + 1;
        if (targetIndexInParent > [parent.children count]) {
            targetIndexInParent = 0; // back to the start
        }
        [parent.children insertObject:item atIndex:targetIndexInParent];
        
        // Tell outlineview about our change to our model; but of course, it uses 'nil' as the root item so we have to move back to nil if we were using the root as the parent.
        if (parent == _rootContents) {
            parent = nil;
        }
        
        [_outlineView moveItemAtIndex:indexInParent inParent:parent toIndex:targetIndexInParent inParent:parent];
    } else {
        NSRunAlertPanel(@"Select something!", @"Select a row for an example of moving it down...", @"OK", nil, nil);
    }
}

- (IBAction)btnDemoBatchedMoves:(id)sender {
    // Swap all the children of the first two expandable items
    ATDesktopFolderEntity *firstParent = nil;
    ATDesktopFolderEntity *secondParent = nil;
    for (ATDesktopEntity *entity in _rootContents.children) {
        if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
            ATDesktopFolderEntity *folderEntity = (ATDesktopFolderEntity *)entity;
            if (firstParent == nil) {
                firstParent = folderEntity;
            } else {
                secondParent = folderEntity;
                break;
            }
        }
    }
    if (firstParent && secondParent) {
        [_outlineView beginUpdates];
        // Move all the first children to the second array
        for (NSInteger i = 0; i < firstParent.children.count; i++) {
            [_outlineView moveItemAtIndex:0 inParent:firstParent toIndex:i inParent:secondParent];
        }
        // Move all the children from the second to the first. We have to account for the fact that we just moved all the first items to this one.
        NSInteger childrenOffset = firstParent.children.count;
        for (NSInteger i = 0; i < secondParent.children.count; i++) {
            [_outlineView moveItemAtIndex:childrenOffset inParent:secondParent toIndex:i inParent:firstParent];
        }
        // Do the changes on our model, and tell the OV we are done
        NSMutableArray *firstParentChildren = [firstParent.children retain];
        firstParent.children = secondParent.children;
        secondParent.children = firstParentChildren;
        [firstParentChildren release];
        [_outlineView endUpdates];
    } else {
        NSRunAlertPanel(@"Expand something!!", @"Couldn't find two parents to do demo move with. Expand some items!", @"OK", nil, nil);
    }    
}

- (IBAction)chkbxFloatGroupRowsClicked:(id)sender {
    BOOL checked = [(NSButton *)sender state] == 1;
    [_outlineView setFloatsGroupRows:checked];
}

- (IBAction)clrWellChanged:(id)sender {
    NSColor *color = [sender color];
    [_outlineView setBackgroundColor:color];
}

@end

