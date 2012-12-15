/*
     File: ATFilterBrowserController.m
 Abstract: A basic controller that takes an input sourceImage and generates a resulting filteredImage through a series of modifications from NSBrowser. Demonstrates the use of SnowLeopard NSBrowser item-based API.
 
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

#import <Quartz/Quartz.h>

#import "ATFilterBrowserController.h"
#import "ATFilterItem.h"

#define kPrefferedPreviewColumnWidth 288.0
#define kPrefferedColumnWidth 165.0

struct {
    NSString *filterName;
    NSString *inputKey;
}_gFilterList[] = {
        {@"", @""},
        {@"CIHueAdjust", @"inputAngle"},
        {@"CIExposureAdjust", @"inputEV"},
        {@"CIGammaAdjust", @"inputPower"},
        {@"CISepiaTone", @"inputIntensity"},
        {@"CIEdges", @"inputIntensity"},
        {@"CIEdgeWork", @"inputRadius"},
        {@"CIDiscBlur", @"inputRadius"},
        {@"CIGaussianBlur", @"inputRadius"},
        {@"CIPixellate", @"inputScale"},
        {@"CICrystallize", @"inputRadius"},
        {@"CIHoleDistortion", @"inputRadius"}
        };

@implementation ATFilterBrowserController

@synthesize browser = _browser;
@synthesize target = _target;
@synthesize applyAction = _applyAction;

+ (NSArray *)arrayOfStandardATFilterItems {
    NSInteger itemCount = sizeof(_gFilterList)/(sizeof(NSString*)*2);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:itemCount];
    
    for (NSInteger idx = 0; idx < itemCount; idx++) {
        ATFilterItem *item = [ATFilterItem filterItemWithFilterName:_gFilterList[idx].filterName inputKey:_gFilterList[idx].inputKey];
        NSAssert(item, @"No item? Invalid filtername or inputKey?");
        [array addObject:item];
    }
    
    return [NSArray arrayWithArray:array];
}

- (void)dealloc {
    [_sourceImage release];
    [_rootBrowserItem release];
    [super dealloc];
}

- (void)awakeFromNib {
    // This is how you make the NSBrowser transparent
    [self.browser setBackgroundColor:[NSColor clearColor]];
    [self.browser setAction:@selector(_browserClicked:)];
    [self.browser setTarget:self];
}

- (void)_browserClicked:(id)sender {
    NSIndexPath *selectionIndexPath = [self.browser selectionIndexPath];
    if (selectionIndexPath.length > 0) {
        // Auto select a leaf item, but maintain the first responder
        if (![self.browser isLeafItem:[self.browser itemAtIndexPath:selectionIndexPath]]) {
            NSResponder *firstResponder = [self.browser.window.firstResponder retain];
            NSIndexPath *indexPathForLastColumn = [self.browser indexPathForColumn:self.browser.lastColumn];
            NSIndexPath *firstRowInLastColumn = [indexPathForLastColumn indexPathByAddingIndex:0];
            [self.browser setSelectionIndexPath:firstRowInLastColumn];
            [self.browser.window makeFirstResponder:firstResponder];
            [firstResponder release];
            // Also attempt to keep it scrolled into view
            [self.browser scrollColumnToVisible:self.browser.lastColumn];
        }
    }
    
}

- (CIImage *)_rootSourceImage {
    // The core image filters like to work with CIImages, but to be nice,
    // ATFilterBrowserController vends and recevies NSImages to the outside world.
    // So convert the source NSImage to a CIImage
    //
    CGImageRef cgImage = [self.sourceImage CGImageForProposedRect:NULL context:nil hints:nil]; // The result is autoreleased. See NSImage header file.
    CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
    return ciImage;
}

- (NSImage *)sourceImage {
    return [[_sourceImage retain] autorelease];
}

- (void)setSourceImage:(NSImage *)sourceImage {
    if (_sourceImage != sourceImage) {
        [_sourceImage release];
        _sourceImage = [sourceImage retain];
        
        // The root ATFilterItem source iamge is the CIImage version of this source image.
        _rootBrowserItem.sourceImage = [self _rootSourceImage];
    }
}

- (NSImage *)filteredImage {
    NSInteger column = [self.browser selectedColumn];
    ATFilterItem *item = [self.browser itemAtRow:[self.browser selectedRowInColumn:column] inColumn:column];
    return [item resultingNSImage];
}

- (void)_applyButtonAction:(id)sender {
    // Route the action of the preview column's Apply Filters button to the target and action speficied on the controller.
    if (self.target && self.applyAction) {
        [self.target performSelector:self.applyAction withObject:self];
    }
}

#pragma mark NSBrowser Data Source Methods
- (id)rootItemForBrowser:(NSBrowser *)browser {
    if (!_rootBrowserItem) {
        _rootBrowserItem = [ATFilterItem filterItemWithFilterName:@"" inputKey:@""];
        _rootBrowserItem.childItems = [ATFilterBrowserController arrayOfStandardATFilterItems];
        _rootBrowserItem.sourceImage = [self _rootSourceImage];
    }
    
    return _rootBrowserItem;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(ATFilterItem *)item {
    if (!item.childItems) {
        // Lazyily create the child filter items. All filters have the same set of children
        // except for the "None" filter which has no children. However, that filter is created
        // with a valid child array of count zero and will be excluded by the if check above.
        //
        item.childItems = [ATFilterBrowserController arrayOfStandardATFilterItems];
    }
    return [item.childItems count];
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(ATFilterItem *)item  {
    return [item.childItems objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(ATFilterItem *)item {
    // The "None" filter are the leaf items. Except that the root filter is also a "None"
    // filter just to supply the source image, se we need to special case the root item.
    return (item != _rootBrowserItem && [item.filterName isEqualToString:@""]);
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    return [item localizedFilterName];
}

#pragma mark NSBrowser Layout Delegate Methods
- (NSViewController *)browser:(NSBrowser *)browser previewViewControllerForLeafItem:(id)item {
    // Note: The item will be set as the viewController's representedObject for easy
    // binding creating via Interface Builder.
    NSViewController *viewCtlr = [[[NSViewController alloc] initWithNibName:@"ATFilterBrowserPreview" bundle:nil] autorelease];
    
    NSButton *applyBtn = [[viewCtlr view] viewWithTag:100];
    [applyBtn setTarget:self];
    [applyBtn setAction:@selector(_applyButtonAction:)];
    
    return viewCtlr;
}

- (NSViewController *)browser:(NSBrowser *)browser headerViewControllerForItem:(id)item {
    // Note: The item will be set as the viewController's representedObject for easy
    // binding creating via Interface Builder.
    NSViewController *result = [[[NSViewController alloc] initWithNibName:@"ATFilterBrowserColumnHeader" bundle:nil] autorelease];
    return result;
}

- (void)browser:(NSBrowser *)browser didChangeLastColumn:(NSInteger)oldLastColumn toColumn:(NSInteger)column {
    // Lazily bind the source image of the new selection to the resulting image of the parent
    if (column > 0) {
        ATFilterItem *item = [browser parentForItemsInColumn:column];
        [item bind:@"sourceImage" toObject:[browser parentForItemsInColumn:column - 1] withKeyPath:@"resultingImage" options:nil];
    }
}

- (CGFloat)browser:(NSBrowser *)browser shouldSizeColumn:(NSInteger)columnIndex forUserResize:(BOOL)forUserResize toWidth:(CGFloat)suggestedWidth {
    CGFloat width = suggestedWidth;
    
    if (!forUserResize) {
        id item = [browser parentForItemsInColumn:columnIndex];
        if ([browser isLeafItem:item]) {
            // This is the preview column
            width = kPrefferedPreviewColumnWidth;
        } else {
            width = kPrefferedColumnWidth;
        }
    }
    
    return width;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column {
    // We are draing into a transparent browser on a HUD window. Make the cell draw the text white.
    NSDictionary *whiteAttribute = [NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *value = [[NSAttributedString alloc] initWithString:[cell stringValue] attributes:whiteAttribute];
    [cell setAttributedStringValue:value];
    [value release];
}

@end
