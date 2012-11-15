/*
    File:       UnitTests.m

    Contains:   Unit test for the QRunLoopOperation class.

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

#if defined(NDEBUG)
    #error The UnitTest target will only work in the Debug configuration.
#endif

// ... because it relies on properties of QRunLoopOperation that are not available 
// in the Release configuration.

#import "UnitTests.h"

#include "TimerOperation.h"
#include "DelayOperation.h"

@interface UnitTests ()
@property (retain, readwrite) NSOperationQueue *    queue;
@property (retain, readwrite) NSOperation *         op1;
@property (retain, readwrite) NSOperation *         op2;
@property (retain, readwrite) NSOperation *         op3;
@property (retain, readonly ) TimerOperation *      timerOp1;
@property (retain, readonly ) TimerOperation *      timerOp2;
@property (retain, readonly ) TimerOperation *      timerOp3;
@property (retain, readwrite) NSMutableArray *      operations;
@end

@implementation UnitTests

@synthesize queue = queue_;
@synthesize op1   = op1_;
@synthesize op2   = op2_;
@synthesize op3   = op3_;
@synthesize operations = operations_;

- (TimerOperation *)timerOp1
{
    assert([self.op1 isKindOfClass:[TimerOperation class]]);
    return (TimerOperation *) self.op1;
}

- (TimerOperation *)timerOp2
{
    assert([self.op2 isKindOfClass:[TimerOperation class]]);
    return (TimerOperation *) self.op2;
}

- (TimerOperation *)timerOp3
{
    assert([self.op3 isKindOfClass:[TimerOperation class]]);
    return (TimerOperation *) self.op3;
}

- (void)setUp
{
    [super setUp];
    
    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    [self.queue setMaxConcurrentOperationCount:1];
}

- (void)tearDown
{
    self.queue = nil;
    
    [super tearDown];
}

#pragma mark * No Execute

- (TimerOperation *)timerOperationWithDuration:(NSTimeInterval)duration name:(NSString *)name
{
    TimerOperation *    result;

    result = [[[TimerOperation alloc] initWithDuration:duration] autorelease];
    assert(result != nil);
    result.debugName = name;
    [result debugEnableEventLog];
    return result;
}

- (void)testNoExecute
{
    TimerOperation *    op;
    
    // tests state transition sequence 1
    
    op = [self timerOperationWithDuration:0.2 name:@"op"];
    assert(op != nil);
    
    STAssertEqualObjects([op.debugEventLog componentsJoinedByString:@"/"], @"", @"sequence error");

    // tests state transition sequence 2
    
    op = [self timerOperationWithDuration:0.2 name:@"op"];
    assert(op != nil);
    
    [op cancel];
    STAssertTrue([op isCancelled], @"Can should be immediate");
    
    STAssertEqualObjects([op.debugEventLog componentsJoinedByString:@"/"], @">cancel/-cancel.winner/<cancel", @"sequence error");
}

#pragma mark * Cancel before Start

- (void)testCancelBeforeStart
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self.op1 cancel];
    
    [self.queue addOperation:self.op1];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");         -- it may be executing at this point
    STAssertTrue( [self.op1 isCancelled], @"shouldn't start cancelled");
    // STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");          -- ditto
    
    [self performSelector:@selector(cancelBeforeStartAfterOp1Done) withObject:nil afterDelay:0.1];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)cancelBeforeStartAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">cancel/-cancel.winner/<cancel/>start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.cancelled/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<startOnRunLoopThread", @"sequence error");
    self.op1 = nil;
}

#pragma mark * Cancel during start

- (void)testCancelDuringStart
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.timerOp1.debugCancelSelfBeforeSchedulingStart = YES;
    self.timerOp2.debugCancelSelfAfterSchedulingStart = YES;
    
    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];

    [self performSelector:@selector(cancelDuringStartAllDone) withObject:nil afterDelay:0.1];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)cancelDuringStartAllDone
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/-start.cancelBefore/>cancel/-cancel.winner/-cancel.schedule/<cancel/<start/>cancelOnRunLoopThread/-cancelOnRunLoopThread.cancel/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<cancelOnRunLoopThread/>startOnRunLoopThread/-startOnRunLoopThread.bounce/<startOnRunLoopThread", @"sequence error");

    STAssertNotNil(self.op2, @"op2 shouldn't be already done");
    STAssertFalse([self.op2 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op2 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/-start.cancelAfter/>cancel/-cancel.winner/-cancel.schedule/<cancel/<start/>startOnRunLoopThread/-startOnRunLoopThread.cancelled/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<startOnRunLoopThread/>cancelOnRunLoopThread/-cancelOnRunLoopThread.bounce/<cancelOnRunLoopThread", @"sequence error");

    self.op1 = nil;
    self.op2 = nil;
}

#pragma mark * Basics

// Tests that stuff works at all.

- (void)testBasics
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self.queue addOperation:self.op1];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(basicsBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(basicsAfterOp1Done)  withObject:nil afterDelay:0.3];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)basicsBeforeOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertTrue( [self.op1 isExecuting], @"should be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't be finished");
}

- (void)basicsAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    self.op1 = nil;
}

#pragma mark * Basics with Cancel

// Tests that cancellation works at all.

- (void)testBasicsCancel
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self.queue addOperation:self.op1];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(basicsCancelBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(basicsCancelAfterOp1Done)  withObject:nil afterDelay:0.125];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.3];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)basicsCancelBeforeOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertTrue( [self.op1 isExecuting], @"should be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't be finished");
    [self.op1 cancel];
}

- (void)basicsCancelAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>cancel/-cancel.winner/-cancel.schedule/<cancel/>cancelOnRunLoopThread/-cancelOnRunLoopThread.cancel/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<cancelOnRunLoopThread", @"sequence error");
    self.op1 = nil;
}

#pragma mark * Basics with Late Cancellation

- (void)testBasicsCancelLate
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.1 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self.queue addOperation:self.op1];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(basicsCancelLateAfterOp1Done) withObject:nil afterDelay:0.11];
    [self performSelector:@selector(basicsCancelLateAllDone)      withObject:nil afterDelay:0.15];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)basicsCancelLateAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    [self.op1 cancel];
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
}

- (void)basicsCancelLateAllDone
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError/>cancel/-cancel.winner/<cancel", @"sequence error");
    self.op1 = nil;
}

#pragma mark * Basics with Cancel Early

// Tests that cancellation works at all.

- (void)testBasicsCancelEarly
{
    NSDate *    endDate;
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");

    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    [self.op1 cancel];
    
    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];

    [self.op2 cancel];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertTrue( [self.op1 isCancelled], @"should start cancelled");
    // STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");

    // STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertTrue([self.op2 isCancelled], @"should start cancelled");
    // STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(basicsCancelEarlyDone) withObject:nil afterDelay:0.025];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.3];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)basicsCancelEarlyDone
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");

    STAssertNotNil(self.op2, @"op1 shouldn't be already done");
    STAssertFalse([self.op2 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op2 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"should be finished");

    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">cancel/-cancel.winner/<cancel/>start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.cancelled/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<startOnRunLoopThread", @"sequence error");
    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">cancel/-cancel.winner/<cancel/>start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.cancelled/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<startOnRunLoopThread", @"sequence error");
    
    self.op1 = nil;
    self.op2 = nil;
}

#pragma mark * Turnover

// Tests that one operation will start the next operation.

- (void)testTurnover
{
    NSDate *    endDate;
        
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    self.op3 = [self timerOperationWithDuration:0.2 name:@"op3"];
    assert(self.op3 != nil);
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");

    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];
    [self.queue addOperation:self.op3];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(turnoverBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(turnoverAfterOp1Done)  withObject:nil afterDelay:0.3];
    [self performSelector:@selector(turnoverAfterOp2Done)  withObject:nil afterDelay:0.5];
    [self performSelector:@selector(turnoverAfterOp3Done)  withObject:nil afterDelay:0.7];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.8];
    while (self.op3 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)turnoverBeforeOp1Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertTrue( [self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"op1 shouldn't be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertTrue( [self.op2 isExecuting], @"op2 should be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverAfterOp2Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertTrue( [self.op3 isExecuting], @"op3 should be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverAfterOp3Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertTrue( [self.op3 isFinished],  @"op3 should be finished");

    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp3.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");

    self.op1 = nil;
    self.op2 = nil;
    self.op3 = nil;
}

#pragma mark * Turnover Thread First

// Tests main to thread to run loop to thread turn over.

- (void)testTurnoverThreadFirst
{
    NSDate *    endDate;
        
    self.op1 = [[[DelayOperation alloc] initWithDuration:0.2] autorelease];
    assert(self.op1 != nil);
    ((DelayOperation *) self.op1).debugName = @"op1";
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    self.op3 = [[[DelayOperation alloc] initWithDuration:0.2] autorelease];
    assert(self.op3 != nil);
    ((DelayOperation *) self.op3).debugName = @"op3";
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");

    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];
    [self.queue addOperation:self.op3];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(turnoverThreadFirstBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(turnoverThreadFirstAfterOp1Done)  withObject:nil afterDelay:0.3];
    [self performSelector:@selector(turnoverThreadFirstAfterOp2Done)  withObject:nil afterDelay:0.5];
    [self performSelector:@selector(turnoverThreadFirstAfterOp3Done)  withObject:nil afterDelay:0.7];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.8];
    while (self.op3 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)turnoverThreadFirstBeforeOp1Done
{
    // NSLog(@"turnoverThreadFirstBeforeOp1Done");
    
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertTrue( [self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"op1 shouldn't be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverThreadFirstAfterOp1Done
{
    // NSLog(@"turnoverThreadFirstAfterOp1Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertTrue( [self.op2 isExecuting], @"op2 should be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverThreadFirstAfterOp2Done
{
    // NSLog(@"turnoverThreadFirstAfterOp2Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertTrue( [self.op3 isExecuting], @"op3 should be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverThreadFirstAfterOp3Done
{
    // NSLog(@"turnoverThreadFirstAfterOp3Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertTrue( [self.op3 isFinished],  @"op3 should be finished");

    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    
    self.op1 = nil;
    self.op2 = nil;
    self.op3 = nil;
}

#pragma mark * Turnover Run Loop First

// Tests main to run loop to thread to run loop turn over.

- (void)testTurnoverRunLoopFirst
{
    NSDate *    endDate;
        
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [[[DelayOperation alloc] initWithDuration:0.2] autorelease];
    assert(self.op2 != nil);
    ((DelayOperation *) self.op2).debugName = @"op2";
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    self.op3 = [self timerOperationWithDuration:0.2 name:@"op3"];
    assert(self.op3 != nil);
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");

    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];
    [self.queue addOperation:self.op3];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(turnoverRunLoopFirstBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(turnoverRunLoopFirstAfterOp1Done)  withObject:nil afterDelay:0.3];
    [self performSelector:@selector(turnoverRunLoopFirstAfterOp2Done)  withObject:nil afterDelay:0.5];
    [self performSelector:@selector(turnoverRunLoopFirstAfterOp3Done)  withObject:nil afterDelay:0.7];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.8];
    while (self.op3 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)turnoverRunLoopFirstBeforeOp1Done
{
    // NSLog(@"turnoverRunLoopFirstBeforeOp1Done");
    
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertTrue( [self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"op1 shouldn't be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverRunLoopFirstAfterOp1Done
{
    // NSLog(@"turnoverRunLoopFirstAfterOp1Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertTrue( [self.op2 isExecuting], @"op2 should be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverRunLoopFirstAfterOp2Done
{
    // NSLog(@"turnoverRunLoopFirstAfterOp2Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertTrue( [self.op3 isExecuting], @"op3 should be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverRunLoopFirstAfterOp3Done
{
    // NSLog(@"turnoverRunLoopFirstAfterOp3Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertTrue( [self.op3 isFinished],  @"op3 should be finished");

    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp3.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    
    self.op1 = nil;
    self.op2 = nil;
    self.op3 = nil;
}

#pragma mark * Turnover Width

// Tests that multiple operations execute concurrent on the queue.

- (void)testTurnoverWidth
{
    NSDate *    endDate;
    
    [self.queue setMaxConcurrentOperationCount:2];
    
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    self.op3 = [self timerOperationWithDuration:0.2 name:@"op3"];
    assert(self.op3 != nil);
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");

    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];
    [self.queue addOperation:self.op3];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    // STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(turnoverWidthBeforeOp1And2Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(turnoverWidthAfterOp1And2Done)  withObject:nil afterDelay:0.3];
    [self performSelector:@selector(turnoverWidthAfterOp3Done)      withObject:nil afterDelay:0.5];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.6];
    while (self.op3 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }

    [self.queue setMaxConcurrentOperationCount:1];
}

- (void)turnoverWidthBeforeOp1And2Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertTrue( [self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"op1 shouldn't be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertTrue( [self.op2 isExecuting], @"op2 should be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverWidthAfterOp1And2Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 shouldn't be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertTrue( [self.op3 isExecuting], @"op3 shouldn be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverWidthAfterOp3Done
{
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertTrue( [self.op3 isFinished],  @"op3 should be finished");

    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp3.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    
    self.op1 = nil;
    self.op2 = nil;
    self.op3 = nil;
}

#pragma mark * Turnover Cancel Middle

// Tests that one operation will start the next operation.

- (void)testTurnoverCancelMiddle
{
    NSDate *    endDate;
        
    self.op1 = [self timerOperationWithDuration:0.2 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.op2 = [self timerOperationWithDuration:0.2 name:@"op2"];
    assert(self.op2 != nil);
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    self.op3 = [self timerOperationWithDuration:0.2 name:@"op3"];
    assert(self.op3 != nil);
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");

    [self.queue addOperation:self.op1];
    [self.queue addOperation:self.op2];
    [self.queue addOperation:self.op3];

    // STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");      -- it may be executing at this point
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op2 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op2 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op2 isFinished],  @"shouldn't start finished");
    
    STAssertFalse([self.op3 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op3 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op3 isFinished],  @"shouldn't start finished");
    
    [self performSelector:@selector(turnoverCancelMiddleBeforeOp1Done) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(turnoverCancelMiddleAfterOp2Done)  withObject:nil afterDelay:0.3];
    [self performSelector:@selector(turnoverCancelMiddleAfterOp3Done)  withObject:nil afterDelay:0.5];

    endDate = [NSDate dateWithTimeIntervalSinceNow:0.6];
    while (self.op3 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

//    +op1       -op2       +op3
// 0.0    0.2 0.2    0.2 0.2    0.4
//      ^                     ^     ^

- (void)turnoverCancelMiddleBeforeOp1Done
{
    // NSLog(@"turnoverCancelMiddleBeforeOp1Done");
    
    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertTrue( [self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"op1 shouldn't be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertFalse([self.op2 isCancelled], @"op2 shouldn't be cancelled");
    STAssertFalse([self.op2 isFinished],  @"op2 shouldn't be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
    
    [self.op2 cancel];
}

- (void)turnoverCancelMiddleAfterOp2Done
{
    // NSLog(@"turnoverCancelMiddleAfterOp2Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertTrue( [self.op2 isCancelled], @"op2 should be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertTrue( [self.op3 isExecuting], @"op3 should be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertFalse([self.op3 isFinished],  @"op3 shouldn't be finished");
}

- (void)turnoverCancelMiddleAfterOp3Done
{
    // NSLog(@"turnoverCancelMiddleAfterOp3Done");

    STAssertNotNil(self.op1, @"op1 should be present");
    STAssertFalse([self.op1 isExecuting], @"op1 should be executing");
    STAssertFalse([self.op1 isCancelled], @"op1 shouldn't be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"op1 should be finished");

    STAssertNotNil(self.op2, @"op2 should be present");
    STAssertFalse([self.op2 isExecuting], @"op2 shouldn't be executing");
    STAssertTrue( [self.op2 isCancelled], @"op2 should be cancelled");
    STAssertTrue( [self.op2 isFinished],  @"op2 should be finished");

    STAssertNotNil(self.op3, @"op3 should be present");
    STAssertFalse([self.op3 isExecuting], @"op3 shouldn't be executing");
    STAssertFalse([self.op3 isCancelled], @"op3 shouldn't be cancelled");
    STAssertTrue( [self.op3 isFinished],  @"op3 should be finished");

    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    STAssertEqualObjects([self.timerOp2.debugEventLog componentsJoinedByString:@"/"], @">cancel/-cancel.winner/<cancel/>start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.cancelled/>finishWithError/-finishWithError.error/-setState.finished/<finishWithError/<startOnRunLoopThread", @"sequence error");
    STAssertEqualObjects([self.timerOp3.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError", @"sequence error");
    
    self.op1 = nil;
    self.op2 = nil;
    self.op3 = nil;
}

#pragma mark * Delayed Cancel

// Tests the much-delayed cancel case

- (void)testDelayedCancel
{
    NSDate *    endDate;
    
    // 0.0   0.05   0.1    0.15       0.2
    // start cancel finish cancel     all done
    //       begins        effective
    //                     but bounces
    
    self.op1 = [self timerOperationWithDuration:0.1 name:@"op1"];
    assert(self.op1 != nil);
    
    STAssertFalse([self.op1 isExecuting], @"shouldn't start executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't start cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't start finished");
    
    self.timerOp1.debugSecondaryThreadCancelDelay = 0.1;
    
    [self.queue addOperation:self.op1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        assert( ! [NSThread isMainThread] );
        STAssertNotNil(self.op1, @"op1 shouldn't be already done");
        STAssertTrue( [self.op1 isExecuting], @"should be executing");
        STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
        STAssertFalse([self.op1 isFinished],  @"shouldn't be finished");
        [self.op1 cancel];
        STAssertTrue([self.op1 isCancelled], @"shouldn't be cancelled");
    });

    [self performSelector:@selector(delayedCancelBeforeOp1Cancelled) withObject:nil afterDelay:0.02];
    [self performSelector:@selector(delayedCancelAfterOp1Cancelled)  withObject:nil afterDelay:0.07];
    [self performSelector:@selector(delayedCancelAfterOp1Done)       withObject:nil afterDelay:0.12];
    [self performSelector:@selector(delayedCancelAfterAllDone)       withObject:nil afterDelay:0.20];
    
    endDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while (self.op1 != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:endDate];
    }
}

- (void)delayedCancelBeforeOp1Cancelled
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertTrue( [self.op1 isExecuting], @"should be executing");
    STAssertFalse([self.op1 isCancelled], @"shouldn't be cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't be finished");
}

- (void)delayedCancelAfterOp1Cancelled
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertTrue( [self.op1 isExecuting], @"should be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertFalse([self.op1 isFinished],  @"shouldn't be finished");
}

- (void)delayedCancelAfterOp1Done
{
    STAssertNotNil(self.op1, @"op1 shouldn't be already done");
    STAssertFalse([self.op1 isExecuting], @"shouldn't be executing");
    STAssertTrue( [self.op1 isCancelled], @"should be cancelled");
    STAssertTrue( [self.op1 isFinished],  @"should be finished");
}

- (void)delayedCancelAfterAllDone
{
    STAssertEqualObjects([self.timerOp1.debugEventLog componentsJoinedByString:@"/"], @">start/-setState.executing/<start/>startOnRunLoopThread/-startOnRunLoopThread.start/<startOnRunLoopThread/>cancel/-cancel.winner/-cancel.delay/>finishWithError/-finishWithError.noError/-setState.finished/<finishWithError/-cancel.schedule/<cancel/>cancelOnRunLoopThread/-cancelOnRunLoopThread.bounce/<cancelOnRunLoopThread", @"sequence error");
    self.op1 = nil;
}

#pragma mark * Stress Test

enum {
    kTestStressLogEnabled = NO
};

- (void)testStress
{
    NSDate *            endDate;
    NSUInteger          cancelIndex;
    TimerOperation *    timerOp;
    NSUInteger          opCount;
    
    [self.queue setMaxConcurrentOperationCount:5];
    
    assert(self.operations == nil);
    self.operations = [NSMutableArray array];
    assert(self.operations != nil);
    
    opCount = 666;
    
    endDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while ( [NSDate timeIntervalSinceReferenceDate] < [endDate timeIntervalSinceReferenceDate] ) {
        NSAutoreleasePool * pool;
        
        pool = [[NSAutoreleasePool alloc] init];
        assert(pool != nil);
        
        // in in ten iterations, cancel a random operation
        
        if ([self.operations count] != 0) {
            if ((arc4random() % 10) == 0) {
                cancelIndex = arc4random() % [self.operations count];
                assert(cancelIndex < [self.operations count]);
                timerOp = (TimerOperation *) [self.operations objectAtIndex:cancelIndex];
                assert([timerOp isKindOfClass:[TimerOperation class]]);
                [timerOp cancel];
            }
        }
        
        // start operations until we hit our limit
        
        while ( [self.operations count] < 20 ) {
            timerOp = [self timerOperationWithDuration:((NSTimeInterval) (arc4random() % 100)) / 1000.0 name:[NSString stringWithFormat:@"op%zu", (size_t) opCount]];
            opCount += 1;
            
            [timerOp addObserver:self forKeyPath:@"isFinished" options:0 context:&self->operations_];
            
            if (kTestStressLogEnabled) {
                NSLog(@"  started %@ for %.3f", timerOp.debugName, timerOp.duration);
            }
            [self.operations addObject:timerOp];
            
            [self.queue addOperation:timerOp];
        }

        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        [pool drain];
    }
    while ([self.operations count] != 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    assert([self.operations count] == 0);
    self.operations = nil;

    [self.queue setMaxConcurrentOperationCount:1];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->operations_) {
        TimerOperation *    timerOp;
        
        timerOp = (TimerOperation *) object;
        assert([timerOp isKindOfClass:[TimerOperation class]]);
        
        [timerOp removeObserver:self forKeyPath:@"isFinished"];
        
        [self performSelectorOnMainThread:@selector(nixOperation:) withObject:timerOp waitUntilDone:NO];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)nixOperation:(TimerOperation *)timerOp
{
    assert([timerOp isKindOfClass:[TimerOperation class]]);
    
    if (kTestStressLogEnabled) {
        if ([timerOp isCancelled]) {
            NSLog(@"cancelled %@", timerOp.debugName);
        } else {
            NSLog(@"     done %@", timerOp.debugName);
        }
    }
    [self.operations removeObject:timerOp];
}

@end
