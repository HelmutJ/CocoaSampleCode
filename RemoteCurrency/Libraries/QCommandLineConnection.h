/*
    File:       QCommandLineConnection.h

    Contains:   Manages a connection consisting of CR LF delimited lines.

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

// QCommandLineConnection is a subclass of QCommandConnection that managers 
// command-oriented network connection where the commands are lines of text, 
// each separated by a CR LF.
// 
// The class is run loop based and must be called from a single thread. 
// Specifically, the -open and -close methods add and remove run loop sources 
// to the current thread's run loop, and it's that thread that calls the 
// delegate callbacks.

@protocol QCommandLineConnectionDelegate;

@interface QCommandLineConnection : QCommandConnection

// Most of the heavy lifting is done by the QCommandConnection superclass.  The 
// following inherited methods are critical to all clients:
// 
// - (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
// - (void)open;
// - (void)close;

@property (nonatomic, assign, readwrite) id<QCommandLineConnectionDelegate> commandDelegate;

- (void)sendCommandLine:(NSString *)line;
    // Sends a single command line to the peer, adding CR LF to the end.
    
- (void)sendCommandLines:(NSArray *)lines;
    // Sends a list of command lines to the peer, adding CR LF after each.
    // lines must have at least one element.

@end

@protocol QCommandLineConnectionDelegate <NSObject>

@optional

- (void)commandLineConnection:(QCommandLineConnection *)connection willCloseWithError:(NSError *)error;
    // Called when the connection is closed from the network side of things (but not 
    // if you call -close on it).  You should implement this method to remove the connection 
    // from your table of active connections.
    //
    // error will be nil if the connection closed due to EOF; otherwise 
    // error will represent the reason for the close.

- (void)commandLineConnection:(QCommandLineConnection *)connection didReceiveCommandLine:(NSString *)commandLine;
    // Called when the connection receives a command line.  The command line will be CR LF 
    // terminated but may be empty.  If the command is unknown or malformed, the delegate 
    // can send an error response using -sendCommandLine:, or close the connection with 
    // -close, or both.

- (void)commandLineConnection:(QCommandLineConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList;
    // Called when the connection wants to log something.

@end

// The following methods are exported for the benefit of subclasses.  Specifically, 
// they allow subclasses to see the delegate methods without actually being the 
// command delegate.  The default implementation of these routines just calls the 
// command delegate callback, if any, and then calls super (resulting in a call to the 
// connection delegate callback, if any).

@interface QCommandLineConnection (ForSubclassOverride)

- (void)willCloseWithError:(NSError *)error;

- (void)didReceiveCommandLine:(NSString *)commandLine;

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;

@end
