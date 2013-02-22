/*
 
 File: main.c of Dispatch_Compared
 
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
#include "invocations.h"
#include "executions.h"

#include <getopt.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    int test_seconds = 60;
	int max_iterations = 1e6;
    int folds = 16;

    // Not using longopts correctly, but will leave in for now...
    struct option longopts[] = {
        { "test_seconds",   required_argument, &test_seconds,    60        },
        { "max_iterations", required_argument, &max_iterations,  1024*1024 },
        { "folds",          required_argument, &folds,           16        },
        { NULL,         0,                      NULL,            0         }
    };
    

    int ch;
    while ((ch = getopt_long(argc, argv, "w:t:m:f:", longopts, NULL)) != -1) {
#ifdef DEBUG
        printf("Option: %c, %s\n", ch, optarg);
#endif
        switch (ch) {
            case 't':
                test_seconds = atoi(optarg);
                break;
            case 'm':
                max_iterations = atoi(optarg);
                break;
            case 'f':
                folds = atoi(optarg);
                break;
            default:
                printf("Usage: %s [-t test_seconds] [-m max_iterations] [-f folds]\n", argv[0]);
                break;
        }
    }

	printf("$ %s -t %d -m %d -f %d\n", argv[0], test_seconds, max_iterations, folds);

    
    printf("Benchmark averaged over: %d seconds\n", test_seconds);
    benchmark_setup(test_seconds);

    printf("Iterate maximum of: %d times\n", max_iterations);    
    printf("Work function folded: %d times\n", folds);    
    executions_setup(max_iterations, folds);
    
    printf("\nASYNCHRONOUS: Microseconds to *initiate* execution (avg. over %d seconds)\n", test_seconds);
    for (int i = 1; i <= max_iterations; i *= 2) {
        invocations_run(i);
    }
    
    printf("\nSYNCHRONOUS: Microseconds to *complete* execution (avg. over %d seconds)\n", test_seconds);
    for (int i = 1; i <= max_iterations; i *= 2) {
        executions_run(i);
    }

    executions_done(max_iterations);
   
}
