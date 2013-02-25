/*
File:  vector.h

Abstract:
    This file declares some things needed or useful for working with
    vector code.

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
#if !defined vector_h
#define vector_h


#include <stdint.h> // We need uintptr_t.


/*  Several implementations of vector types are provided as illustration.
    VectorImplementationSelect picks one of them to use.
*/
#define VectorImplementationSelect 0

#if VectorImplementationSelect == 0

    // Define vector types from processor manufacturer specifications.
    #if defined __i386__ || defined __x86_64__
        #include <emmintrin.h>  // Define entities up to and including SSE2.
        typedef __m128 vFloat;
        /*  Intel headers are available in steps including:
                mmintrin.h:  MMX.
                xmmintrin.h:  SSE.
                emmintrin.h:  SSE2.
                pmmintrin.h:  SSE3.
                tmmintrin.h:  SSSE3.
                smmintrin.h:  SSSE4 vector operations.
                nmmintrin.h:  SSSE4 string operations.

            Intel vector types include:
                __mm128:  four floats.
                __m128d:  2 doubles.
                __m128i:  16 8-bit, 8 16-bit, 4 32-bit, or 2 64-bit integers.
        */
    #elif defined __ppc__ || defined __ppc64__
        #include <altivec.h>
        typedef vector float vFloat;
        /*  AltiVec extensions can be used either by specifying "-faltivec"
            in the GCC compile command line or by including <altivec.h> and
            specifying "-maltivec" in the compile command line.

            PowerPC/AltiVec vector types include:
                vector float:  four floats.
                vector double:  two doubles.
                vector signed char, vector unsigned char:  16 8-bit integers.
                vector signed short, vector unsigned short:  8 16-bit integers.
                vector signed int, vector unsigned int:  4 32-bit integers.
        */
    #else
        // Define a vector type using a GCC extension to C.
        typedef float vFloat __attribute__((__vector_size__(16)));
    #endif

#elif VectorImplementationSelect == 1

    // Define vector types using Accelerate framework.
    #if defined __ppc__ || defined __ppc64__
        #include <altivec.h>
    #endif
    #include <Accelerate/Accelerate.h>

#elif VectorImplementationSelect == 2

    // Define a vector type using a GCC extension to C.
    typedef float vFloat __attribute__((__vector_size__(16)));

#endif  // VectorImplementationSelect == 0


#define FloatsPerVector 4


/*  Return the residue modulo the vector block size of an address.  This is the
    byte offset of an address within a vector block.
*/
#define Residue(a)          ((uintptr_t) (a) % sizeof(vFloat))


// Evaluate to true iff p is aligned to a multiple of the vector size.
#define IsAligned(p)    (Residue(p) == 0)


#endif  // !defined vector_h
