/*
     File: ATComplexTableViewController.m
 Abstract: The basic controller for the demo app. An instance exists inside the MainMenu.xib file.
 
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

#import <QuartzCore/QuartzCore.h>

#import "ATComplexTableViewController.h"
#import "ATColorView.h"
#import "ATTableCellView.h"
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableCellView.h>
#import "ATObjectTableRowView.h"

@implementation ATComplexTableViewController

- (void)dealloc {
    [_tableContents release];
    // Stop any observations that we may have
    for (ATDesktopEntity *imageEntity in _observedVisibleItems) {
        if ([imageEntity isKindOfClass:[ATDesktopImageEntity class]]) {
            [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
        }
    }
    [_observedVisibleItems release];
    [_windowForAnimation release];
    [super dealloc];
}

-(NSString *)windowNibName {
    return @"ATComplexTableViewWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSURL *url = [NSURL fileURLWithPath:@"/Library/Desktop Pictures" isDirectory:YES];
    ATDesktopFolderEntity *primaryFolder = [[[ATDesktopFolderEntity alloc] initWithFileURL:url] autorelease];
    // Create a flat array of ATDesktopFolderEntity and ATDesktopImageEntity objects to display
    _tableContents = [NSMutableArray new];
    
    // We first do a pass over the children and add all the images under the "Desktop Pictures" category
    [_tableContents addObject:primaryFolder];
    for (ATDesktopEntity *entity in primaryFolder.children) {
        if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
            [_tableContents addObject:entity];
        }
    }

    // Then do another pass through and add all the folders -- including their children. A recursive loop could be used too, but we want to only go one level deep
    for (ATDesktopEntity *entity in primaryFolder.children) {
        if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
            [_tableContents addObject:entity];
            ATDesktopFolderEntity *subFolder = (ATDesktopFolderEntity *)entity;
            for (ATDesktopEntity *subFolderChildEntity in subFolder.children) {
                if ([subFolderChildEntity isKindOfClass:[ATDesktopImageEntity class]]) {
                    [_tableContents addObject:subFolderChildEntity];
                }
            }
        }
    }
    
    _colorViewMain.drawBorder = YES;
    _colorViewMain.backgroundColor = [NSColor whiteColor];
    
    // Initialize the main image view to our current desktop background.
    NSImage *initialImage = [[NSImage alloc] initByReferencingURL:[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]]];
    [_imageViewMain setImage:initialImage];
    [initialImage release];
    [_tableViewMain setDoubleAction:@selector(tblvwDoubleClick:)];
    [_tableViewMain setTarget:self];
    [_tableViewMain reloadData];
    
    // Allow drags to go everywhere
    [_tableViewMain setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (ATDesktopEntity *)_entityForRow:(NSInteger)row {
    return (ATDesktopEntity *)[_tableContents objectAtIndex:row];
}

- (ATDesktopImageEntity *)_imageEntityForRow:(NSInteger)row {
    id result = row != -1 ? [_tableContents objectAtIndex:row] : nil;
    if ([result isKindOfClass:[ATDesktopImageEntity class]]) {
        return result;
    }
    return nil;
}

// NSTableView delegate and datasource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _tableContents.count;
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(ATObjectTableRowView *)rowView forRow:(NSInteger)row {
    // Stop observing visible things
    ATDesktopImageEntity *imageEntity = rowView.objectValue;
    NSInteger index = imageEntity ? [_observedVisibleItems indexOfObject:imageEntity] : NSNotFound;
    if (index != NSNotFound) {
        [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
        [_observedVisibleItems removeObjectAtIndex:index];
    }    
}

- (void)_reloadRowForEntity:(id)object {
    NSInteger row = [_tableContents indexOfObject:object];
    if (row != NSNotFound) {
        ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
        ATTableCellView *cellView = [_tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            // Fade the imageView in, and fade the progress indicator out
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.8];
            [cellView.imageView setAlphaValue:0];
            cellView.imageView.image = entity.thumbnailImage;
            [cellView.imageView setHidden:NO];
            [[cellView.imageView animator] setAlphaValue:1.0];
            [cellView.progessIndicator setHidden:YES];
            [NSAnimationContext endGrouping];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ATEntityPropertyNamedThumbnailImage]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(_reloadRowForEntity:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    // Make the row view keep track of our main model object
    ATObjectTableRowView *result = [[ATObjectTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    result.objectValue = [self _entityForRow:row];
    return [result autorelease];    
}

// We want to make "group rows" for the folders
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    if ([[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ATDesktopEntity *entity = [self _entityForRow:row];
    if ([entity isKindOfClass:[ATDesktopFolderEntity class]]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"TextCell" owner:self];
        [textField setStringValue:entity.title];
        return textField;
    } else {
        ATTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
        ATDesktopImageEntity *imageEntity = (ATDesktopImageEntity *)entity;
        cellView.textField.stringValue = entity.title;
        cellView.subTitleTextField.stringValue = imageEntity.fillColorName;
        cellView.colorView.backgroundColor = imageEntity.fillColor;
        cellView.colorView.drawBorder = YES;

        // Use KVO to observe for changes of the thumbnail image
        if (_observedVisibleItems == nil) {
            _observedVisibleItems = [NSMutableArray new];
        }
        if (![_observedVisibleItems containsObject:entity]) {
            [imageEntity addObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage options:0 context:NULL];
            [imageEntity loadImage];
            [_observedVisibleItems addObject:imageEntity];
        }
        
        // Hide/show progress based on the thumbnail image being loaded or not.
        if (imageEntity.thumbnailImage == nil) {
            [cellView.progessIndicator setHidden:NO];
            [cellView.progessIndicator startAnimation:nil];
            [cellView.imageView setHidden:YES];
        } else {
            [cellView.imageView setImage:imageEntity.thumbnailImage];
        }
        
        // Size/hide things based on the row size
        [cellView layoutViewsForSmallSize:_useSmallRowHeight animated:NO];
        return cellView;
    }
}    

// We make the "group rows" have the standard height, while all other image rows have a larger height
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if ([[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return [tableView rowHeight];
    } else {
        return _useSmallRowHeight ? 30.0 : 75.0;
    }
}

- (void)_animationDoneTimerFired:(NSTimer *)timer {
    [_animationDoneTimer release];
    _animationDoneTimer = nil;
    
    // Set the normal one to have the final image and alpha value. Set the image and update us before ordering out the animation window.
    [_imageViewMain setImage:[_imageViewForTransition image]];
    [_imageViewMain setAlphaValue:1.0];
    [_imageViewMain.window displayIfNeeded]; // This displays right now, and prevents flicker if the animation window orders out before our display happened
    
    // Hide the animation window
    [_windowForAnimation orderOut:nil];
}

- (void)_ensureAnimationWindowCreated {
    if (_windowForAnimation == nil) {
        NSRect contentRect = _imageViewForTransition.frame;
        contentRect.origin = NSZeroPoint;
        _imageViewForTransition.frame = contentRect;
        _windowForAnimation = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_windowForAnimation setReleasedWhenClosed:NO];
        [_windowForAnimation setOpaque:NO];
        [_windowForAnimation setBackgroundColor:[NSColor clearColor]];
        // For ease of use, we setup the _imageViewForTransition in the nib and add it as a subview
        [[_windowForAnimation contentView] addSubview:_imageViewForTransition];
    }
}

- (NSRect)_screenImageRectForRow:(NSInteger)row {
    NSRect result = NSZeroRect;
    // We always want to try to get a view back to do the animation from that rect
    ATTableCellView *cellView = [_tableViewMain viewAtColumn:0 row:row makeIfNecessary:YES];
    if (cellView) {
        result = [cellView.imageView convertRect:cellView.imageView.bounds toView:nil];
        // Convert that frame to the right coordinate system
        result.origin = [cellView.window convertBaseToScreen:result.origin];
    }
    return result;
}

- (NSRect)_finalScreenImageRect {
    // We are animating to right over the image view's frame. Convert to the right screen coordinates and animate the window there.
    NSRect finalImageFrame = [_imageViewMain.superview convertRect:_imageViewMain.frame toView:nil];
    finalImageFrame.origin = [_imageViewMain.window convertBaseToScreen:finalImageFrame.origin];
    return finalImageFrame;
}

- (void)_stopExistingTimerIfNeeded {
    // We want to stop any previous animations
    if (_animationDoneTimer != nil) {
        [_animationDoneTimer invalidate];
        [_animationDoneTimer release];
        _animationDoneTimer = nil;
    }    
}

- (void)_animateImageFromRow:(NSInteger)row {
    [self _stopExistingTimerIfNeeded];

    // We create a window to do the animation. The purpose of using a window is to allow an animation to happen from a non-layer backed view to over a layer-backed view. 
    // We easily could use a sibling view if everything was layer backed, or non-layer backed.
    [self _ensureAnimationWindowCreated];
    
    // Grab our model object for this row
    ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
    
    // Set some initial state
    NSRect startingWindowFrame = [self _screenImageRectForRow:row];
    [_windowForAnimation setFrame:startingWindowFrame display:NO];
    [_imageViewForTransition setImage:entity.thumbnailImage];
    [_imageViewMain setAlphaValue:1.0];
    
    // Bring the window above our existing window
    [_windowForAnimation orderFront:nil];

    // We want to sync all the animations together. We use a grouping to do that.
    [NSAnimationContext beginGrouping]; 
    {
        NSTimeInterval animationDuration = 0.4;
        // Do a slow animation if the shift key is down
        if (([NSEvent modifierFlags] & NSShiftKeyMask) != 0) {
            animationDuration *= 4;
        }
        
        [[NSAnimationContext currentContext] setDuration:animationDuration];
        
        NSRect finalImageFrame = [self _finalScreenImageRect];
        [[_windowForAnimation animator] setFrame:finalImageFrame display:YES];

        // Alpha/opacity animations only work for layer-backed views
        [[_imageViewMain animator] setAlphaValue:0.25];
        
        // Also, animate the background color. This is done with the layer. See ATColorView.h/.m
        [[_colorViewMain animator] setBackgroundColor:entity.fillColor];
        
        // At the end of the animation we want to do some cleanup. We keep track of the timer so we can stop the operation if we need to.
        _animationDoneTimer = [[NSTimer scheduledTimerWithTimeInterval:animationDuration target:self selector:@selector(_animationDoneTimerFired:) userInfo:nil repeats:NO] retain];
    }    
    [NSAnimationContext endGrouping];
}

- (IBAction)btnSetAsDesktopWallpaperClick:(id)sender {
    NSInteger selectedRow = [_tableViewMain selectedRow];
    if (selectedRow != -1) {
        ATDesktopEntity *entity = [_tableContents objectAtIndex:selectedRow];
        if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
            ATDesktopImageEntity *desktopImageEntity = (ATDesktopImageEntity *)entity;
            NSError *error;
            NSURL *imageURL = desktopImageEntity.fileURL;
            NSColor *fillColor = desktopImageEntity.fillColor;
            
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:fillColor, NSWorkspaceDesktopImageFillColorKey, [NSNumber numberWithBool:NO], NSWorkspaceDesktopImageAllowClippingKey, [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown], NSWorkspaceDesktopImageScalingKey, nil];
            BOOL result = [[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL forScreen:[[NSScreen screens] lastObject] options:options error:&error];
            if (!result) {
                [NSApp presentError:error];
            }
        }
    }
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    // We don't want to change the selection if the user clicked in the fill color area
    NSInteger row = [tableView clickedRow];
    if (row != -1 && ![self tableView:tableView isGroupRow:row]) {
        ATTableCellView *cellView = [_tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            // Use hit testing to see if is a color view; if so, don't let it change the selection
            NSPoint windowPoint = [[NSApp currentEvent] locationInWindow];
            NSPoint point = [cellView.superview convertPoint:windowPoint fromView:nil]; 
            NSView *view = [cellView hitTest:point];
            if ([view isKindOfClass:[ATColorView class]]) {
                // Don't allow the selection change
                return [tableView selectedRowIndexes];
            }
        }
    }
    return proposedSelectionIndexes;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    // Make sure the view on the right has at least 200 px wide
    CGFloat splitViewWidth = splitView.bounds.size.width;
    return splitViewWidth - 200;
}

- (void)colorTableController:(ATColorTableController *)controller didChooseColor:(NSColor *)color named:(NSString *)colorName {
    if (_rowForEditingColor != -1) {
        // Update our model
        ATDesktopImageEntity *entity = [self _imageEntityForRow:_rowForEditingColor];
        entity.fillColorName = colorName;
        entity.fillColor = color;    

        // Update the view; we could reload things, but this is faster
        ATTableCellView *cellView = [_tableViewMain viewAtColumn:0 row:_rowForEditingColor makeIfNecessary:NO];
        cellView.colorView.backgroundColor = color;
        cellView.subTitleTextField.stringValue = colorName;
    } else {
        // With no row we are just setting the background color.
        _colorViewMain.backgroundColor = color;
    }
}

- (void)_editColorOnRow:(NSInteger)row {
    _rowForEditingColor = row;
    ATTableCellView *cellView = [_tableViewMain viewAtColumn:0 row:row makeIfNecessary:NO];
    
    NSColor *color = cellView.colorView.backgroundColor;
    [[ATColorTableController sharedColorTableController] setDelegate:self];
    [[ATColorTableController sharedColorTableController] editColor:color withPositioningView:cellView.colorView];
}

- (IBAction)cellColorViewClicked:(id)sender {
    // Find out what row it was in and edit that color with the popup
    NSInteger row = [_tableViewMain rowForView:sender];
    if (row != -1) {
        [self _editColorOnRow:row];
    }
}

- (IBAction)textTitleChanged:(id)sender {
    NSInteger row = [_tableViewMain rowForView:sender];
    if (row != -1) {
        ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
        entity.title = [sender stringValue];
    }
}

- (IBAction)colorTitleChanged:(id)sender {
    NSInteger row = [_tableViewMain rowForView:sender];
    if (row != -1) {
        ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
        entity.fillColorName = [sender stringValue];
    }
}

- (void)_selectRowStartingAtRow:(NSInteger)row {
    if ([_tableViewMain selectedRow] == -1) {
        if (row == -1) {
            row = 0;
        }

        // Select the same or next row (if possible) but skip group rows
        while (row < [_tableViewMain numberOfRows]) {
            if (![self tableView:_tableViewMain isGroupRow:row]) {
                [_tableViewMain selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                return;
            }
            row++;
        }
        row = [_tableViewMain numberOfRows] - 1;
        while (row >= 0) {
            if (![self tableView:_tableViewMain isGroupRow:row]) {
                [_tableViewMain selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                return;
            }
            row--;
        }
    }
}

- (IBAction)btnRemoveRowClick:(id)sender {
    NSInteger row = [_tableViewMain rowForView:sender];
    if (row != -1) {
        [_tableContents removeObjectAtIndex:row];
        [_tableViewMain removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectFade];
        [self _selectRowStartingAtRow:row];
    }
}

- (IBAction)btnRemoveAllSelectedRowsClick:(id)sender {
    [_tableContents removeObjectsAtIndexes:[_tableViewMain selectedRowIndexes]];
    [_tableViewMain removeRowsAtIndexes:[_tableViewMain selectedRowIndexes] withAnimation:NSTableViewAnimationEffectFade];
}

- (IBAction)btnInsertNewRow:(id)sender {
    NSURL *url = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];
    ATDesktopImageEntity *entity = [[ATDesktopImageEntity alloc] initWithFileURL:url];
    entity.fillColor = [_colorViewMain backgroundColor];
    entity.fillColorName = @"Untitled Color";
    NSInteger index = [_tableViewMain selectedRow];
    if (index == -1) {
        if (_tableViewMain.numberOfRows == 0) {
            index = 0;
        } else {
            index = 1;
        }
    }
    
    [_tableContents insertObject:entity atIndex:index];
    [entity release];
    [_tableViewMain beginUpdates];
    [_tableViewMain insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
    [_tableViewMain scrollRowToVisible:index];
    [_tableViewMain endUpdates];
}

- (IBAction)mainColorViewClicked:(id)sender {
    _rowForEditingColor = -1;
    
    NSColor *color = _colorViewMain.backgroundColor;
    
    [[ATColorTableController sharedColorTableController] setDelegate:self];
    [[ATColorTableController sharedColorTableController] editColor:color withPositioningView:_colorViewMain];
}

- (IBAction)cellBtnAnimateImageClick:(id)sender {
    NSInteger selectedRow = [_tableViewMain rowForView:sender];
    if (selectedRow != -1) {
        [_tableViewMain scrollRowToVisible:selectedRow];
        // Only animate if the thumbnail image is loaded
        ATDesktopImageEntity *entity = [_tableContents objectAtIndex:selectedRow];
        if (entity.thumbnailImage != nil) {
            [self _animateImageFromRow:selectedRow];
        }
    } else {
        [_imageViewMain setImage:nil];
    }
}

- (IBAction)chkbxHorizontalGridLineClicked:(id)sender {
    if ([(NSButton *)sender state] == 0) {
        [_tableViewMain setGridStyleMask:NSTableViewGridNone]; 
    } else {
        [_tableViewMain setGridStyleMask:NSTableViewSolidHorizontalGridLineMask]; 
    }
}

- (IBAction)chkbxUseSmallRowHeightClicked:(id)sender {
    _useSmallRowHeight = [(NSButton *)sender state] == 1;
    // Reload the height for all non group rows
    NSMutableIndexSet *indexesToNoteHeightChanges = [NSMutableIndexSet indexSet];
    for (NSInteger row = 0; row < _tableContents.count; row++) {
        if (![[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
            [indexesToNoteHeightChanges addIndex:row];
        }
    }
    // We also want to synchronize our own animations with the height change. We do this by creating our own animation grouping
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1.5];
    
    // Update all the current visible views animated in sync with the row heights
    [_tableViewMain enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        for (NSInteger i = 0; i < [_tableViewMain tableColumns].count; i++) {
            NSView *view = [_tableViewMain viewAtColumn:i row:row makeIfNecessary:NO];
            if (view && [view isKindOfClass:[ATTableCellView class]]) {
                [(ATTableCellView *)view layoutViewsForSmallSize:_useSmallRowHeight animated:YES];
            }
        }
    }];
    
    [_tableViewMain noteHeightOfRowsWithIndexesChanged:indexesToNoteHeightChanges];
    
    [NSAnimationContext endGrouping];
}

- (IBAction)chkbxFloatGroupRowsClicked:(id)sender {
    BOOL checked = [(NSButton *)sender state] == 1;
    [_tableViewMain setFloatsGroupRows:checked];
}

- (IBAction)btnBeginUpdatesClicked:(id)sender {
    [_tableViewMain beginUpdates];
}

- (IBAction)btnEndUpdatesClicked:(id)sender {
    [_tableViewMain endUpdates];
}

- (IBAction)btnMoveRowClick:(id)sender {
    NSInteger fromRow = [_txtFldFromRow integerValue];
    NSInteger toRow = [_txtFldToRow integerValue];
    
    [_tableViewMain beginUpdates];

    [_tableViewMain moveRowAtIndex:fromRow toIndex:toRow];
    
    id object = [[_tableContents objectAtIndex:fromRow] retain];
    [_tableContents removeObjectAtIndex:fromRow];
    [_tableContents insertObject:object atIndex:toRow];
    [object release];    
        
    [_tableViewMain endUpdates];
}

- (IBAction)tblvwDoubleClick:(id)sender {
    NSInteger row = [_tableViewMain selectedRow];
    if (row != -1) {
        ATDesktopEntity *entity = [self _entityForRow:row];
        [[NSWorkspace sharedWorkspace] selectFile:[entity.fileURL path] inFileViewerRootedAtPath:nil];
    }
}

- (IBAction)btnManuallyBeginEditingClick:(id)sender {
    NSInteger row = [_txtFldRowToEdit integerValue];
    [_tableViewMain editColumn:0 row:row withEvent:nil select:YES];
}

- (NSIndexSet *)_indexesToProcessForContextMenu {
    NSIndexSet *selectedIndexes = [_tableViewMain selectedRowIndexes];
    // If the clicked row was in the selectedIndexes, then we process all selectedIndexes. Otherwise, we process just the clickedRow
    if ([_tableViewMain clickedRow] != -1 && ![selectedIndexes containsIndex:[_tableViewMain clickedRow]]) {
        selectedIndexes = [NSIndexSet indexSetWithIndex:[_tableViewMain clickedRow]];
    }
    return selectedIndexes;    
}

- (IBAction)mnuRevealInFinderSelected:(id)sender {
    NSIndexSet *selectedIndexes = [self _indexesToProcessForContextMenu];
    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
        ATDesktopEntity *entity = [self _entityForRow:row];
        [[NSWorkspace sharedWorkspace] selectFile:[entity.fileURL path] inFileViewerRootedAtPath:nil];
    }];
}

- (IBAction)btnRevealInFinderSelected:(id)sender {
    NSInteger row = [_tableViewMain rowForView:sender]; 
    ATDesktopEntity *entity = [self _entityForRow:row];
    [[NSWorkspace sharedWorkspace] selectFile:[entity.fileURL path] inFileViewerRootedAtPath:nil];
}

- (IBAction)mnuRemoveRowSelected:(id)sender {
    NSIndexSet *indexes = [self _indexesToProcessForContextMenu];
    [_tableViewMain beginUpdates];
    [_tableContents removeObjectsAtIndexes:indexes];
    [_tableViewMain removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectFade];
    [_tableViewMain endUpdates];
}

- (IBAction)btnChangeSelectionAnimated:(id)sender {
    if ([_tableViewMain selectedRow] != -1) {
        [[_tableViewMain animator] selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO]; 
    } else {
        [[_tableViewMain animator] selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    }
}

- (id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    // Support for us being a dragging source
    return [self _entityForRow:row];
}

@end
