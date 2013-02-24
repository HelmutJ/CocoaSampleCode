/*
     File: DragTracker.h 
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

#import "InputTracker.h"

@interface DragTracker : InputTracker {
@private
    BOOL _trackingDrag;
    NSPoint _initialPoint;
    NSPoint _currentPoint;
    
    CGFloat _threshold;
    NSUInteger _modifiers;
    
    SEL _beginTrackingAction;
    SEL _updateTrackingAction;
    SEL _endTrackingAction;
    
    id _userInfo;
}

// The cursor location in the view's coordinate space where the mouse down occured.
@property(readonly) NSPoint initialPoint;

// The difference between the initial cursor location and the current cursor location. This value is in the view's coordinate space.
@property(readonly) NSPoint delta;

// The modifier flags of the last event processed by the tracker. The returned value outside of the begin and end tracking actions are undefined.
@property(readonly) NSUInteger modifiers;

// The number of points the cursor must move (in any direction) before tracking begins.
@property CGFloat threshold;

// The following three properties hold the tracking callbacks on the view. Each method should have one paramenter (DragTracker *) and a void return.
@property SEL beginTrackingAction;
@property SEL updateTrackingAction;
@property SEL endTrackingAction;

// Storage for your custom object to help with tracking. For example, a pointer to the object being modified may be set as the userInfo when the beginTrackingAction method is called. 
@property(retain) id userInfo;
@end
