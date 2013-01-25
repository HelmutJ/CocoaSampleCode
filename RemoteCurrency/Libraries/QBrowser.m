/*
    File:       QBrowser.m

    Contains:   Manages a Bonjour browse operation.

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

#import "QBrowser.h"

@interface QBrowser () <NSNetServiceBrowserDelegate>

// read/write versions of public properties

@property (nonatomic, retain, readonly ) NSMutableSet *         servicesMutable;
@property (nonatomic, retain, readonly ) NSMutableSet *         runLoopModesMutable;

// private properties

@property (nonatomic, retain, readwrite) NSNetServiceBrowser *  netBrowser;
@property (nonatomic, retain, readonly ) NSMutableSet *         pendingServicesToAdd;
@property (nonatomic, retain, readonly ) NSMutableSet *         pendingServicesToRemove;

@end

@implementation QBrowser

@synthesize domain   = domain_;
@synthesize type     = type_;
@synthesize delegate = delegate_;

@synthesize servicesMutable     = servicesMutable_;
@synthesize runLoopModesMutable = runLoopModesMutable_;

@synthesize netBrowser = netBrowser_;
@synthesize pendingServicesToAdd    = pendingServicesToAdd_;
@synthesize pendingServicesToRemove = pendingServicesToRemove_;

- (id)initWithDomain:(NSString *)domain type:(NSString *)type
{
    // domain may be nil
    assert(type != nil);
    self = [super init];
    if (self != nil) {
        self->domain_ = [domain copy];
        self->type_ = [type copy];
        self->servicesMutable_ = [[NSMutableSet alloc] init];
        self->runLoopModesMutable_ = [[NSMutableSet alloc] initWithObjects:NSDefaultRunLoopMode, nil];
        self->pendingServicesToAdd_ = [[NSMutableSet alloc] init];
        self->pendingServicesToRemove_ = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    assert(self->netBrowser_ == nil);       // should be cleared by -stop
    
    [self->servicesMutable_ release];
    [self->runLoopModesMutable_ release];
    [self->pendingServicesToAdd_ release];
    [self->pendingServicesToRemove_ release];
    
    [self->domain_ release];
    [self->type_ release];
    [super dealloc];
}

#pragma mark * Properties

+ (NSSet *)keyPathsForValuesAffectingIsStarted
{
    return [NSSet setWithObject:@"netBrowser"];
}

- (BOOL)isStarted
{
    return self.netBrowser != nil;
}

- (NSSet *)services
{
    return [[self.servicesMutable copy] autorelease];
}

#pragma mark * Run loop modes

- (void)addRunLoopMode:(NSString *)modeToAdd
{
    assert(modeToAdd != nil);
    if ( ! self.isStarted ) {
        [self.runLoopModesMutable addObject:modeToAdd];
    }
}

- (void)removeRunLoopMode:(NSString *)modeToRemove
{
    assert(modeToRemove != nil);
    if ( ! self.isStarted ) {
        [self.runLoopModesMutable removeObject:modeToRemove];
    }
}

- (NSSet *)runLoopModes
{
    return [[self.runLoopModesMutable copy] autorelease];
}

#pragma mark * Actions

- (void)start
{
    assert( ! self.isStarted );
    self.netBrowser = [[[NSNetServiceBrowser alloc] init] autorelease];
    assert(self.netBrowser != nil);
    
    [self.netBrowser setDelegate:self];
    for (NSString * mode in self.runLoopModesMutable) {
        [self.netBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    }
    
    [self.netBrowser searchForServicesOfType:self.type inDomain:(self.domain == nil ? @"" : self.domain)];
}

- (void)stop
{
    if (self.isStarted) {

        // Stop the browse.  We don't need to explicitly remove it from the run loop 
        // modes because -stop takes care of that for us.
        
        [self.netBrowser setDelegate:nil];
        [self.netBrowser stop];
        self.netBrowser = nil;

        // Remove any currently visible displayed.
        
        [self willChangeValueForKey:@"services" withSetMutation:NSKeyValueSetSetMutation usingObjects:[NSSet set]];
        [self  didChangeValueForKey:@"services" withSetMutation:NSKeyValueSetSetMutation usingObjects:[NSSet set]];
        
        // Don't want any inflight services to get noticed the next time we're started.
        
        [self.pendingServicesToAdd removeAllObjects];
        [self.pendingServicesToRemove removeAllObjects];
    }
}

- (void)stopWithError:(NSError *)error
{
    assert(error != nil);
    
    [self stop];

    if ([self.delegate respondsToSelector:@selector(browser:didStopWithError:)]) {

        // The following retain and autorelease is necessary to prevent crashes when, 
        // after we tell the delegate about the stop, the delegate releases its reference 
        // to us, and that's the last reference, so we end up freed, and hence crash on 
        // returning back up the stack to this code.
        
        [[self retain] autorelease];
        
        [self.delegate browser:self didStopWithError:error];
    }
}

#pragma mark * NSNetServiceBrowser delegate callbacks

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    // An NSNetServiceBrowser delegate callback that's called when we discover a service. 
    // We add this service to our set of pending services to add and, if there are 
    // no more services coming, we add that set to our services set, triggering the 
    // necessary KVO notification.
{
    assert(aNetServiceBrowser == self.netBrowser);
    #pragma unused(aNetServiceBrowser)
    assert(aNetService != nil);
    
    [self.pendingServicesToAdd addObject:aNetService];
    
    if ( ! moreComing ) {
        NSSet * setToAdd;

        setToAdd = [[self.pendingServicesToAdd copy] autorelease];
        assert(setToAdd != nil);
        [self.pendingServicesToAdd removeAllObjects];
        
        [self willChangeValueForKey:@"services" withSetMutation:NSKeyValueUnionSetMutation usingObjects:setToAdd];
        [self.servicesMutable unionSet:setToAdd];
        [self  didChangeValueForKey:@"services" withSetMutation:NSKeyValueUnionSetMutation usingObjects:setToAdd];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    // An NSNetServiceBrowser delegate callback that's called when a service goes away. 
    // We add this service to our set of pending services to remove and, if there are 
    // no more services coming (well, going :-), we remove that set to our services set, 
    // triggering the necessary KVO notification.
{
    assert(aNetServiceBrowser == self.netBrowser);
    #pragma unused(aNetServiceBrowser)
    assert(aNetService != nil);

    [self.pendingServicesToRemove addObject:aNetService];
    
    if ( ! moreComing ) {
        NSSet * setToRemove;

        setToRemove = [[self.pendingServicesToRemove copy] autorelease];
        assert(setToRemove != nil);
        [self.pendingServicesToRemove removeAllObjects];

        [self willChangeValueForKey:@"services" withSetMutation:NSKeyValueMinusSetMutation usingObjects:setToRemove];
        [self.servicesMutable minusSet:setToRemove];
        [self  didChangeValueForKey:@"services" withSetMutation:NSKeyValueMinusSetMutation usingObjects:setToRemove];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
    // An NSNetServiceBrowser delegate callback that's called when the service stops.  
    // This shouldn't happen in this context (because we remove ourselves as the delegate 
    // of the browser before we call -stop) but, if it does, we treat it like didNotSearch.
{
    assert(aNetServiceBrowser == self.netBrowser);
    #pragma unused(aNetServiceBrowser)
    assert(NO);
    [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
    // An NSNetServiceBrowser delegate callback that's called when the browser fails 
    // completely.  We respond by shutting it down.
{
    NSNumber *  domainObj;
    NSNumber *  codeObj;
    NSInteger   domain;
    NSInteger   code;
    NSString *  domainStr;
    NSError *   error;
    
    assert(aNetServiceBrowser == self.netBrowser);
    #pragma unused(aNetServiceBrowser)
    assert(errorDict != nil);

    // Annoyingly, errorDict does not contain an NSError, or even an NSError 
    // domain string, so we have to extract the properties it does contain 
    // and convert them to an NSError.
    
    domainObj = [errorDict objectForKey:NSNetServicesErrorDomain];
    assert(domainObj != nil);
    assert([domainObj isKindOfClass:[NSNumber self]]);

    codeObj = [errorDict objectForKey:NSNetServicesErrorCode];
    assert(codeObj != nil);
    assert([codeObj isKindOfClass:[NSNumber self]]);
    
    domain = [domainObj integerValue];
    code   = [codeObj   integerValue];
    
    // The following is less than ideal.  I only handle a limited number of error 
    // constant, and I can't use a switch statement because kCFStreamErrorDomainNetServices 
    // is not a constant.  Wouldn't it be nice if there was a public API to do 
    // this mapping <rdar://problem/5845848>.
    
    domainStr = nil;
    if (domain == kCFStreamErrorDomainPOSIX) {
        domainStr = NSPOSIXErrorDomain;
    } else if (domain == kCFStreamErrorDomainMacOSStatus) {
        domainStr = NSOSStatusErrorDomain;
    } else if (domain == kCFStreamErrorDomainNetServices) {
        domainStr = (NSString *) kCFErrorDomainCFNetwork;
    } else {
        // If it's something we don't understand, we just assume it comes from 
        // CFNetwork.
        assert(NO);
        domainStr = (NSString *) kCFErrorDomainCFNetwork;
    }
    
    error = [NSError 
        errorWithDomain:domainStr 
        code:code 
        userInfo:nil
    ];
    assert(error != nil);

    [self stopWithError:error];
}

@end
