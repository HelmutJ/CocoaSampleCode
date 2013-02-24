/*
 
 File: PluginAppCategory.m
 
 Abstract: Implementation for the NSApplication category provided
 by the scripting plugin.  This category is used to extend the scripting
 functionality of the host application's application class.
 
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

#import "PluginAppCategory.h"
#import "AppCategory.h"
#import "Trinket.h"
#import "TrinketCategory.h"
#import "Treasure.h"
#import "TreasureCategory.h"
#import "Bucket.h"
#import "BucketCategory.h"
#import "StrongBox.h"
#import "StrongBoxCategory.h"
#import "scriptLog.h"

@implementation NSApplication (ScriptingPlugin)



/* kvc methods for the 'Mattresses' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of Mattresses inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'Mattress', like so:
 <element type="Mattress"/>
 Cocoa will use the plural form of the class name when naming the property used by
 AppleScript to access the list of Mattresses, and we should use the property name
 when naming our methods.  So, using the property name, we name our methods as follows:
 - (NSArray *)mattresses;
 - (void)insertInMattresses:(id)mattress;
 - (void)insertInMattresses:(id)mattress atIndex:(unsigned)index;
 - (void)removeFromMattressesAtIndex:(unsigned)index;
 
 */

/* our application items are implemented as a category of NSApplication so,
 as such, we don't have any instance variables for storing our application
 class' data.  So, we use globals for that storage.  */
NSMutableArray *gMattresses = nil;


	/* return the entire list of Mattresses */
- (NSArray *)mattresses {
	SLOG(@"return app's Mattresses");
		/* initial value */
	if ( gMattresses == nil ) {
		gMattresses = [[NSMutableArray alloc] init];
	}
	return gMattresses;
}

	/* insert a Mattress at the beginning of the list */
- (void)insertInMattresses:(id)mattress {
	SLOG(@"inserting Mattress %@ into app's Mattresses", [((Mattress*)mattress) uniqueID]);
	[mattress setContainer:self andProperty:@"mattresses"];
	if (gMattresses == nil) {
		gMattresses = [[NSMutableArray alloc] initWithObjects:mattress, nil];
	} else {
		[gMattresses insertObject:mattress atIndex:0];
	}
}

	/* insert a Mattress at some position in the list */
- (void) insertInMattresses:(id)mattress atIndex:(unsigned)index {
	SLOG(@"insert Mattress %@ at index %d into app's Mattresses", [((Mattress*)mattress) uniqueID], index);
	[mattress setContainer:self andProperty:@"mattresses"];
	if (gMattresses == nil) {
		gMattresses = [[NSMutableArray alloc] initWithObjects:mattress, nil];
	} else {
		[gMattresses insertObject:mattress atIndex:index];
	}
}

	/* remove a Mattress from the list */
- (void)removeFromMattressesAtIndex:(unsigned)index {
	SLOG(@"removing Mattress at %d from app's Mattresses", index);
	[gMattresses removeObjectAtIndex:index];
}




	/* return true if the value to weight ratio of all of the items in the app
	 is better than two to one.  Items hidden in mattresses are not counted.  */
- (NSNumber *)valuable {
	
	NSNumber *itemValue = [NSApp value];
	NSNumber *itemWeight = [NSApp weight];
	NSNumber *result = [NSNumber numberWithBool:((([itemValue doubleValue] / [itemWeight doubleValue]) > 2.0) ? YES : NO)];
	
	SLOG(@"valuable property plugin application category %@", result);
	
    return result;
}



	/* The following methods are called by Cocoa scripting in response
	 to the randomize weight and randomize value AppleScript commands when
	 they are sent to the application object. 
	 
	 Their effect is to randomize the weights and values of every item contained
	 in the application container, and inside of every container it contains.  */

- (void)setRandomWeight:(NSScriptCommand *)command {
	NSDictionary *theArguments = [command evaluatedArguments];
	
		/* report the parameters */
	SLOG(@"\n - the direct parameter is: '%@'\n - other parameters are: %@", [command directParameter], theArguments);
	
		/* calculate the bounds */
	NSNumber *lowWeight = [theArguments objectForKey:@"LowestWeight"];
	NSNumber *highWeight = [theArguments objectForKey:@"HighestWeight"];
	
		/* call the items in the application to randomize themselves
		 or the items they contain. */
	for ( Trinket *nthTrinket in [self trinkets] ) {
		[nthTrinket randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
	}
	for ( Treasure *nthTreasure in [self treasures] ) {
		[nthTreasure randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
	}
	for ( Bucket *nthBucket in [self buckets] ) {
		[nthBucket randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
	}
	for ( StrongBox *nthBucket in [self strongBoxes] ) {
		[nthBucket randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
	}
	for ( Mattress *nthMattress in [self mattresses] ) {
		[nthMattress randomizeWeightBetweenMinimum:lowWeight andMaximum:highWeight];
	}
}



- (void)setRandomValue:(NSScriptCommand *)command {
	NSDictionary *theArguments = [command evaluatedArguments];
	
		/* report the parameters */
	SLOG(@"\n - the direct parameter is: '%@'\n - other parameters are: %@", [command directParameter], theArguments);
	
		/* calculate the bounds */
	NSNumber *lowValue = [theArguments objectForKey:@"LowestValue"];
	NSNumber *highValue = [theArguments objectForKey:@"HighestValue"];
	
		/* call the items in the application to randomize themselves
		 or the items they contain. */
	for ( Treasure *nthTreasure in [self treasures] ) {
		[nthTreasure randomizeValueBetweenMinimum:lowValue andMaximum:highValue];
	}
	for ( Bucket *nthBucket in [self buckets] ) {
		[nthBucket randomizeValueBetweenMinimum:lowValue andMaximum:highValue];
	}
	for ( StrongBox *nthBucket in [self strongBoxes] ) {
		[nthBucket randomizeValueBetweenMinimum:lowValue andMaximum:highValue];
	}
	for ( Mattress *nthMattress in [self mattresses] ) {
		[nthMattress randomizeValueBetweenMinimum:lowValue andMaximum:highValue];
	}
}


@end
