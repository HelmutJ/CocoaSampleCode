/*

File: DCGame.h

Abstract: Dice Game Interface

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

#import <Cocoa/Cocoa.h>

enum {
	DCOnesScoreTag = 1,
	DCTwosScoreTag,
	DCThreesScoreTag,
	DCFoursScoreTag,
	DCFivesScoreTag,
	DCSixesScoreTag,
	DCThreeOfAKindScoreTag,
	DCFourOfAKindScoreTag,
	DCFullHouseScoreTag,
	DCSmallStraightScoreTag,
	DCLargeStraightScoreTag,
	DCChanceScoreTag,
	DCFiveOfAKindScoreTag,
};

typedef unsigned int DCScoreCategoryTag;


extern NSString * const DCOnesScoreKey;
extern NSString * const DCTwosScoreKey;
extern NSString * const DCThreesScoreKey;
extern NSString * const DCFoursScoreKey;
extern NSString * const DCFivesScoreKey;
extern NSString * const DCSixesScoreKey;

extern NSString * const DCUpperSubtotalKey;
extern NSString * const DCBonusKey;
extern NSString * const DCUpperTotalKey;

extern NSString * const DCThreeOfAKindScoreKey;
extern NSString * const DCFourOfAKindScoreKey;
extern NSString * const DCFullHouseScoreKey;
extern NSString * const DCSmallStraightScoreKey;
extern NSString * const DCLargeStraightScoreKey;
extern NSString * const DCChanceScoreKey;
extern NSString * const DCFiveOfAKindScoreKey;

extern NSString * const DCLowerSubtotalKey;
extern NSString * const DCFiveOfAKindBonusKey;
extern NSString * const DCGrandTotalKey;



@interface DCGame : NSObject {

	unsigned int numberOfRollsPerTurn;
	unsigned int numberOfTurnsRemaining;
	unsigned int numberOfRollsRemaining;
	
	NSMutableDictionary *scoreValues;

	NSArray *diceValues;
}

-(id) initWithNumberOfRollsPerTurn:(unsigned int) rolls;

/* Game actions */

-(void)recordDiceRoll:(NSArray *)value;
-(void)recordScoreForScoreCategoryTag:(DCScoreCategoryTag)categoryTag;

/* Current game information */
-(unsigned int)numberOfTurnsRemaining;
-(unsigned int)numberOfRollsRemaining;
-(BOOL)canRoll;
-(BOOL)canScore;
-(BOOL)isGameOver;

/* Dictionaries of scoring information.  The keys are the constant strings such as DCOnesScoreKey.  The values are NSNumbers with the score value for that key.  These are bound to the appropriate text fields in the nib file */
- (NSDictionary *)scoreValues;
- (NSDictionary *)rollValues;




@end
