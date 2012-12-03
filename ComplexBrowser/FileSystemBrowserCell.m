/*
     File: FileSystemBrowserCell.m
 Abstract: A cell that can draw an image/icon and a label color.
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

#import "FileSystemBrowserCell.h"

@implementation FileSystemBrowserCell

#define ICON_SIZE 		16.0	// Our Icons are ICON_SIZE x ICON_SIZE 
#define ICON_INSET_HORIZ	4.0     // Distance to inset the icon from the left edge. 
#define ICON_TEXT_SPACING	2.0     // Distance between the end of the icon and the text part 
#define ICON_INSET_VERT         2.0     // Distance from top/bottom of icon

- (id)init {
    self = [super init];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    FileSystemBrowserCell *result = [super copyWithZone:zone];
    result->_image = nil;
    result.image = self.image;
    result->_labelColor = nil;
    result.labelColor = self.labelColor;
    return result;
}

- (void)dealloc {
    [_image release];
    [_labelColor release];
    [super dealloc];
}

@synthesize image = _image;
@synthesize labelColor = _labelColor;

- (NSRect)imageRectForBounds:(NSRect)bounds {
    bounds.origin.x += ICON_INSET_HORIZ;
    bounds.size.width = ICON_SIZE;
    bounds.origin.y += trunc((bounds.size.height - ICON_SIZE) / 2.0); 
    bounds.size.height = ICON_SIZE;
    return bounds;
}

- (NSRect)titleRectForBounds:(NSRect)bounds {
    // Inset the title for the image
    CGFloat inset = (ICON_INSET_HORIZ + ICON_SIZE + ICON_TEXT_SPACING);
    bounds.origin.x += inset;
    bounds.size.width -= inset;
    return [super titleRectForBounds:bounds];
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    // Make our cells a bit higher than normal to give some additional space for the icon to fit.
    NSSize theSize = [super cellSizeForBounds:aRect];
    theSize.width += (ICON_INSET_HORIZ + ICON_SIZE + ICON_TEXT_SPACING);
    theSize.height = ICON_INSET_VERT + ICON_SIZE + ICON_INSET_VERT;
    return theSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    // First draw a label background color
    if (self.labelColor != nil) {
        [[self.labelColor colorWithAlphaComponent:0.2] set];
        NSRectFillUsingOperation(cellFrame, NSCompositeSourceOver);
    }
    
    NSRect imageRect = [self imageRectForBounds:cellFrame];
    if (self.image) {
        // Flip images that don't agree with our flipped state
        BOOL flipped = [controlView isFlipped] != [self.image isFlipped];
        if (flipped) {
            [[NSGraphicsContext currentContext] saveGraphicsState];
            NSAffineTransform *transform = [[NSAffineTransform alloc] init];
            [transform translateXBy:0 yBy:cellFrame.origin.y + cellFrame.size.height];
            [transform scaleXBy:1.0 yBy:-1.0];
            [transform translateXBy:0 yBy:-cellFrame.origin.y];
            [transform concat];
            [transform release];
        }
        [self.image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        if (flipped) {
            [[NSGraphicsContext currentContext] restoreGraphicsState];
        }
    }
    CGFloat inset = (ICON_INSET_HORIZ + ICON_SIZE + ICON_TEXT_SPACING);
    cellFrame.origin.x += inset;
    cellFrame.size.width -= inset;
    cellFrame.origin.y += 1; // Looks better
    cellFrame.size.height -= 1;
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view {
    // We want to exclude the icon from the expansion frame when you hover over the cell
    [super drawInteriorWithFrame:cellFrame inView:view];
}

@end
