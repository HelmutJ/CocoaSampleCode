/*
    File: RoundedCornersView.m
Abstract: A view that draws a rounded rect with the window background. It is used to draw the background for the suggestions window and expose the suggestions to accessibility.
 Version: 1.4

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

#import "RoundedCornersView.h"


@implementation RoundedCornersView

@synthesize rcvCornerRadius = _cornerRadius;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.rcvCornerRadius = 10.0f;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {

    CGFloat cornerRadius = self.rcvCornerRadius;
    
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:cornerRadius yRadius:cornerRadius];

    [[NSColor windowBackgroundColor] setFill];
    [borderPath fill];
}

- (BOOL)isFlipped {
    return YES;
}

#pragma mark -
#pragma mark Accessibility

/* This view contains the list of selections.  It should be exposed to accessibility, and should report itself with the role 'AXList'.  Because this is an NSView subclass, most of the basic accessibility behavior (accessibility parent, children, size, position, window, and more) is inherited from NSView.  Note that even the role description attribute will update accordingly and its behavior does not need to be overridden.  However, since the role AXList has a number of additional required attributes, we need to declare them and implement them.
*/


/* Make sure we are reported by accessibility.  NSView's default return value is YES.
*/
- (BOOL)accessibilityIsIgnored {
    return NO;
}

/* The suggestions will be an AXList of suggestions.  AXList requires additional attributes beyond what NSView provides.
*/
- (NSArray *)accessibilityAttributeNames {
    NSMutableArray *attributeNames = [NSMutableArray arrayWithArray:[super accessibilityAttributeNames]];
    [attributeNames addObject:NSAccessibilityOrientationAttribute];
    [attributeNames addObject:NSAccessibilityEnabledAttribute];
    [attributeNames addObject:NSAccessibilityVisibleChildrenAttribute];
    [attributeNames addObject:NSAccessibilitySelectedChildrenAttribute];
    return attributeNames;
}


/* Return a different value for the role attribute, and the values for the additional attributes declared above.
*/
- (id)accessibilityAttributeValue:(NSString *)attribute {
    // Report our role as AXList
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityListRole;

    // Our orientation is vertical
    } else if ([attribute isEqualToString:NSAccessibilityOrientationAttribute]) {
        return NSAccessibilityVerticalOrientationValue;

    // The list is always enabled
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
        return [NSNumber numberWithBool:YES];

    // There is no scroll bar in this example - all children are always visible
    } else if ([attribute isEqualToString:NSAccessibilityVisibleChildrenAttribute]) {
        return [self accessibilityAttributeValue:NSAccessibilityChildrenAttribute];

    // Run through children, and if they respond to 'isHighlighted' put them in the list
    } else if ([attribute isEqualToString:NSAccessibilitySelectedChildrenAttribute]) {
        NSMutableArray *selectedChildren = [NSMutableArray array];
        for (id element in [self accessibilityAttributeValue:NSAccessibilityChildrenAttribute]) {
            if ([element respondsToSelector:@selector(isHighlighted)] && [element isHighlighted]) {
                [selectedChildren addObject:element];
            }
        }
        return selectedChildren;

    // Otherwise, return what super returns
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}

/* In addition to reporting the value for an attribute, we need to return whether value of the attribute can be set.
*/
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {

    // Three of the four attributes we added are not settable
    if ([attribute isEqualToString:NSAccessibilityOrientationAttribute] || [attribute isEqualToString:NSAccessibilityEnabledAttribute] || [attribute isEqualToString:NSAccessibilityVisibleChildrenAttribute] || [attribute isEqualToString:NSAccessibilitySelectedChildrenAttribute]) {
        return NO;
    }

    // Accessibility clients like VoiceOver can set the selected suggestion, so return YES
    else if ([attribute isEqualToString:NSAccessibilitySelectedChildrenAttribute]) {
        return YES;

    // Otherwise, return what super returns
    } else {
        return [super accessibilityIsAttributeSettable:attribute];
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilitySelectedChildrenAttribute]) {
        NSWindowController *windowController = [[self window] windowController];
        if (windowController) {
            // Our subclass of NSWindowController has a selectedView property
            [windowController setValue:value forKey:@"selectedView"];
        }
    } else {
        [super accessibilitySetValue:value forAttribute:attribute];
    }
}

@end
