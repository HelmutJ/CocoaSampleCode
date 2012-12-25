/*
    File:       QCFHostResolver.h

    Contains:   A Cocoa-style wrapper around CFHost.

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

/*
    You can use the object to map from a DNS name to a set of addresses or from a 
    address to a set of DNS names.  To do this:
    
    1. create the QCFHostResolver object with the info you have
    
    2. set a delegate
    
    3. call -start
    
    4. wait for -hostResolverDidFinish: to be called
    
    5. extract the information you need from the resolvedXxx properties
*/

@protocol QCFHostResolverDelegate;

@interface QCFHostResolver : NSObject

- (id)initWithName:(NSString *)name;
    // Initialise the object for name-to-address translation.
    
- (id)initWithAddress:(NSData *)address;
    // Initialise the object for address-to-name translation based on a (struct sockaddr) 
    // embedded in an NSData object.

- (id)initWithAddressString:(NSString *)addressString;
    // Initialise the object for address-to-name translation based on an address string.

// properties set up by the various -init routines

@property (nonatomic, copy,   readonly ) NSString *     name;
@property (nonatomic, copy,   readonly ) NSData *       address;
@property (nonatomic, copy,   readonly ) NSString *     addressString;

// properties you can set at any time

@property (nonatomic, weak,   readwrite) id<QCFHostResolverDelegate> delegate;

- (void)start;
    // Starts the resolution process.
    // 
    // It's not safe to call this is if the resolve is running.

- (void)cancel;
    // Cancels a resolve.  It's safe to call this redundantly.

// properties that are set when resolution completes

@property (nonatomic, copy,   readonly ) NSError *      error;
@property (nonatomic, copy,   readonly ) NSArray *      resolvedAddresses;          // of NSData, each containing a (struct sockaddr)
@property (nonatomic, copy,   readonly ) NSArray *      resolvedAddressStrings;     // of NSString
@property (nonatomic, copy,   readonly ) NSArray *      resolvedNames;              // of NSString

@end

@protocol QCFHostResolverDelegate <NSObject>

@optional

- (void)hostResolverDidFinish:(QCFHostResolver *)resolver;
    // Called when resolution completes succesfully.  Either the resolvedAddress[es|Strings] 
    // or the resolvedNames properties will contain meaningful results depending on whether 
    // the object was initialised for name-to-address or address-to-name translation.
    
- (void)hostResolver:(QCFHostResolver *)resolver didFailWithError:(NSError *)error;
    // Called when resolution fails.  The error parameter reflects the value in the error 
    // property

@end
