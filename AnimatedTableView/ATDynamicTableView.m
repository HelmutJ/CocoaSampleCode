/*
     File: ATDynamicTableView.m
 Abstract: An NSTableView subclass that adds delegate extensions for lazily batch loading cell contents, sub-view support, and multi-valued properties.
 
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

#import "ATDynamicTableView.h"

@interface ATDynamicTableView(ATPrivate)

- (void)_removeCachedViewForRow:(NSInteger)row;
- (void)_removeCachedViewsInIndexSet:(NSIndexSet *)rowIndexes;

@end

@implementation ATDynamicTableView

@dynamic delegate;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    _dynEditingRow = -1;
    _dynEditingColumn = -1;
    return self;
}

- (void)dealloc {
    [_viewsInVisibleRows release];
    _viewsInVisibleRows = nil;
    [super dealloc];
}

- (void)_ensureVisibleRowsIsCreated {
    if (_viewsInVisibleRows == nil) {
        _viewsInVisibleRows = [NSMutableDictionary new];
    }
}

- (void)viewWillDraw {
    // We have to call super first in case the NSTableView does some layout in -viewWillDraw
    [super viewWillDraw];
    
    // Calculate the new visible rows and let the delegate do any extra work it wants to
    NSRange newVisibleRows = [self rowsInRect:self.visibleRect];
    BOOL visibleRowsNeedsUpdate = !NSEqualRanges(newVisibleRows, _visibleRows);
    NSRange oldVisibleRows = _visibleRows;
    if (visibleRowsNeedsUpdate) {
        _visibleRows = newVisibleRows;
        // Give the delegate a chance to do any pre-loading or special work that it wants to do
        if ([[self delegate] respondsToSelector:@selector(dynamicTableView:changedVisibleRowsFromRange:toRange:)]) {
            [[self delegate] dynamicTableView:self changedVisibleRowsFromRange:oldVisibleRows toRange:newVisibleRows];
        }
        // We always have to update our views if the visible area changed
        _viewsNeedUpdate = YES;
    }
    
    if (_viewsNeedUpdate) {
        _viewsNeedUpdate = NO;
        // Update any views that the delegate wants to give us
        if ([[self delegate] respondsToSelector:@selector(dynamicTableView:viewForRow:)]) {

            if (visibleRowsNeedsUpdate) {
                // First, remove any views that are no longer before our new visible rows
                NSMutableIndexSet *rowIndexesToRemove = [NSMutableIndexSet indexSetWithIndexesInRange:oldVisibleRows];
                // Remove any rows from the set that are STILL visible; we want a resulting
                // index set that has the views which are no longer on screen.
                [rowIndexesToRemove removeIndexesInRange:newVisibleRows];
                // Remove those views which are no longer visible
                [self _removeCachedViewsInIndexSet:rowIndexesToRemove];
            }
            
            [self _ensureVisibleRowsIsCreated];
            
            // Finally, update and add in any new views given to us by the delegate.
            // Use [NSNull null] for things that don't have a view at a particular row
            for (NSInteger row = _visibleRows.location; row < NSMaxRange(_visibleRows); row++) {
                NSNumber *key = [NSNumber numberWithInteger:row];
                id view = [_viewsInVisibleRows objectForKey:key];
                if (view == nil) {
                    // We don't already have a view at that row
                    view = [[self delegate] dynamicTableView:self viewForRow:row];
                    if (view != nil) {
                        [self addSubview:view];
                    } else {
                        // Use null as a place holder so we don't call the delegate again
                        // until the row is relaoded
                        view = [NSNull null]; 
                    }
                    [_viewsInVisibleRows setObject:view forKey:key];
                }
            }
        }
    }
}

- (void)_removeCachedViewForRow:(NSInteger)row {
    _viewsNeedUpdate = YES;
    if (_viewsInVisibleRows != nil) {
        NSNumber *key = [NSNumber numberWithInteger:row];
        id view = [_viewsInVisibleRows objectForKey:key];
        if (view != nil) {
            if (view != [NSNull null]) {
                [view removeFromSuperview];
            }
            [_viewsInVisibleRows removeObjectForKey:key];
        }
    }
}
            
- (void)_removeCachedViewsInIndexSet:(NSIndexSet *)rowIndexes {
    if (rowIndexes != nil) {
        for (NSInteger row = [rowIndexes firstIndex]; row != NSNotFound; row = [rowIndexes indexGreaterThanIndex:row]) {
            [self _removeCachedViewForRow:row];
        }
    }                 
}

- (void)_removeAllCachedViews {
    if (_viewsInVisibleRows != nil) {
        for (id view in [_viewsInVisibleRows allValues]) {
            [view removeFromSuperview];
        }
        [_viewsInVisibleRows release];
        _viewsInVisibleRows = nil;
    }
}             

// Reset our visible row cache when we reload things
- (void)reloadData {
    [self _removeAllCachedViews];
    _visibleRows = NSMakeRange(NSNotFound, 0);
    [super reloadData];
}

- (void)noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)indexSet {
    // We replace all cached views, as their offsets may change
    [self _removeAllCachedViews];
    _visibleRows = NSMakeRange(NSNotFound, 0);
    [super noteHeightOfRowsWithIndexesChanged:indexSet];
}

- (void)reloadDataForRowIndexes:(NSIndexSet *)rowIndexes columnIndexes:(NSIndexSet *)columnIndexes {
    [self _removeCachedViewsInIndexSet:rowIndexes];
    [super reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
}

- (void)setDelegate:(id <ATDynamicTableViewDelegate>)delegate {
    [super setDelegate:delegate];
}

- (id <ATDynamicTableViewDelegate>)delegate {
    return (id <ATDynamicTableViewDelegate>)[super delegate];
}

// We override the edited column and row and return our cell that is currently being edited by a seperate editor
- (NSInteger)editedColumn {
    if (_dynEditingColumn != -1) {
        return _dynEditingColumn;
    } else {
        return [super editedColumn];
    }
}

- (NSInteger)editedRow {
    if (_dynEditingRow != -1) {
        return _dynEditingRow;
    } else {
        return [super editedRow];
    }
}

- (NSCell *)preparedCellAtColumn:(NSInteger)column row:(NSInteger)row {
    if (_dynEditingRow == row && _dynEditingColumn == column) {
        return [[_dynEditingCell retain] autorelease];
    } else {
        return [super preparedCellAtColumn:column row:row];
    }
}

// The cell editor may want to dynamically update the cell for this control view
- (void)updateCell:(NSCell *)aCell {
    if (aCell == _dynEditingCell) {
        [self reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:_dynEditingRow] columnIndexes:[NSIndexSet indexSetWithIndex:_dynEditingColumn]];
    } else {
        [super updateCell:aCell];
    }
}

- (void)willStartEditingProperty:(NSString *)propertyName forCell:(NSCell *)cell {
    // Store off the row/column we are editing
    if (_editingCount == 0) {
        _dynEditingRow = [self clickedRow];
        _dynEditingColumn = [self clickedColumn];
        _dynEditingCell = [cell retain];
    }
    _editingCount++;
}

- (void)didEndEditingProperty:(NSString *)propertyName forCell:(NSCell *)cell successfully:(BOOL)success {
    _editingCount--;
    // Inform the delegate/datasource of the change!
    if (success && [[self delegate] respondsToSelector:@selector(dynamicTableView:setObjectValue:forTableColumn:row:property:)]) {
        id newValue = [cell valueForKey:propertyName];
        NSTableColumn *tableColumn = _dynEditingColumn != -1 ? [self.tableColumns objectAtIndex:_dynEditingColumn] : nil;
        [[self delegate] dynamicTableView:self setObjectValue:newValue forTableColumn:tableColumn row:_dynEditingRow property:propertyName];
    }
    if (_editingCount == 0) {
        _dynEditingRow = -1;
        _dynEditingColumn = -1;
        [_dynEditingCell release];
        _dynEditingCell = nil;
    }
}

@end
