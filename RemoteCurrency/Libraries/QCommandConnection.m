/*
    File:       QCommandConnection.m

    Contains:   Manages a single TCP connection for sending and receiving commands.

    Written by: DTS

    Copyright:  Copyright (c) 2011 Apple Inc. All Rights Reserved.

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

#import "QCommandConnection.h"

@interface QCommandConnection () <NSStreamDelegate>

// read/write versions of public properties

@property (nonatomic, retain, readonly ) NSMutableSet *     runLoopModesMutable;
@property (nonatomic, assign, readwrite) BOOL               isOpen;

// private properties

@property (nonatomic, retain, readwrite) NSMutableData *    inputBuffer;
@property (nonatomic, retain, readwrite) NSMutableData *    outputBuffer;
@property (nonatomic, assign, readwrite) BOOL               hasSpaceAvailable;

@end

@implementation QCommandConnection

@synthesize inputStream  = inputStream_;
@synthesize outputStream = outputStream_;

@synthesize inputBufferCapacity  = inputBufferCapacity_;
@synthesize outputBufferCapacity = outputBufferCapacity_;

@synthesize runLoopModesMutable = runLoopModesMutable_;

@synthesize delegate = delegate_;
@synthesize name     = name_;

@synthesize error = error_;

@synthesize isOpen = isOpen_;

@synthesize inputBuffer  = inputBuffer_;
@synthesize outputBuffer = outputBuffer_;
@synthesize hasSpaceAvailable = hasSpaceAvailable_;

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
    // See comment in header.
{
    assert(inputStream != nil);
    assert(outputStream != nil);
    self = [super init];
    if (self != nil) {
        self->inputStream_  = [inputStream  retain];
        self->outputStream_ = [outputStream retain];
        self->runLoopModesMutable_ = [[NSMutableSet alloc] initWithObjects:NSDefaultRunLoopMode, nil];
        assert(self->runLoopModesMutable_ != nil);
    }
    return self;
}

- (void)dealloc
{
    [self->inputStream_  release];
    [self->outputStream_ release];
    [self->runLoopModesMutable_ release];
    [self->name_ release];
    [self->error_ release];
    [self->inputBuffer_ release];
    [self->outputBuffer_ release];
    [super dealloc];
}

#pragma mark * Run loop modes

- (void)addRunLoopMode:(NSString *)modeToAdd
{
    assert(modeToAdd != nil);
    if ( ! self.isOpen ) {
        [self.runLoopModesMutable addObject:modeToAdd];
    }
}

- (void)removeRunLoopMode:(NSString *)modeToRemove
{
    assert(modeToRemove != nil);
    if ( ! self.isOpen ) {
        [self.runLoopModesMutable removeObject:modeToRemove];
    }
}

- (NSSet *)runLoopModes
{
    return [[self.runLoopModesMutable copy] autorelease];
}

#pragma mark * Utilities

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
    assert(format != nil);
    if ([self.delegate respondsToSelector:@selector(connection:logWithFormat:arguments:)]) {
        [self.delegate connection:self logWithFormat:format arguments:argList];
    }    
}

- (void)logWithFormat:(NSString *)format, ...
{
    va_list argList;

    assert(format != nil);
    va_start(argList, format);
    [self logWithFormat:format arguments:argList];
    va_end(argList);
}

+ (NSError *)errorWithCode:(NSInteger)code
    // Creates an error in the kQCommandConnectionErrorDomain domain 
    // with the specified code and (not really) user-visible string.
{
    NSMutableDictionary *   userInfo;
    NSString *              description;
    
    assert(code != 0);
    
    userInfo = nil;
    
    switch (code) {
        case kQCommandConnectionOutputBufferFullError: {
            description = @"output buffer full";
        } break;
        case kQCommandConnectionInputBufferFullError: {
            description = @"input buffer full";
        } break;
        case kQCommandConnectionOutputCommandTooLongError: {
            description = @"output command too long";
        } break;
        case kQCommandConnectionInputUnexpectedError: {
            description = @"did not expect input on this connection";
        } break;
        case kQCommandConnectionInputCommandTooLongError: {
            description = @"input command too long";
        } break;
        case kQCommandConnectionInputCommandMalformedError: {
            description = @"input command malformed";
        } break;
        default: {
            assert(NO);
            description = nil;
        } break;
    }
    
    if (description != nil) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            description, NSLocalizedDescriptionKey,
            nil
        ];
        assert(userInfo != nil);
    }
    return [NSError errorWithDomain:kQCommandConnectionErrorDomain code:code userInfo:userInfo];
}

#pragma mark * Open and close

- (void)open
    // See comment in header.
{
    assert( ! self.isOpen );
    
    [self logWithFormat:@"open"];
    
    // Set up the input and output buffers.
    
    if (self.inputBufferCapacity == 0) {
        self.inputBufferCapacity = 16 * 1024;
    }
    if (self.outputBufferCapacity == 0) {
        self.outputBufferCapacity = 16 * 1024;
    }
    self.inputBuffer  = [NSMutableData dataWithCapacity:self.inputBufferCapacity];
    assert(self.inputBuffer != nil);
    self.outputBuffer = [NSMutableData dataWithCapacity:self.outputBufferCapacity];
    assert(self.outputBuffer != nil);

    // Start the streams.
    
    [self.inputStream  setDelegate:self];
    [self.outputStream setDelegate:self];

    for (NSString * mode in self.runLoopModesMutable) {
        [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    }
    
    [self.inputStream  open];
    [self.outputStream open];

    self.isOpen = YES;
}

- (void)willCloseWithError:(NSError *)error
    // See comment in header.
{
    // error may be nil (indicates EOF)
    if ([self.delegate respondsToSelector:@selector(connection:willCloseWithError:)]) {
        [self.delegate connection:self willCloseWithError:error];
    }
}

- (void)closeWithError:(NSError *)error notify:(BOOL)notify
    // Closes the stream and, if notify is YES, tells the delegate about it. 
    // This is the core code for the -close and -closeWithError: public 
    // methods.
{
    // error may be nil (indicates EOF)
    if (self.isOpen) {
        // Latch the error.
        
        if (self.error == nil) {
            self.error = error;
        }
        
        // Inform the delegate, if required.
        
        if (notify) {
            // The following retain and autorelease is necessary to prevent crashes when, 
            // after we tell the delegate about the close, the delegate releases its reference 
            // to us, and that's the last reference, so we end up freed, and hence crash on 
            // returning back up the stack to this code.
            
            [[self retain] autorelease];

            [self willCloseWithError:error];
        }
        
        // Tear down the streams.
        
        [self.inputStream  setDelegate:nil];
        [self.outputStream setDelegate:nil];

        for (NSString * mode in self.runLoopModesMutable) {
            [self.inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
            [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }

        [self.inputStream  close];
        [self.outputStream close];
        
        self.isOpen = NO;
    }
}

- (void)closeWithError:(NSError *)error
    // See comment in header.
{
    if (error == nil) {
        [self logWithFormat:@"close without error"];
    } else {
        [self logWithFormat:@"close with error %@", error];
    }
    [self closeWithError:error notify:YES];
}

- (void)close
    // See comment in header.
{
    [self logWithFormat:@"close"];
    [self closeWithError:nil notify:NO];
}

#pragma mark * Send and receive

- (NSUInteger)parseCommandData:(NSData *)commandData
    // See comment in header.
{
    NSUInteger  result;
    
    assert(commandData != nil);
    assert([commandData length] != 0);
    
    result = 0;
    if ( [self.delegate respondsToSelector:@selector(connection:parseCommandData:)] ) {
        result = [self.delegate connection:self parseCommandData:commandData];
    } else {
        [self closeWithError:[[self class] errorWithCode:kQCommandConnectionInputUnexpectedError]];
    }
    return result;
}

- (void)parseCommandsInBuffer
    // Calls the delegate to parse all of the commands that are currently sitting 
    // in the input buffer.
{
    NSUInteger  inputBufferLength;
    NSData *    dataToParse;
    NSUInteger  offset;
    NSUInteger  bytesParsed;

    inputBufferLength = [self.inputBuffer length];
    assert(inputBufferLength != 0);
    assert(inputBufferLength <= self.inputBufferCapacity);
    
    // We retain the data here because we're going to release it at the end. 
    // This allows us to, inside the loop, create a sub-range of data and 
    // have all the retains and releases work out.  This means that the 
    // delegate gets a retained pointer to our input buffer for the first call 
    // and an immutable copy of a sub-range of our data for subsequent calls. 
    // But hey, the delegate is supposed to copy it if it wants to keep it. 
    // And parse all the commands it can on each call.
    
    dataToParse = [self.inputBuffer retain];
    assert(dataToParse != nil);
    
    offset = 0;
    do {
        // Call the delegate to parse the commands in the buffer.
        
        bytesParsed = [self parseCommandData:dataToParse];
        assert(bytesParsed <= [dataToParse length]);     // you can't parse more data than we gave you

        // If the stream is now magically closed, the delegate closed it out from under 
        // us and we need to leave.
        
        if ( ! self.isOpen ) {
            break;
        }
        
        // If the delegate couldn't parse any bytes, then leave the loop and wait for the 
        // remaining bytes in the command to arrive.  However, if we already passed a maximum 
        // size command to the delegate and it still wasn't enough, that means the 
        // client sent us a command that's too long to be parsed and the connection dies.
        
        if (bytesParsed == 0) {
            if ([dataToParse length] == self.outputBufferCapacity) {
                [self closeWithError:[[self class] errorWithCode:kQCommandConnectionInputCommandTooLongError]];
            }
            break;
        }
        
        // Consume the bytes that the delegate parsed and continue parsing.  If we've consumed 
        // the entire input buffer, it's time to leave.  Otherwise, create a subrange of 
        // our input buffer and pass it back to the delegate.
        
        offset += bytesParsed;
        [self logWithFormat:@"parsed %zu bytes of commands", (size_t) bytesParsed];
        if (offset == inputBufferLength) {
            break;
        }
        [dataToParse release];
        dataToParse = [[self.inputBuffer subdataWithRange:NSMakeRange(offset, inputBufferLength - offset)] retain];
        assert(dataToParse != nil);
    } while (YES);
    
    [dataToParse release];
    
    // If we consumed any bytes, remove them from the front of the input buffer.
    
    if (offset != 0) {
        [self.inputBuffer replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
}

- (void)processInput
    // Called in response to a NSStreamEventHasBytesAvailable event to read the data 
    // from the input stream and process any commands in the data.
{
    NSInteger   bytesRead;
    NSUInteger  bufferLength;
    
    bufferLength = [self.inputBuffer length];
    if (bufferLength == self.inputBufferCapacity) {
        [self closeWithError:[[self class] errorWithCode:kQCommandConnectionInputBufferFullError]];
    } else {
        // Temporarily increase the size of the buffer up to its capacity 
        // so as to give us a space to read data.
        
        [self.inputBuffer setLength:self.inputBufferCapacity];
        
        // Read the actual data and respond to the three types of return values.
        
        bytesRead = [self.inputStream read:((uint8_t *) [self.inputBuffer mutableBytes]) + bufferLength maxLength:self.inputBufferCapacity - bufferLength];
        if (bytesRead == 0) {
            [self logWithFormat:@"read EOF"];
            [self closeWithError:nil];
        } else if (bytesRead < 0) {
            assert([self.inputStream streamError] != nil);
            [self logWithFormat:@"read error %@", [self.inputStream streamError]];
            [self closeWithError:[self.inputStream streamError]];
        } else {
            [self logWithFormat:@"read %zu bytes", (size_t) bytesRead];
            
            // Reset the buffer length based on the bytes we actually read and 
            // then parse any received commands.
            
            [self.inputBuffer setLength:bufferLength + bytesRead];
            [self parseCommandsInBuffer];
        }
    }
}

- (void)processOutput
    // Called in response to a NSStreamEventHasSpaceAvailable event (or if such 
    // an event was deferred) to start sending data to the output stream.
{
    NSInteger   bytesWritten;
    
    if (self.hasSpaceAvailable) {
        if ( [self.outputBuffer length] != 0 ) {
            
            // Write the data and process the two types of return values.
            
            bytesWritten = [self.outputStream write:[self.outputBuffer bytes] maxLength:[self.outputBuffer length]];
            if (bytesWritten <= 0) {
                assert([self.outputStream streamError] != nil);
                [self logWithFormat:@"write error %@", [self.outputStream streamError]];
                [self closeWithError:[self.outputStream streamError]];
            } else {
                [self logWithFormat:@"wrote %zu bytes", (size_t) bytesWritten];
                [self.outputBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
                self.hasSpaceAvailable = NO;
            }
        }
    }
}

- (void)sendCommand:(NSData *)command
    // See comment in header.
{
    NSUInteger  commandLength;
    
    assert(command != nil);
    commandLength = [command length];
    assert(commandLength != 0);             // that's just silly
    if (commandLength > self.outputBufferCapacity) {
        [self closeWithError:[[self class] errorWithCode:kQCommandConnectionOutputCommandTooLongError]];
    } else if ( ([self.outputBuffer length] + commandLength) > self.outputBufferCapacity ) {
        [self closeWithError:[[self class] errorWithCode:kQCommandConnectionOutputBufferFullError]];
    } else {
        [self logWithFormat:@"enqueue %zu byte command", (size_t) commandLength];
        
        [self.outputBuffer appendData:command];
        
        [self processOutput];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // The input and output stream delegate callback method.
{
    assert( (aStream == self.inputStream) || (aStream == self.outputStream) );
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self logWithFormat:@"open %@", (aStream == self.inputStream) ? @"input" : @"output"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(aStream == self.inputStream);
            [self logWithFormat:@"has bytes available"];
            [self processInput];
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(aStream == self.outputStream);
            [self logWithFormat:@"has space available"];
            self.hasSpaceAvailable = YES;
            [self processOutput];
        } break;
        case NSStreamEventEndEncountered: {
            [self logWithFormat:@"EOF %@", (aStream == self.inputStream) ? @"input" : @"output"];
            [self closeWithError:nil];
        } break;
        default:
            assert(NO);
            // fall through
        case NSStreamEventErrorOccurred: {
            [self logWithFormat:@"error %@ %@", (aStream == self.inputStream) ? @"input" : @"output", [aStream streamError]];
            [self closeWithError:[aStream streamError]];
        } break;
    }
}

@end

NSString * kQCommandConnectionErrorDomain = @"com.apple.dts.kQCommandConnectionErrorDomain";
