/* 
    File: main.c
Abstract: 
Demonstrates the use of pre-compiled bitcode with the OpenCL framework.

This program creates an OpenCL command queue against a device of the
user's choosing and then builds a CL program from a bitcode that the
user specifies.

To build the program and bitcode for 32/64bit CPUs and 32bit GPUs, type
'make'.

Usage:
./test -t cpu32|cpu64|gpu32 -i num -f kernel.bc

For example, to execute against the first gpu in your system:
./test -t gpu32 -i 0 -f kernel.gpu32.bc

Or to test 32bit CPU bitcode:
arch -i386 ./test -t cpu32 -f kernel.cpu32.bc

Or 64bit CPU, presuming a 64bit machine:
./test -t cpu64 -f kernel.cpu64.bc

The code below is divided into three sections.  The first, 'Bitcode
loading and use,' will be of the most interest.  The other sections,
'Typical OpenCL setup and teardown' and 'Supporting code,' are
run-of-the-mill C argument processing and OpenCL setup.

 Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <sys/stat.h>

#include <OpenCL/opencl.h>

#define MAXPATHLEN  512

// The number of float4s we will pass to our test kernel execution.
#define NELEMENTS   1024

// The various OpenCL objects needed to execute our CL program against a
// given compute device in our system.
int              device_index;
cl_device_type   device_type;
cl_device_id     device;
cl_context       context;
cl_command_queue queue;
cl_program       program;
cl_kernel        kernel;
cl_mem           a, b, c;

// A utility function to simplify error checking within this test code.
static void check_status(char* msg, cl_int err) {
  if (err != CL_SUCCESS) {
    fprintf(stderr, "%s failed. Error: %d\n", msg, err);
  }
}

#pragma mark -
#pragma mark Bitcode loading and use

static void create_program_from_bitcode(char* bitcode_path) {
  cl_int err;
  unsigned int i;
  
  // Instead of passing actual executable bits, we pass a path to the
  // already-compiled bitcode to clCreateProgramWithBinary.  Note that
  // you may load bitcode for multiple devices in one call by passing
  // multiple paths and multiple devices.  In the multiple-device case, 
  // the indices should match: if device 0 is a 32-bit GPU, then path 0 
  // should be bitcode for a GPU.  In the example below, we are loading
  // bitcode for one device only.
  
  size_t len = strlen(bitcode_path);
  program = clCreateProgramWithBinary(context, 1, &device, &len,
    (const unsigned char**)&bitcode_path, NULL, &err);
  check_status("clCreateProgramWithBinary", err);
  
  // The above tells OpenCL how to locate the intermediate bitcode, but we
  // still must build the program to produce executable bits for our
  // *specific* device.  This transforms gpu32 bitcode into actual executable
  // bits for an AMD or Intel compute device (for example).
  
  err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
  check_status("clBuildProgram", err);
  
  // And that's it -- we have a fully-compiled program created from the 
  // bitcode.  Let's ask OpenCL for the test kernel.
  
  kernel = clCreateKernel(program, "vecadd", &err);
  check_status("clCreateKernel", err);
  
  // And now, let's test the kernel with some dummy data.
  
  float *host_a = (float*)malloc(sizeof(float)*4*NELEMENTS);
  float *host_b = (float*)malloc(sizeof(float)*4*NELEMENTS);
  float *host_c = (float*)malloc(sizeof(float)*4*NELEMENTS);
  
  // We pack some host buffers with our data.
  
  for (i = 0; i < NELEMENTS; i++) {
    host_a[i*4+0] = host_b[i*4+0] = i;
    host_a[i*4+1] = host_b[i*4+1] = i;
    host_a[i*4+2] = host_b[i*4+2] = i;
    host_a[i*4+3] = host_b[i*4+3] = i;
  }
  
  // And create and load some CL memory buffers with that host data.
  
  cl_mem a = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
    sizeof(cl_float4)*NELEMENTS, host_a, &err);
  
  cl_mem b = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, 
    sizeof(cl_float4)*NELEMENTS, host_b, &err);
  
  // CL buffer 'c' is for output, so we don't prepopulate it with data.
  
  cl_mem c = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
    sizeof(cl_float4)*NELEMENTS, NULL, &err);
  
  if (a == NULL || b == NULL || c == NULL) {
    fprintf(stderr, "Error: Unable to create OpenCL buffer memory objects.\n");
    exit(1);
  }
  
  // We set the CL buffers as arguments for the 'vecadd' kernel.
  
  int argc = 0;
  err |= clSetKernelArg(kernel, argc++, sizeof(cl_mem), &a);
  err |= clSetKernelArg(kernel, argc++, sizeof(cl_mem), &b);
  err |= clSetKernelArg(kernel, argc++, sizeof(cl_mem), &c);
  check_status("clSetKernelArg", err);
  
  // Launch the kernel over a single dimension, which is the same size
  // as the number of float4s.  We let OpenCL select the local dimensions
  // by passing 'NULL' as the 6th parameter.
  
  size_t global = NELEMENTS;
  err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global, NULL, 0, NULL, 
    NULL);
  check_status("clEnqueueNDRangeKernel", err);
  
  // Read back the results (blocking, so everything finishes), and then 
  // validate the results.
  
  clEnqueueReadBuffer(queue, c, CL_TRUE, 0, NELEMENTS*sizeof(cl_float4), host_c, 
    0, NULL, NULL);
  
  int success = 1;
  for (i = 0; i < NELEMENTS; i++) {
    if ( host_c[i*4+0] != i*2.0 || host_c[i*4+1] != i * 2.0 ||
         host_c[i*4+2] != i*2.0 || host_c[i*4+3] != i * 2.0 ) 
    {
      success = 0;
      fprintf(stderr, "Validation failed at index %d\n", i);
      fprintf(stderr, "Kernel FAILED!\n");
      break;
    }
  }
  
  if (success) {
    fprintf(stdout, "Validation successful.\n");
  }
  
}

#pragma mark -
#pragma mark Typical OpenCL setup and teardown

static void init_opencl() {
  cl_int err;
  cl_uint num_devices;
  
  // How many devices of the type requested are in the system?
  clGetDeviceIDs(NULL, device_type, 0, NULL, &num_devices);
  
  // Make sure the requested index is within bounds.  Otherwise, correct it.
  if (device_index < 0 || device_index > num_devices - 1) {
    fprintf(stdout, "Requsted index (%d) is out of range.  Using 0.\n", 
      device_index);
    device_index = 0;
  }
  
  // Grab the requested device.
  cl_device_id all_devices[num_devices];
  clGetDeviceIDs(NULL, device_type, num_devices, all_devices, NULL);
  device = all_devices[device_index];
  
  // Dump the device.
  char name[128];
  clGetDeviceInfo(device, CL_DEVICE_NAME, 128*sizeof(char), name, NULL);
  fprintf(stdout, "Using OpenCL device: %s\n", name);
  
  // Create an OpenCL context using this compute device.
  context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
  check_status("clCreateContext", err);
  
  // Create a command queue on this device, since we want to use if for
  // running our CL program.
  queue = clCreateCommandQueue(context, device, 0, &err);
  check_status("clCreateCommandQueue", err);
}

static void shutdown_opencl() {
  
  // Free up all the CL objects we've allocated.
  
  clReleaseMemObject(a);
  clReleaseMemObject(b);
  clReleaseMemObject(c);
  clReleaseKernel(kernel);
  clReleaseProgram(program);
  clReleaseCommandQueue(queue);
  clReleaseContext(context);
}

#pragma mark -
#pragma mark Supporting code

static void usage(char* name) {
  fprintf(stdout, "\nUsage:   %s [-t gpu|cpu] [-i index] [-f filename]\n", name);
  fprintf(stdout, "Example: %s -t gpu -i 0 -f kernel.gpu32.bc\n\n", name);
  exit(0);
}

static void process_arguments(int argc, char* const *argv, char* filepath) {
  int c;
  
  static struct option longopts[] = {
    {"type", required_argument, NULL, 't'},
    {"filename", required_argument, NULL, 'f'},
    {"index", required_argument, NULL, 'i'},
    {0, 0, 0, 0}
  };
  
  while ((c = getopt_long(argc, argv, "t:f:i:", longopts, NULL)) != -1) {
    switch (c) {
      case 'f':
      filepath[0] = '\0';
      strlcat(filepath, optarg, MAXPATHLEN);
      break;
      
      case 't':
      if (0 == strncmp(optarg, "gpu", 3)) {
        device_type = CL_DEVICE_TYPE_GPU;
      } else if (0 == strncmp(optarg, "cpu", 3)) {
        device_type = CL_DEVICE_TYPE_CPU;
      } else {
        fprintf(stderr, "Unsupported test device type '%s'; using 'cpu'.\n", optarg);
      }
      break;
      
      case 'i':
      device_index = atoi(optarg);
      break;
      
      default:
      usage(argv[0]);
    }
  }
  
  // Ensure a valid bitcode filepath.
  
  struct stat stat_buf;
  if (0 != stat(filepath, &stat_buf)) {
      fprintf(stderr, "Error: the specified file '%s' does not exist.\n", filepath);
      exit(1);
  }
  
}

int main (int argc, char* const *argv)
{
  char filepath[MAXPATHLEN];
  filepath[0] = '\0';
  
  // By default, ask for the first GPU and use the gpu32 bitcode file, but
  // we check the args to let the user choose a different device and pre-
  // compiled bitcode file.
  
  device_index = 0;
  device_type = CL_DEVICE_TYPE_GPU;
  strlcat(filepath, "kernel.gpu32.bc", MAXPATHLEN);
  process_arguments(argc, argv, filepath);
  
  // Perform typical OpenCL setup in order to obtain a context and command
  // queue.
  init_opencl();
  
  // Obtain a CL program and kernel from our pre-compiled bitcode file and
  // test it by running the kernel on some test data.
  create_program_from_bitcode(filepath);
  
  // Close everything down.
  shutdown_opencl();
  
  return 0;
}
