/*
    File:       EchoServer.m

    Contains:   A basic TCP echo server.

    Copyright:  Copyright (c) 2005-2012 Apple Inc. All Rights Reserved.

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

#import "EchoServer.h"

#import "EchoConnection.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface EchoServer () <NSStreamDelegate>

// read/write versions of public properties

@property (nonatomic, assign, readwrite) NSUInteger         port;

// private properties

@property (nonatomic, strong, readwrite) NSNetService *     netService;
@property (nonatomic, strong, readonly ) NSMutableSet *     connections;    // of EchoConnection

@end

@implementation EchoServer {
    CFSocketRef             _ipv4socket;
    CFSocketRef             _ipv6socket;
}

@synthesize port = _port;

@synthesize netService = _netService;
@synthesize connections = _connections;

- (id)init
{
    self = [super init];
    if (self != nil) {
        _connections = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)echoConnectionDidCloseNotification:(NSNotification *)note
{
    EchoConnection *connection = [note object];
    assert([connection isKindOfClass:[EchoConnection class]]);
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self name:EchoConnectionDidCloseNotification object:connection];
    [self.connections removeObject:connection];
    NSLog(@"Connection closed.");
}

- (void)acceptConnection:(CFSocketNativeHandle)nativeSocketHandle
{
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
    if (readStream && writeStream) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

        EchoConnection * connection = [[EchoConnection alloc] initWithInputStream:(__bridge NSInputStream *)readStream outputStream:(__bridge NSOutputStream *)writeStream];
        [self.connections addObject:connection];
        [connection open];
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(echoConnectionDidCloseNotification:) name:EchoConnectionDidCloseNotification object:connection];
        NSLog(@"Added connection.");
    } else {
        // On any failure, we need to destroy the CFSocketNativeHandle 
        // since we are not going to use it any more.
        (void) close(nativeSocketHandle);
    }
    if (readStream) CFRelease(readStream);
    if (writeStream) CFRelease(writeStream);
}

// This function is called by CFSocket when a new connection comes in.
// We gather the data we need, and then convert the function call to a method
// invocation on EchoServer.
static void EchoServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(type)
    #pragma unused(address)
    
    EchoServer *server = (__bridge EchoServer *)info;
    assert(socket == server->_ipv4socket || socket == server->_ipv6socket);
    #pragma unused(socket)
    
    // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
    [server acceptConnection:*(CFSocketNativeHandle *)data];
}

- (BOOL)start {
    assert(_ipv4socket == NULL && _ipv6socket == NULL);       // don't call -start twice!

    CFSocketContext socketCtxt = {0, (__bridge void *) self, NULL, NULL, NULL};
    _ipv4socket = CFSocketCreate(kCFAllocatorDefault, AF_INET,  SOCK_STREAM, 0, kCFSocketAcceptCallBack, &EchoServerAcceptCallBack, &socketCtxt);
    _ipv6socket = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, 0, kCFSocketAcceptCallBack, &EchoServerAcceptCallBack, &socketCtxt);

    if (NULL == _ipv4socket || NULL == _ipv6socket) {
        [self stop];
        return NO;
    }

    static const int yes = 1;
    (void) setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
    (void) setsockopt(CFSocketGetNative(_ipv6socket), SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));

    // Set up the IPv4 listening socket; port is 0, which will cause the kernel to choose a port for us.
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(0);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (__bridge CFDataRef) [NSData dataWithBytes:&addr4 length:sizeof(addr4)])) {
        [self stop];
        return NO;
    }
    
    // Now that the IPv4 binding was successful, we get the port number 
    // -- we will need it for the IPv6 listening socket and for the NSNetService.
    NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4socket);
    assert([addr length] == sizeof(struct sockaddr_in));
    self.port = ntohs(((const struct sockaddr_in *)[addr bytes])->sin_port);

    // Set up the IPv6 listening socket.
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(self.port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv6socket, (__bridge CFDataRef) [NSData dataWithBytes:&addr6 length:sizeof(addr6)])) {
        [self stop];
        return NO;
    }

    // Set up the run loop sources for the sockets.
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
    CFRelease(source4);

    CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
    CFRelease(source6);

    assert(self.port > 0 && self.port < 65536);
    self.netService = [[NSNetService alloc] initWithDomain:@"local" type:@"_cocoaecho._tcp." name:@"" port:(int) self.port];
    [self.netService publishWithOptions:0];

    return YES;
}

- (void)stop {
    [self.netService stop];
    self.netService = nil;
    // Closes all the open connections.  The EchoConnectionDidCloseNotification notification will ensure 
    // that the connection gets removed from the self.connections set.  To avoid mututation under iteration 
    // problems, we make a copy of that set and iterate over the copy.
    for (EchoConnection * connection in [self.connections copy]) {
        [connection close];
    }
    if (_ipv4socket != NULL) {
        CFSocketInvalidate(_ipv4socket);
        CFRelease(_ipv4socket);
        _ipv4socket = NULL;
    }
    if (_ipv6socket != NULL) {
        CFSocketInvalidate(_ipv6socket);
        CFRelease(_ipv6socket);
        _ipv6socket = NULL;
    }
}

@end
