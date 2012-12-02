/*
     File: LazyDataTextStorage.m
 Abstract:     This file contains one class:
 LazyDataTextStorage: Subclass of NSTextStorage which treats its contents as immutable, allowing for lazy loading.
 But used to contain another:
 LazyDataString: Subclass of NSString for displaying a hex and text dump of binary data. Most of its code is now in HexAndASCIIString.
 
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */


#import "LazyDataTextStorage.h"

@implementation LazyDataTextStorage

- (id)init {
    if (self = [super init]) {
        myString = [@"" copy];
        myAttributes = [[NSDictionary dictionary] copy];
    }
    return self;
}

- (void)dealloc {
    [myString release];
    [myAttributes release];
    [super dealloc];
}

/* These two methods are the way to change the string and attributes of this text storage
We assume non-editable backing store; in addition, the same attributes apply to the whole string.
*/
- (void)setAttributes:(NSDictionary *)attrs {
    if (myAttributes != attrs) {
        [myAttributes release];
        myAttributes = [attrs retain];
        [self edited:NSTextStorageEditedAttributes range:NSMakeRange(0, [self length]) changeInLength:0];
    }
}

- (void)setString:(NSString *)string {
    if (myString != string) {
        NSUInteger origLength = [self length];
        [myString release];
        myString = [string retain];
        [self edited:NSTextStorageEditedCharacters range:NSMakeRange(0, origLength) changeInLength:[self length] - origLength];
    }
}

- (NSString *)string {
    return myString;
}

/* Primitve for returning the attributes; we just have a fixed set, so the result is easy...
*/
- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    if (range) *range = NSMakeRange(0, [self length]);
    return myAttributes;
}

/* The actual mutable primitives, the two below, don't do anything. This means this text storage is really not editable. We generate a warning just to  make sure these are never called...
*/
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    NSLog (@"Attempt to edit characters!");
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range {
    NSLog (@"Attempt to edit attributes!");
}

/* Do nothing; because we're not editable, no need to try to fix (and, in fact, trying to fix attributes might cause trouble if the fixing causes some changes. Note that what this means is we need to make sure that the attributes assigned to the text are always valid.
*/
- (void)fixAttributesInRange:(NSRange)range {
}


@end

