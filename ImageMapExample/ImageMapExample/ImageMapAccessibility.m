/*
     File: ImageMapAccessibility.m
 Abstract: accessibility code for image map widget.
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

#import "ImageMapPrivate.h"
#import "FauxUIElement.h"

#import <AppKit/NSAccessibility.h>


@interface  HotSpotUIElement : FauxUIElement {
    NSUInteger index;
}
- (id)initWithIndex:(NSUInteger)anIndex parent:(id)aParent;
+ (HotSpotUIElement *)elementWithIndex:(NSUInteger)anIndex parent:(id)aParent;
- (NSUInteger)index;
@end


@implementation HotSpotUIElement

- (id)initWithIndex:(NSUInteger)anIndex parent:(id)aParent {
    if (self = [super initWithRole:NSAccessibilityButtonRole parent:aParent]) {
        index = anIndex;
    }
    return self;
}

+ (HotSpotUIElement *)elementWithIndex:(NSUInteger)anIndex parent:(id)aParent {
    return [[[HotSpotUIElement alloc] initWithIndex:anIndex parent:aParent] autorelease];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[HotSpotUIElement self]]) {
        HotSpotUIElement *other = object;
        return (index == other->index) && [super isEqual:object];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    // Equal objects must hash the same.
    return [super hash] + index;
}

- (NSUInteger)index {
    return index;
}

- (NSArray *)accessibilityAttributeNames {
    ImageMap *imageMap = (ImageMap*)parent;
    if ([imageMap isHTMLImageMap]) {
	// For HTML image maps we can provide a description using the alt or title attributes.
	static NSArray *attributes = nil;
	if (attributes == nil) {
	    attributes = [[[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityDescriptionAttribute] retain];
	}
	return attributes;
    } else {
	return [super accessibilityAttributeNames];
    }
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
	ImageMap *imageMap = (ImageMap*)parent;
	NSDictionary *info = [imageMap infoForHotSpotAtIndex:index];
	NSString *description = [info valueForKey:@"alt"];
	if (description == nil) {
	    description = [info valueForKey:@"title"];
	}
	return description;
    } else {
	return [super accessibilityAttributeValue:attribute];
    }
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
    return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
    ImageMap *imageMap = (ImageMap*)parent;
    [imageMap performActionForHotSpotAtIndex:index];
}

@end


@implementation ImageMap (ImageMapAccessibility)

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
	return NSAccessibilityGroupRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
	return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
	int numHotSpots = [self numHotSpots];
	NSMutableArray *kids = [NSMutableArray arrayWithCapacity:numHotSpots];
	int i;
	for (i = 0; i < numHotSpots; ++i) {
	    [kids addObject:[HotSpotUIElement elementWithIndex:i parent:self]];
	}
	
	// Handle the default as a giant hot spot - for accessibility purposes.
	if ([self hasDefault]) {
	    [kids addObject:[HotSpotUIElement elementWithIndex:NSNotFound parent:self]];
	}
	
	return NSAccessibilityUnignoredChildren(kids);
    } else {
	return [super accessibilityAttributeValue:attribute];
    }
}

- (id)accessibilityHitTest:(NSPoint)point {
    NSPoint windowPoint = [[self window] convertScreenToBase:point];
    NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];
    int index = [self hotSpotIndexForPoint:localPoint];
    if (index != NSNotFound || [self hasDefault]) {
	// Handle the default as a giant hot spot - for accessibility purposes.
	HotSpotUIElement *hotSpot = [HotSpotUIElement elementWithIndex:index parent:self];
	// Allow the hot spot to do further hit testing.
	return [hotSpot accessibilityHitTest:point];
    } else {
	return [super accessibilityHitTest:point];
    }
}


//
// FauxUIElementChildSupport protocol
//

- (BOOL)isFauxUIElementFocusable:(FauxUIElement *)fauxElement {
    // Always NO - unless we add keyboard focus support to image map.
    return NO;
}

- (void)fauxUIElement:(FauxUIElement *)fauxElement setFocus:(id)value {
    // Never called - unless we add keyboard focus support to image map.
}

- (NSPoint)fauxUIElementPosition:(FauxUIElement *)fauxElement {
    HotSpotUIElement *hotSpot = (HotSpotUIElement *)fauxElement;
    NSUInteger index = [hotSpot index];
    NSPoint windowPoint;
    if (index != NSNotFound) {
	NSRect localBounds = [self boundsForHotSpotAtIndex:index];
	NSPoint localPoint = localBounds.origin;
	if ([self isFlipped]) {
	    localPoint.y += localBounds.size.height;
	}
	windowPoint = [self convertPoint:localPoint toView:nil];
    } else {
	// Handle the default as a giant hot spot - for accessibility purposes.
	windowPoint = [self frame].origin;
    }
    return [[self window] convertBaseToScreen:windowPoint];
}

- (NSSize)fauxUIElementSize:(FauxUIElement *)fauxElement {
    HotSpotUIElement *hotSpot = (HotSpotUIElement *)fauxElement;
    NSUInteger index = [hotSpot index];
    if (index != NSNotFound) {
	NSRect localBounds = [self boundsForHotSpotAtIndex:index];
	return [self convertSize:localBounds.size toView:nil];
    } else {
	// Handle the default as a giant hot spot - for accessibility purposes.
	return [self frame].size;
    }
}

@end