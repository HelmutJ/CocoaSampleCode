/*
     File: PasteboardController.m
 Abstract: Controller object for the pasteboard viewer; handles retrieving types and data from the selected pasteboard, as well as saving.
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


#import "PasteboardController.h"
#import "PasteboardTypeTransformer.h"

#import "LazyDataTextStorage.h"
#import "HexString.h"
#import "ASCIIString.h"
#import "HexAndASCIIString.h"

@interface PasteboardController ()
@property(readwrite, retain) NSPasteboard *whichPboard;
@property(readwrite, retain) NSArray *types;
@end

@implementation PasteboardController
/* Called when the nib has barely started loading, so we can register our custom NSValueTransformer here.
 */
+ (void)initialize {
    [PasteboardTypeTransformer class]; // register transformer
}

/* Called once the nib is done loading; we do various setup actions here so that everything goese smoothly.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    // Set up our own data storage
    NSDictionary *plainTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         [NSFont userFixedPitchFontOfSize:10.0], NSFontAttributeName,
                                         nil];
    LazyDataTextStorage *lazyStorage = [[LazyDataTextStorage alloc] init];
    [lazyStorage setAttributes:plainTextAttributes];
    [plainTextAttributes release];

    [[dataView layoutManager] replaceTextStorage:lazyStorage];
    [lazyStorage release];
    
    // Set up our two text containers, one for fixed width and one normal
    sizableContainer = [[dataView textContainer] retain];
    fixedWidthContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1.0e7, 1.0e7)];
    [fixedWidthContainer setWidthTracksTextView:NO];
    [fixedWidthContainer setHeightTracksTextView:NO];
    [fixedWidthContainer setLineFragmentPadding:[sizableContainer lineFragmentPadding]];
    
    // Load initial data
    self.whichPboard = [NSPasteboard generalPasteboard];
    displayMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"displayMode"];
    [self reload:nil];
    
    // Make the bottom of the window look nice
    [[dataView window] setContentBorderThickness:32.0 forEdge:NSMinYEdge];
    
    // And make sure we get selection updates
    [typesController addObserver:self forKeyPath:@"selectionIndex" options:0 context:NULL]; // lets us know when the selection changes
}

/* Free up resources, remember to remove this instance as an observer. This should only be called if the app is quitting anyway, though.
 */
- (void)dealloc {
    [typesController removeObserver:self forKeyPath:@"selectionIndex"];
    
    [sizableContainer release];
    [fixedWidthContainer release];
    
    self.types = nil;
    self.whichPboard = nil;
    
    [super dealloc];
}

#pragma mark -

/* Reload the current pasteboard's types; thanks to bindings they are redisplayed and the data view is also updated.
 */
- (IBAction)reload:(id)sender {
    // do not switch the order of these two statements; it results in an infinite loop!
    lastChangeCount = [self.whichPboard changeCount];
    self.types = [self.whichPboard types];
    // refresh happens automatically because typesController is bound to self.types
    // and self is observing typesController.selectionIndex
}

/* Select a new pasteboard to look at; if it's part of the combo box's menu, it's a standard pasteboard. Otherwise it's a custom pasteboard which we load by name.
 */
- (IBAction)selectPasteboard:(NSComboBox *)sender {
    NSString *pboardName;
    
    NSInteger selectedIndex = [sender indexOfSelectedItem];
    switch (selectedIndex) {
        case 0:
            pboardName = NSGeneralPboard;
            break;
        case 1:
            pboardName = NSFontPboard;
            break;
        case 2:
            pboardName = NSRulerPboard;
            break;
        case 3:
            pboardName = NSFindPboard;
            break;
        case 4:
            pboardName = NSDragPboard;
            break;
        default:
            pboardName = [sender stringValue]; // for custom pasteboards
            break;
    }
    
    self.whichPboard = [NSPasteboard pasteboardWithName:pboardName];
    [self reload:nil];
}

/* Switch between ASCII, hex, and combination displays, then refresh the data view. The mode is the index of the sender's selected segment.
 */
- (IBAction)selectDisplayMode:(NSSegmentedControl *)sender {
    displayMode = [sender selectedSegment];
    [self refreshDataView:sender];
}

/* Refresh the data view with the current data, or an empty string if no type is selected. If the clipboard contents have changed, the types are reloaded and data is only displayed if the selected type is still available. The status field is updated as well with the size of the data and the selected type; if the clipboard contents changed a note is appended as well.
 */
- (IBAction)refreshDataView:(id)sender {
    if ([self.whichPboard changeCount] != lastChangeCount) {
        [self reload:sender];
        [statusField setStringValue:[[statusField stringValue] stringByAppendingString:NSLocalizedString(@" -- Clipboard contents changed", @"Status field string for when clipboards are reloaded")]];
    } else {
        NSString *dataString;
        NSString *statusString;
        BOOL fixedWidth = NO;

        NSUInteger selectedTypeIndex = [typesController selectionIndex];
        if (selectedTypeIndex == NSNotFound) {
            dataString = [@"" retain];
            statusString = [NSLocalizedString(@"No type selected", @"Status field string for no selection") retain];
        } else {
            NSString *type = [self.types objectAtIndex:selectedTypeIndex];
            NSData *data = [self.whichPboard dataForType:type];
            
            switch (displayMode) {
                case DataDisplayHexAndASCIIMode:
                    dataString = [[HexAndASCIIString alloc] initWithData:data];
                    fixedWidth = YES;
                    break;
                case DataDisplayHexMode:
                    dataString = [[HexString alloc] initWithData:data];
                    break;
                default:
                    dataString = [[ASCIIString alloc] initWithData:data];
                    break;
            }
            
            // Little touches like correct handling of "1 byte" make applications that much better
            NSUInteger dataLength = [data length];
            if (dataLength == 1) {
                statusString = [[NSString alloc] initWithFormat:NSLocalizedString(@"1 byte: %@", @"Status field string for exactly 1 byte of clipboard data"),
                                [[NSValueTransformer valueTransformerForName:@"PasteboardTypeTransformer"] transformedValue:type]];
            } else {
                statusString = [[NSString alloc] initWithFormat:NSLocalizedString(@"%lu bytes: %@", @"Status field string for clipboard data"),
                                (unsigned long) dataLength, // we cast this because NSUIntegers can't be used directly in format strings
                                [[NSValueTransformer valueTransformerForName:@"PasteboardTypeTransformer"] transformedValue:type]];
            }
        }
        
        if (fixedWidth) {
            [dataView replaceTextContainer:fixedWidthContainer];
        } else {
            [dataView replaceTextContainer:sizableContainer];
        }

        [(LazyDataTextStorage *)[dataView textStorage] setString:dataString];
        [dataString release];
        
        [masterDetailSplit setPosition:NSMaxX([[[masterDetailSplit subviews] objectAtIndex:0] frame]) ofDividerAtIndex:0]; // adjust splitview to fit constraints

        [statusField setStringValue:statusString];
        [statusString release];
    }
}

/* We're only observing the current selection, so we can just refresh the data view if it changes.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)unused {
    [self refreshDataView:nil];
}

#pragma mark -

/* Brings up the default save panel for the selected data. If no type is selected, or if there is no data, beeps instead.
 */
- (IBAction)save:(id)sender {
    NSUInteger selectedTypeIndex = [typesController selectionIndex];
    if (selectedTypeIndex == NSNotFound) {
        NSBeep();
    } else {
        NSData *data = [self.whichPboard dataForType:[self.types objectAtIndex:selectedTypeIndex]];
        if (data) {
            NSSavePanel *savePanel = [NSSavePanel savePanel];
            [savePanel beginSheetModalForWindow:[dataView window] completionHandler:^(NSInteger result) {
                if (result == NSFileHandlingPanelOKButton) {     // User confirmed
                    NSURL *url = [savePanel URL];
                    [savePanel orderOut:nil];   // To allow any error sheet to display properly
                    NSError *error;
                    if (![data writeToURL:url options:NSAtomicWrite error:&error]) {
                        [dataView presentError:error modalForWindow:[dataView window] delegate:nil didPresentSelector:0 contextInfo:NULL];	// It's easy to present error messages!  Here we present a sheet.
                    }
                }
            }];
        } else {
            NSBeep();
        }
    }
}

/* Validate any item hooked up to the save: action -- a type must be selected and must have data for a save to be valid. */
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(save:)) {
        NSUInteger selectedTypeIndex = [typesController selectionIndex];
        return selectedTypeIndex != NSNotFound && [self.whichPboard dataForType:[self.types objectAtIndex:selectedTypeIndex]] != nil;
    } else {
        return YES;
    }
}

#pragma mark -

/* Enforce our split view constraints when the window is resized.
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    [sender adjustSubviews]; // first get default resize behavior
    [sender setPosition:NSMaxX([[[sender subviews] objectAtIndex:0] frame]) ofDividerAtIndex:0]; // then resize subject to constraints
}

/* Minimum width of the types list on the left.
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    return 64;
}

/* Maximum width of the types list on the left, by subtracting off the minimum width of the data view. If we're in ASCII and Hex mode we actually calculate this; otherwise we just use a reasonable width.
 */
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    CGFloat max = NSWidth([sender bounds]);
    max -= [sender dividerThickness];
    
    if (displayMode == DataDisplayHexAndASCIIMode) {
        max -= NSWidth([[[dataView enclosingScrollView] verticalScroller] frame]);
        max -= NSWidth([[dataView layoutManager] lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:NULL]);
        max -= [[dataView textContainer] lineFragmentPadding];
    } else {
        max -= 100;
    }
    
    return max;
}
    
@synthesize whichPboard;
@synthesize types;
@end
