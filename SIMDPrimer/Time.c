/*
File:  Time.c

Abstract:
    This program times some cases of the vAdd routine.  It illustrates the
    execution speed of the sample routine but is not otherwise needed to
    understand the lessons of the session.

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

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/


#include <stdio.h>
#include <stdlib.h>

#include "ClockServices.h"
#include "vAdd.h"


#define ElementsPerVector   4


// Define a structure to hold parameters needed by the routine being timed.
typedef struct { const float *A; const float *B; float *C; long N; } Parameters;


// Driver is a routine that calls the subject routine repeatedly.
void Driver(unsigned int iterations, void *data)
{
    // Get the parameters from the structure passed to us.
    Parameters *parameters = (Parameters *) data;

    const float *A  = parameters->A;
    const float *B  = parameters->B;
          float *C  = parameters->C;
    long N = parameters->N;

    // Call the subject routine the number of times requested.
    while (iterations--)
        vAdd(A, B, C, N);
}


int main(void)
{
    // Define test data.
    static const int N = 1024;
    int AllocationLength = N + ElementsPerVector - 1;

    /*  Allocate space for arrays.  Include extra space so we can perform
        measurements with different address offsets.
    */
    float *A = malloc(AllocationLength * sizeof *A);
    float *B = malloc(AllocationLength * sizeof *B);
    float *C = malloc(AllocationLength * sizeof *C);
    if (!A || !B || !C)
    {
        free(C);
        free(B);
        free(A);
        fprintf(stderr, "Error, failed to allocate memory.\n");
        return EXIT_FAILURE;
    }

    // Initialize input arrays.
    for (long i = 0; i < AllocationLength; ++i)
    {
        A[i] = i;
        B[i] = 10000 * i;
    }

    // Print table header.
    printf("Offset in Bytes\n");
    printf("   A    B    C    CPU Cycles Per Element\n");

    for (long AOffset = 0; AOffset < ElementsPerVector; ++AOffset)
    for (long BOffset = 0; BOffset < ElementsPerVector; ++BOffset)
    for (long COffset = 0; COffset < ElementsPerVector; ++COffset)
    {
        // Package parameters for timing routine.
        Parameters parameters = { A + AOffset, B + BOffset, C + COffset, N };

        // Measure the execution time of the subject routine.
        double t = MeasureNetTimeInCPUCycles(Driver, 100, &parameters, 100);

        printf("%4zd %4zd %4zd    %.3g\n",
            AOffset * sizeof *A, BOffset * sizeof *B, COffset * sizeof *C,
            t / N);
    }

    free(C);
    free(B);
    free(A);

    return 0;
}
