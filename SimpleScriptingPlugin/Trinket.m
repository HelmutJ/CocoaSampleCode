/*

File: Trinket.m

Abstract: implementation of the trinket class
for this example application.  Trinkets have
a few properties.

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

#import "Trinket.h"
#import "scriptLog.h"



@implementation Trinket




	/* after initializing our superclasses, we set the properties we're
	maintaining in this class to their default values.
	
	See the description of the NSCreateCommand for more information about
	when your init method will be called.  */
- (id)init {
	if ((self = [super init]) != nil) {
		shiny = [[NSNumber alloc] initWithBool:YES];
		weight = [[NSNumber alloc] initWithFloat:0.0];
		description = [[NSString alloc] initWithString:@"no description"];
	}
		/* I put the logging statement later after the superclass was initialized
		so we will be able to report the uniqueID */
	SLOG(@"init trinket %@", [self uniqueID]);
	return self;
}


	/* standard deallocation of our members followed by superclass.
	nothing out of the ordinary here. */
- (void)dealloc {
	SLOG(@"del trinket %@", [self uniqueID]);
	[shiny release];
	[weight release];
	[description release];
	[super dealloc];
}



	/* standard setter and getter methods for the 'shiny' property
	nothing out of the ordinary here.
	
	Note that the 'shiny' property is of type boolean on the AppleScript
	side, but it is stored as type NSNumber on the Objective-C side. */
- (NSNumber *)shiny {
	SLOG(@"trinket %@ property shiny %@", [self uniqueID], shiny);
    return [[shiny retain] autorelease];
}

- (void)setShiny:(NSNumber *)value {
	SLOG(@"set shiny of trinket %@ to %@", [self uniqueID], value);
    if (shiny != value) {
        [shiny release];
        shiny = [value copy];
    }
}



	/* standard setter and getter methods for the 'weight' property
	nothing out of the ordinary here. */
- (NSNumber *)weight {
	SLOG(@"report weight of trinket %@ as %@", [self uniqueID], weight);
    return [[weight retain] autorelease];
}

- (void)setWeight:(NSNumber *)value {
	SLOG(@"set weight of trinket %@ to %@", [self uniqueID], value);
    if (weight != value) {
        [weight release];
        weight = [value copy];
    }
}



	/* standard setter and getter methods for the 'description' property
	nothing out of the ordinary here. */
- (NSString *)description {
	SLOG(@"report description of trinket %@ as '%@'", [self uniqueID], description);
    return [[description retain] autorelease];
}

- (void)setDescription:(NSString *)value {
	SLOG(@"set description of trinket %@ to '%@'", [self uniqueID], value);
    if (description != value) {
        [description release];
        description = [value copy];
    }
}


@end








