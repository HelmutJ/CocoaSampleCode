/*

File: DCDie-Accessibility.m

Abstract: Accessibility implementation for each die

Version: <1.0>

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006-2009 Apple Inc., All Rights Reserved

*/

#import "DCDie.h"
#import "DCDiceView-Private.h"


@implementation DCDie (Accessibility)

-(BOOL)accessibilityIsIgnored {
	return NO;
}

/* The list of attributes is taken from what an AXCheckbox UI Element supports */
- (NSArray *)accessibilityAttributeNames {

	static NSArray *attributes;
	
	if (!attributes) {
		attributes = [[NSArray alloc] initWithObjects: NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, NSAccessibilityParentAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityValueAttribute, NSAccessibilityHelpAttribute, NSAccessibilityEnabledAttribute, NSAccessibilityFocusedAttribute, NSAccessibilityDescriptionAttribute, nil];
	}
	return attributes;
}

- (NSString *)dieDescriptionForAccessiblity {
	
	NSString *heldString = nil;
	if (hasHold) heldString = NSLocalizedString(@"held", @"Accessibility description for held die");
	else heldString = NSLocalizedString(@"unheld", @"Accessibility description for unheld die");

	
	if (spotCount > 1) // @"%@ die with %d spots"
		return [NSString stringWithFormat:NSLocalizedString(@"held die with X spots", @"Accessibility description for die with more than one spots"), heldString, [self spotCount]];
	else // @"%@ die with %d spot"
		return [NSString stringWithFormat:NSLocalizedString(@"held die with X spot", @"Accessibility description for die with one spot"), heldString, [self spotCount]];
}

/* This should return a localized string */
- (id)accessibilityAttributeValue:(NSString *)attribute {

	id attributeValue = nil;
	
	/* We are a button that maintains state (held/unheld) our closest UI Element is a checkbox */
	if ([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
		attributeValue = NSAccessibilityCheckBoxRole;
	} 
	
	/* Can use the convenience function NSAccessibilityRoleDescription to get localized role descriptions of standard roles */
	else if ([attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute]) {
		attributeValue = NSAccessibilityRoleDescription(NSAccessibilityCheckBoxRole,nil);
	} 
	
	/* We need to have some way to return a reference to our parent. */
	else if ([attribute isEqualToString: NSAccessibilityParentAttribute]) {
		attributeValue = parent;
	} 
	
	/* Screen geometery properties:
		Accessibility coordinates are always screen coordinates.  	
		We return NSValues of points and rects.
	*/
	
	/* We take our origin, if we're flipped, our origin is in the top-left corner.  We need to use our bottom-left corner
		Then:
			1. Convert the point to the window coordinates (base coordinates)
			2. Convert that point from base to screen
			3. Wrap the result as an NSValue using -valueWithPoint:
	*/
	else if ([attribute isEqualToString: NSAccessibilityPositionAttribute]) {
		NSPoint localPoint = [self bounds].origin;
		if ([parent isFlipped]) {
			localPoint.y += [self bounds].size.height;
		}
		NSPoint windowPoint = [parent convertPoint:localPoint toView: nil];
		attributeValue =  [NSValue valueWithPoint:[[parent window] convertBaseToScreen:windowPoint]];;
		
	}
	
	/* Base (window) coordinate and screen coordinate sizes are the same so we can just:
		1. Convert from local coordinate system size to window coordinates
		2. Return as an NSValue using -valueWithSize:
	*/
	else if ([attribute isEqualToString: NSAccessibilitySizeAttribute]) {
		NSRect localBounds = [self bounds];
		attributeValue =  [NSValue valueWithSize:[parent convertSize:localBounds.size toView:nil]];
	}
	
	/* For our Window and Top Level UI Element, we can just return whatever our parent says */
	else if ([attribute isEqualToString: NSAccessibilityWindowAttribute]) {
		attributeValue =  [parent accessibilityAttributeValue:NSAccessibilityWindowAttribute];
	} 
	else if ([attribute isEqualToString: NSAccessibilityTopLevelUIElementAttribute]) {
		attributeValue =  [parent accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
	} 
	
	/* Our value is an integer, so create one basedon the value of hasHold */
	else if ([attribute isEqualToString: NSAccessibilityValueAttribute]) {
		attributeValue =  [NSNumber numberWithInt:hasHold ? 1 : 0];
	} 
	
	/* We are always enabled if we are showing, so return YES */
	else if ([attribute isEqualToString: NSAccessibilityEnabledAttribute]) {
		attributeValue =  [NSNumber numberWithBool:YES];
	} 
	
	/* We know if we have focus, so return that value as a bool */
	else if ([attribute isEqualToString: NSAccessibilityFocusedAttribute]) {
		attributeValue =  [NSNumber numberWithBool:hasFocus];
	} 
	
	/* We return no help */
	else if ([attribute isEqualToString: NSAccessibilityHelpAttribute]) {
		attributeValue =  @"";
	} 
		
	
	else if ([attribute isEqualToString: NSAccessibilityDescriptionAttribute]) {
		attributeValue =  [self dieDescriptionForAccessiblity];
	}

	return attributeValue;
}


/* Only focused and value attributes are settable*/
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
	if ([attribute isEqualToString: NSAccessibilityFocusedAttribute]) return YES;
    else if ([attribute isEqualToString: NSAccessibilityValueAttribute]) return YES;
	else return NO;
}

/* If someone tries to set the focused attribute we do the following: 
	Tell parent to set us as the focused die.
*/
- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
	if ([attribute isEqualToString: NSAccessibilityFocusedAttribute]) {
		if ([value boolValue]) {
			[[self parent] setFocusedDie: self];
		}
	}
	else if ([attribute isEqualToString: NSAccessibilityValueAttribute]) {
		if ([value boolValue] != hasHold) {
			[self toggleHold];
            [parent setNeedsDisplay: YES];
		}
	}
}


/* We only respond to one action AXPress */
-(NSArray *)accessibilityActionNames {
	static NSArray *actions;
	
	if (!actions) actions = [[NSArray alloc] initWithObjects: NSAccessibilityPressAction, nil];
	return actions;
}

/* Use convenience function to return standard localized description for action */
- (NSString *)accessibilityActionDescription:(NSString *)action {
	return NSAccessibilityActionDescription(action);
}

/* If we are asked to perform action we need to toggle ourselves and tell parent to redisplay */
- (void)accessibilityPerformAction:(NSString *)action {
	if ([action isEqualToString:NSAccessibilityPressAction]) {
		[self toggleHold];
		[parent setNeedsDisplay: YES];
	}
}

/* For both hit testing and focus testing, we return ourselves */
- (id)accessibilityHitTest:(NSPoint)point {
	return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
	return NSAccessibilityUnignoredAncestor(self);
}



@end
