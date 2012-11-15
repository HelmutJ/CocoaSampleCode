/*
    File:       QRunLoopOperation.m

    Contains:   An abstract subclass of NSOperation for async run loop based operations.

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

#import "QRunLoopOperation.h"

/*
    Theory of Operation
    -------------------
    Some critical points:
    
     1. By the time we're running on the run loop thread, we know that all further state 
        transitions happen on the run loop thread.  That's because there are only three 
        states (inited, executing, and finished) and run loop thread code can only run 
        in the last two states and the transition from executing to finished is 
        always done on the run loop thread.

     2. -start can only be called once.  So run loop thread code doesn't have to worry 
        about racing with -start because, by the time the run loop thread code runs, 
        -start has already been called.
        
     3. Likewise, because -start can only be called once, it doesn't have to worry about 
        racing with invocations of -start.
        
     3. -cancel can be called multiple times from any thread.  Run loop thread code 
        must take a lot of care with do the right thing with cancellation.  Also, -cancel 
        and -start can race.
    
    Some state sequences:
    
     1. no execute (testNoExecute)
    
        [-init]
        [-dealloc]

        This is the case where you create the operation and never run it.  That's just fine by us.
        
        There are no formal sequence points here because neither -init nor -dealloc have logging (-init 
        because you can't tell whether logging is enabled at that time, and -dealloc because, once the 
        object is called, there's no way to collect the log).

     2. no execute, cancel (testNoExecute)
     
        [-init]
        >cancel
        -cancel.winner
        <cancel
        [-dealloc]

        This is the case where you create the operation, cancel it, but never run it.  We specifically 
        want to allow this to make it easier to write clean up code.

     3. cancel before start (testCancelBeforeStart)
     
        [-init]
        >cancel
        -cancel.winner
        <cancel
        >start
        -setState.executing
        <start
        >startOnRunLoopThread
        -startOnRunLoopThread.cancelled
        >finishWithError
        -finishWithError.error
        -setState.finished
        <finishWithError
        <startOnRunLoopThread
        [-dealloc]
        
        I originally thought that this could never happen, but it seems that NSOperationQueue will 
        quite happily start a cancelled operation.
        
        Note that the following sequence /can't/ happen:
        
        [-init]
        >cancel
        -cancel.winner
        <cancel
        >start
        -setState.executing
        <start
        [-dealloc]

        because a) the operation queue holds a reference to the operation until it's finished, and 
        b) the -start uses -performSelector:onThread: to queue a call to -startOnRunLoopThread, 
        and that retains the object.

     4. cancel during start, before schedule (testCancelDuringStart)

        [-init]
        >start
        -setState.executing
        -start.cancelBefore
        >cancel
        -cancel.winner
        -cancel.schedule
        <cancel
        <start
        >cancelOnRunLoopThread
        -cancelOnRunLoopThread.cancel
        >finishWithError
        -finishWithError.error
        -setState.finished
        <finishWithError
        <cancelOnRunLoopThread
        >startOnRunLoopThread
        -startOnRunLoopThread.bounce
        <startOnRunLoopThread
        [-dealloc]
     
        This is what happens if -cancel gets called while -start is running but before -start 
        has scheduled -startOnRunLoopThread to execute.  -cancelOnRunLoopThread is queued 
        before -startOnRunLoopThread, so -startOnRunLoopThread runs second, notices the cancellation, 
        and then bounces.

     5. cancel during start, after schedule (testCancelDuringStart)

        [-init]
        >start
        -setState.executing
        -start.cancelAfter
        >cancel
        -cancel.winner
        -cancel.schedule
        <cancel
        <start
        >startOnRunLoopThread
        -startOnRunLoopThread.cancelled
        >finishWithError
        -finishWithError.error
        -setState.finished
        <finishWithError
        <startOnRunLoopThread
        >cancelOnRunLoopThread
        -cancelOnRunLoopThread.bounce
        <cancelOnRunLoopThread
        [-dealloc]
     
        This is what happens if -cancel gets called while -start is running but before -start 
        has scheduled -startOnRunLoopThread to execute.  -cancelOnRunLoopThread is queued 
        after -startOnRunLoopThread, so -startOnRunLoopThread runs first and does the real work 
        and -cancelOnRunLoopThread runs second and bounces.
        
     6. Basics (testBasics)

        [-init]
        >start
        -setState.executing
        <start
        >startOnRunLoopThread
        -startOnRunLoopThread.start
        <startOnRunLoopThread
        >finishWithError
        -finishWithError.noError
        -setState.finished
        <finishWithError
        [-dealloc]
        
        This is the standard run-to-completion case.

     7. Basics with cancel (testBasicsCancel)

        [-init]
        >start
        -setState.executing
        <start
        >startOnRunLoopThread
        -startOnRunLoopThread.start
        <startOnRunLoopThread
        >cancel
        -cancel.winner
        -cancel.schedule
        <cancel
        >cancelOnRunLoopThread
        -cancelOnRunLoopThread.cancel
        >finishWithError
        -finishWithError.error
        -setState.finished
        <finishWithError
        <cancelOnRunLoopThread
        [-dealloc]

        This is the standard cancel-while-executing case.  -cancelOnRunLoopThread wins the race 
        with finish, and it detects that the operation is executing and actually cancels. 

     8. Basics with late cancel (testBasicsCancelLate)
     
        [-init]
        >start,
        -setState.executing,
        <start,
        >startOnRunLoopThread,
        -startOnRunLoopThread.start,
        <startOnRunLoopThread,
        >finishWithError,
        -finishWithError.noError,
        -setState.finished,
        <finishWithError,
        >cancel,
        -cancel.winner,
        <cancel
        [-dealloc]
        
        The cancellation comes in after the operation has finished.  -cancelOnRunLoopThread is 
        not scheduled because the operation is already in the finished state.  Also note that 
        we call [super cancel] in this case, but that has no effect: -[NSOperation cancel] looks 
        at -isFinished and bounces in that case.

     9. Much delayed cancel (testDelayedCancel)

        [-init]
        >start
        -setState.executing
        <start
        >startOnRunLoopThread
        -startOnRunLoopThread.start
        <startOnRunLoopThread
        >cancel
        -cancel.winner
        -cancel.delay
        >finishWithError
        -finishWithError.noError
        -setState.finished
        <finishWithError
        -cancel.schedule
        <cancel
        >cancelOnRunLoopThread
        -cancelOnRunLoopThread.bounce
        <cancelOnRunLoopThread
        [-dealloc]
        
        This is very similar to case 5 but the thread doing the cancel has been artifically 
        delayed to ensure that the finish happens between the start of -cancel and its end.

    Markup:
        [x]  denotes an emplied sequence point.
        >x   denotes the entry to -[QRunLoopOperation x].
        <x   denotes the return of -[QRunLoopOperation x].
        -x.y denotes a significant point within -[QRunLoopOperation x].
        -x   denotes an otherwise unannotated invocation of -[QRunLoopOperation x].
        (x)  means that the case is tested by the unit test method -[UnitTests x].
*/

@interface QRunLoopOperation ()

// read/write versions of public properties

@property (assign, readwrite) QRunLoopOperationState    state;
@property (copy,   readwrite) NSError *                 error;          

@end

// debugging infrastructure

#if defined(NDEBUG)

#define DebugLogEvent(str) do { } while (0)

#else

@interface QRunLoopOperation (UnitTestSupportPrivate)

- (void)debugLogEvent:(NSString *)event;

@end

#define DebugLogEvent(str) do { [self debugLogEvent:str]; } while (0)

#endif

@implementation QRunLoopOperation

@synthesize debugName     = debugName_;

@synthesize runLoopThread = runLoopThread_;
@synthesize runLoopModes  = runLoopModes_;

@synthesize error         = error_;

- (id)init
{
    self = [super init];
    if (self != nil) {
        assert(self->state_ == kQRunLoopOperationStateInited);
    }
    return self;
}

- (void)dealloc
{
    assert(self->state_ != kQRunLoopOperationStateExecuting);
    [self->debugName_ release];
    [self->runLoopModes_ release];
    [self->runLoopThread_ release];
    [self->error_ release];
    #if ! defined(NDEBUG)
        [self->debugEventLog_ release];
    #endif
    [super dealloc];
}

#pragma mark * Non-synthesized Properties

- (NSThread *)actualRunLoopThread
    // Returns the effective run loop thread, that is, the one set by the user 
    // or, if that's not set, the main thread.
{
    NSThread *  result;
    
    result = self.runLoopThread;
    if (result == nil) {
        result = [NSThread mainThread];
    }
    return result;
}

- (BOOL)isActualRunLoopThread
    // Returns YES if the current thread is the actual run loop thread.
{
    return [[NSThread currentThread] isEqual:self.actualRunLoopThread];
}

- (NSSet *)actualRunLoopModes
{
    NSSet * result;
    
    result = self.runLoopModes;
    if ( (result == nil) || ([result count] == 0) ) {
        result = [NSSet setWithObject:NSDefaultRunLoopMode];
    }
    return result;
}

#pragma mark * Core state transitions

- (QRunLoopOperationState)state
{
    return self->state_;
}

- (void)setState:(QRunLoopOperationState)newState
    // Change the state of the operation, sending the appropriate KVO notifications.
{
    QRunLoopOperationState  oldState;

    // The following check is really important.  The state can only go forward, and there 
    // should be no redundant changes to the state (that is, newState must never be 
    // equal to self->state_).
    
    assert(newState > self->state_);

    // As a corollary to the above, you can't change the state to inited because it starts 
    // out there.
    
    assert(newState != kQRunLoopOperationStateInited);

    // The -start method is the one that transitions from inited to executing, 
    // and it can run on any thread.  However, there's no race possible because 
    // only one thread is allowed to call -start.  The transition from executing 
    // to finished must be done by the run loop thread.
    //
    // There's a subtle requirement here, namely that -start must change the state 
    // before scheduling -startOnRunLoopThread.  Without that, the inited to executing 
    // and executing to finished changes race.

    assert((newState == kQRunLoopOperationStateExecuting) || self.isActualRunLoopThread);
    
    // Change the state and send the right KVO notifications.
    
    // inited    + executing -> isExecuting
    // inited    + finished  -> isFinished
    // executing + finished  -> isExecuting + isFinished

    oldState = self->state_;
    if ( (newState == kQRunLoopOperationStateExecuting) || (oldState == kQRunLoopOperationStateExecuting) ) {
        [self willChangeValueForKey:@"isExecuting"];
    }
    if (newState == kQRunLoopOperationStateFinished) {
        [self willChangeValueForKey:@"isFinished"];
    }
    self->state_ = newState;
    if (newState == kQRunLoopOperationStateFinished) {
        [self didChangeValueForKey:@"isFinished"];
    }
    if ( (newState == kQRunLoopOperationStateExecuting) || (oldState == kQRunLoopOperationStateExecuting) ) {
        [self didChangeValueForKey:@"isExecuting"];
    }
    
    // Log the change.
    
    #if ! defined(NDEBUG)
        switch (newState) {
            default:
                assert(NO);
                // fall through
            case kQRunLoopOperationStateInited: {
                DebugLogEvent(@"-setState.inited");
            } break;
            case kQRunLoopOperationStateExecuting: {
                DebugLogEvent(@"-setState.executing");
            } break;
            case kQRunLoopOperationStateFinished: {
                DebugLogEvent(@"-setState.finished");
            } break;
        }
    #endif
}

- (void)startOnRunLoopThread
    // Starts the operation.  The actual -start method is very simple, 
    // deferring all of the work to be done on the run loop thread by this 
    // method.
{
    DebugLogEvent(@">startOnRunLoopThread");

    assert(self.isActualRunLoopThread);
    assert(self.state != kQRunLoopOperationStateInited);

    // State might be kQRunLoopOperationStateFinished at this point if someone managed 
    // to cancel us from the actual run loop thread between -start and -startOnRunLoopThread.  
    // In that case we've already finished, so we just do nothing.
    
    if (self.state == kQRunLoopOperationStateExecuting) {
        if ([self isCancelled]) {
            DebugLogEvent(@"-startOnRunLoopThread.cancelled");
            
            // We were cancelled before we even got running.  Flip the the finished 
            // state immediately.
            
            [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
        } else {
            DebugLogEvent(@"-startOnRunLoopThread.start");
            [self operationDidStart];
        }
    } else {
        DebugLogEvent(@"-startOnRunLoopThread.bounce");
    }

    DebugLogEvent(@"<startOnRunLoopThread");
}

- (void)cancelOnRunLoopThread
    // Cancels the operation.
{
    DebugLogEvent(@">cancelOnRunLoopThread");

    assert(self.isActualRunLoopThread);

    // We know that a) state was kQRunLoopOperationStateExecuting when we were 
    // scheduled (that's enforced by -cancel), and b) the state can't go 
    // backwards (that's enforced by -setState), so we know the state must 
    // either be kQRunLoopOperationStateExecuting or kQRunLoopOperationStateFinished. 
    // We also know that the transition from executing to finished always 
    // happens on the run loop thread.  Thus, we don't need to lock here.  
    // We can look at state and, if we're executing, trigger a cancellation.
    
    if (self.state == kQRunLoopOperationStateExecuting) {
        DebugLogEvent(@"-cancelOnRunLoopThread.cancel");
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    } else {
        DebugLogEvent(@"-cancelOnRunLoopThread.bounce");
    }
    DebugLogEvent(@"<cancelOnRunLoopThread");
}

- (void)finishWithError:(NSError *)error
    // See comment in header.
{
    DebugLogEvent(@">finishWithError");

    assert(self.isActualRunLoopThread);
    // error may be nil

    // Latch the error.  This code is very simple once you remove all the debug logging (-:
    if (self.error == nil) {
        if (error != nil) {
            DebugLogEvent(@"-finishWithError.error");
        } else {
            DebugLogEvent(@"-finishWithError.noError");
        }
        self.error = error;
    } else {
        if (error != nil) {
            DebugLogEvent(@"-finishWithError.bounceError");
        } else {
            DebugLogEvent(@"-finishWithError.bounceNoError");
        }
    }
    
    // Call -operationWillFinish to let subclasses know about the change.
    
    [self operationWillFinish];

    // Make the change.
    
    self.state = kQRunLoopOperationStateFinished;

    DebugLogEvent(@"<finishWithError");
}

#pragma mark * Subclass override points

- (void)operationDidStart
{
    assert(self.isActualRunLoopThread);
}

- (void)operationWillFinish
{
    assert(self.isActualRunLoopThread);
}

#pragma mark * Overrides

- (BOOL)isConcurrent
{
    // any thread
    return YES;
}

- (BOOL)isExecuting
{
    // any thread
    return self->state_ == kQRunLoopOperationStateExecuting;
}
 
- (BOOL)isFinished
{
    // any thread
    return self->state_ == kQRunLoopOperationStateFinished;
}

- (void)start
{
    DebugLogEvent(@">start");

    // any thread

    assert(self.state == kQRunLoopOperationStateInited);
    
    // We have to change the state here, otherwise isExecuting won't necessarily return 
    // true by the time we return from -start.  Also, we don't test for cancellation 
    // here because that would a) result in us sending isFinished notifications on a 
    // thread that isn't our run loop thread, and b) confuse the core cancellation code, 
    // which expects to run on our run loop thread.  Finally, we don't have to worry 
    // about races with other threads calling -start.  Only one thread is allowed to 
    // start us at a time.
    
    self.state = kQRunLoopOperationStateExecuting;
    #if ! defined(NDEBUG)
        if (self.debugCancelSelfBeforeSchedulingStart) {
            DebugLogEvent(@"-start.cancelBefore");
            [self cancel];
        }
    #endif
    [self performSelector:@selector(startOnRunLoopThread) onThread:self.actualRunLoopThread withObject:nil waitUntilDone:NO modes:[self.actualRunLoopModes allObjects]];
    #if ! defined(NDEBUG)
        if (self.debugCancelSelfAfterSchedulingStart) {
            DebugLogEvent(@"-start.cancelAfter");
            [self cancel];
        }
    #endif

    DebugLogEvent(@"<start");
}

- (void)cancel
{
    BOOL    runCancelOnRunLoopThread;
    BOOL    oldValue;

    DebugLogEvent(@">cancel");

    // any thread

    // We synchronise here to ensure that only one thread calls [super cancel]. 
    
    @synchronized (self) {
        oldValue = [self isCancelled];

        if ( ! oldValue ) {
            DebugLogEvent(@"-cancel.winner");
        }
        
        // Call our super class so that isCancelled starts returning true immediately.
        
        [super cancel];
        
        // If we were the one to set isCancelled (that is, we won the race with regards 
        // other threads calling -cancel) and we're actually running (that is, we lost 
        // the race with other threads calling -start and the run loop thread finishing), 
        // we schedule to run on the run loop thread.
        //
        // The concurrency guarantee here is kinda hazy.  Specifically, state can change 
        // immediately after we read it (because of another thread calling -start or 
        // the run loop thread finishing).  There are two important cases to consider here: 
        //
        // o -start taking us from inited to executing -- We might want to schedule 
        //   -cancelOnRunLoopThread in this case, but we miss our chance.  That's OK though: 
        //   after changing the state -start will schedule -startOnRunLoopThread which will 
        //   check for cancellation.
        //
        // o run loop thread taking us from executing to finished -- In this case we might 
        //   schedule -cancelOnRunLoopThread redundantly.  That's OK though because 
        //   -cancelOnRunLoopThread will just bounce in that case.

        runCancelOnRunLoopThread = ! oldValue && self.state == kQRunLoopOperationStateExecuting;
    }
    if (runCancelOnRunLoopThread) {
        #if ! defined(NDEBUG)
            if (self.debugSecondaryThreadCancelDelay > 0.0) {
                if ( ! self.isActualRunLoopThread ) {
                    DebugLogEvent(@"-cancel.delay");
                    [NSThread sleepForTimeInterval:self.debugSecondaryThreadCancelDelay];
                }
            }
        #endif
        DebugLogEvent(@"-cancel.schedule");
        [self performSelector:@selector(cancelOnRunLoopThread) onThread:self.actualRunLoopThread withObject:nil waitUntilDone:NO modes:[self.actualRunLoopModes allObjects]];
    }
    DebugLogEvent(@"<cancel");
}

@end

#if ! defined(NDEBUG)

@implementation QRunLoopOperation (UnitTestSupport)

// The compiler won't let me @synthesize these accessors, so we write them out 
// by hand.  Fortunately they are single item "assign" properties, so atomicity is 
// not a problem.

// If debugCancelSelfBeforeSchedulingStart is set, -start calls -cancel 
// before scheduling -startOnRunLoopThread.

- (BOOL)debugCancelSelfBeforeSchedulingStart
{
    return self->debugCancelSelfBeforeSchedulingStart_;
}

- (void)setDebugCancelSelfBeforeSchedulingStart:(BOOL)newValue
{
    self->debugCancelSelfBeforeSchedulingStart_ = newValue;
}

// If debugCancelSelfAfterSchedulingStart is set, -start calls -cancel 
// after scheduling -startOnRunLoopThread.

- (BOOL)debugCancelSelfAfterSchedulingStart
{
    return self->debugCancelSelfAfterSchedulingStart_;
}

- (void)setDebugCancelSelfAfterSchedulingStart:(BOOL)newValue
{
    self->debugCancelSelfAfterSchedulingStart_ = newValue;
}

// debugSecondaryThreadCancelDelay controls a delay in -cancel, just 
// before is schedules -cancelOnRunLoopThread.

- (NSTimeInterval)debugSecondaryThreadCancelDelay
{
    return self->debugSecondaryThreadCancelDelay_;
}

- (void)setDebugSecondaryThreadCancelDelay:(NSTimeInterval)newValue
{
    self->debugSecondaryThreadCancelDelay_ = newValue;
}

- (NSArray *)debugEventLog
    // Returns the current event log.
{
    NSArray *   result;
    
    // Synchronisation is necessary to avoid accessing the array while 
    // it's being mutated by another thread.
    
    @synchronized (self) {
        // debugEventLog_ may be nil, and that's OK.
        result = [[self->debugEventLog_ copy] autorelease];
    }
    return result;
}

- (void)debugEnableEventLog
    // Enables the event log on this object.
{
    // Synchronisation is necessary to because it's reasonable for multiple 
    // threads to call this routine at once.

    @synchronized (self) {
        if (self->debugEventLog_ == nil) {
            self->debugEventLog_ = [[NSMutableArray alloc] init];
        }
    }
}

- (void)debugLogEvent:(NSString *)event
    // Called by the implementation to log events.
{
    assert(event != nil);
    
    // Synchronisation is necessary because multiple threads might be adding 
    // events concurrently.
    
    @synchronized (self) {
        if (self->debugEventLog_ != nil) {
            [self->debugEventLog_ addObject:event];
        }
    }
}

@end

#endif
