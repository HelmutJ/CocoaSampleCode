/*
     File: RemainingHelicopters.m
 Abstract: Subclass of NSView for displaying the number of helicopters left
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



#import "RemainingHelicopters.h"

@implementation RemainingHelicopters
    
- (void)drawRect:(NSRect)r {
    NSRect bounds = [self bounds];
    NSInteger helicoptersToDisplay = remainingHelicopters;
    if (helicoptersToDisplay < 3) helicoptersToDisplay = 3;

    CGFloat inc;
    NSInteger cnt;
    NSPoint point = NSZeroPoint;
    NSImage *helicopters = [NSImage imageNamed:@"helicopter"];
    NSRect rect = NSMakeRect(0.0, 0.0, [helicopters size].width, [helicopters size].height / 4);
    point.x = floor((bounds.size.width - rect.size.width) / 2.0);
    if (helicoptersToDisplay * rect.size.height >= bounds.size.height) {
        inc = (bounds.size.height - helicoptersToDisplay * rect.size.height) / (helicoptersToDisplay - 1);
    } else {
        inc = (bounds.size.height - helicoptersToDisplay * rect.size.height) / (helicoptersToDisplay + 1);
    }
    point.y = floor(NSMaxY(bounds) - rect.size.height - ((inc < 0) ? 0 : inc));
    for (cnt = helicoptersToDisplay; cnt > 0; cnt--) {
	[helicopters dissolveToPoint:point fromRect:rect fraction:(cnt > remainingHelicopters) ? 0.2 : 1.0];
        point.y = point.y - (rect.size.height + inc);
    }
}

- (void)setIntegerValue:(NSInteger)val {
    remainingHelicopters = val - 1;
    [self setNeedsDisplay:YES];
}

- (NSInteger)integerValue {
    return remainingHelicopters + 1;
}
@end
