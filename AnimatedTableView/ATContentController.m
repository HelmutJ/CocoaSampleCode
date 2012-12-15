/*
     File: ATContentController.m
 Abstract: The basic controller for the demo app. An instance exists inside the MainMenu.xib file.
 
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

#import <QuartzCore/QuartzCore.h>

#import "ATContentController.h"
#import "ATImageTextCell.h"
#import "ATDynamicTableView.h"
#import "ATColorCell.h"
#import "ATColorView.h"
#import "ATFilterBrowserController.h"

@interface ATContentController(ATPrivate)

// Private forward declarations

- (void)_animateImageFromRow:(NSInteger)row;

@end

@implementation ATContentController

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
    [_filterBrowserController release];
    [super dealloc];
}

- (void)awakeFromNib {
    NSURL *url = [NSURL fileURLWithPath:@"/Library/Desktop Pictures" isDirectory:YES];
    ATDesktopFolderEntity *primaryFolder = [[ATDesktopFolderEntity alloc] initWithFileURL:url];
    // Create a flat array of ATDesktopFolderEntity and ATDesktopImageEntity objects to display
    _tableContents = [NSMutableArray new];
    
    // We first do a pass over the children and add all the images under the "Desktop Pictures" category
    [_tableContents addObject:primaryFolder];
    for (ATDesktopEntity *entity in primaryFolder.children) {
        if ([entity isKindOfClass:[ATDesktopImageEntity class]]) {
            [_tableContents addObject:entity];
        }
    }

    // Then do another pass through and add all the folders -- including their children.
    // A recursive loop could be used too, but we want to only go one level deep
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
    
    // Initialize the main image view to our current desktop background.
    NSImage *initialImage = [[NSImage alloc] initByReferencingURL:[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]]];
    [_imageViewMain setImage:initialImage];
    [initialImage release];
    
    [primaryFolder release];
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

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self _entityForRow:row].title;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
    if (entity != nil) {
        // Setup the image and fill color
        ATImageTextCell *imageTextCell = (ATImageTextCell *)cell;
        imageTextCell.image = entity.thumbnailImage;
        imageTextCell.fillColor = entity.fillColor;
        imageTextCell.fillColorName = entity.fillColorName;
    }
}

// We pre-load the images in batches. We could easily use this as a point to stop loading
// rows that are no longer visible and don't have the images fully loaded. We use this as
// an entry point to start/stop watching the image for the visible items to see when it changes.
//
- (void)dynamicTableView:(ATDynamicTableView *)tableView changedVisibleRowsFromRange:(NSRange)oldVisibleRows toRange:(NSRange)newVisibleRows {
    // First, stop observing all prior things
    for (ATDesktopEntity *imageEntity in _observedVisibleItems) {
        if ([imageEntity isKindOfClass:[ATDesktopImageEntity class]]) {
            [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
        }
    }
    // Now, observe things that are newly visible and kick off a request to load the image
    [_observedVisibleItems release];
    _observedVisibleItems = (NSMutableArray *)[[_tableContents subarrayWithRange:newVisibleRows] retain];
    for (ATDesktopEntity *imageEntity in _observedVisibleItems) {
        if ([imageEntity isKindOfClass:[ATDesktopImageEntity class]]) {
            [(ATDesktopImageEntity *)imageEntity loadImage];
            [imageEntity addObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage options:0 context:NULL];
        }
    }
}

- (NSView *)dynamicTableView:(ATDynamicTableView *)tableView viewForRow:(NSInteger)row {
    // Return a spinner for rows that are loading
    NSProgressIndicator *result = nil;
    ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
    if (entity != nil && entity.thumbnailImage == nil) {
        NSRect cellFrame = [tableView frameOfCellAtColumn:0 row:row];
        ATImageTextCell *imageCell = (ATImageTextCell *)[tableView preparedCellAtColumn:0 row:row];
        NSRect imageFrame = [imageCell imageRectForBounds:cellFrame];
        result = [[[NSProgressIndicator alloc] initWithFrame:imageFrame] autorelease];
        [result setIndeterminate:YES];
        [result setStyle:NSProgressIndicatorSpinningStyle];
        [result setControlSize:NSRegularControlSize];        
        [result sizeToFit];
        [result startAnimation:nil];
        NSRect progressFrame = [result frame];
        // Center it in the image frame
        progressFrame.origin.x = NSMinX(imageFrame) + floor((NSWidth(imageFrame) - NSWidth(progressFrame)) / 2.0);
        progressFrame.origin.y = NSMinY(imageFrame) + floor((NSHeight(imageFrame) - NSHeight(progressFrame)) / 2.0);
        [result setFrame:progressFrame];
    }
    return result;
}

- (void)_reloadRowForEntity:(id)object {
    NSInteger row = [_tableContents indexOfObject:object];
    if (row != NSNotFound) {
        [_tableViewMain reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        // Animate if that item is selected and we now have an image for it
        if ([_tableViewMain selectedRow] == row) {
            [self _animateImageFromRow:row];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (keyPath == ATEntityPropertyNamedThumbnailImage) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread
        // (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use
        // NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(_reloadRowForEntity:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
}

// We want to make "group rows" for the folders
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    if ([[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return YES;
    } else {
        return NO;
    }
}

// We want a regular text field cell that we setup in the nib for the group rows, and the default one setup for the tablecolumn for all others
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableColumn != nil) {
        if ([[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
            // Use a shared cell setup in IB via an IBOutlet
            return _sharedGroupTitleCell;
        } else {
            return [tableColumn dataCell];
        }
    } else {
        // A nil table column is for a "full width" table column which we don't need (since we only ever have one column)
        return nil; 
    }
}

// We make the "group rows" have the standard height, while all other image rows have a larger height
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if ([[self _entityForRow:row] isKindOfClass:[ATDesktopFolderEntity class]]) {
        return [tableView rowHeight];
    } else {
        return 75.0;
    }
}

- (void)_animationDoneTimerFired:(NSTimer *)timer {
    [_animationDoneTimer release];
    _animationDoneTimer = nil;
    
    // Set the normal one to have the final image and alpha value.
    // Set the image and update us before ordering out the animation window.
    [_imageViewMain setImage:[_imageViewForTransition image]];
    [_imageViewMain setAlphaValue:1.0];
    
    // This displays right now, and prevents flicker if the animation window orders
    // out before our display happened
    [_imageViewMain.window displayIfNeeded];
    
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
    // Figure out the location of the cell's image
    NSRect cellFrame = [_tableViewMain frameOfCellAtColumn:0 row:row];
    // Grab the fully setup cell
    ATImageTextCell *imageTextCell = (ATImageTextCell *)[_tableViewMain preparedCellAtColumn:0 row:row];
    // As it for its frame
    NSRect cellImageFrame = [imageTextCell imageRectForBounds:cellFrame];
    
    // Convert that cell image frame to the right coordinate system
    NSRect initialImageFrame = [_tableViewMain convertRect:cellImageFrame toView:nil];
    initialImageFrame.origin = [_tableViewMain.window convertBaseToScreen:initialImageFrame.origin];
    return initialImageFrame;    
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

    // We create a window to do the animation. The purpose of using a window is to allow an
    // animation to happen from a non-layer backed view to over a layer-backed view.
    // We easily could use a sibling view if everything was layer backed, or non-layer backed.
    //
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
        
        // At the end of the animation we want to do some cleanup. We keep track of the
        // timer so we can stop the operation if we need to.
        _animationDoneTimer = [[NSTimer scheduledTimerWithTimeInterval:animationDuration
                                                                target:self
                                                              selector:@selector(_animationDoneTimerFired:)
                                                              userInfo:nil
                                                               repeats:NO] retain];
    }    
    [NSAnimationContext endGrouping];
}

- (void)_performAnimationFromSelectedRowToImage {
    NSInteger selectedRow = [_tableViewMain selectedRow];
    // We don't animate the group rows
    if (selectedRow != -1 && ![self tableView:_tableViewMain isGroupRow:selectedRow]) {
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self _performAnimationFromSelectedRowToImage];
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
        ATImageTextCell *cell = (ATImageTextCell *)[tableView preparedCellAtColumn:0 row:row];
        // Use the hit testing API with our own special marker to find out what we hit
        NSUInteger hitTest = [cell hitTestForEvent:[NSApp currentEvent] inRect:[tableView frameOfCellAtColumn:0 row:row] ofView:tableView];
        if ((hitTest & ATCellHitTestColorRect) != 0) {
            // Don't allow the selection change
            return [tableView selectedRowIndexes];
        }
    } else {
        // If the selection is just a group row, don't let it be selected; return the original selection
        if (proposedSelectionIndexes.count > 0 && [self tableView:tableView isGroupRow:[proposedSelectionIndexes lastIndex]]) {
            return [tableView selectedRowIndexes];
        }
    }
    return proposedSelectionIndexes;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Always allow tracking if the cell wants to do it, even if the row isn't selected
    NSInteger column = tableColumn ? [[tableView tableColumns] indexOfObject:tableColumn] : -1;
    NSUInteger hitTest = [cell hitTestForEvent:[NSApp currentEvent] inRect:[tableView frameOfCellAtColumn:column row:row] ofView:tableView];
    return (hitTest & NSCellHitTrackableArea) != 0;
}

- (void)dynamicTableView:(ATDynamicTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row property:(NSString *)propertyName {
    // Update our model and refresh that row
    ATDesktopImageEntity *entity = [self _imageEntityForRow:row];
    if ([propertyName isEqualToString:ATEntityPropertyNamedFillColor]) {
        entity.fillColor = object;
    } else if ([propertyName isEqualToString:ATEntityPropertyNamedFillColorName]) {
        entity.fillColorName = object;
    }
    [_tableViewMain reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (IBAction)_takeFilteredImageFrom:(ATFilterBrowserController *)filterBrowser {
    // Update the model and the UI with the new image
    NSImage *image = _filterBrowserController.filteredImage;
    ATDesktopImageEntity *entity = [self _imageEntityForRow:_tableViewMain.selectedRow];
    if (entity != nil) {
        
        // Write the file to disk so we can set it as the wallpaper
        NSURL *imageURL = [NSURL URLWithString:NSTemporaryDirectory()];
        imageURL = [imageURL URLByAppendingPathComponent:@"Filtered Image.tiff"];
        [[image TIFFRepresentation] writeToURL:imageURL atomically:NO];
        
        // Update the URL in our model and reload the image
        entity.fileURL = imageURL;
        entity.image = nil;
        [entity loadImage];
    }
    [[_filterBrowserController window] orderOut:self];
}

- (IBAction)imgViewMainDoubleClick:(id)sender {
    if (_filterBrowserController == nil) {
        _filterBrowserController = [[ATFilterBrowserController alloc] initWithWindowNibName:@"ATFilterBrowser"];
        [_filterBrowserController setTarget:self];
        [_filterBrowserController setApplyAction:@selector(_takeFilteredImageFrom:)];
    }
    _filterBrowserController.sourceImage = [_imageViewMain image];
    [[_filterBrowserController window] orderFront:self];                                    
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    // Make sure the view on the right has at least 200 px wide
    CGFloat splitViewWidth = splitView.bounds.size.width;
    return splitViewWidth - 200;
}

@end
