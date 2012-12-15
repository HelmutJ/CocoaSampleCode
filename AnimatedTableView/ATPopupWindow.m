/*
     File: ATPopupWindow.m
 Abstract:  A custom NSWindow that mainly implements a "popup" animation using CoreAnimation.
 
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

#import <QuartzCore/QuartzCore.h>
#import "ATPopupWindow.h"

#define GROW_ANIMATION_DURATION 0.20
#define GROW_SCALE 1.25

#define SHRINK_ANIMATION_DURATION 0.10
#define SHRINK_SCALE 0.80

#define RESTORE_ANIMATION_DURATION 0.10

@implementation ATPopupWindow

- (void)_cleanupAndRestoreViews {
    // Swap back the content view
    if (_oldContentView != nil) {
        // We disable screen updates to avoid any flashing that might happening when one
        // layer backed view goes away and another regular view replaces it.
        //
        NSDisableScreenUpdates();
        [self setFrame:_originalWidowFrame display:NO];
        [self setContentView:_oldContentView];
        [_oldContentView release];
        _oldContentView = nil;
        
        [self makeFirstResponder:_oldFirstResponder];
        _oldFirstResponder = nil;
        
        [_animationView release];
        _animationView = nil;
        
        _animationLayer = nil; // Non retained
        NSEnableScreenUpdates();
    }
    _shrinking = NO;
    _growing = NO;
}

- (CATransform3D)_transformForScale:(CGFloat)scale {
    if (scale == 1.0) {
        return CATransform3DIdentity;
    } else {
        // Start at the scale percentage
        CATransform3D scaleTransform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0);
        // Create a translation to make us popup from somewhere other than the center
        CGFloat yTrans = NSHeight(_originalLayerFrame)/2.0 - (NSHeight(_originalLayerFrame)*scale)/2.0;
        CGFloat xTrans = 0; // No X translating -- we popup from the X center
        CATransform3D translateTransform = CATransform3DTranslate(CATransform3DIdentity, xTrans, yTrans, 1.0);
        return CATransform3DConcat(scaleTransform, translateTransform);
    }
}

- (void)_addAnimationToScale:(CGFloat)scale duration:(NSTimeInterval)duration {
    CABasicAnimation *transformAni = [CABasicAnimation animation];
    transformAni.fromValue = [NSValue valueWithCATransform3D:_animationLayer.transform];
    transformAni.duration = duration;
    // We make ourselves the delegate to get notified when the animation ends
    transformAni.delegate = self;
    // Set the final "toValue" for the animation and the layer contents. 
    // At the end of the animation it is left at this value, which is what we want
    _animationLayer.transform = [self _transformForScale:scale];
    [_animationLayer addAnimation:transformAni forKey:@"transform"];
}

// Chain several animations together -- one starting at the end of the other
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (!flag) {
        _animationLayer.transform = [self _transformForScale:1.0];
        [self _cleanupAndRestoreViews];
    } else if (_growing) {
        _growing = NO;
        _shrinking = YES;
        [self _addAnimationToScale:SHRINK_SCALE duration:SHRINK_ANIMATION_DURATION];
    } else if (_shrinking) {
        _shrinking = NO;
        [self _addAnimationToScale:1.0 duration:RESTORE_ANIMATION_DURATION];
    } else {
        [self _cleanupAndRestoreViews];
    }
}

// Our window doesn't have a title bar or a resize bar, but we want it to still become key.
// However, we want the tableview to draw as the first responder even when the window
// isn't key. So, we return NO when we are drawing to work around that.
//
- (BOOL)canBecomeKeyWindow {
    if (_pretendKeyForDrawing) return NO;
    return YES;
}

// The scrollers always draw blue if they are in a key window.
// Temporarily tell them that our window is key for caching the proper image.
//
- (BOOL)isKeyWindow {
    if (_pretendKeyForDrawing) return YES;
    return [super isKeyWindow];
}

- (void)popup {
    // Stop any existing animations
    if (_animationView != nil) {
        [_animationLayer removeAllAnimations];
        [self _cleanupAndRestoreViews];
    }
    
    // Perform some initial setup - hide the window and make us not have a shadow while animating
    if ([self isVisible]) {
        [self orderOut:nil];
    }
    
    // Grab the content view and cache its contents
    _oldContentView = [[self contentView] retain];
    // We also want to restore the current first responder
    _oldFirstResponder = [self firstResponder];

    _pretendKeyForDrawing = YES;
    NSRect visibleRect = [_oldContentView visibleRect];
    NSBitmapImageRep *imageRep = [_oldContentView bitmapImageRepForCachingDisplayInRect:visibleRect];
    [_oldContentView cacheDisplayInRect:visibleRect toBitmapImageRep:imageRep];
    _pretendKeyForDrawing = NO;
    
    // Create a new content view for animating
    _animationView = [[NSView alloc] initWithFrame:visibleRect];
    [_animationView setWantsLayer:YES];
    [self setContentView:_animationView];
    
    // Temporarily enlargen the window size to accomidate the "grow" animation.
    _originalWidowFrame = self.frame;
    CGFloat xGrow = NSWidth(_originalWidowFrame)*0.5;
    CGFloat yGrow = NSHeight(_originalWidowFrame)*0.5;
    [self setFrame:NSInsetRect(_originalWidowFrame, -xGrow, -yGrow) display:NO];

    // Calculate where we want the animation layer to be based off of the offset we set above
    _originalLayerFrame = visibleRect;
    _originalLayerFrame.origin.x += xGrow;
    _originalLayerFrame.origin.y += yGrow;

    // Create a manual layer and control it's contents and position
    _animationLayer = [CALayer layer];
    _animationLayer.frame = NSRectToCGRect(_originalLayerFrame);
    _animationLayer.contents = (id)[imageRep CGImage];
    // A shadow is needed to match what the window normally has
    _animationLayer.shadowOpacity = 0.50;
    _animationLayer.shadowRadius = 4;
    // Start at 1% scale
    _animationLayer.transform = [self _transformForScale:0.01];
    
    // Get the layer into the rendering tree
    [[_animationView layer] addSublayer:_animationLayer];

    // Bring the window up and flush the contents
    [self makeKeyAndOrderFront:nil];
    [self displayIfNeeded];
    
    // Start the grow animation
    _growing = YES;
    [self _addAnimationToScale:GROW_SCALE duration:GROW_ANIMATION_DURATION];
}

@end
