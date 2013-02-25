/*
File:  vAdd.c

Abstract:
    This module implements the vAdd routine shown in the session.  It
    illustrates some techniques for using SIMD technology.

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

#if defined __i386__ || defined __x86_64__
    #include <emmintrin.h>
#endif

#include "vAdd.h"
#include "vector.h"

#define ElementsPerVector   FloatsPerVector


// Swap two things of type Type.
#define Swap(a, b)    { __typeof__(a) t = (a); (a) = (b); (b) = (t); }


/*  Calculate the encoding for a shuffle that selects elements e0, e1, e2, and
    e3 in that order for ascending addresses.
*/
#define Shuffle4(e0, e1, e2, e3)    \
    ((e0) << 0 | (e1) << 2 | (e2) << 4 | (e3) << 6)

/*  Calculate the encoding for a shuffle that selects elements e0 and e1 in
    that order for ascending addresses.
*/
#define Shuffle2(e0, e1)    ((e0) << 0 | (e1) << 1)


/*  We need to move parts of vector registers around, and the movss instruction
    is a handy way to do some of the manipulations we need.  <xmmintrin.h>
    defines an instrinsic named _mm_move_ss for the movss instruction.

    The movss instruction is also available as a GCC extension:

        #define movss(v0, v1)   __builtin_ia32_movss((v0), (v1))
*/
#define movss(v0, v1)   _mm_move_ss((v0), (v1))


/*  We need to move parts of vector registers around, and the shufpd
    instruction is a handy way to do some of the manipulations we need.
    <emmintrin.h> defines an intrinsic named _mm_shuffle_pd for the shufpd
    instruction.  However, its return type is __m128d (a vector containing two
    doubles), so we must cast it to the vector type we are using.  Since we are
    only moving data around and not interpreting the bits with arithmetic, this
    is okay.

    The selector passed to shufpd is a two-bit field.  The first bit selects
    which eight bytes in the first parameter are taken (0 for the first eight
    bytes, 1 for the second eight bytes).  The second bit selects which eight
    bytes in the second parameter are taken.

    The shufpd instruction is also available as a GCC extension.  To use the
    GCC extension, the first two parameters must be cast to the correct type:

        #define shufpd(v0, v1, selector)    ((vFloat) \
            __builtin_ia32_shufpd((__m128d) (v0), (__m128d) (v1), (selector)))
*/
#define shufpd(v0, v1, selector)    \
    ((vFloat) _mm_shuffle_pd((v0), (v1), (selector)))


/*  We need to move parts of vector registers around, and the pshufd
    instruction is a handy way to do some of the manipulations we need.
    <emmintrin.h> defines an intrinsic named _mm_shuffle_epi32 for the pshufd
    instruction.  However, its return type is __m128i (a vector containing
    integers), so we must cast it to the vector type we are using.  Since we
    are only moving data around and not interpreting the bits with arithmetic,
    this is okay.

    The selector passed to pshufd is an eight-bit field.  Each pair selects
    four bytes from the first parameter (0 for the first four bytes, 1 for the
    second four bytes, 2 for the third four bytes, and 3 for the last four
    bytes).

    The pshufd instruction is also available as a GCC extension.  To use the
    GCC extension, the first two parameters must be cast to the correct type:

        #define pshufd(v0, selector)    ((vFloat) \
            __builtin_ia32_pshufd((__m128i) (v0), (selector)))
*/
#define pshufd(v0, selector)    ((vFloat) _mm_shuffle_epi32((v0), (selector)))


/*  vAddB00 implements vAdd given that each of A, B, and C is 0 modulo 16 and N
    is a multiple of ElementsPerVector.

    This routine uses GCC extensions to C that are not architecture-specific,
    so it is a good introduction to some simple vector/SIMD processing.
*/
static inline void vAddB00(const float *A, const float *B, float *C, long N)
{
    /*  Convert scalar pointers to vector pointers and scalar length
        (number of elements) to vector length (number of vector blocks).
    */
    const vFloat *vA = (const vFloat *) A;
    const vFloat *vB = (const vFloat *) B;
          vFloat *vC = (      vFloat *) C;
    long vN = N / ElementsPerVector;

    /*  This main loop processes four vector blocks in each iteration, so we
        execute it as long as there are at least four more blocks to do.
    */
    while (4 <= vN)
    {
        vN -= 4;
        vC[0] = vA[0] + vB[0];
        vC[1] = vA[1] + vB[1];
        vC[2] = vA[2] + vB[2];
        vC[3] = vA[3] + vB[3];
        vA += 4;
        vB += 4;
        vC += 4;
    }

    /*  After the main loop, there could be zero, one, two, or three more
        vector blocks to process.  We handle those here with code that is
        essentially a subset of the main loop.
    */

    if (2 <= vN)
    {
        vN -= 2;
        vC[0] = vA[0] + vB[0];
        vC[1] = vA[1] + vB[1];
        vA += 2;
        vB += 2;
        vC += 2;
    }

    if (1 <= vN)
        vC[0] = vA[0] + vB[0];

    /*  Note:  Ideally, we would use simple code such as:

            for (long i = 0; i < vN; ++i)
                vC[i] = vA[i] + vB[i];

        That code works and is functionally identical to the above code in
        terms of what it computes.  Unfortunately, GCC does not generate the
        best assembly code.  For example, it uses separate registers for i and
        vN even though we can get the work done with just one.

        Discussing what GCC does and how to work with it is beyond the scope of
        this primer.  It does require experimentation and studying the assembly
        language GCC generates.  Also, work-arounds are subject to breaking
        when new versions of GCC are used or even when simple code changes are
        made.  These are part of the reasons I prefer to use assembly language
        for core pieces of high-performance work.
    */
}


/*  vAddB04 implements vAdd given that each of A and C is 0 modulo 16, B is 4
    modulo 16, and N is a multiple of ElementsPerVector.

    This routine uses SIMD constructions that are specific to the Intel
    architectures.  (That is, the IA-32 and EM64T architectures, called "i386"
    and "x86_64" by various Apple tools.)
*/
static inline void vAddB04(const float *A, const float *B, float *C, long N)
{
    #if defined __i386__ || defined __x86_64__  // Architecture.

        if (N <= 0)
            return;

        /*  Convert scalar pointers to vector pointers and scalar length
            (number of elements) to vector length (number of vector blocks).

            vB is set to point to the start of the aligned vector block into
            which B points.
        */
        const vFloat *vA = (const vFloat *) A;
        const vFloat *vB = (const vFloat *) (B-1);
              vFloat *vC = (      vFloat *) C;
        long vN = N / ElementsPerVector;

        /*  Since B is unaligned with respect to vector blocks, we cannot load
            data directly from it using vector instructions.  Instead, we will
            construct a pipeline or buffer of data coming from B.  Aligned data
            will be loaded into the pipeline using vector instructions.  Once
            the data is in registers, there are vector instructions we can use
            to shift it to be aligned.
        */

        // Prime the pipeline.
        vFloat pipe0 = vB[0];

        /*  This main loop processes four vector blocks in each iteration, so
            we execute it as long as there are at least four more blocks to do.
        */
        while (4 <= vN)
        {
            vN -= 4;

            vFloat pipe1;

            pipe1 = vB[1];
            pipe0 = movss(pipe0, pipe1);
            vFloat vb0 = pshufd(pipe0, Shuffle4(1, 2, 3, 0));

            pipe0 = vB[2];
            pipe1 = movss(pipe1, pipe0);
            vFloat vb1 = pshufd(pipe1, Shuffle4(1, 2, 3, 0));

            pipe1 = vB[3];
            pipe0 = movss(pipe0, pipe1);
            vFloat vb2 = pshufd(pipe0, Shuffle4(1, 2, 3, 0));

            pipe0 = vB[4];
            pipe1 = movss(pipe1, pipe0);
            vFloat vb3 = pshufd(pipe1, Shuffle4(1, 2, 3, 0));

            vC[0] = vA[0] + vb0;
            vC[1] = vA[1] + vb1;
            vC[2] = vA[2] + vb2;
            vC[3] = vA[3] + vb3;

            vA += 4;
            vB += 4;
            vC += 4;
        }

        /*  After the main loop, there could be zero, one, two, or three more
            vector blocks to process.  We handle those here with code that is
            essentially a subset of the main loop.
        */

        if (2 <= vN)
        {
            vN -= 2;

            vFloat pipe1;

            pipe1 = vB[1];
            pipe0 = movss(pipe0, pipe1);
            vFloat vb0 = pshufd(pipe0, Shuffle4(1, 2, 3, 0));

            pipe0 = vB[2];
            pipe1 = movss(pipe1, pipe0);
            vFloat vb1 = pshufd(pipe1, Shuffle4(1, 2, 3, 0));

            vC[0] = vA[0] + vb0;
            vC[1] = vA[1] + vb1;

            vA += 2;
            vB += 2;
            vC += 2;
        }

        if (1 <= vN)
        {
            vFloat pipe1;

            pipe1 = vB[1];
            pipe0 = movss(pipe0, pipe1);
            vFloat vb0 = pshufd(pipe0, Shuffle4(1, 2, 3, 0));

            vC[0] = vA[0] + vb0;
        }

    #else   // Architecture.

        /*  For architectures for which we do not have SIMD code, use normal
            scalar code.
        */

        N = -N;
        A -= N;
        B -= N;
        C -= N;
        for (; N < 0; ++N)
            C[N] = A[N] + B[N];

    #endif  // Architecture.
}


/*  vAddB08 implements vAdd given that each of A and C is 0 modulo 16, B is 8
    modulo 16 and N is a multiple of ElementsPerVector.

    This routine uses SIMD constructions that are specific to the Intel
    architectures.  (That is, the IA-32 and EM64T architectures, called "i386"
    and "x86_64" by various Apple tools.)
*/
static inline void vAddB08(const float *A, const float *B, float *C, long N)
{
    #if defined __i386__ || defined __x86_64__  // Architecture.

        if (N <= 0)
            return;

        /*  Convert scalar pointers to vector pointers and scalar length
            (number of elements) to vector length (number of vector blocks).

            vB is set to point to the start of the aligned vector block into
            which B points.
        */
        const vFloat *vA = (const vFloat *) A;
        const vFloat *vB = (const vFloat *) (B-2);
              vFloat *vC = (      vFloat *) C;
        long vN = N / ElementsPerVector;

        /*  Since B is unaligned with respect to vector blocks, we cannot load
            data directly from it using vector instructions.  Instead, we will
            construct a pipeline or buffer of data coming from B.  Aligned data
            will be loaded into the pipeline using vector instructions.  Once
            the data is in registers, there are vector instructions we can use
            to shift it to be aligned.
        */

        // Prime the pipeline.
        vFloat pipe0 = vB[0];

        /*  This main loop process four vector blocks in each iteration, so we
            execute it as long as there are at least four more blocks to do.
        */
        while (4 <= vN)
        {
            vN -= 4;

            vFloat pipe1, pipe2, pipe3;

            // Load more data into the pipeline.
            pipe1 = vB[1];
            /*  Take the second eight bytes (index 1) from pipe0 and the
                first eight bytes (index 0) from pipe1 and put them together
                in vb0.
            */
            vFloat vb0 = shufpd(pipe0, pipe1, Shuffle2(1, 0));
            // Add the shifted data from vB to vA and store in vC.
            vC[0] = vA[0] + vb0;


            /*  Repeat the above three times, but note that we reuse pipe0 here
                as we load from vB[3].  The first eight bytes are used in the
                addition below.  The second eight bytes remain in pipe0 for the
                next iteration of this loop.
            */
            pipe2 = vB[2];
            vFloat vb1 = shufpd(pipe1, pipe2, Shuffle2(1, 0));
            vC[1] = vA[1] + vb1;

            pipe3 = vB[3];
            vFloat vb2 = shufpd(pipe2, pipe3, Shuffle2(1, 0));
            vC[2] = vA[2] + vb2;

            pipe0 = vB[4];
            vFloat vb3 = shufpd(pipe3, pipe0, Shuffle2(1, 0));
            vC[3] = vA[3] + vb3;

            vA += 4;
            vB += 4;
            vC += 4;
        }

        /*  After the main loop, there could be zero, one, two, or three more
            vector blocks to process.  We handle those here with code that is
            essentially a subset of the main loop.
        */

        if (2 <= vN)
        {
            vN -= 2;

            vFloat pipe1;

            pipe1 = vB[1];

            vFloat vb0 = shufpd(pipe0, pipe1, Shuffle2(1, 0));
            pipe0 = vB[2];
            vFloat vb1 = shufpd(pipe1, pipe0, Shuffle2(1, 0));

            vC[0] = vA[0] + vb0;
            vC[1] = vA[1] + vb1;

            vA += 2;
            vB += 2;
            vC += 2;
        }

        if (1 <= vN)
        {
            vFloat pipe1;

            pipe1 = vB[1];

            vFloat vb0 = shufpd(pipe0, pipe1, Shuffle2(1, 0));

            vC[0] = vA[0] + vb0;
        }

    #else   // Architecture.

        /*  For architectures for which we do not have SIMD code, use normal
            scalar code.
        */

        N = -N;
        A -= N;
        B -= N;
        C -= N;
        for (; N < 0; ++N)
            C[N] = A[N] + B[N];

    #endif  // Architecture.
}


/*  vAddB12 implements vAdd given that each of A and C is 0 modulo 16, B is 12
    modulo 16 and N is a multiple of ElementsPerVector.

    This routine uses SIMD constructions that are specific to the Intel
    architectures.  (That is, the IA-32 and EM64T architectures, called "i386"
    and "x86_64" by various Apple tools.)
*/
static inline void vAddB12(const float *A, const float *B, float *C, long N)
{
    #if defined __i386__ || defined __x86_64__  // Architecture.

        if (N <= 0)
            return;

        /*  Convert scalar pointers to vector pointers and scalar length
            (number of elements) to vector length (number of vector blocks).

            vB is set to point to the start of the aligned vector block into
            which B points.
        */
        const vFloat *vA = (const vFloat *) A;
        const vFloat *vB = (const vFloat *) (B-3);
              vFloat *vC = (      vFloat *) C;
        long vN = N / ElementsPerVector;

        /*  This code works through the arrays backward, from high addresses to
            low addresses.  This is because the Intel instruction set does not
            provide a good way to extract the four bytes we want from one
            register and the twelve we want from another without overwriting
            other bytes that we want to preserve.  So we would have to copy the
            bytes to preserve them.  Working backward allows us to use a
            different extraction pattern for which that are good instructions.
        */

        /*  Since B is unaligned with respect to vector blocks, we cannot load
            data directly from it using vector instructions.  Instead, we will
            construct a pipeline or buffer of data coming from B.  Aligned data
            will be loaded into the pipeline using vector instructions.  Once
            the data is in registers, there are vector instructions we can use
            to shift it to be aligned.
        */

        vA += vN;
        vB += vN;
        vC += vN;

        // Prime the pipeline.
        vFloat pipe3 = pshufd(vB[0], Shuffle4(3, 0, 1, 2));

        /*  This main loop process four vector blocks in each iteration, so we
            execute it as long as there are at least four more blocks to do.
        */
        while (4 <= vN)
        {
            vB -= 4;
            vA -= 4;
            vC -= 4;
            vN -= 4;

            vFloat pipe0, pipe1, pipe2;

            pipe2 = pshufd(vB[3], Shuffle4(3, 0, 1, 2));
            pipe3 = movss(pipe3, pipe2);
            vC[3] = vA[3] + pipe3;

            pipe1 = pshufd(vB[2], Shuffle4(3, 0, 1, 2));
            pipe2 = movss(pipe2, pipe1);
            vC[2] = vA[2] + pipe2;

            pipe0 = pshufd(vB[1], Shuffle4(3, 0, 1, 2));
            pipe1 = movss(pipe1, pipe0);
            vC[1] = vA[1] + pipe1;

            pipe3 = pshufd(vB[0], Shuffle4(3, 0, 1, 2));
            pipe0 = movss(pipe0, pipe3);
            vC[0] = vA[0] + pipe0;
        }

        /*  After the main loop, there could be zero, one, two, or three more
            vector blocks to process.  We handle those here with code that is
            essentially a subset of the main loop.
        */

        if (2 <= vN)
        {
            vN -= 2;
            vA -= 2;
            vB -= 2;
            vC -= 2;

            vFloat pipe2;

            pipe2 = pshufd(vB[1], Shuffle4(3, 0, 1, 2));
            pipe3 = movss(pipe3, pipe2);

            vC[1] = vA[1] + pipe3;

            pipe3 = pshufd(vB[0], Shuffle4(3, 0, 1, 2));
            pipe2 = movss(pipe2, pipe3);

            vC[0] = vA[0] + pipe2;
        }

        if (1 <= vN)
        {
            vA -= 1;
            vB -= 1;
            vC -= 1;

            vFloat pipe2;

            pipe2 = pshufd(vB[0], Shuffle4(3, 0, 1, 2));
            pipe3 = movss(pipe3, pipe2);

            vC[0] = vA[0] + pipe3;
        }

    #else   // Architecture.

        /*  For architectures for which we do not have SIMD code, use normal
            scalar code.
        */

        N = -N;
        A -= N;
        B -= N;
        C -= N;
        for (; N < 0; ++N)
            C[N] = A[N] + B[N];

    #endif  // Architecture.
}


// vAddScalar implements vAdd.
static inline void vAddScalar(
    const float *A, const float *B, float *C, long N)
{
    #if 0
        for (long i = 0; i < N; ++i)
            C[i] = A[i] + B[i];
    #else
        /*  Ideally, we would use the simple loop above, and the compiler
            would generate good assembly code for it.  Unfortunately, GCC does
            not generate the best code, and sometimes we need to help it along.
            The code below eliminates a variable (it only needs N instead of
            both i and N), and this is enough to improve the execution time on
            a Xeon (with a particular version of GCC, et cetera).
        */
        N = -N;
        A -= N;
        B -= N;
        C -= N;
        for (; N < 0; ++N)
            C[N] = A[N] + B[N];
    #endif
}


void vAdd(const float *A, const float *B, float *C, long N)
{
    /*  Trim the front:  Process individual elements at the start until the
        output is aligned.
    */
    for (; !IsAligned(C) && 0 < N; --N)
        *C++ = *A++ + *B++;

    /*  Trim the back:  Process individual elements at the end until the number
        of elements left is a multiple of the number in a vector block.  This
        allows us to execute the main loop later without worrying about
        residue.
    */
    while (N % ElementsPerVector)
    {
        --N;
        C[N] = A[N] + B[N];
    }

    /*  Sort A and B according to their residues, to reduce the number of cases
        we have to test.  (Obviously, this works only with commutative
        operations.)
    */
    if (Residue(B) < Residue(A))
        Swap(A, B);

    // If A is vector-block aligned, dispatch based on residue of B.
    if (IsAligned(A))
        switch (Residue(B))
        {
            case  0: vAddB00(A, B, C, N); return;
            case  4: vAddB04(A, B, C, N); return;
            case  8: vAddB08(A, B, C, N); return;
            case 12: vAddB12(A, B, C, N); return;
        }

    // Neither A nor B is aligned.
    vAddScalar(A, B, C, N);
}
