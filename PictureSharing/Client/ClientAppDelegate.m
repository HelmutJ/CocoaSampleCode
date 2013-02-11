/*
    File:       ClientAppDelegate.m

    Contains:   Core client application logic.

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

#import "ClientAppDelegate.h"

#import "FileReceiveOperation.h"

@interface ClientAppDelegate () <NSNetServiceBrowserDelegate>

// read/write versions of public properties

@property (nonatomic, retain, readwrite) NSImage *              lastReceivedImage;
@property (nonatomic, copy,   readwrite) NSString *             longStatus;

// browser internal properties

@property (nonatomic, retain, readwrite) NSNetServiceBrowser *  browser;
@property (nonatomic, retain, readonly ) NSMutableSet *         pendingServicesToAdd;
@property (nonatomic, retain, readonly ) NSMutableSet *         pendingServicesToRemove;

// downloader internal properties

@property (nonatomic, retain, readonly ) NSOperationQueue *     queue;
@property (nonatomic, assign, readwrite) NSUInteger             runningOperations;
@property (nonatomic, assign, readonly ) BOOL                   isReceiving;

// forward declarations

- (void)startBrowsing;
- (void)startReceiveFromService:(NSNetService *)service;

@end

@implementation ClientAppDelegate

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

    // Start the Bonjour browser.

    [self startBrowsing];
}

- (void)applicationWillTerminate:(NSNotification *)notification
    // An application delegate callback called when the application is about to quit.
    // At this point we stop any downloads.  We leave the browser running because 
    // the system will clean it up when our process exits.
{
    #pragma unused(notification)
    if (self.isReceiving) {
        [self.queue cancelAllOperations];
    }
}

#pragma mark * Bound properties

// The user interface uses Cocoa bindings to set itself up based on these
// KVC/KVO compatible properties.

- (NSMutableSet *)services
{
    if (self->_services == nil) {
        self->_services = [[NSMutableSet alloc] init];
    }
    return self->_services;
}

- (NSArray *)sortDescriptors
{
    if (self->_sortDescriptors == nil) {
        SEL     selector;
        
        if ([[NSString string] respondsToSelector:@selector(localizedStandardCompare)]) {
            selector = @selector(localizedStandardCompare:);
        } else {
            selector = @selector(localizedCaseInsensitiveCompare:);
        }
        self->_sortDescriptors = [[NSArray alloc] initWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:selector] autorelease], 
            [[[NSSortDescriptor alloc] initWithKey:@"domain" ascending:YES selector:selector] autorelease],
            nil
        ];
    }
    return self->_sortDescriptors;
}

@synthesize lastReceivedImage = _lastReceivedImage;

@synthesize servicesArray = _servicesArray;

- (NSString *)longStatus
{
    NSString *  result;
    if (self->_longStatus == nil) {
        result = @"Click on a service to download its image.";
    } else {
        result = self->_longStatus;
    }
    return result;
}

@synthesize longStatus = _longStatus;

@synthesize runningOperations = _runningOperations;

+ (NSSet *)keyPathsForValuesAffectingIsReceiving
{
    return [NSSet setWithObject:@"runningOperations"];
}

- (BOOL)isReceiving
{
    return (self.runningOperations != 0);
}

#pragma mark * Actions

- (IBAction)tableRowClickedAction:(id)sender
    // Called when user clicks a row in the services table.  If we're not already receiving, 
    // we kick off a receive.
{
    #pragma unused(sender)
    // We test for a positive clickedRow to eliminate clicks in the column headers.
    if ( ([sender clickedRow] >= 0) && [[self.servicesArray selectedObjects] count] != 0) {
        NSNetService *  service;

        service = [[self.servicesArray selectedObjects] objectAtIndex:0];
        assert([service isKindOfClass:[NSNetService class]]);

        [self startReceiveFromService:service];
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

#pragma mark * Browsing

@synthesize browser       = _browser;

- (NSMutableSet *)pendingServicesToAdd
{
    if (self->_pendingServicesToAdd == nil) {
        self->_pendingServicesToAdd = [[NSMutableSet alloc] init];
    }
    return self->_pendingServicesToAdd;
}

- (NSMutableSet *)pendingServicesToRemove
{
    if (self->_pendingServicesToRemove == nil) {
        self->_pendingServicesToRemove = [[NSMutableSet alloc] init];
    }
    return self->_pendingServicesToRemove;
}

- (void)startBrowsing
    // Starts a browse operation for our service type.
{
    assert(self.browser == nil);
    self.browser = [[[NSNetServiceBrowser alloc] init] autorelease];
    [self.browser setDelegate:self];
    // Passing in "" for the domain causes us to browse in the default browse domain
    [self.browser searchForServicesOfType:@"_wwdcpic2._tcp." inDomain:@""];
}

- (void)stopBrowsingWithStatus:(NSString *)status
    // Stops the browser after some sort of fatal error, displaying 
    // the status message to the user.
{
    assert(status != nil);
    
    [self.browser setDelegate:nil];
    [self.browser stop];
    self.browser = nil;
    
    [self.pendingServicesToAdd removeAllObjects];
    [self.pendingServicesToRemove removeAllObjects];

    [self willChangeValueForKey:@"services"];
    [self.services removeAllObjects];
    [self  didChangeValueForKey:@"services"];
    
    self.longStatus = status;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    // An NSNetService delegate callback that's called when we discover a service. 
    // We add this service to our set of pending services to add and, if there are 
    // no more services coming, we add that set to our services set, triggering the 
    // necessary KVO notification.
{
    assert(aNetServiceBrowser == self.browser);
    #pragma unused(aNetServiceBrowser)
    
    [self.pendingServicesToAdd addObject:aNetService];
    
    if ( ! moreComing ) {
        NSSet * setToAdd;

        setToAdd = [[self.pendingServicesToAdd copy] autorelease];
        assert(setToAdd != nil);
        [self.pendingServicesToAdd removeAllObjects];
        
        [self willChangeValueForKey:@"services" withSetMutation:NSKeyValueUnionSetMutation usingObjects:setToAdd];
        [self.services unionSet:setToAdd];
        [self  didChangeValueForKey:@"services" withSetMutation:NSKeyValueUnionSetMutation usingObjects:setToAdd];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    // An NSNetService delegate callback that's called when a service goes away. 
    // We add this service to our set of pending services to remove and, if there are 
    // no more services coming (well, going :-), we remove that set to our services set, 
    // triggering the necessary KVO notification.
{
    assert(aNetServiceBrowser == self.browser);
    #pragma unused(aNetServiceBrowser)

    [self.pendingServicesToRemove addObject:aNetService];
    
    if ( ! moreComing ) {
        NSSet * setToRemove;

        setToRemove = [[self.pendingServicesToRemove copy] autorelease];
        assert(setToRemove != nil);
        [self.pendingServicesToRemove removeAllObjects];

        [self willChangeValueForKey:@"services" withSetMutation:NSKeyValueMinusSetMutation usingObjects:setToRemove];
        [self.services minusSet:setToRemove];
        [self  didChangeValueForKey:@"services" withSetMutation:NSKeyValueMinusSetMutation usingObjects:setToRemove];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
    // An NSNetService delegate callback that's called when the service spontaneously 
    // stops.  This rarely happens on Mac OS X but, regardless, we respond by shutting 
    // down our browser.
{
    assert(aNetServiceBrowser == self.browser);
    #pragma unused(aNetServiceBrowser)
    [self stopBrowsingWithStatus:@"Service browsing stopped."];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
    // An NSNetService delegate callback that's called when the browser fails 
    // completely.  We respond by shutting it down.
{
    assert(aNetServiceBrowser == self.browser);
    #pragma unused(aNetServiceBrowser)
    assert(errorDict != nil);
    #pragma unused(errorDict)
    [self stopBrowsingWithStatus:@"Service browsing failed."];
}

#pragma mark Core receive

- (NSOperationQueue *)queue
{
    if (self->_queue == nil) {
        self->_queue = [[NSOperationQueue alloc] init];
        assert(self->_queue != nil);
    }
    return self->_queue;
}

- (void)startReceiveFromService:(NSNetService *)service
    // Starts a receive operation from the specified service.
{
    NSInputStream *         stream;
    FileReceiveOperation *  op;
    
    assert(service != nil);
    
    // Cancel any previous download operations.
    
    [self.queue cancelAllOperations];
    
    // Nix the current image so that if the download fails or stalls we're left with 
    // a blank image rather than the previous image.
    
    self.lastReceivedImage = nil;
    
    // Create a stream from the service, and create a FileReceiveOperation with that stream.
    
    [service getInputStream:&stream outputStream:nil];
    assert(stream != nil);

    op = [[FileReceiveOperation alloc] initWithInputStream:stream];
    assert(op != nil);

    // -[NSNetService getInputStream:outputStream:] currently returns the stream 
    // with a reference that we have to release (something that's counter to the 
    // standard Cocoa memory management rules <rdar://problem/6868813>).

    [stream release];

    // Configure the operation.
    
    #if ! defined(NDEBUG)
        if (self->_debugOptions & kDebugOptionMaskStallReceive) {
            op.debugStallReceive = YES;
        }
        if (self->_debugOptions & kDebugOptionMaskReceiveBadChecksum) {
            op.debugReceiveBadChecksum = YES;
        }
    #endif

    // Watch for the operation finishing.  In a real application I'd probably use something more 
    // sophisticated (like the QWatchedOperationQueue class from the LinkedImageFetcher sample code), 
    // but in this small sample I just use KVO directly.
    
    [op addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_queue];

    // Enqueue the operation and then clean up.

    [self.queue addOperation:op];

    [op release];
    
    self.longStatus = [NSString stringWithFormat:@"Downloading image from “%@”.", [service name]];
    self.runningOperations += 1;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_queue) {
        assert([keyPath isEqual:@"isFinished"]);
        assert([object isKindOfClass:[FileReceiveOperation class]]);
        
        // This notification is delivered when a FileReceiveOperation's "isFinished" property 
        // changes.  We respond by calling the -didFinishOperation: operation on the main 
        // thread to clean up that operation.
        
        assert( [(FileReceiveOperation *) object isFinished] );

        // IMPORTANT
        // ---------
        // KVO notifications arrive on the thread that sets the property.  In this case that's 
        // always going to be the main thread (because FileReceiveOperation is a concurrent operation 
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

- (void)didFinishOperation:(FileReceiveOperation *)op
    // Called when a FileSendOperation finishes.  It gets the downloaded file, creates 
    // an image from it, and displays that image.
{
    NSString *  status;

    assert([op isKindOfClass:[FileReceiveOperation class]]);
    
    [op removeObserver:self forKeyPath:@"isFinished"];
    
    status = nil;
    if (op.error == nil) {
        NSData *    imageData;
        
        imageData = [NSData dataWithContentsOfMappedFile:op.finalFilePath];
        if (imageData == nil) {
            status = @"Image load failed.";
        } else {
            NSImage *   image;

            image = [[[NSImage alloc] initWithData:imageData] autorelease];
            if (image == nil) {
                status = @"Downloaded image was unusable.";
            } else {
                self.lastReceivedImage = image;
            }
        }
        
        // Delete the file after we've mapped it so that, once we get rid of this image 
        // and hence unmap the file, the system will reclaim the disk space automagically.
        
        (void) [[NSFileManager defaultManager] removeItemAtPath:op.finalFilePath error:NULL];
    } else if ([[op.error domain] isEqual:NSCocoaErrorDomain] && ([op.error code] == NSUserCancelledError)) {
        status = @"Download cancelled.";
    } else {
        status = @"Download failed.";
    }
    
    // Only set the status if we're the last running operation.  This prevents cancelled 
    // operations from overriding the initial status of the last running operation.
    
    if (self.runningOperations == 1) {
        self.longStatus = status;
    }
    
    assert(self.runningOperations != 0);
    self.runningOperations -= 1;
}

@end
