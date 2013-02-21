//
// File:       reduce.c
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

#include <libc.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach_time.h>
#include <math.h>

#include <OpenCL/opencl.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

#define MIN_ERROR       (1e-7)
#define MAX_GROUPS      (64)
#define MAX_WORK_ITEMS  (64)
#define SEPARATOR       ("----------------------------------------------------------------------\n")

static int iterations = 1000;
static int count      = 1024 * 1024;
static int channels   = 1;
static bool integer   = true;

////////////////////////////////////////////////////////////////////////////////////////////////////

uint64_t
current_time()
{
    return mach_absolute_time();
}
	
double 
subtract_time_in_seconds( uint64_t endtime, uint64_t starttime )
{    
	static double conversion = 0.0;
	uint64_t difference = endtime - starttime;
	if( 0 == conversion )
	{
		mach_timebase_info_data_t timebase;
		kern_return_t kError = mach_timebase_info( &timebase );
		if( kError == 0  )
			conversion = 1e-9 * (double) timebase.numer / (double) timebase.denom;
    }
		
	return conversion * (double) difference; 
}

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

////////////////////////////////////////////////////////////////////////////////////////////////////

void reduce_validate_float(float *data, int size, float * result)
{
    int i;
    float sum = data[0];
    float c = (float)0.0f;              
    for (i = 1; i < size; i++)
    {
        float y = data[i] - c;  
        float t = sum + y;      
        c = (t - sum) - y;  
        sum = t;            
    }
    result[0] = sum;
}

void reduce_validate_float2(float *data, int size, float *result)
{
    int i;
    float c[2] = { 0.0f, 0.0f }; 
    
    result[0] = data[0*2+0];
    result[1] = data[0*2+1];
    
    for (i = 1; i < size; i++)
    {
        float y[2] = { data[i*2+0] - c[0], data[i*2+1] - c[1] };  
        float t[2] = { result[0] + y[0], result[1] + y[1] };  

        c[0] = (t[0] - result[0]) - y[0];
        c[1] = (t[1] - result[1]) - y[1];
        
        result[0] = t[0];
        result[1] = t[1];
    }
}

void reduce_validate_float4(float *data, int size, float *result)
{
    int i;
    float c[4] = { 0.0f, 0.0f, 0.0f, 0.0f}; 
    
    result[0] = data[0*4+0];
    result[1] = data[0*4+1];
    result[2] = data[0*4+2];
    result[3] = data[0*4+3];
    
    for (i = 1; i < size; i++)
    {
        float y[4] = { data[i*4+0] - c[0], data[i*4+1] - c[1], data[i*4+2] - c[2], data[i*4+3] - c[3] };  
        float t[4] = { result[0] + y[0], result[1] + y[1], result[2] + y[2], result[3] + y[3] };  

        c[0] = (t[0] - result[0]) - y[0];
        c[1] = (t[1] - result[1]) - y[1];
        c[2] = (t[2] - result[2]) - y[2];
        c[3] = (t[3] - result[3]) - y[3];
        
        result[0] = t[0];
        result[1] = t[1];
        result[2] = t[2];
        result[3] = t[3];
    }
}

void reduce_validate_int(int *data, int size, int * result)
{
    int i;
    int sum = data[0];
    int c = (int)0.0f;              
    for (i = 1; i < size; i++)
    {
        int y = data[i] - c;  
        int t = sum + y;      
        c = (t - sum) - y;  
        sum = t;            
    }
    result[0] = sum;
}

void reduce_validate_int2(int *data, int size, int *result)
{
    int i;
    int c[2] = { 0.0f, 0.0f }; 
    
    result[0] = data[0*2+0];
    result[1] = data[0*2+1];
    
    for (i = 1; i < size; i++)
    {
        int y[2] = { data[i*2+0] - c[0], data[i*2+1] - c[1] };  
        int t[2] = { result[0] + y[0], result[1] + y[1] };  

        c[0] = (t[0] - result[0]) - y[0];
        c[1] = (t[1] - result[1]) - y[1];
        
        result[0] = t[0];
        result[1] = t[1];
    }
}

void reduce_validate_int4(int *data, int size, int *result)
{
    int i;
    int c[4] = { 0.0f, 0.0f, 0.0f, 0.0f}; 
    
    result[0] = data[0*4+0];
    result[1] = data[0*4+1];
    result[2] = data[0*4+2];
    result[3] = data[0*4+3];
    
    for (i = 1; i < size; i++)
    {
        int y[4] = { data[i*4+0] - c[0], data[i*4+1] - c[1], data[i*4+2] - c[2], data[i*4+3] - c[3] };  
        int t[4] = { result[0] + y[0], result[1] + y[1], result[2] + y[2], result[3] + y[3] };  

        c[0] = (t[0] - result[0]) - y[0];
        c[1] = (t[1] - result[1]) - y[1];
        c[2] = (t[2] - result[2]) - y[2];
        c[3] = (t[3] - result[3]) - y[3];
        
        result[0] = t[0];
        result[1] = t[1];
        result[2] = t[2];
        result[3] = t[3];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void create_reduction_pass_counts(
    int count, 
    int max_group_size,    
    int max_groups,
    int max_work_items, 
    int *pass_count, 
    size_t **group_counts, 
    size_t **work_item_counts,
    int **operation_counts,
    int **entry_counts)
{
    int work_items = (count < max_work_items * 2) ? count / 2 : max_work_items;
    if(count < 1)
        work_items = 1;
        
    int groups = count / (work_items * 2);
    groups = max_groups < groups ? max_groups : groups;

    int max_levels = 1;
    int s = groups;

    while(s > 1) 
    {
        int work_items = (s < max_work_items * 2) ? s / 2 : max_work_items;
        s = s / (work_items*2);
        max_levels++;
    }
 
    *group_counts = (size_t*)malloc(max_levels * sizeof(size_t));
    *work_item_counts = (size_t*)malloc(max_levels * sizeof(size_t));
    *operation_counts = (int*)malloc(max_levels * sizeof(int));
    *entry_counts = (int*)malloc(max_levels * sizeof(int));

    (*pass_count) = max_levels;
    (*group_counts)[0] = groups;
    (*work_item_counts)[0] = work_items;
    (*operation_counts)[0] = 1;
    (*entry_counts)[0] = count;
    if(max_group_size < work_items)
    {
        (*operation_counts)[0] = work_items;
        (*work_item_counts)[0] = max_group_size;
    }
    
    s = groups;
    int level = 1;
   
    while(s > 1) 
    {
        int work_items = (s < max_work_items * 2) ? s / 2 : max_work_items;
        int groups = s / (work_items * 2);
        groups = (max_groups < groups) ? max_groups : groups;

        (*group_counts)[level] = groups;
        (*work_item_counts)[level] = work_items;
        (*operation_counts)[level] = 1;
        (*entry_counts)[level] = s;
        if(max_group_size < work_items)
        {
            (*operation_counts)[level] = work_items;
            (*work_item_counts)[level] = max_group_size;
        }
        
        s = s / (work_items*2);
        level++;
    }
}

/////////////////////////////////////////////////////////////////////////////

int main(int argc, char **argv)
{
    uint64_t         t1 = 0;
    uint64_t         t2 = 0;
    int              err;
    cl_device_id     device_id;
    cl_command_queue commands;
    cl_context       context;
    cl_mem			 output_buffer;
    cl_mem           input_buffer;
    cl_mem           partials_buffer;
    size_t           typesize;
    int              pass_count = 0;
    size_t*          group_counts = 0;
    size_t*          work_item_counts = 0;
    int*             operation_counts = 0;
    int*             entry_counts = 0;
    int              use_gpu = 1;
    
    int i;
    int c;
    
    // Parse command line options
    //
    for( i = 0; i < argc && argv; i++)
    {
        if(!argv[i])
            continue;
            
        if(strstr(argv[i], "cpu"))
        {
            use_gpu = 0;        
        }
        else if(strstr(argv[i], "gpu"))
        {
            use_gpu = 1;
        }
        else if(strstr(argv[i], "float2"))
        {
            integer = false;
            channels = 2;
        }
        else if(strstr(argv[i], "float4"))
        {
            integer = false;
            channels = 4;
        }
        else if(strstr(argv[i], "float"))
        {
            integer = false;
            channels = 1;
        }
        else if(strstr(argv[i], "int2"))
        {
            integer = true;
            channels = 2;
        }
        else if(strstr(argv[i], "int4"))
        {
            integer = true;
            channels = 4;
        }
        else if(strstr(argv[i], "int"))
        {
            integer = true;
            channels = 1;
        }
    }
    
    // Create some random input data on the host 
    //
    float *float_data = (float*)malloc(count * channels * sizeof(float));
    int *integer_data = (int*)malloc(count * channels * sizeof(int));
    for (i = 0; i < count * channels; i++)
    {
        float_data[i] = ((float) rand() / (float) RAND_MAX);
        integer_data[i] = (int) (255.0f * float_data[i]);
    }

    // Connect to a compute device
    //
    err = clGetDeviceIDs(NULL, use_gpu ? CL_DEVICE_TYPE_GPU : CL_DEVICE_TYPE_CPU, 1, &device_id, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to locate a compute device!\n");
        return EXIT_FAILURE;
    }

    size_t returned_size = 0;
    size_t max_workgroup_size = 0;
    err = clGetDeviceInfo(device_id, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(size_t), &max_workgroup_size, &returned_size);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to retrieve device info!\n");
        return EXIT_FAILURE;
    }

    cl_char vendor_name[1024] = {0};
    cl_char device_name[1024] = {0};
    err = clGetDeviceInfo(device_id, CL_DEVICE_VENDOR, sizeof(vendor_name), vendor_name, &returned_size);
    err|= clGetDeviceInfo(device_id, CL_DEVICE_NAME, sizeof(device_name), device_name, &returned_size);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to retrieve device info!\n");
        return EXIT_FAILURE;
    }

    printf(SEPARATOR);
    printf("Connecting to %s %s...\n", vendor_name, device_name);

    // Load the compute program from disk into a cstring buffer
    //
    typesize = integer ? (sizeof(int)) : (sizeof(float));    
    const char* filename = 0;
    switch(channels)
    {
        case 4:
            filename = integer ? "reduce_int4_kernel.cl" : "reduce_float4_kernel.cl";
            break;
        case 2:
            filename = integer ? "reduce_int2_kernel.cl" : "reduce_float2_kernel.cl";
            break;
        case 1:
            filename = integer ? "reduce_int_kernel.cl" : "reduce_float_kernel.cl";
            break;
        default:
            printf("Invalid channel count specified!\n");
            return EXIT_FAILURE;
    };

    printf(SEPARATOR);
    printf("Loading program '%s'...\n", filename);
    printf(SEPARATOR);

    char *source = load_program_source(filename);
    if(!source)
    {
        printf("Error: Failed to load compute program from file!\n");
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
    commands = clCreateCommandQueue(context, device_id, 0, &err);
    if (!commands)
    {
        printf("Error: Failed to create a command commands!\n");
        return EXIT_FAILURE;
    }

    // Create the input buffer on the device
    //
    size_t buffer_size = typesize * count * channels;
    input_buffer = clCreateBuffer(context, CL_MEM_READ_WRITE, buffer_size, NULL, NULL);
    if (!input_buffer)
    {
        printf("Error: Failed to allocate input buffer on device!\n");
        return EXIT_FAILURE;
    }

    // Fill the input buffer with the host allocated random data
    //
    void *input_data = (integer) ? (void*)integer_data : (void*)float_data;
    err = clEnqueueWriteBuffer(commands, input_buffer, CL_TRUE, 0, buffer_size, input_data, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to write to source array!\n");
        return EXIT_FAILURE;
    }

    // Create an intermediate data buffer for intra-level results
    //
    partials_buffer = clCreateBuffer(context, CL_MEM_READ_WRITE, buffer_size, NULL, NULL);
    if (!partials_buffer)
    {
        printf("Error: Failed to allocate partial sum buffer on device!\n");
        return EXIT_FAILURE;
    }

    // Create the output buffer on the device
    //
    output_buffer = clCreateBuffer(context, CL_MEM_READ_WRITE, buffer_size, NULL, NULL);
    if (!output_buffer)
    {
        printf("Error: Failed to allocate result buffer on device!\n");
        return EXIT_FAILURE;
    }

    // Determine the reduction pass configuration for each level in the pyramid
    //
    create_reduction_pass_counts(
        count, max_workgroup_size, 
        MAX_GROUPS, MAX_WORK_ITEMS, 
        &pass_count, &group_counts, 
        &work_item_counts, &operation_counts,
        &entry_counts);

    // Create specialized programs and kernels for each level of the reduction
    //
    cl_program *programs = (cl_program*)malloc(pass_count * sizeof(cl_program));
    memset(programs, 0, pass_count * sizeof(cl_program));

    cl_kernel *kernels = (cl_kernel*)malloc(pass_count * sizeof(cl_kernel));
    memset(kernels, 0, pass_count * sizeof(cl_kernel));

    for(i = 0; i < pass_count; i++)
    {
        char *block_source = malloc(strlen(source) + 1024);
        size_t source_length = strlen(source) + 1024;
        memset(block_source, 0, source_length);
        
        // Insert macro definitions to specialize the kernel to a particular group size
        //
        const char group_size_macro[] = "#define GROUP_SIZE";
        const char operations_macro[] = "#define OPERATIONS";
        sprintf(block_source, "%s (%d) \n%s (%d)\n\n%s\n", 
            group_size_macro, (int)group_counts[i], 
            operations_macro, (int)operation_counts[i], 
            source);
        
        // Create the compute program from the source buffer
        //
        programs[i] = clCreateProgramWithSource(context, 1, (const char **) & block_source, NULL, &err);
        if (!programs[i] || err != CL_SUCCESS)
        {
            printf("%s\n", block_source);
            printf("Error: Failed to create compute program!\n");
            return EXIT_FAILURE;
        }
    
        // Build the program executable
        //
        err = clBuildProgram(programs[i], 0, NULL, NULL, NULL, NULL);
        if (err != CL_SUCCESS)
        {
            size_t length;
            char build_log[2048];
            printf("%s\n", block_source);
            printf("Error: Failed to build program executable!\n");
            clGetProgramBuildInfo(programs[i], device_id, CL_PROGRAM_BUILD_LOG, sizeof(build_log), build_log, &length);
            printf("%s\n", build_log);
            return EXIT_FAILURE;
        }
    
        // Create the compute kernel from within the program
        //
        kernels[i] = clCreateKernel(programs[i], "reduce", &err);
        if (!kernels[i] || err != CL_SUCCESS)
        {
            printf("Error: Failed to create compute kernel!\n");
            return EXIT_FAILURE;
        }

        free(block_source);
    }
    
    // Do the reduction for each level  
    //
    cl_mem pass_swap;
    cl_mem pass_input = output_buffer;
    cl_mem pass_output = input_buffer;

    for(i = 0; i < pass_count; i++)
    {
        size_t global = group_counts[i] * work_item_counts[i];        
        size_t local = work_item_counts[i];
        unsigned int operations = operation_counts[i];
        unsigned int entries = entry_counts[i];
        size_t shared_size = typesize * channels * local * operations;

        printf("Pass[%4d] Global[%4d] Local[%4d] Groups[%4d] WorkItems[%4d] Operations[%d] Entries[%d]\n",  i, 
            (int)global, (int)local, (int)group_counts[i], (int)work_item_counts[i], operations, entries);

        // Swap the inputs and outputs for each pass
        //
        pass_swap = pass_input;
        pass_input = pass_output;
        pass_output = pass_swap;
        
        err = CL_SUCCESS;
        err |= clSetKernelArg(kernels[i],  0, sizeof(cl_mem), &pass_output);  
        err |= clSetKernelArg(kernels[i],  1, sizeof(cl_mem), &pass_input);
        err |= clSetKernelArg(kernels[i],  2, shared_size,    NULL);
        err |= clSetKernelArg(kernels[i],  3, sizeof(int),    &entries);
        if (err != CL_SUCCESS)
        {
            printf("Error: Failed to set kernel arguments!\n");
            return EXIT_FAILURE;
        }
        
        // After the first pass, use the partial sums for the next input values
        //
        if(pass_input == input_buffer)
            pass_input = partials_buffer;
            
        err = CL_SUCCESS;
        err |= clEnqueueNDRangeKernel(commands, kernels[i], 1, NULL, &global, &local, 0, NULL, NULL);
        if (err != CL_SUCCESS)
        {
            printf("Error: Failed to execute kernel!\n");
            return EXIT_FAILURE;
        }
    }
    
    err = clFinish(commands);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to wait for command queue to finish! %d\n", err);
        return EXIT_FAILURE;
    }

    // Start the timing loop and execute the kernel over several iterations  
    //
    printf(SEPARATOR);
    printf("Timing %d iterations of reduction with %d elements of type %s%s...\n", 
        iterations, count, integer ? "int" : "float", 
        (channels <= 1) ? (" ") : (channels == 2) ? "2" : "4");
    printf(SEPARATOR);

    int k;
    err = CL_SUCCESS;
    t1 = current_time();
    for (k = 0 ; k < iterations; k++)
    {    
        for(i = 0; i < pass_count; i++)
        {
            size_t global = group_counts[i] * work_item_counts[i];        
            size_t local = work_item_counts[i];

            err = clEnqueueNDRangeKernel(commands, kernels[i], 1, NULL, &global, &local, 0, NULL, NULL);
            if (err != CL_SUCCESS)
            {
                printf("Error: Failed to execute kernel!\n");
                return EXIT_FAILURE;
            }
        }
    }
    err = clFinish(commands);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to wait for command queue to finish! %d\n", err);
        return EXIT_FAILURE;
    }
    t2 = current_time();
    
    // Calculate the statistics for execution time and throughput
    //
    double t = subtract_time_in_seconds(t2, t1);
    printf("Exec Time:  %.2f ms\n", 1000.0 * t / (double)(iterations));
    printf("Throughput: %.2f GB/sec\n", 1e-9 * buffer_size * iterations / t);
    printf(SEPARATOR);

    // Read back the results that were computed on the device
    //
    void *computed_result = malloc(typesize * channels);
    memset(computed_result, 0, typesize * channels);
    err = clEnqueueReadBuffer(commands, pass_output, CL_TRUE, 0, typesize * channels, computed_result, 0, NULL, NULL);
    if (err)
    {
        printf("Error: Failed to read back results from the device!\n");
        return EXIT_FAILURE;
    }


    // Verify the results are correct
    //
    if(integer)
    {
        int reference[4] = { 0, 0, 0, 0};    
        switch(channels)
        {
            case 4:
                reduce_validate_int4(integer_data, count, reference);
                break;
            case 2:
                reduce_validate_int2(integer_data, count, reference);
                break;
            case 1:
                reduce_validate_int(integer_data, count, reference);
                break;
            default:
                printf("Invalid channel count specified!\n");
                return EXIT_FAILURE;
        }    

        int result[4] = { 0.0f, 0.0f, 0.0f, 0.0f};    
        for(c = 0; c < channels; c++)
        {
            int v = ((int*) computed_result)[c]; 
            result[c] += v;
        }

        float error = 0.0f;
        float diff = 0.0f;
        for(c = 0; c < channels; c++)
        {
            diff = fabs(reference[c] - result[c]);
            error = diff > error ? diff : error;
        }
    
        if (error > MIN_ERROR)
        {
            for(c = 0; c < channels; c++)
                printf("Result[%d] %d != %d\n", c, reference[c], result[c]);
    
            printf("Error:  Incorrect results obtained! Max error = %f\n", error);
            return EXIT_FAILURE;
        }
        else
        {
            printf("Results Validated!\n");
            printf(SEPARATOR);
        }
    }
    else
    {
        float reference[4] = { 0.0f, 0.0f, 0.0f, 0.0f};    
        switch(channels)
        {
            case 4:
                reduce_validate_float4(float_data, count, reference);
                break;
            case 2:
                reduce_validate_float2(float_data, count, reference);
                break;
            case 1:
                reduce_validate_float(float_data, count, reference);
                break;
            default:
                printf("Invalid channel count specified!\n");
                return EXIT_FAILURE;
        }

        float result[4] = { 0.0f, 0.0f, 0.0f, 0.0f};    
        for(c = 0; c < channels; c++)
        {
            float v = ((float*) computed_result)[c]; 
            result[c] += v;
        }

        float error = 0.0f;
        float diff = 0.0f;
        for(c = 0; c < channels; c++)
        {
            diff = fabs(reference[c] - result[c]);
            error = diff > error ? diff : error;
        }
    
        if (error > MIN_ERROR)
        {
            for(c = 0; c < channels; c++)
                printf("Result[%d] %f != %f\n", c, reference[c], result[c]);
    
            printf("Error:  Incorrect results obtained! Max error = %f\n", error);
            return EXIT_FAILURE;
        }
        else
        {
            printf("Results Validated!\n");
            printf(SEPARATOR);
        }
    }
    
    // Shutdown and cleanup
    //
    for(i = 0; i < pass_count; i++)
    {
        clReleaseKernel(kernels[i]);
        clReleaseProgram(programs[i]);
    }
    
    clReleaseMemObject(input_buffer);
    clReleaseMemObject(output_buffer);
    clReleaseMemObject(partials_buffer);        
    clReleaseCommandQueue(commands);
    clReleaseContext(context);
    
    free(group_counts);
    free(work_item_counts);
    free(operation_counts);
    free(entry_counts);
    free(computed_result);
    free(kernels);
    free(float_data);
    free(integer_data);
    
        
    return 0;
}

