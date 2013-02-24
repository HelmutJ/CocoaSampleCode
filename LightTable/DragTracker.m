/*
     File: DragTracker.m
 Abstract: The Drag Tracker tracks the changes of the mouse during a primary button drag. Tracking starts when the left mouse button is held down and the movement of the cursor exceeds a threshold value. Tracking ends when the mouse button is released. The owning view must route mouseDown:, mouseDragged: and mouseUp: responder messages to this tracker.
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "DragTracker.h"


@interface DragTracker()
@property BOOL isTrackingDrag;
@property(readwrite) NSPoint initialPoint;
@property NSPoint currentPoint;
@property(readwrite) NSUInteger modifiers;
@end


@implementation DragTracker

- (id)init {
    if (self = [super init]) {
        self.threshold = 2.0;
    }
    
    return self;
}

- (void)dealloc {
    self.userInfo = nil;
    [super dealloc];
}

#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)event {
    self.initialPoint = [self.view convertPointFromBase:[event locationInWindow]];
    self.currentPoint = self.initialPoint;
}

- (void)mouseDragged:(NSEvent *)event {
    self.modifiers = [event modifierFlags];
    self.currentPoint = [self.view convertPointFromBase:[event locationInWindow]];
    
    if (!self.isEnabled) return;
    
    if (!self.isTrackingDrag) {
        NSPoint delta = self.delta;
        if (fabs(delta.x) > self.threshold || fabs(delta.y) > self.threshold) {
            self.isTrackingDrag = YES;
            if (self.beginTrackingAction) [NSApp sendAction:self.beginTrackingAction to:self.view from:self];
        }
    } else {
        if (self.updateTrackingAction) [NSApp sendAction:self.updateTrackingAction to:self.view from:self];
    }
}

- (void)mouseUp:(NSEvent *)event {
    if (self.isTrackingDrag) {
        self.modifiers = [event modifierFlags];
        if (self.endTrackingAction) [NSApp sendAction:self.endTrackingAction to:self.view from:self];
        self.isTrackingDrag = NO;
    }
}


#pragma mark InputTracker



- (void)cancelTracking {
    if (self.isTrackingDrag) {
        if (self.endTrackingAction) [NSApp sendAction:self.endTrackingAction to:self.view from:self];
        self.isTrackingDrag = NO;
    }
}

#pragma mark API

@synthesize isTrackingDrag = _trackingDrag;
@synthesize initialPoint = _initialPoint;
@synthesize currentPoint = _currentPoint;
@synthesize threshold = _threshold;

@synthesize beginTrackingAction = _beginTrackingAction;
@synthesize updateTrackingAction = _updateTrackingAction;
@synthesize endTrackingAction = _endTrackingAction;

@synthesize modifiers = _modifiers;

@synthesize userInfo = _userInfo;

- (NSPoint)delta;
{
    NSPoint delta;
    delta.x = self.currentPoint.x - self.initialPoint.x;
    delta.y = self.currentPoint.y - self.initialPoint.y;
    return delta;
}

@end

