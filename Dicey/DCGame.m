/*

File: DCGame.m

Abstract: Dice Game Implementation

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

#import "DCGame.h"
#import "DCDiceView.h"

#define NUMBER_OF_TURNS 13

#define UPPER_SECTION_BONUS_GOAL 63
#define UPPER_SECTION_BONUS_VALUE 35

NSString * const DCGameCategoryName = @"DCGameCategoryName";
NSString * const DCGameCategoryScore = @"DCGameCategoryScore";


NSString * const DCOnesScoreKey = @"DCOnesScoreKey";
NSString * const DCTwosScoreKey = @"DCTwosScoreKey";
NSString * const DCThreesScoreKey = @"DCThreesScoreKey";
NSString * const DCFoursScoreKey = @"DCFoursScoreKey";
NSString * const DCFivesScoreKey = @"DCFivesScoreKey";
NSString * const DCSixesScoreKey = @"DCSixesScoreKey";


NSString * const DCUpperSubtotalKey = @"DCUpperSubtotalKey";
NSString * const DCBonusKey = @"DCBonusKey";
NSString * const DCUpperTotalKey = @"DCUpperTotalKey";

NSString * const DCThreeOfAKindScoreKey = @"DCThreeOfAKindScoreKey";
NSString * const DCFourOfAKindScoreKey = @"DCFourOfAKindScoreKey";
NSString * const DCFullHouseScoreKey = @"DCFullHouseScoreKey";
NSString * const DCSmallStraightScoreKey = @"DCSmallStraightScoreKey";
NSString * const DCLargeStraightScoreKey = @"DCLargeStraightScoreKey";
NSString * const DCChanceScoreKey = @"DCChanceScoreKey";
NSString * const DCFiveOfAKindScoreKey = @"DCFiveOfAKindScoreKey";

NSString * const DCLowerSubtotalKey = @"DCLowerSubtotalKey";
NSString * const DCFiveOfAKindBonusKey = @"DCFiveOfAKindBonusKey";
NSString * const DCGrandTotalKey = @"DCGrandTotalKey";




@implementation DCGame


+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {

    NSSet* set = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"canRoll"]) {
        set = [set setByAddingObjectsFromSet:[NSSet setWithObjects:@"numberOfRollsRemaining", @"numberOfTurnsRemaining", nil]];
    } else if ([key isEqualToString:@"canScore"]) {
        set = [set setByAddingObject:@"numberOfTurnsRemaining"];
    } else if ([key isEqualToString:@"isGameOver"]) {
        set = [set setByAddingObject:@"numberOfTurnsRemaining"];
    }
    
    return set;
}

/* Method to convert the enum value used as a tag to the corresponding string constant */
-(NSString *)scoreKeyForScoreCategoryTag:(DCScoreCategoryTag)categoryTag {

	NSString *scoreCategoryKey = nil;
	switch(categoryTag) {
		case DCOnesScoreTag:
			scoreCategoryKey = DCOnesScoreKey;
			break;
			
		case DCTwosScoreTag:
			scoreCategoryKey = DCTwosScoreKey;
			break;

		case DCThreesScoreTag:
			scoreCategoryKey = DCThreesScoreKey;
			break;

		case DCFoursScoreTag:
			scoreCategoryKey = DCFoursScoreKey;
			break;
			
		case DCFivesScoreTag:
			scoreCategoryKey = DCFivesScoreKey;
			break;
			
		case DCSixesScoreTag:
			scoreCategoryKey = DCSixesScoreKey;
			break;
			
		case DCThreeOfAKindScoreTag:
			scoreCategoryKey = DCThreeOfAKindScoreKey;
			break;
			
		case DCFourOfAKindScoreTag:
			scoreCategoryKey = DCFourOfAKindScoreKey;
			break;
			
		case DCFullHouseScoreTag:
			scoreCategoryKey = DCFullHouseScoreKey;
			break;
			
		case DCSmallStraightScoreTag:
			scoreCategoryKey = DCSmallStraightScoreKey;
			break;
						
		case DCLargeStraightScoreTag:
			scoreCategoryKey = DCLargeStraightScoreKey;
			break;
			
		case DCChanceScoreTag:
			scoreCategoryKey = DCChanceScoreKey;
			break;
			
		case DCFiveOfAKindScoreTag:
			scoreCategoryKey = DCFiveOfAKindScoreKey;
			break;

		default:
			NSLog(@"Unknown Score Category Tag");
			break;
	}

	return scoreCategoryKey;

}

	
-(NSDictionary *)rollValues {

	if (![diceValues count]) return [NSMutableDictionary dictionary];

	NSMutableDictionary *rollScoreValues = [NSMutableDictionary dictionaryWithCapacity: 13];

	NSArray *sortedValues = [diceValues sortedArrayUsingSelector: @selector(compare:)];
	NSNumber *diceTotal = [diceValues valueForKeyPath:@"@sum.intValue"];
	NSCountedSet *countedSet = [[NSCountedSet alloc] initWithArray:sortedValues];
	
	BOOL hasThreeOfAKind = NO;
	BOOL hasFourOfAKind = NO;
	BOOL hasFiveOfAKind = NO;
	BOOL hasExactlyTwo = NO;
	BOOL hasExactlyThree = NO;
	// Check the number scores
	
	int i, count = 6;
	
	for (i = 1; i <= count; i++) {
		NSNumber *number = [NSNumber numberWithInt:i];
		int objectCount = [countedSet countForObject:number];
		NSString *key = [self scoreKeyForScoreCategoryTag: i];
		[rollScoreValues setObject: [NSNumber numberWithInt: (i * objectCount)] forKey: key];
		if (!hasThreeOfAKind && objectCount >= 3) hasThreeOfAKind = YES;
		if (!hasFourOfAKind && objectCount >= 4) hasFourOfAKind = YES;
		if (!hasFiveOfAKind && objectCount >= 5) hasFiveOfAKind = YES;
		if (!hasExactlyTwo && objectCount == 2) hasExactlyTwo = YES;
		if (!hasExactlyThree && objectCount == 3) hasExactlyThree = YES;
	}
    
    [countedSet release];
	
	if (hasThreeOfAKind) [rollScoreValues setObject: diceTotal forKey: DCThreeOfAKindScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCThreeOfAKindScoreKey];
	
	if (hasFourOfAKind) [rollScoreValues setObject: diceTotal forKey: DCFourOfAKindScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCFourOfAKindScoreKey];

	if (hasFiveOfAKind) [rollScoreValues setObject: [NSNumber numberWithInt:50] forKey: DCFiveOfAKindScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCFiveOfAKindScoreKey];
	
	if (hasExactlyTwo && hasExactlyThree) [rollScoreValues setObject: [NSNumber numberWithInt:25] forKey: DCFullHouseScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCFullHouseScoreKey];


	[rollScoreValues setValue: diceTotal forKey: DCChanceScoreKey];
	
	// Check for straights	
	unsigned int currentValue = 0;
	unsigned int lastValue = 743; // any number that will never be consecutive with 1 through 6
	unsigned int consecutiveNumberCount = 1;
	unsigned int maxConsecutiveNumberCount = 1;

	count = [sortedValues count];
	for (i = 0; i < count; i++) {
		currentValue = [[sortedValues objectAtIndex: i] unsignedIntValue];
		if (currentValue - 1 == lastValue) {
			consecutiveNumberCount++;
			maxConsecutiveNumberCount = MAX(maxConsecutiveNumberCount, consecutiveNumberCount);
		}
		else if (currentValue != lastValue) {
			consecutiveNumberCount = 1;
		}
		
		lastValue = currentValue;
	}
	
	if (maxConsecutiveNumberCount >= 4) [rollScoreValues setObject: [NSNumber numberWithInt:30] forKey: DCSmallStraightScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCSmallStraightScoreKey];
	
	if (maxConsecutiveNumberCount == 5) [rollScoreValues setObject: [NSNumber numberWithInt:40] forKey: DCLargeStraightScoreKey];
	else [rollScoreValues setObject: [NSNumber numberWithInt:0] forKey: DCLargeStraightScoreKey];	
	
	return rollScoreValues;
}




-(id) initWithNumberOfRollsPerTurn:(unsigned int) rolls {
	self = [super init];
	if (self) {
		numberOfRollsPerTurn = rolls;
		numberOfTurnsRemaining = NUMBER_OF_TURNS;
		numberOfRollsRemaining = numberOfRollsPerTurn;
		
		scoreValues = [[NSMutableDictionary alloc] initWithCapacity: 20];
		
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCUpperSubtotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCBonusKey];
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCUpperTotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCLowerSubtotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCFiveOfAKindBonusKey];
		[scoreValues setValue: [NSNumber numberWithInt: 0] forKey: DCGrandTotalKey];
		
	}
	return self;
}

-(void)dealloc {
	[scoreValues release];
	[super dealloc];
}



-(void)recordDiceRoll:(NSArray *)value {
    if (diceValues != value) {
        [diceValues release];
        diceValues = [value copy];
		[self willChangeValueForKey:@"rollValues"];
		[self willChangeValueForKey:@"numberOfRollsRemaining"];
		numberOfRollsRemaining--;
		[self didChangeValueForKey:@"numberOfRollsRemaining"];
[self rollValues];

		[self didChangeValueForKey:@"rollValues"];
    }
}


-(unsigned int)numberOfTurnsRemaining {
	return numberOfTurnsRemaining;
}


-(unsigned int)numberOfRollsRemaining {
	return numberOfRollsRemaining;
}


-(BOOL)canRoll {
	return (numberOfRollsRemaining > 0 && ![self isGameOver]);
}

-(BOOL)canScore {
	return numberOfTurnsRemaining > 0;
}

-(BOOL)isGameOver {
	return numberOfTurnsRemaining < 1;
}



-(void)recordScoreForScoreCategoryTag:(DCScoreCategoryTag)categoryTag
{
	BOOL isUpperSection = (categoryTag < DCThreeOfAKindScoreTag);
	NSString *scoreCategoryKey = [self scoreKeyForScoreCategoryTag:categoryTag];
	int addedScore = 0;

	[self willChangeValueForKey: @"scoreValues"];
	
	NSNumber *rollValue = [[self rollValues] valueForKey: scoreCategoryKey];
	[scoreValues setValue: rollValue forKey: scoreCategoryKey];
	addedScore = [rollValue intValue];
	
	if (isUpperSection) {
		NSNumber *subtotal = [scoreValues valueForKey: DCUpperSubtotalKey];
		int subtotalInt = [subtotal intValue];
		int newSubtotal = subtotalInt + addedScore;
		[scoreValues setValue: [NSNumber numberWithInt: newSubtotal] forKey: DCUpperSubtotalKey];
		
		if (subtotalInt < UPPER_SECTION_BONUS_GOAL && newSubtotal >= UPPER_SECTION_BONUS_GOAL) {
				[scoreValues setValue: [NSNumber numberWithInt:UPPER_SECTION_BONUS_VALUE] forKey: DCBonusKey];
				addedScore += UPPER_SECTION_BONUS_VALUE;
		}

		NSNumber *upperTotal = [scoreValues valueForKey: DCUpperTotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: [upperTotal intValue] + addedScore] forKey: DCUpperTotalKey];
		
	} else {
		NSNumber *lowerSubtotal = [scoreValues valueForKey: DCLowerSubtotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: [lowerSubtotal intValue] + addedScore] forKey: DCLowerSubtotalKey];
	}
	
	if(addedScore) {
		NSNumber *grandTotal = [scoreValues valueForKey: DCGrandTotalKey];
		[scoreValues setValue: [NSNumber numberWithInt: [grandTotal intValue] + addedScore] forKey: DCGrandTotalKey];
	}
	
	[self didChangeValueForKey: @"scoreValues"];

	[self willChangeValueForKey:@"numberOfTurnsRemaining"];
	numberOfTurnsRemaining--;
	[self didChangeValueForKey:@"numberOfTurnsRemaining"];
	
	[self willChangeValueForKey:@"numberOfRollsRemaining"];
	numberOfRollsRemaining = numberOfRollsPerTurn;
	[self didChangeValueForKey:@"numberOfRollsRemaining"];
	
	[self willChangeValueForKey:@"rollValues"];
	[diceValues release];
	diceValues = [[NSArray alloc] init];
	[self didChangeValueForKey:@"rollValues"];

}

- (NSDictionary *)scoreValues {
	return scoreValues;
}






@end
