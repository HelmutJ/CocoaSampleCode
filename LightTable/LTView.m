/*
     File: LTView.m
 Abstract: This custom view uses CALayers to arange and draw slides. Drag and Drop images onto this view to add them as slides. Double-click a slide to edit the masking of the image to the slide. This view tracks both mouse and touch events to modify the slide. Using two fingers on the trackpad will adjust the position and size of the slide under the cursor.
 
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

#import "InputTrackers.h"
#import "LTView.h"
#import "LTMaskLayer.h"

// The _LTOverlayLayer class is used so that our overlay layer with the drag handles is not included in hit testing. Otherwise, hit testing would always return the overlay layer since it is the top layer and fills the entire view. I used an underbar in the classname and implemented it in this file because it is a private helper class of LTView.
@interface _LTOverlayLayer : CALayer
@end

@implementation _LTOverlayLayer
- (BOOL)containsPoint:(CGPoint)p {
    return NO;
}
@end


#pragma mark Tracking Dictionary Keys
// These are the keys for properties we store in the InputTracker dictionary.
static NSString *kLayerKey = @"layer";
static NSString *kInitialFrameKey = @"initialFrame";
static NSString *kInitialPositionKey = @"initialPosition";
static NSString *kResizeIndexKey = @"resizeIndex";

// This is pointer value that we use as the binding context fot LTView
NSString *kLTOberserverContext = @"LTView.context";

// In 64bit, NS and CG points/rects are interchangeable without compiler warnings. But for 32 bit, we have to do a whole bunch of conversions to make the compiler happy. There is no CG equivalent call for NSPointInRect. We use it a fair amount in this sample, so this macro will make reading the code easier later on.
#define LTPointInRect(p,r) NSPointInRect(NSPointFromCGPoint(p), NSRectFromCGRect(r))

#pragma mark Resize Rect Helpers
static void resizeRectsForFrame(CGRect *resizeRects, CGRect frame) {
    if (!resizeRects) return;
    CGFloat width = 5.0;
            
    //top left
    resizeRects[0] = CGRectMake(CGRectGetMinX(frame) - width, CGRectGetMaxY(frame), width, width);
    //top middle
    resizeRects[1] = CGRectMake(CGRectGetMidX(frame) - width/2.0, CGRectGetMaxY(frame), width, width);
    //top right
    resizeRects[2] = CGRectMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame), width, width);
    //right middle
    resizeRects[3] = CGRectMake(CGRectGetMaxX(frame), CGRectGetMidY(frame) - width/2.0, width, width);
    //bottom right
    resizeRects[4] = CGRectMake(CGRectGetMaxX(frame), CGRectGetMinY(frame)- width, width, width);
    //bottom middle
    resizeRects[5] = CGRectMake(CGRectGetMidX(frame) - width/2.0, CGRectGetMinY(frame) - width, width, width);
    //bottom left
    resizeRects[6] = CGRectMake(CGRectGetMinX(frame) - width, CGRectGetMinY(frame) - width, width, width);
    //left middle
    resizeRects[7] = CGRectMake(CGRectGetMinX(frame) - width, CGRectGetMidY(frame) - width/2.0, width, width);
}

static NSInteger indexOfResizeRectForPoint(CGRect *resizeRects, CGPoint point) {
    if (!resizeRects) return -1;
    
    if (LTPointInRect(point, resizeRects[0])) return 0;
    if (LTPointInRect(point, resizeRects[1])) return 1;
    if (LTPointInRect(point, resizeRects[2])) return 2;
    if (LTPointInRect(point, resizeRects[3])) return 3;
    if (LTPointInRect(point, resizeRects[4])) return 4;
    if (LTPointInRect(point, resizeRects[5])) return 5;
    if (LTPointInRect(point, resizeRects[6])) return 6;
    if (LTPointInRect(point, resizeRects[7])) return 7;
    
    return -1;
}

@interface LTView ()
- (void)_initTrackers;
- (void)drawDragHandleFrames:(CGRect *)handleFrames inContext:(CGContextRef)context;
@end


@implementation LTView

+ (void)initialize {
    [self exposeBinding:kLTViewSlides];
    [self exposeBinding:kLTViewSelectionIndexes];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

		// setup the CALayer for the overall full-screen view
		CALayer *backingLayer = [CALayer layer];
		_overlayLayer = [[_LTOverlayLayer layer] retain];
		
		[self setLayer:backingLayer];
		[self setWantsLayer:YES];
		
		backingLayer.frame = NSRectToCGRect(frame);
		backingLayer.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
        backingLayer.backgroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
        backingLayer.opaque = YES;
        
        // The overlay layer is used to draw any drag handles, so that they are always on top of all slides. We must take care to make sure this layer is always the last one.
        _overlayLayer.frame = backingLayer.frame;
        _overlayLayer.opaque = NO;
        _overlayLayer.delegate = self; // We want to be the delegate so we can do the drag handle drawing
        _overlayLayer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 0.0);
        _overlayLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        [backingLayer addSublayer:_overlayLayer];
		
        // init ivars
        _slides = [[NSMutableArray array] retain];
        self.selectionIndexes = [NSIndexSet indexSet];
		
        // init the input trackers
        [self _initTrackers];
        
        // register for dragging
        [self registerForDraggedTypes:[NSArray arrayWithObject:(NSString *)kUTTypeFileURL]];
        
		// we want touch events
		[self setAcceptsTouchEvents:YES];
    }
	
    return self;
}

- (void)dealloc {
    [_inputTrackers release];
    [_selectionIndexes release];
    [_overlayLayer release];
    
    // Remove all objects via the KVO methods to make sure we remove our observers.
    [[self mutableArrayValueForKey:kLTViewSlides] removeAllObjects];
    [_slides release];
    
	[super dealloc];
}


// Create the set of tracker objects the LTView needs. See InputTracker.h for more information.
- (void)_initTrackers {
    _inputTrackers = [NSMutableArray new];
    
    ClickTracker *clickTracker = [ClickTracker new];
    clickTracker.action = @selector(clickAction:);
    clickTracker.doubleAction = @selector(doubleClickAction:);
    clickTracker.view = self;
    [_inputTrackers addObject:clickTracker];
    [clickTracker release];
    
    DragTracker *dragTracker = [DragTracker new];
    dragTracker.beginTrackingAction = @selector(beginMouseDrag:);
    dragTracker.view = self;
    [_inputTrackers addObject:dragTracker];
    [dragTracker release];
    
    DualTouchTracker *touchTracker = [DualTouchTracker new];
    touchTracker.beginTrackingAction = @selector(dualTouchesBegan:);
    touchTracker.view = self;
    [_inputTrackers addObject:touchTracker];
    [touchTracker release];
}


#pragma mark CALayerDelegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGContextSetFillColorWithColor(context, layer.backgroundColor);
    CGContextFillRect(context, layer.bounds);
    
    if ([self.selectionIndexes count]) {
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        
        for (CALayer *layer in [[self.layer sublayers] objectsAtIndexes:self.selectionIndexes]) {
            CGRect frame = layer.frame;
            CGRect handleFrames[8] = {0.0};
            
            resizeRectsForFrame(handleFrames, frame);
            [self drawDragHandleFrames:handleFrames inContext:context];
        }
    }
    
    if (_editingSlide) {
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        
        CGRect frame = _editingSlide.photoFrame;
        CGRect handleFrames[8] = {0.0};
        
        resizeRectsForFrame(handleFrames, frame);
        [self drawDragHandleFrames:handleFrames inContext:context];
    }
}

- (void)drawDragHandleFrames:(CGRect *)handleFrames inContext:(CGContextRef)context {
    CGContextFillRects(context, handleFrames, 8);
    CGContextStrokeRectWithWidth(context, handleFrames[0], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[1], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[2], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[3], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[4], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[5], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[6], 1.0);
    CGContextStrokeRectWithWidth(context, handleFrames[7], 1.0);
}


#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationGeneric;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *draggingPasteboard = [sender draggingPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSURL class]]; 
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSImage imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
    NSArray *items = [draggingPasteboard readObjectsForClasses:classArray options:options];
    NSPoint slideOrigin = [self convertPointFromBase:[sender draggingLocation]];
    
    
    for (NSURL *fileURL in items) {
        id newObject = [_newObjectCreator newObject];
        NSImage *image = [[[NSImage alloc] initWithContentsOfURL:fileURL] autorelease];
        NSSize maxSize = self.bounds.size;
        maxSize.width /= 2.0;
        maxSize.height /= 2.0;
        NSRect slideFrame = {NSZeroPoint, [image size]};
        
        // Reduce the size of the slide until it fits on no more than a quarter of the view.
        while(slideFrame.size.width > maxSize.width || slideFrame.size.height > maxSize.height) {
            slideFrame.size.width /= 2.0;
            slideFrame.size.height /= 2.0;
        }
        
        // Start the photo filling the entire slide.
        NSRect photoFrame = slideFrame;
        slideFrame.origin = slideOrigin;
        slideFrame.origin.y -= slideFrame.size.height / 2.0;
        
        [newObject setValue:[NSValue valueWithRect:slideFrame] forKey:kLTViewSlidePropertyFrame];
        [newObject setValue:[NSValue valueWithRect:photoFrame] forKey:kLTViewSlidePropertyPhotoFrame];
        [newObject setValue:[NSData dataWithContentsOfURL:fileURL] forKey:kLTViewSlidePropertyPhoto];
        
        [_newObjectCreator insertObject:newObject atArrangedObjectIndex:[_slides count]];
        
        // Shift the next image over a bit.
        slideOrigin.x += slideFrame.size.width + 5;
    }
    
    return YES;
}


#pragma mark NSKeyValueBindingCreation

- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    if ([binding isEqualToString:kLTViewSlides]) {
        _newObjectCreator = [observable retain];
        _keyPath = [keyPath retain];
        [_newObjectCreator addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:kLTOberserverContext];
        return;
    }
    
    [super bind:binding toObject:observable withKeyPath:keyPath options:options];
}

- (void)unbind:(NSString *)binding {
    if ([binding isEqualToString:kLTViewSlides]) {
        [_newObjectCreator removeObserver:self forKeyPath:_keyPath];
        [_newObjectCreator release];
        [_keyPath release];
    }
    
    [super unbind:binding];
}


#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualTo:_keyPath] && context == kLTOberserverContext) {
        switch([[change objectForKey:NSKeyValueChangeKindKey] integerValue]) {
            case NSKeyValueChangeSetting:
            {
                NSMutableArray *slides = [self mutableArrayValueForKey:kLTViewSlides];
                [slides removeAllObjects];
                [slides addObjectsFromArray:[object valueForKey:_keyPath]];
                [_overlayLayer setNeedsDisplay];
            }
                break;
            
            default:
                break;

        }
        return;
    }
      
    if (context == kLTOberserverContext) {
        LTMaskLayer *layer = nil;
        for (LTMaskLayer *subLayer in [self.layer sublayers]) {
            if (subLayer.source == object) {
                layer = subLayer;
                break;
            }
        }
        
        if ([keyPath isEqualTo:kLTViewSlidePropertyCornerRadius]) {
            layer.cornerRadius = [[object valueForKeyPath:keyPath] floatValue];
            return;
        }
        
        if ([keyPath isEqualTo:kLTViewSlidePropertyFrameThickness]) {
            layer.borderWidth = [[object valueForKeyPath:keyPath] floatValue];
            return;
        }
        
        if ([keyPath isEqualTo:kLTViewSlidePropertyFrame]) {
            layer.frame = NSRectToCGRect([[object valueForKeyPath:keyPath] rectValue]);
            [_overlayLayer setNeedsDisplay]; //update drag handles
            return;
        }
        
        if ([keyPath isEqualTo:kLTViewSlidePropertyPhotoFrame]) {
            layer.photoLayer.frame = NSRectToCGRect([[object valueForKeyPath:keyPath] rectValue]);
            [_overlayLayer setNeedsDisplay]; //update drag handles
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark NSResponder

// Route all events to the input tracker collection. See InputTracker.h.

- (void)mouseDown:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)mouseUp:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    [_inputTrackers makeObjectsPerformSelector:_cmd withObject:event];
}


#pragma mark API

static BOOL gOldAnimationIsDisabled = FALSE;
static double gOldAnimationDuration = 0.25;

@synthesize selectionIndexes = _selectionIndexes;

// These functions set up the Core Animation variables that we want and restore whatever was there
+ (void)setupCAAnimationStack {
	gOldAnimationIsDisabled = [CATransaction animationDuration];
	gOldAnimationDuration = [CATransaction disableActions];
	
	[CATransaction setValue:[NSNumber numberWithBool:FALSE] forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
}

+ (void)restoreCAAnimationStack {
	[CATransaction setValue:[NSNumber numberWithBool:gOldAnimationIsDisabled] forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:gOldAnimationDuration] forKey:kCATransactionAnimationDuration];	
}

- (NSInteger)countOfSlides {
    return [_slides count];
}

- (id)objectInSlidesAtIndex:(NSInteger)index {
    return [_slides objectAtIndex:index];
}

- (NSArray *)slidesAtIndexes:(NSIndexSet *)indexes {
    return [_slides objectsAtIndexes:indexes];
}

- (void)insertSlides:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    NSUInteger layerIndex = [indexes firstIndex];
    
    for (id slide in array) {
        NSImage *image = [[NSImage alloc] initWithData:[slide valueForKey:kLTViewSlidePropertyPhoto]];
    
        CGRect frame = NSRectToCGRect([[slide valueForKey:kLTViewSlidePropertyFrame] rectValue]);
        LTMaskLayer *slideLayer = [LTMaskLayer layer];
        slideLayer.photo = image;
        slideLayer.frame = frame;
        slideLayer.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
        slideLayer.cornerRadius = [[slide valueForKey:kLTViewSlidePropertyCornerRadius] floatValue];
        slideLayer.borderWidth = [[slide valueForKey:kLTViewSlidePropertyFrameThickness] floatValue];
        slideLayer.photoLayer.frame = NSRectToCGRect([[slide valueForKey:kLTViewSlidePropertyPhotoFrame] rectValue]);
        slideLayer.source = slide;
        
        // Finally insert the layer at the same index of the data source. Note: The data source is always one less than the number of sublayers because we have the overlay layer. This means that we always insert slide layers under the overlay layer (just like we want).
        [self.layer insertSublayer:slideLayer atIndex:layerIndex];
        layerIndex = [indexes indexGreaterThanIndex:layerIndex];
        
        // Add observers for the properties that LTView displays. Why not have the LTMaskLayer doing the observing? Mainly because, LTView needs to know about frame changes to update the resizeRects. So we do them all in the same place to keeps things simpler for the sample project.
        [slide addObserver:self forKeyPath:kLTViewSlidePropertyFrame options:0 context:kLTOberserverContext];
        [slide addObserver:self forKeyPath:kLTViewSlidePropertyPhotoFrame options:0 context:kLTOberserverContext];
        [slide addObserver:self forKeyPath:kLTViewSlidePropertyCornerRadius options:0 context:kLTOberserverContext];
        [slide addObserver:self forKeyPath:kLTViewSlidePropertyFrameThickness options:0 context:kLTOberserverContext];
        
        [image release];
    }
    
    [_slides insertObjects:array atIndexes:indexes];
}

- (void)removeSlidesAtIndexes:(NSIndexSet *)indexes {
    // Stop observing all the properties we started observing when we inserted the layer above.
    for (id slide in [_slides objectsAtIndexes:indexes]) {
        [slide removeObserver:self forKeyPath:kLTViewSlidePropertyFrame];
        [slide removeObserver:self forKeyPath:kLTViewSlidePropertyPhotoFrame];
        [slide removeObserver:self forKeyPath:kLTViewSlidePropertyCornerRadius];
        [slide removeObserver:self forKeyPath:kLTViewSlidePropertyFrameThickness];
    }
    
    // Finally remove all the layers at the same indexes of the data source. Note: The data source is always one less than the number of sublayers because we have the overlay layer. This means that we always remove slide layers under the overlay layer and never the overlay layer itself.
    [_slides removeObjectsAtIndexes:indexes];
    
    for (CALayer *layer in [[self.layer sublayers] objectsAtIndexes:indexes]) {
        [layer removeFromSuperlayer];
    }
}

// We commit the changes to the LTMaskLayer at the end of tracking so that we only hit the data source a minimal amount. Also, this way, Undo will undo the whole tracking action instead of just one small step of it.
- (void)commitFrameChangeOfLayer:(LTMaskLayer *)layer {
    CGRect photoFrame;
    
    // This methods is called when either the mask layer's frame has changed, or when the photo layer's frame has changed. Note, changing the mask layer's frame implies a photo layer frame change, but not the other way around.
    if (layer.superlayer == self.layer) {
        photoFrame = layer.photoLayer.frame;
        [layer.source setValue:[NSValue valueWithRect:NSRectFromCGRect(layer.frame)] forKey:kLTViewSlidePropertyFrame];
    } else {
        layer = (LTMaskLayer *)layer.superlayer;
        photoFrame = layer.photoLayer.frame;
    }
    
    [layer.source setValue:[NSValue valueWithRect:NSRectFromCGRect(photoFrame)] forKey:kLTViewSlidePropertyPhotoFrame];
    
    [_overlayLayer setNeedsDisplay];
}


#pragma mark Input Tracker Support and Actions

- (void)disableTrackersExcluding:(InputTracker*)excluded {
    for (InputTracker *tracker in _inputTrackers) {
        if (tracker != excluded) tracker.isEnabled = NO;
    }
}

- (void)enableTrackers {
    for (InputTracker *tracker in _inputTrackers) {
        tracker.isEnabled = YES;
    }
}

// The user clicked and is not in the process of adjusting the photo masking. Modify the selection accordingly. A different set of tracker actions will manage dragging.
- (void)clickAction:(ClickTracker*)tracker {
    CGPoint trackerLocation = NSPointToCGPoint([tracker location]);
    CGPoint layerLocation = [self.layer convertPoint:trackerLocation fromLayer:nil];
    
    // Check for clicks in any existing resize handles first.
    for (CALayer *layer in [[self.layer sublayers] objectsAtIndexes:self.selectionIndexes]) {
        CGRect resizeRects[8];
        resizeRectsForFrame(resizeRects, layer.frame);
        NSInteger resizeIndex = indexOfResizeRectForPoint(resizeRects, layerLocation);
        
        if (resizeIndex >= 0) return; // in resize handle, don't change selection
    }
    
    // Use layer hit testing to find the targeted layer, if any.
    CALayer *layer = [self.layer hitTest:trackerLocation];
    layer = (layer == self.layer) ? nil : layer;
    
    if (layer) {
        NSUInteger layerIndex = [[self.layer sublayers] indexOfObject:layer];
        if (layerIndex != NSNotFound) {
            BOOL isCommandDown = (([tracker modifiers] & NSCommandKeyMask) != 0);
            if (isCommandDown) {
                NSMutableIndexSet *newIndexSet = [self.selectionIndexes mutableCopy];
                
                if ([newIndexSet containsIndex:layerIndex]) {
                    [newIndexSet removeIndex:layerIndex];
                } else {
                    [newIndexSet addIndex:layerIndex];
                    self.selectionIndexes = [[NSIndexSet alloc] initWithIndexSet:newIndexSet];
                }
                
                [newIndexSet release];
            } else {
                if (![self.selectionIndexes containsIndex:layerIndex]) {
                    self.selectionIndexes = [NSIndexSet indexSetWithIndex:layerIndex];
                }
            }
        }
    } else {
        self.selectionIndexes = [NSIndexSet indexSet];
    }
    
    // Redraw resize handles for new selection.
    [_overlayLayer setNeedsDisplay];
}

// The user clicked while adjusting the photo masking of a slide. If the click is outside the photo's unmasked frame (and not in a resize handle either), then stop adjusting the photo masking.
- (void)editingClickAction:(ClickTracker*)tracker {
    CGPoint layerLocation = [self.layer convertPoint:NSPointToCGPoint([tracker location]) fromLayer:nil];
    if (!LTPointInRect(layerLocation, _editingSlide.photoFrame)){
        CGRect resizeRects[8];
        resizeRectsForFrame(resizeRects, _editingSlide.photoFrame);
        NSInteger resizeIndex = indexOfResizeRectForPoint(resizeRects, layerLocation);
        if (resizeIndex < 0) {
            _editingSlide.masksToBounds = YES;
            _editingSlide = nil;
            tracker.action = @selector(clickAction:);
            [self clickAction:tracker];
        }
    }
}

// The user double cliked. If adjusting a photo mask, then stop. Otherwise, begin adjusting a photo mask if the double click occured on a slide.
- (void)doubleClickAction:(ClickTracker*)tracker {
    if (_editingSlide) {
        _editingSlide.masksToBounds = YES;
        _editingSlide = nil;
        tracker.action = @selector(clickAction:);
        [self clickAction:tracker];
        [_overlayLayer setNeedsDisplay];
        return;
    } else {
        CGPoint trackerLocation = NSPointToCGPoint([tracker location]);
        
        CALayer *layer = [self.layer hitTest:trackerLocation];
        layer = (layer == self.layer) ? nil : layer;
        
        if (layer) {
            // We don't allow selections during photo mask adjustments.
            self.selectionIndexes = [NSIndexSet indexSet];
            
            // Begin photo mask adjustment mode.
            _editingSlide = (LTMaskLayer *)layer;
            layer.masksToBounds = NO;
            
            // Change the click action because selection modification is not valid in this mode.
            tracker.action = @selector(editingClickAction:);
        }
    }
    
    // Update the resize handle drawing.
    [_overlayLayer setNeedsDisplay];
}


// The user has exceeded the drag threshold, and we are not currently tracking touches. Start drag tracking. 
- (void)beginMouseDrag:(DragTracker*)tracker {
    CGPoint layerLocation = [self.layer convertPoint:NSPointToCGPoint(tracker.initialPoint) fromLayer:nil];
    
    if (_editingSlide) {
        // The user is adjusting a photo mask
        CALayer *layer = _editingSlide.photoLayer;
        
        // Check if the use is resizing via a drag handle
        CGRect resizeRects[8];
        resizeRectsForFrame(resizeRects, _editingSlide.photoFrame);
        NSInteger resizeIndex = indexOfResizeRectForPoint(resizeRects, layerLocation);
        
        if (resizeIndex >= 0) {
            // Drag handle resize
            tracker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    layer, kLayerKey,
                                    [NSValue valueWithRect:NSRectFromCGRect(layer.frame)], kInitialFrameKey,
                                    [NSNumber numberWithInteger:resizeIndex], kResizeIndexKey,
                                    nil];
            
            // Notice how we manage which type of tracking we are performing by simply changing the tracking action methods.
            tracker.updateTrackingAction = @selector(resizeSlide:);
            tracker.endTrackingAction = @selector(resizeSlideEnd:);
            
            [self disableTrackersExcluding:tracker]; // No other tracking allowed while dragging.
        } else {
            // The user is moving the photo inside the mask. Note: we don't need to confrim this by comparing the mouse location against the photo's frame, because the dragging threshold means the click action will have already fired, making the assessment for us and updated the _editingSlide value.
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    layer, kLayerKey,
                                    [NSValue valueWithPoint:NSPointFromCGPoint(layer.position)], kInitialPositionKey,
                                    nil];
            tracker.userInfo = [NSArray arrayWithObject:userInfo];
            
            // Notice how we manage which type of tracking we are performing by simply changing the tracking action methods.
            tracker.updateTrackingAction = @selector(dragSlides:);
            tracker.endTrackingAction = @selector(dragSlidesEnd:);
            
            [self disableTrackersExcluding:tracker]; // No other tracking allowed while dragging.
        }
        return;
    }
    
    // The user is not modifying a photo mask. Determine if the user is resizing via drag handle, moving the selection, or dragging in empty space.
    // Loop through every layer in the selection.
    for (CALayer *layer in [[self.layer sublayers] objectsAtIndexes:self.selectionIndexes]) {
        CGRect resizeRects[8];
        resizeRectsForFrame(resizeRects, layer.frame);
        NSInteger resizeIndex = indexOfResizeRectForPoint(resizeRects, layerLocation);
        
        // Check the resize handles.
        if (resizeIndex >= 0) {
            // Resize only this layer.
            tracker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                layer, kLayerKey,
                                [NSValue valueWithRect:NSRectFromCGRect(layer.frame)], kInitialFrameKey,
                                [NSNumber numberWithInteger:resizeIndex], kResizeIndexKey,
                                nil];
            
            // Notice how we manage which type of tracking we are performing by simply changing the tracking action methods.
            tracker.updateTrackingAction = @selector(resizeSlide:);
            tracker.endTrackingAction = @selector(resizeSlideEnd:);
            
            [self disableTrackersExcluding:tracker]; // No other tracking allowed while dragging.
            return;
        }
        
        // Check if the cursor is within this slide. If so, move the entire selection.
        if ([layer containsPoint:[layer convertPoint:layerLocation fromLayer:self.layer]]){
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.selectionIndexes count]];
            for (CALayer *layer in [[self.layer sublayers] objectsAtIndexes:self.selectionIndexes]) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                        layer, kLayerKey,
                                        [NSValue valueWithPoint:NSPointFromCGPoint(layer.position)], kInitialPositionKey,
                                        nil];
                [array addObject:userInfo];
            }
            tracker.userInfo = array;
            
            // Notice how we manage which type of tracking we are performing by simply changing the tracking action methods.
            tracker.updateTrackingAction = @selector(dragSlides:);
            tracker.endTrackingAction = @selector(dragSlidesEnd:);
            
            [self disableTrackersExcluding:tracker]; // No other tracking allowed while dragging.
            return;
        }
    }
    
    // If we get here, then the user has dragged in empty space. Notice how we manage which type of tracking we are performing by simply changing the tracking action methods. In this case, the actions are left as nil, so nothing will occur. 
    
    // A rubber band selection is left as an exercise to the reader.
}

// Mouse dragging of either the selection or of an LTMaskLayer's photo sublayer. Though, this method only looks at an array of CALayers in the tracker userInfo, and does not need to distinguish between the two.
- (void)dragSlides:(DragTracker*)tracker {
    NSPoint delta = tracker.delta;
    NSArray *array = tracker.userInfo;
    
    // Turn off animation so that each layer is moved immediately.
    [LTView setupCAAnimationStack];
    for (NSDictionary *userInfo in array){
        CALayer *layer = [userInfo objectForKey:kLayerKey];
        NSPoint initialPosition = [[userInfo objectForKey:kInitialPositionKey] pointValue];
        if (layer) {
            initialPosition.x += delta.x;
            initialPosition.y += delta.y;
            layer.position = NSPointToCGPoint(initialPosition);
        }
    }
    [LTView restoreCAAnimationStack];
    
    // Update drag handles
    [_overlayLayer setNeedsDisplay];
}

// Mouse dragging of either the selection or of an LTMaskLayer's photo sublayer has ended. Though, this method only looks at an array of CALayers in the tracker userInfo, and does not need to distinguish between the two.
- (void)dragSlidesEnd:(DragTracker*)tracker {    
    [self dragSlides:tracker];
    
    // Commit the new CALayer frame values to the data source
    for (NSDictionary *userInfo in tracker.userInfo){
        [self commitFrameChangeOfLayer:[userInfo objectForKey:kLayerKey]];
    }
    
    // reset the tracker back to nil values
    tracker.userInfo = nil;
    tracker.updateTrackingAction = nil;
    tracker.endTrackingAction = nil;
    
    // Tracking over, re-enable all trackers.
    [self enableTrackers];
}

// Mouse resizing of a layer via a drag handle. This may be an LTMaskLayer or its photo sublayer. Though, this method only looks at the CALayer in the tracker userInfo, and does not need to distinguish between the two.
- (void)resizeSlide:(DragTracker*)tracker {
    NSPoint delta = tracker.delta;
    NSDictionary *userInfo = tracker.userInfo;
    CALayer *layer = [userInfo objectForKey:kLayerKey];
    
    CGRect frame = NSRectToCGRect([[userInfo objectForKey:kInitialFrameKey] rectValue]);
    switch ([[userInfo objectForKey:kResizeIndexKey] integerValue]) {
        case 0: //top left
            frame.origin.x += delta.x;
            frame.size.width -= delta.x;
            frame.size.height += delta.y;
            break;
            
        case 1: //top middle
            frame.size.height += delta.y;
            break;
            
        case 2: //top right
            frame.size.width += delta.x;
            frame.size.height += delta.y;
            break;
            
        case 3: //right middle
            frame.size.width += delta.x;
            break;
            
        case 4: //bottom right
            frame.origin.y += delta.y;
            frame.size.width += delta.x;
            frame.size.height -= delta.y;
            break;
            
        case 5: //bottom middle
            frame.origin.y += delta.y;
            frame.size.height -= delta.y;
            break;
            
        case 6: //bottom left
            frame.origin.x += delta.x;
            frame.origin.y += delta.y;
            frame.size.width -= delta.x;
            frame.size.height -= delta.y;
            break;
            
        case 7: //left middle
            frame.origin.x += delta.x;
            frame.size.width -= delta.x;
            break;
            
        default:
            break;
    }

    // Turn off animation so that each layer is moved immeditaly.
    [LTView setupCAAnimationStack];
    layer.frame = frame;
    [LTView restoreCAAnimationStack];
    
    // Update resize handles
    [_overlayLayer setNeedsDisplay];
}

- (void)resizeSlideEnd:(DragTracker*)tracker {    
    [self resizeSlide:tracker];
    
    // Commit the new CALayer frame values to the data source
    NSDictionary *userInfo = tracker.userInfo;
    [self commitFrameChangeOfLayer:[userInfo objectForKey:kLayerKey]];
    
    // Reset the tracker back to nil values
    tracker.userInfo = nil;
    tracker.updateTrackingAction = nil;
    tracker.endTrackingAction = nil;
    
    // Tracking over, re-enable all trackers.
    [self enableTrackers];
}


// The user has two fingers on the trackpad, has exceeded the movement threshold, and we are not currently tracking the mouse. Start dual-touch tracking.
- (void)dualTouchesBegan:(DualTouchTracker*)tracker {
    CALayer *layer = nil;
    CGPoint trackerLocation = NSPointToCGPoint(tracker.initialPoint);
    
    if (_editingSlide) {
        // The user is adjusting a photo mask, use the photo sublayer if the cursor is over the unmasked photo
        CGPoint layerLocation = [self.layer convertPoint:trackerLocation fromLayer:nil];
        if (LTPointInRect(layerLocation, _editingSlide.photoFrame)) {
            layer = _editingSlide.photoLayer;
        }
    } else {
        // The user is not adjusting a photo mask. Determine which LTMaskLayer is under the cursor, if any.
        layer = [self.layer hitTest:trackerLocation];
        layer = (layer == self.layer) ? nil : layer;
    }

    if (layer) {
        tracker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    layer, kLayerKey,
                                    [NSValue valueWithRect:NSRectFromCGRect(layer.frame)], kInitialFrameKey,
                                    nil];
                                    
        // Notice how we manage which type of tracking we are performing by simply changing the tracking action methods.
        tracker.updateTrackingAction = @selector(dualTouchesMoved:);
        tracker.endTrackingAction = @selector(dualTouchesEnded:);
        
        [self disableTrackersExcluding:tracker]; // No other tracking allowed while dragging.
        
        // Hide the cursor since the user is not moving the cursor.
        [NSCursor hide];
    }/* else {
        The cursor is not over an appropriate layer. Notice how we manage which type of tracking we are performing by simply changing the tracking action methods. In this case, the actions are left as nil, so nothing will occur.  
    } */
}

- (void)dualTouchesMoved:(DualTouchTracker*)tracker {
    NSDictionary *userInfo = tracker.userInfo;
    CGPoint deltaOrigin = NSPointToCGPoint(tracker.deltaOrigin);
    CGSize deltaSize = NSSizeToCGSize(tracker.deltaSize);
    
    CGRect originalFrame = NSRectToCGRect([[userInfo objectForKey:kInitialFrameKey] rectValue]);
    CGRect newFrame = originalFrame;
    newFrame.origin.x += deltaOrigin.x;
    newFrame.origin.y += deltaOrigin.y;
    newFrame.size.width += deltaSize.width;
    newFrame.size.height += deltaSize.height;
    
    // Update the Layer's frame
    CALayer *layer = [userInfo objectForKey:kLayerKey];
    [LTView setupCAAnimationStack];
    layer.frame = newFrame;
    [LTView restoreCAAnimationStack];
    
    // Update selection handles if needed
    [_overlayLayer setNeedsDisplay];
    
    // Warp the cursor so that new touches are targeted to this Slide.
    NSPoint trackerLocation = NSPointFromCGPoint([layer.superlayer convertPoint:NSPointToCGPoint(tracker.initialPoint) fromLayer:nil]);
    
    // Calculate the original cursor offest.
    deltaOrigin.x = trackerLocation.x - CGRectGetMinX(originalFrame);
    deltaOrigin.y = trackerLocation.y - CGRectGetMinY(originalFrame);
    
    // Determine new cursor offest
    deltaOrigin.x = (deltaOrigin.x/CGRectGetWidth(originalFrame)) * CGRectGetWidth(newFrame);
    deltaOrigin.y = (deltaOrigin.y/CGRectGetHeight(originalFrame)) * CGRectGetHeight(newFrame);
    
    // Use new cursor offset to warp cursor in screen space
    CGPoint cgCursorLocation = newFrame.origin;
    cgCursorLocation.x += deltaOrigin.x;
    cgCursorLocation.y += deltaOrigin.y;
    cgCursorLocation = [layer.superlayer convertPoint:cgCursorLocation toLayer:nil];
    
    NSPoint nsCursorLocation = NSPointFromCGPoint(cgCursorLocation);
    nsCursorLocation = [self convertPointToBase:nsCursorLocation];
    nsCursorLocation = [self.window convertBaseToScreen:nsCursorLocation];
    nsCursorLocation.y = [[NSScreen mainScreen] frame].size.height - nsCursorLocation.y;
    CGWarpMouseCursorPosition(NSPointToCGPoint(nsCursorLocation));
}

- (void)dualTouchesEnded:(DualTouchTracker*)tracker {
    NSDictionary *userInfo = tracker.userInfo;
    [self commitFrameChangeOfLayer:[userInfo objectForKey:kLayerKey]];
        
    tracker.updateTrackingAction = nil;
    tracker.endTrackingAction = nil;
    [self enableTrackers];
    
    // We explicitly hide the cursor, so unhide it here.
    [NSCursor unhide];
    [NSCursor setHiddenUntilMouseMoves:YES];
}

@end

// See LTView.h for definitions of these properties
NSString *kLTViewSlides = @"slides";
NSString *kLTViewSelectionIndexes = @"selectionIndexes";
NSString *kLTViewSlidePropertyFrame = @"frame";
NSString *kLTViewSlidePropertyPhotoFrame = @"photoFrame";
NSString *kLTViewSlidePropertyPhoto = @"photo";
NSString *kLTViewSlidePropertyCornerRadius = @"cornerRadius";
NSString *kLTViewSlidePropertyFrameThickness = @"frameThickness";
