 /*
 
 File: FileBuffer.h
 
 Abstract: FileBuffer represents a simple wrapper around NSFileHandle,
 adding some buffering and byte swapping.  It is deliberately not
 thread-safe; instead, the application serializes it by assigning a
 single instance to a single-threaded NSOperationQueue.
 
 Version: 1.1
 
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
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */ 

#import "FileBuffer.h"

#define FILE_BUFFER_QUANTUM 512

@implementation FileBuffer 

- (NSData *)readDataAtOffset:(unsigned long long)offset length:(NSUInteger)length {
    NSData *data = nil;
    @try {
        [fileHandle seekToFileOffset:offset];
        data = [fileHandle readDataOfLength:length];
    } @catch (NSException *exception) {
        data = nil;
    }
    return data;
}

- (BOOL)getBytes:(void *)buffer length:(NSUInteger)length atOffset:(unsigned long long)offset {
    BOOL retval = YES;
    NSUInteger currentLength = [currentData length];
    unsigned long long end = offset + length, currentEnd = currentOffset + currentLength, targetOffset;
    size_t bytesMoved = (size_t)-1;
    while (retval && length > 0 && offset < fileLength) {
        if (offset >= currentOffset && offset < currentEnd && end > currentOffset) {
            bytesMoved = (end > currentEnd) ? currentEnd - offset : length;
            memmove(buffer, [currentData bytes] + offset - currentOffset, bytesMoved);
            buffer += bytesMoved;
            length -= bytesMoved;
            offset += bytesMoved;
        } else if (offset < currentOffset && end > currentOffset && end <= currentEnd) {
            bytesMoved = end - currentOffset;
            memmove(buffer + currentOffset - offset, [currentData bytes], bytesMoved);
            length -= bytesMoved;
            end -= bytesMoved;
        } else {
            if (bytesMoved == 0) retval = NO;
            bytesMoved = 0;
            targetOffset = FILE_BUFFER_QUANTUM * (offset / FILE_BUFFER_QUANTUM);
            currentData = [self readDataAtOffset:targetOffset length:2 * FILE_BUFFER_QUANTUM];
            currentOffset = targetOffset;
            currentLength = [currentData length];
            currentEnd = currentOffset + currentLength;
        }
    }
    return retval;
}

- (id)initWithURL:(NSURL *)url error:(NSError **)error {
    self = [super init];
    if (self) {
        fileHandle = [NSFileHandle fileHandleForReadingAtPath:[url path]];
        if (fileHandle) {
            @try {
                fileLength = [fileHandle seekToEndOfFile];
            } @catch (NSException *exception) {
                [fileHandle closeFile];
                fileHandle = nil;
                fileLength = 0;
            }
            if (fileLength > 0) {
                uint8_t val;
                if (![self getBytes:&val length:1 atOffset:fileLength - 1]) {
                    [fileHandle closeFile];
                    fileHandle = nil;
                }
            }
        }
    }
    if (!fileHandle && error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:url, NSURLErrorKey, nil]];
    return fileHandle ? self : nil;
}

- (void)close {
    [fileHandle closeFile];
    fileHandle = nil;
}

- (void)finalize {
    [self close];
    [super finalize];
}

- (unsigned long long)fileLength {
    return fileLength;
}

- (uint8_t)byteAtOffset:(unsigned long long)offset {
    uint8_t val = 0;
    (void)[self getBytes:&val length:sizeof(val) atOffset:offset];
    return val;
}

- (uint16_t)littleUnsignedShortAtOffset:(unsigned long long)offset {
    uint16_t val = 0;
    (void)[self getBytes:&val length:sizeof(val) atOffset:offset];
    return NSSwapLittleShortToHost(val);
}
    
- (uint32_t)littleUnsignedIntAtOffset:(unsigned long long)offset {
    uint32_t val = 0;
    (void)[self getBytes:&val length:sizeof(val) atOffset:offset];
    return NSSwapLittleIntToHost(val);
}
    
- (NSData *)dataAtOffset:(unsigned long long)offset length:(NSUInteger)length {
    NSData *data = nil;
    if (length <= FILE_BUFFER_QUANTUM) {
        uint8_t buffer[FILE_BUFFER_QUANTUM] = {0};
        (void)[self getBytes:buffer length:length atOffset:offset];
        data = [NSData dataWithBytes:buffer length:length];
    } else {
        data = [self readDataAtOffset:offset length:length];
    }
    return data;
}

@end

