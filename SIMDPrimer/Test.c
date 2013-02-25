/*
File:  Test.c

Abstract:
    This is a simple test program for the vAdd routine.  It is not needed to
    understand the lessons of the WWDC session.  This is not a robust test
    program; it is only intend for assistance with the sample code.

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

#include "vAdd.h"


#define ElementsPerVector   4

// Add padding before and after array to check for improper modifications.
#define Padding 4


// This routine generates expected results.
void Reference(const float *A, const float *B, float *C, long N)
{
    for (long i = 0; i < N; ++i)
        C[i] = A[i] + B[i];
}


int main(void)
{
    // Define test data.
    static const int MaximumN = 1024;
    int AllocationLength = MaximumN + ElementsPerVector - 1;

    /*  Allocate space for arrays.  Include extra space so we can perform
        experiments with different address offsets.
    */
    float *A  = malloc(AllocationLength * sizeof *A );
    float *B  = malloc(AllocationLength * sizeof *B );
    float *C0 = malloc(MaximumN * sizeof *C0);
    float *mC = malloc((AllocationLength + 2*Padding) * sizeof *mC);
    if (!A || !B || !C0 || !mC)
    {
        free(mC);
        free(C0 );
        free(B  );
        free(A  );
        fprintf(stderr, "Error, failed to allocate memory.\n");
        return EXIT_FAILURE;
    }
    float *C  = mC + Padding;

    // Initialize input arrays.
    for (long i = 0; i < AllocationLength; ++i)
    {
        A[i] = i + 1;
        B[i] = 10000 * (i+1);
    }

    // Test different lengths.
    for (long N = 0; N <= MaximumN; ++N)

    // Try combinations of address offsets modulo vector size.
    for (long AOffset = 0; AOffset < ElementsPerVector; ++AOffset)
    for (long BOffset = 0; BOffset < ElementsPerVector; ++BOffset)
    for (long COffset = 0; COffset < ElementsPerVector; ++COffset)
    {
        float *C1 = C + COffset;

        // Erase output.
        for (long i = -Padding; i < N + Padding; ++i)
            C1[i] = 0;

        // Get expected results.
        Reference(A + AOffset, B + BOffset, C0, N);

        // Get observed results.
        vAdd(A + AOffset, B + BOffset, C + COffset, N);

        // Look for errors in the expected output elements.
        for (long i = 0; i < N; ++i)
            if (C0[i] != C1[i])
            {
                fprintf(stderr,
"Error.\n"
"\tA = %p.  B = %p.  C = %p.  N = %zd.\n"
"\tElement %zd:  Expected %.7g, observed %.7g.\n",
                    (void *) A, (void *) B, (void *) C1, (size_t) N,
                    (size_t) i, C0[i], C1[i]);
                return EXIT_FAILURE;
            }

        // Look for errors outside the expected output elements.
        for (long i = -Padding; i < N + Padding; ++i)
            if (C1[i] != 0 && (i < 0 || N <= i))
            {
                fprintf(stderr,
"Error.\n"
"\tA = %p.  B = %p.  C = %p.  N = %zd.\n"
"\tExternal element %zd was modified:  Expected 0, observed %.7g.\n",
                    (void *) A, (void *) B, (void *) C1, (size_t) N,
                    (size_t) i, C1[i]);
                return EXIT_FAILURE;
            }
    }

    free(mC);
    free(C0);
    free(B );
    free(A );

    return 0;
}
