/*
    File:       QHTTPOperation.m

    Contains:   An NSOperation that runs an HTTP request.

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

#import "QHTTPOperation.h"

@interface QHTTPOperation ()

// Read/write versions of public properties

@property (copy,   readwrite) NSURLRequest *        lastRequest;
@property (copy,   readwrite) NSHTTPURLResponse *   lastResponse;

// Internal properties

@property (retain, readwrite) NSURLConnection *     connection;
@property (assign, readwrite) BOOL                  firstData;
@property (retain, readwrite) NSMutableData *       dataAccumulator;

#if ! defined(NDEBUG)
@property (retain, readwrite) NSTimer *             debugDelayTimer;
#endif

@end

@implementation QHTTPOperation

@synthesize request         = request_;

@synthesize acceptableStatusCodes = acceptableStatusCodes_;
@synthesize acceptableContentTypes = acceptableContentTypes_;
@synthesize authenticationDelegate = authenticationDelegate_;

@synthesize responseOutputStream = responseOutputStream_;
@synthesize defaultResponseSize = defaultResponseSize_;
@synthesize maximumResponseSize = maximumResponseSize_;

@synthesize lastRequest     = lastRequest_;
@synthesize lastResponse    = lastResponse_;
@synthesize responseBody    = responseBody_;

@synthesize connection      = connection_;
@synthesize firstData       = firstData_;
@synthesize dataAccumulator = dataAccumulator_;

#pragma mark * Initialise and finalise

static NSSet * sKeysImmutableWhileExecuting;
static NSSet * sKeysImmutableOnceDataReceived;

- (id)initWithRequest:(NSURLRequest *)request
    // See comment in header.
{
    // Initialise some globals.
    
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sKeysImmutableWhileExecuting = [[NSSet alloc] initWithObjects:
            @"acceptableStatusCodes", 
            @"acceptableContentTypes", 
            @"authenticationDelegate", 
            nil
        ];
        sKeysImmutableOnceDataReceived = [[NSSet alloc] initWithObjects:
            @"responseOutputStream", 
            @"defaultResponseSize", 
            @"maximumResponseSize", 
            nil
        ];
    });

    // any thread
    assert(request != nil);
    assert([request URL] != nil);
    // Because we require an NSHTTPURLResponse, we only support HTTP and HTTPS URLs.
    assert([[[[request URL] scheme] lowercaseString] isEqual:@"http"] || [[[[request URL] scheme] lowercaseString] isEqual:@"https"]);
    self = [super init];
    if (self != nil) {
        #if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
            static const NSUInteger kPlatformReductionFactor = 4;
        #else
            static const NSUInteger kPlatformReductionFactor = 1;
        #endif
        self->request_ = [request copy];
        self->defaultResponseSize_ = 1 * 1024 * 1024 / kPlatformReductionFactor;
        self->maximumResponseSize_ = 4 * 1024 * 1024 / kPlatformReductionFactor;
        self->firstData_ = YES;

        // Add a set of KVO observers that watch for clients not playing by the rules.
    
        assert(sKeysImmutableWhileExecuting != nil);
        for (NSString * key in sKeysImmutableWhileExecuting) {
            [self addObserver:self forKeyPath:key options:0 context:&self->connection_];
        }
        assert(sKeysImmutableOnceDataReceived != nil);
        for (NSString * key in sKeysImmutableOnceDataReceived) {
            [self addObserver:self forKeyPath:key options:0 context:&self->lastResponse_];
        }
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
    // See comment in header.
{
    assert(url != nil);
    return [self initWithRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dealloc
{
    // Remove the observers added at init time.
    
    assert(sKeysImmutableWhileExecuting != nil);
    for (NSString * key in sKeysImmutableWhileExecuting) {
        [self removeObserver:self forKeyPath:key];
    }
    assert(sKeysImmutableOnceDataReceived != nil);
    for (NSString * key in sKeysImmutableOnceDataReceived) {
        [self removeObserver:self forKeyPath:key];
    }

    #if ! defined(NDEBUG)
        [self->debugError_ release];
        [self->debugDelayTimer_ invalidate];
        [self->debugDelayTimer_ release];
    #endif
    // any thread
    [self->request_ release];
    [self->acceptableStatusCodes_ release];
    [self->acceptableContentTypes_ release];
    [self->responseOutputStream_ release];
    assert(self->connection_ == nil);               // should have been shut down by now
    [self->dataAccumulator_ release];
    [self->lastRequest_ release];
    [self->lastResponse_ release];
    [self->responseBody_ release];
    [super dealloc];
}

#pragma mark * Properties

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // Our API contract states that you're not allowed to change many of the readwrite 
    // properties at certain points in time.  In previous versions of the code I had 
    // custom setters to enforce these rules.  That's a painful amount of code if you 
    // consider that it only really benefits developers.  I've removed all those setters 
    // and now use KVO to watch for changes and complain if I see any.
{
    if (context == &self->connection_) {
        assert([sKeysImmutableWhileExecuting containsObject:keyPath]);
        assert(object == self);
        if (self.state == kQRunLoopOperationStateExecuting) {
            NSLog(@"*** Programmer Error *** Changed key %@ of %@ while executing", keyPath, self);
            assert(NO);
        }
    } else if (context == &self->lastResponse_) {
        assert([sKeysImmutableOnceDataReceived containsObject:keyPath]);
        assert(object == self);
        if (self.dataAccumulator != nil) {
            NSLog(@"*** Programmer Error *** Changed key %@ of %@ after data received", keyPath, self);
            assert(NO);
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSURL *)URL
{
    return [self.request URL];
}

- (BOOL)isStatusCodeAcceptable
{
    NSIndexSet *    acceptableStatusCodes;
    NSInteger       statusCode;
    
    assert(self.lastResponse != nil);
    
    acceptableStatusCodes = self.acceptableStatusCodes;
    if (acceptableStatusCodes == nil) {
        acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    assert(acceptableStatusCodes != nil);
    
    statusCode = [self.lastResponse statusCode];
    return (statusCode >= 0) && [acceptableStatusCodes containsIndex: (NSUInteger) statusCode];
}

- (BOOL)isContentTypeAcceptable
{
    NSString *  contentType;
    
    assert(self.lastResponse != nil);
    contentType = [self.lastResponse MIMEType];
    return (self.acceptableContentTypes == nil) || ((contentType != nil) && [self.acceptableContentTypes containsObject:contentType]);
}

#pragma mark * Start and finish overrides

- (void)operationDidStart
    // Called by QRunLoopOperation when the operation starts.  This kicks of an 
    // asynchronous NSURLConnection.
{
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);
    
    assert(self.defaultResponseSize > 0);
    assert(self.maximumResponseSize > 0);
    assert(self.defaultResponseSize <= self.maximumResponseSize);
    
    assert(self.request != nil);
    
    assert(self.connection == nil);
    if ([self isCancelled]) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    } else {
        // If a debug error is set, apply that error rather than running the connection.
        
        #if ! defined(NDEBUG)
            if (self.debugError != nil) {
                [self finishWithError:self.debugError];
                return;
            }
        #endif

        // Create a connection that's scheduled in the required run loop modes.
        
        self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
        assert(self.connection != nil);
        
        for (NSString * mode in self.actualRunLoopModes) {
            [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
        
        [self.connection start];
    }
}

- (void)operationWillFinish
    // Called by QRunLoopOperation when the operation has finished.  We 
    // do various bits of tidying up.
{
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);

    // I can't think of any circumstances under which the debug delay timer 
    // might still be running at this point, but add an assert just to be sure.
    
    #if ! defined(NDEBUG)
        assert(self.debugDelayTimer == nil);
    #endif

    [self.connection cancel];
    self.connection = nil;

    // If we have an output stream, close it at this point.  We might never 
    // have actually opened this stream but, AFAICT, closing an unopened stream 
    // doesn't hurt. 

    if (self.responseOutputStream != nil) {
        [self.responseOutputStream close];
    }
}

- (void)finishWithError:(NSError *)error
    // We override -finishWithError: just so we can handle our debug delay.
{
    // If a debug delay was set, don't finish now but rather start the debug delay timer 
    // and have it do the actual finish.  We clear self.debugDelay so that the next 
    // time this code runs its doesn't do this again.
    
    #if ! defined(NDEBUG)
        if (self.debugDelay > 0.0) {
            assert(self.debugDelayTimer == nil);
            self.debugDelayTimer = [NSTimer timerWithTimeInterval:self.debugDelay target:self selector:@selector(debugDelayTimerDone:) userInfo:self.error repeats:NO];
            assert(self.debugDelayTimer != nil);
            for (NSString * mode in self.actualRunLoopModes) {
                [[NSRunLoop currentRunLoop] addTimer:self.debugDelayTimer forMode:mode];
            }
            self.debugDelay = 0.0;
            return;
        } 
    #endif

    [super finishWithError:error];
}

#if ! defined(NDEBUG)

@synthesize debugError      = debugError_;
@synthesize debugDelay      = debugDelay_;
@synthesize debugDelayTimer = debugDelayTimer_;

- (void)debugDelayTimerDone:(NSTimer *)timer
{
    NSError *   error;
    
    assert(timer == self.debugDelayTimer);

    error = [[[timer userInfo] retain] autorelease];
    assert( (error == nil) || [error isKindOfClass:[NSError class]] );
    
    [self.debugDelayTimer invalidate];
    self.debugDelayTimer = nil;
    
    [self finishWithError:error];
}

#endif

#pragma mark * NSURLConnection delegate callbacks

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
    // See comment in header.
{
    BOOL    result;
    
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert(protectionSpace != nil);
    #pragma unused(protectionSpace)
    
    result = NO;
    if (self.authenticationDelegate != nil) {
        result = [self.authenticationDelegate httpOperation:self canAuthenticateAgainstProtectionSpace:protectionSpace];
    }
    return result;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
    // See comment in header.
{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert(challenge != nil);
    #pragma unused(challenge)
    
    if (self.authenticationDelegate != nil) {
        [self.authenticationDelegate httpOperation:self didReceiveAuthenticationChallenge:challenge];
    } else {
        if ( [challenge previousFailureCount] == 0 ) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
    // See comment in header.
{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert( (response == nil) || [response isKindOfClass:[NSHTTPURLResponse class]] );

    self.lastRequest  = request;
    self.lastResponse = (NSHTTPURLResponse *) response;
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
    // See comment in header.
{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert([response isKindOfClass:[NSHTTPURLResponse class]]);

    self.lastResponse = (NSHTTPURLResponse *) response;
    
    // We don't check the status code here because we want to give the client an opportunity 
    // to get the data of the error message.  Perhaps we /should/ check the content type 
    // here, but I'm not sure whether that's the right thing to do.
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
    // See comment in header.
{
    BOOL    success;
    
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert(data != nil);
    
    // If we don't yet have a destination for the data, calculate one.  Note that, even 
    // if there is an output stream, we don't use it for error responses.
    
    success = YES;
    if (self.firstData) {
        assert(self.dataAccumulator == nil);
        
        if ( (self.responseOutputStream == nil) || ! self.isStatusCodeAcceptable ) {
            long long   length;
            
            assert(self.dataAccumulator == nil);
            
            length = [self.lastResponse expectedContentLength];
            if (length == NSURLResponseUnknownLength) {
                length = self.defaultResponseSize;
            }
            if (length <= (long long) self.maximumResponseSize) {
                self.dataAccumulator = [NSMutableData dataWithCapacity:(NSUInteger)length];
            } else {
                [self finishWithError:[NSError errorWithDomain:kQHTTPOperationErrorDomain code:kQHTTPOperationErrorResponseTooLarge userInfo:nil]];
                success = NO;
            }
        }
        
        // If the data is going to an output stream, open it.
        
        if (success) {
            if (self.dataAccumulator == nil) {
                assert(self.responseOutputStream != nil);
                [self.responseOutputStream open];
            }
        }
        
        self.firstData = NO;
    }
    
    // Write the data to its destination.

    if (success) {
        if (self.dataAccumulator != nil) {
            if ( ([self.dataAccumulator length] + [data length]) <= self.maximumResponseSize ) {
                [self.dataAccumulator appendData:data];
            } else {
                [self finishWithError:[NSError errorWithDomain:kQHTTPOperationErrorDomain code:kQHTTPOperationErrorResponseTooLarge userInfo:nil]];
            }
        } else {
            NSUInteger      dataOffset;
            NSUInteger      dataLength;
            const uint8_t * dataPtr;
            NSError *       error;
            NSInteger       bytesWritten;

            assert(self.responseOutputStream != nil);

            dataOffset = 0;
            dataLength = [data length];
            dataPtr    = [data bytes];
            error      = nil;
            do {
                if (dataOffset == dataLength) {
                    break;
                }
                bytesWritten = [self.responseOutputStream write:&dataPtr[dataOffset] maxLength:dataLength - dataOffset];
                if (bytesWritten <= 0) {
                    error = [self.responseOutputStream streamError];
                    if (error == nil) {
                        error = [NSError errorWithDomain:kQHTTPOperationErrorDomain code:kQHTTPOperationErrorOnOutputStream userInfo:nil];
                    }
                    break;
                } else {
                    dataOffset += bytesWritten;
                }
            } while (YES);
            
            if (error != nil) {
                [self finishWithError:error];
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
    // See comment in header.
{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    
    assert(self.lastResponse != nil);

    // Swap the data accumulator over to the response data so that we don't trigger a copy.
    
    assert(self->responseBody_ == nil);
    self->responseBody_ = self->dataAccumulator_;
    self->dataAccumulator_ = nil;
    
    if ( ! self.isStatusCodeAcceptable ) {
        [self finishWithError:[NSError errorWithDomain:kQHTTPOperationErrorDomain code:self.lastResponse.statusCode userInfo:nil]];
    } else if ( ! self.isContentTypeAcceptable ) {
        [self finishWithError:[NSError errorWithDomain:kQHTTPOperationErrorDomain code:kQHTTPOperationErrorBadContentType userInfo:nil]];
    } else {
        [self finishWithError:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
    // See comment in header.
{
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    #pragma unused(connection)
    assert(error != nil);

    [self finishWithError:error];
}

@end

NSString * kQHTTPOperationErrorDomain = @"kQHTTPOperationErrorDomain";
