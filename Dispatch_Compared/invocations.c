/*
 
 File: invocations.c of Dispatch_Compared
 
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

#include "invocations.h"
#include "benchmark.h"

#include <assert.h>
#include <pthread.h>
#include <dispatch/dispatch.h>
#include <CoreFoundation/CoreFoundation.h>

// The thread entry point routine.
void* PosixThreadNullRoutine(void* data)
{
    return NULL;
}

void* InvokeThread(int n)
{
    pthread_t *thread_id = (pthread_t*) malloc(n*sizeof(pthread_t));
    for (int i = 0; i < n; i++) {
        int threadError = pthread_create(&thread_id[i], NULL, PosixThreadNullRoutine, NULL);
        assert(threadError == 0);
    }
    return thread_id;
}

void CleanupThread(int n, void *thread_ptr)
{
    pthread_t *thread_id = (pthread_t*)thread_ptr;
    for (int i = 0; i < n; i++) {
        int threadError = pthread_join(thread_id[i], NULL);
        assert(threadError == 0);
    }
    free(thread_id);
}

void* InvokeDispatch(int n)
{
    static int dummy = 0;
    static dispatch_queue_t queue = NULL;
    if (NULL == queue) queue = dispatch_queue_create("com.apple.gcd.examples.compare.invoke", NULL);
    dispatch_suspend(queue);
    for (int i = 0; i < n; i++) {
        dispatch_async(queue, ^{ dummy = i; }); // Assign variable to avoid over-optimization
    }
    return queue;
}

void CleanupDispatch(int n, void *queue_ptr)
{
    dispatch_queue_t queue = (dispatch_queue_t) queue_ptr;
    dispatch_resume(queue);
    dispatch_sync(queue, ^{ }); // block until queue has completed all previous work
}


static int global_dummy = 0;
void test_dispatch(void *ctxt)
{
    int* i_p = ctxt;
    global_dummy = *i_p;
}

void* InvokeDispatchF(int n)
{
    static dispatch_queue_t queue = NULL;
    if (NULL == queue) queue = dispatch_queue_create("com.apple.gcd.examples.compare.invokef", NULL);
    dispatch_suspend(queue);
    for (int i = 0; i < n; i++) {
        dispatch_async_f(queue, &i, test_dispatch); // Assign variable to avoid over-optimization
    }
    return queue;
}

void CleanupDispatchF(int n, void *queue_ptr)
{
    dispatch_queue_t queue = (dispatch_queue_t) queue_ptr;
    dispatch_resume(queue);
    dispatch_sync(queue, ^{ }); // block until queue has completed all previous work
}


void* InvokeArray(int n)
{
    CFMutableArrayRef array = CFArrayCreateMutable(NULL, 0, NULL);
    
    for (int i = 0; i < n; i++) {
        char *label;
        int rc = asprintf(&label, "string #i", i);
        assert(rc > 0);
        CFStringRef str = CFStringCreateWithCString(NULL, label, kCFStringEncodingMacRoman);
        free(label);
        CFArrayAppendValue(array, str);
        CFRelease(str);
    }
    return array;
}


void CleanupArray(int n, void *array_ptr)
{
    CFMutableArrayRef array = (CFMutableArrayRef)array_ptr;
    CFRelease(array);    
}

void* InvokeAlloc(int n)
{
    void* *alloc_id = (void**)malloc(n*sizeof(void*));
    
    for (int i = 0; i < n; i++) {
        size_t alloc_size = sizeof(pthread_t) + sizeof(dispatch_queue_t);
        alloc_id[i] = malloc(alloc_size);
        bzero(alloc_id[i],alloc_size); 
    }
    return alloc_id;
}

void CleanupAlloc(int n, void *alloc_ptr)
{
    void* *alloc_id = (void**)alloc_ptr;
    for (int i = 0; i < n; i++) {
        free(alloc_id[i]);
    }
}

void invocations_run(int i)
{
    benchmark_header(i);
    benchmark_function(i, "alloc", InvokeAlloc, CleanupAlloc);
    benchmark_function(i, "array", InvokeArray, CleanupArray);
    benchmark_function(i, "dsptch_f", InvokeDispatchF, CleanupDispatchF);
    benchmark_function(i, "dispatch", InvokeDispatch, CleanupDispatch);
    if (i < 1e4)
        benchmark_function(i, "fork", InvokeThread, CleanupThread);    
}

