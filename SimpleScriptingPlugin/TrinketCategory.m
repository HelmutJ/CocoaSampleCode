/*
 
 File: TrinketCategory.m
 
 Abstract: Implementation for the Trinket category provided
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

#import "TrinketCategory.h"
#import "scriptLog.h"
#include <stdlib.h>


@implementation Trinket (ScriptingPlugin)


- (NSNumber *)valuable {
	SLOG(@"trinket category %@ property valuable %@", [self uniqueID], [NSNumber numberWithBool:NO]);
    return [NSNumber numberWithBool:NO];
}



- (void)randomizeWeightBetweenMinimum:(NSNumber *)minimum andMaximum:(NSNumber *)maximum {
	const double kMinimumTinketWeight = 0.0;
	const double kMaximumTinketWeight = 100000.0;
	double minWeight = (minimum ? [minimum doubleValue] : kMinimumTinketWeight);
	double maxWeight = (maximum ? [maximum doubleValue] : kMaximumTinketWeight);
	double randomValue;
	
		/* calculate a random value between min and max */
	if ( minWeight < maxWeight ) {
		randomValue = minWeight + fmod(fabs((double) random()), maxWeight-minWeight);
	} else {
		randomValue = minWeight;
	}
	
		/* set the new weight */
	[self setWeight:[NSNumber numberWithDouble:randomValue]];
}



-(void)setRandomWeight:(NSScriptCommand *)command {
	NSDictionary *theArguments = [command evaluatedArguments];
	
		/* report the parameters */
	SLOG(@"\n - the direct parameter is: '%@'\n - other parameters are: %@", [command directParameter], theArguments);
	
		/* calculate the next value */
	NSNumber *lowWeight = [theArguments objectForKey:@"LowestWeight"];
	NSNumber *highWeight = [theArguments objectForKey:@"HighestWeight"];
	
		/* update the value */
	[self randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
}



@end
