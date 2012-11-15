/*
    File:       SRVResolver.m

    Contains:   Uses <dns_sd.h> APIs to resolve SRV records.

    Written by: DTS

    Copyright:  Copyright (c) 2010-2012 Apple Inc. All Rights Reserved.

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

#import "SRVResolver.h"

#include <dns_util.h>

@interface SRVResolver ()

// Redeclare some external properties as read/write

@property (nonatomic, assign, readwrite, getter=isFinished) BOOL    finished;
@property (nonatomic, copy,   readwrite) NSError *                  error;

// Private properties

@property (nonatomic, strong, readonly ) NSMutableArray *           resultsMutable;     // backing for the public results property

// Forward declarations

- (void)startInternal;

@end

@implementation SRVResolver
{
    DNSServiceRef           _sdRef;
    CFSocketRef             _sdRefSocket;
}

@synthesize srvName  = _srvName;
@synthesize delegate = _delegate;

@synthesize finished = _finished;
@synthesize error    = _error;
@synthesize resultsMutable = _resultsMutable;

- (id)initWithSRVName:(NSString *)srvName
{
    assert(srvName != nil);
    self = [super init];
    if (self != nil) {
        self->_srvName = [srvName copy];
        assert(self->_srvName != nil);
        self->_resultsMutable = [[NSMutableArray alloc] init];
        assert(self->_resultsMutable != nil);
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)start
{
    if (self->_sdRef == NULL) {
        self.error    = nil;            // starting up again, so forget any previous error
        self.finished = NO;
        [self startInternal];
    }
}

- (void)stop
{
    if (self->_sdRefSocket != NULL) {
        CFSocketInvalidate(self->_sdRefSocket);
        CFRelease(self->_sdRefSocket);
        self->_sdRefSocket = NULL;
    }
    if (self->_sdRef != NULL) {
        DNSServiceRefDeallocate(self->_sdRef);
        self->_sdRef = NULL;
    }
    self.finished = YES;
}

- (void)stopWithError:(NSError *)error
{
    // error may be nil
    self.error = error;
    [self stop];
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(srvResolver:didStopWithError:)] ) {
        [self.delegate srvResolver:self didStopWithError:error];
    }
}

- (void)stopWithDNSServiceError:(DNSServiceErrorType)errorCode
{
    NSError *   error;
    
    error = nil;
    if (errorCode != kDNSServiceErr_NoError) {
        error = [NSError errorWithDomain:kSRVResolverErrorDomain code:errorCode userInfo:nil];
    }
    [self stopWithError:error];
}

- (NSArray *)results
{
    // Return a snapshot of our internal mutable array.
    return [self.resultsMutable copy];
}

- (void)processRecord:(const void *)rdata length:(NSUInteger)rdlen
{
    NSMutableData *         rrData;
    dns_resource_record_t * rr;
    uint8_t                 u8;
    uint16_t                u16;
    uint32_t                u32;
    
    assert(rdata != NULL);
    assert(rdlen < 65536);      // rdlen comes from a uint16_t, so can't exceed this.  
                                // This also constrains [rrData length] to well less than a uint32_t.
    
    // Rather than write a whole bunch of icky parsing code, I just synthesise 
    // a resource record and use <dns_util.h>.

    rrData = [NSMutableData data];
    assert(rrData != nil);
    
    u8 = 0;
    [rrData appendBytes:&u8 length:sizeof(u8)];
    u16 = htons(kDNSServiceType_SRV);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    u16 = htons(kDNSServiceClass_IN);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    u32 = htonl(666);
    [rrData appendBytes:&u32 length:sizeof(u32)];
    u16 = htons(rdlen);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    [rrData appendBytes:rdata length:rdlen];

    // Parse the record.
    
    rr = dns_parse_resource_record([rrData bytes], (uint32_t) [rrData length]);
    assert(rr != NULL);
    
    // If the parse is successful, add the results to the array.
    
    if (rr != NULL) {
        NSString *      target;
        
        target = [NSString stringWithCString:rr->data.SRV->target encoding:NSASCIIStringEncoding];
        if (target != nil) {
            NSDictionary *  result;
            NSIndexSet *    resultIndexSet;
        
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithUnsignedInt:rr->data.SRV->priority], kSRVResolverPriority,
                [NSNumber numberWithUnsignedInt:rr->data.SRV->weight],   kSRVResolverWeight,
                [NSNumber numberWithUnsignedInt:rr->data.SRV->port],     kSRVResolverPort,
                target,                                                  kSRVResolverTarget, 
                nil
            ];
            assert(result != nil);
            
            resultIndexSet = [NSIndexSet indexSetWithIndex:self.results.count];
            assert(resultIndexSet != nil);
            
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:resultIndexSet forKey:@"results"];
            [self.resultsMutable addObject:result];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:resultIndexSet forKey:@"results"];

            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(srvResolver:didReceiveResult:)] ) {
                [self.delegate srvResolver:self didReceiveResult:result];
            }
        }

        dns_free_resource_record(rr);
    }
}

static void QueryRecordCallback(
    DNSServiceRef       sdRef,
    DNSServiceFlags     flags,
    uint32_t            interfaceIndex,
    DNSServiceErrorType errorCode,
    const char *        fullname,
    uint16_t            rrtype,
    uint16_t            rrclass,
    uint16_t            rdlen,
    const void *        rdata,
    uint32_t            ttl,
    void *              context
)
    // Call (via our CFSocket callback) when we get a response to our query.  
    // It does some preliminary work, but the bulk of the interesting stuff 
    // is done in the -processRecord:length: method.
{
    SRVResolver *   obj;

    obj = (__bridge SRVResolver *) context;
    assert([obj isKindOfClass:[SRVResolver class]]);
    
    #pragma unused(sdRef)
    assert(sdRef == obj->_sdRef);
    assert(flags & kDNSServiceFlagsAdd);
    #pragma unused(interfaceIndex)
    // errorCode looked at below
    #pragma unused(fullname)
    #pragma unused(rrtype)
    assert(rrtype == kDNSServiceType_SRV);
    #pragma unused(rrclass)
    assert(rrclass == kDNSServiceClass_IN);
    // rdlen and rdata used below
    #pragma unused(ttl)
    // context used above

    if (errorCode == kDNSServiceErr_NoError) {
        [obj processRecord:rdata length:rdlen];
        
        // We're assuming SRV records over unicast DNS here, so the first result packet we get 
        // will contain all the information we're going to get.  In a more dynamic situation 
        // (for example, multicast DNS or long-lived queries in Back to My Mac) we'd would want 
        // to leave the query running.
        
        if ( ! (flags & kDNSServiceFlagsMoreComing) ) {
            [obj stopWithError:nil];
        }
    } else {
        [obj stopWithDNSServiceError:errorCode];
    }
}

static void SDRefSocketCallback(
    CFSocketRef             s, 
    CFSocketCallBackType    type, 
    CFDataRef               address, 
    const void *            data, 
    void *                  info
)
    // A CFSocket callback.  This runs when we get messages from mDNSResponder 
    // regarding our DNSServiceRef.  We just turn around and call DNSServiceProcessResult, 
    // which does all of the heavy lifting (and would typically call QueryRecordCallback).
{
    DNSServiceErrorType err;
    SRVResolver *       obj;
    
    #pragma unused(type)
    assert(type == kCFSocketReadCallBack);
    #pragma unused(address)
    #pragma unused(data)
    
    obj = (__bridge SRVResolver *) info;
    assert([obj isKindOfClass:[SRVResolver class]]);
    
    #pragma unused(s)
    assert(s == obj->_sdRefSocket);
    
    err = DNSServiceProcessResult(obj->_sdRef);
    if (err != kDNSServiceErr_NoError) {
        [obj stopWithDNSServiceError:err];
    }
}

- (void)startInternal
{
    DNSServiceErrorType err;
    const char *        srvNameCStr;
    int                 fd;
    CFSocketContext     context = { 0, (__bridge void *) self, NULL, NULL, NULL };
    CFRunLoopSourceRef  rls;
    
    assert(self->_sdRef == NULL);
    
    // Create the DNSServiceRef to run our query.
    
    err = kDNSServiceErr_NoError;
    srvNameCStr = [self.srvName UTF8String];
    if (srvNameCStr == nil) {
        err = kDNSServiceErr_BadParam;
    }
    if (err == kDNSServiceErr_NoError) {
        err = DNSServiceQueryRecord(
            &self->_sdRef, 
            kDNSServiceFlagsReturnIntermediates,
            0,                                      // interfaceIndex
            srvNameCStr, 
            kDNSServiceType_SRV, 
            kDNSServiceClass_IN, 
            QueryRecordCallback,
            (__bridge void *)(self)
        );
    }

    // Create a CFSocket to handle incoming messages associated with the 
    // DNSServiceRef.

    if (err == kDNSServiceErr_NoError) {
        assert(self->_sdRef != NULL);
        
        fd = DNSServiceRefSockFD(self->_sdRef);
        assert(fd >= 0);
        
        assert(self->_sdRefSocket == NULL);
        self->_sdRefSocket = CFSocketCreateWithNative(
            NULL, 
            fd, 
            kCFSocketReadCallBack, 
            SDRefSocketCallback, 
            &context
        );
        assert(self->_sdRefSocket != NULL);
        
        CFSocketSetSocketFlags(
            self->_sdRefSocket, 
            CFSocketGetSocketFlags(self->_sdRefSocket) & ~ (CFOptionFlags) kCFSocketCloseOnInvalidate
        );
        
        rls = CFSocketCreateRunLoopSource(NULL, self->_sdRefSocket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
    }
    if (err != kDNSServiceErr_NoError) {
        [self stopWithDNSServiceError:err];
    }
}

@end

NSString * kSRVResolverPriority = @"priority";
NSString * kSRVResolverWeight   = @"weight";
NSString * kSRVResolverPort     = @"port";
NSString * kSRVResolverTarget   = @"target";

NSString * kSRVResolverErrorDomain = @"kSRVResolverErrorDomain";
