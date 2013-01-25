/*
    File:       RemoteCurrencyConverter.m

    Contains:   A model object that manages all networking within the client app.

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

#import "RemoteCurrencyConverter.h"

#import "RemoteCurrencyClientConnection.h"

@interface RemoteCurrencyConverter () <RemoteCurrencyClientConnectionDelegate>

// read/write versions of public properties

@property (nonatomic, assign, readwrite) RemoteCurrencyConverterStatus      status;
@property (nonatomic, assign, readwrite) BOOL                               networkActive;
@property (nonatomic, assign, readwrite) BOOL                               finished;
@property (nonatomic, copy,   readwrite) NSNumber *                         result;

// private properties

@property (nonatomic, retain, readwrite) RemoteCurrencyClientConnection *   connection;
@property (nonatomic, copy,   readwrite) NSString *                         pendingCommand;

@property (nonatomic, retain, readwrite) NSTimer *                          dummyConversionTimer;

@end

@implementation RemoteCurrencyConverter

@synthesize status        = status_;
@synthesize netService    = netService_;
@synthesize networkActive = networkActive_;
@synthesize result        = result_;
@synthesize finished      = finished_;

@synthesize connection     = connection_;
@synthesize pendingCommand = pendingCommand_;

@synthesize dummyConversionTimer = dummyConversionTimer_;

- (id)initWithNetService:(NSNetService *)netService
{
    assert(netService != nil);
    self = [super init];
    if (self != nil) {
        self->status_ = kRemoteCurrencyConverterInitialised;
        self->netService_ = [netService retain];
    }
    return self;
}

- (void)dealloc
{
    // All of the following should have be cleaned up by -stopConverting 
    // (actually, either -networkStopConverting or -dummyStopConverting).
    assert(self->connection_ == nil);
    assert(self->pendingCommand_ == nil);
    assert(self->dummyConversionTimer_ == nil);
    
    [self->netService_ release];
    [self->result_ release];
    
    [super dealloc];
}

#pragma mark * Network core conversion

+ (NSString *)nextConnectionName
{
    static NSUInteger sConnectionSequenceNumber;
    NSString *  result;
    
    result = [NSString stringWithFormat:@"%zu", (size_t) sConnectionSequenceNumber];
    sConnectionSequenceNumber += 1;
    return result;
}

- (void)networkStartConvertingValue:(double)value fromCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency
    // The network implementation of -startConvertingValue:fromCurrency:toCurrency:, for which you 
    // should see the comments in the header.
{
    #pragma unused(value)
    #pragma unused(fromCurrency)
    #pragma unused(toCurrency)
    NSString *  command;
    
    assert(fromCurrency != nil);
    assert(toCurrency != nil);

    // If the connection is not open, open it.

    if (self.connection == nil) {
        NSInputStream *     input;
        NSOutputStream *    output;

        assert( (self.status == kRemoteCurrencyConverterInitialised) || (self.status == kRemoteCurrencyConverterClosed) || (self.status == kRemoteCurrencyConverterFailed) );
        
        [self.netService getInputStream:&input outputStream:&output];
        
        self.connection = [[[RemoteCurrencyClientConnection alloc] initWithInputStream:input outputStream:output] autorelease];
        self.connection.clientDelegate = self;
        self.connection.name = [[self class] nextConnectionName];
        [self.connection open];
        
        // -[NSNetService getInputStream:outputStream:] currently returns the stream 
        // with a reference that we have to release (something that's counter to the 
        // standard Cocoa memory management rules <rdar://problem/6868813>).
        
        [input release];
        [output release];
        
        self.status = kRemoteCurrencyConverterIdle;
    }
    assert( (self.status == kRemoteCurrencyConverterIdle) || (self.status == kRemoteCurrencyConverterConverting) );

    // Form up a command based on the inputs.
    
    command = [NSString stringWithFormat:@"convert %@ %.2f to %@", fromCurrency, value, toCurrency];
    assert(command != nil);

    // If the connection is idle, send the command straight away.  If we're still 
    // waiting for a result, store this command in pendingCommand, replacing any 
    // previous pending command, so that it gets sent then the current command completes.
    
    switch (self.status) {
        case kRemoteCurrencyConverterIdle: {
            assert(self.pendingCommand == nil);
            [self.connection sendRequest:command];
            self.networkActive = YES;
            self.finished = NO;
            self.status = kRemoteCurrencyConverterConverting;
        } break;
        case kRemoteCurrencyConverterConverting: {
            self.pendingCommand = command;
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)networkFailedConverting
{
    if (self.connection != nil) {
        self.connection.delegate = nil;
        [self.connection close];
        self.connection = nil;
    }
    self.pendingCommand = nil;
    self.status = kRemoteCurrencyConverterFailed;
    self.networkActive = NO;
    self.finished = NO;
}

- (void)networkStopConverting
    // The network implementation of -stopConverting, for which you should see the comments in the header.
{
    if (self.connection != nil) {
        self.connection.delegate = nil;
        [self.connection close];
        self.connection = nil;
    }
    self.pendingCommand = nil;
    self.status = kRemoteCurrencyConverterClosed;
    self.networkActive = NO;
    self.finished = NO;
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection willCloseWithError:(NSError *)error
    // Called by the network connection when the connection tears. The current implementation 
    // just shuts everything down and leaves it up to the user to trigger a retry.
{
    assert(connection == self.connection);
    #pragma unused(error)
    // error may be nil
    [self networkFailedConverting];
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveResponse:(NSString *)response lines:(NSArray *)lines
    // Called by the network connection when it receives a valid response from the server. 
    // This parses the response to extract the converted value and then passes that 
    // back up to the user interface.  Also, if there is a pending conversion, it kicks 
    // that off.
{
    BOOL            success;
    NSScanner *     scanner;
    double          value;
    
    assert(self.status == kRemoteCurrencyConverterConverting);
    
    assert(connection == self.connection);
    assert(response != nil);
    assert(lines != nil);
    
    success = NO;
    if ([response caseInsensitiveCompare:@"OK"] == NSOrderedSame) {
        if ([lines count] == 1) {
            scanner = [NSScanner scannerWithString:[lines objectAtIndex:0]];
            assert(scanner != nil);
            
            success = [scanner scanDouble:&value];
            if (success) {
                success = [scanner isAtEnd];
            }
        }
    }
    if (success) {
        self.result = [NSNumber numberWithDouble:value];
        
        // If a subsequent conversion got queued behind this one, start it. 
        // Otherwise all our conversions are done and we can set finished, 
        // which triggers a UI update.
        
        if (self.pendingCommand != nil) {
            NSString *  command;
            
            command = [[self.pendingCommand retain] autorelease];
            self.pendingCommand = nil;

            [self.connection sendCommandLine:command];
        } else {
            self.status = kRemoteCurrencyConverterIdle;
            self.networkActive = NO;
            self.finished = YES;
        }
    } else {
        [self networkFailedConverting];
    }
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection didReceiveError:(NSString *)errorResponse
    // Called by the network connection it receives an error response from the server. 
    // The current implementation just shuts everything down and leaves it up to the user 
    // to trigger a retry.
{
    assert(connection == self.connection);
    assert(errorResponse != nil);
    [self networkFailedConverting];
}

- (void)remoteCurrencyClientConnection:(RemoteCurrencyClientConnection *)connection logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString *  str;
    assert(connection != nil);
    assert( (self.connection == nil) || (connection == self.connection) );          // self.connection can be nil during shut down
    assert(format != nil);
    
    str = [[NSString alloc] initWithFormat:format arguments:argList];
    assert(str != nil);
    NSLog(@"control-%@ %@", connection.name, str);
    [str release];
}

#pragma mark * Dummy core conversion

// To make testing easier we have a dummy converter that juts converts values 
// locally, with a suitable delay.

- (void)dummyStartConvertingValue:(double)value fromCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency
    // The local implementation of -startConvertingValue:fromCurrency:toCurrency:, for which you 
    // should see the comments in the header.  This uses an NSTimer to simulate the delays caused 
    // by a network operation.
{
    static NSDictionary *  sValueFromCurrencyStr;
    NSDictionary *  userInfo;
    NSNumber *      fromValueObj;
    NSNumber *      toValueObj;

    assert(fromCurrency != nil);
    assert(toCurrency != nil);
        
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
    
    fromValueObj = [sValueFromCurrencyStr objectForKey:fromCurrency];
    assert(fromValueObj != nil);
    toValueObj = [sValueFromCurrencyStr objectForKey:toCurrency];
    assert(toValueObj != nil);
        
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:value / [fromValueObj doubleValue] * [toValueObj doubleValue]], @"result", 
        nil
    ];
    assert(userInfo != nil);

    self.result = nil;
    self.networkActive = YES;
    self.finished = NO;

    [self.dummyConversionTimer invalidate];
    self.dummyConversionTimer = nil;

    self.dummyConversionTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(didFinishDummyConversionTimer:) userInfo:userInfo repeats:NO];
}

- (void)dummyStopConverting
    // The local implementation of -stopConverting, for which you should see the comments in the header.
{
    if (self.dummyConversionTimer != nil) {
        assert(self.result == nil);
        assert(self.networkActive);
        assert( ! self.finished );
        [self.dummyConversionTimer invalidate];
        self.dummyConversionTimer = nil;
        self.networkActive = NO;
        self.finished = NO;
    }
}

- (void)didFinishDummyConversionTimer:(NSTimer *)timer
    // Called when the dummy conversion timer fires, this sets up the result 
    // so that the app can see it.
{
    NSDictionary *  userInfo;
    
    assert(timer == self.dummyConversionTimer);
    assert(self.result == nil);
    assert(self.networkActive);
    assert( ! self.finished );

    userInfo = [[[timer userInfo] retain] autorelease];
    assert(userInfo != nil);

    [self.dummyConversionTimer invalidate];
    self.dummyConversionTimer = nil;
    
    self.result = [userInfo objectForKey:@"result"];
    self.networkActive = NO;
    self.finished = YES;
}

#pragma mark * Core conversion dispatch

- (void)startConvertingValue:(double)value fromCurrency:(NSString *)fromCurrency toCurrency:(NSString *)toCurrency
    // See comment in header.
{
    assert(fromCurrency != nil);
    assert(toCurrency != nil);

    // Dispatches to either the network converter or our dummy local converter.
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"enableDummyLocalConverter"]) {
        [self dummyStartConvertingValue:value fromCurrency:fromCurrency toCurrency:toCurrency];
    } else {
        [self networkStartConvertingValue:value fromCurrency:fromCurrency toCurrency:toCurrency];
    }
}

- (void)stopConverting
    // See comment in header.
{
    // Dispatches to either the network converter or our dummy local converter.
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"enableDummyLocalConverter"]) {
        [self dummyStopConverting];
    } else {
        [self networkStopConverting];
    }
}

@end
