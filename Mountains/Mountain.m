/*
 
 File:		Mountains.m
 
 Abstract:	A simple class with three fields used to make the auto-sorting
			in an NSTableView straightforward
 
 Version:	1.1
 
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
 
 Copyright (C) 2008-2011 Apple Inc. All Rights Reserved.
 
 */

#import "Mountain.h"
#import "MountainsController.h"


@implementation Mountain

// Access to our data members
@synthesize name = _name;
@synthesize height = _height;
@synthesize climbedDate = _climbedDate;

// Create an object from the dictionaries found in our localized plists
+ (Mountain*)mountainWithDictionary:(id)inputDictionary;
{
	id returnValue = nil;
	if ( inputDictionary != nil && [ inputDictionary isKindOfClass:[ NSDictionary class ] ] ) {
		NSString *name = [ (NSDictionary *) inputDictionary objectForKey:kMountainNameString ];
		NSNumber *height = [ (NSDictionary *) inputDictionary objectForKey:kMountainHeightString ];
		NSDate *climbedDate = [ (NSDictionary *) inputDictionary objectForKey:kMountainClimbedDateString ];
		if ( name != nil && height != nil ) {
			returnValue = [ [ [ Mountain alloc ] initWithName:name height:height climbedDate:climbedDate ] autorelease ];
		}
	}
	return returnValue;
}

// Designated initializer
- (id)initWithName:(NSString*)name height:(NSNumber*)height climbedDate:(NSDate*)climbedDate
{
	self = [ super init ];
	if ( self != nil ) {
		self.name = name;
		self.height = height;
		self.climbedDate = climbedDate;
	}
	return self;
}


- (void)dealloc
{
	[ _name release ];
	[ _height release ];
	[ _climbedDate release ];
	[ super dealloc ];
}

// Encoding and decoding
- (void)encodeWithCoder:(NSCoder *)coder 
{
    [ coder encodeObject:self.name forKey:kMountainNameString ];
    [ coder encodeObject:self.height forKey:kMountainHeightString ];
    [ coder encodeObject:self.climbedDate forKey:kMountainClimbedDateString ];
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
    self.name = [ aDecoder decodeObjectForKey:kMountainNameString ];
    self.height = [ aDecoder decodeObjectForKey:kMountainHeightString ];
    self.climbedDate = [ aDecoder decodeObjectForKey:kMountainClimbedDateString ];
	return self;
}

// Descriptions
- (NSString*)description
{
	return [ self descriptionWithLocale:[ NSLocale autoupdatingCurrentLocale ] ];
}

- (NSString*)descriptionWithLocale:(id)locale
{
	NSString *returnValue = @"";
	if ( self.climbedDate != nil && locale != nil ) {
		NSDateFormatter *formatter = [ [ NSDateFormatter alloc ] init ];
		[ formatter setDateStyle:NSDateFormatterShortStyle ];
		[ formatter setTimeStyle:NSDateFormatterNoStyle ];
		[ formatter setLocale:locale ];
		returnValue = [ NSString stringWithFormat:@"%@-%@-%@", self.name, self.height, [ formatter stringFromDate:self.climbedDate ] ];
		[ formatter release ];
	}
	else {
		returnValue = [ NSString stringWithFormat:@"%@-%@", self.name, self.height ];
	}
	return returnValue;
}

@end
