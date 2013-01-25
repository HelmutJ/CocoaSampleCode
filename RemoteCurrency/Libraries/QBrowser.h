/*
    File:       QBrowser.h

    Contains:   Manages a Bonjour browse operation.

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

// QBrowser is a general purpose class for browsing Bonjour services.
// 
// The class is run loop based and must be called from a single thread. 
// Specifically, the -start and -stop methods add and remove run loop sources 
// to the current thread's run loop, and it's that thread that calls the 
// delegate callbacks.

@protocol QBrowserDelegate;

@interface QBrowser : NSObject

- (id)initWithDomain:(NSString *)domain type:(NSString *)type;
    // type must not be nil
    // domain of nil implies domain of @"" implies browse in default domains

// properties set by the init method

@property (nonatomic, copy,   readonly ) NSString * domain;
@property (nonatomic, copy,   readonly ) NSString * type;

// properties that can be set any time

@property (nonatomic, assign, readwrite) id<QBrowserDelegate> delegate;

// properties that are set as the browser executes

@property (nonatomic, copy,   readonly ) NSSet *    services;       // observable, of NSNetService
@property (nonatomic, assign, readonly ) BOOL       isStarted;      // observable

// run loop modes

// IMPORTANT: You can't add or remove run loop modes while the browser is running.

- (void)addRunLoopMode:(NSString *)modeToAdd;
- (void)removeRunLoopMode:(NSString *)modeToRemove;

@property (nonatomic, copy,   readonly ) NSSet *    runLoopModes;   // contains NSDefaultRunLoopMode by default

// actions

// It is reasonable to start and stop the same browser object multiple times.

- (void)start;
    // Starts the browser.  It's not legal to call this if the browser is started.

- (void)stop;
    // Does nothing if the brower is already stopped.  This does not call 
    // -browser:didStopWithError:.

@end

@protocol QBrowserDelegate <NSObject>

@optional

- (void)browser:(QBrowser *)browser didStopWithError:(NSError *)error;
    // Called when some underlying network failure has caused the browser to stop 
    // spontaneously.

@end
