/*
     File: ATColorCell.m
 Abstract: A simple cell that draws a color swatch next to the color's name.
 
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

#import "ATColorCell.h"

#define INSET_FROM_IMAGE_TO_TEXT 4.0

@implementation ATColorCell

- (id)init {
    self = [super init];
    [self setUsesSingleLineMode:YES];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    self = [super copyWithZone:zone];
    self->_color = [_color retain];
    return self;
}

- (void)dealloc {
    [_color release];
    [super dealloc];
}

@synthesize color = _color;

- (NSRect)colorRectForFrame:(NSRect)frame {
    NSRect result = frame;
    result.size.width = frame.size.height;
    return result;
}

- (NSRect)_titleFrameForInteriorFrame:(NSRect)frame {
    NSRect colorFrame = [self colorRectForFrame:frame];
    NSRect result = colorFrame;
    result.origin.x = NSMaxX(colorFrame) + INSET_FROM_IMAGE_TO_TEXT;
    // Go as wide as we can
    result.size.width = NSMaxX(frame) - NSMinX(result);
    // Center in the height
    // Move the title above the Y centerline of the image. 
    NSSize naturalSize = [super cellSize];
    result.origin.y = floor(NSMidY(frame) - naturalSize.height / 2.0);
    result.size.height = naturalSize.height;
    return result;
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
    if (_color) {
        [_color set];
        NSRect colorFrame = [self colorRectForFrame:frame];
        NSRectFill(colorFrame);
        [[NSColor lightGrayColor] set];
        NSFrameRectWithWidth(colorFrame, 1.0);
    }
    
    NSRect titleFrame = [self _titleFrameForInteriorFrame:frame];
    [super drawInteriorWithFrame:titleFrame inView:controlView];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)frame ofView:(NSView *)controlView {
    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
    NSRect colorRect = [self colorRectForFrame:frame];
    if (NSPointInRect(point, colorRect)) {
        // We combine in our own hit test marker
        return NSCellHitTrackableArea | ATCellHitTestColorRect;
    } else {
        NSUInteger result = [super hitTestForEvent:event inRect:[self _titleFrameForInteriorFrame:frame] ofView:controlView];
        // We don't want the label to be editable
        result = result & ~NSCellHitEditableTextArea;
        return result;
    }
    
}


@end
