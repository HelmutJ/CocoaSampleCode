/*
    File:       QWatchedOperationQueue.m

    Contains:   An NSOperationQueue subclass that calls you back when operations finish.

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

#import "QWatchedOperationQueue.h"

@interface QWatchedOperationQueue ()
@property (assign, readwrite) id            target;
@end

@implementation QWatchedOperationQueue

@synthesize target       = target_;
@synthesize targetThread = targetThread_;

- (id)initWithTarget:(id)target
    // See comment in header.
{
    assert(target != nil);
    self = [super init];
    if (self != nil) {
        self->target_ = target;
        self->targetThread_ = [[NSThread currentThread] retain];
        self->operationToAction_ = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
        assert(self->operationToAction_ != NULL);
    }
    return self;
}

- (void)dealloc
{
    // can be called on any thread
    if (self->operationToAction_ != NULL) {
        assert(CFDictionaryGetCount(self->operationToAction_) == 0);
        CFRelease(self->operationToAction_);
    }
    [self->targetThread_ release];
    [super dealloc];
}

- (void)addOperation:(NSOperation *)op finishedAction:(SEL)action
    // See comment in header.
{
    // can be called on any thread
    assert(op != nil);
    assert(action != nil);
    
    // Add the operation-to-action map entry.  We do this synchronised 
    // because we can be running on any thread.
    
    @synchronized (self) {
        assert( ! CFDictionaryContainsKey(self->operationToAction_, (const void *) op) );
        CFDictionarySetValue(self->operationToAction_, (const void *) op, (const void *) action);
    }
    
    // Retain ourselves so that we can't go away while the operation is running, 
    // and then observe the finished property of the operation.
    
    [self retain];
    [op addObserver:self forKeyPath:@"isFinished" options:0 context:&self->target_];
    
    // Call into the real NSOperationQueue.
    
    [self addOperation:op];
}

- (void)invalidate
    // See comment in header.
{
    assert([NSThread currentThread] == self.targetThread);
    
    // Because self.target is only referenced by this and -didFinishOperation:, 
    // and both of these can only be called on the target thread, this doesn't 
    // require synchronisation and is guaranteed to be effective against any 
    // 'in flight' operations.
    
    self.target = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // Called when the finished property of the operation changes.  We do very 
    // little here, but rather push the work off to the target thread.
{
    // can be called on any thread
    if (context == &self->target_) {
        assert([keyPath isEqual:@"isFinished"]);
        @synchronized (self) {
            assert( CFDictionaryContainsKey(self->operationToAction_, (const void *) object) );
        }
        assert([object isKindOfClass:[NSOperation class]]);
        
        // We ignore the change if isFinished is not set.  Various operations 
        // end up triggering KVO notification on isFinished when they're not 
        // actually finished so, just to be sure, we perform a definitive check 
        // here.
        
        if ( [((NSOperation *) object) isFinished] ) {
            [self performSelector:@selector(didFinishOperation:) onThread:self.targetThread withObject:object waitUntilDone:NO];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)didFinishOperation:(NSOperation *)op
    // Called on the target thread when an operation finishes. 
{
    SEL     action;
    
    assert([NSThread currentThread] == self.targetThread);
    assert([op isKindOfClass:[NSOperation class]]);
    assert([op isFinished]);
    
    // Pull the action out of the operation-to-action map, remembering the 
    // action that was required.
    
    @synchronized (self) {
        assert( CFDictionaryContainsKey(self->operationToAction_, (const void *) op) );
        action = (SEL) CFDictionaryGetValue(self->operationToAction_, (const void *) op);
        CFDictionaryRemoveValue(self->operationToAction_, (const void *) op);
        assert(action != nil);
    }
    
    // Remove ourselves as an observer for this operation. We can now 
    // safely release the retain on ourselves that we took in 
    // -addOperation:finishedAction:.
    
    [op removeObserver:self forKeyPath:@"isFinished"];
    [self autorelease];
    
    // If we haven't been invalidated, and the operation hasn't been 
    // cancelled, call the action method.
    
    // IMPORTANT: You have to be very careful here.  It's quite possible that the action 
    // we sent to target can call us recursively, perhaps to add more operations but, 
    // more interestingly, to call -invalidate.  This will, in turn, set target to nil. 
    // So it's important we not reference target after doing the -performSelector:withObject:.
    //
    // If you crash inside the -performSelector:withObject: code but target is nil, it's most 
    // likely the completion of this operation has caused the client to shut down, and 
    // the client is crashing, not because of problems with this class, but because it's failing 
    // to ensure that it's still alive during the shutdown process.
    
    if ( (self.target != nil) && ! [op isCancelled] ) {
        [self.target performSelector:action withObject:op];
    }
}

@end
