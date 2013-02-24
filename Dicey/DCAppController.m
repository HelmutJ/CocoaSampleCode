/*

File: DCAppController.m

Abstract: Application Controller Implementation

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

#import "DCAppController.h"
#import "DCGame.h"
#import "DCDiceView.h"
#import "DCDie.h"

NSString * const DCGameDifficultyDefaultKey = @"DCGameDifficultyDefaultKey";


@implementation DCAppController


// Set up factory defaults for preferences.
+(void)initialize {
	NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:3] forKey:DCGameDifficultyDefaultKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
}


// For fun, make the icon in the Dock a random die roll every launch
-(void)setRandomDiceRollIcon {
	NSImage *iconImage = [[NSImage alloc] initWithSize:NSMakeSize(128.0, 128.0)];
	DCDie *die = [[DCDie alloc] initWithBounds:NSInsetRect(NSMakeRect(0.0, 0.0, 128.0, 128.0), 12.0, 12.0)];
	[die roll];
	[iconImage lockFocus];
	[die draw];
	[iconImage unlockFocus];
	[NSApp setApplicationIconImage:iconImage];
	[die release];
	[iconImage release];

}

- (void) setupSliderAccessibility {

	float sliderMinValue = [difficultySlider minValue];
	float sliderMaxValue = [difficultySlider maxValue];

	/* Make an array of the text field cells that are the labels of the slider.  Set that array as the label UI elements of the slider cell.  Remember that the cell is the unignored UI element exposed to assistive applications. */
	NSArray *labels = [NSArray arrayWithObjects: [difficultLabel cell], [normalLabel cell], [easyLabel cell], nil];
	[[difficultySlider cell] accessibilitySetOverrideValue:labels forAttribute:NSAccessibilityLabelUIElementsAttribute];
	
	/* For each text field cell, add a label value attribute with the corresponding value from the slider */
	[[difficultLabel cell] accessibilitySetOverrideValue:[NSNumber numberWithDouble: sliderMinValue] forAttribute:NSAccessibilityLabelValueAttribute];
	
	[[normalLabel cell] accessibilitySetOverrideValue:[NSNumber numberWithDouble: ((sliderMaxValue - sliderMinValue) / 2.0 + sliderMinValue)] forAttribute:NSAccessibilityLabelValueAttribute];

	[[easyLabel cell] accessibilitySetOverrideValue:[NSNumber numberWithDouble: sliderMaxValue] forAttribute:NSAccessibilityLabelValueAttribute];
}


-(void) awakeFromNib {
	[self setupSliderAccessibility];
	[self setRandomDiceRollIcon];
	[self newGame: self];
}

-(void)dealloc {
	[game release];
	[super dealloc];
}


/* Actions */

// Get the default rolls per turn
-(IBAction)newGame:(id)sender {
	NSNumber *defaultRollsPerTurn = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.DCGameDifficultyDefaultKey"];
	[self setGame: [[[DCGame alloc] initWithNumberOfRollsPerTurn:[defaultRollsPerTurn intValue]] autorelease]];
	[diceView clear:self];
}

-(IBAction)rollDice:(id)sender {
	[diceView rollDice:self];
	[game recordDiceRoll: [diceView diceValues]];
}

-(IBAction)scoreIt:(id)sender {
	int tag = [sender tag];
	[game recordScoreForScoreCategoryTag: tag];
	[diceView clear:self];
}

/* User Interface Validation */
-(BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)userInterfaceItem {
	if([userInterfaceItem action] == @selector(rollDice:) && ![game canRoll]) return NO;
	else return YES;
}


/* Accessors */
- (DCGame *)game {
    return [[game retain] autorelease];
}

- (void)setGame:(DCGame *)value {
    if (game != value) {
        [game release];
        game = [value retain];
    }
}



@end
