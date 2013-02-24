
/*
     File: SKTGraphicView+Accessibility.m
 Abstract: Adds accessibility support to SKTGraphicView.
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */


#import "SKTGraphicView.h"
#import "SKTGraphicAccessibilityProxy.h"

@interface SKTGraphicView (Private)
- (NSArray *)graphics;
- (SKTGraphic *)graphicUnderPoint:(NSPoint)point index:(NSUInteger *)outIndex isSelected:(BOOL *)outIsSelected handle:(NSInteger *)outHandle;
@end

@implementation SKTGraphicView (Accessibility)

- (BOOL)isGraphicSelected:(SKTGraphic *)graphic {
    return [[self selectedGraphics] containsObject:graphic];
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

#pragma mark -
#pragma mark Attributes

- (NSArray *)accessibilityAttributeNames {
	
    static NSArray *attributes;
    
	if (!attributes) {
		NSMutableArray *temp = [[super accessibilityAttributeNames] mutableCopy];
		[temp addObject:NSAccessibilityEnabledAttribute];
		[temp addObject:NSAccessibilityVerticalUnitsAttribute];
		[temp addObject:NSAccessibilityHorizontalUnitsAttribute];
		[temp addObject:NSAccessibilityVerticalUnitDescriptionAttribute];
		[temp addObject:NSAccessibilityHorizontalUnitDescriptionAttribute];
		attributes = [temp copy];
		[temp release];
    }
	
    return attributes;
}



- (id)accessibilityAttributeValue:(NSString *)attribute {
	
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityLayoutAreaRole;
		
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		
		// Get all the graphics
		NSArray *allGraphics = [self graphics];
		
		// Create an autoreleased mutable array to hold the graphic proxy elements
		NSMutableArray *children = [NSMutableArray arrayWithCapacity:[allGraphics count]];
		
		// Iterate through the graphics.  We go backwards so they are returned in z-order.
		SKTGraphic *graphic = nil;
		NSEnumerator *reverseEnumerator = [allGraphics reverseObjectEnumerator];
		while (graphic = [reverseEnumerator nextObject]) {
			
			// For each graphic, create an autoreleased proxy element and add it to the array
			id child = [SKTGraphicAccessibilityProxy graphicProxyWithGraphic:graphic parent:self];
			[children addObject:child];
		}
		
		// Send back the array.
		return children;
		
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		return [NSNumber numberWithBool:YES];
		
    } else if ([attribute isEqualToString:NSAccessibilityVerticalUnitsAttribute] || [attribute isEqualToString:NSAccessibilityHorizontalUnitsAttribute]) {
		return NSAccessibilityPointsUnitValue;
		
    } else if ([attribute isEqualToString:NSAccessibilityVerticalUnitDescriptionAttribute] || [attribute isEqualToString:NSAccessibilityHorizontalUnitDescriptionAttribute]) {
		return NSLocalizedStringFromTable(@"points", @"Accessibility", @"accessibility description for unit measurement");
		
    } else {
		return [super accessibilityAttributeValue:attribute];
    }
}


/* Our superclass NSView will report NO for any attribute it does not explicitly allow.  Since all of the attributes we have added are read-only, we do not need to override -accessibilityIsAttributeSettable:, however, this template is here to be uncommented and used if a settable attribute is ever added by this subclass.  Change the NSSet init method to -initWithObjects: and list the settable attributes.

*/
/*- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    static NSSet *settableAttributes;
    if (!settableAttributes) {
	settableAttributes = [[NSSet alloc] init];
    }
    if ([settableAttributes containsObject:attribute]) {
	return YES;
    }
    else {
	return [super accessibilityIsAttributeSettable:attribute];
    }
}*/

#pragma mark -
#pragma mark Parameterized Attributes

/* The parameterized attributes of a layout area allow an accessibility client to take usual information about sub-elements, such as the AXSize and AXPosition and translate into the units used by the user interface, so they can be reported by the user.  Similarly, the accessibility client can let its user work with units in this application's user interface, and then use these parameterized methods to convert to the correct screen units.
 */
- (NSArray *)accessibilityParameterizedAttributeNames {
    static NSArray *attributes;
    if (!attributes) {
		NSMutableArray *temp = [[super accessibilityParameterizedAttributeNames] mutableCopy];
		[temp addObject:NSAccessibilityLayoutPointForScreenPointParameterizedAttribute];
		[temp addObject:NSAccessibilityLayoutSizeForScreenSizeParameterizedAttribute];
		[temp addObject:NSAccessibilityScreenPointForLayoutPointParameterizedAttribute];
		[temp addObject:NSAccessibilityScreenSizeForLayoutSizeParameterizedAttribute];
		attributes = [temp copy];
		[temp release];
    }
    return attributes;
}

/* Sketch uses points as the unit of measure - the coordinate system reported to the user is the same as the SKTGraphicView's native coordinate system.  So for these methods, convert between view coordinates and screen coordinates and vice versa.  If Sketch reported inches to the user, for instance, we would need to add an additional conversion from view coordinates to the reported measurement system and vice versa.
 */
- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter {
	
    if (![parameter isKindOfClass:[NSValue class]]) NSAccessibilityRaiseBadArgumentException(self, attribute, parameter);
	
    if ([attribute isEqualToString:NSAccessibilityLayoutPointForScreenPointParameterizedAttribute]) {
		NSPoint point = [parameter pointValue];
		NSPoint windowPoint = [[self window] convertScreenToBase:point];
		NSPoint localPoint = [self convertPointFromBase:windowPoint];
		return [NSValue valueWithPoint:localPoint];
    }
    
    else if ([attribute isEqualToString:NSAccessibilityLayoutSizeForScreenSizeParameterizedAttribute]) {
		NSSize size = [parameter sizeValue];
		NSSize localSize = [self convertSizeFromBase:size];
		return [NSValue valueWithSize:localSize];
    }
	
    else if ([attribute isEqualToString:NSAccessibilityScreenPointForLayoutPointParameterizedAttribute]) {
		NSPoint point = [parameter pointValue];
		NSPoint windowPoint = [self convertPointToBase:point];
		NSPoint screenPoint = [[self window] convertBaseToScreen:windowPoint];
		return [NSValue valueWithPoint:screenPoint];
    }
	
    else if ([attribute isEqualToString:NSAccessibilityScreenSizeForLayoutSizeParameterizedAttribute]) {
		NSSize size = [parameter sizeValue];
		NSSize screenSize = [self convertSizeToBase:size];
		return [NSValue valueWithSize:screenSize];
    }
	
    else {
		return [super accessibilityAttributeValue:attribute forParameter:parameter];
    }
}


#pragma mark -
#pragma mark Hit Testing

/* If accessibilityHitTest: is called, it has already been determined that the point is either contained in this element, or one of its descendants.  We figure out whether one of our graphics is hit, if so we create a graphic proxy element and ask it to perform an accessibility hit test.  If not, we return our first unignored anscestor (which in this case is us).
 */
- (id)accessibilityHitTest:(NSPoint)point {
	
    // Convert screen point to window point
    NSPoint windowPoint = [[self window] convertScreenToBase:point];
	
    // Convert window point to local point
    NSPoint localPoint = [self convertPointFromBase:windowPoint];
	
    // Use existing method to hit test graphics
    SKTGraphic *hitGraphic = [self graphicUnderPoint:localPoint index:0 isSelected:0 handle:0];
	
    if (hitGraphic) {
		// If we hit a graphic, make a graphic proxy object
		SKTGraphicAccessibilityProxy *graphicProxy = [SKTGraphicAccessibilityProxy graphicProxyWithGraphic:hitGraphic parent:self];
		
		// And ask it to do an accessibility hit test, return the result
		return [graphicProxy accessibilityHitTest:point];
		
    } else {
		// Otherwise, just return our unignored anscestor.  In this case, ourself.
		return NSAccessibilityUnignoredAncestor(self);
    }
}

@end

