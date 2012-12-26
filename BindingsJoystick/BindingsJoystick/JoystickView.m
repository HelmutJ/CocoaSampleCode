
/*
     File: JoystickView.m
 Abstract: View that represents a joystick allowing angle and offset to be manipulated graphically.
 
  Version: 2.0
 
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

#import "JoystickView.h"


@interface JoystickView ()

-(void)updateForMouseEvent:(NSEvent *)event;

- (void)keyDown:(NSEvent *)event;

- (void)updateXOffset:(float) xOffset yOffset:(float) yOffset withEvent:(NSEvent *)event;

- (NSString *)angleValueTransformerName;

- (BOOL)allowsMultipleSelectionForAngle;
- (BOOL)allowsMultipleSelectionForOffset;

- (id)observedObjectForAngle;
- (NSString *)observedKeyPathForAngle;

- (id)observedObjectForOffset;
- (NSString *)observedKeyPathForOffset;

@end



@implementation JoystickView
{
    BOOL badSelectionForAngle,
    badSelectionForOffset,
    multipleSelectionForAngle,
    multipleSelectionForOffset;
    
    NSMutableDictionary *bindingInfo;
    
    BOOL mouseDown;
}

static char AngleObservationContext;
static char OffsetObservationContext;


#define ANGLE_BINDING_NAME @"angle"
#define OFFSET_BINDING_NAME @"offset"


- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        _maxOffset = 15.0;
        _offset = 0.0;
        _angle = 28.0;
        multipleSelectionForAngle = NO;
        multipleSelectionForOffset = NO;
        
        bindingInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)bind:(NSString *)bindingName toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    
    if ([bindingName isEqualToString:ANGLE_BINDING_NAME])
    {
        if ([bindingInfo objectForKey:ANGLE_BINDING_NAME] != nil)
        {
            [self unbind:ANGLE_BINDING_NAME];    
        }
        /*
         Observe the controller for changes -- note, pass binding identifier as the context, so we get that back in observeValueForKeyPath:... -- that way we can determine what needs to be updated.
         */
        [observableController addObserver:self forKeyPath:keyPath options:0 context:&AngleObservationContext];
        
        NSDictionary *bindingsData = @{ NSObservedObjectKey:observableController, NSObservedKeyPathKey:[keyPath copy], NSOptionsKey:[options copy] };
        [bindingInfo setObject:bindingsData forKey:ANGLE_BINDING_NAME];
    }
    else
    {
        if ([bindingName isEqualToString:OFFSET_BINDING_NAME])
        {
            if ([bindingInfo objectForKey:OFFSET_BINDING_NAME] != nil)
            {
                [self unbind:OFFSET_BINDING_NAME];    
            }
            [observableController addObserver:self forKeyPath:keyPath options:0 context:&OffsetObservationContext];
            
            NSDictionary *bindingsData = @{NSObservedObjectKey:observableController, NSObservedKeyPathKey:[keyPath copy], NSOptionsKey:[options copy] };
            [bindingInfo setObject:bindingsData forKey:OFFSET_BINDING_NAME];
        }
        else
        {
            [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
        }
    }
    [self setNeedsDisplay:YES];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    /*
     We passed a context when we added ourselves as an observer -- use that to decide what to update... should ask the dictionary for the value...
     */
    if (context == &AngleObservationContext)
    {
        // Angle changed
        /*
         If we got a NSNoSelectionMarker or NSNotApplicableMarker, or if we got a NSMultipleValuesMarker and we don't allow multiple selections then note we have a bad angle.
         */
        id newAngle = [object valueForKeyPath:keyPath];
        
        if ((newAngle == NSNoSelectionMarker) || (newAngle == NSNotApplicableMarker)
            || ((newAngle == NSMultipleValuesMarker) && ![self allowsMultipleSelectionForAngle]))
        {
            badSelectionForAngle = YES;
        }
        else
        {
            /*
             Note we have a good selection.
             If we got a NSMultipleValuesMarker, note it but don't update value.
             */
            badSelectionForAngle = NO;
            if (newAngle == NSMultipleValuesMarker)
            {
                multipleSelectionForAngle = YES;
            }
            else
            {
                multipleSelectionForAngle = NO;
                
                NSString *angleValueTransformerName = [self angleValueTransformerName];
                
                if (angleValueTransformerName != nil)
                {
                    NSValueTransformer *valueTransformer =
                    [NSValueTransformer valueTransformerForName:angleValueTransformerName];
                    newAngle = [valueTransformer transformedValue:newAngle]; 
                }    
                [self setValue:newAngle forKey:ANGLE_BINDING_NAME];
            }
        }
    }
    if (context == &OffsetObservationContext)
    {
        // Offset changed.
        /*
         If we got a NSNoSelectionMarker or NSNotApplicableMarker, or if we got a NSMultipleValuesMarker and we don't allow multiple selections then note we have a bad selection.
         */
        id newOffset = [object valueForKeyPath:keyPath];
        
        if ((newOffset == NSNoSelectionMarker) || (newOffset == NSNotApplicableMarker)
            || ((newOffset == NSMultipleValuesMarker) && ![self allowsMultipleSelectionForOffset]))
        {
            badSelectionForOffset = YES;
        }
        else
        {
            // Note we have a good selection
            /*
             If we got a NSMultipleValuesMarker, note it but don't update value.
             */
            badSelectionForOffset = NO;
            if (newOffset == NSMultipleValuesMarker)
            {
                multipleSelectionForOffset = YES;
            }
            else
            {
                [self setValue:newOffset forKey:OFFSET_BINDING_NAME];
                multipleSelectionForOffset = NO;
            }
        }
    }
    [self setNeedsDisplay:YES];
}


- (void)unbind:bindingName
{
    if ([bindingName isEqualToString:ANGLE_BINDING_NAME])
    {
        id observedObjectForAngle = [self observedObjectForAngle];
        NSString *observedKeyPathForAngle = [self observedKeyPathForAngle];
        
        [observedObjectForAngle removeObserver:self forKeyPath:observedKeyPathForAngle];
        [bindingInfo removeObjectForKey:ANGLE_BINDING_NAME];
    }
    else
    {
        if ([bindingName isEqualToString:OFFSET_BINDING_NAME])
        {
            id observedObjectForOffset = [self observedObjectForOffset];
            NSString *observedKeyPathForOffset = [self observedKeyPathForOffset];
            
            [observedObjectForOffset removeObserver:self forKeyPath:observedKeyPathForOffset];
            [bindingInfo removeObjectForKey:OFFSET_BINDING_NAME];
        }
        else
        {
            [super unbind:bindingName];    
        }
    }
    [self setNeedsDisplay:YES];
}


- (NSDictionary *)infoForBinding:(NSString *)bindingName
{
    NSDictionary *info = bindingInfo[bindingName];
    if (info == nil)
    {
        info = [super infoForBinding:bindingName];
    }
    return info;
}


#pragma mark ---- accessing data from infoForBinding ----
/*
 Convenience methods to retrieve data from the infoForBinding dictionary
 */

- (id)observedObjectForAngle
{
    return [self infoForBinding:ANGLE_BINDING_NAME][NSObservedObjectKey];
}

- (NSString *)observedKeyPathForAngle
{
    return [self infoForBinding:ANGLE_BINDING_NAME][NSObservedKeyPathKey];
}


- (id)observedObjectForOffset
{
    return [self infoForBinding:OFFSET_BINDING_NAME][NSObservedObjectKey];
}

- (NSString *)observedKeyPathForOffset
{
    return [[self infoForBinding:OFFSET_BINDING_NAME] objectForKey:NSObservedKeyPathKey];
}


- (NSString *)angleValueTransformerName
{
    NSDictionary *infoDictionary = [self infoForBinding:ANGLE_BINDING_NAME];
    NSDictionary *optionsDictionary = infoDictionary[NSOptionsKey];
    id name = optionsDictionary[NSValueTransformerNameBindingOption];
    if ((name == [NSNull null]) || (name == nil))
    {
        return nil;
    }
    return (NSString *)name;
}


- (BOOL)allowsMultipleSelectionForAngle
{
    NSDictionary *options = [self infoForBinding:ANGLE_BINDING_NAME][NSOptionsKey];
    NSNumber *allows = options[NSAllowsEditingMultipleValuesSelectionBindingOption];
    return [allows boolValue];
}


- (BOOL)allowsMultipleSelectionForOffset
{
    NSDictionary *options = [self infoForBinding:OFFSET_BINDING_NAME][NSOptionsKey];
    NSNumber *allows = options[NSAllowsEditingMultipleValuesSelectionBindingOption];
    return [allows boolValue];
}



#pragma mark ---- responding to events ----

-(void)updateForMouseEvent:(NSEvent *)event
{
    // Update based on event location and selection state.
    
    if (badSelectionForAngle || badSelectionForOffset)
    {
        // Don't do anything.
        return;
    }
    
    // Find out where the event is, offset from the view center.
    
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];    
    
    NSRect myBounds = [self bounds];    
    float xOffset = (p.x - (myBounds.size.width/2));
    float yOffset = (p.y - (myBounds.size.height/2));
    [self updateXOffset:xOffset yOffset:yOffset withEvent:event];
}



- (void)keyDown:(NSEvent *)event 
{ 
    float angleRadians = self.angle * (3.1415927/180.0);
    float x = sin(angleRadians) * self.offset;
    float y = cos(angleRadians) * self.offset;
                
    BOOL handled = NO;
    
    NSString  *characters; 
    // Get the pressed key. 
    characters = [event charactersIgnoringModifiers]; 
    // Is the "0" key pressed? 
    if ([characters isEqualToString:@"0"])
    { 
        x = 0;
        y = 0;
        handled = YES;
    }
    else
    {
        unichar key = [characters characterAtIndex:0];
        switch (key)
        {
            
        case NSUpArrowFunctionKey :
            y += 1;
            handled = YES;
            break;
            
        case NSDownArrowFunctionKey :
            y -= 1;
            handled = YES;
            break;
            
        case NSLeftArrowFunctionKey :
            x -= 1;
            handled = YES;
            break;
            
        case NSRightArrowFunctionKey :
            x += 1;
            handled = YES;
            break;
        }
    }
    
    if (handled)
    {
        [self updateXOffset:x yOffset:y withEvent:(NSEvent *)event];
    }
    else
    {
        [super keyDown:event];
    }
} 


- (void)updateXOffset:(float) xOffset yOffset:(float) yOffset withEvent:(NSEvent *)event
{
    float newOffset = hypot(xOffset, yOffset);
    
    if (newOffset > self.maxOffset)
    {
        newOffset = self.maxOffset;
    }
    
    /*
     If we have a multiple selection for offset and Shift key is pressed then don't update the offset.
     This allows the offset to remain constant while the angle is changed.
     */
    if (!(multipleSelectionForOffset && ([event modifierFlags] & NSShiftKeyMask)))
    {
        [self setOffset:newOffset];
        
        // Update the observed controller, if it is set.
        if ([self observedObjectForOffset] != nil)
        {
            [[self observedObjectForOffset] setValue:[NSNumber numberWithFloat:newOffset] forKeyPath:[self observedKeyPathForOffset]];
        }    
    }
    
    /*
     If we have a multiple selection for angle and Shift key is pressed then don't update the angle.
     This allows the angle to remain constant while the offset is changed.
     */
    if (!(multipleSelectionForAngle && ([event modifierFlags] & NSShiftKeyMask)))
    {
        float newAngle = atan2(xOffset, yOffset);
        
        float newAngleDegrees = newAngle / (3.1415927/180.0);
        
        if (newAngleDegrees < 0)
        {
            newAngleDegrees += 360;    
        }
        
        [self setAngle:newAngleDegrees];
        
        if (fabs(newAngle - self.angle) > 0.00001)
        {
            // Update observed controller if set.
            if ([self observedObjectForAngle] != nil)
            {
                NSNumber *newControllerAngle;
                
                // If there's a value transformer associated with the 'angle' binding, apply it to the value.
                if ([self angleValueTransformerName] != nil)
                {
                    NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:[self angleValueTransformerName]];
                    newControllerAngle = (NSNumber *)[valueTransformer reverseTransformedValue:[NSNumber numberWithFloat:newAngleDegrees]]; 
                }
                else
                {
                    newControllerAngle = [NSNumber numberWithFloat:self.angle];
                }
                
                [[self observedObjectForAngle] setValue:newControllerAngle forKeyPath:[self observedKeyPathForAngle]];
            }
        }
    }
    
    [self setNeedsDisplay:YES];
}



/*
 For standard mouse events, invoke updateForMouseEvent: with the event.
 In the case of mouse down/up events, also record the down/up state.
 */

-(void)mouseDown:(NSEvent *)event
{
    mouseDown = YES;
    [self updateForMouseEvent:event];
}


-(void)mouseDragged:(NSEvent *)event
{
    [self updateForMouseEvent:event];
}


-(void)mouseUp:(NSEvent *)event
{
    mouseDown = NO;
    [self updateForMouseEvent:event];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}


#pragma mark ---- drawing ----

- (void)drawRect:(NSRect)rect
{
    /*
     Basic goals:
     If either the angle or the offset has a "bad selection", then draw a gray rectangle, and that's it.
     Note: bad selection is set if there's a multiple selection but the "allows multiple selection" binding is NO.
     
     If there's a multiple selection for either angle or offset: then what you draw depends on what's multiple.
     
     - First, draw a white background to show all's OK.
     
     - If both are multiple, then draw a special symbol.
     
     - If offset is multiple, draw a line from the center of the view to the edge at the shared angle.
     
     - If angle is multiple, draw a circle of radius the shared offset centered in the view.
     
     If neither is multiple, draw a cross at the center of the view and a cross at distance 'offset' from the center at angle 'angle'
     
     */
    NSRect myBounds = [self bounds];    
    
    if (badSelectionForAngle || badSelectionForOffset)
    {
        // "Disable" and exit.
        NSDrawDarkBezel(myBounds,myBounds);
        return;
    }
    
    /*
     The user can do something, so draw white background and clip in anticipation of future drawing.
     */
    NSDrawLightBezel(myBounds,myBounds);
    
    NSBezierPath *clipRect =
    [NSBezierPath bezierPathWithRect:NSInsetRect(myBounds,2.0,2.0)];
    [clipRect addClip];
    
    if (multipleSelectionForAngle || multipleSelectionForOffset)
    {
        
        float originOffsetX = myBounds.size.width/2 + 0.5;
        float originOffsetY = myBounds.size.height/2 + 0.5;
        
        if (multipleSelectionForAngle && multipleSelectionForOffset)
        {
            /*
             Draw a diagonal line and circle to denote multiple selections for angle and offset.
             */
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(myBounds.size.width, myBounds.size.height)];
            NSRect circleBounds = NSMakeRect(originOffsetX-5, originOffsetY-5, 10, 10);
            NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circleBounds];
            [path stroke];
            return;
        }
        
        
        if (multipleSelectionForOffset)
        {
            /*
             Draw a line from center to a point outside bounds in the direction specified by angle.
             */
            float angleRadians = self.angle * (3.1415927/180.0);
            float x = sin(angleRadians) * myBounds.size.width + originOffsetX;
            float y = cos(angleRadians) * myBounds.size.height + originOffsetX;
            [NSBezierPath strokeLineFromPoint:NSMakePoint(originOffsetX, originOffsetY) toPoint:NSMakePoint(x, y)];
            return;
        }
        
        // 
        if (multipleSelectionForAngle)
        {
            /*
             Draw a circle with radius the shared offset don't draw radius < 1.0, else invisible.
             */
            float drawRadius = self.offset;
            if (drawRadius < 1.0)
            {
                drawRadius = 1.0;
            }
            NSRect offsetBounds = NSMakeRect(originOffsetX-drawRadius, originOffsetY-drawRadius, drawRadius*2, drawRadius*2);
            NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:offsetBounds];
            [path stroke];
            return;
        }
        // Shouldn't get here.
        return;
    }
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:(myBounds.size.width/2 + 0.5) yBy:(myBounds.size.height/2 + 0.5)];
    [transform concat];
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    // Draw a "+" at the location to which the shadow extends.
    float angleRadians = self.angle * (3.1415927/180.0);
    
    float xOffset = sin(angleRadians) * self.offset;
    float yOffset = cos(angleRadians) * self.offset;    
    
    [path moveToPoint:NSMakePoint(xOffset,yOffset-5)];
    [path lineToPoint:NSMakePoint(xOffset,yOffset+5)];
    [path moveToPoint:NSMakePoint(xOffset-5,yOffset)];
    [path lineToPoint:NSMakePoint(xOffset+5,yOffset)];
    
    [[NSColor lightGrayColor] set];
    [path setLineWidth:1.5];
    [path stroke];
    
    
    // Draw + in center of view.
    path = [NSBezierPath bezierPath];
    
    [path moveToPoint:NSMakePoint(0,-5)];
    [path lineToPoint:NSMakePoint(0,5)];
    [path moveToPoint:NSMakePoint(-5,0)];
    [path lineToPoint:NSMakePoint(5,0)];
    
    [[NSColor blackColor] set];
    [path setLineWidth:1.0];
    [path stroke];
}


#pragma mark ---- accessor and accessor-related methods ----

- (void)setNilValueForKey:(NSString *)key
{
    /*
     We may get passed nil for angle or offset; Just use 0.
     */
    [self setValue:@0 forKey:key];
}


-(BOOL)validateMaxOffset:(id *)ioValue error:(NSError **)outError

{
    if (*ioValue == nil)
    {
        /*
         Trap this in setNilValueForKey; an alternative might be to create new NSNumber with value 0 here.
         */
        return YES;
    }
    
    if ([*ioValue floatValue] <= 0.0)
    {
        NSString *errorString =
        NSLocalizedStringFromTable(@"Maximum Offset must be greater than zero", @"Joystick", @"validation: zero maxOffset error");
        
        if (outError != NULL) {
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey:errorString };
            NSError *error = [[NSError alloc] initWithDomain:@"JoystickView" code:1 userInfo:userInfoDict];
            *outError = error;
        }
        return NO;
    }
    return YES;
}


#pragma mark ---- changing the view hierarchy ----

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    if (newSuperview == nil)
    {
        [self unbind:ANGLE_BINDING_NAME];
        [self unbind:OFFSET_BINDING_NAME];
    }
}


@end


