
//
// File:       main.cpp
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


#include <string.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <OpenCL/opencl.h>
#include "clFFT.h"
#include <mach/mach_time.h>
#include <Accelerate/Accelerate.h>
#include "procs.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <float.h>

#define eps_avg 10.0

#define MAX( _a, _b)	((_a)>(_b)?(_a) : (_b))

typedef enum {
	clFFT_OUT_OF_PLACE,
	clFFT_IN_PLACE,
}clFFT_TestType;

typedef struct
{
	double real;
	double imag;
}clFFT_ComplexDouble;

typedef struct
{
	double *real;
	double *imag;
}clFFT_SplitComplexDouble;

cl_device_id     device_id;
cl_context       context;
cl_command_queue queue;

typedef unsigned long long ulong;

double subtractTimes( uint64_t endTime, uint64_t startTime )
{
    uint64_t difference = endTime - startTime;
    static double conversion = 0.0;
    
    if( conversion == 0.0 )
    {
        mach_timebase_info_data_t info;
        kern_return_t err = mach_timebase_info( &info );
        
		//Convert the timebase into seconds
        if( err == 0  )
			conversion = 1e-9 * (double) info.numer / (double) info.denom;
    }
    
    return conversion * (double) difference;
}

void computeReferenceF(clFFT_SplitComplex *out, clFFT_Dim3 n, 
					  unsigned int batchSize, clFFT_Dimension dim, clFFT_Direction dir)
{
	FFTSetup plan_vdsp;
	DSPSplitComplex out_vdsp;
	FFTDirection dir_vdsp = dir == clFFT_Forward ? FFT_FORWARD : FFT_INVERSE;
	
	unsigned int i, j, k;
	unsigned int stride;
	unsigned int log2Nx = (unsigned int) log2(n.x);
	unsigned int log2Ny = (unsigned int) log2(n.y);
	unsigned int log2Nz = (unsigned int) log2(n.z);
	unsigned int log2N;
	
	log2N = log2Nx;
	log2N = log2N > log2Ny ? log2N : log2Ny;
	log2N = log2N > log2Nz ? log2N : log2Nz;
	
	plan_vdsp = vDSP_create_fftsetup(log2N, 2);
	
	switch(dim)
	{
		case clFFT_1D:
			
			for(i = 0; i < batchSize; i++)
			{
				stride = i * n.x;
				out_vdsp.realp  = out->real  + stride;
				out_vdsp.imagp  = out->imag  + stride;
				
			    vDSP_fft_zip(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
			}
			break;
			
		case clFFT_2D:
			
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.y; j++)
				{
					stride = j * n.x + i * n.x * n.y;
					out_vdsp.realp = out->real + stride;
					out_vdsp.imagp = out->imag + stride;
					
					vDSP_fft_zip(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.x; j++)
				{
					stride = j + i * n.x  * n.y;
					out_vdsp.realp = out->real + stride;
					out_vdsp.imagp = out->imag + stride;
					
					vDSP_fft_zip(plan_vdsp, &out_vdsp, n.x, log2Ny, dir_vdsp);
				}
			}
			break;
			
		case clFFT_3D:
			
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.z; j++)
				{
					for(k = 0; k < n.y; k++)
					{
						stride = k * n.x + j * n.x * n.y + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zip(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
					}
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.z; j++)
				{
					for(k = 0; k < n.x; k++)
					{
						stride = k + j * n.x * n.y + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zip(plan_vdsp, &out_vdsp, n.x, log2Ny, dir_vdsp);
					}
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.y; j++)
				{
					for(k = 0; k < n.x; k++)
					{
						stride = k + j * n.x + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zip(plan_vdsp, &out_vdsp, n.x*n.y, log2Nz, dir_vdsp);
					}
				}
			}
			break;
	}
	
	vDSP_destroy_fftsetup(plan_vdsp);
}

void computeReferenceD(clFFT_SplitComplexDouble *out, clFFT_Dim3 n, 
					  unsigned int batchSize, clFFT_Dimension dim, clFFT_Direction dir)
{
	FFTSetupD plan_vdsp;
	DSPDoubleSplitComplex out_vdsp;
	FFTDirection dir_vdsp = dir == clFFT_Forward ? FFT_FORWARD : FFT_INVERSE;
	
	unsigned int i, j, k;
	unsigned int stride;
	unsigned int log2Nx = (int) log2(n.x);
	unsigned int log2Ny = (int) log2(n.y);
	unsigned int log2Nz = (int) log2(n.z);
	unsigned int log2N;
	
	log2N = log2Nx;
	log2N = log2N > log2Ny ? log2N : log2Ny;
	log2N = log2N > log2Nz ? log2N : log2Nz;
	
	plan_vdsp = vDSP_create_fftsetupD(log2N, 2);
	
	switch(dim)
	{
		case clFFT_1D:
			
			for(i = 0; i < batchSize; i++)
			{
				stride = i * n.x;
				out_vdsp.realp  = out->real  + stride;
				out_vdsp.imagp  = out->imag  + stride;
				
			    vDSP_fft_zipD(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
			}
			break;
			
		case clFFT_2D:
			
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.y; j++)
				{
					stride = j * n.x + i * n.x * n.y;
					out_vdsp.realp = out->real + stride;
					out_vdsp.imagp = out->imag + stride;
					
					vDSP_fft_zipD(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.x; j++)
				{
					stride = j + i * n.x  * n.y;
					out_vdsp.realp = out->real + stride;
					out_vdsp.imagp = out->imag + stride;
					
					vDSP_fft_zipD(plan_vdsp, &out_vdsp, n.x, log2Ny, dir_vdsp);
				}
			}
			break;
			
		case clFFT_3D:
			
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.z; j++)
				{
					for(k = 0; k < n.y; k++)
					{
						stride = k * n.x + j * n.x * n.y + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zipD(plan_vdsp, &out_vdsp, 1, log2Nx, dir_vdsp);
					}
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.z; j++)
				{
					for(k = 0; k < n.x; k++)
					{
						stride = k + j * n.x * n.y + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zipD(plan_vdsp, &out_vdsp, n.x, log2Ny, dir_vdsp);
					}
				}
			}
			for(i = 0; i < batchSize; i++)
			{
				for(j = 0; j < n.y; j++)
				{
					for(k = 0; k < n.x; k++)
					{
						stride = k + j * n.x + i * n.x * n.y * n.z;
						out_vdsp.realp = out->real + stride;
						out_vdsp.imagp = out->imag + stride;
						
						vDSP_fft_zipD(plan_vdsp, &out_vdsp, n.x*n.y, log2Nz, dir_vdsp);
					}
				}
			}
			break;
	}
	
	vDSP_destroy_fftsetupD(plan_vdsp);
}

double complexNormSq(clFFT_ComplexDouble a)
{
	return (a.real * a.real + a.imag * a.imag);
}

double computeL2Error(clFFT_SplitComplex *data, clFFT_SplitComplexDouble *data_ref, int n, int batchSize, double *max_diff, double *min_diff)
{
	int i, j;
	double avg_norm = 0.0;
	*max_diff = 0.0;
	*min_diff = 0x1.0p1000;
	
	for(j = 0; j < batchSize; j++)
	{
		double norm_ref = 0.0;
		double norm = 0.0;
	    for(i = 0; i < n; i++) 
		{
			int index = j * n + i;
		    clFFT_ComplexDouble diff = (clFFT_ComplexDouble) { data_ref->real[index] - data->real[index], data_ref->imag[index] - data->imag[index] };
		    double norm_tmp = complexNormSq(diff);
		    norm += norm_tmp;
		    norm_ref += (data_ref->real[index] * data_ref->real[index] + data_ref->imag[index] * data_ref->imag[index]);
	    }
	    double curr_norm = sqrt( norm / norm_ref ) / FLT_EPSILON;
		avg_norm += curr_norm;
		*max_diff = *max_diff < curr_norm ? curr_norm : *max_diff;
		*min_diff = *min_diff > curr_norm ? curr_norm : *min_diff;
	}
	
	return avg_norm / batchSize;
}

void convertInterleavedToSplit(clFFT_SplitComplex *result_split, clFFT_Complex *data_cl, int length)
{
	int i;
	for(i = 0; i < length; i++) {
		result_split->real[i] = data_cl[i].real;
		result_split->imag[i] = data_cl[i].imag;
	}
}

int runTest(clFFT_Dim3 n, int batchSize, clFFT_Direction dir, clFFT_Dimension dim, 
			clFFT_DataFormat dataFormat, int numIter, clFFT_TestType testType)
{	
	cl_int err = CL_SUCCESS;
	int iter;
	double t;
	
	uint64_t t0, t1;
	int mx = (int)log2(n.x);
	int my = (int)log2(n.y);
	int mz = (int)log2(n.z);

	int length = n.x * n.y * n.z * batchSize;
		
	double gflops = 5e-9 * ((double)mx + (double)my + (double)mz) * (double)n.x * (double)n.y * (double)n.z * (double)batchSize * (double)numIter;
	
	clFFT_SplitComplex data_i_split = (clFFT_SplitComplex) { NULL, NULL };
	clFFT_SplitComplex data_cl_split = (clFFT_SplitComplex) { NULL, NULL };
	clFFT_Complex *data_i = NULL;
	clFFT_Complex *data_cl = NULL;
	clFFT_SplitComplexDouble data_iref = (clFFT_SplitComplexDouble) { NULL, NULL }; 
	clFFT_SplitComplexDouble data_oref = (clFFT_SplitComplexDouble) { NULL, NULL };
	
	clFFT_Plan plan = NULL;
	cl_mem data_in = NULL;
	cl_mem data_out = NULL;
	cl_mem data_in_real = NULL;
	cl_mem data_in_imag = NULL;
	cl_mem data_out_real = NULL;
	cl_mem data_out_imag = NULL;
	
	if(dataFormat == clFFT_SplitComplexFormat) {
		data_i_split.real     = (float *) malloc(sizeof(float) * length);
		data_i_split.imag     = (float *) malloc(sizeof(float) * length);
		data_cl_split.real    = (float *) malloc(sizeof(float) * length);
		data_cl_split.imag    = (float *) malloc(sizeof(float) * length);
		if(!data_i_split.real || !data_i_split.imag || !data_cl_split.real || !data_cl_split.imag)
		{
			err = -1;
			log_error("Out-of-Resources\n");
			goto cleanup;
		}
	}
	else {
		data_i  = (clFFT_Complex *) malloc(sizeof(clFFT_Complex)*length);
		data_cl = (clFFT_Complex *) malloc(sizeof(clFFT_Complex)*length);
		if(!data_i || !data_cl)
		{
			err = -2;
			log_error("Out-of-Resouces\n");
			goto cleanup;
		}
	}
	
	data_iref.real   = (double *) malloc(sizeof(double) * length);
	data_iref.imag   = (double *) malloc(sizeof(double) * length);
	data_oref.real   = (double *) malloc(sizeof(double) * length);
	data_oref.imag   = (double *) malloc(sizeof(double) * length);	
	if(!data_iref.real || !data_iref.imag || !data_oref.real || !data_oref.imag)
	{
		err = -3;
		log_error("Out-of-Resources\n");
		goto cleanup;
	}

	int i;
	if(dataFormat == clFFT_SplitComplexFormat) {
		for(i = 0; i < length; i++)
		{
			data_i_split.real[i] = 2.0f * (float) rand() / (float) RAND_MAX - 1.0f;
			data_i_split.imag[i] = 2.0f * (float) rand() / (float) RAND_MAX - 1.0f;
			data_cl_split.real[i] = 0.0f;
			data_cl_split.imag[i] = 0.0f;			
			data_iref.real[i] = data_i_split.real[i];
			data_iref.imag[i] = data_i_split.imag[i];
			data_oref.real[i] = data_iref.real[i];
			data_oref.imag[i] = data_iref.imag[i];	
		}
	}
	else {
		for(i = 0; i < length; i++)
		{
			data_i[i].real = 2.0f * (float) rand() / (float) RAND_MAX - 1.0f;
			data_i[i].imag = 2.0f * (float) rand() / (float) RAND_MAX - 1.0f;
			data_cl[i].real = 0.0f;
			data_cl[i].imag = 0.0f;			
			data_iref.real[i] = data_i[i].real;
			data_iref.imag[i] = data_i[i].imag;
			data_oref.real[i] = data_iref.real[i];
			data_oref.imag[i] = data_iref.imag[i];	
		}		
	}
	
	plan = clFFT_CreatePlan( context, n, dim, dataFormat, &err );
	if(!plan || err) 
	{
		log_error("clFFT_CreatePlan failed\n");
		goto cleanup;
	}
	
	//clFFT_DumpPlan(plan, stdout);
	
	if(dataFormat == clFFT_SplitComplexFormat)
	{
		data_in_real = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float), data_i_split.real, &err);
	    if(!data_in_real || err) 
	    {
			log_error("clCreateBuffer failed\n");
			goto cleanup;
	    }
		
		data_in_imag = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float), data_i_split.imag, &err);
	    if(!data_in_imag || err) 
	    {
			log_error("clCreateBuffer failed\n");
			goto cleanup;
	    }
		
		if(testType == clFFT_OUT_OF_PLACE)
		{
			data_out_real = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float), data_cl_split.real, &err);
			if(!data_out_real || err) 
			{
				log_error("clCreateBuffer failed\n");
				goto cleanup;
			}
			
			data_out_imag = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float), data_cl_split.imag, &err);
			if(!data_out_imag || err) 
			{
				log_error("clCreateBuffer failed\n");
				goto cleanup;
			}			
		}
		else
		{
			data_out_real = data_in_real;
			data_out_imag = data_in_imag;
		}
	}
	else
	{
	    data_in = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float)*2, data_i, &err);
	    if(!data_in) 
	    {
			log_error("clCreateBuffer failed\n");
			goto cleanup;
	    }
		if(testType == clFFT_OUT_OF_PLACE)
		{
			data_out = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, length*sizeof(float)*2, data_cl, &err);
			if(!data_out) 
			{
				log_error("clCreateBuffer failed\n");
				goto cleanup;
			}			
		}
		else
			data_out = data_in;
	}
		
			
	err = CL_SUCCESS;
	
	t0 = mach_absolute_time();
	if(dataFormat == clFFT_SplitComplexFormat)
	{
		for(iter = 0; iter < numIter; iter++)
		    err |= clFFT_ExecutePlannar(queue, plan, batchSize, dir, data_in_real, data_in_imag, data_out_real, data_out_imag, 0, NULL, NULL);
	}
	else
	{
	    for(iter = 0; iter < numIter; iter++) 
			err |= clFFT_ExecuteInterleaved(queue, plan, batchSize, dir, data_in, data_out, 0, NULL, NULL);
	}
	
	err |= clFinish(queue);
	
	if(err) 
	{
		log_error("clFFT_Execute\n");
		goto cleanup;	
	}
	
	t1 = mach_absolute_time(); 
	t = subtractTimes(t1, t0);
	char temp[100];
	sprintf(temp, "GFlops achieved for n = (%d, %d, %d), batchsize = %d", n.x, n.y, n.z, batchSize);
	log_perf(gflops / (float) t, 1, "GFlops/s", "%s", temp);

	if(dataFormat == clFFT_SplitComplexFormat)
	{	
		err |= clEnqueueReadBuffer(queue, data_out_real, CL_TRUE, 0, length*sizeof(float), data_cl_split.real, 0, NULL, NULL);
		err |= clEnqueueReadBuffer(queue, data_out_imag, CL_TRUE, 0, length*sizeof(float), data_cl_split.imag, 0, NULL, NULL);
	}
	else
	{
		err |= clEnqueueReadBuffer(queue, data_out, CL_TRUE, 0, length*sizeof(float)*2, data_cl, 0, NULL, NULL);
	}
	
	if(err) 
	{
		log_error("clEnqueueReadBuffer failed\n");
        goto cleanup;
	}	

	computeReferenceD(&data_oref, n, batchSize, dim, dir);
	
	double diff_avg, diff_max, diff_min;
	if(dataFormat == clFFT_SplitComplexFormat) {
		diff_avg = computeL2Error(&data_cl_split, &data_oref, n.x*n.y*n.z, batchSize, &diff_max, &diff_min);
		if(diff_avg > eps_avg)
			log_error("Test failed (n=(%d, %d, %d), batchsize=%d): %s Test: rel. L2-error = %f eps (max=%f eps, min=%f eps)\n", n.x, n.y, n.z, batchSize, (testType == clFFT_OUT_OF_PLACE) ? "out-of-place" : "in-place", diff_avg, diff_max, diff_min);
		else
			log_info("Test passed (n=(%d, %d, %d), batchsize=%d): %s Test: rel. L2-error = %f eps (max=%f eps, min=%f eps)\n", n.x, n.y, n.z, batchSize, (testType == clFFT_OUT_OF_PLACE) ? "out-of-place" : "in-place", diff_avg, diff_max, diff_min);			
	}
	else {
		clFFT_SplitComplex result_split;
		result_split.real = (float *) malloc(length*sizeof(float));
		result_split.imag = (float *) malloc(length*sizeof(float));
		convertInterleavedToSplit(&result_split, data_cl, length);
		diff_avg = computeL2Error(&result_split, &data_oref, n.x*n.y*n.z, batchSize, &diff_max, &diff_min);
		
		if(diff_avg > eps_avg)
			log_error("Test failed (n=(%d, %d, %d), batchsize=%d): %s Test: rel. L2-error = %f eps (max=%f eps, min=%f eps)\n", n.x, n.y, n.z, batchSize, (testType == clFFT_OUT_OF_PLACE) ? "out-of-place" : "in-place", diff_avg, diff_max, diff_min);
		else
			log_info("Test passed (n=(%d, %d, %d), batchsize=%d): %s Test: rel. L2-error = %f eps (max=%f eps, min=%f eps)\n", n.x, n.y, n.z, batchSize, (testType == clFFT_OUT_OF_PLACE) ? "out-of-place" : "in-place", diff_avg, diff_max, diff_min);	
		free(result_split.real);
		free(result_split.imag);
	}
	
cleanup:
	clFFT_DestroyPlan(plan);	
	if(dataFormat == clFFT_SplitComplexFormat) 
	{
		if(data_i_split.real)
			free(data_i_split.real);
		if(data_i_split.imag)
			free(data_i_split.imag);
		if(data_cl_split.real)
			free(data_cl_split.real);
		if(data_cl_split.imag)
			free(data_cl_split.imag);
		
		if(data_in_real)
			clReleaseMemObject(data_in_real);
		if(data_in_imag)
			clReleaseMemObject(data_in_imag);
		if(data_out_real && testType == clFFT_OUT_OF_PLACE)
			clReleaseMemObject(data_out_real);
		if(data_out_imag && clFFT_OUT_OF_PLACE)
			clReleaseMemObject(data_out_imag);
	}
	else 
	{
		if(data_i)
			free(data_i);
		if(data_cl)
			free(data_cl);
		
		if(data_in)
			clReleaseMemObject(data_in);
		if(data_out && testType == clFFT_OUT_OF_PLACE)
			clReleaseMemObject(data_out);
	}
	
	if(data_iref.real)
		free(data_iref.real);
	if(data_iref.imag)
		free(data_iref.imag);		
	if(data_oref.real)
		free(data_oref.real);
	if(data_oref.imag)
		free(data_oref.imag);
	
	return err;
}

bool ifLineCommented(const char *line) {
	const char *Line = line;
	while(*Line != '\0')
		if((*Line == '/') && (*(Line + 1) == '/'))
			return true;
		else
			Line++;
	return false;
}

cl_device_type getGlobalDeviceType()
{
	char *force_cpu = getenv( "CL_DEVICE_TYPE" );
	if( force_cpu != NULL )
	{
		if( strcmp( force_cpu, "gpu" ) == 0 || strcmp( force_cpu, "CL_DEVICE_TYPE_GPU" ) == 0 )
			return CL_DEVICE_TYPE_GPU;
		else if( strcmp( force_cpu, "cpu" ) == 0 || strcmp( force_cpu, "CL_DEVICE_TYPE_CPU" ) == 0 )
			return CL_DEVICE_TYPE_CPU;
		else if( strcmp( force_cpu, "accelerator" ) == 0 || strcmp( force_cpu, "CL_DEVICE_TYPE_ACCELERATOR" ) == 0 )
			return CL_DEVICE_TYPE_ACCELERATOR;
		else if( strcmp( force_cpu, "CL_DEVICE_TYPE_DEFAULT" ) == 0 )
			return CL_DEVICE_TYPE_DEFAULT;
	}
	// default
	return CL_DEVICE_TYPE_GPU;
}

void 
notify_callback(const char *errinfo, const void *private_info, size_t cb, void *user_data)
{
    log_error( "%s\n", errinfo );
}

int
checkMemRequirements(clFFT_Dim3 n, int batchSize, clFFT_TestType testType, cl_ulong gMemSize)
{
	cl_ulong memReq = (testType == clFFT_OUT_OF_PLACE) ? 3 : 2;
	memReq *= n.x*n.y*n.z*sizeof(clFFT_Complex)*batchSize;
	memReq = memReq/1024/1024;
	if(memReq >= gMemSize)
		return -1;
	return 0;
}

int main (int argc, char * const argv[]) {
	
	test_start();
	
	cl_ulong gMemSize;
	clFFT_Direction dir = clFFT_Forward;
	int numIter = 1;
	clFFT_Dim3 n = { 1024, 1, 1 };
	int batchSize = 1;
	clFFT_DataFormat dataFormat = clFFT_SplitComplexFormat;
	clFFT_Dimension dim = clFFT_1D;
	clFFT_TestType testType = clFFT_OUT_OF_PLACE;
	cl_device_id device_ids[16];
	
	FILE *paramFile;
			
	cl_int err;
	unsigned int num_devices;
	
	cl_device_type device_type = getGlobalDeviceType();	
	if(device_type != CL_DEVICE_TYPE_GPU) 
	{
		log_info("Test only supported on DEVICE_TYPE_GPU\n");
		test_finish();
		exit(0);
	}
	
	err = clGetDeviceIDs(NULL, device_type, sizeof(device_ids), device_ids, &num_devices);
	if(err) 
	{		
		log_error("clGetComputeDevice failed\n");
		test_finish();
		return -1;
	}
	
	device_id = NULL;
	
	unsigned int i;
	for(i = 0; i < num_devices; i++)
	{
	    cl_bool available;
	    err = clGetDeviceInfo(device_ids[i], CL_DEVICE_AVAILABLE, sizeof(cl_bool), &available, NULL);
	    if(err)
	    {
	         log_error("Cannot check device availability of device # %d\n", i);
	    }
	    
	    if(available)
	    {
	        device_id = device_ids[i];
	        break;
	    }
	    else
	    {
	        char name[200];
	        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_NAME, sizeof(name), name, NULL);
	        if(err == CL_SUCCESS)
	        {
	             log_info("Device %s not available for compute\n", name);
	        }
	        else
	        {
	             log_info("Device # %d not available for compute\n", i);
	        }
	    }
	}
	
	if(!device_id)
	{
	    log_error("None of the devices available for compute ... aborting test\n");
	    test_finish();
	    return -1;
	}
	
	context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
	if(!context || err) 
	{
		log_error("clCreateContext failed\n");
		test_finish();
		return -1;
	}
	
    queue = clCreateCommandQueue(context, device_id, 0, &err);
    if(!queue || err)
	{
        log_error("clCreateCommandQueue() failed.\n");
		clReleaseContext(context);
        test_finish();
        return -1;
    }  
	
	err = clGetDeviceInfo(device_id, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &gMemSize, NULL);
	if(err)
	{
		log_error("Failed to get global mem size\n");
		clReleaseContext(context);
		clReleaseCommandQueue(queue);
		test_finish();
		return -2;
	}
	
	gMemSize /= (1024*1024);
			
	char delim[] = " \n";
	char tmpStr[100];
	char line[200];
	char *param, *val;	
	int total_errors = 0;
	if(argc == 1) {
		log_error("Need file name with list of parameters to run the test\n");
		test_finish();
		return -1;
	}
	
	if(argc == 2) {	// arguments are supplied in a file with arguments for a single run are all on the same line
		paramFile = fopen(argv[1], "r");
		if(!paramFile) {
			log_error("Cannot open the parameter file\n");
			clReleaseContext(context);
			clReleaseCommandQueue(queue);			
			test_finish();
			return -3;
		}
		while(fgets(line, 199, paramFile)) {
			if(!strcmp(line, "") || !strcmp(line, "\n") || ifLineCommented(line))
				continue;
			param = strtok(line, delim);
			while(param) {
				val = strtok(NULL, delim);
				if(!strcmp(param, "-n")) {
					sscanf(val, "%d", &n.x);
					val = strtok(NULL, delim);
					sscanf(val, "%d", &n.y);
					val = strtok(NULL, delim);
					sscanf(val, "%d", &n.z);					
				}
				else if(!strcmp(param, "-batchsize")) 
					sscanf(val, "%d", &batchSize);
				else if(!strcmp(param, "-dir")) {
					sscanf(val, "%s", tmpStr);
					if(!strcmp(tmpStr, "forward"))
						dir = clFFT_Forward;
					else if(!strcmp(tmpStr, "inverse"))
						dir = clFFT_Inverse;
				}
				else if(!strcmp(param, "-dim")) {
					sscanf(val, "%s", tmpStr);
					if(!strcmp(tmpStr, "1D"))
						dim = clFFT_1D;
					else if(!strcmp(tmpStr, "2D"))
						dim = clFFT_2D; 
					else if(!strcmp(tmpStr, "3D"))
						dim = clFFT_3D;					
				}
				else if(!strcmp(param, "-format")) {
					sscanf(val, "%s", tmpStr);
					if(!strcmp(tmpStr, "plannar"))
						dataFormat = clFFT_SplitComplexFormat;
					else if(!strcmp(tmpStr, "interleaved"))
						dataFormat = clFFT_InterleavedComplexFormat;					
				}
				else if(!strcmp(param, "-numiter"))
					sscanf(val, "%d", &numIter);
				else if(!strcmp(param, "-testtype")) {
					sscanf(val, "%s", tmpStr);
					if(!strcmp(tmpStr, "out-of-place"))
						testType = clFFT_OUT_OF_PLACE;
					else if(!strcmp(tmpStr, "in-place"))
						testType = clFFT_IN_PLACE;										
				}
				param = strtok(NULL, delim);
			}
			
			if(checkMemRequirements(n, batchSize, testType, gMemSize)) {
				log_info("This test cannot run because memory requirements canot be met by the available device\n");
				continue;
			}
				
			err = runTest(n, batchSize, dir, dim, dataFormat, numIter, testType);
			if (err)
				total_errors++;
		}
	}
	
	clReleaseContext(context);
	clReleaseCommandQueue(queue);
	
	test_finish();
	return total_errors;		
}
