/*
     File: TargetGalleryController.m 
 Abstract: The main controller for this application. This class demonstrates how events may flow up the responder chain to the NSWindowController by implementing mouse tracking to drag targets when the TargetGallery is in edit mode.
  
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

#import "TargetGalleryController.h"
#import "TargetGallery.h"
#import "TargetObject.h"
#import "TargetView.h"


static const CGFloat kTargetSize = 64.0f;

@implementation TargetGalleryController

- (void)awakeFromNib {
    [_targetGallery setIsEditing:NO];
    
    // Create a bunch of targets all lined up and start animating them.
    TargetObject *target;
    NSRect targetFrame = NSMakeRect(NSMaxX(_targetGallery.bounds) - kTargetSize / 2.0f, NSMidY(_targetGallery.bounds), kTargetSize, kTargetSize);
    
    do {
        target = [[TargetObject alloc] init];
        target.view = [[[TargetView alloc] initWithFrame:targetFrame] autorelease];
        target.velocity = NSMakePoint(50.0f, 0.0f);
        [_targetGallery addTarget:target];
        [target release];
        targetFrame.origin.x -= NSWidth(targetFrame) + kTargetSize / 2.0f;
    } while (targetFrame.origin.x > 0);
    
    [_targetGallery startAnimating];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


#pragma mark NSResponder

// It is reasonable to have the TargetGalleryView handle the dragging of the targets in edit mode. However, I do it here to demonstrate how the mouse events flow up the responder chain to the window controller.
- (void)mouseDown:(NSEvent *)event {
    NSPoint targetLocation = [_targetGallery convertPoint:event.locationInWindow fromView:nil];
    _dragTarget = [_targetGallery targetAtPoint:targetLocation];
    
    if(!_dragTarget) return;
    
    _lastDragTime = event.timestamp;
    _lastDragPoint = targetLocation;
    _dragVelocity = NSZeroPoint;
    _dragTarget.velocity = NSZeroPoint;

    [self mouseDragged:event];
}

- (void)mouseDragged:(NSEvent *)event {
    if(!_dragTarget) return;
    
    NSPoint targetLocation = [_targetGallery convertPoint:event.locationInWindow fromView:nil];
    NSTimeInterval timeDelta = event.timestamp - _lastDragTime;
    
    if(timeDelta > 0) {
        _dragVelocity.x = (targetLocation.x - _lastDragPoint.x) / timeDelta;
        _dragVelocity.y = (targetLocation.y - _lastDragPoint.y) / timeDelta;
    }
    _lastDragTime = event.timestamp;
    _lastDragPoint = targetLocation;
    
    NSRect targetFrame = _dragTarget.view.frame;
    targetFrame.origin.x = targetLocation.x - NSWidth(targetFrame) / 2.0f;
    targetFrame.origin.y = targetLocation.y - NSHeight(targetFrame) / 2.0f;
    [_dragTarget.view setFrameOrigin:targetFrame.origin];
}

- (void)mouseUp:(NSEvent *)event {
    if (!_dragTarget) return;

    _dragTarget.velocity = _dragVelocity;
    _dragTarget = nil;
}


#pragma mark API

- (IBAction)toggleGalleryEditing:(id)sender {
    BOOL isEditing = [_targetGallery isEditing];
    
    // Update the text of the toolbar item since it is a toggle.
    if (isEditing) {
        [sender setLabel:NSLocalizedString(@"Edit", "Switch Target Gallery to edit mode")];
    } else {
        [sender setLabel:NSLocalizedString(@"Shoot", "Switch Target Gallery to shooting mode")];
    }
    
    // Flip the state.
    [_targetGallery setIsEditing:!isEditing];
}

-(IBAction)stopTargets:(id)sender {
    // Don't stop animating, just set all the targets' velocity to 0 so they don't move.
    for (TargetObject *object in [_targetGallery targets]) {
        object.velocity = NSZeroPoint;
    }
}

@end
