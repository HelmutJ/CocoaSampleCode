/*
    File:       RemoteCurrencyServer.m

    Contains:   A server for the remote currency protocol.

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

#import "RemoteCurrencyServer.h"

#import "RemoteCurrencyServerConnection.h"

#import "QServer.h"

@interface RemoteCurrencyServer () <RemoteCurrencyServerConnectionDelegate, QServerDelegate>

@property (nonatomic, retain, readwrite) QServer *      server;

@end

@implementation RemoteCurrencyServer

@synthesize port           = port_;
@synthesize disableIPv6    = disableIPv6_;
@synthesize disableBonjour = disableBonjour_;

@synthesize server = server_;

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->port_ = 12345;
    }
    return self;
}

- (void)dealloc
{
    assert(self->server_ == nil);           // should be nil because someone should have called -stop
    [super dealloc];
}

#pragma mark * Start and stop

- (void)start
{
    NSString *  type;
    
    assert(self.server == nil);
    
    if (self.disableBonjour) {
        type = nil;
    } else {
        type = @"_x-remotecurrency._tcp";
    }
    
    self.server = [[[QServer alloc] initWithDomain:nil type:type name:nil preferredPort:self.port] autorelease];
    assert(self.server != nil);
    
    self.server.delegate = self;
    if (self.disableIPv6) {
        self.server.disableIPv6 = YES;
    }

    [self.server start];
}

- (void)stop
{
    if (self.server != nil) {
        [self.server stop];
        self.server = nil;
    }
}

- (void)run
{
    [self start];
    
    while (self.server != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    // We can't leave the loop unless the server has stopped, so we 
    // don't need to stop it again.
    //
    // [self stop];
}

#pragma mark * Server delegate callbacks

- (void)serverDidStart:(QServer *)server
{
    assert(server == self.server);
}

- (void)server:(QServer *)server didStopWithError:(NSError *)error
{
    assert(server == self.server);
    assert(error != nil);
    [self stop];
}

- (id)server:(QServer *)server connectionForInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    RemoteCurrencyServerConnection *  connection;
    
    assert(server == self.server);
    assert(inputStream  != nil);
    assert(outputStream != nil);

    connection = [[[RemoteCurrencyServerConnection alloc] initWithInputStream:inputStream outputStream:outputStream] autorelease];
    if (connection != nil) {
        connection.serverDelegate = self;
        connection.name = [NSString stringWithFormat:@"%zu", (size_t) self.server.connectionSequenceNumber];
        
        [connection open];
    }
    return connection;
}

- (void)server:(QServer *)server closeConnection:(id)connection
{
    assert(server == self.server);
    assert( [connection isKindOfClass:[RemoteCurrencyServerConnection class]] );
    [ (RemoteCurrencyServerConnection *) connection close];
}

- (void)server:(QServer *)server logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString *  str;
    
    assert(server == self.server);
    assert(format != nil);

    str = [[NSString alloc] initWithFormat:format arguments:argList];
    assert(str != nil);
    NSLog(@"server %@", str);
    [str release];
}

#pragma mark * Connection delegate callbacks

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection willCloseWithError:(NSError *)error
{
    assert(connection != nil);
    assert([self.server.connections containsObject:connection]);
    #pragma unused(error)
    [self.server closeOneConnection:connection];
}

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString *  str;
    
    assert(connection != nil);
    // assert([self.server.connections containsObject:connection]);     // Not always the case, because logs are recorded before we return 
    assert(format != nil);                                              // from -server:connectionForInputStream:outputStream:
    
    str = [[NSString alloc] initWithFormat:format arguments:argList];
    assert(str != nil);
    NSLog(@"control-%@ %@", connection.name, str);
    [str release];
}

#pragma mark * Command processing

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection helloCommand:(NSScanner *)scanner
    // Implements the 'hello' command.
{
    assert(connection != nil);
    assert([scanner isAtEnd]);
    [connection sendResponse:@"Hello Cruel World!"];
}

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection goodbyeCommand:(NSScanner *)scanner
    // Implements the 'goodbye' command.
{
    assert(connection != nil);
    assert([scanner isAtEnd]);
    [connection sendResponse:@"Goodbye Cruel World!"];
    [connection close];
    [self.server closeOneConnection:connection];
}

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection stopCommand:(NSScanner *)scanner
    // Implements the 'stop' command.
{
    assert(connection != nil);
    assert([scanner isAtEnd]);
    [connection sendResponse:@"Daisy, Daisy, give me your answer do..."];
    [self stop];
}

- (BOOL)scanCurrency:(double *)valuePtr from:(NSScanner *)scanner
    // Scans a currency symbol from the scanner object, returning YES if it found one 
    // and the conversion rate (relative to the Euro) in *valuePtr.
{
    BOOL        success;
    NSString *  currencyStr;
    NSNumber *  valueObj;
    
    assert(valuePtr != NULL);
    assert(scanner != nil);
    
    success = [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&currencyStr];
    if (success) {
        static NSDictionary *  sValueFromCurrencyStr;
        
        if (sValueFromCurrencyStr == nil) {
            sValueFromCurrencyStr = [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSNumber numberWithDouble:1.3246], @"USD", 
                [NSNumber numberWithDouble:1.0],    @"EUR", 
                [NSNumber numberWithDouble:0.848],  @"GBP", 
                [NSNumber numberWithDouble:110.86], @"JPY", 
                [NSNumber numberWithDouble:1.3508], @"AUD", 
                nil
            ];
            assert(sValueFromCurrencyStr != nil);
        }
        
        valueObj = [sValueFromCurrencyStr objectForKey:[currencyStr uppercaseString]];
        success = (valueObj != nil);
        
        if (success) {
            *valuePtr = [valueObj doubleValue];
        }
    }
    return success;
}

- (void)remoteCurrencyServerConnection:(RemoteCurrencyServerConnection *)connection convertCommand:(NSScanner *)scanner
    // Implements the 'convert' command.
{
    BOOL        success;
    double      fromCurrency;
    double      fromValue;
    double      toCurrency;
    double      result;
    
    assert(connection != nil);
    assert(scanner != nil);

    success = [self scanCurrency:&fromCurrency from:scanner];
    if ( ! success ) {
        [connection sendError:@"From currency expected"];
    }
    
    if (success) {
        success = [scanner scanDouble:&fromValue];
        if ( ! success ) {
            [connection sendError:@"From value expected"];
        }
    }
    
    if (success) {
        success = [scanner scanString:@"to" intoString:NULL];
        if ( ! success ) {
            [connection sendError:@"'to' expected"];
        }
    }

    if (success) {
        success = [self scanCurrency:&toCurrency from:scanner];
        if ( ! success ) {
            [connection sendError:@"To currency expected"];
        }
    }
    
    if (success && ! [scanner isAtEnd]) {
        success = NO;
        [connection sendError:@"End of command expected"];
    }
    
    if (success) {
        result = (fromValue / fromCurrency) * toCurrency;
        [connection sendResponse:@"OK" lines:[NSArray arrayWithObject:[NSString stringWithFormat:@"%.2f", result]]];
    }
}

@end
