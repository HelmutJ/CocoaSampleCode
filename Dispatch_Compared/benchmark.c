/*
 
 File: benchmark.c of Dispatch_Compared
 
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

#include "benchmark.h"

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <locale.h>

#include <math.h>  
#include <sys/sysctl.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <mach/mach_time.h>  

#include <dispatch/dispatch.h>

static int64_t offset_nsec = 1e6;  // start at 1 msec for warmup purposes
static int test_running = 0;

// set from $ sysctl hw.cpufrequency
void show_cpu_speed(void)
{
    double cpu_speed = 0.0;
    unsigned hertz;
	size_t size = sizeof(unsigned);
	int mib[2] = {CTL_HW, HW_CPU_FREQ};
	sysctl(mib, 2, &hertz, &size, NULL, 0);
    cpu_speed = hertz / 1.0e9;
	printf("CPU speed: %.2lf GHz\n", cpu_speed);
}

void show_locale(void)
{
    char *lang = getenv("LANG");
    setlocale(LC_NUMERIC, (lang != NULL) ? lang : "en_US.utf-8");
#ifdef DEBUG
	printf("Locale: %s\n", setlocale(LC_NUMERIC, NULL));  
#endif
}

void benchmark_setup(int test_seconds)
{
    offset_nsec = test_seconds * NSEC_PER_SEC;
    show_locale();
    show_cpu_speed();
}

void benchmark_begin()
{
    dispatch_time_t duration = dispatch_walltime(DISPATCH_TIME_NOW, offset_nsec);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_after(duration, queue, ^{
        test_running = 0;
    });
    test_running = 1;    
}

int benchmark_running()
{
    return test_running;
}


typedef struct bench_times {
    double wall;
    double wall_sq;
    double user;
    double system;
} bench_times_t;

double resource_usec(struct timeval *time) {
    return time->tv_sec*1e6 + time->tv_usec;
}

void bench_start(bench_times_t *now)
{
    static double usec_per_unit = 0.0;
    if (0 == usec_per_unit) {
        mach_timebase_info_data_t sTimebaseInfo;
        mach_timebase_info(&sTimebaseInfo);
        double nsec_per_unit = sTimebaseInfo.numer / sTimebaseInfo.denom;
        usec_per_unit = nsec_per_unit / 1e3;
    }
    struct rusage resource_times;
    getrusage(RUSAGE_SELF, &resource_times);
    
    now->wall = mach_absolute_time() * usec_per_unit;
    now->wall_sq = 0;
    now->user = resource_usec(&resource_times.ru_utime);
    now->system = resource_usec(&resource_times.ru_stime);
}

void bench_stop(bench_times_t *then)
{
    bench_times_t now;
    bench_start(&now);
    
    then->wall    = (now.wall - then->wall);
    then->wall_sq = then->wall * then->wall;
    then->user    = (now.user - then->user);
    then->system  = (now.system - then->system);
}

void bench_set(bench_times_t *dest, bench_times_t *src)
{
    dest->wall    = src->wall;
    dest->wall_sq = src->wall_sq;
    dest->user    = src->user;
    dest->system  = src->system;
}

void bench_add(bench_times_t *dest, bench_times_t *src)
{
    dest->wall    += src->wall;
    dest->wall_sq += src->wall_sq;
    dest->user    += src->user;
    dest->system  += src->system;
}

void bench_normalize(bench_times_t *dest, int n)
{
    dest->wall    /= n;
    dest->wall_sq /= n;
    dest->user    /= n;
    dest->system  /= n;
}


void benchmark_header(int i)
{
    printf("\n  µsecs±error/%-'8d = WALL(µs)±error   [+-rate]   USER (µs) +    SYS (µs) [overhead]\n",i);
}

void benchmark_function(int n, char *label, void* (*f)(int), void (*cleanup)(int, void*))
{
    static bench_times_t base = { 0, 0, 0 };
    bench_times_t timer = { 0, 0, 0 };
    int count = 0;

    void *ptr = f(n); //warmup
    if (NULL != cleanup) cleanup(n, ptr);

    benchmark_begin();
    while (benchmark_running()) {
        ++count;        
        bench_times_t lap_timer;
        bench_start(&lap_timer);
        ptr = f(n);
        bench_stop(&lap_timer);
        bench_add(&timer, &lap_timer);
        if (NULL != cleanup) cleanup(n, ptr);
    } 
    bench_normalize(&timer, count);
    
    if (0 == strncmp(label, "loop", 8) || 0 == strncmp(label, "alloc", 8) || 0 == base.wall) {
        bench_set(&base, &timer);
    }
    double wall_error = sqrt(timer.wall_sq - timer.wall*timer.wall);
    double speedup = base.wall/timer.wall; // note: inverted vis-a-vis overhead
    double overhead = (timer.user + timer.system) / (base.user + base.system);
    
	printf("%7.3f±%'5.3f/%-8s = %'8.3g±%'-7.2g [%+5.0f%%] %'10.4gu + %'10.4gs [%7.0f%%]\n",
           timer.wall / n, wall_error / n, label, 
           timer.wall, wall_error, (speedup-1)*100,
           timer.user, timer.system, (overhead-1)*100);
}
