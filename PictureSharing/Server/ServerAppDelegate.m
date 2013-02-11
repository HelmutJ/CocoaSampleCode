/*
    File:       AppDelegate.m

    Contains:   Core server application logic.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

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

#import "ServerAppDelegate.h"

#import "FileSendOperation.h"

#include <sys/socket.h>
#include <netinet/in.h>

@interface ServerAppDelegate () <NSNetServiceDelegate, NSApplicationDelegate>

// read/write variants of public properties

@property (nonatomic, assign, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, copy,   readwrite) NSString *         longStatus;
@property (nonatomic, copy,   readwrite) NSString *         serviceName;
@property (nonatomic, assign, readwrite) NSUInteger         inProgressSendCount;
@property (nonatomic, assign, readwrite) NSUInteger         successfulSendCount;
@property (nonatomic, assign, readwrite) NSUInteger         failedSendCount;

// private properties

@property (nonatomic, copy,   readonly ) NSString *         defaultServiceName;
@property (nonatomic, retain, readwrite) NSNetService *     netService;
@property (nonatomic, retain, readonly ) NSOperationQueue * queue;

// forward declarations

- (void)start;
- (void)stopWithStatus:(NSString *)newStatus;

- (void)connectionReceived:(int)fd;

@end

@implementation ServerAppDelegate

- (void)dealloc
    // The application delegate lives for the lifetime of the application, so we don't bother 
    // implementing -dealloc.
{
    assert(NO);
    [super dealloc];
}

#pragma mark * Application delegate callbacks

// This object is the delegate of the NSApplication instance so we can get notifications about 
// various state changes.

- (void)applicationDidFinishLaunching:(NSNotification *)notification
    // An application delegate callback called when the application has just started up.
{
    #pragma unused(notification)
    
    // Remove the debug menu if we're not the debug variant.
    
    #if defined(NDEBUG)
        {
            NSMenuItem *    debugMenuItem;

            debugMenuItem = nil;
            for (NSMenuItem * menuItem in [[NSApp mainMenu] itemArray]) {
                assert([menuItem isKindOfClass:[NSMenuItem class]]);
                if ([menuItem tag] == kDebugMenuTag) {
                    debugMenuItem = menuItem;
                    break;
                }
            }
            [[NSApp mainMenu] removeItem:debugMenuItem];
        }
    #endif
}

- (void)applicationWillTerminate:(NSNotification *)sender
    // An application delegate callback called when the application is about to quit.
    // At this point we stop our service so that it doesn't linger on the network.
{
    #pragma unused(sender)
    [self stopWithStatus:nil];
}

#pragma mark * Bound properties

// The user interface uses Cocoa bindings to set itself up based on these
// KVC/KVO compatible properties.

- (NSArray *)pictureNames
{
    return [NSArray arrayWithObjects:@"Dew Drop", @"Ladybug", @"Snowy Hills", @"Water", nil];
}

@synthesize selectedPictureIndex = _selectedPictureIndex;

+ (NSSet *)keyPathsForValuesAffectingSelectedImagePath
{
    return [NSSet setWithObject:@"selectedPictureIndex"];
}

- (NSString *)selectedImagePath
{
    return [NSString stringWithFormat:@"/Library/Desktop Pictures/Nature/%@.jpg", [self.pictureNames objectAtIndex:self.selectedPictureIndex]];
}

+ (NSSet *)keyPathsForValuesAffectingStartStopButtonTitle
{
    return [NSSet setWithObject:@"running"];
}

@synthesize running = _running;

- (NSString *)startStopButtonTitle
{
    NSString *  result;
    if (self.isRunning) {
        result = @"Stop";
    } else {
        result = @"Start";
    }
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingShortStatus
{
    return [NSSet setWithObject:@"running"];
}

- (NSString *)shortStatus
{
    NSString *  result;
    if (self.isRunning) {
        result = @"Picture Sharing is on.";
    } else {
        result = @"Picture Sharing is off.";
    }
    return result;
}

- (NSString *)longStatus
{
    NSString *  result;
    if (self->_longStatus == nil) {
        result = @"Click Start to turn on Picture Sharing and allow other users to see a thumbnail of the picture below.";
    } else {
        result = self->_longStatus;
    }
    return result;
}

@synthesize longStatus = _longStatus;

- (NSString *)defaultServiceName
{
    NSString *  result;
    
    result = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultServiceName"];
    if (result == nil) {
        NSString *  str;
        
        str = NSFullUserName();
        if (str == nil) {
            result = @"Pictures";
            assert(result != nil);
        } else {
            result = [NSString stringWithFormat:@"%@'s Pictures", str];
            assert(result != nil);
        }
    }
    assert(result != nil);
    return result;
}

- (NSString *)serviceName
{
    if (self->_serviceName == nil) {
        self->_serviceName = [[self defaultServiceName] copy];
        assert(self->_serviceName != nil);
    }
    return self->_serviceName;
}

- (void)setServiceName:(NSString *)newValue
{
    if (newValue != self->_serviceName) {
        [self->_serviceName release];
        self->_serviceName = [newValue copy];
        
        // We write back the service name if it's ever set.  This means that the service 
        // name gets written back a) when the user modifies the field in the UI, and 
        // b) when the user clicks Start and the Bonjour service gets registered. 
        // The upshot is that the service name tracks changes to the user's name 
        // (that is, "Bob Dylan's Pictures" changes to "Mannfred Man's Pictures" if 
        // the user's full name changes from "Bob Dylan" to "Mannfred Man") unless the 
        // user explicitly changes it or they start the service.  After the service has 
        // started we want the name to stay fixed for the benefit of returning clients.

        if (self->_serviceName == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"defaultServiceName"];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:self->_serviceName forKey:@"defaultServiceName"];
        }
    }
}

@synthesize inProgressSendCount = _inProgressSendCount;
@synthesize successfulSendCount = _successfulSendCount;
@synthesize failedSendCount     = _failedSendCount;

+ (NSSet *)keyPathsForValuesAffectingSending
{
    return [NSSet setWithObject:@"inProgressSendCount"];
}

- (BOOL)isSending
{
    return self.inProgressSendCount != 0;
}

#pragma mark * Actions

- (IBAction)startStopAction:(id)sender
    // Called when user clicks the Start/Stop button.  This either starts or 
    // stops the picture sharing service.
{
    #pragma unused(sender)
    if (self.isRunning) {
        [self stopWithStatus:nil];
    } else {
        [self start];
    }
}

- (IBAction)toggleDebugOptionAction:(id)sender
    // Called when the user selects an item from the Debug menu.  We use the 
    // menu item's tag to determine which debug option to toggle.
{
    NSMenuItem *    menuItem;
    
    menuItem = (NSMenuItem *) sender;
    assert([menuItem isKindOfClass:[NSMenuItem class]]);
    assert([menuItem tag] != 0);
    self->_debugOptions ^= [menuItem tag];
    [menuItem setState: ! [menuItem state]];
}

#pragma mark * Core networking code

@synthesize netService = _netService;

static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
    // forward declaration

- (void)start
    // Called to start the network service.
{
    int                 err;
    int                 junk;
    int                 fdForListening;
    int                 chosenPort;
    socklen_t           namelen;

    assert( ! self.isRunning );
    assert(_listeningSocket == NULL);
    assert(self.netService == nil);
    
    chosenPort = -1;        // quieten assert

    // Here, create the socket from traditional BSD socket calls, and then set up a CFSocket with that to listen for 
    // incoming connections.

    // Start by trying to do everything with IPv6.  This will work for both IPv4 and IPv6 clients 
    // via the miracle of mapped IPv4 addresses.
    
    if (self->_debugOptions & kDebugOptionMaskForceIPv4) {
        // This allows us to test IPv4 support on an IPv6-capable kernel.
        fdForListening = -1;
        err = EAFNOSUPPORT;
    } else {
        err = 0;
        fdForListening = socket(AF_INET6, SOCK_STREAM, 0);
        if (fdForListening < 0) {
            err = errno;
        }
    }
    if (err == 0) {
        struct sockaddr_in6 serverAddress6;

        // If we created an IPv6 socket, bind it to a kernel-assigned port and then use 
        // getsockname to determine what port we got.
        
        memset(&serverAddress6, 0, sizeof(serverAddress6));
        serverAddress6.sin6_family = AF_INET6;
        serverAddress6.sin6_len    = sizeof(serverAddress6);

        err = bind(fdForListening, (const struct sockaddr *) &serverAddress6, sizeof(serverAddress6));
        if (err < 0) {
            err = errno;
        }
        if (err == 0) {
            namelen = sizeof(serverAddress6);
            err = getsockname(fdForListening, (struct sockaddr *) &serverAddress6, &namelen);
            if (err < 0) {
                err = errno;
                assert(err != 0);       // quietens static analyser
            } else {
                chosenPort = ntohs(serverAddress6.sin6_port);
            }
        }
    } else if (err == EAFNOSUPPORT) {
        struct sockaddr_in  serverAddress;

        // IPv6 is not available (this can happen, for example, on the iPhone OS 3 kerne).  
        // Let's fall back to IPv4.  Create an IPv4 socket, bind it to a kernel-assigned port 
        // and then use getsockname to determine what port we got.
        
        err = 0;
        fdForListening = socket(AF_INET, SOCK_STREAM, 0);
        if (fdForListening < 0) {
            err = errno;
        }

        if (err == 0) {
            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_len    = sizeof(serverAddress);

            err = bind(fdForListening, (const struct sockaddr *) &serverAddress, sizeof(serverAddress));
            if (err < 0) {
                err = errno;
            }
        }
        if (err == 0) {
            namelen = sizeof(serverAddress);
            err = getsockname(fdForListening, (struct sockaddr *) &serverAddress, &namelen);
            if (err < 0) {
                err = errno;
                assert(err != 0);       // quietens static analyser
            } else {
                chosenPort = ntohs(serverAddress.sin_port);
            }
        }
    }
    
    // Listen for connections on our socket, then create a CFSocket to route any connections 
    // to a run loop based callback.
    
    if (err == 0) {
        err = listen(fdForListening, 5);
        if (err < 0) {
            err = errno;
        } else {
            CFSocketContext     context = {0, self, NULL, NULL, NULL};
            CFRunLoopSourceRef  rls;
            
            self->_listeningSocket = CFSocketCreateWithNative(NULL, fdForListening, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
            if (self->_listeningSocket != NULL) {
                assert( CFSocketGetSocketFlags(self->_listeningSocket) & kCFSocketCloseOnInvalidate );
                fdForListening = -1;        // so that the clean up code doesn't close it
                
                rls = CFSocketCreateRunLoopSource(NULL, self->_listeningSocket, 0);
                assert(rls != NULL);
                
                CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
                
                CFRelease(rls);
            }
        }
    }

    // Register our service with Bonjour.

    if (err == 0) {
        NSLog(@"chosenPort = %d", chosenPort);

        self.netService = [[[NSNetService alloc] initWithDomain:@"" type:@"_wwdcpic2._tcp." name:self.serviceName port:chosenPort] autorelease];
        if (self.netService != nil) {
            [self.netService setDelegate:self];
            [self.netService publishWithOptions:0];
        }
    }

    // Clean up.
    
    if ( (self->_listeningSocket != NULL) && (self.netService != nil) ) {
        self.longStatus = @"Click Stop to turn off Picture Sharing.";
        self.running = YES;
    } else {
        [self stopWithStatus:@"Failed to start up."];
    }
    if (fdForListening >= 0) {
        junk = close(fdForListening);
        assert(junk == 0);
    }
}

- (void)stopWithStatus:(NSString *)newStatus
    // Called to stop the network service.
{
    // assert(self.isRunning);          -- can be called when we're not running, for example, when we fail to start up
    // newStatus may be nil, which results in a generic 'Click Start to turn on...' message.

    self.longStatus = newStatus;

    if (self.netService != nil) {
        [self.netService setDelegate:nil];
        [self.netService stop];
        self.netService = nil;
    }
    if (self->_listeningSocket != NULL) {
        CFSocketInvalidate(self->_listeningSocket);
        CFRelease(self->_listeningSocket);
        self->_listeningSocket = NULL;
    }

    [self.queue cancelAllOperations];
    // We don't do a -waitUntilAllOperationsAreFinished because the operations may require 
    // the main thread's run loop to be running in the default mode in order to complete 
    // the cancellation.  This isn't actually the case right now (due to implementation 
    // details of NSOperationQueue and the FileSendOperation), but I don't want to rely 
    // on those implementation details staying the same forever.

    self.running = NO;
}

- (void)netServiceDidPublish:(NSNetService *)sender
    // An NSNetService delegate callback that's called when the service is successfully 
    // registered on the network.  We set our service name to the name of the service 
    // because the service might be been automatically renamed by Bonjour to avoid 
    // conflicts.
{
    assert(sender == self.netService);
    self.serviceName = [sender name];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    // An NSNetService delegate callback that's called when the service fails to 
    // register on the network.  We respond by shutting down our entire network 
    // service.
{
    assert(sender == self.netService);
    #pragma unused(sender)
    #pragma unused(errorDict)
    [self stopWithStatus:@"Failed to registered service."];
}

- (void)netServiceDidStop:(NSNetService *)sender
    // An NSNetService delegate callback that's called when the service spontaneously 
    // stops.  This rarely happens on Mac OS X but, regardless, we respond by shutting 
    // down our entire network service.
{
    assert(sender == self.netService);
    #pragma unused(sender)
    [self stopWithStatus:@"Network service stopped."];
}

- (NSOperationQueue *)queue
{
    if (self->_queue == nil) {
        self->_queue = [[NSOperationQueue alloc] init];
        assert(self->_queue != nil);
    }
    return self->_queue;
}

static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    // The CFSocket callback associated with _listeningSocket.  This is called when 
    // a new connection arrives.  It routes the connection to the -connectionReceived: 
    // method.
{
    ServerAppDelegate *   obj;
    int             fd;
    
    obj = (ServerAppDelegate *) info;
    assert([obj isKindOfClass:[ServerAppDelegate class]]);
    
    assert(s == obj->_listeningSocket);
    #pragma unused(s)
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(type)
    assert(address != NULL);
    #pragma unused(address)
    assert(data != nil);
    
    fd = * (const int *) data;
    assert(fd >= 0);
    [obj connectionReceived:fd];
}

- (void)connectionReceived:(int)fd
    // Called when a connection is received.  We respond by creating and running a 
    // FileSendOperation that sends the current picture down the connection.
{
    CFWriteStreamRef    writeStream;
    FileSendOperation * op;
    Boolean             success;
    
    assert(fd >= 0);

    // Create a CFStream from the connection socket.
    
    CFStreamCreatePairWithSocket(NULL, fd, NULL, &writeStream);
    assert(writeStream != nil);
    
    success = CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    assert(success);

    // Create a FileSendOperation to run the connection.
    
    op = [[FileSendOperation alloc] initWithFilePath:self.selectedImagePath outputStream:(NSOutputStream *) writeStream];
    assert(op != nil);

    // Configure that operation.
    
    #if ! defined(NDEBUG)
        if (self->_debugOptions & kDebugOptionMaskStallSend) {
            op.debugStallSend = YES;
        }
        if (self->_debugOptions & kDebugOptionMaskSendBadChecksum) {
            op.debugSendBadChecksum = YES;
        }
    #endif
    
    // Watch for the operation finishing.  In a real application I'd probably use something more 
    // sophisticated (like the QWatchedOperationQueue class from the LinkedImageFetcher sample code), 
    // but in this small sample I just use KVO directly.
    
    [op addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_queue];
    self.inProgressSendCount += 1;
    
    // Enqueue the operation and then clean up.
    
    [self.queue addOperation:op];
    
    [op release];
    CFRelease(writeStream);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_queue) {
        assert([keyPath isEqual:@"isFinished"]);
        assert([object isKindOfClass:[FileSendOperation class]]);
        
        // This notification is delivered when a FileSendOperation's "isFinished" property 
        // changes.  We respond by calling the -didFinishOperation: operation on the main 
        // thread to clean up that operation.
        
        assert( [(FileSendOperation *) object isFinished] );
        
        // IMPORTANT
        // ---------
        // KVO notifications arrive on the thread that sets the property.  In this case that's 
        // always going to be the main thread (because FileSendOperation is a concurrent operation 
        // that runs off the main thread run loop), but I take no chances and force us to the 
        // main thread.  There's no worries about race conditions here (one of the things that 
        // QWatchedOperationQueue solves nicely) because AppDelegate lives for the lifetime of 
        // the application.
        
        [self performSelectorOnMainThread:@selector(didFinishOperation:) withObject:object waitUntilDone:NO];
    }
    if (NO) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)didFinishOperation:(FileSendOperation *)op
    // Called when a FileSendOperation finishes.  It simply updates our statistics. 
{
    assert([op isKindOfClass:[FileSendOperation class]]);
    
    [op removeObserver:self forKeyPath:@"isFinished"];
    
    if (op.error == nil) {
        self.successfulSendCount += 1;
    } else {
        self.failedSendCount += 1;
    }
    assert(self.inProgressSendCount != 0);
    self.inProgressSendCount -= 1;
    
    if (self->_debugOptions & kDebugOptionMaskAutoAdvanceImage) {
        NSUInteger  newPictureIndex;

        newPictureIndex = self.selectedPictureIndex + 1;
        if (newPictureIndex == [self.pictureNames count]) {
            newPictureIndex = 0;
        }
        self.selectedPictureIndex = newPictureIndex;
    }
}

@end
