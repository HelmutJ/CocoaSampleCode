/*
    File:       FileReceiveOperation.m

    Contains:   An NSOperation that receives a file over a TCP connection.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "FileReceiveOperation.h"

#include <zlib.h>

enum {
    kFileReceiveOperationStateStart, 
    kFileReceiveOperationStateHeader, 
    kFileReceiveOperationStateBody, 
    kFileReceiveOperationStateTrailer
};

enum {
    kFileReceiveOperationBufferSize = 32768
};

@interface FileReceiveOperation () <NSStreamDelegate>

// read/write variants of public properties

@property (copy,   readwrite) NSString *        finalFilePath;

// internal properties

@property (assign, readwrite) NSInteger         receiveState;
@property (retain, readwrite) NSOutputStream *  fileStream;
@property (retain, readwrite) NSMutableData *   buffer;
@property (assign, readwrite) NSUInteger        bufferOffset;
@property (assign, readwrite) off_t             fileLength;
@property (assign, readwrite) off_t             fileOffset;
@property (assign, readwrite) uLong             crc;

@end

@implementation FileReceiveOperation

- (id)initWithInputStream:(NSInputStream *)inputStream
{
    assert(inputStream != nil);

    self = [super init];
    if (self != nil) {
        self->_inputStream = [inputStream retain];
    }
    return self;
}

- (void)dealloc
{
    assert(self->_buffer == nil);
    assert(self->_fileStream == nil);
    [self->_finalFilePath release];
    [self->_filePath release];
    [self->_inputStream release];
    [super dealloc];
}

@synthesize filePath    = _filePath;
@synthesize inputStream = _inputStream;

#if ! defined(NDEBUG)

@synthesize debugStallReceive       = _debugStallReceive;
@synthesize debugReceiveBadChecksum = _debugReceiveBadChecksum;

#endif

@synthesize finalFilePath = _finalFilePath;

@synthesize fileStream    = _fileStream;
@synthesize buffer        = _buffer;
@synthesize bufferOffset  = _bufferOffset;
@synthesize fileLength    = _fileLength;
@synthesize fileOffset    = _fileOffset;
@synthesize crc           = _crc;

#pragma mark * Start and stop

- (void)operationDidStart
    // Our superclass calls this on the actual run loop thread to give us an opportunity 
    // to install our run loop sources (and do various other bits of initialisation).
{
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);

    // Decide where we're going to download to, and remember that in finalFilePath.
    // Note that, if the download fails, -operationWillFinish will nix finalFilePath 
    // so that the final result seen by our client is nil.
    
    if (self.filePath != nil) {
        self.finalFilePath = self.filePath;
    } else {
        self.finalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"PictureSharing-%.9f.tmp", [NSDate timeIntervalSinceReferenceDate]]];
        assert(self.finalFilePath != nil);
        assert( ! [[NSFileManager defaultManager] fileExistsAtPath:self.finalFilePath] );
    }

    // Create and open our output file stream.
    
    self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.finalFilePath append:NO];
    if (self.fileStream == nil) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil]];
    } else {
        [self.fileStream open];

        // Create a transfer buffer and set it up for the initial read of the header.
        
        self.buffer = [NSMutableData dataWithCapacity:kFileReceiveOperationBufferSize];
        assert(self.buffer != nil);
        
        // Open our input TCP stream.
        
        [self.inputStream setDelegate:self];
        for (NSString * mode in self.actualRunLoopModes) {
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
        [self.inputStream open];

        assert(self.receiveState == kFileReceiveOperationStateStart);
        assert(self.bufferOffset == 0);
        assert(self.fileOffset == 0);
        assert(self.crc == 0);
    }
}

- (void)operationWillFinish
    // Our superclass calls this on the actual run loop thread to give us an opportunity 
    // to remove our run loop sources (and do various other bits of clean up).
{
    BOOL    failed;

    assert(self.isActualRunLoopThread);
    
    failed = (self.error != nil);
    
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
        
        // If we failed, we delete any file we created.
        
        if ( failed && (self.finalFilePath != nil) ) {
            (void) [[NSFileManager defaultManager] removeItemAtPath:self.finalFilePath error:NULL];
        }
    }
    if (failed) {
        self.finalFilePath = nil;
    }
    if (self.inputStream != nil) {
        // We want to hold on to our reference to inputStream until -dealloc, but 
        // we don't want to do this teardown twice, so we conditionalise it based on 
        // whether the delegate is still set.
        if ([self.inputStream delegate] != nil) {
            [self.inputStream setDelegate:nil];
            for (NSString * mode in self.actualRunLoopModes) {
                [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            }
            [self.inputStream close];
        }
    }
    self.buffer = nil;      // might as well free up the memory now
}

#pragma mark * Stream delegate callbacks

@synthesize receiveState = _receiveState;

- (void)processHeaderBuffer
    // Called by the stream event handling delegate callback to handle a buffer 
    // containing header data.
{
    // Extract the file length.

    assert([self.buffer length] == sizeof(uint64_t));
    uint64_t tmp = OSSwapBigToHostInt64( * (const uint64_t *) [self.buffer bytes] );
    self.fileLength = tmp;
    
    // We really should bounds check the file length to prevent a bogus server from 
    // running us completely out of disk space.  That's beyond the scope of this 
    // sample code though.
    
    assert(self.fileOffset == 0);
}

- (void)processBodyBuffer
    // Called by the stream event handling delegate callback to handle a buffer 
    // containing file body data.
{
    NSError *   error;
    NSUInteger  bytesWrittenTotal;
    NSInteger   bytesWritten;
    
    error = nil;
        
    // We just received a block of file data.  Update our CRC calculation.
    
    self.crc = crc32(self.crc, [self.buffer bytes], (uInt) [self.buffer length]);
    
    // Write buffer to disk.
    
    bytesWrittenTotal = 0;
    do {
        bytesWritten = [self.fileStream write:((const uint8_t *) [self.buffer bytes]) + bytesWrittenTotal maxLength:[self.buffer length] - bytesWrittenTotal];
        if (bytesWritten <= 0) {
            error = [self.fileStream streamError];
            assert(error != nil);
        } else {
            bytesWrittenTotal += bytesWritten;
        }
    } while ( (error == nil) && (bytesWrittenTotal != [self.buffer length]) );
    
    // And record that we've written that many bytes to the file.
    
    if (error == nil) {
        self.fileOffset += [self.buffer length];
    } else {
        [self finishWithError:error];
    }
}

- (void)processTrailerBuffer
    // Called by the stream event handling delegate callback to handle a buffer 
    // containing trailer data.
{
    uint32_t    crcReceived;
    
    // We've just received the trailer.  Check its CRC.
    
    assert([self.buffer length] == sizeof(uint32_t));
    crcReceived = OSSwapBigToHostInt32( * (const uint32_t *) [self.buffer bytes] );
    #if ! defined(NDEBUG)
        if (self.debugReceiveBadChecksum) {
            crcReceived ^= 1;
        }
    #endif
    if (crcReceived == self.crc) {
        [self finishWithError:nil];
    } else {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil]];
    }
}

- (void)setupNextReceiveBuffer
    // Called by the stream event handling delegate callback after handling a buffer of 
    // header or file body data.  It sets up the next receive buffer based on how 
    // much file body data is left to read.
{
    if (self.fileOffset < self.fileLength) {
        off_t   bytesRemaining;
        
        // More file to read.  Calculate the size of the next buffer.
        
        bytesRemaining = self.fileLength - self.fileOffset;
        if (bytesRemaining > (off_t) kFileReceiveOperationBufferSize) {
            bytesRemaining = kFileReceiveOperationBufferSize;
        }
        [self.buffer setLength:(NSUInteger) bytesRemaining];    // bytesRemaining can't overflow 32-bits because it's bounded by kFileReceiveOperationBufferSize
        self.receiveState = kFileReceiveOperationStateBody;
    } else {
    
        // No more file to read.  Set up the next buffer to receive the trailer.
        
        [self.buffer setLength:sizeof(uint32_t)];
        self.receiveState = kFileReceiveOperationStateTrailer;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // An NSStream delegate callback that's called when events happen on our TCP stream.
{
    assert([NSThread isMainThread]);

    assert(aStream == self.inputStream);
    #pragma unused(aStream)

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            // do nothing
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            
            #if ! defined(NDEBUG)
                if (self.debugStallReceive) {
                    return;
                }
            #endif

            // If we're just starting out, set up to receive the header.
            
            if (self.receiveState == kFileReceiveOperationStateStart) {
                assert(self.bufferOffset == 0);
                [self.buffer setLength:sizeof(uint64_t)];
                self.receiveState = kFileReceiveOperationStateHeader;
            }

            // Try to read enough bytes to fill out current buffer.
            
            assert(self.bufferOffset < [self.buffer length]);
            bytesRead = [self.inputStream read:((uint8_t *) [self.buffer mutableBytes]) + self.bufferOffset maxLength:[self.buffer length] - self.bufferOffset];
            if (bytesRead < 0) {
                assert([self.inputStream streamError] != nil);
                [self finishWithError:[self.inputStream streamError]];
            } else if (bytesRead == 0) {
                [self finishWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:EPIPE userInfo:nil]];
            } else {
                assert(bytesRead > 0);
                
                // Update the buffer offset and, if we've filled a buffer, process it.
                
                self.bufferOffset += bytesRead;
                if (self.bufferOffset == [self.buffer length]) {
                    self.bufferOffset = 0;

                    switch (self.receiveState) {
                        case kFileReceiveOperationStateStart: {
                            assert(NO);
                        } break;
                        case kFileReceiveOperationStateHeader: {
                            [self processHeaderBuffer];
                            [self setupNextReceiveBuffer];
                        } break;
                        case kFileReceiveOperationStateBody: {
                            [self processBodyBuffer];
                            if ( ! [self isFinished] ) {
                                [self setupNextReceiveBuffer];
                            }
                        } break;
                        case kFileReceiveOperationStateTrailer: {
                            [self processTrailerBuffer];
                        } break;
                    }
                }
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
        case NSStreamEventErrorOccurred: {
            assert([self.inputStream streamError] != nil);
            [self finishWithError:[self.inputStream streamError]];
        } break;
        case NSStreamEventEndEncountered: {
            assert(NO);
        } break;
        default: {
            assert(NO);
        } break;
    }
}

@end
