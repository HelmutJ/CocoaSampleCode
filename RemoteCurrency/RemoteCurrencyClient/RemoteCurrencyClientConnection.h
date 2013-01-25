/*
    File:       RemoteCurrencyClientConnection.h

    Contains:   Manages the client side of a client-server connection.

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

@protocol RemoteCurrencyClientConnectionDelegate;

@interface RemoteCurrencyClientConnection : QCommandLineConnection

// Most of the heavy lifting is done by the QCommandLineConnection superclass.  The 
// following inherited methods are critical to all clients:
// 
// - (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
// - (void)open;
// - (void)close;

@property (nonatomic, assign, readwrite) id<RemoteCurrencyClientConnectionDelegate> clientDelegate;

- (void)sendRequest:(NSString *)request;
    // Sends a request to the server, adding the CR LF.

@end

@protocol RemoteCurrencyClientConnectionDelegate <NSObject>

@required

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection willCloseWithError:(NSError *)error;
    // Called when the connection is closed from the network side of things (but not 
    // if you call -close on it).  You should implement this method to remove the connection 
    // from your table of active connections.
    //
    // error will be nil if the connection closed due to EOF; otherwise 
    // error will represent the reason for the close.

// IMPORTANT: Commands are always processed in order, so this response is implicitly the response 
// to the oldest unresponded to request (where a request is considered responded to by either 
// didReceiveResponse or didReceiveError).

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveResponse:(NSString *)response lines:(NSArray *)lines;
    // Called when the server receives a response for a request.  response is the actual response 
    // text, which does not include the "+ " prefix.  lines contains the data lines associated with 
    // the response; it will never be nil but may be empty.
    
- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveError:(NSString *)errorResponse;
    // Called when the server receives an error response for a request.  errorResponse is the actual 
    // text, which does not include the "- " prefix.

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList;
    // Called when the connection wants to log something.

@end
