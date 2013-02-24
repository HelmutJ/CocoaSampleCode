/*
     File: DualTouchTracker.m
 Abstract: The Dual Touch Tracker tracks the changes of two touches on a multi-touch trackpad. Tracking starts when the movement of two concurrent touches exceeds a threshold value. Tracking ends when either a third touch begins, or one of the touches are released, or touches are cancelled. The owning view must route touchesBeganWithEvent:, touchesMovedWithEvent:, touchesEndedWithEvent: and touchesCancelledWithEvent: responder messages to this tracker.
 
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

#import "DualTouchTracker.h"

@interface DualTouchTracker()
@property BOOL isTracking;
@property(readwrite) NSPoint initialPoint;
@property(readwrite) NSUInteger modifiers;
- (void)releaseTouches;
@end


@implementation DualTouchTracker

- (id)init {
    if (self = [super init]) {
        self.threshold = 1;
    }
    
    return self;
}

- (void)dealloc {
    self.userInfo = nil;
    [self releaseTouches];
    [super dealloc];
}

#pragma mark NSResponder

- (void)touchesBeganWithEvent:(NSEvent *)event {
    if (!self.isEnabled) return;
    
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self.view];
    
    if (touches.count == 2) {
        self.initialPoint = [self.view convertPointFromBase:[event locationInWindow]];
        NSArray *array = [touches allObjects];
        _initialTouches[0] = [[array objectAtIndex:0] retain];
        _initialTouches[1] = [[array objectAtIndex:1] retain];
        
        _currentTouches[0] = [_initialTouches[0] retain];
        _currentTouches[1] = [_initialTouches[1] retain];
    } else if (touches.count > 2) {
        // More than 2 touches. Only track 2.
        if (self.isTracking) {
            [self cancelTracking];
        } else {
            [self releaseTouches];
        }

    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    if (!self.isEnabled) return;
    
    self.modifiers = [event modifierFlags];
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self.view];
    
    if (touches.count == 2 && _initialTouches[0]) {
        NSArray *array = [touches allObjects];
        [_currentTouches[0] release];
        [_currentTouches[1] release];
        
        NSTouch *touch;
        touch = [array objectAtIndex:0];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = [touch retain];
        } else {
            _currentTouches[1] = [touch retain];
        }
        
        touch = [array objectAtIndex:1];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = [touch retain];
        } else {
            _currentTouches[1] = [touch retain];
        }
        
        if (!self.isTracking) {
            NSPoint deltaOrigin = self.deltaOrigin;
            NSSize  deltaSize = self.deltaSize;
            
            if (fabs(deltaOrigin.x) > _threshold || fabs(deltaOrigin.y) > _threshold || fabs(deltaSize.width) > _threshold || fabs(deltaSize.height) > _threshold) {
                self.isTracking = YES;
                if (self.beginTrackingAction) [NSApp sendAction:self.beginTrackingAction to:self.view from:self];
            }
        } else {
            if (self.updateTrackingAction) [NSApp sendAction:self.updateTrackingAction to:self.view from:self];
        }
    }
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    if (!self.isEnabled) return;
    
    self.modifiers = [event modifierFlags];
    [self cancelTracking];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    [self cancelTracking];
}

#pragma mark InputTracker


- (void)cancelTracking {
    if (self.isTracking) {
        if (self.endTrackingAction) [NSApp sendAction:self.endTrackingAction to:self.view from:self];
        self.isTracking = NO;
        [self releaseTouches];
    }
}

#pragma mark API

@synthesize userInfo = _userInfo;
@synthesize threshold = _threshold;
@synthesize isTracking = _tracking;
@synthesize initialPoint = _initialPoint;

@synthesize beginTrackingAction = _beginTrackingAction;
@synthesize updateTrackingAction = _updateTrackingAction;
@synthesize endTrackingAction = _endTrackingAction;

@synthesize modifiers = _modifiers;

- (NSPoint)deltaOrigin {
    if (!(_initialTouches[0] && _initialTouches[1] && _currentTouches[0] && _currentTouches[1])) return NSZeroPoint;
    
    CGFloat x1 = MIN(_initialTouches[0].normalizedPosition.x, _initialTouches[1].normalizedPosition.x);
    CGFloat x2 = MIN(_currentTouches[0].normalizedPosition.x, _currentTouches[1].normalizedPosition.x);
    CGFloat y1 = MIN(_initialTouches[0].normalizedPosition.y, _initialTouches[1].normalizedPosition.y);
    CGFloat y2 = MIN(_currentTouches[0].normalizedPosition.y, _currentTouches[1].normalizedPosition.y);
    
    NSSize deviceSize = _initialTouches[0].deviceSize;
    NSPoint delta;
    delta.x = (x2 - x1) * deviceSize.width;
    delta.y = (y2 - y1) * deviceSize.height;
    return delta;
}

- (NSSize)deltaSize {
    if (!(_initialTouches[0] && _initialTouches[1] && _currentTouches[0] && _currentTouches[1])) return NSZeroSize;
    
    CGFloat x1,x2,y1,y2,width1,width2,height1,height2;
    
    x1 = MIN(_initialTouches[0].normalizedPosition.x, _initialTouches[1].normalizedPosition.x);
    x2 = MAX(_initialTouches[0].normalizedPosition.x, _initialTouches[1].normalizedPosition.x);
    width1 = x2 - x1;
    
    y1 = MIN(_initialTouches[0].normalizedPosition.y, _initialTouches[1].normalizedPosition.y);
    y2 = MAX(_initialTouches[0].normalizedPosition.y, _initialTouches[1].normalizedPosition.y);
    height1 = y2 - y1;
    
    x1 = MIN(_currentTouches[0].normalizedPosition.x, _currentTouches[1].normalizedPosition.x);
    x2 = MAX(_currentTouches[0].normalizedPosition.x, _currentTouches[1].normalizedPosition.x);
    width2 = x2 - x1;
    
    y1 = MIN(_currentTouches[0].normalizedPosition.y, _currentTouches[1].normalizedPosition.y);
    y2 = MAX(_currentTouches[0].normalizedPosition.y, _currentTouches[1].normalizedPosition.y);
    height2 = y2 - y1;
    
    NSSize deviceSize = _initialTouches[0].deviceSize;
    NSSize delta;
    delta.width = (width2 - width1) * deviceSize.width;
    delta.height = (height2 - height1) * deviceSize.height;
    return delta;
}

- (void)releaseTouches {
    [_initialTouches[0] release];
    [_initialTouches[1] release];
    [_currentTouches[0] release];
    [_currentTouches[1] release];
    
    _initialTouches[0] = nil;
    _initialTouches[1] = nil;
    _currentTouches[0] = nil;
    _currentTouches[1] = nil;
}

@end
