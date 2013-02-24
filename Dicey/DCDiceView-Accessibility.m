/*

File: DCDiceView-Accessibility.m

Abstract: Accessibility implementation for dice view

Version: 1.0

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

#import "DCDiceView.h"
#import "DCDie.h"

@implementation DCDiceView (Accessibility)

/* Override accessibilityIsIgnored to return NO.
	See what you inherit for free from NSView */

-(BOOL)accessibilityIsIgnored {
	return NO;
}


/* Override the role attribute.  Note that the role description automatically updates.
*/

- (id)accessibilityAttributeValue:(NSString *)attribute {
	id attributeValue = nil;
	
	if ([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
		attributeValue = NSAccessibilityGroupRole;
	} 	
	
	/* For the children attribute.  If we are cleared, then we have zero children, return an empty array.
		If we are showing dice, return the unignored children of the dice.
	*/
	else if ([attribute isEqualToString: NSAccessibilityChildrenAttribute]) {
		if (isCleared) attributeValue = NSAccessibilityUnignoredChildren([NSArray array]);
		else attributeValue = NSAccessibilityUnignoredChildren(dice);
	} 
	
	else {
		attributeValue = [super accessibilityAttributeValue:attribute];
	}
	
	return attributeValue;
}

/* If this method is sent, it has been determined that the point is within our bounds.  So we hit test to see if the point hits any of our subelements.  If so, we send it the same message.  If not, we return ourself.  Note that the point is in screen coordinates.  We need to translate from screen to base (window) coordinates, and then from the window to local view coordinates.
	Also note that we pass the original point to our child.  Since we implement the same API in every object, the point passed to -accesibilityHitPoint: is always expected to be in screen coordinates.
*/
- (id)accessibilityHitTest:(NSPoint)point {
	id hitTestResult = self;

	if (!isCleared) {
		NSPoint windowPoint = [[self window] convertScreenToBase:point];
		NSPoint localPoint = [self convertPoint:windowPoint fromView: nil];
		NSEnumerator *enumerator = [dice objectEnumerator];
		DCDie *die = nil;
		DCDie *foundDie = nil;
		while (!foundDie && (die = [enumerator nextObject])) {
			if ([die containsPoint: localPoint]) {
				foundDie = die;
			}
		}
		if (foundDie) hitTestResult = [foundDie accessibilityHitTest:point];
	}
	return hitTestResult;
}


/* If this method has been called, it has already been determined that this object, or some subelement of this object, has the keyboard focus.  In this case we find the die that has the focus and pass the message along, returning the result we provide back.
*/
- (id)accessibilityFocusedUIElement {
	if (shouldDisplayFocus && [[self window] firstResponder] == self && firstResponderIndex != -1) {
		return [[dice objectAtIndex: firstResponderIndex] accessibilityFocusedUIElement];
	}
	else return self;
}








@end
