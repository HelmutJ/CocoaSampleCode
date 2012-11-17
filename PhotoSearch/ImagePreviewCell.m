/*
     File: ImagePreviewCell.m 
 Abstract: Provides a cell implementation that draws an image, title, sub-title, and has a
 custom trackable button that highlights when the mouse moves over it.
  
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

#import "ImagePreviewCell.h"

// These defines should be on, and are simply for demo purposes
#define HIT_TEST 1
#define EDIT_FRAME 1
#define TRACKING 1
#define TRACKING_AREA 1
#define EXPANSION_FRAME_SUPPORT 1

#pragma mark -

@implementation ImagePreviewCell

- (id)init {
    self = [super init];
    if (self != nil) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

// NSTableView likes to copy a cell before tracking --
// therefore we need to properly implement copyWithZone.
//
- (id)copyWithZone:(NSZone *)zone {
    ImagePreviewCell *result = [super copyWithZone:zone];
    if (result != nil) {
        // We must clear out the image beforehand; otherwise, it would contain the previous
        // image (which wouldn't be retained), and doing the setImage: would be a nop since
        // it is the same image. This would eventually lead to a crash after you click on
        // the cell in a tableview, since it copies the cell at that time, and later releases it.
        //
        result->iImage = nil;
        result->iSubTitle = nil;
        [result setImage:[self image]];
        [result setSubTitle:[self subTitle]];
    }
    return result;
}

- (void)dealloc {
    [iImage release];
    [iSubTitle release];
    [super dealloc];
}

- (NSImage *)image {
    return iImage;
}

- (void)setImage:(NSImage *)image {
    if (image != iImage) {
        [iImage release];
        iImage = [image retain];
    }
}

- (NSString *)subTitle {
    return iSubTitle;
}

- (void)setSubTitle:(NSString *)subTitle {
    if ((iSubTitle == nil) || ![iSubTitle isEqualToString:subTitle]) {
        [iSubTitle release];
        iSubTitle = [subTitle retain];
    }
}

- (SEL)infoButtonAction {
    return iInfoButtonAction;
}

- (void)setInfoButtonAction:(SEL)action {
    iInfoButtonAction = action;
}

- (NSImage *)infoButtonImage {
    // Construct an image name based on our current state
    NSString *imageName = [NSString stringWithFormat:@"info-%@%@", 
                 [self isHighlighted] ? @"selected" : @"normal", 
                  iMouseDownInInfoButton ? @"-mouse" : 
                       iMouseHoveredInInfoButton ? @"-hovered" : @""];
    return [NSImage imageNamed:imageName];
}

- (NSAttributedString *)attributedSubTitle {
    NSAttributedString *result = nil;
    if (iSubTitle) {
        // Make the text color gray, or light gray, depending on if we are highlighted (selected) or not
        NSColor *textColor = [self isHighlighted] ? [NSColor lightGrayColor] : [NSColor grayColor];
        // Create a set of attributes to use
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
            textColor, NSForegroundColorAttributeName,
            nil];
        result = [[NSAttributedString alloc] initWithString:iSubTitle attributes:attrs];
    }
    return [result autorelease];
}


#pragma mark -

#define PADDING_BEFORE_IMAGE 5.0
#define PADDING_BETWEEN_TITLE_AND_IMAGE 4.0
#define VERTICAL_PADDING_FOR_IMAGE 4.0
#define INFO_IMAGE_SIZE 13.0
#define PADDING_AROUND_INFO_IMAGE 2.0
#define IMAGE_SIZE 32.0

- (NSRect)rectForSubTitleBasedOnTitleRect:(NSRect)titleRect inBounds:(NSRect)bounds {
    NSAttributedString *subTitle = [self attributedSubTitle];
    if (subTitle != nil) {
        titleRect.origin.y += titleRect.size.height;
        titleRect.size.width = [subTitle size].width;
        // Make sure it doesn't go past the bounds
        CGFloat amountPast = NSMaxX(titleRect) - NSMaxX(bounds);
        if (amountPast > 0) {
            titleRect.size.width -= amountPast;
        }
        return titleRect;
    } else {
        return NSZeroRect;
    }
}

- (NSRect)subTitleRectForBounds:(NSRect)bounds {
    NSRect titleRect = [self titleRectForBounds:bounds];
    return [self rectForSubTitleBasedOnTitleRect:titleRect inBounds:bounds];
}

- (NSRect)rectForInfoButtonBasedOnTitleRect:(NSRect)titleRect inBounds:(NSRect)bounds {
    NSRect buttonRect = titleRect;
    buttonRect.origin.x = NSMaxX(titleRect) + PADDING_BETWEEN_TITLE_AND_IMAGE;
    buttonRect.origin.y += 2.0;
    buttonRect.size.height = INFO_IMAGE_SIZE;
    buttonRect.size.width = INFO_IMAGE_SIZE;
    // Make sure it doesn't go past the bounds -- if so, we don't want to draw it.
    if (NSMaxX(buttonRect) - NSMaxX(bounds) > 0) {
        buttonRect = NSZeroRect;
    }
    buttonRect.origin.x = round(buttonRect.origin.x);
    return buttonRect;
}

- (NSRect)infoButtonRectForBounds:(NSRect)bounds {
    NSRect titleRect = [self titleRectForBounds:bounds];
    return [self rectForInfoButtonBasedOnTitleRect:titleRect inBounds:bounds];
}

- (NSRect)imageRectForBounds:(NSRect)bounds {
    NSRect result = bounds;
    result.origin.y += VERTICAL_PADDING_FOR_IMAGE;
    result.origin.x += PADDING_BEFORE_IMAGE;
    if (iImage != nil) { 
        // Take the actual image and center it in the result
        result.size = [iImage size];
        CGFloat widthCenter = IMAGE_SIZE - NSWidth(result);
        if (widthCenter > 0) {
            result.origin.x += round(widthCenter / 2.0);
        }
        CGFloat heightCenter = IMAGE_SIZE - NSHeight(result);
        if (heightCenter > 0) {
            result.origin.y += round(heightCenter / 2.0);
        }
    } else {
        result.size.width = result.size.height = IMAGE_SIZE;
    }
    return result;
}

- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSAttributedString *title = [self attributedStringValue];
    NSRect result = bounds;
    // The x origin is easy
    result.origin.x += PADDING_BEFORE_IMAGE + IMAGE_SIZE + PADDING_BETWEEN_TITLE_AND_IMAGE;
    // The y origin should be inline with the image
    result.origin.y += VERTICAL_PADDING_FOR_IMAGE;
    // Set the width and the height based on the texts real size. Notice the nil check!
    // Otherwise, the resulting NSSize could be undefined if we messaged a nil object.
    if (title != nil) {
        result.size = [title size];
    } else {
        result.size = NSZeroSize;
    }
    // Now, we have to constrain us to the bounds. The max x we can go to has to be the
    // same as the bounds, but minus the info image location
    CGFloat maxX = NSMaxX(bounds) - (PADDING_AROUND_INFO_IMAGE + INFO_IMAGE_SIZE + PADDING_AROUND_INFO_IMAGE);
    CGFloat maxWidth = maxX - NSMinX(result);
    if (maxWidth < 0) maxWidth = 0;
    // Constrain us to these bounds
    result.size.width = MIN(NSWidth(result), maxWidth);
    return result;
}

- (NSSize)cellSizeForBounds:(NSRect)bounds {
    NSSize result;
    // Figure out the natural cell size and confine it to the bounds given
    NSRect titleRect = [self titleRectForBounds:bounds];
    result.width = PADDING_BEFORE_IMAGE + IMAGE_SIZE + PADDING_BETWEEN_TITLE_AND_IMAGE + titleRect.size.width;
    // Add in spacing for the info image
    result.width += PADDING_AROUND_INFO_IMAGE + INFO_IMAGE_SIZE + PADDING_AROUND_INFO_IMAGE;
    result.height = VERTICAL_PADDING_FOR_IMAGE + IMAGE_SIZE + VERTICAL_PADDING_FOR_IMAGE;
    // Constrain it to the bounds passed in
    result.width = MIN(result.width, NSWidth(bounds));
    result.height = MIN(result.height, NSHeight(bounds));
    return result;
}

- (void)drawInteriorWithFrame:(NSRect)bounds inView:(NSView *)controlView {

    NSRect imageRect = [self imageRectForBounds:bounds];
    if (iImage != nil) {
        [iImage setFlipped:[controlView isFlipped]];
        [iImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceIn fraction:1.0];
    } else {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:imageRect];
    CGFloat pattern[2] = { 4.0, 2.0 };
    [path setLineDash:pattern count:2 phase:1.0];
    [path setLineWidth:0];
        [[NSColor grayColor] set];
        [path stroke];
    }

    NSRect titleRect = [self titleRectForBounds:bounds];
    NSAttributedString *title = [self attributedStringValue];
    if ([title length] > 0) {
        [title drawInRect:titleRect];
    }

    NSAttributedString *attributedSubTitle = [self attributedSubTitle];
    if ([attributedSubTitle length] > 0) {
        NSRect attributedSubTitleRect = [self rectForSubTitleBasedOnTitleRect:titleRect inBounds:bounds];
        [attributedSubTitle drawInRect:attributedSubTitleRect];
    }

    NSRect infoButtonRect = [self infoButtonRectForBounds:bounds];
    NSImage *image = [self infoButtonImage];
    [image setFlipped:[controlView isFlipped]];
    [image drawInRect:infoButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

#if HIT_TEST

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {

    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];

    NSRect titleRect = [self titleRectForBounds:cellFrame];
    if (NSMouseInRect(point, titleRect, [controlView isFlipped])) {
        return NSCellHitContentArea | NSCellHitEditableTextArea;
    } 
    
    NSRect imageRect = [self imageRectForBounds:cellFrame];
    if (NSMouseInRect(point, imageRect, [controlView isFlipped])) {
        return NSCellHitContentArea;
    }

    // Did we hit the sub title?
    NSAttributedString *attributedSubTitle = [self attributedSubTitle];
    if ([attributedSubTitle length] > 0) {
        NSRect attributedSubTitleRect = [self rectForSubTitleBasedOnTitleRect:titleRect inBounds:cellFrame];
        if (NSMouseInRect(point, attributedSubTitleRect, [controlView isFlipped])) {
            // Notice that this text isn't an editable area. Clicking on it won't begin an editing session.
            return NSCellHitContentArea;
        }
    }

    // How about the info button?
    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];
    if (NSMouseInRect(point, infoButtonRect, [controlView isFlipped])) {
        return NSCellHitContentArea | NSCellHitTrackableArea;
    } 

    return NSCellHitNone;
}

#endif

#if EDIT_FRAME

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    // Take advantaged of NSTextFieldCell's implementation of editWithFrame:, and just
    // adjust the frame for the area that really contains the text.
    NSRect titleRect = [self titleRectForBounds:aRect];
    // Push the origin a little to the left so the new text appears directly over the
    // existing text in the cell
    titleRect.origin.x -= 2;
    // Since the NSText will not automatically grow, we should give it all the space that
    // is available for editing
    CGFloat sizeBeforeTitle = NSMinX(titleRect) - NSMinX(aRect);
    titleRect.size.width =  NSWidth(aRect) - sizeBeforeTitle;
    [super editWithFrame:titleRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// NSTableView may call selectWithFrame: or editWithFrame: depending on how it is invoked.
// This code should mirror the above method. selectWithFrame: differs by starting an editing
// session and selecting all the text in the cell.
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect titleRect = [self titleRectForBounds:aRect];
    titleRect.origin.x -= 2;
    CGFloat sizeBeforeTitle = NSMinX(titleRect) - NSMinX(aRect);
    titleRect.size.width =  NSWidth(aRect) - sizeBeforeTitle;
    [super selectWithFrame:titleRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

#endif

#if TRACKING

+ (BOOL)prefersTrackingUntilMouseUp {
    // NSCell returns NO for this by default. If you want to have trackMouse:inRect:ofView:untilMouseUp:
    // always track until the mouse is up, then you MUST return YES. Otherwise, strange things will happen.
    return YES;
}

// Mouse tracking -- the only part we want to track is the "info" button
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
    [self setControlView:controlView];

    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];
    while ([theEvent type] != NSLeftMouseUp) {
        // This is VERY simple event tracking. We simply check to see if the mouse is in
        // the "i" button or not and dispatch entered/exited mouse events
        NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
        BOOL mouseInButton = NSMouseInRect(point, infoButtonRect, [controlView isFlipped]);
        if (iMouseDownInInfoButton != mouseInButton) {
            iMouseDownInInfoButton = mouseInButton;
            [controlView setNeedsDisplayInRect:cellFrame];
        }
        if ([theEvent type] == NSMouseEntered || [theEvent type] == NSMouseExited) {
            [NSApp sendEvent:theEvent];
        }
        // Note that we process mouse entered and exited events and dispatch them to properly handle updates
        theEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSMouseEnteredMask | NSMouseExitedMask)];
    }

    // Another way of implementing the above code would be to keep an NSButtonCell as an ivar, and simply call trackMouse:inRect:ofView:untilMouseUp: on it, if the tracking area was inside of it. 

    if (iMouseDownInInfoButton) {
        // Send the action, and redisplay
        iMouseDownInInfoButton = NO;
        [controlView setNeedsDisplayInRect:cellFrame];
        if (iInfoButtonAction) {
            [NSApp sendAction:iInfoButtonAction to:[self target] from:[self controlView]];
        }
    }

    // We return YES since the mouse was released while we were tracking.
    // Not returning YES when you processed the mouse up is an easy way to introduce bugs!
    return YES;
}

#endif

#if TRACKING_AREA

// Mouse movement tracking -- we have a custom NSOutlineView subclass that automatically
// lets us add mouseEntered:/mouseExited: support to any cell!
//
- (void)addTrackingAreasForView:(NSView *)controlView inRect:(NSRect)cellFrame withUserInfo:(NSDictionary *)userInfo mouseLocation:(NSPoint)mouseLocation {
    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];

    NSTrackingAreaOptions options = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;

    BOOL mouseIsInside = NSMouseInRect(mouseLocation, infoButtonRect, [controlView isFlipped]);
    if (mouseIsInside) {
        options |= NSTrackingAssumeInside;
        [controlView setNeedsDisplayInRect:cellFrame];
    }

    // We make the view the owner, and it delegates the calls back to the cell after it is
    // properly setup for the corresponding row/column in the outlineview
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:infoButtonRect options:options owner:controlView userInfo:userInfo];
    [controlView addTrackingArea:area];
    [area release];
}

- (void)mouseEntered:(NSEvent *)event {
    iMouseHoveredInInfoButton = YES;
    [(NSControl *)[self controlView] updateCell:self];
}

- (void)mouseExited:(NSEvent *)event {
    iMouseHoveredInInfoButton = NO;
    [(NSControl *)[self controlView] updateCell:self];
}

#endif

#if EXPANSION_FRAME_SUPPORT

// Expansion tool tip support
- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
    // By default, for NSTextFieldCell, the cell is queried for the titleRectForBounds:
    // with a large rect. That value is returned, and is the correct implementation for us,
    // but we want a slightly larger rect
    //
    NSRect rect = [super expansionFrameWithFrame:cellFrame inView:view];
    if (!NSIsEmptyRect(rect)) {
        // We want to make the cell *slightly* larger; it looks better when showing the expansion tool tip.
        rect.size.width += 4.0;
        rect.origin.x -= 2.0;
    }
    return rect;
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view {
    // The drawing isn't correct; we ONLY want to draw the title rect, and do that here.
    NSAttributedString *title = [self attributedStringValue];
    if ([title length] > 0) {
        cellFrame.origin.x += 2.0;
        cellFrame.size.width -= 2.0;
        [title drawInRect:cellFrame];
    }
}

#endif

@end
