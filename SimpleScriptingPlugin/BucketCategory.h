/*

File: BucketCategory.h

Abstract: Declarations for the Bucket category provided
by the scripting plugin.  This category is used to extend the scripting
functionality of the host application's bucket class.

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


	/* The Bucket class is a container for trinkets and treasures.
	
	Two points of interest in this class are the weight and value
	accessor methods that we use to implement the weight and value
	AppleScript properties.  These accessors implement read only
	properties and they return a calculated result reflecting the sum
	total of the weights of all of the trinkets and treasures
	contained in the bucket.
	
	We take care of most of the 'infrastructure' type operations
	needed for scripting in the Element class (the superclass of the
	Trinket class), so all we have to worry about here is storage management
	and providing accessors for the properties.*/
@interface Bucket (ScriptingPlugin)



	/* This method returns the value of the 'valuable' property added to the
	 bucket objects by the plugin.  For buckets, valuable returns true
	 if the value to weight ratio of all of the items contained in the bucket
	 is at least two to one.  */

- (NSNumber *)valuable;


	/* methods used for randomizing the weights and values of
	 elements contained inside of the bucket object.  These methods are called
	 by the -setRandomWeight: and -setRandomValue: methods, but they have been
	 separated out so they can also be called by objects containing the
	 bucket objects.  */

- (void)randomizeWeightBetweenMinimum:(NSNumber *)minimum andMaximum:(NSNumber *)maximum;

- (void)randomizeValueBetweenMinimum:(NSNumber *)minimum andMaximum:(NSNumber *)maximum;



	/* The following methods are called by Cocoa scripting in response
	 to the randomize weight and randomize value AppleScript commands when
	 they are sent to a bucket object. */

- (void)setRandomWeight:(NSScriptCommand *)command;

- (void)setRandomValue:(NSScriptCommand *)command;
	
@end
