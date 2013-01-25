/*
    File:       QCommandConnection.h

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

#import <Foundation/Foundation.h>

// QCommandConnection is a general purpose class for managing a command-oriented 
// network connection.
// 
// The class is run loop based and must be called from a single thread. 
// Specifically, the -open and -close methods add and remove run loop sources 
// to the current thread's run loop, and it's that thread that calls the 
// delegate callbacks.

@protocol QCommandConnectionDelegate;

@interface QCommandConnection : NSObject

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
    // Creates the command connection to run over the supplied streams.  
    // You can set other configuration parameters, like the buffer capacities, 
    // before calling -open on the connection.

// properties set on init
    
@property (nonatomic, retain, readonly ) NSInputStream *            inputStream;
@property (nonatomic, retain, readonly ) NSOutputStream *           outputStream;

// properties that must be configured before -open

@property (nonatomic, assign, readwrite) NSUInteger                 inputBufferCapacity;            // default is 0, meaning chose a reasonable default
@property (nonatomic, assign, readwrite) NSUInteger                 outputBufferCapacity;           // default is 0, meaning chose a reasonable default

// You must open or remove run loop modes before opening the connection

- (void)addRunLoopMode:(NSString *)modeToAdd;
- (void)removeRunLoopMode:(NSString *)modeToRemove;

@property (nonatomic, copy,   readonly ) NSSet *                    runLoopModes;                   // contains NSDefaultRunLoopMode by default

// properties that can be set at any time

@property (nonatomic, assign, readwrite) id<QCommandConnectionDelegate>    delegate;
@property (nonatomic, copy,   readwrite) NSString *                 name;                           // for debugging

// properties that change as the result of other actions

@property (nonatomic, assign, readonly ) BOOL                       isOpen;
@property (nonatomic, copy,   readwrite) NSError *                  error;

// actions

- (void)open;
    // Opens the connection.  It's not legal to call this if the connection has 
    // already been opened.  If the open fails, this calls the 
    // -connection:willCloseWithError: delegate method.

- (void)close;
    // Closes the connection.  It is safe to call this even if -open has not called, 
    // or the connection has already closed.  Will not call -connection:willCloseWithError: 
    // delegate method (that method is only called if the connection closes by 
    // itself).

- (void)closeWithError:(NSError *)error;
    // Closes the connection with the specified error (nil to indicate an end of file), 
    // much like what happens if the connection tears (or ends).  This is primarily for 
    // subclasses and delegates.  It is safe to call this even if -open has not called, 
    // or the connection has already closed.  This /will/ end up calling the 
    // -connection:willCloseWithError: delegate method.

- (void)sendCommand:(NSData *)command;
    // Sends the specified command down the connection.  Note that there's no send-side 
    // flow control here.  If the connection stops sending data, eventually the buffer 
    // space will fill up and connection will tear.

@end

@protocol QCommandConnectionDelegate <NSObject>

@optional

- (void)connection:(QCommandConnection *)connection willCloseWithError:(NSError *)error;
    // Called when the connection fails to open or closes badly (error is not nil), or if 
    // there's an EOF (error is nil).

- (NSUInteger)connection:(QCommandConnection *)connection parseCommandData:(NSData *)commandData;
    // Called when data arrives on the connection.  The delegate is expected to parse the 
    // data to see if there's a complete command present.  If so, it should consume the 
    // command and return the number of bytes consumed.  If not, it should return 0 
    // and will be called again when the next chunk of data arrives.
    //
    // It is more efficient if the delegate parses out multiple commands in one call, 
    // but that is not strictly necessary.
    //
    // If the delegate detects some sort of failure it is reasonable for it to force 
    // the connection to close by calling -closeWithError:.
    //
    // If the delegate does not implement this method, any data arriving on the input stream 
    // will cause the connection to fail with kQCommandConnectionInputUnexpectedError.

- (void)connection:(QCommandConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList;
    // Called to log connection activity.

@end

// The following methods are exported for the benefit of subclasses.  Specifically, 
// they allow subclasses to see the delegate methods without actually being the 
// delegate.  The default implementation of these routines just calls the 
// delegate callback, if any.

@interface QCommandConnection (ForSubclassOverride)

- (void)willCloseWithError:(NSError *)error;

- (NSUInteger)parseCommandData:(NSData *)commandData;

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;

@end

// The following methods are exported for the benefit of subclasses.

@interface QCommandConnection (ForSubclassUse)

- (void)logWithFormat:(NSString *)format, ...;
    // This allows subclasses to log things to the connection delegate.

+ (NSError *)errorWithCode:(NSInteger)code;
    // This allows subclasses to construct errors in the kQCommandConnectionErrorDomain.

@end

// Most connection errors come from NSStream, but some are generated internally.

extern NSString * kQCommandConnectionErrorDomain;

enum {
    kQCommandConnectionOutputBufferFullError = 1, 
    kQCommandConnectionInputBufferFullError = 2,
    kQCommandConnectionOutputCommandTooLongError = 3,
    kQCommandConnectionInputUnexpectedError = 4, 
    kQCommandConnectionInputCommandTooLongError = 5, 
    kQCommandConnectionInputCommandMalformedError = 6       // for the benefit of our subclasses
};
