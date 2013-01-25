/*
     File: FauxUIElement.m 
 Abstract: abstract ui element object for accessibility 
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

#import "FauxUIElement.h"

#import <AppKit/NSAccessibility.h>

@implementation FauxUIElement

- (id)initWithRole:(NSString *)aRole parent:(id)aParent {
    
    self = [super init];
    if (self) {
        role = [aRole retain];
        parent = aParent;
    }
    
    return self;
}

+ (FauxUIElement *)elementWithRole:(NSString *)aRole parent:(id)aParent {
    return [[[self alloc] initWithRole:aRole parent:aParent] autorelease];
}

- (void)dealloc {
    [role release];
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[FauxUIElement class]]) {
        FauxUIElement *other = object;
        return [role isEqualToString:other->role] && [parent isEqual:other->parent];
    } else
        return NO;
}

- (NSUInteger)hash {
    // Equal objects must hash the same.
    return [role hash] + [parent hash];
}

//
// accessibility protocol
//

// attributes

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
	attributes = [[NSArray alloc] initWithObjects:
	    NSAccessibilityRoleAttribute,
	    NSAccessibilityRoleDescriptionAttribute,
	    NSAccessibilityFocusedAttribute,
	    NSAccessibilityParentAttribute,
	    NSAccessibilityWindowAttribute,
	    NSAccessibilityTopLevelUIElementAttribute,
	    NSAccessibilityPositionAttribute,
	    NSAccessibilitySizeAttribute,
	    nil];
    }
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return role;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescription(role, nil);
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        // Just check if the app thinks we're focused.
        id focusedElement = [NSApp accessibilityAttributeValue:NSAccessibilityFocusedUIElementAttribute];
        return [NSNumber numberWithBool:[focusedElement isEqual:self]];
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [parent accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [parent accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        return [NSValue valueWithPoint:[parent fauxUIElementPosition:self]];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        return [NSValue valueWithSize:[parent fauxUIElementSize:self]];
    }
    
    return nil;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
	return [parent isFauxUIElementFocusable:self];
    } else {
	return NO;
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
	[parent fauxUIElement:self setFocus:value];
    }
}


// actions

- (NSArray *)accessibilityActionNames {
    return [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
    return nil;
}

- (void)accessibilityPerformAction:(NSString *)action {
}


// misc

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
