
/*
     File: SKTGraphicAccessibilityProxy.m
 Abstract: A proxy for an SKTGraphic to provide accessibility support.
 
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

#import "SKTGraphicAccessibilityProxy.h"
#import "SKTGraphicView.h"
#import "SKTHandleUIElement.h"

@implementation SKTGraphicAccessibilityProxy

@synthesize parent, graphic;


- (id)initWithGraphic:(SKTGraphic *)graphicValue parent:(id)parentValue {
	self = [super init];
	if (self) {
		graphic = [graphicValue retain];
		parent = [parentValue retain];
	}
	return self;
}


+ (SKTGraphicAccessibilityProxy *)graphicProxyWithGraphic:(SKTGraphic *)graphicValue parent:(id)parentValue {
	return [[[[self class] alloc] initWithGraphic:graphicValue parent:parentValue] autorelease];
}


- (void)dealloc {
	[graphic release];
	[parent release];
	[super dealloc];
}


/* All accessibility elements need to report their size and position in screen coordinates.  To do this, an element that is a subelement of an NSView, needs to use that NSView in order to convert local coordinates to window coordinates.  The element also needs the window of the NSView to convert the window coordinates to screen coordinates.  At present, the parent of each graphic in Sketch is the SKTGraphicsView.  If Sketch were to implement grouping of graphics, then the parent of a graphic could be the grouped layout item, not the graphics view.  Since we cannot assume that the parent of a graphic is always a view, this method walks up the accessibility hierarchy until the first containing view is found.  Also note that we rely on the assumption that the containing graphic view is not ignored by accessibility.
 */
- (SKTGraphicView *)containingGraphicView {
	id currentElement = self;
	
	do {
		currentElement = [currentElement accessibilityAttributeValue:NSAccessibilityParentAttribute];
	} while (![currentElement isKindOfClass:[SKTGraphicView class]]);
	
	return (SKTGraphicView *)currentElement;
}

- (BOOL)isSelected {
	return [[[self containingGraphicView] selectedGraphics] containsObject:graphic];
}

- (NSArray *)handleUIElementsWithHandleCodes:(NSIndexSet *)handleCodes {
    NSMutableArray *handleElements = [NSMutableArray arrayWithCapacity:[handleCodes count]];
    
    [handleCodes enumerateIndexesUsingBlock:^(NSUInteger currentIndex, BOOL *stop) {
		
		id handleUIElement = [[SKTHandleUIElement alloc] initWithHandleCode:currentIndex parent:self];
		[handleElements addObject:handleUIElement];
		[handleUIElement release];
		
    }];
	
    return handleElements;
}


- (BOOL)accessibilityIsIgnored {
	return NO;
}

#pragma mark -
#pragma mark Attributes

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes;
    if (!attributes) {
		attributes = [[NSArray alloc] initWithObjects:    
						NSAccessibilityRoleAttribute,
						NSAccessibilityRoleDescriptionAttribute,
						NSAccessibilityParentAttribute,
						NSAccessibilityChildrenAttribute,
						NSAccessibilityWindowAttribute,
						NSAccessibilityTopLevelUIElementAttribute,
						NSAccessibilityPositionAttribute,
						NSAccessibilitySizeAttribute,
						NSAccessibilityEnabledAttribute,
						NSAccessibilityFocusedAttribute,
						NSAccessibilityHandlesAttribute,
						NSAccessibilityDescriptionAttribute,
					  nil];
    }
    return attributes;
}


- (id)accessibilityAttributeValue:(NSString *)attribute {
	
    
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityLayoutItemRole;
    }
    
    else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		return NSAccessibilityRoleDescription(NSAccessibilityLayoutItemRole, nil);
    }
    
    else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
		// Our parent should never be ignored, but just in case
		return NSAccessibilityUnignoredAncestor(parent);
    }
    
    else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [self accessibilityAttributeValue:NSAccessibilityHandlesAttribute];
    }
    
    else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		// Just ask our parent for the value of its AXWindow attribute
		return [parent accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    }
    
    else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		// Just ask our parent for the value of its AXTopLevelUIElement attribute
		return [parent accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    }
	
    else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		// Get our containing view
		NSView *containingGraphicView = [self containingGraphicView];
		
		// Get the bounds of our graphic
		NSRect localBounds = [graphic bounds];
		
		// Get origin of the bounds
		NSPoint localPoint = localBounds.origin;
		
		// If we are flipped, we need to adjust to use the correct corner as the origin
		if ([containingGraphicView isFlipped]) {
			localPoint.y += localBounds.size.height;
		}
		
		// Convert from local coordinates to window coordinates
		NSPoint windowPoint = [containingGraphicView convertPointToBase:localPoint];
		
		// Convert from window coordinates to screen coordinates
		NSPoint screenPoint = [[containingGraphicView window] convertBaseToScreen:windowPoint];
		
		// Return an NSValue of the point in Cocoa screen coordinates
		return [NSValue valueWithPoint:screenPoint];
    }
    
    else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		// Get our containing view
		NSView *containingGraphicView = [self containingGraphicView];
		
		// Get size of the bounds of our graphic
		NSSize localSize = [graphic bounds].size;
		
		// Convert from local to window/screen coordinates.
		// Note that the scale of the window and screen coordinate systems are always the same
		NSSize screenSize = [containingGraphicView convertSizeToBase:localSize];
		
		// Return an NSValue of the size
		return [NSValue valueWithSize:screenSize];
    }
    
    
    else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		return [NSNumber numberWithBool:YES];
    }
    
    else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
		return [NSNumber numberWithBool:NO];
    }
    
    else if ([attribute isEqualToString:NSAccessibilityHandlesAttribute]) {
		if ([self isSelected]) {
			return [self handleUIElementsWithHandleCodes:[graphic handleCodes]];
		} else {
			return [NSArray array];
		}
    }
	
    else if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
		return [graphic shapeDescription];
    }
	
	else {
		return nil; // Our superclass does not implement NSAccessibility.
    }
}

/* Here all settable attributes are put into a set to be checked against.  Since there are only two settable attributes at present, that could be done by using -isEqualToString: for each attribute.  For any other attribute, return NO
 */
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    static NSSet *settableAttributes;
    if (!settableAttributes) {
		settableAttributes = [[NSSet alloc] initWithObjects:NSAccessibilitySizeAttribute, NSAccessibilityPositionAttribute, nil];
    }
    if ([settableAttributes containsObject:attribute]) {
		return YES;
    }
    else {
		return NO;
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		NSView *containingGraphicView = [self containingGraphicView];
		NSSize screenSize = [value sizeValue];
		NSSize localSize = [containingGraphicView convertSizeFromBase:screenSize];
		NSRect bounds = [graphic bounds];
		bounds.size = localSize;
		[graphic setBounds:bounds];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		NSView *containingGraphicView = [self containingGraphicView];
		NSPoint screenPoint = [value pointValue];
		NSPoint windowPoint = [[containingGraphicView window] convertScreenToBase:screenPoint];
		NSPoint localPoint = [containingGraphicView convertPointFromBase:windowPoint];
		NSRect bounds = [graphic bounds];
		if ([containingGraphicView isFlipped]) {
			localPoint.y -= bounds.size.height;
		}
		bounds.origin = localPoint;
		[graphic setBounds:bounds];
    }
}


#pragma mark -
#pragma mark Optional Array Attribute Methods

/* Given an accessibility child of an object, return the index of that child in the parent.  We can figure out the index of a particular child by getting the handle code of that child and running through the index set of handle enum values and returning the appropriate index.
*/
- (NSUInteger)accessibilityIndexOfChild:(id)child {
    // At present, all of our children are SKTHandleUIElements
    NSUInteger childHandleCode = [(SKTHandleUIElement *)child handleCode];
    
    NSUInteger indexOfChild = NSNotFound;
    NSUInteger currentIndex = 0;
    NSIndexSet *handleCodes = [graphic handleCodes];

    NSUInteger currentHandleCode = [handleCodes firstIndex];
 
    if (currentHandleCode == childHandleCode) indexOfChild = 0;
    
    while (currentHandleCode != NSNotFound && indexOfChild == NSNotFound) {
	currentIndex++;
        currentHandleCode = [handleCodes indexGreaterThanIndex:currentHandleCode];
	if (currentHandleCode == childHandleCode) indexOfChild = currentIndex;
    }

    return indexOfChild;
}

/* We already know the count of our children and handles without making all the faux UI elements to count.
*/
- (NSUInteger)accessibilityArrayAttributeCount:(NSString *)attribute {
    
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute] || [attribute isEqualToString:NSAccessibilityHandlesAttribute]) {
	// If we are selected we have handles, and we can quickly get the count.  Otherwise, we have no handles.
	if ([self isSelected]) {
	    return [[graphic handleCodes] count];
	} else {
	    return 0;
	}
    
    } else {
	return [super accessibilityArrayAttributeCount:attribute];
    }
}


/* We don't need to create all faux UI elements if the accessibility client only wants a subset.  Remember that max count is not bound-checked by the accessibility client, we need to do that ourselves.
 */
- (NSArray *)accessibilityArrayAttributeValues:(NSString *)attribute index:(NSUInteger)index maxCount:(NSUInteger)maxCount {
	
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute] || [attribute isEqualToString:NSAccessibilityHandlesAttribute]) {
		
		NSIndexSet *handleCodes = [graphic handleCodes];
		NSUInteger handleCodeCount = [handleCodes count];
		
		NSMutableIndexSet *handleCodeSubrange = [NSMutableIndexSet indexSet];
		
		NSUInteger currentHandleCode = [handleCodes firstIndex];
		
		NSUInteger firstReportedCode = NSNotFound;
		NSUInteger currentIndex = 0;
		
		// Find and add the first requested index in the index set
		if (0 != index) {
			while (currentHandleCode != NSNotFound && firstReportedCode == NSNotFound) {
				currentIndex++;
				currentHandleCode = [handleCodes indexGreaterThanIndex:currentHandleCode];
				if (currentIndex == index) {
					firstReportedCode = currentHandleCode;
				}
			}
		} else {
			firstReportedCode = currentHandleCode;
		}
		
		[handleCodeSubrange addIndex:firstReportedCode];
		
		
		// Now run through and add the values at the remaining requested index
		// Remember the accessibility client can ask for an out of bounds value, we need to limit to our bounds
		NSUInteger remainingHandleCount = handleCodeCount - currentIndex - 1;
		remainingHandleCount = MIN(remainingHandleCount, (maxCount - 1));
		NSUInteger i;
		if (remainingHandleCount > 0) {
			for (i = 0; i < remainingHandleCount; i++) {
				currentIndex++;
				currentHandleCode = [handleCodes indexGreaterThanIndex:currentHandleCode];
				[handleCodeSubrange addIndex:currentHandleCode];
			}
		}
		
		// Once we build the index set of desired handle codes, just created the faux elements we need.
		NSArray *arrayAttributeValue = [self handleUIElementsWithHandleCodes:handleCodeSubrange];
		return arrayAttributeValue;
		
    } else {
		return [super accessibilityArrayAttributeValues:attribute index:index maxCount:maxCount];
    }
}


#pragma mark -
#pragma mark Actions

- (NSArray *)accessibilityActionNames {
    return [NSArray array];
}


- (void)accessibilityPerformAction:(NSString *)action {
	
}


#pragma mark -
#pragma mark Acccessibility Hit Testing

- (id)accessibilityHitTest:(NSPoint)point {
	
	SKTGraphicView *graphicView = [self containingGraphicView];
	
    NSPoint windowPoint = [[graphicView window] convertScreenToBase:point];
	
    NSPoint localPoint = [graphicView convertPointFromBase:windowPoint];
	
    NSInteger hitHandle = [graphic handleUnderPoint:localPoint];
	
    if (hitHandle != SKTGraphicNoHandle) {
		SKTHandleUIElement *handleElement = [SKTHandleUIElement graphicHandleWithCode:hitHandle parent:self];
		return [handleElement accessibilityHitTest:point];
    } else {
		return NSAccessibilityUnignoredAncestor(self);
    }
}


#pragma mark -
#pragma mark Support for children elements

/* Implement the FauxUIElementChildSupport informal protocol as defined in FauxUIElement.h
 */
- (NSPoint)fauxUIElementPosition:(FauxUIElement *)fauxElement {
    SKTHandleUIElement *handleUIElement = (SKTHandleUIElement *)fauxElement;
    NSInteger handleCode = [handleUIElement handleCode];
    NSRect bounds = [graphic rectangleForHandleCode:handleCode];
	SKTGraphicView *graphicView = [self containingGraphicView];
	
    NSPoint localPoint = bounds.origin;
    if ([graphicView isFlipped]) {
		localPoint.y += bounds.size.height;
    }
    NSPoint windowPoint = [graphicView convertPointToBase:localPoint];
    NSPoint screenPoint = [[graphicView window] convertBaseToScreen:windowPoint];
    return screenPoint;
}

- (NSSize)fauxUIElementSize:(FauxUIElement *)fauxElement {
    SKTHandleUIElement *handleUIElement = (SKTHandleUIElement *)fauxElement;
	SKTGraphicView *graphicView = [self containingGraphicView];
    NSInteger handleCode = [handleUIElement handleCode];
    NSRect bounds = [graphic rectangleForHandleCode:handleCode];
    NSSize localSize = bounds.size;
    NSSize windowSize = [graphicView convertSizeToBase:localSize];
    return windowSize;
}

- (BOOL)isFauxUIElementFocusable:(FauxUIElement *)fauxElement {
    return NO;
}

- (void)fauxUIElement:(FauxUIElement *)fauxElement setFocus:(id)value {
    // No op
}


- (void)setPosition:(NSPoint)point forHandleUIElement:(SKTHandleUIElement *)handleUIElement {
    SKTGraphicView *graphicView = [self containingGraphicView];
	
    NSPoint windowPoint = [[graphicView window] convertScreenToBase:point];
    NSPoint localPoint = [graphicView convertPointFromBase:windowPoint];
    
    // Use existing SKTGraphic method to do the move of the handle
    [graphic resizeByMovingHandle:[handleUIElement handleCode] toPoint:localPoint];
}


- (NSString *)descriptionForHandleCode:(NSInteger)handleCode {
	return [graphic descriptionForHandleCode:handleCode];
}


#pragma mark -
#pragma mark NSObject overridden methods

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) {
		return NO;
	} else {
		return ([graphic isEqual:[(SKTGraphicAccessibilityProxy *)object graphic]] && [parent isEqual:[(SKTGraphicAccessibilityProxy *)object parent]]);
	}
}

- (NSUInteger)hash {
	return [graphic hash] + [parent hash];
}

@end

