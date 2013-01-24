/*
    File:       main.m

    Contains:   Command line tool main.

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

#import <Foundation/Foundation.h>

#import "DNSSDRegistration.h"
#import "DNSSDBrowser.h"
#import "DNSSDService.h"

static NSString * Quote(NSString * str)
    // Returns a quoted form of the string.  This isn't intended to be super-clever, 
    // for example, it doesn't escape any single quotes in the string.
{
    return [NSString stringWithFormat:@"'%@'", (str == nil) ? @"" : str];
}

// MainBase is an abstract base class from which each of the main classes are derived. 
// It's only that to support starting and stopping the event loop.

@interface MainBase : NSObject
@property (nonatomic, assign, readwrite) BOOL quitNow;
- (void)run;
- (void)quit;
@end

#pragma mark * RegisterMain

// RegisterMain implements the "-r" command using the DNSSDRegistration object.

@interface RegisterMain : MainBase <DNSSDRegistrationDelegate>
@property (nonatomic, copy,   readwrite) NSString *     type;
@property (nonatomic, assign, readwrite) NSUInteger     port;

@property (nonatomic, retain, readwrite) DNSSDRegistration *  registration;
@end

@implementation RegisterMain

@synthesize type = type_;
@synthesize port = port_;

@synthesize registration = registration_;

- (void)dealloc
{
    [self->registration_ stop];
    [self->registration_ release];
    [self->type_ release];
    [super dealloc];
}

- (void)run
{
    assert(self.type != nil);
    assert(self.registration == nil);
    
    self.registration = [[[DNSSDRegistration alloc] initWithDomain:nil type:self.type name:nil port:self.port] autorelease];
    assert(self.registration != nil);

    self.registration.delegate = self;

    [self.registration start];

    [super run];
}

- (void)dnssdRegistrationWillRegister:(DNSSDRegistration *)sender
{
    assert(sender == self.registration);
    #pragma unused(sender)
    
    NSLog(@"will register %@ / %@ / %@", Quote(self.registration.name), Quote(self.registration.type), Quote(self.registration.domain));
}

- (void)dnssdRegistrationDidRegister:(DNSSDRegistration *)sender
{
    assert(sender == self.registration);
    #pragma unused(sender)

    NSLog(@"registered as %@ / %@ / %@", Quote(self.registration.registeredName), Quote(self.registration.type), Quote(self.registration.registeredDomain));
}

- (void)dnssdRegistration:(DNSSDRegistration *)sender didNotRegister:(NSError *)error
{
    assert(sender == self.registration);
    #pragma unused(sender)
    assert(error != nil);

    NSLog(@"did not register (%@ / %zd)", [error domain], (ssize_t) [error code]);
    [self quit];
}

- (void)dnssdRegistrationDidStop:(DNSSDRegistration *)sender
{
    assert(sender == self.registration);
    #pragma unused(sender)

    NSLog(@"stopped");
}

@end

#pragma mark * BrowseMain

// BrowseMain implements the "-b" command using the DNSSDBrowser object.

@interface BrowseMain : MainBase <DNSSDBrowserDelegate>
@property (nonatomic, copy,   readwrite) NSString *                 type;

@property (nonatomic, retain, readwrite) DNSSDBrowser *       browser;
@end

@implementation BrowseMain

@synthesize type = type_;

@synthesize browser = browser_;

- (void)dealloc
{
    [self->browser_ stop];
    [self->browser_ release];
    [self->type_ release];
    [super dealloc];
}

- (void)run
{
    assert(self.browser == nil);
    assert(self.type != nil);
    
    self.browser = [[[DNSSDBrowser alloc] initWithDomain:nil type:self.type] autorelease];
    assert(self.browser != nil);
    
    self.browser.delegate = self;
    
    [self.browser startBrowse];
    
    [super run];
}

- (void)dnssdBrowserWillBrowse:(DNSSDBrowser *)browser
{
    assert(browser == self.browser);
    #pragma unused(browser)

    NSLog(@"will browse %@ / %@", Quote(self.browser.type), Quote(self.browser.domain));
}

- (void)dnssdBrowser:(DNSSDBrowser *)browser didAddService:(DNSSDService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    #pragma unused(browser)

    NSLog(@"   add service %@ / %@ / %@%s", Quote(service.name), Quote(service.type), Quote(service.domain), moreComing ? " ..." : "");
}

- (void)dnssdBrowser:(DNSSDBrowser *)browser didRemoveService:(DNSSDService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    #pragma unused(browser)

    NSLog(@"remove service %@ / %@ / %@%s", Quote(service.name), Quote(service.type), Quote(service.domain), moreComing ? " ..." : "");
}

- (void)dnssdBrowser:(DNSSDBrowser *)browser didNotBrowse:(NSError *)error
{
    assert(browser == self.browser);
    #pragma unused(browser)
    assert(error != nil);
    
    NSLog(@"did not browse (%@ / %zd)", [error domain], (ssize_t) [error code]);
    [self quit];
}

- (void)dnssdBrowserDidStopBrowse:(DNSSDBrowser *)browser
{
    assert(browser == self.browser);
    #pragma unused(browser)
    NSLog(@"stopped");
}

@end

#pragma mark * ResolveMain

// ResolveMain implements the "-l" command using the DNSSDService object.

@interface ResolveMain : MainBase <DNSSDServiceDelegate>
@property (nonatomic, copy,   readwrite) NSString *     name;
@property (nonatomic, copy,   readwrite) NSString *     type;
@property (nonatomic, copy,   readwrite) NSString *     domain;

@property (nonatomic, retain, readwrite) DNSSDService *  service;
@end

@implementation ResolveMain

@synthesize name   = name_;
@synthesize type   = type_;
@synthesize domain = domain_;

@synthesize service = service_;

- (void)dealloc
{
    [self->name_ release];
    [self->type_ release];
    [self->domain_ release];
    [super dealloc];
}

- (void)run
{
    assert(self.service == nil);
    assert(self.type != nil);
    
    self.service = [[[DNSSDService alloc] initWithDomain:self.domain type:self.type name:self.name] autorelease];
    assert(self.service != nil);
    
    self.service.delegate = self;
    
    [self.service startResolve];
    
    [super run];
}

- (void)dnssdServiceWillResolve:(DNSSDService *)service
{
    assert(service == self.service);
    #pragma unused(service)
    NSLog(@"will resolve %@ / %@ / %@", Quote(self.service.name), Quote(self.service.type), Quote(self.service.domain));
}

- (void)dnssdServiceDidResolveAddress:(DNSSDService *)service
{
    assert(service == self.service);
    #pragma unused(service)
    NSLog(@"did resolve to %@:%zu", service.resolvedHost, (size_t) service.resolvedPort);
    [self quit];
}

- (void)dnssdService:(DNSSDService *)service didNotResolve:(NSError *)error
{
    assert(service == self.service);
    #pragma unused(service)
    NSLog(@"did not resolve (%@ / %zd)", [error domain], (ssize_t) [error code]);
    [self quit];
}

- (void)dnssdServiceDidStop:(DNSSDService *)service
{
    assert(service == self.service);
    #pragma unused(service)
    NSLog(@"stopped");
}

@end

#pragma mark * main

@implementation MainBase

@synthesize quitNow = quitNow_;

- (void)run
{
    while ( ! self.quitNow ) {
        BOOL    didRun;
        
        didRun = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        assert(didRun);
    }
}

- (void)quit
{
    self.quitNow = YES;
}

@end

int main(int argc, char **argv)
{
    #pragma unused(argc)
    #pragma unused(argv)
    int                 retVal;
    MainBase *          mainObj;

    @autoreleasepool {
        retVal = EXIT_FAILURE;
        if ( (argc == 4) && (strcasecmp(argv[1], "-r") == 0) ) {
            RegisterMain *  registerObj;

            registerObj = [[[RegisterMain alloc] init] autorelease];
            assert(registerObj != nil);
            
            registerObj.type = [NSString stringWithUTF8String:argv[2]];
            registerObj.port = (NSUInteger) atoi(argv[3]);
            if ( (registerObj.type != nil) && ([registerObj.type length] != 0) && ! [registerObj.type hasPrefix:@"."] && 
                 (registerObj.port != 0) && (registerObj.port < 65536) ) {
                mainObj = registerObj;
                retVal = EXIT_SUCCESS;
            }
        } else if ( (argc == 3) && (strcasecmp(argv[1], "-b") == 0) ) {
            BrowseMain *    browseObj;

            browseObj = [[[BrowseMain alloc] init] autorelease];
            assert(browseObj != nil);
            
            browseObj.type = [NSString stringWithUTF8String:argv[2]];
            if ( (browseObj.type != nil) && ([browseObj.type length] != 0) && ! [browseObj.type hasPrefix:@"."] ) {
                mainObj = browseObj;
                retVal = EXIT_SUCCESS;
            }
        } else if ( (argc == 5) && (strcasecmp(argv[1], "-l") == 0) ) {
            ResolveMain *   resolveObj;

            resolveObj = [[[ResolveMain alloc] init] autorelease];
            assert(resolveObj != nil);
            
            resolveObj.name   = [NSString stringWithUTF8String:argv[2]];
            resolveObj.type   = [NSString stringWithUTF8String:argv[3]];
            resolveObj.domain = [NSString stringWithUTF8String:argv[4]];
            if ( (resolveObj.name   != nil) && ([resolveObj.name   length] != 0) && 
                 (resolveObj.type   != nil) && ([resolveObj.type   length] != 0) && ! [resolveObj.type   hasPrefix:@"."] && 
                 (resolveObj.domain != nil) && ([resolveObj.domain length] != 0) && ! [resolveObj.domain hasPrefix:@"."] ) {
                mainObj = resolveObj;
                retVal = EXIT_SUCCESS;
            }
        }
        
        if (retVal == EXIT_FAILURE) {
            fprintf(stderr, "usage: %s -r type port\n", getprogname());
            fprintf(stderr, "       %s -b type\n", getprogname());
            fprintf(stderr, "       %s -l name type domain\n", getprogname());
        } else {
            [mainObj run];
        }
    }

    return retVal;
}
