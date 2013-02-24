 /*
 
 File: AccessibilityElement.h
 
 Abstract: AccessibilityElement is an object used to represent an
 element in the view (an image or text) for accessibility purposes.
 It can be created with either the image role or the static text role,
 and it serves up its string value as value or description accordingly.
 
 Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */ 

#import "AccessibilityElement.h"

@implementation AccessibilityElement

- (id)initWithRole:(NSString *)role parentView:(NSView *)parent index:(NSInteger)idx {
    self = [super init];
    if (self) {
        accessibilityRole = [role copy];
        parentView = parent;
        accessibilityIndex = idx;
        bounds = NSZeroRect;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AccessibilityElement self]]) {
        AccessibilityElement *other = object;
        return ([[self accessibilityRole] isEqualToString:[other accessibilityRole]] && [[self parentView] isEqual:[other parentView]] && [self accessibilityIndex] == [other accessibilityIndex]);
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return [[self accessibilityRole] hash] + [[self stringValue] hash] + [[self parentView] hash] + [self accessibilityIndex];
}

@synthesize accessibilityRole;
@synthesize parentView;
@synthesize accessibilityIndex;
@synthesize stringValue;
@synthesize bounds;

- (NSArray *)accessibilityAttributeNames {
    BOOL isStaticText = [[self accessibilityRole] isEqualToString:NSAccessibilityStaticTextRole];
    return [NSArray arrayWithObjects:NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, NSAccessibilityFocusedAttribute, NSAccessibilityParentAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, NSAccessibilityEnabledAttribute, isStaticText ? NSAccessibilityValueAttribute : NSAccessibilityDescriptionAttribute, nil];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    NSView *parent = [self parentView];
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
	return [self accessibilityRole];
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
	return NSAccessibilityRoleDescription([self accessibilityRole], nil);
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
	id focusedElement = [NSApp accessibilityAttributeValue:NSAccessibilityFocusedUIElementAttribute];
	return [NSNumber numberWithBool:[focusedElement isEqual:self]];
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
	return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
	return [parent accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
	return [parent accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        // Position is lower-left of element, in screen coordinates
        NSPoint point = [self bounds].origin;
        if ([parent isFlipped]) point.y = NSMaxY([self bounds]);
        return [NSValue valueWithPoint:[[parent window] convertBaseToScreen:[parent convertPointToBase:point]]];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
	return [NSValue valueWithSize:[parent convertSizeToBase:[self bounds].size]];
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
	return [NSNumber numberWithBool:YES];
    } else if ([attribute isEqualToString:NSAccessibilityValueAttribute] || [attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
	return [self stringValue];
    } else {
	return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return NO;
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
}

- (NSArray *)accessibilityActionNames {
    return [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
    return nil;
}

- (void)accessibilityPerformAction:(NSString *)action {
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

@end
