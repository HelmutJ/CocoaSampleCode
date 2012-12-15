/*
     File: ATColorTableController.m 
 Abstract: A controller used by the ATColorTableController to edit the color property. Also demonstrates NSPopover introduced in MacOS 10.7.
  
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

#import "ATColorTableController.h"
#import "ATTableCellView.h"
#import "ATColorView.h"

@implementation ATColorTableController

+ (ATColorTableController *)sharedColorTableController {
    static ATColorTableController *gSharedColorTableController = nil;
    if (gSharedColorTableController == nil) {
        gSharedColorTableController = [[[self class] alloc] initWithNibName:@"ATColorTable" bundle:[NSBundle bundleForClass:[self class]]];
    }
    return gSharedColorTableController;
}

@synthesize delegate = _delegate;
@dynamic selectedColor, selectedColorName;

- (void)dealloc {
    [_colorList release];
    [_colorNames release];
    [_popover release];
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    _colorList = [[NSColorList colorListNamed:@"Crayons"] retain];
    _colorNames = [[_colorList allKeys] retain];
    [_tableColorList setIntercellSpacing:NSMakeSize(3, 3)];
    [_tableColorList setTarget:self];
    [_tableColorList setAction:@selector(_tableViewAction:)];
}

- (NSColor *)selectedColor {
    NSString *name = [self selectedColorName];
    if (name != nil) {
        return [_colorList colorWithKey:name];
    } else {
        return nil;
    }
}

- (NSString *)selectedColorName {
    if ([_tableColorList selectedRow] != -1) {
        return [_colorNames objectAtIndex:[_tableColorList selectedRow]];
    } else {
        return nil;
    }
}

- (void)_selectColor:(NSColor *)color {
    // Search for that color in our list
    NSInteger row = 0;
    for (NSString *name in _colorNames) {
        NSColor *colorInList = [_colorList colorWithKey:name];
        if ([color isEqual:colorInList]) {
            break;
        }
        row++;
    }    
    _updatingSelection = YES;
    // This is done in an animated fashion
    if (row != -1) {
        [_tableColorList scrollRowToVisible:row];
        [[_tableColorList animator] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    } else {
        [_tableColorList scrollRowToVisible:0];
        [[_tableColorList animator] selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
    _updatingSelection = NO;
}

- (void)_makePopoverIfNeeded {
    if (_popover == nil) {
        // Create and setup our window
        _popover = [[NSPopover alloc] init];
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        _popover.contentViewController = self;
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.delegate = self;
    }
}

- (void)editColor:(NSColor *)color withPositioningView:(NSView *)positioningView {
    [self _makePopoverIfNeeded];
    [self _selectColor:color];
    [_popover showRelativeToRect:[positioningView bounds] ofView:positioningView preferredEdge:NSMinYEdge];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _colorNames.count;
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *name = [_colorNames objectAtIndex:row];
    NSColor *color = [_colorList colorWithKey:name];
    // In IB, the TableColumn's identifier is set to "Automatic". The ATTableCellView's is also set to "Automatic". IB then keeps the two in sync, and we don't have to worry about setting the identifier.
    ATTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
    result.colorView.backgroundColor = color;
    result.colorView.drawBorder = YES;
    result.subTitleTextField.stringValue = name;
    return result;
}

- (void)_tableViewAction:(id)sender {
    [_popover close];
    if ([self.delegate respondsToSelector:@selector(colorTableController:didChooseColor:named:)]) {
        [self.delegate colorTableController:self didChooseColor:self.selectedColor named:self.selectedColorName];
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    // Free the popover to avoid a cycle. We could also just break the contentViewController property, and reset it when we show the popover
    [_popover release];
    _popover = nil;
}

@end
