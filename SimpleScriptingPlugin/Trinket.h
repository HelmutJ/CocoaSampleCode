/*

File: Trinket.h

Abstract: declarations for the trinket class
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

#import <Cocoa/Cocoa.h>
#import "Element.h"

	/* The Trinket class builds on top of our Element class.
	We take care of most of the 'infrastructure' type operations
	needed for scripting in the Element class,  so all we have
	to worry about here is storage management and providing
	accessors for the properties.*/
@interface Trinket : Element {
	NSNumber *shiny; /* storage for the 'shiny' AppleScript boolean property. */
	NSNumber *weight; /* storage for the 'weight' AppleScript real property. */
	NSString *description; /* storage for the 'description' AppleScript string property. */
}

	/* storage management */
- (id)init;
- (void)dealloc;

	/* kvc methods for the 'shiny' AppleScript property */
- (NSNumber *)shiny;
- (void)setShiny:(NSNumber *)isShiny;

	/* kvc methods for the 'weight' AppleScript property */
- (NSNumber *)weight;
- (void)setWeight:(NSNumber *)theWeight;

	/* kvc methods for the 'description' AppleScript property */
- (NSString *)description;
- (void)setDescription:(NSString *)theDescription;

@end
