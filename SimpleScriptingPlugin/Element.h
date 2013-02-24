/*

File: Element.h

Abstract: root class for the scriptable objects in this sample.
This base class is used in both the main application and in
the scripting plugin.
 

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


	/* The Element class is the root class for all of the AppleScript
	objects we provide in our application.
	
	It is in this class that take care of most of the 'infrastructure'
	type operations needed for maintaining our objects.  In our application
	we assume that all of our objects will have a 'name' property and an
	'id' property and we maintain those properties in this class.
	
	Given that's taken care of here, we implement the objectSpecifier method
	based on the id property.  By doing that here, we don't have to worry about
	implementing an objectSpecifier method in any of our other sub-classes.
	
	For most intentions and purposes, you should be able to use this class
	unmodified as a superclass for your own scriptable objects.  
	*/
@interface Element : NSObject {
		/* the following two fields are used in calculating the objectSpecifier
		for this object.  To do that, we maintain a reference to the containing
		object (container) and the name of the Cocoa key (containerProperty) on
		that container where our instance is being stored.  For example, the Bucket
		class contains a list of 'trinket' objects in it.  A trinket contained in
		an instance of the Bucket class would retain a reference to the Bucket object
		it is stored in along with the name of the Cocoa key ('trinkets') being used
		to reference the list of trinkets inside of that Bucket. */
	id container; /* reference to the object containing this object */
	NSString* containerProperty; /* name of the cocoa key on container specifying the 
	                               list property where this object is stored */
	
		/* storage for our id and name AppleScript properties. */
	NSString* uniqueID; /* a unique id value for this object */
	NSString* name; /* the name property for this object */
}

	/* storage management
	
	The normal sequence of events when an object is created is as follows:
	
	1. an AppleScript 'make' command will allocate and initialize an instance
	of the class it has been asked to create.  For example, it may create a Trinket.
	
	2. then it will call the insertInXXXXX: insertInXXXXX:atIndex: method on the container
	object where the new object will be stored.  For example, if we were being asked
	to create a Trinket in a Bucket, then the make command would create an instance
	of Trinket and then it would call insertInTrinkets: on the Bucket object.
	
	3. Inside of the insertInXXXXX: or insertInXXXXX:atIndex: you must record the
	parent object and the parent's property key for the new object being created so
	you can create a objectSpecifier later.  In this class, we have defined the
	setContainer:andProperty: for that purpose.  For example, inside of our
	insertInTrinkets: method on our Bucket object, we the setContainer:andProperty:
	method on the trinket object like so:
	   [trinket setContainer:self andProperty:@"trinkets"]
	to inform the trinket object who its container is and the name of the Cocoa key
	on that container object used for the list of trinkets.
	*/
-(id) init;
- (void) dealloc;


	/* ensuring that the id values we are using for unique ids are unique
	is essential go good operation.  Here we provide a class method to vend
	unique id values for use with our objects.  */
+ (NSString *)calculateNewUniqueID;


	/* accessor methods for the container and containerProperty fields. */
- (id)container;
- (NSString *)containerProperty;


	/* since the container and containerProperty fields are always set at the
	same time, we have lumped those setter calls together into one call that
	sets both. */
- (void)setContainer:(id)value andProperty:(NSString *)property;


	/* kvc methods for the 'id' AppleScript property */
- (NSString *)uniqueID;
- (void)setUniqueID:(NSString *)value;

	/* kvc methods for the 'name' AppleScript property */
- (NSString*) name;
- (void) setName:(NSString*) name;

	/* calling objectSpecifier asks an object to return an object specifier
	record referring to itself.  You must call setContainer:andProperty: before
	you can call this method.   see the explanation above. 
	
	Note: this routine assumes you have added a objectSpecifier method to
	a category of NSApplication that always returns nil (the default value
	for the application class).  */
- (NSScriptObjectSpecifier *)objectSpecifier;


@end
