/*

File: AStoObjC.m

Abstract: Converts AppleScript Automator Action output to SIU input

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#import "AStoObjC.h"

@implementation AStoObjC

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {
	// If our input came from an AppleScript-based Automator Action, the class will be 
	// NSAppleEventDescriptor, and we need to convert it to NSObject types for System Image Utility
	if (![input isKindOfClass:[NSAppleEventDescriptor class]]) return input;
	return [self objectFromAppleEventDescriptor:(NSAppleEventDescriptor *)input];	
}

- (id)objectFromAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor {
	switch ([descriptor descriptorType]) {
		case typeChar:
		case typeUnicodeText:
			return [descriptor stringValue];
		case typeAEList:
			return [self arrayFromAppleEventDescriptor:descriptor];
		case typeAERecord:
			return [self dictionaryFromAppleEventDescriptor:descriptor];

		case typeBoolean:
			return [NSNumber numberWithBool:(BOOL)[descriptor booleanValue]];
		case typeTrue:
			return [NSNumber numberWithBool:YES];
		case typeFalse:
			return [NSNumber numberWithBool:NO];
		case typeType:
			return [NSNumber numberWithUnsignedLong:(unsigned long)[descriptor typeCodeValue]];
		case typeEnumerated:
			return [NSNumber numberWithUnsignedLong:(unsigned long)[descriptor enumCodeValue]];
		case typeNull:
			return [NSNull null];

		case typeSInt16:
			return [NSNumber numberWithInt:(short)[descriptor int32Value]];
		case typeSInt32:
			return [NSNumber numberWithInt:(int)[descriptor int32Value]];
		case typeUInt32:
			return [NSNumber numberWithLong:(unsigned int)[descriptor int32Value]];
		case typeSInt64:
			return [NSNumber numberWithLong:(long)[descriptor int32Value]];
//		case typeIEEE32BitFloatingPoint:
//			return [NSNumber numberWithBytes:[[descriptor data] bytes] objCType:@encode(float)];
//		case typeIEEE64BitFloatingPoint:
//			return [NSNumber numberWithBytes:[[descriptor data] bytes] objCType:@encode(double)];
//		case type128BitFloatingPoint:
//		case typeDecimalStruct:
	}
	
	return [descriptor data];
}


- (NSMutableArray *)arrayFromAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor { 
	unsigned int count = [descriptor numberOfItems]; 
	unsigned int i = 1; 
	NSMutableArray *myList = [NSMutableArray arrayWithCapacity:count]; 

	for (i = 1; i <= count; i++ ) { 
		id value = [self objectFromAppleEventDescriptor:[descriptor descriptorAtIndex:i]]; 
		if (value) [myList addObject:value]; 
	} 
	
	return myList; 
 } 


- (NSMutableDictionary *)dictionaryFromAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor { 
	if (![descriptor numberOfItems]) return nil; 
	descriptor = [descriptor descriptorAtIndex:1]; 
	unsigned int count = [descriptor numberOfItems]; 
	unsigned int i = 1; 
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count]; 
	 
	for (i = 1; i <= count; i += 2 ) { 
		NSString *key = [[descriptor descriptorAtIndex:i] stringValue]; 
		id value = [self objectFromAppleEventDescriptor:[descriptor descriptorAtIndex:(i + 1)]]; 
		if (key && value) [dict setObject:value forKey:key]; 
	} 
	 
	return dict; 
} 

@end
