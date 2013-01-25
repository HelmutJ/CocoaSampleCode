/*
    File:       RemoteCurrencyClientConnection.m

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

#import "RemoteCurrencyClientConnection.h"

@interface RemoteCurrencyClientConnection ()

@property (nonatomic, retain, readonly ) NSMutableArray *   requests;
@property (nonatomic, retain, readonly ) NSMutableArray *   lines;

@end

@implementation RemoteCurrencyClientConnection

@synthesize clientDelegate = clientDelegate_;
@synthesize requests       = requests_;
@synthesize lines          = lines_;

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    self = [super initWithInputStream:inputStream outputStream:outputStream];
    if (self) {
        self->requests_ = [[NSMutableArray alloc] init];
        self->lines_    = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self->requests_ release];
    [self->lines_ release];
    [super dealloc];
}

#pragma mark * Overrides

// See comment in header for an explanation of what these routines are about.

- (void)willCloseWithError:(NSError *)error
{
    // error may be nil
    if ([self.clientDelegate respondsToSelector:@selector(remoteCurrencyClientConnection:willCloseWithError:)]) {
        [self.clientDelegate remoteCurrencyClientConnection:self willCloseWithError:error];
    }
    [super willCloseWithError:error];
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
    assert(format != nil);
    if ([self.clientDelegate respondsToSelector:@selector(remoteCurrencyClientConnection:logWithFormat:arguments:)]) {
        [self.clientDelegate remoteCurrencyClientConnection:self logWithFormat:format arguments:argList];
    }
    [super logWithFormat:format arguments:argList];
}

#pragma mark * Send

- (void)sendRequest:(NSString *)request
{
    assert(request != nil);
    [self.requests addObject:request];
    [self sendCommandLine:request];
}

#pragma mark * Parse

- (void)didReceiveCommandLine:(NSString *)commandLine
{
    BOOL        success;
    NSString *  prefix;
    NSString *  content;
    
    assert(commandLine != nil);
    assert([commandLine length] >= 2);  // because of the trailing CR LF
    
    // Check whether there are any requests pending.  If there aren't, the server 
    // is sending us random stuff that we don't know what to do with, and we die.
    
    success = NO;
    if ([self.requests count] != 0) {
        prefix = [commandLine substringToIndex:2];
        assert(prefix != nil);
        
        // We calculate content in advance because it's needed by all of the branches 
        // of the long 'if' chain to follow.  However, we can't be guaranteed to have 
        // any useful content unless the command line is 4 characters long (that is, the 
        // prefix and the trailing CR LF), so we only calculate content in that case. 
        // However, if a valid prefix is found then content must be valid because 
        // we know we have a valid prefix and we know we have a CR LF suffix.
        // Yikes!
        
        if ([commandLine length] < 4) {
            content = nil;
        } else {
            content = [commandLine substringWithRange:NSMakeRange(2, [commandLine length] - 4)];
            assert(content != nil);
        }
        
        // Act according to the prefix.
        
        success = YES;
        if ([prefix isEqual:@"  "]) {
            assert(content != nil);
            [self.lines addObject:content];
        } else if ([prefix isEqual:@"+ "]) {
            NSArray *   responseLines;
            responseLines = [[self.lines copy] autorelease];    // latch and then discard any lines we've received
            assert(responseLines != nil);
            [self.lines removeAllObjects];
            [self.requests removeObjectAtIndex:0];              // we've completed this request
            assert(content != nil);
            [self.clientDelegate remoteCurrencyClientConnection:self didReceiveResponse:content lines:responseLines];
        } else if ([prefix isEqual:@"- "]) {
            [self.lines removeAllObjects];                      // we discard any lines we got
            [self.requests removeObjectAtIndex:0];              // we've completed this request
            assert(content != nil);
            [self.clientDelegate remoteCurrencyClientConnection:self didReceiveError:content];
        } else {
            success = NO;
        }
    }

    if ( ! success ) {
        [self closeWithError:[[self class] errorWithCode:kQCommandConnectionInputCommandMalformedError]];
    }
}


@end
