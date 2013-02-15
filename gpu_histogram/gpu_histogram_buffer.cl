/*********************************************************************************************
//
//  OpenCL Histogram kernels for GPU
// 
// File:       gpu_histogram_buffer.cl
//
// Abstract:   This example demonstrates a CL histogram implementation using buffers
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
//  Copyright:	(c) 2008-2009 by Apple Inc. All Rights Reserved.
//
*********************************************************************************************/

#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable

//
// sum partial histogram results into final histogram bins
//
// num_groups is the number of work-groups used to compute partial histograms.
// partial_histogram is an array of num_groups * (257 * 3 * 32-bits/entry) entries
// we store 257 Red bins, followed by 257 Green bins and then the 257 Blue bins.
//
// final summed results are returned in histogram.
//
kernel
void histogram_sum_partial_results_fp(global uint *partial_histogram, int num_groups, global uint *histogram)
{
    int     tid = (int)get_global_id(0);
    int     group_id = (int)get_group_id(0);
    int     group_indx;
    int     n = num_groups;
    local uint  tmp_histogram[257 * 3];

    int     first_workitem_not_in_first_group = ((get_local_id(0) == 0) && group_id);
    
    tid += group_id;
    int     tid_first = tid - 1;
    if (first_workitem_not_in_first_group)
        tmp_histogram[tid_first] = partial_histogram[tid_first];
    
    tmp_histogram[tid] = partial_histogram[tid];
    
    group_indx = 257*3;
    while (--n > 0)
    {
        if (first_workitem_not_in_first_group)
            tmp_histogram[tid_first] += partial_histogram[tid_first];
            
        tmp_histogram[tid] += partial_histogram[group_indx+tid];
        group_indx += 257*3;
    }
    
    if (first_workitem_not_in_first_group)
        histogram[tid_first] = tmp_histogram[tid_first];
    histogram[tid] = tmp_histogram[tid];
}

//
// this kernel takes a RGBA 32-bit FP / channel input image and produces a partial histogram.
// the kernel is executed over multiple work-groups.  for each work-group a partial histogram is generated
// partial_histogram is an array of num_groups * (257 * 3 * 32-bits/entry) entries
// we store 257 Red bins, followed by 257 Green bins and then the 257 Blue bins.
//
kernel
void histogram_rgba_fp32(global float4 *image_ptr, int image_width, int image_height, global uint *histogram)
{
    int     tid = (int)get_local_id(0);
    int     gid = (int)get_global_id(0);
    int     local_size = (int)get_local_size(0);
    int     group_indx = (int)get_group_id(0) * 257 * 3;
    
    local uint  tmp_histogram[257 * 3];
        
    int     j = 257 * 3;
    int     indx = 0;
    
    // clear the local buffer that will generate the partial histogram
    do
    {
        if (tid < j)
            tmp_histogram[indx+tid] = 0;
            
        j -= local_size;
        indx += local_size;
    } while (j > 0);
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (gid < (image_width * image_height))
    {                
        float4  clr = image_ptr[gid];
    
        ushort   indx;
        indx = convert_ushort_sat(min(clr.x, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[indx]);

        indx = convert_ushort_sat(min(clr.y, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[257+indx]);

        indx = convert_ushort_sat(min(clr.z, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[514+indx]);
    }        

    barrier(CLK_LOCAL_MEM_FENCE);

    // copy the partial histogram to appropriate location in histogram given by group_indx
    if (local_size >= (257 * 3))
    {
        if (tid < (257 * 3))
            histogram[group_indx + tid] = tmp_histogram[tid];
    }
    else
    {
        j = 257 * 3;
        indx = 0;
        do 
        {
            if (tid < j)
                histogram[group_indx + indx + tid] = tmp_histogram[indx + tid];
                
            j -= local_size;
            indx += local_size;
        } while (j > 0);
    }
}

//
// this kernel takes a RGBA 16-bit FP / channel input image and produces a partial histogram.
// the kernel is executed over multiple work-groups.  for each work-group a partial histogram is generated
// partial_histogram is an array of num_groups * (257 * 3 * 32-bits/entry) entries
// we store 257 Red bins, followed by 257 Green bins and then the 257 Blue bins.
//
kernel
void histogram_rgba_fp16(global half *image_ptr, int image_width, int image_height, global uint *histogram)
{
    int     tid = (int)get_local_id(0);
    int     gid = (int)get_global_id(0);
    int     local_size = (int)get_local_size(0);
    int     group_indx = (int)get_group_id(0) * 257 * 3;
    
    local uint  tmp_histogram[257 * 3];
        
    int     j = 257 * 3;
    int     indx = 0;
    
    // clear the local buffer that will generate the partial histogram
    do
    {
        if (tid < j)
            tmp_histogram[indx+tid] = 0;
            
        j -= local_size;
        indx += local_size;
    } while (j > 0);
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (gid < (image_width * image_height))
    {                
        float4  clr = vloada_half4(gid, image_ptr);
    
        ushort   indx;
        indx = convert_ushort_sat(min(clr.x, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[indx]);

        indx = convert_ushort_sat(min(clr.y, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[257+indx]);

        indx = convert_ushort_sat(min(clr.z, 1.0f) * 256.0f);
        atom_inc(&tmp_histogram[514+indx]);
    }        

    barrier(CLK_LOCAL_MEM_FENCE);

    // copy the partial histogram to appropriate location in histogram given by group_indx
    if (local_size >= (257 * 3))
    {
        if (tid < (257 * 3))
            histogram[group_indx + tid] = tmp_histogram[tid];
    }
    else
    {
        j = 257 * 3;
        indx = 0;
        do 
        {
            if (tid < j)
                histogram[group_indx + indx + tid] = tmp_histogram[indx + tid];
                
            j -= local_size;
            indx += local_size;
        } while (j > 0);
    }
}


/***************************************************************************************************************/

//
// sum partial histogram results into final histogram bins
//
// num_groups is the number of work-groups used to compute partial histograms.
// partial_histogram is an array of num_groups * (256 * 3 * 32-bits/entry) entries
// we store 256 Red bins, followed by 256 Green bins and then the 256 Blue bins.
//
// final summed results are returned in histogram.
//
kernel
void histogram_sum_partial_results_unorm8(global uint *partial_histogram, int num_groups, global uint *histogram)
{
    int     tid = (int)get_global_id(0);
    int     group_indx;
    int     n = num_groups;
    local uint  tmp_histogram[256 * 3];

    tmp_histogram[tid] = partial_histogram[tid];
    
    group_indx = 256*3;
    while (--n > 0)
    {
        tmp_histogram[tid] += partial_histogram[group_indx + tid];
        group_indx += 256*3;
    }
    
    histogram[tid] = tmp_histogram[tid];
}

//
// this kernel takes a RGBA 8-bit / channel input image and produces a partial histogram.
// the kernel is executed over multiple work-groups.  for each work-group a partial histogram is generated
// partial_histogram is an array of num_groups * (256 * 3 * 32-bits/entry) entries
// we store 256 Red bins, followed by 256 Green bins and then the 256 Blue bins.
//
kernel
void histogram_rgba_unorm8(global uchar4 *image_ptr, int image_width, int image_height, global uint *histogram)
{
    int     tid = (int)get_local_id(0);
    int     gid = (int)get_global_id(0);
    int     local_size = (int)get_local_size(0);
    int     group_indx = (int)get_group_id(0) * 256 * 3;
    
    local uint  tmp_histogram[256 * 3];
        
    int     j = 256 * 3;
    int     indx = 0;
    
    // clear the local buffer that will generate the partial histogram
    do
    {
        if (tid < j)
            tmp_histogram[indx+tid] = 0;
            
        j -= local_size;
        indx += local_size;
    } while (j > 0);
    
    barrier(CLK_LOCAL_MEM_FENCE);
    
    if (gid < (image_width * image_height))
    {                
        uchar4 clr = image_ptr[gid];
    
        atom_inc(&tmp_histogram[clr.x]);
        atom_inc(&tmp_histogram[256 + (uint)clr.y]);
        atom_inc(&tmp_histogram[512 + (uint)clr.z]);
    }        

    barrier(CLK_LOCAL_MEM_FENCE);

    // copy the partial histogram to appropriate location in histogram given by group_indx
    if (local_size >= (256 * 3))
    {
        if (tid < (256 * 3))
            histogram[group_indx + tid] = tmp_histogram[tid];
    }
    else
    {
        j = 256 * 3;
        indx = 0;
        do 
        {
            if (tid < j)
                histogram[group_indx + indx + tid] = tmp_histogram[indx + tid];
                
            j -= local_size;
            indx += local_size;
        } while (j > 0);
    }
}


