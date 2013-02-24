/*

File: DCDiceView.m

Abstract: Dice View Implementation

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


@implementation DCDiceView


// Figure out the die sizes and locations, make DCDies, get background color
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {

		dice = [[NSMutableArray alloc] initWithCapacity: 5];
		
		float unit = frameRect.size.width / 4.0;
		float doubleUnit = unit * 2.0;
		
		int i, count = 5;
		DCDie *die = nil;
		for (i = 0; i < count; i++) {
			die = [[DCDie alloc] initWithBounds: NSMakeRect(unit, (3 * i + 1) * unit, doubleUnit, doubleUnit)];
			[die setParent: self]; // Accessiblity related
			[dice addObject: die];
	
			[die release];
		}
		
		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"greenfelt"]] retain];
		isCleared = YES;
		shouldDisplayFocus = NO;
		firstResponderIndex = -1;

	}
	return self;
}

-(void)dealloc {
	[dice release];
	[backgroundColor release];
	[super dealloc];
}

// Draw background and frame.  If not cleared, tell dice to draw.
- (void)drawRect:(NSRect)rect
{
	[backgroundColor set];
	NSRectFill(rect);
	
	[[NSColor blackColor] set];
	NSFrameRect(rect);

	if (!isCleared) {
		[dice makeObjectsPerformSelector:@selector(draw)];
	}

}

/* On mouse down, hit test the dice.  The mouse handling could be extended to handle tracking more like a standard button - but keeping things simple for this sample code */
-(void)mouseDown:(NSEvent *)event {
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView: nil];
	NSEnumerator *enumerator = [dice objectEnumerator];
	DCDie *die = nil;
	while (die = [enumerator nextObject]) {
		if ([die containsPoint: localPoint]) {
			[die toggleHold];
			[self setNeedsDisplay:YES];
		}
	}
}

/* If cleared return empty array.  If dice are showing return NSNumbers of the dice */
-(NSArray *)diceValues {
	if (isCleared) return [NSArray array];
	else return [dice valueForKeyPath:@"spotCount"];
}


-(IBAction)clear:(id)sender {
	[[self window] makeFirstResponder:[self nextValidKeyView]];
	isCleared = YES;
	[dice makeObjectsPerformSelector:@selector(clearFromView)];
	[self setNeedsDisplay:YES];
}

-(IBAction)rollDice:(id)sender {
	isCleared = NO;
	[dice makeObjectsPerformSelector:@selector(roll)];
	[self setNeedsDisplay:YES];
}



-(void)windowDidBecomeKey:(NSNotification *)note {
	shouldDisplayFocus = YES;
	[self setNeedsDisplay:YES];
}

-(void)windowDidResignKey:(NSNotification *)note {
	shouldDisplayFocus = NO;
	[self setNeedsDisplay:YES];
}


-(void)viewDidMoveToWindow {
	NSWindow *window = [self window];
	if (window) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:window];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	}
}


/* Need to enable full keyboard navigation for this NSView subclass.
*/
-(BOOL)acceptsFirstResponder {
	return !isCleared;
}

/* As we are asked to resign or become first responder, we need to manage
	which die within should have focus.
*/

-(BOOL)becomeFirstResponder {
	if (isCleared) {
		return NO;
	}
	
	if ([[self window] keyViewSelectionDirection] == NSDirectSelection) {
		if (firstResponderIndex == -1) {
			return NO;
		}
	} else if ([[self window] keyViewSelectionDirection] == NSSelectingNext) {
		firstResponderIndex = 4;

	} else {
		firstResponderIndex = 0;
	}
	
	[[dice objectAtIndex: firstResponderIndex] setFocus:YES];

	[self setNeedsDisplay:YES];

	return YES;
}

-(BOOL)resignFirstResponder {
	BOOL returnValue = YES;
	
	if ([[self window] keyViewSelectionDirection] == NSDirectSelection) {
		[[dice objectAtIndex: firstResponderIndex] setFocus:NO];
		firstResponderIndex = -1;
		returnValue = YES;
	} else if ([[self window] keyViewSelectionDirection] == NSSelectingNext) {
		if (firstResponderIndex == 0) {
			[[dice objectAtIndex: firstResponderIndex] setFocus:NO];
			firstResponderIndex = -1;
			returnValue = YES;
		}
		else {
			[[dice objectAtIndex: firstResponderIndex] setFocus:NO];
			[[dice objectAtIndex: --firstResponderIndex] setFocus:YES];
			returnValue = NO;
		}
	} else {
		if (firstResponderIndex == 4) {
			[[dice objectAtIndex: firstResponderIndex] setFocus:NO];
			firstResponderIndex = -1;
			returnValue = YES;
		}
		else {
			[[dice objectAtIndex: firstResponderIndex] setFocus:NO];
			[[dice objectAtIndex: ++firstResponderIndex] setFocus:YES];
			returnValue = NO;
		}
	}

	// If we respond NO, Cocoa doesn't know the focus has changed within us.  We need to send notification.
	if (returnValue == NO) NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);	// Accessibility Related
	[self setNeedsDisplay:YES];

	return returnValue;
}


/* Key events when first responder */

-(void)keyDown:(NSEvent *)event {
	// If the space bar was pressed, toggle hold on the first responder
	if ([[event characters] isEqualToString:@" "]) {
		[[dice objectAtIndex:firstResponderIndex] toggleHold];
		[self setNeedsDisplay:YES];
	} else {
		// We do care about our superclass dealing with tab shift-tab for first responder changes
		[super keyDown: event];
	}
}


-(BOOL)shouldDisplayFocus {
	return shouldDisplayFocus;
}


-(void)setFocusedDie:(DCDie *)die {
	if (die) {
		int index = [dice indexOfObject: die];
		if (index != NSNotFound) {
			// If we're already focused, unfocus current die
			if (firstResponderIndex != -1) {
				[[dice objectAtIndex:firstResponderIndex] setFocus:NO];
			}

			firstResponderIndex = index;
			[die setFocus: YES];
			[self setNeedsDisplay: YES];
			// Ask window to make us the first responder
			[[self window] makeFirstResponder: self];
		}
	}
}





@end
