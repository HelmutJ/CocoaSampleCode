/*
 
 File: executions.c of Dispatch_Compared
 
 Abstract: Compare overhead of several GCD approaches with that of serial code and threads
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

#include "executions.h"
#include "benchmark.h"

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <math.h>
#include <assert.h>
#include <pthread.h>
#include <dispatch/dispatch.h>

static double *results = NULL;
static int n_folds = 1;

// Perform relatively complex trigonometry on the input value, and store in a (uniquely indexed) global array
void work_function(int i)
{
    double x = 1.0+i*i; // zero would skew the result
    for (int j=0; j < n_folds; ++j) {
        x = tan(M_PI_2 - atan(exp(2*log(sqrt(x))))); // really slow identity function
    }
    if (NULL != results) results[i] = x;
}


// The thread entry point routine.
void* PosixThreadMainRoutine(void* data)
{
    int* iptr = data;
    work_function(*iptr);
    return NULL;
}

// Create threads using POSIX routines, then wait for them to finish.
// Note: this is NOT the most efficient way to use threads, but rather an example of 'naive' parallelism
void* UseThread(int n)
{
    pthread_t thread_id[n];
    int index[n];
    
    for (int i = 0; i < n; i++) {
        index[i] = i;
        int threadError = pthread_create(&thread_id[i], NULL, PosixThreadMainRoutine, (void *) &index[i]);
        assert(threadError == 0);
    }   
    for (int i = 0; i < n; i++) {
        int threadError = pthread_join(thread_id[i], NULL);
        assert(threadError == 0);
    }
#ifdef DEBUG
    fprintf(stderr, "\tRan %d threads\n", n);
#endif
    return NULL;
}

// Use many queues -- this is also inefficient :-)

void* UseMultiQueue(int n)
{
    dispatch_queue_t queues[n];
    char *queue_label;
    for (int i = 0; i < n; i++) {
        int rc = asprintf(&queue_label, "com.apple.gcd.examples.compare.multiq%04d", i);
        assert(rc > 0);
        queues[i] = dispatch_queue_create(queue_label, NULL);
        free(queue_label);
        assert(queues[i] != NULL);
        dispatch_async(queues[i], ^{
            work_function(i);
        });
    }
    for (int i = 0; i < n; i++) {
        dispatch_sync(queues[i], ^{ }); // block until queue has completed all previous work
        dispatch_release(queues[i]);
    }
    return NULL;
}

// Use dispatch groups to queue concurrently, then wait for completion
void* UseConcurrentQueue(int n)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    dispatch_group_t group = dispatch_group_create();
    assert(group);
    
    for (int i = 0; i < n; i++) {
        dispatch_group_async(group, queue, ^{
            work_function(i);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(group);
    return NULL;
}

// Use a private serial queue.
void* UseSerialQueue(int n)
{
    dispatch_queue_t queue = dispatch_queue_create("com.apple.gcd.examples.compare.serial", NULL);
    assert(queue);
    
    for (int i = 0; i < n; i++) {
        dispatch_async(queue, ^{
            work_function(i);
        });
    }
    dispatch_sync(queue, ^{ return; }); // block until queue has completed all previous work
    dispatch_release(queue);
    return NULL;
}

// Use the highly optimized dispatch_apply to loop concurrently.
void* UseApply(int n)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    dispatch_apply(n, queue, ^(size_t i){
        work_function(i);
    });
    return NULL;
}

void* UseOpenMP(int n)
{
#pragma omp parallel for    
    for (int i = 0; i < n; i++) {
        work_function(i);
    }
    return NULL;
}

// Run calculation entirely in the main thread; least overhead but zero parallelism.
void* UseLoop(int n)
{
    for (int i = 0; i < n; i++) {
        work_function(i);
    }
    return NULL;
}

// External Functions

void executions_setup(int max_iterations, int folds)
{
    results = (double*)malloc(max_iterations*sizeof(double));
    n_folds = folds;
}

void executions_run(int i)
{
    benchmark_header(i);
    benchmark_function(i, "loop", UseLoop, NULL);
    benchmark_function(i, "apply", UseApply, NULL);
    benchmark_function(i, "serial", UseSerialQueue, NULL);
    benchmark_function(i, "parallel", UseConcurrentQueue, NULL);
    benchmark_function(i, "queues", UseMultiQueue, NULL);
    benchmark_function(i, "openmp", UseOpenMP, NULL);
    if (i < 1e4)
        benchmark_function(i, "thread", UseThread, NULL);
}

void executions_done(int n)
{
    if (NULL != results) return;

    printf("Calculation results:\n");
    for (int i = 0; i < n; i++) {
        if (results[i] != 0)
            printf("  %'10.0f", results[i]);
    }
    printf("\n\tdone.\n");
    free(results);
}
