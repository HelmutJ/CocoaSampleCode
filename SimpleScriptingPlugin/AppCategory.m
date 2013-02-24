/*
 
 File: AppCategory.m
 
 Abstract: a category of NSApplication where we
 implement all of our application objects properties
 and elements.
 
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

#import "AppCategory.h"
#import "scriptLog.h"

#import "Trinket.h"
#import "Treasure.h"
#import "Bucket.h"
#import "StrongBox.h"



@implementation NSApplication (AppCategory)




/* kvc methods for the 'trinkets' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of trinkets inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'trinket', like so:
 <element type="trinket"/>
 Cocoa will use the plural form of the class name, 'trinkets',  when naming the
 property used by AppleScript to access the list of buckets, and we should use
 the property name when naming our methods.  So, using the property name, we
 name our methods as follows:
 - (NSArray*) trinkets;
 -(void) insertInTrinkets:(id) trinket;
 -(void) insertInTrinkets:(id) trinket atIndex:(unsigned)index;
 -(void) removeFromTrinketsAtIndex:(unsigned)index;
 */

/* our application items are implemented as a category of NSApplication so,
 as such, we don't have any instance variables for storing our application
 class' data.  So, we use globals for that storage.  */
NSMutableArray *gTrinkets = nil;


/* return the entire list of trinkets */
- (NSArray *)trinkets {
	SLOG(@"return app's trinkets");
		/* initial value */
	if ( nil == gTrinkets ) {
		gTrinkets = [[NSMutableArray alloc] init];
	}
	return gTrinkets;
}

/* insert a trinket at the beginning of the list */
- (void)insertInTrinkets:(id)trinket {
	SLOG(@"inserting trinket %@ into bucket app's trinkets", [((Trinket *)trinket) uniqueID]);
	[trinket setContainer:self andProperty:@"trinkets"];
	if ( nil == gTrinkets ) {
		gTrinkets = [[NSMutableArray alloc] initWithObjects:trinket, nil];
	} else {
		[gTrinkets insertObject:trinket atIndex:0];
	}
}

/* insert a trinket at some position in the list */
- (void)insertInTrinkets:(id)trinket atIndex:(unsigned)index {
	SLOG(@"insert trinket %@ at index %d into app's trinkets", [((Trinket *)trinket) uniqueID], index);
	[trinket setContainer:self andProperty:@"trinkets"];
	if ( nil == gTrinkets ) {
		gTrinkets = [[NSMutableArray alloc] initWithObjects:trinket, nil];
	} else {
		[gTrinkets insertObject:trinket atIndex:0];
	}
}

/* remove a trinket from the list */
- (void)removeFromTrinketsAtIndex:(unsigned)index {
	SLOG(@"removing trinket at %d from app's trinkets", index);
	[gTrinkets removeObjectAtIndex:index];
}





/* kvc methods for the 'treasures' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of treasures inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'treasure', like so:
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


/* our application items are implemented as a category of NSApplication so,
 as such, we don't have any instance variables for storing our application
 class' data.  So, we use globals for that storage.  */
NSMutableArray *gTreasures = nil;


/* return the entire list of treasures */
- (NSArray *)treasures {
	SLOG(@"return app's treasures");
		/* initial value */
	if ( nil == gTreasures ) {
		gTreasures = [[NSMutableArray alloc] init];
	}
	return gTreasures;
}

/* insert a treasure at the beginning of the list */
- (void)insertInTreasures:(id)treasure {
	SLOG(@"inserting treasure %@ into app's treasures", [((Treasure *)treasure) uniqueID]);
	[treasure setContainer:self andProperty:@"treasures"];
	if ( nil == gTreasures ) {
		gTreasures = [[NSMutableArray alloc] initWithObjects:treasure, nil];
	} else {
		[gTreasures insertObject:treasure atIndex:0];
	}
}

/* insert a treasure at some position in the list */
- (void)insertInTreasures:(id)treasure atIndex:(unsigned)index {
	SLOG(@"insert treasure %@ at index %d into app's treasures", [((Treasure *)treasure) uniqueID], index);
	[treasure setContainer:self andProperty:@"treasures"];
	if ( nil == gTreasures ) {
		gTreasures = [[NSMutableArray alloc] initWithObjects:treasure, nil];
	} else {
		[gTreasures insertObject:treasure atIndex:index];
	}
}

/* remove a treasure from the list */
- (void)removeFromTreasuresAtIndex:(unsigned)index {
	SLOG(@"removing treasure at %d from app's treasures", index);
	[gTreasures removeObjectAtIndex:index];
}



/* kvc methods for the 'buckets' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of buckets inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'bucket', like so:
 <element type="bucket"/>
 Cocoa will use the plural form of the class name when naming the property used by
 AppleScript to access the list of buckets, and we should use the property name
 when naming our methods.  So, using the property name, we name our methods as follows:
 - (NSArray *)buckets;
 - (void)insertInBuckets:(id)bucket;
 - (void)insertInBuckets:(id)bucket atIndex:(unsigned)index;
 - (void)removeFromBucketsAtIndex:(unsigned)index;
 
 */

/* our application items are implemented as a category of NSApplication so,
 as such, we don't have any instance variables for storing our application
 class' data.  So, we use globals for that storage.  */
NSMutableArray *gBuckets = nil;


/* return the entire list of buckets */
- (NSArray *)buckets {
	SLOG(@"return app's buckets");
		/* initial value */
	if ( nil == gBuckets ) {
		gBuckets = [[NSMutableArray alloc] init];
	}
	return gBuckets;
}

/* insert a bucket at the beginning of the list */
- (void)insertInBuckets:(id)bucket {
	SLOG(@"inserting bucket %@ into app's buckets", [((Bucket *)bucket) uniqueID]);
	[bucket setContainer:self andProperty:@"buckets"];
	if ( nil == gBuckets ) {
		gBuckets = [[NSMutableArray alloc] initWithObjects:bucket, nil];
	} else {
		[gBuckets insertObject:bucket atIndex:0];
	}
}

/* insert a bucket at some position in the list */
- (void)insertInBuckets:(id)bucket atIndex:(unsigned)index {
	SLOG(@"insert bucket %@ at index %d into app's buckets", [((Bucket *)bucket) uniqueID], index);
	[bucket setContainer:self andProperty:@"buckets"];
	if ( nil == gBuckets ) {
		gBuckets = [[NSMutableArray alloc] initWithObjects:bucket, nil];
	} else {
		[gBuckets insertObject:bucket atIndex:index];
	}
}

/* remove a bucket from the list */
- (void)removeFromBucketsAtIndex:(unsigned)index {
	SLOG(@"removing bucket at %d from app's buckets", index);
	[gBuckets removeObjectAtIndex:index];
}





/* kvc methods for the 'strong boxes' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of strong boxes inside of the application container.
 Note the names. In our scripting definition file we specified that the 'strong box'
 class contains an element of type 'strong box', like so:
 <element type="strong box">
 <cocoa key="strongBoxes"/>
 </element>
 But, in our class definition of 'strong box' we have specified an irregular plural form
 for the class name:
 <class name="strong box" plural="strong boxes" code="ScOS" inherits="bucket"
 description="An object that can contain other objects.">
 This makes sense, because simply slapping an 's' on the end of our class name won't
 produce the correct plural form for our class (ie, 'strong boxes') and we would like
 the user to see a proper spelling.
 
 But, now, since we have provided our own plural form, exactly what Cocoa key should
 be used becomes ambiguous.  So, what we have done is explicitly called out the Cocoa
 key we are going to use for our collection of strong boxes inside of our element
 declaration inside of our application class object (see above).   With that in place,
 we can define our accessor methods using the key strongBoxes and normal kvc conventions:
 */

/* our application items are implemented as a category of NSApplication so,
 as such, we don't have any instance variables for storing our application
 class' data.  So, we use globals for that storage.  */
NSMutableArray *gStrongBoxes = nil;

/* return the entire list of strong boxes */
- (NSArray *)strongBoxes {
	SLOG(@"return app's strong boxes");
		/* initial value */
	if ( nil == gStrongBoxes ) {
		gStrongBoxes = [[NSMutableArray alloc] init];
	}
	return gStrongBoxes;
}

/* insert a strong box at the beginning of the list */
- (void)insertInStrongBoxes:(id)strongBox {
	SLOG(@"inserting strong box %@ into app's strong boxes", [((StrongBox *)strongBox) uniqueID]);
	[strongBox setContainer:self andProperty:@"strongBoxes"];
	if ( nil == gStrongBoxes ) {
		gStrongBoxes = [[NSMutableArray alloc] initWithObjects:strongBox, nil];
	} else {
		[gStrongBoxes insertObject:strongBox atIndex:0];
	}
}

/* insert a strong box at some position in the list */
- (void)insertInStrongBoxes:(id)strongBox atIndex:(unsigned)index {
	SLOG(@"insert strong box %@ at index %d into app's strong boxes", [((StrongBox *)strongBox) uniqueID], index);
	[strongBox setContainer:self andProperty:@"strongBoxes"];
	if ( nil == gStrongBoxes ) {
		gStrongBoxes = [[NSMutableArray alloc] initWithObjects:strongBox, nil];
	} else {
		[gStrongBoxes insertObject:strongBox atIndex:index];
	}
}

/* remove a strong box from the list */
- (void)removeFromStrongBoxesAtIndex:(unsigned)index {
	SLOG(@"removing strong box at %d from app's strong boxes", index);
	[gStrongBoxes removeObjectAtIndex:index];
}





/* since the application object will act as a container for other objects,
 and the objectSpecifier method on all of our objects that our application
 can contain will call the objectSpecifier method on it's container object
 we have provided an objectSpecifier method here.  The method on the application
 container object always returns nil to indicate that it is the root container
 object.   See the description of the objectSpecifier method in Element.h/m
 for more information. */
- (NSScriptObjectSpecifier *)objectSpecifier {
	SLOG(@"returning nil for NSApp's objectSpecifier");
	return nil;
}





/* kvc method for the 'weight' AppleScript property.  Note that rather
 than simply returning a value, this method calculates its result by
 summing the weights of all of the trinkets, treasures, buckets,
 and strong boxes contained in the application.
 
 Also note, 'weight' is a declared as a read only property in our scripting
 definition file so we have not defined a 'setWeight:' method here.  */
- (NSNumber *)weight {
	double totalWeight = 0.0;
	NSEnumerator *trinketEnumerator = [gTrinkets objectEnumerator];
	NSEnumerator *treasureEnumerator = [gTreasures objectEnumerator];
	NSEnumerator *bucketEnumerator = [gBuckets objectEnumerator];
	NSEnumerator *strongBoxEnumerator = [gStrongBoxes objectEnumerator];
	Trinket *nthTrinket;
	Treasure *nthTreasure;
	Bucket *nthBucket;
	StrongBox *nthStrongBox;
	NSNumber *theResult;
	/* sum the weights of all of the trinkets */
	while ( (nthTrinket = (Trinket *) [trinketEnumerator nextObject]) != nil ) {
		totalWeight += [[nthTrinket weight] doubleValue];
	}
	/* sum the weights of all of the treasures */
	while ( (nthTreasure = (Treasure *) [treasureEnumerator nextObject]) != nil ) {
		totalWeight += [[nthTreasure weight] doubleValue];
	}
	/* sum the weights of all of the buckets */
	while ( (nthBucket = (Bucket *) [bucketEnumerator nextObject]) != nil ) {
		totalWeight += [[nthBucket weight] doubleValue];
	}
	/* sum the weights of all of the strong boxes */
	while ( (nthStrongBox = (StrongBox *) [strongBoxEnumerator nextObject]) != nil ) {
		totalWeight += [[nthStrongBox weight] doubleValue];
	}
	/* return the calculated weight */
	theResult = [NSNumber numberWithDouble:totalWeight]; 
	SLOG(@"weight of all items in application = %@", theResult);
	return theResult;
}




/* kvc method for the 'value' AppleScript property.  Here also rather
 than simply returning a value, this method calculates its result by
 summing the values of all of the treasures, buckets, and strong boxes
 contained in the application.  And, as with the 'weight' property,
 'value' is a declared as a read only property in our scripting
 definition file so we have not defined a 'setValue:' method here. */
- (NSNumber *)value {
	double totalValue = 0.0;
	NSEnumerator *treasureEnumerator = [gTreasures objectEnumerator];
	NSEnumerator *bucketEnumerator = [gBuckets objectEnumerator];
	NSEnumerator *strongBoxEnumerator = [gStrongBoxes objectEnumerator];
	Treasure *nthTreasure;
	Bucket *nthBucket;
	StrongBox *nthStrongBox;
	NSNumber *theResult;
	/* sum the values of all of the treasures */
	while ( (nthTreasure = (Treasure *) [treasureEnumerator nextObject]) != nil ) {
		totalValue += [[nthTreasure value] doubleValue];
	}
	/* sum the values of all of the buckets */
	while ( (nthBucket = (Bucket *) [bucketEnumerator nextObject]) != nil ) {
		totalValue += [[nthBucket value] doubleValue];
	}
	/* sum the values of all of the strong boxes */
	while ( (nthStrongBox = (StrongBox *) [strongBoxEnumerator nextObject]) != nil ) {
		totalValue += [[nthStrongBox value] doubleValue];
	}
	theResult = [NSNumber numberWithDouble:totalValue]; 
	SLOG(@"value of all items in application = %@", theResult);
	return theResult;
}



@end
