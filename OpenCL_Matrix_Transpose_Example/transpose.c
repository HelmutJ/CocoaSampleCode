//
// File:       transpose.c
//
// Abstract:   This example shows how to efficiently perform a transpose of a matrix composed
//             of M x N power-of-two elements for GPU architectures which require specific
//             memory addressing to avoid memory bank conflicts. 
//
//             Transposing large power-of-two matrices naively can easily cause bank 
//             conflicts which can severly affect the performance.
//
//             With appropriate padding and choice of local block size, good performance 
//             can be ensured.
//
//             In this example 64 work items are issued per work-group which individually 
//             operate small 32x2 sections to fill a 32x32 sub-matrix (over 8 iterations). 
//             The final 32 x 32 sub-matrix is transposed locally using local memory 
//             with one column padding to avoid bank conflicts.   Performing the transpose 
//             in local memory allows the reads and writes to global memory to be coalesced.
//
//             The extra column padding is used to offset the write addresses, so that
//             they don't conflict with the read requests. 
//
//             Using a padding of 32 (or any odd multiple of GROUP_DIMX = 32) ensures that
//             the reads and writes for each element in global memory will be offset and 
//             not operate on the same memory bank/channel/port.  
//
//             This is important for the global memory write operations, since the column 
//             major indices are non-sequential and can cause global memory bank conflicts.
//
//             Global memory read requests will operate on sequential indices for the 
//             row-major elements, and will not conflict.
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

#include <libc.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <OpenCL/opencl.h>
#include <mach/mach_time.h>
#include <math.h>

/////////////////////////////////////////////////////////////////////////////

#define PADDING         (32)

#define GROUP_DIMX      (32)
#define LOG_GROUP_DIMX  (5)
#define GROUP_DIMY      (2)

#define WIDTH           (256)
#define HEIGHT          (4096)

static int iterations = 100;
static int width      = 256;
static int height     = 4096;

/////////////////////////////////////////////////////////////////////////////

static char *
load_program_source(const char *filename)
{
    struct stat statbuf;
    FILE        *fh;
    char        *source;

    fh = fopen(filename, "r");
    if (fh == 0)
        return 0;

    stat(filename, &statbuf);
    source = (char *) malloc(statbuf.st_size + 1);
    fread(source, statbuf.st_size, 1, fh);
    source[statbuf.st_size] = '\0';

    return source;
}

/////////////////////////////////////////////////////////////////////////////

int main(int argc, char **argv)
{
    uint64_t         t0, t1, t2;
    int              err;
    cl_device_id     device_id;
    cl_context       context;
    cl_kernel        kernel;
    cl_command_queue queue;
    cl_program       program;
    cl_mem			 dst, src;

    // Create some random input data on the host 
    //
    float *h_data = malloc(width * height * sizeof(float));
    int i, j;
    for (i = 0; i < height; i++)
    {
        for (j = 0; j < width; j++)
        {
            h_data[i*width + j] = 10.0f * ((float) rand() / (float) RAND_MAX);
        }
    }

    // Connect to a GPU compute device
    //
    int gpu = 1;
    err = clGetDeviceIDs(NULL, gpu ? CL_DEVICE_TYPE_GPU : CL_DEVICE_TYPE_CPU, 1, &device_id, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to create a device group!\n");
        return EXIT_FAILURE;
    }
  
    // Create a compute context 
    //
    context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
    if (!context)
    {
        printf("Error: Failed to create a compute context!\n");
        return EXIT_FAILURE;
    }

    // Create a command queue
    //
    queue = clCreateCommandQueue(context, device_id, 0, &err);
    if (!queue)
    {
        printf("Error: Failed to create a command queue!\n");
        return EXIT_FAILURE;
    }

    // Load the compute program from disk into a cstring buffer
    //
    char *source = load_program_source("transpose_kernel.cl");
    if(!source)
    {
        printf("Error: Failed to load compute program from file!\n");
        return EXIT_FAILURE;    
    }

    // Create the compute program from the source buffer
    //
    program = clCreateProgramWithSource(context, 1, (const char **) & source, NULL, &err);
    if (!program || err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute program!\n");
        return EXIT_FAILURE;
    }

    // Build the program executable
    //
    err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        size_t len;
        char buffer[2048];

        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        return EXIT_FAILURE;
    }

    // Create the compute kernel from within the program
    //
    kernel = clCreateKernel(program, "transpose", &err);
    if (!kernel || err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute kernel!\n");
        return EXIT_FAILURE;
    }

    // Create the input array on the device
    //
    src = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * width * height, NULL, NULL);
    if (!src)
    {
        printf("Error: Failed to allocate source array!\n");
        return EXIT_FAILURE;
    }

    // Fill the input array with the host allocated random data
    //
    err = clEnqueueWriteBuffer(queue, src, true, 0, sizeof(float) * width * height, h_data, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to write to source array!\n");
        return EXIT_FAILURE;
    }

    // Create the output array on the device
    //
    dst = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(float) * width * (height + PADDING), NULL, NULL);
    if (!dst)
    {
        printf("Error: Failed to allocate destination array!\n");
        return EXIT_FAILURE;
    }

    // Set the kernel arguments prior to execution
    //
    err  = clSetKernelArg(kernel,  0, sizeof(cl_mem), &dst);
    err |= clSetKernelArg(kernel,  1, sizeof(cl_mem), &src);
    err |= clSetKernelArg(kernel,  2, sizeof(float) * GROUP_DIMX * (GROUP_DIMX + 1), NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to set kernel arguments!\n");
        return EXIT_FAILURE;
    }

    // Determine the global and local dimensions for the execution
    //
    size_t global[2], local[2];
    global[0] = width * GROUP_DIMY;
    global[1] = height / GROUP_DIMX;
    local[0] = GROUP_DIMX * GROUP_DIMY;
    local[1] = 1;

    // Execute once without timing to guarantee data is on the device
    //
    err = clEnqueueNDRangeKernel(queue, kernel, 2, NULL, global, local, 0, NULL, NULL);
    if (err)
    {
        printf("Error: Failed to execute kernel!\n");
        return EXIT_FAILURE;
    }
    clFinish(queue);

    // Start the timing loop and execute the kernel over several iterations  
    //
    printf("Performing Matrix Transpose [%d x %d]...\n", width, height);

    int k;
    err = CL_SUCCESS;
    t0 = t1 = mach_absolute_time();
    for (k = 0 ; k < iterations; k++)
        err |= clEnqueueNDRangeKernel(queue, kernel, 2, NULL, global, local, 0, NULL, NULL);

    clFinish(queue);
    t2 = mach_absolute_time();
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to execute kernel!\n");
        return EXIT_FAILURE;
    }

    // Calculate the total bandwidth that was obtained on the device for all memory transfers
    //
    struct mach_timebase_info info;
    mach_timebase_info(&info);
    double t = 1e-9 * (t2 - t1) * info.numer / info.denom;
    printf("Bandwidth Achieved = %f GB/sec\n", 2e-9 * sizeof(float) * width * height * iterations / t);

    // Verify the results are correct by performing the matrix transpose on the host
    //
    float *reference = (float *) malloc(sizeof(float) * width * height);
    int l;
    for (k = 0; k < height; k++)
        for (l = 0; l < width; l++)
            reference[l*height + k] = h_data[k*width + l];

    float *h_result = (float *) malloc(sizeof(float) * width * (height + PADDING));
    memset(h_result, 0, sizeof(float)*width*(height + PADDING));

    // Read back the results that were computed on the device
    //
    err = clEnqueueReadBuffer( queue, dst, true, 0, sizeof(float) * width * (height + PADDING), h_result, 0, NULL, NULL );  
    if (err)
    {
        printf("Error: Failed to read back results from the device!\n");
        return EXIT_FAILURE;
    }

    // Validate the matrix transpose by comparing the device results
    //
    float error = 0.0f;
    for (l = 0; l < width; l++)
    {
        for (k = 0; k < height; k++)
        {
            float diff = fabs(reference[l*height + k] - h_result[l*(height + PADDING) + k]);
            error = diff > error ? diff : error;
        }
    }

    free(h_data);
    free(h_result);
    
    clReleaseMemObject(src);
    clReleaseMemObject(dst);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    if (error > 1e-5)
    {
        printf("Error:  Incorrect results obtained! Max error = %f\n", error);
        return EXIT_FAILURE;
    }
    else
    {
        printf("Results Validated!\n");
    }
    
    return 0;
}
