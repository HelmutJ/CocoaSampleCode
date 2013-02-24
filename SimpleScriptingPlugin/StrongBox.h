/*

File: StrongBox.h

Abstract: declarations for the strong box container
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

#import <Cocoa/Cocoa.h>
#import "Bucket.h"


	/* The StrongBox class adds a new property to the Bucket and it is
	also a container for a list of buckets.
	
	Two points of interest in this class are the weight and value
	accessor methods that we use to implement the weight and value
	AppleScript properties.  These accessors implement read only
	properties and they return a calculated result reflecting the sum
	total of the weights of all of the items contained in the strong box.
	
	We take care of most of the 'infrastructure' type operations
	needed for scripting in the Element class (the superclass of the
	Trinket class), so all we have to worry about here is storage management
	and providing accessors for the properties.*/
@interface StrongBox : Bucket {
	NSString *label;
	NSMutableArray *theBuckets;
}

	/* storage management */
-(id) init;
- (void) dealloc;

	/* kvc method for the 'weight' AppleScript property.  Note that here we
	are providing a specialization of the weight method provided by the Bucket
	class.  We do this because when calculating the weight of all of the objects
	in the strong box, we want to include the total weight of all of the buckets
	it contains, so we perform that extra calculation in this specialization.
	
	Also note, 'weight' is a declared as a read only property in our scripting
	definition file so we have not defined a 'setWeight:' method here.  */
- (NSNumber *)weight;

	/* kvc method for the 'value' AppleScript property.  Here we are also
	providing a specialization of the weight method provided by the Bucket class
	for exactly the same reasons: to factor in the value of all of the buckets
	contained in the strong box.  And, as with the 'weight' property, 'value' is
	a declared as a read only property in our scripting definition file so
	we have not defined a 'setValue:' method here. */
- (NSNumber *)value;


	/* kvc methods for the 'label' AppleScript property */
- (NSString *)label;
- (void)setLabel:(NSString *)value;


	/* kvc methods for the 'buckets' AppleScript element.  Here we implement the methods
	necessary for maintaining the list of buckets inside of a StrongBox.  Note the names.
	I our scripting definition file we specified that the 'strong box' class contains an
	element of type 'bucket', like so:
		<element type="bucket"/>
	Cocoa will use the plural form of the class name when naming the property used by
	AppleScript to access the list of buckets, and we should use the property name
	when naming our methods.  So, using the property name, we name our methods as follows:
		- (NSArray*) buckets;
		-(void) insertInBuckets:(id) bucket;
		-(void) insertInBuckets:(id) bucket atIndex:(unsigned)index;
		-(void) removeFromBucketsAtIndex:(unsigned)index;
			
	*/
	
	/* return the entire list of buckets */
- (NSArray*) buckets;

	/* insert a bucket at the beginning of the list */
-(void) insertInBuckets:(id) bucket;

	/* insert a bucket at some position in the list */
-(void) insertInBuckets:(id) bucket atIndex:(unsigned)index;

	/* remove a bucket from the list */
-(void) removeFromBucketsAtIndex:(unsigned)index;



/*
Note that if we had wanted to use a different name in our Objective-C code as our
property accessor, say, 'bucketsInStrongBox', then we would have specified that
in our scripting definition file with an element declaration such as:
		<element type="bucket">
			<cocoa key="bucketsInStrongBox"/>
		</element>
and then we would have named our methods for maintaining the list of buckets like so:
	- (NSArray*) bucketsInStrongBox;
	-(void) insertInBucketsInStrongBox:(id) bucket;
	-(void) insertInBucketsInStrongBox:(id) bucket atIndex:(unsigned)index;
	-(void) removeFromBucketsInStrongBoxAtIndex:(unsigned)index;
*/

@end
