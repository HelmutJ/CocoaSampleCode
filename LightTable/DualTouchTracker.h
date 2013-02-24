/*
     File: DualTouchTracker.h 
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

#import "InputTracker.h"

@interface DualTouchTracker : InputTracker {
@private
    BOOL _tracking;
    NSPoint _initialPoint;
    NSUInteger _modifiers;
    CGFloat _threshold;
    
    NSTouch *_initialTouches[2];
    NSTouch *_currentTouches[2];
    
    SEL _beginTrackingAction;
    SEL _updateTrackingAction;
    SEL _endTrackingAction;
    
    id _userInfo;
}

// The amount of dual touch movement before tracking begins. This value is in points (72ppi). Defaults to 1.
@property CGFloat threshold;

// The location of the cursor in the view's coordinate space when the second touch began.
@property(readonly) NSPoint initialPoint;

// The modifier flags of the last event processed by the tracker. The returned value outside of the begin and end tracking actions are undefined.
@property(readonly) NSUInteger modifiers;

// The two tracked touches are considered the bounds of a rectangle. THe following methods allow you to get the change in origin or size from the inital tracking values to the current values of said rectangle. The values are in points (72ppi)
@property(readonly) NSPoint deltaOrigin;
@property(readonly) NSSize deltaSize;

// The following three properties hold the tracking callbacks on the view. Each method should have one paramenter (DragTracker *) and a void return.
@property SEL beginTrackingAction;
@property SEL updateTrackingAction;
@property SEL endTrackingAction;

// Storage for your custom object to help with tracking. For example, a pointer to the object being modified may be set as the userInfo when the beginTrackingAction method is called. 
@property(retain) id userInfo;
@end
