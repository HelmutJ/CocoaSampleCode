/*
     File: InputIndicator.m
 Abstract: Subclass of NSView for displaying which key from the numeric pad is down.
  Version: 1.0
 
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

// ??? This should just dirty the appropriate rect

#import "InputIndicator.h"

@implementation InputIndicator

- (id)initWithFrame:(NSRect)rect {
    if (self = [super initWithFrame:rect]) {
	[self allocateGState];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    NSImage *image = [NSImage imageNamed:@"keypad"];
    NSRect imageRect = NSMakeRect(0, 0, [image size].width, [image size].height);
    [image drawAtPoint:NSZeroPoint fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)rectFor:(NSInteger)cmd {
    CGFloat width = [self bounds].size.width / 4.0;
    CGFloat height = [self bounds].size.height / 5.0;
    CGFloat xLoc = 0.0, yLoc = 0.0;

    switch (cmd) {
        case GoUpRightCommand:		xLoc = 2 * width; yLoc = 3 * height; break;
        case GoUpCommand:		xLoc =     width; yLoc = 3 * height; break;
        case GoUpLeftCommand:		yLoc = 3 * height; break;
        case GoRightCommand:		xLoc = 2 * width; yLoc = 2 * height; break;
        case StopCommand:		xLoc =     width; yLoc = 2 * height; break;
        case GoLeftCommand:		yLoc = 2 * height; break;
        case GoDownRightCommand:	xLoc = 2 * width; yLoc =     height; break;
        case GoDownCommand:		xLoc =     width; yLoc =     height; break;
        case GoDownLeftCommand:		yLoc =     height; break;
        case FireCommand:		width *= 2; break;
        default:			return NSZeroRect;
    }

    return NSIntegralRect(NSMakeRect(xLoc, yLoc, width, height));
}

- (void)turnOn:(NSInteger)cmd {
    if (!highlighted[cmd]) {
        NSRect rect = [self rectFor:cmd];
        if (rect.size.width > 0.0) {
            rect = NSInsetRect(rect, 1.0, 1.0);
            [self lockFocus];
            [[NSColor whiteColor] set];
            [NSBezierPath strokeRect:rect];
            [self unlockFocus];
            highlighted[cmd] = YES;
        }
    }
}

- (void)turnOff:(NSInteger)cmd {
    if (highlighted[cmd]) {
        NSRect rect = [self rectFor:cmd];
        if (rect.size.width > 0.0) {
            [self lockFocus];
            [[NSImage imageNamed:@"keypad"] drawAtPoint:rect.origin fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
            [self unlockFocus];
            highlighted[cmd] = NO;
        }
    }
}
@end
