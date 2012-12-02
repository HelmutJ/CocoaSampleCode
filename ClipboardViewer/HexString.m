/*
     File: HexString.m
 Abstract: An NSData-backed string that displays its bytes as pairs of hex digits, separated by spaces.
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


#import "HexString.h"

@implementation HexString
- (id)initWithData:(NSData *)obj {
    if (self = [super init]) {
        data = [obj copy];
    }
    return self;
}

- (id)init {
    return [self initWithData:[NSData data]];
}

- (void)dealloc {
    [data release];
    [super dealloc];
}

- (NSData *)data {
    return data;
}

#pragma mark -

/* Returns the length of the string in Unicode characters; each byte results in three characters in the string (e.g. "3a ").
 */
- (NSUInteger)length {
    return [data length] * 3;
}

/* Returns the character at the given index, taking a shortcut if we know beforehand it's a space, and using a format string otherwise.
 */
- (unichar)characterAtIndex:(NSUInteger)index {
    unsigned char which = index % 3;
    if (which == 2) {
        return ' '; // every third character is a space
    } else {
        const unsigned char *bytes = [data bytes];
        NSString *byteString = [[NSString alloc] initWithFormat:@"%02hhx", bytes[index / 3]];
        unichar result = [byteString characterAtIndex:which];
        [byteString release];
        return result;
    }
}

/* Converts bytes in the given range into printable characters and stores them in the given buffer. Each byte is appended to a mutable string using a format string, then its characters are transferred to the buffer. There are special cases for when the range overlaps part of a "byte" on either end.
 */
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    if (NSMaxRange(range) > [self length]) {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"*** -[%@ %@]: Range %@ is out of bounds", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRange(range)] userInfo:nil];
    }

    NSMutableString *byteString = [[NSMutableString alloc] initWithCapacity:2];
    const unsigned char *bytes = [data bytes];
    
    NSUInteger firstByte = range.location / 3;
    NSUInteger offset = 3 - (range.location % 3); // how much of the first byte we need to handle separately
    
    // handle the first byte specially (note that it's the *last* 1, 2, or 3 characters of the first byte)
    if (offset == 1) {
        buffer[0] = ' ';
    } else if (offset == 2) {
        [byteString appendFormat:@"%02hhx", bytes[firstByte]];
        buffer[0] = [byteString characterAtIndex:1];
        buffer[1] = ' ';
        [byteString setString:@""];
    } else {
        [byteString appendFormat:@"%02hhx", bytes[firstByte]];
        buffer[0] = [byteString characterAtIndex:0];
        buffer[1] = [byteString characterAtIndex:1];
        buffer[2] = ' ';
        [byteString setString:@""];
    }
    
    firstByte += 1;
    
    // each byte has three characters, for example "3a "
    NSUInteger byteCount = (range.length - offset) / 3;
    NSUInteger i;
    for (i = 0; i < byteCount; i++) {
        [byteString appendFormat:@"%02hhx", bytes[i + firstByte]];
        buffer[(3 * i) + offset] = [byteString characterAtIndex:0];
        buffer[(3 * i) + offset + 1] = [byteString characterAtIndex:1];
        buffer[(3 * i) + offset + 2] = ' ';
        [byteString setString:@""];
    }
    
    // if the range has part of the next byte, the integer divison for byteCount would have left it out
    // so we handle it here
    NSUInteger charCountSoFar = ((3 * i) + offset);
    if (charCountSoFar <= (range.length - 1)) {
        [byteString appendFormat:@"%02hhx", bytes[i + firstByte]];
        buffer[charCountSoFar] = [byteString characterAtIndex:0];
        
        if (charCountSoFar == (range.length - 2)) {
            buffer[charCountSoFar + 1] = [byteString characterAtIndex:1];
        }
    }
    
    [byteString release];
}

@end
