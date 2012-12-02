/*
     File: main.m
 Abstract: This example shows how to do authentication of messages over Distributed Objects.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#include <stdio.h>

#define CONNECTION_NAME @"authentication test"

@interface Authenticator : NSObject <NSConnectionDelegate>
    // An instance of this class will act as the NSConnection delegates.
    // NSConnection delegates can do things in addition to authenticate
    // messages, but we're just interested in authentication here.

- (NSData *)authenticationDataForComponents:(NSArray *)components;
    // Computes and returns an NSData containing arbitrary authentication
    // information. In effect this is a "signature" for the components array.

- (BOOL)authenticateComponents:(NSArray *)components withData:(NSData *)signature;
    // Verifies the authentication information in the NSData is valid and 
    // matches the message components.

@end


int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (argc < 2) {
        fprintf(stderr, "usage: %s server            // to run as server\n", argv[0]);
        fprintf(stderr, "usage: %s client            // to run as client\n", argv[0]);
        fprintf(stderr, "usage: One of the two arguments must be specified.\n");
        exit(1);
    }
    
    if (0 == strcmp(argv[1], "server")) {
        // Create a generic NSConnection to use to vend an object over DO.
        NSConnection *conn = [[NSConnection alloc] init];
        
        // Create a generic object to vend over DO; usually this is an object
        // that actually has something interesting to do as a "server".
        NSObject *object = [[NSObject alloc] init];
        
        // Create an Authenticator object to authenticate messages that come
        // in to the server.  The client and server need to use the same
        // authentication logic, but would not need to use the same class.
        Authenticator *authenticator = [[Authenticator alloc] init];
        
        // Configure the connection
        [conn setDelegate:authenticator];
        [conn setRootObject:object];

        // Set the name of the root object
        if (![conn registerName:CONNECTION_NAME]) {
            fprintf(stderr, "%s server: could not register server.  Is one already running?\n", argv[0]);
            exit(1);
        }
        fprintf(stderr, "%s server: started\n", argv[0]);
        
        // Have the run loop run forever, servicing incoming messages
        [[NSRunLoop currentRunLoop] run];
        
        // Cleanup objects; not really necessary in this case
        [authenticator release];
        [object release];
        [conn release];

    } else if (0 == strcmp(argv[1], "client")) {
        // Create an Authenticator object to authenticate messages going
        // to the server.  The client and server need to use the same
        // authentication logic, but would not need to use the same class.
        Authenticator *authenticator = [[Authenticator alloc] init];
        NSDistantObject *proxy;

        // Lookup the server connection
        NSConnection *conn = [NSConnection connectionWithRegisteredName:CONNECTION_NAME host:nil];
        
        if (!conn) {
            fprintf(stderr, "%s server: could not find server.  You need to start one on this machine first.\n", argv[0]);
            exit(1);
        }

        // Set the authenticator as the NSConnection delegate; all 
        // further messages, including the first one to lookup the root 
        // proxy, will go through the authenticator.
        [conn setDelegate:authenticator];

        proxy = [conn rootProxy];

        if (!proxy) {
            fprintf(stderr, "%s server: could not get proxy.  This should not happen.\n", argv[0]);
            exit(1);
        }

        // Since this is an example, we don't really care what the "served" 
        // object really does, just that we can message it.  Since it is just
        // an NSObject, send it some NSObject messages.  If these aren't
        // authenticated successfully, an NSFailedAuthenticationException
        // exception is raised.
    
        NSLog(@"description: %@", [proxy description]);
        NSLog(@"isKindOfClass NSObject? %@", [proxy isKindOfClass:[NSObject self]] ? @"YES" : @"NO");
            
        NSLog(@"Done. Messages sent successfully.");
        
        [authenticator release];
    } else {
        fprintf(stderr, "Unknown argument '%s'.  Must be 'client' or 'server'.\n", argv[1]);
        exit(1);
    }

    [pool release];
    return 0;
}


@implementation Authenticator

- (BOOL)connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn {
    // A non-authentication related delegate method.  Make sure all
    // child (per-client) connections get the same delegate.
    [conn setDelegate:[ancestor delegate]];
    return YES;
}

- (NSData *)authenticationDataForComponents:(NSArray *)components {
    unsigned int idx1, idx2;
    unsigned char checksum = 0;
    unsigned int count = [components count];
    
    // Compute authentication data for the components in the
    // given array.  There are two types of components, NSPorts
    // and NSDatas.  You should ignore a component of a type
    // which you don't understand.
    
    // Here, we compute a trivial 1 byte checksum over all the
    // bytes in the NSData objects in the array.
    for (idx1 = 0; idx1 < count; idx1++) {
        id item = [components objectAtIndex:idx1];
        if ([item isKindOfClass:[NSData class]]) {
            const unsigned char *bytes = [item bytes];
            unsigned int length = [item length];
            for (idx2 = 0; idx2 < length; idx2++) {
                checksum ^= bytes[idx2];
            }
        }
    }

    // Put the checksum byte in an NSData and return it.  This is
    // the authentication data for the message components.
    return [NSData dataWithBytes:&checksum length:1];
}

- (BOOL)authenticateComponents:(NSArray *)components withData:(NSData *)signature {
    // Verify the authentication data against the components.  A good
    // authenticator would have a way of verifying the signature without
    // recomputing it.  We don't, in this example, so just recompute.
    NSData *recomputedSignature = [self authenticationDataForComponents:components];

    // If the two NSDatas are not equal, authentication failure!
    if (![recomputedSignature isEqual:signature]) {
        NSLog(@"received signature %@ doesn't match computed signature %@", signature, recomputedSignature);
        return NO;
    }
    return YES;
}

@end
