/*
     File: ASCIIString.m
 Abstract: An NSData-backed string that treats each byte as an ASCII character (more precisely, an ISO-8859-1 character). If the character is a control character other than tab or newline, it is displayed as a period.
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

#import "ASCIIString.h"

/* Returns the character used to display the given byte in the resulting string.
 */
static inline unichar displayCharacterForByte(unsigned char dataByte) {
    if ((dataByte >= 32 && dataByte < 127) ||
            (dataByte >= (128 + 32) && dataByte < 255) ||
            dataByte == '\n' ||
            dataByte == '\t') {
        return dataByte;
    } else {
        return '.';
    }
}

@implementation ASCIIString
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

/* Returns the length of the string, which is one Unicode character per byte.
 */
- (NSUInteger)length {
    return [data length];
}

/* Converts the byte at the given index to a displayable unichar using displayCharacterForByte().
 */
- (unichar)characterAtIndex:(NSUInteger)index {
    const unsigned char *bytes = [data bytes];

    return displayCharacterForByte(bytes[index]);
}

/* Converts a range of bytes to displayable characters and puts them in the supplied buffer, using displayCharacterForByte(). If the range is beyond the bounds of the data, an exception is thrown.
 */
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    const unsigned char *bytes = [data bytes];
    
    if (NSMaxRange(range) > [data length]) {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"*** -[%@ %@]: Range %@ is out of bounds", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRange(range)] userInfo:nil];
    }
    
    NSUInteger i;
    for (i = 0; i < range.length; i++) {
        buffer[i] = displayCharacterForByte(bytes[range.location + i]);
    }
}

@end
