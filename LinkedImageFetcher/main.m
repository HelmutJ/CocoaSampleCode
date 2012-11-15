/*
    File:       main.m

    Contains:   A tool to fetch all of the images linked to by an HTML page.

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

#include <Foundation/Foundation.h>

#import "LinkedImageFetcher.h"

int main(int argc, char **argv)
{
    NSAutoreleasePool *     pool;
    int                     retVal;
    int                     maximumDepth;
    LinkedImageFetcher *    fetcher;
    
    pool = [[NSAutoreleasePool alloc] init];
    assert(pool != nil);

    retVal = EXIT_FAILURE;
    if ( (argc == 2) || (argc == 3) ) {
        if (argc == 2) {
            maximumDepth = 0;
        } else {
            maximumDepth = atoi(argv[2]);
        }
    
        // Use our convenience method to create the LinkedImageFetcher object.
    
        fetcher = [LinkedImageFetcher fetcherWithURLString:argv[1] maximumDepth:maximumDepth];
        if (fetcher == nil) {
            // Do nothing.  +fetcherWithURLString:maximumDepth: has already printed the error.
        } else {
            BOOL    success;

            // Run that object.
            
            success = [fetcher start];
            if ( ! success ) {
                fprintf(stderr, "%s: failed to create directory: %s\n", getprogname(), [fetcher.imagesDirPath UTF8String]);
            } else {
                do {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                } while ( ! fetcher.done );
                success = (fetcher.error == nil);
                if ( ! success ) {
                    fprintf(stderr, "%s: failed: %s %d\n", getprogname(), [[fetcher.error domain] UTF8String], (int) [fetcher.error code]);
                }
            }
            if (success) {
                retVal = EXIT_SUCCESS;
            }
        }
    } else {
        fprintf(stderr, "usage: %s URL [depth]\n", getprogname());
    }

    [pool drain];
    
    return retVal;
}
