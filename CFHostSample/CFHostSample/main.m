/*
    File:       main.m

    Contains:   A simple command line tool to exercise teh QCFHostResolver object.

    Written by: DTS

    Copyright:  Copyright (c) 2012 Apple Inc. All Rights Reserved.

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

#import "QCFHostResolver.h"

@interface MainObj : NSObject

- (id)initWithResolvers:(NSArray *)resolvers;

@property (nonatomic, copy,   readonly ) NSArray *      resolvers;

- (void)run;

@end

@interface MainObj () <QCFHostResolverDelegate>

@property (nonatomic, assign, readwrite) NSUInteger     runningResolverCount;

@end

@implementation MainObj

@synthesize resolvers = _resolvers;

@synthesize runningResolverCount = _runningResolverCount;

- (id)initWithResolvers:(NSArray *)resolvers
{
    self = [super init];
    if (self != nil) {
        self->_resolvers = [resolvers copy];
    }
    return self;
}

- (void)run
{
    self.runningResolverCount = [self.resolvers count];
    
    // Start each of the resolvers.
    
    for (QCFHostResolver * resolver in self.resolvers) {
        resolver.delegate = self;
        [resolver start];
    }
    
    // Run the run loop until they are all done.
    
    while (self.runningResolverCount != 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)hostResolverDidFinish:(QCFHostResolver *)resolver
    // A resolver delegate callback, called when the resolve completes successfully. 
    // Prints the results.
{
    NSString *      argument;
    NSString *      result;
    
    if (resolver.name != nil) {
        argument = resolver.name;
        result   = [resolver.resolvedAddressStrings componentsJoinedByString:@", "];
    } else {
        argument = resolver.addressString;
        result   = [resolver.resolvedNames componentsJoinedByString:@", "];
    }
    fprintf(stderr, "%s -> %s\n", [argument UTF8String], [result UTF8String]);
    self.runningResolverCount -= 1;
}

- (void)hostResolver:(QCFHostResolver *)resolver didFailWithError:(NSError *)error
    // A resolver delegate callback, called when the resolve fails.  Prints the error.
{
    NSString *      argument;
    
    if (resolver.name != nil) {
        argument = resolver.name;
    } else {
        argument = resolver.addressString;
    }
    fprintf(stderr, "%s -> %s / %zd\n", [argument UTF8String], [[error domain] UTF8String], (ssize_t) [error code]);
    self.runningResolverCount -= 1;
}

@end

int main(int argc, char **argv)
{
    int                 retVal;
    int                 opt;
    NSMutableArray *    resolvers;
    
    @autoreleasepool {
    
        // Parse the command line parameters.
        
        retVal = EXIT_SUCCESS;
        resolvers = [[NSMutableArray alloc] init];
        do {
            QCFHostResolver *    resolver;

            resolver = nil;

            opt = getopt(argc, argv, "h:a:");
            switch (opt) {
                case -1: {
                    // do nothing
                } break;
                case 'h': {
                    resolver = [[QCFHostResolver alloc] initWithName:[NSString stringWithUTF8String:optarg]];
                    if (resolver == nil) {
                        retVal = EXIT_FAILURE;
                    }
                } break;
                case 'a': {
                    resolver = [[QCFHostResolver alloc] initWithAddressString:[NSString stringWithUTF8String:optarg]];
                    if (resolver == nil) {
                        retVal = EXIT_FAILURE;
                    }
                } break;
                default: {
                    retVal = EXIT_FAILURE;
                } break;
            }
            
            if (resolver != nil) {
                [resolvers addObject:resolver];
            }
        } while (opt != -1);
        
        // Check for inconsistencies.
        
        if ( (retVal == EXIT_SUCCESS) && ([resolvers count] == 0) ) {
            retVal = EXIT_FAILURE;          // nothing to do
        }
        if ( (retVal == EXIT_SUCCESS) && (optind != argc) ) {
            retVal = EXIT_FAILURE;          // extra stuff an the command line
        }
        
        // Print the usage or do the resolution.
        
        if (retVal != EXIT_SUCCESS) {
            fprintf(stderr, "usage: %s -h apple.com\n", getprogname());
            fprintf(stderr, "       %s -a 17.172.224.47\n", getprogname());
        } else {
            MainObj *   mainObj;
            
            mainObj = [[MainObj alloc] initWithResolvers:resolvers];
            assert(mainObj != nil);
            
            [mainObj run];
        }
    }
    
    return retVal;
}
