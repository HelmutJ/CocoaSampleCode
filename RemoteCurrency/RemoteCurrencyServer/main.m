/*
    File:       main.m

    Contains:   A command line wrappes for the RemoteCurrencyServer class.

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
#import "RemoteCurrencyServer.h"

#include <getopt.h>

int main(int argc, char **argv)
{
    #pragma unused(argc)
    #pragma unused(argv)
    int                     retVal;
    NSAutoreleasePool *     pool;
    int                     opt;
    NSString *              portName;
    NSInteger               port;
    BOOL                    disableIPv6;
    BOOL                    disableBonjour;
    RemoteCurrencyServer *  server;
    
    pool = [[NSAutoreleasePool alloc] init];
    assert(pool != nil);
        
    // Parse the command line arguments.
    
    portName = nil;
    port = 0;
    disableIPv6 = NO;
    disableBonjour = NO;
    retVal = EXIT_SUCCESS;
    do {
        opt = getopt(argc, argv, "p:4B");
        switch (opt) {
            case 'p': {
                portName = [NSString stringWithUTF8String:optarg];
                if ( (portName == nil) || ([portName length] == 0) ) {
                    retVal = EXIT_FAILURE;
                }
            } break;
            case '4': {
                disableIPv6 = YES;
            } break;
            case 'B': {
                disableBonjour = YES;
            } break;
            default:
                // fall through
            case '?': {
                retVal = EXIT_FAILURE;
            } break;
            case -1: {
                // do nothing
            } break;
        }
    } while ((retVal == EXIT_SUCCESS) && (opt != -1));
    
    if ( (retVal == EXIT_SUCCESS) && (optind != argc) ) {
        retVal = EXIT_FAILURE;
    }
    
    // Run the server based on those arguments.
    
    if (retVal == EXIT_FAILURE) {
        fprintf(stderr, "usage: %s [-p port] [-4] [-B]\n", getprogname());
    } else {
    
        // Check the ports are reasonable.
        
        if ( (retVal == EXIT_SUCCESS) && (portName != nil) ) {
            port = [portName intValue];
            if ( (port <= 0) || (port >= 65536) ) {
                fprintf(stderr, "%s: bad port number: %s\n", getprogname(), [portName UTF8String]);
                retVal = EXIT_FAILURE;
            }
        }
        
        // Run the server.
        
        if (retVal == EXIT_SUCCESS) {
            server = [[[RemoteCurrencyServer alloc] init] autorelease];
            assert(server != nil);
            
            if (port != 0) {
                server.port = port;
            }
            if (disableIPv6) {
                server.disableIPv6 = YES;
            }
            if (disableBonjour) {
                server.disableBonjour = YES;
            }
            
            [server run];
        }
    }
    
    [pool drain];
    
    return retVal;
}
