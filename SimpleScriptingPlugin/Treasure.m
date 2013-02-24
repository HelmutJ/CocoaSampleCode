/*

File: Treasure.m

Abstract: implementation of the treasure class
for this example application.  Treasure is a subclass
of the Trinket class and it has some additional
properties.

Trinkets and treasures provide us with objects to
put inside of the Bucket and StrongBox container
objects.

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

#import "Treasure.h"
#import "scriptLog.h"


@implementation Treasure


	/* after initializing our superclasses, we set the properties we're
	maintaining in this class to their default values.
	
	See the description of the NSCreateCommand for more information about
	when your init method will be called.  */
-(id) init {
	if ((self = [super init]) != nil) {
		itemValue = [[NSNumber alloc] initWithFloat:0.0];
		itemMetal = [[NSNumber alloc] initWithUnsignedLong:kTinMetal];
	}
		/* I put the logging statement later after the superclass was initialized
		so we will be able to report the uniqueID */
	SLOG(@"init treasure %@", [self uniqueID]);
	return self;
}

	/* standard deallocation of our members followed by superclass.
	nothing out of the ordinary here. */
- (void) dealloc {
	SLOG(@"del treasure %@", [self uniqueID]);
	[itemValue release];
	[itemMetal release];
	[super dealloc];
}


	/* We have implemented our 'metal' property as an
	AppleScript enumeration.  As such, each of the items in the
	enumeration is identified by a unique four character code
	stored in a long integer.
	decodeMetal converts the four character OSType stored
	in an unsigned long into a human readable string we can
	display in our logging.  */
+ (NSString*) decodeMetal:(NSNumber*) metal {
	NSString *metalName;
	switch ([metal unsignedLongValue]) {
		case kTinMetal: metalName = @"Tin"; break;
		case kPewterMetal: metalName = @"Pewter"; break;
		case kBronzeMetal: metalName = @"Bronze"; break;
		case kSilverMetal: metalName = @"Silver"; break;
		case kGoldMetal: metalName = @"Gold"; break;
		default: metalName = @"Unknown"; break;
	}
	return [NSString stringWithString:metalName];
}



	/* standard setter and getter methods for the 'value' property
	nothing out of the ordinary here. */
- (NSNumber *)value {
	SLOG(@"treasure %@ value = %@", [self uniqueID], itemValue);
    return [[itemValue retain] autorelease];
}

- (void)setValue:(NSNumber *)value {
	SLOG(@"set treasure %@ value to %@", [self uniqueID], value);
    if (itemValue != value) {
        [itemValue release];
        itemValue = [value copy];
    }
}


	/* standard setter and getter methods for the 'metal' property.
	Nothing out of the ordinary here, but, this time, the fact that
	there is nothing out of the ordinary is interesting in itself.
	Note that since the metal property is an enumeration and it's value
	is stored as a long integer inside of a NSNumber, we don't have to
	do anything special for managing that storage here - we treat it the
	same as any other numeric property.  */
- (NSNumber *)metal {
	SLOG(@"treasure %@ metal = %@", [self uniqueID], [Treasure decodeMetal:itemMetal]);
    return [[itemMetal retain] autorelease];
}

- (void)setMetal:(NSNumber *)value {
	SLOG(@"set treasure %@ metal to %@", [self uniqueID], [Treasure decodeMetal:value]);
    if (itemMetal != value) {
        [itemMetal release];
        itemMetal = [value copy];
    }
}


@end
