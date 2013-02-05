/*
     File: TargetView.m 
 Abstract: A simple NSImageView subclass that draws little green circles where the user clicks on top of the image.
  
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "TargetView.h"

@implementation TargetView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.image = [NSImage imageNamed:@"bullseye"];
        [self setAutoresizingMask: (NSViewMinYMargin | NSViewMinXMargin)];
    }
    return self;
}

- (void)dealloc {
    [_path release];
    [super dealloc];
}


#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)event {
    // We use an NSBezierPath to store and draw the clicked points. We create it lazily on the first click in the view.
    if (!_path){
        _path = [[NSBezierPath bezierPath] retain];
    }
    
    // Convert the clicked point into the views coordinate space and add the green circle to the bezierPath. Any point within the bounds of the view is considered a hit.
    NSPoint cursorLocation = [event locationInWindow];
    cursorLocation = [self convertPoint:cursorLocation fromView:nil];
    
    // Test if the hit occured in the opaque part of the image.  We create a 1x1 rectange at the click point and test for intersection with a non-transparent section of the image.
    NSRect cursorLocationRect = { cursorLocation, {1, 1} };
    if ( [self.image hitTestRect:cursorLocationRect withImageDestinationRect:self.bounds 
                       context:nil hints:nil flipped:NO] == NO ) {
        // If the click missed then we ignore it here.
        [super mouseDown:event];
        return;
    }
    
    static const CGFloat kHoleRadius = 6.0f;
    CGFloat kHoleDiameter = kHoleRadius * 2.0f;
    
    NSRect holeFrame = NSMakeRect(cursorLocation.x - kHoleRadius, cursorLocation.y - kHoleRadius, kHoleDiameter, kHoleDiameter);
    [_path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:holeFrame]];
    
    [self setNeedsDisplayInRect:holeFrame];
}


#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
    // Let super handle drawing of the image.
    [super drawRect:dirtyRect];
    
    // All we need to draw are the green circles where the user clicked.
    [[NSColor greenColor] set];
    [_path fill];
}

@end
