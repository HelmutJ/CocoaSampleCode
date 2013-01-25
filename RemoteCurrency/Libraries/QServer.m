/*
    File:       QServer.m

    Contains:   A generic TCP server object.

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

#import "QServer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

@interface QServer () <NSNetServiceDelegate>

// read/write versions of public properties

@property (nonatomic, assign, readwrite) NSUInteger             connectionSequenceNumber;

@property (nonatomic, assign, readwrite) NSUInteger             registeredPort;
@property (nonatomic, copy,   readwrite) NSString *             registeredName;

@property (nonatomic, retain, readonly ) NSMutableSet *         connectionsMutable;
@property (nonatomic, retain, readwrite) NSMutableSet *         runLoopModesMutable;

// private properties

@property (nonatomic, retain, readonly ) NSMutableSet *         listeningSockets;
@property (nonatomic, retain, readwrite) NSNetService *         netService;

// forward declarations

static void ListeningSocketCallback(CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

- (void)connectionAcceptedWithSocket:(int)fd;

@end

@implementation QServer

@synthesize domain        = domain_;
@synthesize type          = type_;
@synthesize name          = name_;
@synthesize preferredPort = preferredPort_;
@synthesize disableIPv6   = disableIPv6_;
@synthesize delegate      = delegate_;
@synthesize connectionSequenceNumber = connectionSequenceNumber_;

@synthesize registeredPort = registeredPort_;
@synthesize registeredName = registeredName_;

@synthesize connectionsMutable  = connectionsMutable_;
@synthesize runLoopModesMutable = runLoopModesMutable_;

@synthesize listeningSockets = listeningSockets_;
@synthesize netService       = netService_;

#pragma mark * Init and Dealloc

- (id)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name preferredPort:(NSUInteger)preferredPort
    // See comment in header.
{
    assert( (type != nil) || ( (domain == nil) && (name == nil) ) );
    assert(preferredPort < 65536);
    self = [super init];
    if (self != nil) {
        self->domain_ = [domain copy];
        self->type_   = [type   copy];
        self->name_   = [name   copy];
        self->preferredPort_ = preferredPort;
        
        self->connectionsMutable_ = [[NSMutableSet alloc] init];
        assert(self->connectionsMutable_ != nil);
        self->runLoopModesMutable_ = [[NSMutableSet alloc] initWithObjects:NSDefaultRunLoopMode, nil];
        assert(self->runLoopModesMutable_ != nil);
        self->listeningSockets_ = [[NSMutableSet alloc] init];
        assert(self->listeningSockets_ != nil);
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    
    [self->domain_ release];
    [self->type_ release];
    [self->name_ release];

    [self->registeredName_ release];
    [self->connectionsMutable_ release];
    [self->runLoopModesMutable_ release];
    
    // The following should have be deallocated by the call to -stop, above.
    assert( [self->listeningSockets_ count] == 0 );
    [self->listeningSockets_ release];
    assert(self->netService_ == nil);
    
    [super dealloc];
}

- (NSSet *)connections
    // For public consumption, we return an immutable snapshot of the connection set.
{
    return [[self->connectionsMutable_ copy] autorelease];
}

#pragma mark * Utilities

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
    // See comment in header.
{
    assert(format != nil);
    if ([self.delegate respondsToSelector:@selector(server:logWithFormat:arguments:)]) {
        [self.delegate server:self logWithFormat:format arguments:argList];
    }    
}

- (void)logWithFormat:(NSString *)format, ...
    // Logs the specified text.
{
    va_list argList;

    assert(format != nil);
    va_start(argList, format);
    [self logWithFormat:format arguments:argList];
    va_end(argList);
}

#pragma mark * BSD Sockets wrappers

// These routines are simple wrappers around BSD Sockets APIs that turn them into some 
// more palatable to Cocoa.  Without these wrappers, the code in -listenOnPortError: 
// looks incredibly ugly.

- (int)setOption:(int)option atLevel:(int)level onSocket:(int)fd
    // Wrapper for setsockopt.
{
    int     err;
    static const int kOne = 1;
    
    assert(fd >= 0);

    err = setsockopt(fd, level, option, &kOne, sizeof(kOne));
    if (err < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}

- (int)bindSocket:(int)fd toPort:(NSUInteger)port inAddressFamily:(int)addressFamily
    // Wrapper for bind, including a SO_REUSEADDR setsockopt.
{
    int                     err;
    struct sockaddr_storage addr;
    struct sockaddr_in *    addr4Ptr;
    struct sockaddr_in6 *   addr6Ptr;

    assert(fd >= 0);
    assert(port < 65536);

    err = 0;
    if (port != 0) {
        err = [self setOption:SO_REUSEADDR atLevel:SOL_SOCKET onSocket:fd];
    }
    if (err == 0) {
        memset(&addr, 0, sizeof(addr));
        addr.ss_family = addressFamily;
        if (addressFamily == AF_INET) {
            addr4Ptr = (struct sockaddr_in *) &addr;
            addr4Ptr->sin_len  = sizeof(*addr4Ptr);
            addr4Ptr->sin_port = htons(port);
        } else {
            assert(addressFamily == AF_INET6);
            addr6Ptr = (struct sockaddr_in6 *) &addr;
            addr6Ptr->sin6_len  = sizeof(*addr6Ptr);
            addr6Ptr->sin6_port = htons(port);
        }
        err = bind(fd, (const struct sockaddr *) &addr, addr.ss_len);
        if (err < 0) {
            err = errno;
            assert(err != 0);
        }
    }
    return err;
}

- (int)boundPort:(NSUInteger *)portPtr forSocket:(int)fd
    // Wrapper for getsockname.
{
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    
    assert(fd >= 0);
    assert(portPtr != NULL);
    
    addrLen = sizeof(addr);
    err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
    if (err < 0) {
        err = errno;
        assert(err != 0);
    } else {
        if (addr.ss_family == AF_INET) {
            assert(addrLen == sizeof(struct sockaddr_in));
            *portPtr = ntohs(((const struct sockaddr_in *) &addr)->sin_port);
        } else {
            assert(addr.ss_family == AF_INET6);
            assert(addrLen == sizeof(struct sockaddr_in6));
            *portPtr = ntohs(((const struct sockaddr_in6 *) &addr)->sin6_port);
        }
    }
    return err;
}

- (int)listenOnSocket:(int)fd
    // Wrapper for listen.
{
    int     err;

    assert(fd >= 0);
    
    err = listen(fd, 5);
    if (err < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}

- (void)closeSocket:(int)fd
    // Wrapper for close.
{
    int     junk;
    
    if (fd != -1) {
        assert(fd >= 0);
        junk = close(fd);
        assert(junk == 0);
    }
}

#pragma mark * Start and Stop

+ (NSSet *)keyPathsForValuesAffectingStarted
{
    return [NSSet setWithObject:@"preferredPort"];
}

- (BOOL)isStarted
{
    return self.registeredPort != 0;
}

- (void)addListeningSocket:(int)fd
    // See comment in header.
{
    CFSocketContext     context = { 0, self, NULL, NULL, NULL };
    CFSocketRef         sock;
    CFRunLoopSourceRef  rls;
    
    assert(fd >= 0);
    
    sock = CFSocketCreateWithNative(NULL, fd, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
    if (sock != NULL) {
        assert( CFSocketGetSocketFlags(sock) & kCFSocketCloseOnInvalidate );
        rls = CFSocketCreateRunLoopSource(NULL, sock, 0);
        assert(rls != NULL);
        
        for (NSString * mode in self.runLoopModesMutable) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, (CFStringRef) mode);
        }
        
        CFRelease(rls);
        CFRelease(sock);
        
        [self.listeningSockets addObject:(id)sock];
    }
}

- (NSUInteger)listenOnPortError:(NSError **)errorPtr
    // See comment in header.
{
    int         err;
    int         fd4;
    int         fd6;
    BOOL        retry;
    NSUInteger  retryCount;
    NSUInteger  requestedPort;
    NSUInteger  boundPort;
    
    // errorPtr may be nil
    // initial value of *errorPtr undefined
    
    boundPort = 0;
    fd4 = -1;
    fd6 = -1;
    retryCount = 0;
    requestedPort = self.preferredPort;
    assert(requestedPort < 65536);
    do {
        assert(fd4 == -1);
        assert(fd6 == -1);
        retry = NO;
    
        // Create our sockets.  We have to do this inside the loop because BSD Sockets 
        // doesn't support unbind (bring back Open Transport!) and we may need to unbind 
        // when retrying.
    
        err = 0;
        fd4 = socket(AF_INET, SOCK_STREAM, 0);
        if (fd4 < 0) {
            err = errno;
            assert(err != 0);
        }
        if ( (err == 0) && ! self.disableIPv6 ) {
            fd6 = socket(AF_INET6, SOCK_STREAM, 0);
            if (fd6 < 0) {
                err = errno;
                assert(err != 0);
            }
            if (err == EAFNOSUPPORT) {
                // No IPv6 support.  Leave fd6 set to -1.
                assert(fd6 == -1);
                err = 0;
            }
        }
        
        // Bind the IPv4 socket to the specified port (may be 0).
        
        if (err == 0) {
            err = [self bindSocket:fd4 toPort:requestedPort inAddressFamily:AF_INET];
    
            // If we tried to bind to a preferred port and that failed because the 
            // port is in use, and we're registering with Bonjour (meaning that 
            // there's a chance that our clients can find us on a non-standard port), 
            // try binding to 0, which causes the kernel to choose a port for us.
    
            if ( (err == EADDRINUSE) && (requestedPort != 0) && (self.type != nil) && (retryCount < 15) ) {
                requestedPort = 0;
                retryCount += 1;
                retry = YES;
            }
        }
        if (err == 0) {
            err = [self listenOnSocket:fd4];
        }
    
        // Figure out what port we actually bound too.
        
        if (err == 0) {
            err = [self boundPort:&boundPort forSocket:fd4];
        }
        
        // Try to bind the IPv6 socket, if any, to that port.
    
        if ( (err == 0) && (fd6 != -1) ) {
            
            // Have the IPv6 socket only bind to the IPv6 address.  Without this the IPv6 socket 
            // binds to dual mode address (reported by netstat as "tcp46") and that prevents a 
            // second instance of the code getting the EADDRINUSE error on the IPv4 bind, which is 
            // the place we're expecting it, and where we recover from it.
            
            err = [self setOption:IPV6_V6ONLY atLevel:IPPROTO_IPV6 onSocket:fd6];

            if (err == 0) {
                assert(boundPort != 0);
                err = [self bindSocket:fd6 toPort:boundPort inAddressFamily:AF_INET6];

                if ( (err == EADDRINUSE) && (requestedPort == 0) && (retryCount < 15) ) {
                    // If the IPv6 socket's bind failed and we are trying to bind 
                    // to an anonymous port, try again.  This protects us from the 
                    // race condition where we bind IPv4 to a port then, before we can 
                    // bind IPv6 to the same port, someone else binds their own IPv6 
                    // to that port (or vice versa).  We also limit the number of retries 
                    // to guarantee we don't loop forever in some pathological case.
    
                    retryCount += 1;
                    retry = YES;
                }

                if (err == 0) {
                    err = [self listenOnSocket:fd6];
                }
            }
        }
        
        // If something went wrong, close down our sockets.
        
        if (err != 0) {
            [self closeSocket:fd4];
            [self closeSocket:fd6];
            fd4 = -1;
            fd6 = -1;
            boundPort = 0;
        }
    } while ( (err != 0) && retry );
    
    assert( (err == 0) == (fd4 != -1) );
    assert( (err == 0) || (fd6 == -1) );
    // On success, fd6 might still be 0, implying that IPv6 is not available.
    assert( (err == 0) == (boundPort != 0) );
    assert( (err != 0) || (requestedPort == 0) || (boundPort == requestedPort) );

    // Add the sockets to the run loop.
    
    if (err == 0) {
        [self addListeningSocket:fd4];
        if (fd6 != -1) {
            [self addListeningSocket:fd6];
        }
    }
    
    // Clean up.
    
    // There's no need to clean up fd4 and fd6.  We are either successful, 
    // in which case they are now owned by the CFSockets in the listeningSocket 
    // set, or we failed, in which case they were cleaned up on the way out 
    // of the do..while loop.
    if (err != 0) {
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        }
        assert(boundPort == 0);
    }
    assert( (err == 0) == (boundPort != 0) );
    assert( (err == 0) || ( (errorPtr == NULL) || (*errorPtr != nil) ) );

    return boundPort;
}

- (void)didStart
    // See comment in header.
{
    [self logWithFormat:@"did start on port %u", (unsigned int) self.registeredPort];
    if ( [self.delegate respondsToSelector:@selector(serverDidStart:)] ) {
        [self.delegate serverDidStart:self];
    }
}

- (void)didStopWithError:(NSError *)error
    // See comment in header.
{
    assert(error != nil);
    [self logWithFormat:@"did stop with error %@", error];
    if ( [self.delegate respondsToSelector:@selector(server:didStopWithError:)] ) {
        [self.delegate server:self didStopWithError:error];
    }
}

- (void)start
    // See comment in header.
{
    NSUInteger  port;
    NSError *   error;

    assert( ! self.isStarted );
    
    [self logWithFormat:@"starting"];

    port = [self listenOnPortError:&error];

    // Kick off the next stage of the startup, if required, namely the Bonjour registration.

    if (port == 0) {

        // If startup failed, we tell our delegate about it immediately.
        
        assert(error != nil);
        [self didStopWithError:error];

    } else {

        // Set registeredPort, which also sets isStarted, which indicates to everyone 
        // that the server is up and running.  Of course in the Bonjour case it's not 
        // yet fully up, but we handle that by deferring the -didStart.
        
        self.registeredPort = port;

        if (self.type == nil) {
        
            // Startup was successful, but there's nothing to register with Bonjour, so 
            // tell the delegate about the successful start.
            
            [self didStart];

        } else {
        
            // Startup has succeeded so far.  Let's start the Bonjour registration.
            
            assert(port < 65536);
            self.netService = [[[NSNetService alloc] initWithDomain:(self.domain == nil) ? @"" : self.domain 
                type:self.type 
                name:(self.name == nil) ? @"" : self.name
                port:(int)port
            ] autorelease];
            assert(self.netService != nil);

            for (NSString * mode in self.runLoopModesMutable) {
                [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
            }
            [self.netService setDelegate:self];
            [self.netService publishWithOptions:0];
        }
    }
}

- (void)netServiceDidPublish:(NSNetService *)sender
    // An NSNetService delegate callback called when we have registered on the network. 
    // We respond by latching the name we registered (which may be different from the 
    // name we attempted to register due to auto-renaming) and telling the delegate.
{
    assert(sender == self.netService);
    assert(self.isStarted);

    self.registeredName = [sender name];
    [self didStart];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    // An NSNetService delegate callback called when the service failed to register 
    // on the network.  We respond by shutting down the server and telling the delegate.
{
    NSNumber *  errorDomainObj;
    NSNumber *  errorCodeObj;
    int         errorDomain;
    int         errorCode;
    NSError *   error;

    assert(sender == self.netService);
    assert(errorDict != nil);
    assert(self.isStarted);             // that is, the listen sockets should be up

    // Extract the information from the error dictionary.
    
    errorDomain = 0;
    errorDomainObj = [errorDict objectForKey:NSNetServicesErrorDomain];
    if ( (errorDomainObj != nil) && [errorDomainObj isKindOfClass:[NSNumber class]] ) {
        errorDomain = [errorDomainObj intValue];
    }

    errorCode   = 0;
    errorCodeObj = [errorDict objectForKey:NSNetServicesErrorCode];
    if ( (errorCodeObj != nil) && [errorCodeObj isKindOfClass:[NSNumber class]] ) {
        errorCode = [errorCodeObj intValue];
    }

    // We specifically check for Bonjour errors because they are the only thing 
    // we're likely to get here.  It would be nice if CFErrorCreateWithStreamError 
    // existed <rdar://problem/5845848>.
    
    if ( (errorDomain == kCFStreamErrorDomainNetServices) && (errorCode != 0) ) {
        error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:errorCode userInfo:nil];
    } else {
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOTTY userInfo:nil];
    }
    assert(error != nil);
    [self stop];
    [self didStopWithError:error];
}

- (void)netServiceDidStop:(NSNetService *)sender
    // An NSNetService delegate callback called when the service fails in some way. 
    // We respond by shutting down the server and telling the delegate.
{
    NSError *   error;

    assert(sender == self.netService);
    assert(self.isStarted);

    error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOTTY userInfo:nil];
    assert(error != nil);
    [self stop];
    [self didStopWithError:error];
}

- (void)stop
    // See comment in header.
{
    if ( self.isStarted ) {
        [self logWithFormat:@"stopping"];

        [self closeAllConnections];
        
        // Close down the net service if it was started.
        
        if (self.netService != nil) {
            [self.netService setDelegate:nil];
            [self.netService stop];
            // Don't need to call -removeFromRunLoop:forMode: because -stop takes care of that.
            self.netService = nil;
        }
        if (self.registeredName != nil) {
            self.registeredName = nil;
        }
        
        // Close down the listening sockets.
        
        for (id s in self.listeningSockets) {
            CFSocketRef sock;
            
            sock = (CFSocketRef) s;
            assert( CFGetTypeID(sock) == CFSocketGetTypeID() );
            CFSocketInvalidate(sock);
        }
        [self.listeningSockets removeAllObjects];

        self.registeredPort = 0;
        [self logWithFormat:@"did stop"];
    }
}

#pragma mark * Connections

static void ListeningSocketCallback(CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    // The CFSocket callback associated with one of the elements of the listeningSockets set.  This is 
    // called when a new connection arrives.  It routes the connection to the -connectionAcceptedWithSocket: 
    // method.
{
    QServer *   obj;
    int         fd;
    
    obj = (QServer *) info;
    assert([obj isKindOfClass:[QServer class]]);
    
    assert([obj->listeningSockets_ containsObject:(id) sock]);
    #pragma unused(sock)
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(type)
    assert(address != NULL);
    #pragma unused(address)
    assert(data != nil);
    
    fd = * (const int *) data;
    assert(fd >= 0);
    [obj connectionAcceptedWithSocket:fd];
}

- (id)connectionForSocket:(int)fd
    // See comment in header.
    //
    // We first see if the delegate implements -server:connectionForSocket:.  If so, we call that. 
    // If not, we see if the delegate implements -server:connectionForInputStream:outputStream:.  
    // If so, we create the necessary input and output streams and call that method.  If the 
    // delegate implements neither, we simply return nil.
{
    id          connection;

    assert(fd >= 0);
    if ( [self.delegate respondsToSelector:@selector(server:connectionForSocket:)] ) {
        connection = [self.delegate server:self connectionForSocket:fd];
    } else if ( [self.delegate respondsToSelector:@selector(server:connectionForInputStream:outputStream:)] ) {
        BOOL                success;
        CFReadStreamRef     readStream;
        CFWriteStreamRef    writeStream;
        NSInputStream *     inputStream;
        NSOutputStream *    outputStream;
    
        CFStreamCreatePairWithSocket(NULL, fd, &readStream, &writeStream);
    
        inputStream  = [NSMakeCollectable(readStream ) autorelease];
        outputStream = [NSMakeCollectable(writeStream) autorelease];
    
        assert( (CFBooleanRef) [ inputStream propertyForKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanFalse );
        assert( (CFBooleanRef) [outputStream propertyForKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanFalse );
        
        connection = [self.delegate server:self connectionForInputStream:inputStream outputStream:outputStream];
        
        // If the client accepted this connection, we have to flip kCFStreamPropertyShouldCloseNativeSocket 
        // to true so the client streams close the socket when they're done.  OTOH, if the client denies 
        // the connection, we leave kCFStreamPropertyShouldCloseNativeSocket as false because our caller 
        // is going to close the socket in that case.
        
        if (connection != nil) {
            success = [inputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
            assert(success);
            assert( (CFBooleanRef) [outputStream propertyForKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket] == kCFBooleanTrue );
        }
    } else {
        connection = nil;
    }
    
    return connection;
}

- (void)connectionAcceptedWithSocket:(int)fd
    // Called when we receive a connection on one of our listening sockets.  We 
    // call our delegate to create a connection object for this connection and, 
    // if that succeeds, add it to our connections set.
{
    int         junk;
    id          connection;
    
    assert(fd >= 0);
    
    connection = [self connectionForSocket:fd];
    self.connectionSequenceNumber += 1;
    if (connection != nil) {
        [self logWithFormat:@"start connection %p", connection];
        [self.connectionsMutable addObject:connection];
    } else {
        junk = close(fd);
        assert(junk == 0);
    }
}

- (void)closeConnection:(id)connection
    // See comment in header.
{
    if ( [self.delegate respondsToSelector:@selector(server:closeConnection:)] ) {
        [self.delegate server:self closeConnection:connection];
    }
}

- (void)closeConnection:(id)connection notify:(BOOL)notify
    // The core code behind -closeConnection: and -closeAllConnections:. 
    // This removes the connection from the set and, if notify is YES, 
    // tells the delegate about it having been closed.
{
    [self logWithFormat:@"close connection %p", connection];
    if ( [self.connectionsMutable containsObject:connection] ) {
    
        // It's possible that, if a connection calls this on itself, we might 
        // be holding the last reference to the connection.  To avoid crashing 
        // as we unwind out of the call stack, we retain and autorelease the 
        // connection.
    
        [[connection retain] autorelease];
        
        [self.connectionsMutable removeObject:connection];
        
        if (notify) {
            [self closeConnection:connection];
        }
    }
}

- (void)closeOneConnection:(id)connection
    // See comment in header.
{
    [self closeConnection:connection notify:NO];
}

- (void)closeAllConnections
    // See comment in header.
{
    // We can't use for..in because we're mutating while enumerating.
    do {
        id      connection;
        
        connection = [self.connectionsMutable anyObject];
        if (connection == nil) {
            break;
        }
        [self closeConnection:connection notify:YES];
    } while (YES);
}

#pragma mark * Run Loop Modes

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

- (void)scheduleInRunLoopModesInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
    // See comment in header.
{
    assert( (inputStream != nil) || (outputStream != nil) );
    for (NSString * mode in self.runLoopModesMutable) {
        if (inputStream != nil) {
            [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
        if (outputStream != nil) {
            [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
    }
}

- (void)removeFromRunLoopModesInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    assert( (inputStream != nil) || (outputStream != nil) );
    for (NSString * mode in self.runLoopModesMutable) {
        if (inputStream != nil) {
            [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
        if (outputStream != nil) {
            [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
        }
    }
}

@end
