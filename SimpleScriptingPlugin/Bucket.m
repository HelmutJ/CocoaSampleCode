/*

File: Bucket.m

Abstract: declarations for the bucket container
class in this example application.  Buckets can
contain trinkets and treasures.

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

#import "Bucket.h"
#import "Trinket.h"
#import "Treasure.h"
#import "scriptLog.h"


@implementation Bucket


	/* after initializing our superclasses, we set the properties we're
	maintaining in this class to their default values.  Here I have chosen
	to initialize the label field to a unique string using a counter.
	
	See the description of the NSCreateCommand for more information about
	when your init method will be called.   */
-(id) init {
	if ((self = [super init]) != nil) {
		theTrinkets = [[NSMutableArray alloc] init];
		theTreasures = [[NSMutableArray alloc] init];
	}
		/* I put the logging statement later after the superclass was initialized
		so we will be able to report the uniqueID */
	SLOG(@"init bucket %@", [self uniqueID]);
	return self;
}


	/* standard deallocation of our members followed by superclass.
	nothing out of the ordinary here. */
- (void) dealloc {
	SLOG(@"dealloc bucket %@", [self uniqueID]);
	[theTrinkets release];
	[theTreasures release];
	[super dealloc];
}




	/* kvc method for the 'weight' AppleScript property.  Note that rather
	than simply returning a value, this method calculates its result by
	summing the weights of all of the trinkets and treasures contained
	in the bucket.
	
	Also note, 'weight' is a declared as a read only property in our scripting
	definition file so we have not defined a 'setWeight:' method here.  */
- (NSNumber *)weight {
	double totalWeight = 0.0;
	NSEnumerator *trinketEnumerator = [theTrinkets objectEnumerator];
	NSEnumerator *treasureEnumerator = [theTreasures objectEnumerator];
	Trinket* nthTrinket;
	Treasure* nthTreasure;
	NSNumber *theResult;
		/* sum the weights of all of the trinkets in the bucket */
	while ( (nthTrinket = (Trinket*) [trinketEnumerator nextObject]) != nil ) {
		totalWeight += [[nthTrinket weight] doubleValue];
	}
		/* sum the weights of all of the treasures in the bucket */
	while ( (nthTreasure = (Treasure*) [treasureEnumerator nextObject]) != nil ) {
		totalWeight += [[nthTreasure weight] doubleValue];
	}
		/* return the calculated weight */
	theResult = [NSNumber numberWithDouble:totalWeight]; 
	SLOG(@"weight of bucket %@ = %@", [self uniqueID], theResult);
	return theResult;
}



	/* kvc method for the 'value' AppleScript property.  Here also rather
	than simply returning a value, this method calculates its result by
	summing the values of all of the treasures contained in the bucket.
	And, as with the 'weight' property, 'value' is a declared as a read
	only property in our scripting definition file so we have not
	defined a 'setValue:' method here. */
- (NSNumber *)value {
	double totalValue = 0.0;
	NSEnumerator *treasureEnumerator = [theTreasures objectEnumerator];
	Treasure* nthTreasure;
	NSNumber *theResult;
		/* sum the values of all of the treasures in the bucket */
	while ( (nthTreasure = (Treasure*) [treasureEnumerator nextObject]) != nil ) {
		totalValue += [[nthTreasure value] doubleValue];
	}
	theResult = [NSNumber numberWithDouble:totalValue]; 
	SLOG(@"value of bucket %@ = %@", [self uniqueID], theResult);
	return theResult;
}




	/* kvc methods for the 'trinkets' AppleScript element.  Here we implement the methods
	necessary for maintaining the list of trinkets inside of a Bucket.  Note the names.
	I our scripting definition file we specified that the 'bucket' class contains an
	element of type 'trinket', like so:
		<element type="trinket"/>
	Cocoa will use the plural form of the class name, 'trinkets',  when naming the
	property used by AppleScript to access the list of buckets, and we should use
	the property name when naming our methods.  So, using the property name, we
	name our methods as follows:
		- (NSArray *)trinkets;
		- (void)insertInTrinkets:(id)trinket;
		- (void)insertInTrinkets:(id)trinket atIndex:(unsigned)index;
		- (void)removeFromTrinketsAtIndex:(unsigned)index;
	*/


	/* return the entire list of trinkets */
- (NSArray*)trinkets {
	SLOG(@"returning trinkets from a bucket %@", [self uniqueID]);
	return theTrinkets;
}



	/* insert a trinket at the beginning of the list */
- (void)insertInTrinkets:(id)trinket {
	SLOG(@"inserting trinket %@ into bucket %@", [((Trinket*)trinket) uniqueID], [self uniqueID]);
	[trinket setContainer:self andProperty:@"trinkets"];
	[theTrinkets insertObject:trinket atIndex:0];
}



	/* insert a trinket at some position in the list */
- (void)insertInTrinkets:(id)trinket atIndex:(unsigned)index {
	SLOG(@"insert trinket %@ at index %d into bucket %@", [((Trinket*)trinket) uniqueID], index, [self uniqueID]);
	[trinket setContainer:self andProperty:@"trinkets"];
	[theTrinkets insertObject:trinket atIndex:0];
}



	/* remove a trinket from the list */
- (void)removeFromTrinketsAtIndex:(unsigned)index {
	SLOG(@"removing trinket at %d from bucket %@", index, [self uniqueID]);
	[theTrinkets removeObjectAtIndex:index];
}





	/* kvc methods for the 'treasure' AppleScript element.  Here we implement the methods
	necessary for maintaining the list of trinkets inside of a Bucket.  Note the names.
	I our scripting definition file we specified that the 'bucket' class contains an
	element of type 'treasure', like so:
		<element type="treasure"/>
	Cocoa will use the plural form of the class name, 'treasures',  when naming the
	property used by AppleScript to access the list of buckets, and we should use
	the property name when naming our methods.  So, using the property name, we
	name our methods as follows:
		- (NSArray*) treasures;
		-(void) insertInTreasures:(id) treasure;
		-(void) insertInTreasures:(id) treasure atIndex:(unsigned)index;
		-(void) removeFromTreasuresAtIndex:(unsigned)index;
	*/


	/* return the entire list of treasures */
- (NSArray*) treasures {
	SLOG(@"returning treasures from a bucket %@", [self uniqueID]);
	return theTreasures;
}


	/* insert a treasure at the beginning of the list */
-(void) insertInTreasures:(id) treasure {
	SLOG(@"inserting treasure %@ into bucket %@", [((Treasure*)treasure) uniqueID], [self uniqueID]);
	[treasure setContainer:self andProperty:@"treasures"];
	[theTreasures insertObject:treasure atIndex:0];
}


	/* insert a treasure at some position in the list */
-(void) insertInTreasures:(id) treasure atIndex:(unsigned)index {
	SLOG(@"insert treasure %@ at index %d into bucket %@", [((Treasure*)treasure) uniqueID], index, [self uniqueID]);
	[treasure setContainer:self andProperty:@"treasures"];
	[theTreasures insertObject:treasure atIndex:0];
}


	/* remove a treasure from the list */
-(void) removeFromTreasuresAtIndex:(unsigned)index {
	SLOG(@"removing treasure at %d from bucket %@", index, [self uniqueID]);
	[theTreasures removeObjectAtIndex:index];
}

@end
