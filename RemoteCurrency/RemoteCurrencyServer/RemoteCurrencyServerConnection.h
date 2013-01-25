/*
    File:       RemoteCurrencyServerConnection.h

    Contains:   Manages the server side of a client-server connection.

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

#import "QCommandLineConnection.h"

/*
    Protocol Notes
    --------------
    The server implements a very simple command line protocol:
    
    o Each incoming request is just a command line with a CR LF terminator.
    
    o A response consists of one or more data lines followed by a status 
      line.  Each data line starts with two spaces and ends with a CR LF.
      The status line starts with either a plus or a minus character, 
      followed by a space, followed by a comment, where a plus indicates 
      success and a minus indicates failure.
    
    o An empty line is considered a valid command, which the server 
      acknowledges as success automatically.

    For example, a help command sequence starts by the client sending 
    the following:
    
    "help" CR LF
    
    to which the server replies:
    
    "  convert <name> <value> to <name>" CR LF
    "  goodbye" CR LF
    "  hello" CR LF
    "  help" CR LF
    "  stop" CR LF
    "+ OK" CR LF    

    The commands supported by this connection are all pretty boring, except 
    for the convert "command", which is the command used by the client to 
    actually converter currencies.
*/

@protocol RemoteCurrencyServerConnectionDelegate;

@interface RemoteCurrencyServerConnection : QCommandLineConnection

// Most of the heavy lifting is done by the QCommandLineConnection superclass.  The 
// following inherited methods are critical to all clients:
// 
// - (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
// - (void)open;
// - (void)close;

@property (nonatomic, assign, readwrite) id<RemoteCurrencyServerConnectionDelegate> serverDelegate;

- (void)sendResponse:(NSString *)response;
    // Sends a single line response to the client, prefixed by "+ ".
    
- (void)sendResponse:(NSString *)response lines:(NSArray *)lines;
    // Sends a multi-line response to the client, where each line 
    // from the lines array is sent prefixed by two spaces, followed 
    // by a positive response consisting of "+ " and the response 
    // string.
    // 
    // lines may be empty, in which case this is the same as calling 
    // -sendResponse:.

- (void)sendError:(NSString *)response;
    // Sends an error to the client, prefixed by "- ".

@end

@protocol RemoteCurrencyServerConnectionDelegate <NSObject>

@required

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection willCloseWithError:(NSError *)error;
    // Called when the connection is closed from the network side of things (but not 
    // if you call -close on it).  You should implement this method to remove the connection 
    // from your table of active connections.
    //
    // error will be nil if the connection closed due to EOF; otherwise 
    // error will represent the reason for the close.

// The following are called when the connection parses the corresponding incoming command. 
// The supplied scanner object has already skipped over the command (and any trailing 
// whilespace) and the delegate can use it to extract command arguments.
//
// Note that the help command is implemented internally by the connection object itself.

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection helloCommand:(NSScanner *)scanner;
- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection goodbyeCommand:(NSScanner *)scanner;
- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection stopCommand:(NSScanner *)scanner;
- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection convertCommand:(NSScanner *)scanner;

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList;
    // Called when the connection wants to log something.

@end
