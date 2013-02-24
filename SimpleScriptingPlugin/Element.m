/*

File: Element.m

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

#import "Element.h"
#import "scriptLog.h"

#include <sys/types.h>
#include <unistd.h>

@implementation Element



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
-(id) init {
	if ((self = [super init]) != nil) {
		static unsigned long gNameCounter = 1;
			/* call our unique id generator to make a new id */
		[self setUniqueID: [Element calculateNewUniqueID]];
			/* we use a global counter to generate unique names */
		[self setName: [NSString stringWithFormat:@"Untitled %d", gNameCounter++]];
	}
		/* I put the logging statement later after the initialization so we can see
		the uniqueID */
	SLOG(@"init element %@", [self uniqueID]);
	return self;
}

	/* standard deallocation of our members followed by superclass.
	nothing out of the ordinary here. */
- (void) dealloc {
	SLOG(@"dealloc element %@", [self uniqueID]);
	[uniqueID release];
	[container release];
	[containerProperty release];
	[name release];
	[super dealloc];
}



	/* calculateNewUniqueID returns a new unique id value that can be used
	to uniquely idenfity an scriptable object.  Our main concern here is that the
	id value be unique within our process AND that it is unique to the specific
	instance of our process (in case our application is re-launched for some reason
	while a script is running).
	
	To guarantee uniqueness within our UUID values are used as a part of id values.
	
	For convenience and ease of idenfification, I put the application's initials at the
	beginning of the id string.  */
+ (NSString *)calculateNewUniqueID {
	static pid_t gMyProcessID; /* unique id of our process */
	static BOOL gUniqueInited = NO; /* our element id generator */
	CFUUIDRef theUUID = CFUUIDCreate( kCFAllocatorDefault );
	CFStringRef theUUIDString = CFUUIDCreateString( kCFAllocatorDefault, theUUID );
	
		/* set up code for our id generator */
	if ( ! gUniqueInited ) {
		gMyProcessID = getpid(); /* guaranteed unique for our process, see man getpid */
		gUniqueInited = YES;
	}

		/* we'll return unique id values as strings composed of the process id followed
		by a unique count value.  see the man page for getpid for more info about process
		id values.  */
	NSString *theID = [NSString stringWithFormat:@"SSP-%d-%@", gMyProcessID, (NSString *)theUUIDString];
	CFRelease( theUUID );
	CFRelease( theUUIDString );
	SLOG(@"new unique id ='%@'", theID);
	return theID;
}



	/* standard setter and getter methods for the container and
	containerProperty slots.  The only thing that's unusual here is that
	we have lumped the setter functions together because we will always
	call them together. */
- (id)container {
	SLOG(@" of %@ as %@", [self uniqueID], container);
    return [[container retain] autorelease];
}

- (NSString *)containerProperty {
	SLOG(@" return  %@ as '%@'", [self uniqueID], containerProperty);
    return [[containerProperty retain] autorelease];
}

- (void)setContainer:(id)value andProperty:(NSString *)property {
	SLOG(@" of %@ to %@ and '%@'", [self uniqueID], [value class], property);
    if (container != value) {
        [container release];
        container = [value retain];
    }
    if (containerProperty != property) {
        [containerProperty release];
        containerProperty = [property copy];
    }
}




	/* standard setter and getter methods for the 'uniqueID' property
	nothing out of the ordinary here. */
- (NSString *)uniqueID {
    return [[uniqueID retain] autorelease];
}

- (void)setUniqueID:(NSString *)value {
	SLOG(@" of %@ to '%@'", [self uniqueID], value);
    if (uniqueID != value) {
        [uniqueID release];
        uniqueID = [value copy];
    }
}


	/* standard setter and getter methods for the 'name' property
	nothing out of the ordinary here. */
- (NSString *)name {
	SLOG(@" of %@ as '%@'", [self uniqueID], name);
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)value {
	SLOG(@" of %@ to '%@'", [self uniqueID], value);
    if (name != value) {
        [name release];
        name = [value copy];
    }
}


	/* calling objectSpecifier asks an object to return an object specifier
	record referring to itself.  You must call setContainer:andProperty: before
	you can call this method. */
- (NSScriptObjectSpecifier *)objectSpecifier {
	SLOG(@" of %@ ", [self uniqueID]);
	return [[NSUniqueIDSpecifier allocWithZone:[self zone]]
		initWithContainerClassDescription:(NSScriptClassDescription*) [[self container] classDescription]
			containerSpecifier:[[self container] objectSpecifier]
			key:[self containerProperty] uniqueID:[self uniqueID]];
}


@end
