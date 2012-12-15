/*
     File: ATImageTextCell.m
 Abstract: A complex image and text cell that also draws a fill color. The cell uses sub-cells to delegate the real work to other cells.
 
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

#import "ATImageTextCell.h"
#import "ATColorCell.h"
#import "ATColorTableController.h"
#import "ATDynamicTableView.h"

#define IMAGE_INSET 8.0
#define ASPECT_RATIO 1.6
#define TITLE_HEIGHT 17.0
#define FILL_COLOR_RECT_SIZE 25.0
#define INSET_FROM_IMAGE_TO_TEXT 4.0

@interface ATImageTextCell(ATPrivate) <ATColorTableControllerDelegate>

@end

@implementation ATImageTextCell

- (id)copyWithZone:(NSZone *)zone {
    ATImageTextCell *result = [super copyWithZone:zone];
    if (result != nil) {
        // Retain or copy all our ivars
        result->_imageCell = [_imageCell copyWithZone:zone];
        result->_fillColorCell = [_fillColorCell copyWithZone:zone];
    }
    return result;
}

- (void)dealloc {
    [_imageCell release];
    [_fillColorCell release];
    [super dealloc];
}

@dynamic image;
@dynamic fillColor;
@dynamic fillColorName;

- (NSImage *)image {
    return _imageCell.image;
}

- (void)setImage:(NSImage *)image {
    if (_imageCell == nil) {
        _imageCell = [[NSImageCell alloc] init];
        [_imageCell setControlView:self.controlView];
        [_imageCell setBackgroundStyle:self.backgroundStyle];
    }
    _imageCell.image = image;
}

- (void)_ensureFillColorCellCreated {
    if (_fillColorCell == nil) {
        _fillColorCell = [[ATColorCell alloc] init];
        [_fillColorCell setControlView:self.controlView];
        [_fillColorCell setBackgroundStyle:self.backgroundStyle];
        [_fillColorCell setTextColor:[NSColor grayColor]];
    }
}


- (NSString *)fillColorName {
    return [_fillColorCell title];
}

- (void)setFillColorName:(NSString *)title {
    [self _ensureFillColorCellCreated];
    [_fillColorCell setTitle:title];
}

- (NSColor *)fillColor {
    return _fillColorCell.color;
}

- (void)setFillColor:(NSColor *)color {
    [self _ensureFillColorCellCreated];
    _fillColorCell.color = color;
}

- (void)setControlView:(NSView *)controlView {
    [super setControlView:controlView];
    [_imageCell setControlView:controlView];
    [_fillColorCell setControlView:controlView];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style {
    [super setBackgroundStyle:style];
    [_imageCell setBackgroundStyle:style];
    [_fillColorCell setBackgroundStyle:style];
}

- (NSRect)_imageFrameForInteriorFrame:(NSRect)frame {
    NSRect result = frame;
    // Inset the top
    result.origin.y += IMAGE_INSET;
    result.size.height -= 2*IMAGE_INSET;
    // Inset the left
    result.origin.x += IMAGE_INSET;
    // Make the width match the aspect ratio based on the height
    result.size.width = ceil(result.size.height * ASPECT_RATIO);
    return result;
}

- (NSRect)imageRectForBounds:(NSRect)frame {
    // We would apply any inset that here that drawWithFrame did before calling
    // drawInteriorWithFrame:. It does none, so we don't do anything.
    return [self _imageFrameForInteriorFrame:frame];
}

- (NSRect)_titleFrameForInteriorFrame:(NSRect)frame {
    NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
    NSRect result = frame;
    // Move our inset to the left of the image frame
    result.origin.x = NSMaxX(imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
    // Go as wide as we can
    result.size.width = NSMaxX(frame) - NSMinX(result);
    // Move the title above the Y centerline of the image. 
    NSSize naturalSize = [super cellSize];
    result.origin.y = floor(NSMidY(imageFrame) - naturalSize.height - INSET_FROM_IMAGE_TO_TEXT);
    result.size.height = naturalSize.height;
    return result;
}

- (NSRect)_fillColorFrameForInteriorFrame:(NSRect)frame {
    NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
    NSRect result = frame;

    // Move our inset to the left of the image frame
    result.origin.x = NSMaxX(imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
    result.size.width = NSMaxX(frame) - NSMinX(result);
    result.size.height = FILL_COLOR_RECT_SIZE;
    result.origin.y = floor(NSMidY(imageFrame));
    return result;
}

- (NSRect)_subtitleFrameForInteriorFrame:(NSRect)frame {
    NSRect fillColorFrame = [self _fillColorFrameForInteriorFrame:frame];
    NSRect result = fillColorFrame;
    result.origin.x = NSMaxX(fillColorFrame) + INSET_FROM_IMAGE_TO_TEXT;
    result.size.width = NSMaxX(frame) - NSMinX(result);    
    return result;    
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
    if (_imageCell) {
        NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
        [_imageCell drawWithFrame:imageFrame inView:controlView];
    }
    
    if (_fillColorCell) {
        NSRect fillColorFrame = [self _fillColorFrameForInteriorFrame:frame];
        [_fillColorCell drawWithFrame:fillColorFrame inView:controlView];
    }
    
    NSRect titleFrame = [self _titleFrameForInteriorFrame:frame];
    [super drawInteriorWithFrame:titleFrame inView:controlView];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)frame ofView:(NSView *)controlView {
    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];

    // Delegate hit testing to other cells
    if (_imageCell) {
        NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
        if (NSPointInRect(point, imageFrame)) {
            return [_imageCell hitTestForEvent:event inRect:imageFrame ofView:controlView];
        }
    }

    NSRect fillColorFrame = [self _fillColorFrameForInteriorFrame:frame];
    if (NSPointInRect(point, fillColorFrame)) {
        return [_fillColorCell hitTestForEvent:event inRect:fillColorFrame ofView:controlView];
    }
    
    NSRect titleFrame = [self _titleFrameForInteriorFrame:frame];
    if (NSPointInRect(point, titleFrame)) {
        return [super hitTestForEvent:event inRect:titleFrame ofView:controlView];
    }
    
    return NSCellHitNone;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    aRect = [self _titleFrameForInteriorFrame:aRect];
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    aRect = [self _titleFrameForInteriorFrame:aRect];
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

+ (BOOL)prefersTrackingUntilMouseUp {
    // We want to have trackMouse:inRect:ofView:untilMouseUp: always track until the mouse is up
    return YES;
}

// Our custom editor notifies us when the color was changed or cancelled.
// We then signal the tableview of the change. This could easily be abstracted to work with
// a protocol instead of directly with the dynamicTableView class.
//
- (void)_tellControlViewWillStartEditing {
    // We retain ourselves to keep us alive.
    // The delegate does not retain us, and we want to be alive until the controller is done editing.
    [self retain];
    [ATColorTableController sharedColorTableController].delegate = self;
    [(ATDynamicTableView *)[self controlView] willStartEditingProperty:@"fillColor" forCell:self];
    [(ATDynamicTableView *)[self controlView] willStartEditingProperty:@"fillColorName" forCell:self];
}

- (void)_tellControlViewWillEndEditingWithSuccess:(BOOL)success {
    [ATColorTableController sharedColorTableController].delegate = nil;
    [(ATDynamicTableView *)[self controlView] didEndEditingProperty:@"fillColor" forCell:self successfully:success];
    [(ATDynamicTableView *)[self controlView] didEndEditingProperty:@"fillColorName" forCell:self successfully:success];
    [self autorelease]; // Match the retain at the start and reset the delegate
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)frame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
    BOOL result = NO;
    NSRect fillColorCellFrame = [self _fillColorFrameForInteriorFrame:frame];
    NSRect colorRectFrame = [_fillColorCell colorRectForFrame:fillColorCellFrame];
    NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView:nil]; 
    if (NSPointInRect(point, colorRectFrame)) {
        NSColor *color = [self fillColor];
        NSRect colorRectFrameInScreenCoordinates = [controlView convertRectToBase:colorRectFrame];
        colorRectFrameInScreenCoordinates.origin = [controlView.window convertBaseToScreen:colorRectFrameInScreenCoordinates.origin];
        
        [self _tellControlViewWillStartEditing];
        [[ATColorTableController sharedColorTableController] editColor:color locatedAtScreenRect:colorRectFrameInScreenCoordinates];
        
        result = YES;
    }
    return result;
}


- (void)colorTableController:(ATColorTableController *)controller didChooseColor:(NSColor *)color named:(NSString *)colorName {
    // Update our properties and tell the table that things changed
    self.fillColor = color;
    self.fillColorName = colorName;
    [self _tellControlViewWillEndEditingWithSuccess:YES];
}

- (void)didCancelColorTableController:(ATColorTableController *)controller {
    [self _tellControlViewWillEndEditingWithSuccess:NO];
}

@end
