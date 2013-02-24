/*
 
 File: AppCategory.h
 
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

#import <Cocoa/Cocoa.h>



@interface NSApplication (AppCategory)


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

/* return the entire list of trinkets */
- (NSArray *)trinkets;

/* insert a trinket at the beginning of the list */
- (void)insertInTrinkets:(id)trinket;

/* insert a trinket at some position in the list */
- (void)insertInTrinkets:(id)trinket atIndex:(unsigned)index;

/* remove a trinket from the list */
- (void)removeFromTrinketsAtIndex:(unsigned)index;




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

/* return the entire list of treasures */
- (NSArray *)treasures;

/* insert a treasure at the beginning of the list */
- (void)insertInTreasures:(id)treasure;

/* insert a treasure at some position in the list */
- (void)insertInTreasures:(id)treasure atIndex:(unsigned)index;

/* remove a treasure from the list */
- (void)removeFromTreasuresAtIndex:(unsigned)index;




/* kvc methods for the 'buckets' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of buckets inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'bucket', like so:
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
- (NSArray *)buckets;

/* insert a bucket at the beginning of the list */
- (void)insertInBuckets:(id)bucket;

/* insert a bucket at some position in the list */
- (void)insertInBuckets:(id)bucket atIndex:(unsigned)index;

/* remove a bucket from the list */
- (void)removeFromBucketsAtIndex:(unsigned)index;



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

/* return the entire list of strong boxes */
- (NSArray *)strongBoxes;

/* insert a strong box at the beginning of the list */
- (void)insertInStrongBoxes:(id)strongBox;

/* insert a strong box at some position in the list */
- (void)insertInStrongBoxes:(id)strongBox atIndex:(unsigned)index;

/* remove a strong box from the list */
- (void)removeFromStrongBoxesAtIndex:(unsigned)index;




/* since the application object will act as a container for other objects,
 and the objectSpecifier method on all of our objects that our application
 can contain will call the objectSpecifier method on it's container object
 we have provided an objectSpecifier method here.  The method on the application
 container object always returns nil to indicate that it is the root container
 object.   See the description of the objectSpecifier method in Element.h/m
 for more information. */
- (NSScriptObjectSpecifier *)objectSpecifier;




/* kvc method for the 'weight' AppleScript property.  Note that rather
 than simply returning a value, this method calculates its result by
 summing the weights of all of the trinkets, treasures, buckets,
 and strong boxes contained in the application.
 
 Also note, 'weight' is a declared as a read only property in our scripting
 definition file so we have not defined a 'setWeight:' method here.  */
- (NSNumber *)weight;



/* kvc method for the 'value' AppleScript property.  Here also rather
 than simply returning a value, this method calculates its result by
 summing the values of all of the treasures, buckets, and strong boxes
 contained in the application.  And, as with the 'weight' property,
 'value' is a declared as a read only property in our scripting
 definition file so we have not defined a 'setValue:' method here. */
- (NSNumber *)value;



@end
