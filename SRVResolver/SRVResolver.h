/*
    File:       SRVResolver.h

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

#import <Foundation/Foundation.h>

#include <dns_sd.h>

@protocol SRVResolverDelegate;

@interface SRVResolver : NSObject

- (id)initWithSRVName:(NSString *)srvName;

// properties set up by the init method

@property (nonatomic, copy,   readonly ) NSString *                 srvName;

// properties you can change any time

@property (nonatomic, weak,   readwrite) id<SRVResolverDelegate>    delegate;

// properties that change as the result of running the query

@property (nonatomic, assign, readonly, getter=isFinished) BOOL     finished;   // observable
@property (nonatomic, copy,   readonly ) NSError *                  error;      // observable
@property (nonatomic, copy,   readonly ) NSArray *                  results;    // of NSDictionary, observable

// Note that there is no default timeout here.  See "Read Me About SRVResolver" 
// for a discussion as to why not.

- (void)start;
- (void)stop;

@end

// Keys for the dictionaries in the results array:

extern NSString * kSRVResolverPriority;     // NSNumber, host byte order
extern NSString * kSRVResolverWeight;       // NSNumber, host byte order
extern NSString * kSRVResolverPort;         // NSNumber, host byte order
extern NSString * kSRVResolverTarget;       // NSString

extern NSString * kSRVResolverErrorDomain;

@protocol SRVResolverDelegate <NSObject>

@optional

// These delegates methods are called from the default run loop mode on the run loop of the 
// thread that called -start.

- (void)srvResolver:(SRVResolver *)resolver didReceiveResult:(NSDictionary *)result;
    // Called when we've successfully receive an answer.  The result parameter is a copy 
    // of the dictionary that we just added to the results array.  This callback can be 
    // called multiple times if there are multiple results.  You learn that the last 
    // result was delivered by way of the -srvResolver:didStopWithError: callback.
    
- (void)srvResolver:(SRVResolver *)resolver didStopWithError:(NSError *)error;
    // Called when the query stops (except when you stop it yourself by calling -stop), 
    // either because it's received all the results (error is nil) or there's been an 
    // error (error is not nil).

@end
