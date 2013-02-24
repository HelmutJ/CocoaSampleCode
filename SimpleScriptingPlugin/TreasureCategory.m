/*
 
 File: TreasureCategory.m
 
 Abstract: Implementation for the Treasure category provided
 by the scripting plugin.  This category is used to extend the scripting
 functionality of the host application's trinket class.
 
 Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved. 
 
 */



#import "TreasureCategory.h"
#import "scriptLog.h"


@implementation Treasure (ScriptingPlugin)




- (NSNumber *)valuable {
	
	NSNumber *result = [NSNumber numberWithBool:((([[self value] doubleValue] / [[self weight] doubleValue]) > 2.0) ? YES : NO)];

	SLOG(@"treasure category %@ property valuable %@", [self uniqueID], result);

    return result;
}



- (void)randomizeValueBetweenMinimum:(NSNumber *)minimum andMaximum:(NSNumber *)maximum {
	const double kMinimumTreasureValue = 0.0;
	const double kMaximumTreasureValue = 1000000.0;
	double minValue = (minimum ? [minimum doubleValue] : kMinimumTreasureValue);
	double maxValue = (maximum ? [maximum doubleValue] : kMaximumTreasureValue);
	double randomValue;
	
		/* calculate a random value between min and max */
	if ( minValue < maxValue ) {
		randomValue = minValue + fmod(fabs((double) random()), maxValue-minValue);
	} else {
		randomValue = minValue;
	}
	
		/* set the new weight */
	[self setValue:[NSNumber numberWithDouble:randomValue]];
}



-(void)setRandomValue:(NSScriptCommand *)command {
	NSDictionary *theArguments = [command evaluatedArguments];

		/* report the parameters */
	SLOG(@"\n - the direct parameter is: '%@'\n - other parameters are: %@", [command directParameter], theArguments);
	
		/* calculate the next value */
	NSNumber *lowValue = [theArguments objectForKey:@"LowestValue"];
	NSNumber *highValue = [theArguments objectForKey:@"HighestValue"];
	
		/* update the value */
	[self randomizeValueBetweenMinimum:lowValue andMaximum:highValue];
}



@end
