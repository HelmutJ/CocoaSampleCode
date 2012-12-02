/*
     File: HexAndASCIIString.m
 Abstract:     An NSData-backed string that displays binary data in a human readable format. Each line is of the following form:
 12345678:  61 62 63 64 65 66 67 68 69 6a  abcdefghij
 This format, and most of the implementation to support it, is carried over from the original LazyDataString class, once found in LazyDataTextStorage.m.
 The first number is the decimal offset of the current line. The next ten numbers are hex pairs for the next ten bytes. The last ten characters are ISO-8859-1 interpretations of the same ten bytes.
 
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


#define BYTES_PER_LINE 10
/* 00000000:  00 00 00 00  ....\n */
#define CHARS_PER_LINE ((BYTES_PER_LINE * 4) + 8 + 3 + 1 + 1)

#import "HexAndASCIIString.h"

/* Returns the character used to display the given byte in the resulting string. Control characters are replaced by periods.
 */
static inline unichar displayCharForByte(unsigned char dataByte) {
    if ((dataByte >= 32 && dataByte < 127) || (dataByte >= (128 + 32) && dataByte < 255)) {
        return dataByte;
    } else {
        return '.';
    }
}

@implementation HexAndASCIIString
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

/* Returns the length of the string in characters. The string is always going to have complete lines, even if that means padding with spaces.
 */
- (NSUInteger)length {
    NSUInteger dataLength = [data length];
    return ((dataLength + BYTES_PER_LINE - 1) / BYTES_PER_LINE) * CHARS_PER_LINE;
}

/* Just pass the call to getCharacters:range:, because characters are generated a line at a time and this is simpler...if not terribly efficient.
 */
- (unichar)characterAtIndex:(NSUInteger)index {
    unichar buffer;
    [self getCharacters:&buffer range:NSMakeRange(index, 1)];
    return buffer;
}

/* Reasonably complicated method to generate the characters of the string in the format described at the top of the file. Characters are generated a line at a time from a "line" of bytes (a preprocessor constant) in a mutable string, then the string's characters are pulled into the buffer.
 */
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    NSMutableString *mStr = [[NSMutableString alloc] initWithCapacity:CHARS_PER_LINE];
    const unsigned char *bytes = [data bytes];
    NSInteger byteLoc = (range.location / CHARS_PER_LINE) * BYTES_PER_LINE;	// loc in terms of bytes in data, not chars in string
    NSInteger byteEnd = ((NSMaxRange(range) + CHARS_PER_LINE - 1) / CHARS_PER_LINE) * BYTES_PER_LINE;	// same
    
    if (byteEnd > [data length]) {
        byteEnd = [data length];
    }
    
    // Do line at a time
    while (byteLoc < byteEnd) {
        NSInteger numBytesOnThisLine = (byteEnd - byteLoc < BYTES_PER_LINE) ? (byteEnd - byteLoc) : BYTES_PER_LINE;
        NSRange processedRange;
        NSInteger i;
        
        // Compute string for the whole line
        [mStr appendFormat:@"%08ld: ", (long) byteLoc];
        for (i = 0; i < numBytesOnThisLine; i++) [mStr appendFormat:@" %02hhx", bytes[byteLoc + i]];
        for (; i < BYTES_PER_LINE; i++) [mStr appendString:@"   "];
        [mStr appendString:@"  "];
        for (i = 0; i < numBytesOnThisLine; i++) [mStr appendFormat:@"%c", displayCharForByte(bytes[byteLoc + i])];
        for (; i < BYTES_PER_LINE; i++) [mStr appendString:@" "];
        [mStr appendString:@"\n"];
        
        // Now, compute the processedRange, and intersect with the provided range (to deal with first and last lines properly)
        processedRange.location = (byteLoc / BYTES_PER_LINE) * CHARS_PER_LINE;
        processedRange.length = CHARS_PER_LINE;
        processedRange = NSIntersectionRange(processedRange, range);
        processedRange.location -= (byteLoc / BYTES_PER_LINE) * CHARS_PER_LINE;
                
        // Copy the required range to the output
        [mStr getCharacters:buffer range:processedRange];
        
        // Clear line; also increment loop variables
        [mStr setString:@""];
        byteLoc += BYTES_PER_LINE;
        buffer += processedRange.length;
    }
    
    [mStr release];
}

@end
