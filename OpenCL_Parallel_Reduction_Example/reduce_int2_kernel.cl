//
// File:       reduce_int2_kernel.cl
//
// Abstract:   This example shows how to perform an efficient parallel reduction using OpenCL.
//             Reduce is a common data parallel primitive which can be used for variety
//             of different operations -- this example computes the global sum for a large
//             number of values, and includes kernels for integer and floating point vector
//             types.
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef GROUP_SIZE
#define GROUP_SIZE (64)
#endif

#ifndef OPERATIONS
#define OPERATIONS (1)
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////

#define LOAD_GLOBAL_I2(s, i) \
    vload2((size_t)(i), (__global const int*)(s))

#define STORE_GLOBAL_I2(s, i, v) \
    vstore2((v), (size_t)(i), (__global int*)(s))

////////////////////////////////////////////////////////////////////////////////////////////////////

#define LOAD_LOCAL_I1(s, i) \
    ((__local const int*)(s))[(size_t)(i)]

#define STORE_LOCAL_I1(s, i, v) \
    ((__local int*)(s))[(size_t)(i)] = (v)

#define LOAD_LOCAL_I2(s, i) \
    (int2)( (LOAD_LOCAL_I1(s, i)), \
                 (LOAD_LOCAL_I1(s, i + GROUP_SIZE)))

#define STORE_LOCAL_I2(s, i, v) \
    STORE_LOCAL_I1(s, i, (v)[0]); \
    STORE_LOCAL_I1(s, i + GROUP_SIZE, (v)[1])

#define ACCUM_LOCAL_I2(s, i, j) \
{ \
    int2 x = LOAD_LOCAL_I2(s, i); \
    int2 y = LOAD_LOCAL_I2(s, j); \
    int2 xy = (x + y); \
    STORE_LOCAL_I2(s, i, xy); \
}

////////////////////////////////////////////////////////////////////////////////////////////////////

__kernel void
reduce(
    __global int2 *output, 
    __global const int2 *input, 
    __local int2 *shared,
    const unsigned int n)
{
    const int2 zero = (int2)(0.0f, 0.0f);
    const unsigned int group_id = get_global_id(0) / get_local_size(0);
    const unsigned int group_size = GROUP_SIZE;
    const unsigned int group_stride = 2 * group_size;
    const size_t local_stride = group_stride * group_size; 
    
    unsigned int op = 0;
    unsigned int last = OPERATIONS - 1;
    for(op = 0; op < OPERATIONS; op++)
    {
        const unsigned int offset = (last - op);
        const size_t local_id = get_local_id(0) + offset;

        STORE_LOCAL_I2(shared, local_id, zero);
        
        size_t i = group_id * group_stride + local_id; 
        while (i < n)
        {
            int2 a = LOAD_GLOBAL_I2(input, i);
            int2 b = LOAD_GLOBAL_I2(input, i + group_size);
            int2 s = LOAD_LOCAL_I2(shared, local_id);
            STORE_LOCAL_I2(shared, local_id, (a + b + s));
            i += local_stride;
        } 
    
	barrier(CLK_LOCAL_MEM_FENCE);	    
    #if (GROUP_SIZE >= 512) 
        if (local_id < 256) { ACCUM_LOCAL_I2(shared, local_id, local_id + 256); }
    #endif
        
	barrier(CLK_LOCAL_MEM_FENCE);	
    #if (GROUP_SIZE >= 256) 
        if (local_id < 128) { ACCUM_LOCAL_I2(shared, local_id, local_id + 128); }
    #endif    
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 128) 
        if (local_id <  64) { ACCUM_LOCAL_I2(shared, local_id, local_id +  64); }
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 64) 
        if (local_id <  32) { ACCUM_LOCAL_I2(shared, local_id, local_id +  32); } 
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 32) 
        if (local_id <  16) { ACCUM_LOCAL_I2(shared, local_id, local_id +  16); } 
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 16) 
        if (local_id <   8) { ACCUM_LOCAL_I2(shared, local_id, local_id +   8); }
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 8) 
        if (local_id <   4) { ACCUM_LOCAL_I2(shared, local_id, local_id +   4); } 
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 4) 
        if (local_id <   2) { ACCUM_LOCAL_I2(shared, local_id, local_id +   2); } 
    #endif
    
	barrier(CLK_LOCAL_MEM_FENCE);
    #if (GROUP_SIZE >= 2) 
        if (local_id <   1) { ACCUM_LOCAL_I2(shared, local_id, local_id +   1); } 
    #endif

    }

	barrier(CLK_LOCAL_MEM_FENCE);
    if (get_local_id(0) == 0)
    {
        int2 v = LOAD_LOCAL_I2(shared, 0);
        STORE_GLOBAL_I2(output, group_id, v);
    }        
}
