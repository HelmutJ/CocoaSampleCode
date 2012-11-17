/*
     File: MainWindowController.m 
 Abstract: This class provides the delegate/datasource for the NSOutlineView and NSPredicateEditor. 
 In addition, it maintains all the controller logic for the user interface.
  
  Version: 1.6 
  
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

#import "MainWindowController.h"
#import "SearchQuery.h"
#import "SearchItem.h"
#import "ImagePreviewCell.h"

#define TEST_SELECTION 1

@interface MainWindowController()

@property (strong) NSURL *searchLocation;
- (void)updatePathControl;

@end


#pragma mark -

@implementation MainWindowController

@synthesize searchLocation = _searchLocation;

#define COL_IMAGE_ID            @"ImageID"
#define COL_CAMERA_MODEL_ID     @"CameraModelID"
#define COL_LAST_MODIFIED_ID    @"LastModifiedID"


- (void)awakeFromNib {

    // look for the saved search location in NSUserDefaults
    NSError *error = nil;
    NSData *bookMarkDataToResolve = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchLocationKey"];
    if (bookMarkDataToResolve)
    {
        // resolve the bookmark data into our NSURL
        self.searchLocation = [NSURL URLByResolvingBookmarkData:bookMarkDataToResolve
                                                        options:NSURLBookmarkResolutionWithSecurityScope
                                                  relativeToURL:nil
                                            bookmarkDataIsStale:nil
                                                          error:&error];
    }
    
    iSearchQueries = [[NSMutableArray alloc] init];
    iThumbnailSize = 32.0;

    iGroupRowCell = [[NSTextFieldCell alloc] init];
    [iGroupRowCell setEditable:NO];
    [iGroupRowCell setLineBreakMode:NSLineBreakByTruncatingTail];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryChildrenChanged:)
                                                 name:SearchQueryChildrenDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchItemChanged:)
                                                 name:SearchItemDidChangeNotification
                                               object:nil];
    [resultsOutlineView setTarget:self];
    [resultsOutlineView setDoubleAction:@selector(resultsOutlineDoubleClickAction:)];
    
    NSString *placeHolderStr = NSLocalizedString(@"Select an item to show its location.", @"Placeholder string for location items");
    [[pathControl cell] setPlaceholderString:placeHolderStr];
    [pathControl setTarget:self];
    [pathControl setDoubleAction:@selector(pathControlDoubleClick:)];
    
    [predicateEditor setRowHeight:25];
    
    // add some rows
    [[predicateEditor enclosingScrollView] setHasVerticalScroller:NO];
    iPreviousRowCount = 3;
    [predicateEditor addRow:self];
    
    // put the focus in the text field
    id displayValue = [[predicateEditor displayValuesForRow:1] lastObject];
    if ([displayValue isKindOfClass:[NSControl class]])
        [window makeFirstResponder:displayValue];
    
    [self updatePathControl];
    
    [window setDelegate:self];  // we want to be notified when this window is closed

    if (self.searchLocation == nil)
    {
        // we don't have a default search location setup yet,
        // default our searchLocation pointing to "Pictures" folder
        //
        NSArray *picturesDirectory = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
        self.searchLocation = [NSURL fileURLWithPath:[picturesDirectory objectAtIndex:0]];
        
        // write out the NSURL as a security-scoped bookmark to NSUserDefaults
        // (so that we can resolve it again at re-launch)
        //
        NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                             includingResourceValuesForKeys:nil
                                                              relativeToURL:nil
                                                                      error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // lastly, point our searchLocation NSPathControl to the search location
    [searchLocationPathControl setURL:self.searchLocation];
}

- (BOOL)windowShouldClose:(id)sender {
    for (SearchQuery *query in iSearchQueries) {
        // we are no longer interested in accessing SearchQuery's bookmarked search location,
        // so it's important we balance the start/stop access to security scoped bookmarks here
        //
        [[query _searchURL] stopAccessingSecurityScopedResource];
    }
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [iGroupRowCell release];
    [_searchLocation release];
    
    [super dealloc];
}


#pragma mark - NSPredicateEditor support

- (void)createNewSearchForPredicate:(NSPredicate *)predicate withTitle:(NSString *)title withScopeURL:(NSURL *)url {
    if (predicate != nil) {
        // Always search for images
        NSPredicate *imagesPredicate = [NSPredicate predicateWithFormat:@"(kMDItemContentTypeTree = 'public.image')"];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:imagesPredicate, predicate, nil]];
        
        // we are interested in accessing this bookmark for our SearchQuery class
        [url startAccessingSecurityScopedResource];
        
        // Create an instance of our datamodel and keep track of things.
        SearchQuery *searchQuery = [[SearchQuery alloc] initWithSearchPredicate:predicate title:title scopeURL:url];
        [iSearchQueries addObject:searchQuery];
        [searchQuery release];
        
        // Reload the children of the root item, "nil". This only works on 10.5 or higher
        [resultsOutlineView reloadItem:nil reloadChildren:YES];
        [resultsOutlineView expandItem:searchQuery];
        NSInteger row = [resultsOutlineView rowForItem:searchQuery];
        [resultsOutlineView scrollRowToVisible:row];
        [resultsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

/* Foundation's Spotlight support in NSMetdataQuery places the following requirements on an NSPredicate:
    - Value-type (always YES or NO) predicates are not allowed
    - Any compound predicate (other than NOT) must have at least two subpredicates
  The following method will "clean up" an NSPredicate to make it ready for Spotlight,
    or return nil if the predicate can't be cleaned.
*/
- (NSPredicate *)spotlightFriendlyPredicate:(id)predicate {
    if ([predicate isEqual:[NSPredicate predicateWithValue:YES]] || [predicate isEqual:[NSPredicate predicateWithValue:NO]]) return nil;
    else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
	NSCompoundPredicateType type = [predicate compoundPredicateType];
	NSMutableArray *cleanSubpredicates = [NSMutableArray array];
	for (NSPredicate *dirtySubpredicate in [predicate subpredicates]) {
	    NSPredicate *cleanSubpredicate = [self spotlightFriendlyPredicate:dirtySubpredicate];
	    if (cleanSubpredicate) [cleanSubpredicates addObject:cleanSubpredicate];
	}
	
	if ([cleanSubpredicates count] == 0) return nil;
	else if ([cleanSubpredicates count] == 1 && type != NSNotPredicateType) return [cleanSubpredicates objectAtIndex:0];
	else return [[[NSCompoundPredicate alloc] initWithType:type subpredicates:cleanSubpredicates] autorelease];
    }
    else return predicate;
}

/* This method, the action of our predicate editor, is the one-stop-shop for all our updates.
    We need to do potentially three things:
     1) Fire off a search if the user hit enter.
     2) Add some rows if the user deleted all of them, so the user isn't left without any rows.
     3) Resize the window if the number of rows changed (the user hit + or -).
*/
     
- (IBAction)predicateEditorChanged:(id)sender {
    /* This method gets called whenever the predicate editor changes, but we only want to
        create a new predicate when the user hits return.  So check NSApp currentEvent. */
    NSEvent *event = [NSApp currentEvent];
    if ([event type] == NSKeyDown) {
	NSString *characters = [event characters];
	if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D) {
	    /* Get the predicate, which is the object value of our view. */
	    NSPredicate *predicate = [predicateEditor objectValue];
	    /* Make it Spotlight friendly. */
	    predicate = [self spotlightFriendlyPredicate:predicate];
	    if (predicate) {
            static NSInteger searchIndex = 0;
                NSString *title = NSLocalizedString(@"Search %ld", @"Search group title");
            [self createNewSearchForPredicate:predicate withTitle:[NSString stringWithFormat:title, (long)++searchIndex] withScopeURL:self.searchLocation];
	    }
	}
    }
    
    /* if the user deleted the first row, then add it again - no sense leaving the user with no rows */
    if ([predicateEditor numberOfRows] == 0) [predicateEditor addRow:self];
    
    /* resize the window vertically to accomodate our views */
        
    /* Get the new number of rows, which tells us the change in height. 
        Note that we can't just get the view frame, because it's currently animating -
        this method is called before the animation is finished. */
    NSInteger newRowCount = [predicateEditor numberOfRows];
    
    /* If there's no change in row count, there's no need to resize anything */
    if (newRowCount == iPreviousRowCount) return;

    /* The autoresizing masks, by default, allows the outline view to grow and keeps the
        predicate editor fixed.  We need to temporarily grow the predicate editor, and keep
        the outline view fixed, so we have to change the autoresizing masks.  Save off the
        old ones; we'll restore them after changing the window frame. */
    NSScrollView *outlineScrollView = [resultsOutlineView enclosingScrollView];
    NSUInteger oldOutlineViewMask = [outlineScrollView autoresizingMask];
    
    NSScrollView *predicateEditorScrollView = [predicateEditor enclosingScrollView];
    NSUInteger oldPredicateEditorViewMask = [predicateEditorScrollView autoresizingMask];
    
    [outlineScrollView setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    [predicateEditorScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
    /* Determine whether we're growing or shrinking... */
    BOOL growing = (newRowCount > iPreviousRowCount);
    
    /* And figure out by how much.  Sizes must contain nonnegative values,
        which is why we avoid negative floats here. */
    CGFloat heightDifference = fabs([predicateEditor rowHeight] * (newRowCount - iPreviousRowCount));
    
    /* Convert the size to window coordinates.  This is very important!
        If we didn't do this, we would break under scale factors other than 1.
        We don't care about the horizontal dimension, so leave that as 0. */
    NSSize sizeChange = [predicateEditor convertSize:NSMakeSize(0, heightDifference) toView:nil];
    
    /* Change the window frame size.  If we're growing, the height goes up and the origin
        goes down (corresponding to growing down).  If we're shrinking, the height goes
        down and the origin goes up. */
    NSRect windowFrame = [window frame];
    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height;
    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height;
    [window setFrame:windowFrame display:YES animate:YES];
    
    /* restore the autoresizing mask */
    [outlineScrollView setAutoresizingMask:oldOutlineViewMask];
    [predicateEditorScrollView setAutoresizingMask:oldPredicateEditorViewMask];

    /* record our new row count */
    iPreviousRowCount = newRowCount;
}

- (void)queryChildrenChanged:(NSNotification *)note {
    [resultsOutlineView reloadItem:[note object] reloadChildren:YES];
}

- (void)searchItemChanged:(NSNotification *)note {
    // When an item changes, it only will affect the display state.
    // So, we only need to redisplay its contents, and not reload it
    NSInteger row = [resultsOutlineView rowForItem:[note object]];
    if (row != -1) {
        [resultsOutlineView setNeedsDisplayInRect:[resultsOutlineView rectOfRow:row]];
        if ([resultsOutlineView isRowSelected:row]) {
            [self updatePathControl];
        }
    }
}

#pragma mark -
#pragma mark NSOutlineView DataSource and Delegate Methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSArray *children = item == nil ? iSearchQueries : [item children];
    return [children count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSArray *children = item == nil ? iSearchQueries : [item children];
    return [children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[SearchQuery class]]) {
        return YES;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id result = nil;
    if ([item isKindOfClass:[SearchQuery class]]) {
        if (tableColumn == nil || [[tableColumn identifier] isEqualToString:COL_IMAGE_ID]) {
            result = [item title];
        }
    } else if ([item isKindOfClass:[SearchItem class]]) {
        if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COL_IMAGE_ID]) {
            result = [item title];
            if (result == nil) {
                result = NSLocalizedString(@"(Untitled)", @"Untitled title");
            }
        } else if ([[tableColumn identifier] isEqualToString:COL_CAMERA_MODEL_ID]) {
            result = [item cameraModel];            
            if (result == nil) {
                result = NSLocalizedString(@"(Unknown)", @"Unknown camera model name");
            }
        } else if ([[tableColumn identifier] isEqualToString:COL_LAST_MODIFIED_ID]) {
            result = [item modifiedDate];
        }            
    }
    return result;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([item isKindOfClass:[SearchItem class]]) {
        if ([[tableColumn identifier] isEqualToString:COL_IMAGE_ID]) {
            [item setTitle:object];
        }
    }    
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[SearchItem class]]) {
        SearchItem *searchItem = item;
        if ([searchItem metadataItem] != nil) {
            // We could dynamically change the thumbnail size, if desired
            return iThumbnailSize + 9.0; // The extra space is padding around the cell
        }
    }
    return [outlineView rowHeight];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn && [[tableColumn identifier] isEqualToString:COL_IMAGE_ID]) {
        if ([item isKindOfClass:[SearchItem class]]) {
            [cell setImage:[item thumbnailImage]];
            NSString *subTitle;
            NSSize imageSize = [item imageSize];
            if (imageSize.width > 0) {
                subTitle = [NSString stringWithFormat:@"(%ldx%ld)", (long)imageSize.width, (long)imageSize.height];
            } else {
                subTitle = @"--";
            }
            [cell setSubTitle:subTitle];
            [cell setTarget:self];
            [cell setInfoButtonAction:@selector(infoButtonAction:)];
        }
    }
}

// The next delegate method prevents changing the selection when clicking on the "i" button area.
#if TEST_SELECTION
- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes byExtendingSelection:(BOOL)extend {
    // Find out if we are single clicking in the "i" area
    if (!extend && [proposedSelectionIndexes count] == 1) {
        NSInteger clickedCol = [outlineView clickedColumn];
        NSInteger clickedRow = [outlineView clickedRow];
        if (clickedRow >= 0 && clickedCol >= 0) {
            NSCell *cell = [outlineView preparedCellAtColumn:clickedCol row:clickedRow];
            if ([cell isKindOfClass:[ImagePreviewCell class]]) {
                // Did we click in the "i"?
                NSPoint currentPoint = [outlineView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
                NSRect cellBounds = [outlineView frameOfCellAtColumn:clickedCol row:clickedRow];
                NSRect infoImageRect = [(ImagePreviewCell *)cell infoButtonRectForBounds:cellBounds];
                if (NSPointInRect(currentPoint, infoImageRect)) {
                    // Return an empty index set to not allow it to change the selection.
                    return [NSIndexSet indexSet];
                }
            }            
        }
    }
    // Just allow it to work normally
    return proposedSelectionIndexes;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // The "nil" tableColumn is an indicator for the "full width" row
    if (tableColumn == nil) {
        if ([item isKindOfClass:[SearchQuery class]]) {
            return iGroupRowCell;
        } else if ([item isKindOfClass:[SearchItem class]] && [item metadataItem] == nil) {
            // For failed items with no metdata, we also use the group row cell
            return iGroupRowCell;            
        }
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[SearchQuery class]];
}

#endif

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updatePathControl];
}

// End NSOutlineView datasource and delegate methods


#pragma mark - Action Methods

- (void)updatePathControl {
    // Clear out the prior cells
    [pathControl setPathComponentCells:[NSArray array]];
    // Watch for the selection to change in order to update the path control
    NSIndexSet *selection = [resultsOutlineView selectedRowIndexes];
    if ([selection count] == 0) {
        NSString *str = NSLocalizedString(@"Select an item to show its location.", @"Text to display in path control to select a location");
        [[pathControl cell] setPlaceholderString:str];
    } else if ([selection count] == 1) {
        id selectedItem = [resultsOutlineView itemAtRow:[selection firstIndex]];
        if ([selectedItem isKindOfClass:[SearchItem class]]) {
            SearchItem *searchItem = selectedItem;
            [pathControl setURL:[searchItem filePathURL]];
        } else {
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [[NSColor blueColor] colorWithAlphaComponent:0.5], NSForegroundColorAttributeName,
                                    [NSFont systemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName,
                                   nil];
            NSAttributedString *str = [[[NSAttributedString alloc] initWithString:[selectedItem title] attributes:attrs] autorelease];
            [[pathControl cell] setPlaceholderAttributedString:str];
        }
    } else {
        NSString *str = NSLocalizedString(@"Multiple items selected.", @"Text to display in path control when multiple items are selected");
        [[pathControl cell] setPlaceholderString:str];
    }
}

- (void)resultsOutlineDoubleClickAction:(NSOutlineView *)sender {
    // Open a page for all the selected items
    NSIndexSet *selectedRows = [sender selectedRowIndexes];
    for (NSUInteger i = [selectedRows firstIndex]; i <= [selectedRows lastIndex]; i = [selectedRows indexGreaterThanIndex:i]) {
        id item = [sender itemAtRow:i];
        if ([item isKindOfClass:[SearchItem class]]) {
            [[NSWorkspace sharedWorkspace] openURL:[item filePathURL]];
        }
    }    
}

- (void)infoButtonAction:(NSOutlineView *)sender {
    // Access the row that was clicked on and open that image
    NSInteger row = [sender clickedRow];
    SearchItem *item = [resultsOutlineView itemAtRow:row];
    // Do a "reveal" in finder
    if ([item filePathURL]) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard setString:[[item filePathURL] path]  forType:NSStringPboardType];
        NSPerformService(@"Finder/Show Info", pboard);
    }
}

- (void)pathControlDoubleClick:(id)sender {
    if ([pathControl clickedPathComponentCell] != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[[pathControl clickedPathComponentCell] URL]];
    }
}


#pragma mark - NSPathControl support

- (IBAction)searchLocationChanged:(id)sender {
    
    self.searchLocation = [sender URL];
    
    // write out the NSURL as a security-scoped bookmark to NSUserDefaults
    // (so that we can resolve it again at re-launch)
    //
    NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
    
    // customize the open panel to choose directories
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose a location to search for photos and images:"];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setTitle:@"Choose Location"];
    
    // set the default location to the Documents folder
    NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
}

@end


#pragma mark -

@implementation NSObject (RuleEditorChildItems)

- (void)nextSlicePiece:(id)sender { }

@end
