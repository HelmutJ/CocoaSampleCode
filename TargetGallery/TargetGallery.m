/*
     File: TargetGallery.m 
 Abstract: A basic view that animates the movement of "targets". A target is simply an object that associates a view with a velocity. This class adds each target's view as a subview and moves the view according to its associated veloicty.
  
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
 
#import "TargetGallery.h"
#import "TargetView.h"
#import "TargetObject.h"

static const NSTimeInterval kAnimationDelay = 0.03333333;

@interface TargetGallery ()
- (void)moveTargets:(id)ignored;
@end


@implementation TargetGallery

@synthesize isEditing = _isEditing;
@synthesize targets = _targets;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _targets = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)dealloc {
    [self stopAnimating];
    [_targets release];
    [super dealloc];
}


#pragma mark NSResponder

- (void)mouseDown:(NSEvent *) event {
    // In edit mode, let super route the event as normal 
    if (self.isEditing) return [super mouseDown:event];

    // Otherwise, a click hitting this view means the user missed. Beep to let them know.
    NSBeep();
}


#pragma mark NSView
// By overriding -hitTest: we can control where Cocoa routes mouse events. In this case, when the TargetGallery is in editing mode, we stop Cocoa from sending mouse events to our subviews (targets) by returning self.
- (NSView *)hitTest:(NSPoint)aPoint {
    if (self.isEditing) {
        return self;
    }
    
    // Not in editing mode, let super (NSView) do its normal hit testing.
    return [super hitTest:aPoint];
}


#pragma mark API

- (void)addTarget:(TargetObject *)target {
    [_targets addObject:target];
    [self addSubview:target.view];
}

- (TargetObject *)targetForView:(NSView *)view {
    for (TargetObject *target in _targets) {
        if (target.view == view) return target;
    }
    
    return nil;
}

- (TargetObject *)targetAtPoint:(NSPoint)point {
    return [self targetForView:[super hitTest:point]];
}

- (void)startAnimating {
    // cancel any outstanding animation request before requesting a new one.
    [self stopAnimating];
    [self performSelector:@selector(moveTargets:) withObject:nil afterDelay:kAnimationDelay];
}

- (void)stopAnimating {
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
}

- (void)moveTargets:(id)ignored {
    // Adjust each target by its velocity
    for (TargetObject *target in _targets) {
        if (!NSEqualPoints(NSZeroPoint, target.velocity)) {
            NSRect frame = [target.view frame];
            frame.origin.x += target.velocity.x * kAnimationDelay;
            frame.origin.y += target.velocity.y * kAnimationDelay;
            
            if (!NSIntersectsRect(frame, self.bounds)) {
                // Take horizontal wrap around into consideration.
                if (target.velocity.x < 0) {
                    if (NSMaxX(frame) < NSMinX(self.bounds)) {
                        frame.origin.x = NSMaxX(self.bounds) - 1;
                    }
                } else if (target.velocity.x > 0) {
                    if (NSMinX(frame) > NSMaxX(self.bounds)) {
                        frame.origin.x = NSMinX(self.bounds) - NSWidth(frame) + 1;
                    }
                }
                
                // Take vertical wrap around into consideration.
                if (target.velocity.y < 0) {
                    if (NSMaxY(frame) < NSMinY(self.bounds)) {
                        frame.origin.y = NSMaxY(self.bounds) - 1;
                    }
                } else if (target.velocity.y > 0) {
                    if (NSMinY(frame) > NSMaxY(self.bounds)) {
                        frame.origin.y = NSMinY(self.bounds) - NSHeight(frame) + 1;
                    }
                }
            }
            
            
            [target.view setFrameOrigin:frame.origin];
        }
    }
    
    // Set up calling next frame of the animation.
    [self performSelector:@selector(moveTargets:) withObject:nil afterDelay:kAnimationDelay];
}

@end
