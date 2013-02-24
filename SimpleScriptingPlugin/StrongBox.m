/*

File: StrongBox.m

Abstract: implementation of the strong box container
class in this example application.  Strong boxes are
a subclass of Buckets and they can contain trinkets,
treasures, and buckets.

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

#import "StrongBox.h"
#import "scriptLog.h"


@implementation StrongBox


	/* after initializing our superclasses, we set the properties we're
	maintaining in this class to their default values.  Here I have chosen
	to initialize the label field to a unique string using a counter.
	
	See the description of the NSCreateCommand for more information about
	when your init method will be called.   */
-(id) init {
	if ((self = [super init]) != nil) {
		static unsigned long gLabelCounter = 1;
		theBuckets = [[NSMutableArray alloc] init];
		[self setLabel: [NSString stringWithFormat:@"Label %d", gLabelCounter++]];
	}
	SLOG(@"init strong box %@", [self uniqueID]);
	return self;
}


	/* standard deallocation of our members followed by superclass.
	nothing out of the ordinary here. */
- (void) dealloc {
	SLOG(@"dealloc strong box %@", [self uniqueID]);
	[theBuckets release];
	[label release];
	[super dealloc];
}





	/* standard setter and getter methods for the 'label' property
	nothing out of the ordinary here.  */
- (NSString *)label {
    return [[label retain] autorelease];
}

- (void)setLabel:(NSString *)value {
    if (label != value) {
        [label release];
        label = [value copy];
    }
}




	/* kvc method for the 'weight' AppleScript property.  Note that here we
	are providing a specialization of the weight method provided by the Bucket
	class.  We do this because when calculating the weight of all of the objects
	in the strong box, we want to include the total weight of all of the buckets
	it contains, so we perform that extra calculation in this specialization.
	
	Also note, 'weight' is a declared as a read only property in our scripting
	definition file so we have not defined a 'setWeight:' method here.  */
- (NSNumber *)weight {
		 /* call superclass to sum weights of treasures and trinkets */
	double totalWeight = [[super weight] doubleValue];
	NSEnumerator *bucketEnumerator = [theBuckets objectEnumerator];
	Bucket* nthBucket;
	NSNumber *theResult;
		/* sum the weights of all of the buckets in the strong box */
	while ( (nthBucket = (Bucket*) [bucketEnumerator nextObject]) != nil ) {
		totalWeight += [[nthBucket weight] doubleValue];
	}
		/* return the calculated weight */
	theResult = [NSNumber numberWithDouble:totalWeight]; 
	SLOG(@"weight of strong box %@ = %@", [self uniqueID], theResult);
	return theResult;
}




	/* kvc method for the 'value' AppleScript property.  Here we are also
	providing a specialization of the weight method provided by the Bucket class
	for exactly the same reasons: to factor in the value of all of the buckets
	contained in the strong box.
	
	And, as with the 'weight' property, 'value' is a declared as a read only
	property in our scripting definition file so we have not defined a
	'setValue:' method here. */
- (NSNumber *)value {
		 /* call superclass to sum values of treasures */
	double totalValue = [[super value] doubleValue];
	NSEnumerator *bucketEnumerator = [theBuckets objectEnumerator];
	Bucket* nthBucket;
	NSNumber *theResult;
		/* sum the values of all of the buckets in the strong box */
	while ( (nthBucket = (Bucket*) [bucketEnumerator nextObject]) != nil ) {
		totalValue += [[nthBucket value] doubleValue];
	}
		/* return the calculated value */
	theResult = [NSNumber numberWithDouble:totalValue]; 
	SLOG(@"value of strong box %@ = %@", [self uniqueID], theResult);
	return theResult;
}



	/* return the entire list of Bucket objects */
- (NSArray*) buckets {
	SLOG(@"strong box %@", [self uniqueID]);
	return theBuckets;
}


	/* insert a bucket at the beginning of the list */
-(void) insertInBuckets:(id) bucket {
	SLOG(@"bucket %@ into strong box %@", [((Bucket*)bucket) uniqueID], [self uniqueID]);
	[bucket setContainer:self andProperty:@"buckets"];
	[theBuckets insertObject:bucket atIndex:0];
}


	/* insert a bucket at some position in the list */
-(void) insertInBuckets:(id) bucket atIndex:(unsigned)index {
	SLOG(@"bucket %@ at index %d into strong box %@", [((Bucket*)bucket) uniqueID], index, [self uniqueID]);
	[bucket setContainer:self andProperty:@"buckets"];
	[theBuckets insertObject:bucket atIndex:0];
}


	/* remove a bucket from the list */
-(void) removeFromBucketsAtIndex:(unsigned)index {
	SLOG(@"removing bucket at %d from strong box %@", index, [self uniqueID]);
	[theBuckets removeObjectAtIndex:index];
}

@end
