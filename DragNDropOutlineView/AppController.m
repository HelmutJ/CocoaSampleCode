/*
     File: AppController.m
 Abstract: Application Controller object implementation.
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

#import "AppController.h"
#import "SimpleNodeData.h"
#import "ImageAndTextCell.h"

@interface AppController(AppPrivate)

- (void)addNewDataToSelection:(SimpleNodeData *)newChildData;
- (NSImage *)randomIconImage;
- (NSTreeNode *)treeNodeFromDictionary:(NSDictionary *)dictionary;
- (BOOL)_dragIsLocalReorder:(id <NSDraggingInfo>)info;

@end

// It is best to #define strings to avoid making typing errors
#define LOCAL_REORDER_PASTEBOARD_TYPE @"MyCustomOutlineViewPboardType"
#define COLUMNID_IS_EXPANDABLE       @"IsExpandableColumn"
#define COLUMNID_NAME                @"NameColumn"
#define COLUMNID_NODE_KIND           @"NodeKindColumn"
#define COLUMID_IS_SELECTABLE        @"IsSelectableColumn"

#define NAME_KEY                     @"Name"
#define CHILDREN_KEY                 @"Children"

@implementation AppController

- (id)init {
    if ((self = [super init])) {
        // Load our initial outline view data from the "InitInfo" dictionary.
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
        _rootTreeNode = [[self treeNodeFromDictionary:dictionary] retain];
    }
    return self; 
}

- (void)dealloc {
    [_rootTreeNode release];
    [_draggedNodes release];
    [_iconImages release];
    [super dealloc];
}

- (void)awakeFromNib {
    // Register to get our custom type, strings, and filenames. Try dragging each into the view!
    [_outlineView registerForDraggedTypes:[NSArray arrayWithObjects:LOCAL_REORDER_PASTEBOARD_TYPE, NSStringPboardType, NSFilenamesPboardType, nil]];
    [_outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [_outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [_outlineView setAutoresizesOutlineColumn:NO];
}

- (BOOL)allowOnDropOnContainer {   
    return (BOOL)[allowOnDropOnContainerCheck state]; 
}

- (BOOL)allowOnDropOnLeaf { 
    return (BOOL)[allowOnDropOnLeafCheck state]; 
}

- (BOOL)allowBetweenDrop { 
    return (BOOL)[allowBetweenDropCheck state]; 
}

- (BOOL)onlyAcceptDropOnRoot { 
    return (BOOL)[onlyAcceptDropOnRoot state]; 
}

- (void)addContainer:(id)sender {
    // Create a new model object, and insert it into our tree structure
    SimpleNodeData *childNodeData = [[SimpleNodeData alloc] initWithName:@"New Container"];
    [self addNewDataToSelection:childNodeData];
    [childNodeData release];
}

- (void)addLeaf:(id)sender {
    SimpleNodeData *childNodeData = [[SimpleNodeData alloc] initWithName:@"New Leaf"];
    childNodeData.container = NO;
    [self addNewDataToSelection:childNodeData];
    [childNodeData release];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    // This message is sent whenever the selection changes
    if ([[_outlineView selectedRowIndexes] count] > 1) {
        [selectionOutput setStringValue: @"Multiple Rows Selected"];
    } else if ([[_outlineView selectedRowIndexes] count] == 1) {
        // Grab the single selected row value
        NSTreeNode *node = [_outlineView itemAtRow:[_outlineView selectedRow]];
        SimpleNodeData *data = [node representedObject];
        [selectionOutput setStringValue:[data name]];  
    } else {
        [selectionOutput setStringValue: @"Nothing Selected"];   
    }
}

- (void)deleteSelections:(id)sender {
    [_outlineView beginUpdates];
    [[_outlineView selectedRowIndexes] enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
        NSTreeNode *node = [_outlineView itemAtRow:row];
        NSTreeNode *parent = [node parentNode];
        NSMutableArray *childNodes = [parent mutableChildNodes];
        NSInteger index = [childNodes indexOfObject:node];
        [childNodes removeObjectAtIndex:index];
        if (parent == _rootTreeNode) {
            parent = nil; // NSOutlineView doesn't know about our root node, so we use nil
        }
        [_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent withAnimation:NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft];
    }];
    [_outlineView endUpdates];
}

- (IBAction)sortData:(id)sender {
    // Save and restore the selection
    NSMutableArray *items = [NSMutableArray array];
    [[_outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        [items addObject:[_outlineView itemAtRow:row]];
    }];

    // Create a sort descriptor to do the sorting. Use a 'nil' key to sort on the objects themselves. This will by default use the method "compare:" on the representedObjects in the NSTreeNode.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    [_rootTreeNode sortWithSortDescriptors:[NSArray arrayWithObject:sortDescriptor] recursively:YES];
    [sortDescriptor release];
    
    [_outlineView reloadData];
    
    // Reselect the original selected items
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];    
    for (NSTreeNode *node in items) {
        NSInteger row = [_outlineView rowForItem:node];
        if (row != -1) {
            [indexes addIndex:row];
        }
    }
    [_outlineView selectRowIndexes:indexes byExtendingSelection:NO];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(deleteSelections:)) {
        // The delete selection item should be disabled if nothing is selected.
        if ([[_outlineView selectedRowIndexes] count] > 0) {
            return YES;
        } else {
            return NO;
        }
    }    
    return YES;
}

#pragma mark -
#pragma mark NSOutlineView data source methods. (The required ones)
#pragma mark -

// The NSOutlineView uses 'nil' to indicate the root item. We return our root tree node for that case.
- (NSArray *)childrenForItem:(id)item {
    if (item == nil) {
        return [_rootTreeNode childNodes];
    } else {
        return [item childNodes];
    }
}

// Required methods. 
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    // 'item' may potentially be nil for the root item.
    NSArray *children = [self childrenForItem:item];
    // This will return an NSTreeNode with our model object as the representedObject
    return [children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    // 'item' will always be non-nil. It is an NSTreeNode, since those are always the objects we give NSOutlineView. We access our model object from it.
    SimpleNodeData *nodeData = [item representedObject];
    // We can expand items if the model tells us it is a container
    return nodeData.container;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    // 'item' may potentially be nil for the root item.
    NSArray *children = [self childrenForItem:item];
    return [children count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id objectValue = nil;
    SimpleNodeData *nodeData = [item representedObject];
    
    // The return value from this method is used to configure the state of the items cell via setObjectValue:
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
        objectValue = nodeData.name;
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
        // Here, object value will be used to set the state of a check box.
        BOOL isExpandable = nodeData.container && nodeData.expandable;
        objectValue = [NSNumber numberWithBool:isExpandable];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_NODE_KIND]) {
        objectValue = (nodeData.container ? @"Container" : @"Leaf");
    } else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE]) {
        // Again -- this object value will set the state of the check box.
        objectValue = [NSNumber numberWithBool:nodeData.selectable];
    }
    
    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
    SimpleNodeData *nodeData = [item representedObject];
    
    // Here, we manipulate the data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
        nodeData.name = object;
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
        nodeData.expandable = [object boolValue];
        if (!nodeData.expandable && [_outlineView isItemExpanded:item]) {
            [_outlineView collapseItem:item];            
        }
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_NODE_KIND]) {
        // We don't allow editing of this column, so we should never actually get here.
    } else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE]) {
        nodeData.selectable = [object boolValue];
    }
}

// We can return a different cell for each row, if we want
- (NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // If we return a cell for the 'nil' tableColumn, it will be used as a "full width" cell and span all the columns
    if ([useGroupRowLook state] && (tableColumn == nil)) {
        SimpleNodeData *nodeData = [item representedObject];
        if (nodeData.container) {
            // We want to use the cell for the name column, but we could construct a new cell if we wanted to, or return a different cell for each row.
            return [[_outlineView tableColumnWithIdentifier:COLUMNID_NAME] dataCell];
        }
    }
    return [tableColumn dataCell];
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    SimpleNodeData *nodeData = [item representedObject];
    return nodeData.container && [useGroupRowLook state] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    // Query our model for the answer to this question
    SimpleNodeData *nodeData = [item representedObject];
    return nodeData.expandable;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {    
    SimpleNodeData *nodeData = [item representedObject];
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
        // Make sure the image and text cell has an image.  If not, lazily fill in a random image
        if (nodeData.image == nil) {
            nodeData.image = [self randomIconImage];
        }
        // We know that the cell at this column is our image and text cell, so grab it
        ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
        // Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
        [imageAndTextCell setImage:nodeData.image];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
        [cell setEnabled:nodeData.container];
        // On Mac OS 10.5 and later, in willDisplayCell: we can dynamically set the contextual menu (right click menu) for a particular cell. If nothing is set, then the contextual menu for the NSOutlineView itself will be used. We will set a different menu for the "Expandable?" column, and leave the default one for everything else.
        [cell setMenu:expandableColumnMenu];
    }
    // For all the other columns, we don't do anything.
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    // Control selection of a particular item. 
    SimpleNodeData *nodeData = [item representedObject];
    BOOL result = nodeData.selectable;
    if (result) {
        //We can access the clicked row and column to potentially disable row selection based on what item was clicked on. We don't want to change the selection when clicking on a column with a button cell, if that option is checked.
        if (![allowButtonCellsToChangeSelection state]) {
            NSInteger clickedCol = [_outlineView clickedColumn];
            NSInteger clickedRow = [_outlineView clickedRow];
            if (clickedRow >= 0 && clickedCol >= 0) {
                NSCell *cell = [_outlineView preparedCellAtColumn:clickedCol row:clickedRow];
                if ([cell isKindOfClass:[NSButtonCell class]] && [cell isEnabled]) {
                    result = NO;
                }            
            }
        }
    }
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // We want to allow tracking for all the button cells, even if we don't allow selecting that particular row. 
    if ([cell isKindOfClass:[NSButtonCell class]]) {
        // We can also take a peek and make sure that the part of the cell clicked is an area that is normally tracked. Otherwise, clicking outside of the checkbox may make it check the checkbox
        NSRect cellFrame = [_outlineView frameOfCellAtColumn:[[_outlineView tableColumns] indexOfObject:tableColumn] row:[_outlineView rowForItem:item]];
        NSUInteger hitTestResult = [cell hitTestForEvent:[NSApp currentEvent] inRect:cellFrame ofView:_outlineView];
        if ((hitTestResult & NSCellHitTrackableArea) != 0) {
            return YES;
        } else {
            return NO;
        }
    } else {
        // Only allow tracking on selected rows. This is what NSTableView does by default.
        return [_outlineView isRowSelected:[_outlineView rowForItem:item]];
    }
}

/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    return (id <NSPasteboardWriting>)[item representedObject];
}

/* Setup a local reorder. */
- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    _draggedNodes = [draggedItems retain];
    [session.draggingPasteboard setData:[NSData data] forType:LOCAL_REORDER_PASTEBOARD_TYPE];
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    // If the session ended in the trash, then delete all the items
    if (operation == NSDragOperationDelete) {
        [_outlineView beginUpdates];
        
        [_draggedNodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id node, NSUInteger index, BOOL *stop) {
            id parent = [node parentNode];
            NSMutableArray *children = [parent mutableChildNodes];
            NSInteger childIndex = [children indexOfObject:node];
            [children removeObjectAtIndex:childIndex];
            [_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:childIndex] inParent:parent == _rootTreeNode ? nil : parent withAnimation:NSTableViewAnimationEffectFade];
        }];
        
        [_outlineView endUpdates];
    }
    
    [_draggedNodes release];
    _draggedNodes = nil;
}

- (BOOL)treeNode:(NSTreeNode *)treeNode isDescendantOfNode:(NSTreeNode *)parentNode {
    while (treeNode != nil) {
        if (treeNode == parentNode) {
            return YES;
        }
        treeNode = [treeNode parentNode];
    }
    return NO;
}

- (BOOL)_dragIsLocalReorder:(id <NSDraggingInfo>)info {
    // It is a local drag if the following conditions are met:
    if ([info draggingSource] == _outlineView) {
        // We were the source
        if (_draggedNodes != nil) {
            // Our nodes were saved off
            if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:LOCAL_REORDER_PASTEBOARD_TYPE]] != nil) {
                // Our pasteboard marker is on the pasteboard
                return YES;
            }
        }
    }
    return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    // To make it easier to see exactly what is called, uncomment the following line:
//    NSLog(@"outlineView:validateDrop:proposedItem:%@ proposedChildIndex:%ld", item, (long)childIndex);
    
    // This method validates whether or not the proposal is a valid one.
    // We start out by assuming that we will do a "generic" drag operation, which means we are accepting the drop. If we return NSDragOperationNone, then we are not accepting the drop.
    NSDragOperation result = NSDragOperationGeneric;

    if ([self onlyAcceptDropOnRoot]) {
        // We are going to accept the drop, but we want to retarget the drop item to be "on" the entire outlineView
        [_outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
    } else {
        // Check to see what we are proposed to be dropping on
        NSTreeNode *targetNode = item;
        // A target of "nil" means we are on the main root tree
        if (targetNode == nil) {
            targetNode = _rootTreeNode;
        }
        SimpleNodeData *nodeData = [targetNode representedObject];
        if (nodeData.container) {
            // See if we allow dropping "on" or "between"
            if (childIndex == NSOutlineViewDropOnItemIndex) {
                if (![self allowOnDropOnContainer]) {
                    // Refuse to drop on a container if we are not allowing that
                    result = NSDragOperationNone;
                }
            } else {
                if (![self allowBetweenDrop]) {
                    // Refuse to drop between an item if we are not allowing that
                    result = NSDragOperationNone;
                }
            }
        } else {
            // The target node is not a container, but a leaf. See if we allow dropping on a leaf. If we don't, refuse the drop (we may get called again with a between)
            if (childIndex == NSOutlineViewDropOnItemIndex && ![self allowOnDropOnLeaf]) {
                result = NSDragOperationNone;
            }
        }
        
        // If we are allowing the drop, we see if we are draggng from ourselves and dropping into a descendent, which wouldn't be allowed...
        if (result != NSDragOperationNone) {
            // Indicate that we will animate the drop items to their final location
            info.animatesToDestination = YES;
            if ([self _dragIsLocalReorder:info]) {
                if (targetNode != _rootTreeNode) {
                    for (NSTreeNode *draggedNode in _draggedNodes) {
                        if ([self treeNode:targetNode isDescendantOfNode:draggedNode]) {
                            // Yup, it is, refuse it.
                            result = NSDragOperationNone;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    // To see what we decide to return, uncomment this line
//    NSLog(result == NSDragOperationNone ? @" - Refusing drop" : @" + Accepting drop");
    
    return result;    
}

- (void)_performInsertWithDragInfo:(id <NSDraggingInfo>)info parentNode:(NSTreeNode *)parentNode childIndex:(NSInteger)childIndex {
    // NSOutlineView's root is nil
    id outlineParentItem = parentNode == _rootTreeNode ? nil : parentNode;
    NSMutableArray *childNodeArray = [parentNode mutableChildNodes];
    NSInteger outlineColumnIndex = [[_outlineView tableColumns] indexOfObject:[_outlineView outlineTableColumn]];
    
    // Enumerate all items dropped on us and create new model objects for them    
    NSArray *classes = [NSArray arrayWithObject:[SimpleNodeData class]];
    __block NSInteger insertionIndex = childIndex;
    [info enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        SimpleNodeData *newNodeData = (SimpleNodeData *)draggingItem.item;
        // Wrap the model object in a tree node
        NSTreeNode *treeNode = [NSTreeNode treeNodeWithRepresentedObject:newNodeData];
        // Add it to the model
        [childNodeArray insertObject:treeNode atIndex:insertionIndex];
        [_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] inParent:outlineParentItem withAnimation:NSTableViewAnimationEffectGap];
        // Update the final frame of the dragging item
        NSInteger row = [_outlineView rowForItem:treeNode];
        draggingItem.draggingFrame = [_outlineView frameOfCellAtColumn:outlineColumnIndex row:row];
        
        // Insert all children one after another
        insertionIndex++;
    }];
    
}

- (void)_performDragReorderWithDragInfo:(id <NSDraggingInfo>)info parentNode:(NSTreeNode *)newParent childIndex:(NSInteger)childIndex {
    // We will use the dragged nodes we saved off earlier for the objects we are actually moving
    NSAssert(_draggedNodes != nil, @"_draggedNodes should be valid");
    
    NSMutableArray *childNodeArray = [newParent mutableChildNodes];
    
    // We want to enumerate all things in the pasteboard. To do that, we use a generic NSPasteboardItem class
    NSArray *classes = [NSArray arrayWithObject:[NSPasteboardItem class]];
    __block NSInteger insertionIndex = childIndex;
    [info enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        // We ignore the draggingItem.item -- it is an NSPasteboardItem. We only care about the index. The index is deterministic, and can directly be used to look into the initial array of dragged items.
        NSTreeNode *draggedTreeNode = [_draggedNodes objectAtIndex:index];

        // Remove this node from its old location
        NSTreeNode *oldParent = [draggedTreeNode parentNode];
        NSMutableArray *oldParentChildren = [oldParent mutableChildNodes];
        NSInteger oldIndex = [oldParentChildren indexOfObject:draggedTreeNode];
        [oldParentChildren removeObjectAtIndex:oldIndex];
        // Tell the table it is going away; make it pop out with NSTableViewAnimationEffectNone, as we will animate the draggedItem to the final target location.
        // Don't forget that NSOutlineView uses 'nil' as the root parent.
        [_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] inParent:oldParent == _rootTreeNode ? nil : oldParent withAnimation:NSTableViewAnimationEffectNone];

        // Insert this node into the new location and new parent
        if (oldParent == newParent) {
            // Moving it from within the same parent! Account for the remove, if it is past the oldIndex
            if (insertionIndex > oldIndex) {
                insertionIndex--; // account for the remove
            }
        }
        [childNodeArray insertObject:draggedTreeNode atIndex:insertionIndex];
        
        // Tell NSOutlineView about the insertion; let it leave a gap for the drop animation to come into place
        [_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] inParent:newParent == _rootTreeNode ? nil : newParent withAnimation:NSTableViewAnimationEffectGap];
        
        insertionIndex++;
    }];
    
    // Now that the move is all done (according to the table), update the draggingFrames for the all the items we dragged. -frameOfCellAtColumn:row: gives us the final frame for that cell
    NSInteger outlineColumnIndex = [[_outlineView tableColumns] indexOfObject:[_outlineView outlineTableColumn]];
    [info enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        NSTreeNode *draggedTreeNode = [_draggedNodes objectAtIndex:index];
        NSInteger row = [_outlineView rowForItem:draggedTreeNode];
        draggingItem.draggingFrame = [_outlineView frameOfCellAtColumn:outlineColumnIndex row:row];
    }];
    
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    NSTreeNode *targetNode = item;
    // A target of "nil" means we are on the main root tree
    if (targetNode == nil) {
        targetNode = _rootTreeNode;
    }
    SimpleNodeData *nodeData = [targetNode representedObject];

    // Determine the parent to insert into and the child index to insert at.
    if (!nodeData.container) {
        // If our target is a leaf, and we are dropping on it
        if (childIndex == NSOutlineViewDropOnItemIndex) {
            // If we are dropping on a leaf, we will have to turn it into a container node
            nodeData.container = YES;
            nodeData.expandable = YES;
            childIndex = 0;
        } else {
            // We will be dropping on the item's parent at the target index of this child, plus one
            NSTreeNode *oldTargetNode = targetNode;
            targetNode = [targetNode parentNode];
            childIndex = [[targetNode childNodes] indexOfObject:oldTargetNode] + 1;
        }
    } else {            
        if (childIndex == NSOutlineViewDropOnItemIndex) {
            // Insert it at the start, if we were dropping on it
            childIndex = 0;
        }
    }
    
    // Group all insert or move animations together
    [_outlineView beginUpdates];
    // If the source was ourselves, we use our dragged nodes and do a reorder
    if ([self _dragIsLocalReorder:info]) {
        [self _performDragReorderWithDragInfo:info parentNode:targetNode childIndex:childIndex];
    } else {
        [self _performInsertWithDragInfo:info parentNode:targetNode childIndex:childIndex];
    }
    [_outlineView endUpdates];
   
    // Return YES to indicate we were successful with the drop. Otherwise, it would slide back the drag image.
    return YES;
}

/* Multi-item dragging destiation support. 
 */
- (void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo {
    // If the source is ourselves, then don't do anything. If it isn't, we update things
    if (![self _dragIsLocalReorder:draggingInfo]) {
        // We will be doing an insertion; update the dragging items to have an appropriate image
        NSArray *classes = [NSArray arrayWithObject:[SimpleNodeData class]];

        // Create a copied temporary cell to draw to images
        NSTableColumn *tableColumn = [_outlineView outlineTableColumn];
        ImageAndTextCell *tempCell = [[[tableColumn dataCell] copy] autorelease];

        // Calculate a base frame for new cells
        NSRect cellFrame = NSMakeRect(0, 0, [tableColumn width], [outlineView rowHeight]);

        // Subtract out the intercellSpacing from the width only. The rowHeight is sans-spacing
        cellFrame.size.width -= [outlineView intercellSpacing].width;
        
        [draggingInfo enumerateDraggingItemsWithOptions:0 forView:_outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
            SimpleNodeData *newNodeData = (SimpleNodeData *)draggingItem.item;
            // Wrap the model object in a tree node
            NSTreeNode *treeNode = [NSTreeNode treeNodeWithRepresentedObject:newNodeData];
            draggingItem.draggingFrame = cellFrame;
            
            draggingItem.imageComponentsProvider = ^(void) {
                // Setup the cell with this temporary data
                id objectValue = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:treeNode];
                [tempCell setObjectValue:objectValue];
                [self outlineView:outlineView willDisplayCell:tempCell forTableColumn:tableColumn item:treeNode];
                // Ask the table for the image components from that cell
                return (NSArray *)[tempCell draggingImageComponentsWithFrame:cellFrame inView:outlineView];
            };            
        }];
    }
}
        
         
/* On Mac OS 10.5 and above, NSTableView and NSOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on, and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
 */
- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSInteger clickedRow = [_outlineView clickedRow];
    id item = nil;
    SimpleNodeData *nodeData = nil;
    BOOL clickedOnMultipleItems = NO;

    if (clickedRow != -1) {
        // If we clicked on a selected row, then we want to consider all rows in the selection. Otherwise, we only consider the clicked on row.
        item = [_outlineView itemAtRow:clickedRow];
        nodeData = [item representedObject];
        clickedOnMultipleItems = [_outlineView isRowSelected:clickedRow] && ([_outlineView numberOfSelectedRows] > 1);
    }
    
    if (menu == outlineViewContextMenu) {
        NSMenuItem *menuItem = [menu itemAtIndex:0];
        if (nodeData != nil) {
            if (clickedOnMultipleItems) {
                // We could walk through the selection and note what was clicked on at this point
                [menuItem setTitle:[NSString stringWithFormat:@"You clicked on %ld items!", (long)[_outlineView numberOfSelectedRows]]];
            } else {
                [menuItem setTitle:[NSString stringWithFormat:@"You clicked on: '%@'", nodeData.name]];
            }
            [menuItem setEnabled:YES];
        } else {
            [menuItem setTitle:@"You didn't click on any rows..."];
            [menuItem setEnabled:NO];
        }
        [deleteSelectedItemsMenuItem setEnabled:[_outlineView selectedRow] != -1];
    } else if (menu == expandableColumnMenu) {
        NSMenuItem *menuItem = [menu itemAtIndex:0];
        if (!clickedOnMultipleItems && (nodeData != nil)) {
            // The item will be enabled only if it is a group
            [menuItem setEnabled:nodeData.container];
            // Check it if it is expandable
            [menuItem setState:nodeData.expandable ? 1 : 0];
        } else {
            [menuItem setEnabled:NO];
        }
    }
}

- (IBAction)expandableMenuItemAction:(id)sender {
    // The tag of the clicked row contains the item that was clicked on
    NSInteger clickedRow = [_outlineView clickedRow];
    NSTreeNode *treeNode = [_outlineView itemAtRow:clickedRow];
    SimpleNodeData *nodeData = [treeNode representedObject];
    // Flip the expandable state,
    nodeData.expandable = !nodeData.expandable;
    // Refresh that row (since its state has changed)
    [_outlineView setNeedsDisplayInRect:[_outlineView rectOfRow:clickedRow]];
    // And collopse it if we can no longer expand it 
    if (!nodeData.expandable && [_outlineView isItemExpanded:treeNode]) {
        [_outlineView collapseItem:treeNode];
    }
}

- (IBAction)useGroupGrowLook:(id)sender {
    // We simply need to redraw things.
    [_outlineView setNeedsDisplay:YES];
}

- (void)addNewDataToSelection:(SimpleNodeData *)newChildData {
    NSTreeNode *selectedNode;
    // We are inserting as a child of the last selected node. If there are none selected, insert it as a child of the treeData itself
    if ([_outlineView selectedRow] != -1) {
        selectedNode = [_outlineView itemAtRow:[_outlineView selectedRow]];
    } else {
        selectedNode = _rootTreeNode;
    }
    
    // If the selected node is a container, use its parent. We access the underlying model object to find this out.
    // In addition, keep track of where we want the child.
    NSInteger childIndex;
    NSTreeNode *parentNode;

    SimpleNodeData *nodeData = [selectedNode representedObject];
    if (nodeData.container) {
        // Since it was already a container, we insert it as the first child
        childIndex = 0;
        parentNode = selectedNode;
    } else {
        // The selected node is not a container, so we use its parent, and insert after the selected node
        parentNode = [selectedNode parentNode]; 
        childIndex = [[parentNode childNodes] indexOfObject:selectedNode ] + 1; // + 1 means to insert after it.
    }
    
    // Use the new 10.7 API to update the tree directly in an animated fashion
    [_outlineView beginUpdates];
    
    // Now, create a tree node for the data and insert it as a child and tell the outlineview about our new insertion
    NSTreeNode *childTreeNode = [NSTreeNode treeNodeWithRepresentedObject:newChildData];
    [[parentNode mutableChildNodes] insertObject:childTreeNode atIndex:childIndex];
    // NSOutlineView uses 'nil' as the root parent
    if (parentNode == _rootTreeNode) {
        parentNode = nil;
    }
    [_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:childIndex] inParent:parentNode withAnimation:NSTableViewAnimationEffectFade];

    [_outlineView endUpdates];

    NSInteger newRow = [_outlineView rowForItem:childTreeNode];
    if (newRow >= 0) {
        [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
        NSInteger column = 0;
        // With "full width" cells, there is no column
        if (newChildData.container && [useGroupRowLook state]) {
            column = -1;
        }
        [_outlineView editColumn:column row:newRow withEvent:nil select:YES];
    }
}

- (NSImage *)randomIconImage {
    // The first time through, we create a random array of images to use for the items.
    if (_iconImages == nil) {
        _iconImages = [[NSMutableArray alloc] init]; // This is properly released in -dealloc
        // There is a set of images with the format "Image<number>.tiff" in the Resources directory. We go through and add them to the array until we are out of images.
        NSInteger i = 1;
        while (1) {
            // The typcast to a long and the use of %ld allows this application to easily be compiled as 32-bit or 64-bit
            NSString *imageName = [NSString stringWithFormat:@"Image%ld.tiff", (long)i];
            NSImage *image = [NSImage imageNamed:imageName];
            if (image != nil) {
                // Add the image to our array and loop to the next one
                [_iconImages addObject:image];
                i++;
            } else {
                // If the result is nil, then there are no more images
                break;
            }            
        }
    }

    // We systematically iterate through the image array and return a result. Keep track of where we are in the array with a static variable.
    static NSInteger imageNum = 0;
    NSImage *result = [_iconImages objectAtIndex:imageNum];
    imageNum++;
    // Once we are at the end of the array, start over
    if (imageNum == [_iconImages count]) {
        imageNum = 0;
    }
    return result;
}


- (NSTreeNode *)treeNodeFromDictionary:(NSDictionary *)dictionary {
    // We will use the built-in NSTreeNode with a representedObject that is our model object - the SimpleNodeData object.
    // First, create our model object.
    NSString *nodeName = [dictionary objectForKey:NAME_KEY];
    SimpleNodeData *nodeData = [SimpleNodeData nodeDataWithName:nodeName];
    // The image for the nodeData is lazily filled in, for performance.
    
    // Create a NSTreeNode to wrap our model object. It will hold a cache of things such as the children.
    NSTreeNode *result = [NSTreeNode treeNodeWithRepresentedObject:nodeData];
    
    // Walk the dictionary and create NSTreeNodes for each child.
    NSArray *children = [dictionary objectForKey:CHILDREN_KEY];
    
    for (id item in children) {
        // A particular item can be another dictionary (ie: a container for more children), or a simple string
        NSTreeNode *childTreeNode;
        if ([item isKindOfClass:[NSDictionary class]]) {
            // Recursively create the child tree node and add it as a child of this tree node
            childTreeNode = [self treeNodeFromDictionary:item];
        } else {
            // It is a regular leaf item with just the name
            SimpleNodeData *childNodeData = [[SimpleNodeData alloc] initWithName:item];
            childNodeData.container = NO;
            childTreeNode = [NSTreeNode treeNodeWithRepresentedObject:childNodeData];
            [childNodeData release];
        }
        // Now add the child to this parent tree node
        [[result mutableChildNodes] addObject:childTreeNode];
    }
    return result;
    
}

@end
