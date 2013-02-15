//
// File:       simulation.cpp
//
// Abstract:   This example performs an NBody simulation which calculates a gravity field 
//             and corresponding velocity and acceleration contributions accumulated 
//             by each body in the system from every other body.  This example
//             also shows how to mitigate computation between all available devices
//             including CPU and GPU devices, as well as a hybrid combination of both,
//             using separate threads for each simulator.
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

////////////////////////////////////////////////////////////////////////////////

#include <algorithm>

#include <cstdio>
#include <cstring>

#include <libkern/OSAtomic.h>
#include <math.h>

#include "simulation.h"
#include "randomize.h"
#include "timing.h"
#include "data.h"

#define WORK_ITEMS_X 256
#define WORK_ITEMS_Y 1

////////////////////////////////////////////////////////////////////////////////////////////////////

static int MemCopyDeviceToHost(
    cl_command_queue compute_commands, 
    float4 *host_data, 
    cl_mem device_data, 
    int size, 
    int offset)
{
    return clEnqueueReadBuffer(compute_commands, device_data, CL_TRUE, offset, size, host_data, 0, 0, 0);
}

static int MemCopyHostToDevice(
    cl_command_queue compute_commands, 
    float4 *host_data, 
    cl_mem device_data, 
    int size)
{
    return clEnqueueWriteBuffer(compute_commands, device_data, CL_TRUE, 0, size, host_data, 0, 0, 0);
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void *simulate(void *arg)
{
    ((Simulation *)arg)->run();
    return NULL;
}

Simulation::Simulation(size_t nbodies, NBodyParams params) :
    m_initialized(false),
    m_update_external_data(true),
    m_body_count(nbodies),
    m_start_index(0),
    m_end_index(nbodies),
    m_active_params(params),
    m_data(NULL),
    m_thread(0),
    m_run_mode(STOP),
    m_stop(false),
    m_reload(false),
    m_paused(false),
    m_gigaflops_meter(20, false),
    m_gigaflops(0),
    m_updates_per_second_meter(20, false),
    m_updates_per_second(0)
{
    m_device_count = 0;
    m_device_name[0] = '\0';
}

Simulation::~Simulation()
{
    free(takeData());
}

bool Simulation::isInitialized()
{
    return m_initialized;
}

void *Simulation::takeData()
{
    void *oldData;
    do
    {
        oldData = m_data;
    }
    while (!OSAtomicCompareAndSwapPtrBarrier(oldData, NULL, &m_data));
    return oldData;
}

void Simulation::start(bool paused)
{
    pthread_mutex_init(&m_run_lock, NULL);
    pause();
    pthread_create(&m_thread, NULL, simulate, this);

    if(!paused)
        unpause();
}

void Simulation::pause()
{
    if (m_paused)
    {
        // fprintf(stderr, "pausing already-paused simulation\n");
    }
    else
    {
        pthread_mutex_lock(&m_run_lock);
        m_paused = true;
    }
}

void Simulation::unpause()
{
    if (!m_paused)
    {
        // fprintf(stderr, "unpausing already-running simulation\n");
    }
    else
    {
        m_paused = false;
        pthread_mutex_unlock(&m_run_lock);
    }
}

void Simulation::stop()
{
    pause();
    m_stop = true;
    unpause();
    pthread_join(m_thread, NULL);
    m_initialized = false;
}

void Simulation::reset(NBodyParams params)
{
    pause();

    m_start_index = 0;
    m_end_index = m_body_count;
    m_active_params = params;
    m_gigaflops_meter.reset();
    m_gigaflops = 0;
    m_updates_per_second_meter.reset();
    m_updates_per_second = 0;
    m_reload = true;
    m_year = 2.755e9;

    unpause();
}

void Simulation::setActiveParams(NBodyParams params)
{
    m_active_params = params;
    m_reload = true;
}

double Simulation::getGigaFlops() const
{
    return m_gigaflops;
}

double Simulation::getUpdatesPerSecond() const
{
    return m_updates_per_second;
}

void Simulation::giveData(void *data)
{
    void *copy = malloc(sizeof(float4) * m_body_count);
    memcpy(copy, data, sizeof(float4) * m_body_count);

    void *oldData;
    do
    {
        oldData = m_data;
    }
    while (!OSAtomicCompareAndSwapPtrBarrier(oldData, copy, &m_data));
    free(oldData);
}

static pthread_mutex_t cl_lock = PTHREAD_MUTEX_INITIALIZER;

#define CL(...)                    \
    pthread_mutex_lock(&cl_lock);  \
    __VA_ARGS__                    \
    pthread_mutex_unlock(&cl_lock)

void Simulation::run()
{
    CL( { initialize(); });
    while (true)
    {
        pthread_mutex_lock(&m_run_lock);
        if (m_stop)
        {
            pthread_mutex_unlock(&m_run_lock);
            break;
        }
        if (m_reload)
        {
            CL( { reset(); });
            m_reload = false;
        }

        uint64_t before, after;
        CL(
        {
            before = mach_absolute_time();
            step();
            after = mach_absolute_time();
        });
        pthread_mutex_unlock(&m_run_lock);

        double dt = SubtractTime(after, before);

        m_gigaflops_meter.recordFrame(
            20.0 * m_body_count * m_body_count * 1e-9,  // 20 Flops per kernel execution
            dt);
        m_gigaflops = m_gigaflops_meter.stuffPerSecond();

        m_updates_per_second_meter.recordFrame(1, dt);
        m_updates_per_second = m_updates_per_second_meter.stuffPerSecond();
        m_year += 1.8e6 * m_active_params.m_timestep / 0.1 ; // normalize for CCN_TIME_SCALE at 0.4
    }

    CL( { terminate(); });
}

double Simulation::getYear() const
{
    return m_year;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

GPUSimulation::GPUSimulation(
    size_t nbodies, 
    NBodyParams params,
    unsigned int n_devices, 
    int dev_index) 
:
    Simulation(nbodies, params),
    m_device_index(dev_index),
    work_item_x(WORK_ITEMS_X)
{
    m_device_count = n_devices;
    bzero(m_device_id, sizeof(m_device_id));
}

GPUSimulation::~GPUSimulation()
{
    // EMPTY!
}

void GPUSimulation::initialize()
{
    m_read_index = 0;
    m_write_index = 1;

    m_host_position = (float4 *) malloc(sizeof(float4) * m_body_count);
    m_host_velocity = (float4 *) malloc(sizeof(float4) * m_body_count);
    m_host_color = (float4 *) malloc(sizeof(float4) * m_body_count);

    int err = setupComputeDevices();
    if (err != 0)
    {
        fprintf(stderr, "setupComputeDevices() failed: %d\n", err);
        m_initialized = false;
    }
    else
    {
        m_initialized = true;
    }
}

void GPUSimulation::reset()
{
    if (int err = resetDevice() != 0)
    {
        fprintf(stderr, "resetDevice() failed: %d\n", err);
    }
}

void GPUSimulation::step()
{
    if (int err = executeKernel() != 0)
    {
        fprintf(stderr, "executeKernel() failed: %d\n", err);
    }

    unsigned int i = 0;
    if (m_update_external_data)
    {
        for (i = 0; i < m_device_count; i++)
        {
            MemCopyDeviceToHost(m_compute_commands[i], m_host_position, m_device_position[m_write_index], sizeof(float4)*m_body_count, 0);
            giveData(m_host_position);
        }
    }
    std::swap(m_read_index, m_write_index);
}

void GPUSimulation::terminate()
{
    if (m_compute_context)
    {
        unsigned int i = 0;
        for (i = 0; i < m_device_count; i++)
        {
            if (m_compute_commands[i])
            {
                clFinish(m_compute_commands[i]);
                clReleaseCommandQueue(m_compute_commands[i]);
            }
        }

        clReleaseMemObject(m_device_position[0]);
        clReleaseMemObject(m_device_position[1]);
        clReleaseMemObject(m_device_velocity[0]);
        clReleaseMemObject(m_device_velocity[1]);
        clReleaseMemObject(m_body_range_params);

        clReleaseKernel(m_compute_kernel);
        clReleaseContext(m_compute_context);
    }

    bzero(m_device_position, sizeof(m_device_position));
    bzero(m_device_velocity, sizeof(m_device_velocity));
    bzero(m_device_id, sizeof(m_device_id));
    bzero(m_compute_kernel, sizeof(m_compute_kernel));
    bzero(m_compute_context, sizeof(m_compute_context));
    bzero(m_compute_commands, sizeof(m_compute_commands));
    bzero(m_body_range_params, sizeof(m_body_range_params));
}

void *GPUSimulation::getColorData()
{
    return m_host_color;
}

int GPUSimulation::setupComputeDevices()
{
    int return_value;
    char *source;
    size_t src_len;
    cl_mem_flags stream_flags;
    stream_flags = CL_MEM_READ_WRITE;
    unsigned int i = 0;

    unsigned int av = 0;
    unsigned int as = 0;

    size_t args_size[32];
    void *args_value[32];
    unsigned int count = 0;

    return_value = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_GPU, 4, m_device_id, &count);
    if (return_value)
        return -1;

    printf("Found %d GPU devices...\n", count);
    m_device_count = (count > m_device_count) ? m_device_count : count;

    if (m_device_index >= 0)
    {
        m_device_count = 1;
        i = m_device_index;
        size_t returned_size = 0;
        char name[1024] = {0};
        char vendor[1024] = {0};

        clGetDeviceInfo(m_device_id[i], CL_DEVICE_NAME, sizeof(name), &name, &returned_size);
        clGetDeviceInfo(m_device_id[i], CL_DEVICE_VENDOR, sizeof(vendor), &vendor, &returned_size);

        sprintf(m_device_name, "%s", name);
        printf("Using Device[%d]: %s\n", i, m_device_name);

        m_device_id[0] = m_device_id[i];
        m_compute_context = clCreateContext(0, 1, &m_device_id[0], 0, 0, &return_value);
        m_compute_commands[0] = clCreateCommandQueue(m_compute_context, m_device_id[0], 0, &return_value);
        if (!m_compute_commands[0])
            return -2;
    }
    else
    {
        m_compute_context = clCreateContext(0, m_device_count, m_device_id, 0, 0, &return_value);
        for (i = 0; i < m_device_count; i++)
        {
            m_compute_commands[i] = clCreateCommandQueue(m_compute_context, m_device_id[i], 0, &return_value);
            if (!m_compute_commands[i])
                return -2;
        }
    }

    if (!m_compute_context)
    {
        printf("Failed to create compute context for devices: %d\n", m_device_count);
        return -4;

    }

    return_value = LoadFileIntoString("nbody_gpu.cl", &source, &src_len);
    if (return_value)
        return -5;

    m_compute_program = clCreateProgramWithSource(m_compute_context, 1, (const char**) & source, 0, &return_value);
    if (!m_compute_program)
        return -6;

    return_value = clBuildProgram(m_compute_program, m_device_count, m_device_id, 0, NULL, NULL);
    if (return_value != CL_SUCCESS)
    {
        size_t length = 0;
        char info_log[2000];

        for (i = 0; i < m_device_count; i++)
        {
            clGetProgramBuildInfo(m_compute_program, m_device_id[i], CL_PROGRAM_BUILD_LOG, 2000, info_log, &length);
            fprintf(stderr, "Build Log for Device[%d]:\n%s\n", i, info_log);
        }
        return -7;
    }

    m_compute_kernel = clCreateKernel(m_compute_program, (char*) "IntegrateSystem", &return_value);
    if (!m_compute_kernel)
        return -8;

    size_t localSize;
    for(i = 0; i < m_device_count; i++)
    {
        return_value = clGetKernelWorkGroupInfo(m_compute_kernel, m_device_id[i], CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &localSize, NULL);
        if (return_value)
            return -300;

        work_item_x = (work_item_x <= localSize) ? work_item_x : localSize;
    }

    if (m_body_count % work_item_x != 0) {
        fprintf(stderr, "num of particlces (%d) must be evenly divisble work group size (%d) for device\n", (int) m_body_count, work_item_x);
        return -20;
    }

    m_device_position[0] = clCreateBuffer(m_compute_context, stream_flags, sizeof(float4) * m_body_count, NULL, &return_value);
    if (!m_device_position[0])
        return -9;

    m_device_position[1] = clCreateBuffer(m_compute_context, stream_flags, sizeof(float4) * m_body_count, NULL, &return_value);
    if (!m_device_position[1])
        return -11;

    m_device_velocity[0] = clCreateBuffer(m_compute_context, CL_MEM_READ_WRITE, sizeof(float4) * m_body_count, NULL, &return_value);
    if (!m_device_velocity[0])
        return -10;

    m_device_velocity[1] = clCreateBuffer(m_compute_context, CL_MEM_READ_WRITE, sizeof(float4) * m_body_count, NULL, &return_value);
    if (!m_device_velocity[1])
        return -12;

    m_body_range_params = clCreateBuffer(m_compute_context, CL_MEM_READ_WRITE, sizeof(int) * 3, NULL, &return_value);
    if (!m_body_range_params)
        return -200;

    args_value[av++] = &m_device_position[m_write_index];
    args_size[as++] = sizeof(cl_mem);

    args_value[av++] = &m_device_velocity[m_write_index];
    args_size[as++] = sizeof(cl_mem);

    args_value[av++] = &m_device_position[m_read_index];
    args_size[as++] = sizeof(cl_mem);

    args_value[av++] = &m_device_velocity[m_read_index];
    args_size[as++] = sizeof(cl_mem);
    float slow_step = m_active_params.m_timestep;

    args_value[av++] = (void *) & slow_step;
    args_size[as++] = sizeof(float);

    args_value[av++] = (void *) & m_active_params.m_damping;
    args_size[as++] = sizeof(float);

    args_value[av++] = (void *) & m_active_params.m_softening;
    args_size[as++] = sizeof(float);

    args_value[av++] = (void *) &m_body_count;                
    args_size[as++] = sizeof(int);
    
    args_value[av++] = (void *) &m_start_index;                
    args_size[as++] = sizeof(int);
    
    args_value[av++] = (void *) &m_end_index;                
    args_size[as++] = sizeof(int);

    args_value[av++] = 0;
    args_size[as++] = sizeof(float4) * work_item_x * WORK_ITEMS_Y;

    return_value = CL_SUCCESS;
    for (i = 0; i < as; i++)
        return_value |= clSetKernelArg(m_compute_kernel, i, args_size[i], args_value[i]);

    if (return_value)
        return -22;

    free(source);
    return 0;
}

int GPUSimulation::executeKernel()
{
    int err = CL_SUCCESS;
    size_t global_dim[2], local_dim[2];
    local_dim[0]  = work_item_x;
    local_dim[1]  = 1;
    global_dim[0] = m_end_index - m_start_index;
    global_dim[1] = 1;

    unsigned int i;
    unsigned int av = 0;
    unsigned int as = 0;
    unsigned int ai = 0;

    size_t args_size[32];
    void *args_value[32];
    unsigned int args_indices[32];

    args_value[av++] = &m_device_position[m_write_index];
    args_size[as++] = sizeof(cl_mem);
    args_indices[ai++] = 0;
    
    args_value[av++] = &m_device_velocity[m_write_index];
    args_size[as++] = sizeof(cl_mem);
    args_indices[ai++] = 1;

    args_value[av++] = &m_device_position[m_read_index];
    args_size[as++] = sizeof(cl_mem);
    args_indices[ai++] = 2;

    args_value[av++] = &m_device_velocity[m_read_index];
    args_size[as++] = sizeof(cl_mem);
    args_indices[ai++] = 3;

    err = CL_SUCCESS;
    for (i = 0; i < av; i++)
        err |= clSetKernelArg(m_compute_kernel, args_indices[i], args_size[i], args_value[i]);

    if (err != CL_SUCCESS)
        return -1;

    for (i = 0; i < m_device_count; i++)
        err |= clEnqueueNDRangeKernel(m_compute_commands[i], m_compute_kernel, 2, NULL, global_dim, local_dim, 0, NULL, NULL);

    if (err != CL_SUCCESS)
        return -2;

    return 0;
}

int GPUSimulation::resetDevice()
{
    unsigned int i = 0;
    int err = CL_SUCCESS;
    RandomizeBodiesPackedData(m_active_params.m_config, (float*) m_host_position, (float*) m_host_velocity, (float*) m_host_color, m_active_params.m_cluster_scale, m_active_params.m_velocity_scale, m_body_count);

    for (i = 0; i < m_device_count; i++)
        err |= clEnqueueWriteBuffer(m_compute_commands[i], m_device_position[m_read_index], CL_TRUE, 0,  sizeof(float4) * m_body_count, m_host_position, 0, 0, 0);
    if (err)
        return -1;

    for (i = 0; i < m_device_count; i++)
        err |= clEnqueueWriteBuffer(m_compute_commands[i], m_device_velocity[m_read_index], CL_TRUE, 0,  sizeof(float4) * m_body_count, m_host_velocity, 0, 0, 0);
    if (err)
        return -1;

    float slow_step = m_active_params.m_timestep;

    unsigned int av = 0;
    unsigned int as = 0;
    size_t args_size[32];
    void *args_value[32];

    args_value[av++] = &m_device_position[m_write_index];
    args_size[as++] = sizeof(cl_mem);
    
    args_value[av++] = &m_device_velocity[m_write_index];
    args_size[as++] = sizeof(cl_mem);
    
    args_value[av++] = &m_device_position[m_read_index];
    args_size[as++] = sizeof(cl_mem);
    
    args_value[av++] = &m_device_velocity[m_read_index];
    args_size[as++] = sizeof(cl_mem);
    
    args_value[av++] = (void *) & slow_step;
    args_size[as++] = sizeof(float);
    
    args_value[av++] = (void *) & m_active_params.m_damping;
    args_size[as++] = sizeof(float);
    
    args_value[av++] = (void *) & m_active_params.m_softening;
    args_size[as++] = sizeof(float);
    
    args_value[av++] = (void *) & m_body_count;
    args_size[as++] = sizeof(int);
    
    args_value[av++] = &m_start_index;                       
    args_size[as++] = sizeof(int);
    
    args_value[av++] = &m_end_index;                         
    args_size[as++] = sizeof(int);

    args_value[av++] = 0;
    args_size[as++] = sizeof(float4) * work_item_x * WORK_ITEMS_Y;

    int return_value = CL_SUCCESS;
    for (i = 0; i < av; i++)
        return_value |= clSetKernelArg(m_compute_kernel, i, args_size[i], args_value[i]);

    if (return_value)
        return -1;

    return 0;

}

void GPUSimulation::getPartialPositionData(float *pDest)
{
    int data_offset_in_floats = m_start_index * 4;
    int data_offset_bytes = data_offset_in_floats * sizeof(float);
 
    int data_size_in_floats = (m_end_index - m_start_index) * 4;
    int data_size_bytes = data_size_in_floats * sizeof(float);

    unsigned int i = 0;
    for (i = 0; i < m_device_count; i++)
        MemCopyDeviceToHost(m_compute_commands[i], (float4*)(pDest + data_offset_in_floats), m_device_position[m_read_index], data_size_bytes, data_offset_bytes);
}

void GPUSimulation::getSourcePositionData(float *pDest)
{
    unsigned int i = 0;
    for (i = 0; i < m_device_count; i++)
        MemCopyDeviceToHost(m_compute_commands[i], (float4*)pDest, m_device_position[m_read_index], m_body_count*4*sizeof(float), 0);
}

void GPUSimulation::setSourcePositionData(float *pSrc)
{
    unsigned int i = 0;
    for (i = 0; i < m_device_count; i++)
        MemCopyHostToDevice(m_compute_commands[i], (float4*)pSrc, m_device_position[m_read_index], m_body_count*4*sizeof(float));
}

void GPUSimulation::getSourceVelocityData(float *pDest)
{
    unsigned int i = 0;
    for (i = 0; i < m_device_count; i++)
        MemCopyDeviceToHost(m_compute_commands[i], (float4*)pDest, m_device_velocity[m_read_index], m_body_count*4*sizeof(float), 0);
}

void GPUSimulation::setSourceVelocityData(float *pSrc)
{
    unsigned int i = 0;
    for (i = 0; i < m_device_count; i++)
        MemCopyHostToDevice(m_compute_commands[i], (float4*)pSrc, m_device_velocity[m_read_index], m_body_count*4*sizeof(float));
}

////////////////////////////////////////////////////////////////////////////////////////////////////

CPUSimulation::CPUSimulation(
    size_t nbodies, 
    NBodyParams params, 
    bool vectorized, 
    bool threaded)
: 
    Simulation(nbodies, params),
    m_vectorized(vectorized),
    m_threaded(threaded)
{
    // EMPTY!
}

CPUSimulation::~CPUSimulation()
{
    // EMPTY!
}

void CPUSimulation::initialize()
{
    m_read_index = 0;
    m_write_index = 1;

    m_host_position   = (float4 *) malloc(sizeof(float4) * m_body_count);
    m_host_color = (float4 *) malloc(sizeof(float4) * m_body_count);

    m_host_position_x[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_position_x[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_position_y[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_position_y[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_position_z[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_position_z[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_x[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_x[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_y[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_y[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_z[0] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_velocity_z[1] = (float *) malloc(sizeof(float) * m_body_count);
    m_host_mass = (float *) malloc(sizeof(float) * m_body_count);

    int err = setupComputeDevices(m_vectorized, m_threaded);
    if (err != 0)
    {
        fprintf(stderr, "setupComputeDevices() failed: %d\n", err);
    }
}

void CPUSimulation::reset()
{
    if (int err = resetDevice() != 0)
    {
        fprintf(stderr, "resetDevice() failed: %d\n", err);
    }
}

int CPUSimulation::executeScalar(unsigned int startDestIndex, unsigned int destCount)
{
    float deltaTime = m_active_params.m_timestep;
    float damping   = m_active_params.m_damping;
    float softening = m_active_params.m_softening;

    float softeningSq = softening * softening;
    float position_x, position_y, position_z;
    float velocity_x, velocity_y, velocity_z;

    unsigned int i, l;

    for (l = startDestIndex; l < startDestIndex + destCount; l++)
    {

        position_x = m_host_position_x[m_read_index][l];
        position_y = m_host_position_y[m_read_index][l];
        position_z = m_host_position_z[m_read_index][l];

        float accX = 0.0f;
        float accY = 0.0f;
        float accZ = 0.0f;

        for (i = 0; i < m_body_count; i++)
        {

            float dx = m_host_position_x[m_read_index][i] - position_x;
            float dy = m_host_position_y[m_read_index][i] - position_y;
            float dz = m_host_position_z[m_read_index][i] - position_z;

            float Mi = m_host_mass[i];

            float distSqr = dx * dx + dy * dy + dz * dz;
            distSqr += softeningSq;

            float invDist = 1.0f / sqrtf(distSqr);
            float s = (Mi * invDist) * (invDist * invDist);

            accX += dx * s;
            accY += dy * s;
            accZ += dz * s;

        }


        velocity_x = m_host_velocity_x[m_read_index][l];
        velocity_y = m_host_velocity_y[m_read_index][l];
        velocity_z = m_host_velocity_z[m_read_index][l];

        velocity_x += accX * deltaTime;
        velocity_y += accY * deltaTime;
        velocity_z += accZ * deltaTime;
        velocity_x *= damping;
        velocity_y *= damping;
        velocity_z *= damping;

        position_x += velocity_x * deltaTime;
        position_y += velocity_y * deltaTime;
        position_z += velocity_z * deltaTime;

        m_host_position_x[m_write_index][l] = position_x;
        m_host_position_y[m_write_index][l] = position_y;
        m_host_position_z[m_write_index][l] = position_z;

        m_host_velocity_x[m_write_index][l] = velocity_x;
        m_host_velocity_y[m_write_index][l] = velocity_y;
        m_host_velocity_z[m_write_index][l] = velocity_z;

        m_host_position[l].data[0] = position_x;
        m_host_position[l].data[1] = position_y;
        m_host_position[l].data[2] = position_z;
        m_host_position[l].data[3] = 1.0f;
    }

    return 0;
}

void CPUSimulation::step()
{
    int err = 0;
    if (!m_vectorized && !m_threaded)
    {
        executeScalar(m_start_index, m_end_index - m_start_index);
    }
    else
    {
        err = executeKernel();
        if (err != 0)
            fprintf(stderr, "executeKernel() failed: %d\n", err);
    }

    if (m_update_external_data) giveData(m_host_position);

    std::swap(m_read_index, m_write_index);
}

void CPUSimulation::terminate()
{
    if(m_host_position)
        free(m_host_position);
    m_host_position = 0;
    
    if(m_host_color)
        free(m_host_color);
    m_host_color = 0;
    
    if(m_host_mass)
        free(m_host_mass);
    m_host_mass = 0;
    
    int i;
    for(i = 0; i < 2; i++)
    {
        if(m_host_position_x[i])
            free(m_host_position_x[i]);
        m_host_position_x[i] = 0;

        if(m_host_position_y[i])
            free(m_host_position_y[i]);
        m_host_position_y[i] = 0;

        if(m_host_position_z[i])
            free(m_host_position_z[i]);
        m_host_position_z[i] = 0;

        if(m_host_velocity_x[i])
            free(m_host_velocity_x[i]);
        m_host_velocity_x[i] = 0;

        if(m_host_velocity_y[i])
            free(m_host_velocity_y[i]);
        m_host_velocity_y[i] = 0;

        if(m_host_velocity_z[i])
            free(m_host_velocity_z[i]);
        m_host_velocity_z[i] = 0;
    }

    if (m_compute_context)
    {
        unsigned int i = 0;

        clFinish(m_compute_commands);
        clReleaseCommandQueue(m_compute_commands);

        for(i = 0; i < 2; i++)
        {
            clReleaseMemObject(m_device_position_x[i]);
            clReleaseMemObject(m_device_position_y[i]);
            clReleaseMemObject(m_device_position_z[i]);
            
            clReleaseMemObject(m_device_velocity_x[i]);
            clReleaseMemObject(m_device_velocity_y[i]);
            clReleaseMemObject(m_device_velocity_z[i]);
        }

        clReleaseMemObject(m_device_mass);
        clReleaseMemObject(m_device_position);

        clReleaseKernel(m_compute_kernel);
        clReleaseProgram(m_compute_program);
        clReleaseContext(m_compute_context);    
    }
}

void *CPUSimulation::getColorData()
{
    return m_host_color;
}

int CPUSimulation::setupComputeDevices(bool vectorized, bool threaded)
{
    int return_value;
    char *source;
    size_t src_len;

    size_t args_size[20];
    void *args_value[20];

    return_value = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_CPU, 1, &m_compute_device_id, &m_device_count);
    if (return_value)
        return -1;

    m_compute_context = clCreateContext(0, m_device_count, &m_compute_device_id, 0, 0, &return_value);
    if (!m_compute_context)
        return -4;

    m_compute_commands = clCreateCommandQueue(m_compute_context, m_compute_device_id, 0, &return_value);
    if (!m_compute_commands)
        return -2;

    size_t returned_size;
    unsigned int compute_units;

    clGetDeviceInfo(m_compute_device_id, CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(unsigned int), &compute_units,  &returned_size);
    m_compute_units = threaded ? compute_units : 1;

    return_value = LoadFileIntoString("nbody_cpu.cl", &source, &src_len);
    if (return_value)
        return -4;

    m_compute_program = clCreateProgramWithSource(m_compute_context, 1, (const char**) & source, 0, &return_value);
    if (!m_compute_program)
        return -6;

    return_value = clBuildProgram(m_compute_program, m_device_count, &m_compute_device_id, 0, NULL, NULL);
    if (return_value != CL_SUCCESS)
    {
        size_t length = 0;
        char info_log[2000];
        clGetProgramBuildInfo(m_compute_program, m_compute_device_id, CL_PROGRAM_BUILD_LOG, 2000, info_log, &length);
        fprintf(stderr, "%s\n", info_log);
        return -7;
    }

    m_compute_kernel = clCreateKernel(m_compute_program, vectorized ? "IntegrateSystemVectorized" : "IntegrateSystemNonVectorized", &return_value);
    if (!m_compute_kernel)
        return -8;

    m_device_position_x[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_position_x[0], &return_value);
    if (!m_device_position_x[0])
        return -9;

    m_device_position_x[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) *  m_body_count, m_host_position_x[1], &return_value);
    if (!m_device_position_x[1])
        return -10;

    m_device_position_y[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_position_y[0], &return_value);
    if (!m_device_position_y[0])
        return -11;

    m_device_position_y[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_position_y[1], &return_value);
    if (!m_device_position_y[1])
        return -12;

    m_device_position_z[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_position_z[0], &return_value);
    if (!m_device_position_z[0])
        return -13;

    m_device_position_z[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_position_z[1], &return_value);
    if (!m_device_position_z[1])
        return -14;

    m_device_mass = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_mass, &return_value);
    if (!m_device_mass)
        return -15;

    m_device_velocity_x[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_x[0], &return_value);
    if (!m_device_velocity_x[0])
        return -16;

    m_device_velocity_x[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_x[1], &return_value);
    if (!m_device_velocity_x[1])
        return -17;

    m_device_velocity_y[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_y[0], &return_value);
    if (!m_device_velocity_y[0])
        return -18;

    m_device_velocity_y[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_y[1], &return_value);
    if (!m_device_velocity_y[1])
        return -19;

    m_device_velocity_z[0] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_z[0], &return_value);
    if (!m_device_velocity_z[0])
        return -20;

    m_device_velocity_z[1] = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float) * m_body_count, m_host_velocity_z[1], &return_value);
    if (!m_device_velocity_z[1])
        return -21;

    m_device_position = clCreateBuffer(m_compute_context, (cl_mem_flags)(CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR), sizeof(float4) * m_body_count, m_host_position, &return_value);
    if (!m_device_position)
        return -21;

    int m_body_count_per_work_group = (m_end_index - m_start_index) / m_compute_units;
    args_value[0]  = &m_device_position_x[m_write_index];
    args_size[0]  = sizeof(cl_mem);
    args_value[1]  = &m_device_position_y[m_write_index];
    args_size[1]  = sizeof(cl_mem);
    args_value[2]  = &m_device_position_z[m_write_index];
    args_size[2]  = sizeof(cl_mem);
    args_value[3]  = &m_device_mass;
    args_size[3]  = sizeof(cl_mem);
    args_value[4]  = &m_device_velocity_x[m_write_index];
    args_size[4]  = sizeof(cl_mem);
    args_value[5]  = &m_device_velocity_y[m_write_index];
    args_size[5]  = sizeof(cl_mem);
    args_value[6]  = &m_device_velocity_z[m_write_index];
    args_size[6]  = sizeof(cl_mem);
    args_value[7]  = &m_device_position_x[m_read_index];
    args_size[7]  = sizeof(cl_mem);
    args_value[8]  = &m_device_position_y[m_read_index];
    args_size[8]  = sizeof(cl_mem);
    args_value[9]  = &m_device_position_z[m_read_index];
    args_size[9]  = sizeof(cl_mem);
    args_value[10] = &m_device_velocity_x[m_read_index];
    args_size[10] = sizeof(cl_mem);
    args_value[11] = &m_device_velocity_y[m_read_index];
    args_size[11] = sizeof(cl_mem);
    args_value[12] = &m_device_velocity_z[m_read_index];
    args_size[12] = sizeof(cl_mem);
    float slow_step = m_active_params.m_timestep;
    args_value[13] = (void *) & slow_step;
    args_size[13] = sizeof(float);
    args_value[14] = (void *) & m_active_params.m_damping;
    args_size[14] = sizeof(float);
    args_value[15] = (void *) & m_active_params.m_softening;
    args_size[15] = sizeof(float);
    args_value[16] = (void *) & m_body_count;
    args_size[16] = sizeof(int);
    args_value[17] = (void *) & m_body_count_per_work_group;
    args_size[17] = sizeof(int);
    args_value[18] = &m_device_position;
    args_size[18] = sizeof(cl_mem);
    args_value[19] = (void *) & m_start_index;
    args_size[19] = sizeof(int);

    int i;
    return_value = CL_SUCCESS;
    for (i = 0; i < 20; i++)
        return_value |= clSetKernelArg(m_compute_kernel, i, args_size[i], args_value[i]);

    if (return_value)
        return -22;

    free(source);
    return 0;
}

int CPUSimulation::executeKernel()
{
    int err = CL_SUCCESS;
    void *args_value[32];
    size_t args_size[32];
    unsigned args_indices[32];

    size_t global_dim[2];
    size_t local_dim[2];

    local_dim[0]  = 1;
    local_dim[1]  = 1;

    global_dim[0] = m_compute_units;
    global_dim[1] = 1;

    int m_body_count_per_work_group = (m_end_index - m_start_index) / m_compute_units;

    args_value[0]  = &m_device_position_x[m_write_index];
    args_size[0]  = sizeof(cl_mem);
    args_indices[0]  = 0;
    
    args_value[1]  = &m_device_position_y[m_write_index];
    args_size[1]  = sizeof(cl_mem);
    args_indices[1]  = 1;
    
    args_value[2]  = &m_device_position_z[m_write_index];
    args_size[2]  = sizeof(cl_mem);
    args_indices[2]  = 2;
    
    args_value[3]  = &m_device_velocity_x[m_write_index];
    args_size[3]  = sizeof(cl_mem);
    args_indices[3]  = 4;
    
    args_value[4]  = &m_device_velocity_y[m_write_index];
    args_size[4]  = sizeof(cl_mem);
    args_indices[4]  = 5;
    
    args_value[5]  = &m_device_velocity_z[m_write_index];
    args_size[5]  = sizeof(cl_mem);
    args_indices[5]  = 6;
    
    args_value[6]  = &m_device_position_x[m_read_index];
    args_size[6]  = sizeof(cl_mem);
    args_indices[6]  = 7;
    
    args_value[7]  = &m_device_position_y[m_read_index];
    args_size[7]  = sizeof(cl_mem);
    args_indices[7]  = 8;
    
    args_value[8]  = &m_device_position_z[m_read_index];
    args_size[8]  = sizeof(cl_mem);
    args_indices[8]  = 9;
    
    args_value[9]  = &m_device_velocity_x[m_read_index];
    args_size[9]  = sizeof(cl_mem);
    args_indices[9]  = 10;
    
    args_value[10] = &m_device_velocity_y[m_read_index];
    args_size[10] = sizeof(cl_mem);
    args_indices[10] = 11;
    
    args_value[11] = &m_device_velocity_z[m_read_index];
    args_size[11] = sizeof(cl_mem);
    args_indices[11] = 12;
    
    args_value[12] = &m_body_count_per_work_group;
    args_size[12] = sizeof(int);
    args_indices[12] = 17;
    
    args_value[13] = &m_device_position;
    args_size[13] = sizeof(cl_mem);
    args_indices[13] = 18;
    
    args_value[14] = &m_start_index;
    args_size[14] = sizeof(int);
    args_indices[14] = 19;

    int i;
    err = CL_SUCCESS;
    for (i = 0; i < 15; i++)
        err |= clSetKernelArg(m_compute_kernel, args_indices[i], args_size[i], args_value[i]);

    if (err != CL_SUCCESS)
        return -3;

    err = clEnqueueNDRangeKernel(m_compute_commands, m_compute_kernel, 2, NULL, global_dim, local_dim, 0, NULL, NULL);

    err |= clFinish(m_compute_commands);
    if (err != CL_SUCCESS)
        return -4;

    return 0;
}

int CPUSimulation::resetDevice()
{
    RandomizeBodiesSplitData(m_active_params.m_config, m_host_position_x[m_read_index], m_host_position_y[m_read_index], m_host_position_z[m_read_index], m_host_mass, m_host_velocity_x[m_read_index], m_host_velocity_y[m_read_index], m_host_velocity_z[m_read_index], (float *) m_host_color, m_active_params.m_cluster_scale, m_active_params.m_velocity_scale, m_body_count);
    for ( unsigned int i = 0; i < m_body_count; i++ )
    {
        ((float *)m_host_position)[4*i+0] = m_host_position_x[m_read_index][i];
        ((float *)m_host_position)[4*i+1] = m_host_position_y[m_read_index][i];
        ((float *)m_host_position)[4*i+2] = m_host_position_z[m_read_index][i];
        ((float *)m_host_position)[4*i+3] = m_host_mass[i];
    }
    size_t args_size[20];
    void *args_value[20];

    int m_body_count_per_work_group = (m_end_index - m_start_index) / m_device_count;
    args_value[0]  = &m_device_position_x[m_write_index];
    args_size[0] = sizeof(cl_mem);
    args_value[1]  = &m_device_position_y[m_write_index];
    args_size[1] = sizeof(cl_mem);
    args_value[2]  = &m_device_position_z[m_write_index];
    args_size[2] = sizeof(cl_mem);
    args_value[3]  = &m_device_mass;
    args_size[3] = sizeof(cl_mem);
    args_value[4]  = &m_device_velocity_x[m_write_index];
    args_size[4] = sizeof(cl_mem);
    args_value[5]  = &m_device_velocity_y[m_write_index];
    args_size[5] = sizeof(cl_mem);
    args_value[6]  = &m_device_velocity_z[m_write_index];
    args_size[6] = sizeof(cl_mem);
    args_value[7]  = &m_device_position_x[m_read_index];
    args_size[7] = sizeof(cl_mem);
    args_value[8]  = &m_device_position_y[m_read_index];
    args_size[8] = sizeof(cl_mem);
    args_value[9]  = &m_device_position_z[m_read_index];
    args_size[9] = sizeof(cl_mem);
    args_value[10] = &m_device_velocity_x[m_read_index];
    args_size[10] = sizeof(cl_mem);
    args_value[11] = &m_device_velocity_y[m_read_index];
    args_size[11] = sizeof(cl_mem);
    args_value[12] = &m_device_velocity_z[m_read_index];
    args_size[12] = sizeof(cl_mem);
    float slow_step = m_active_params.m_timestep;
    args_value[13] = (void *) & slow_step;
    args_size[13] = sizeof(float);
    args_value[14] = (void *) & m_active_params.m_damping;
    args_size[14] = sizeof(float);
    args_value[15] = (void *) & m_active_params.m_softening;
    args_size[15] = sizeof(float);
    args_value[16] = (void *) & m_body_count;
    args_size[16] = sizeof(int);
    args_value[17] = (void *) & m_body_count_per_work_group;
    args_size[17] = sizeof(int);
    args_value[18] = &m_device_position;
    args_size[18] = sizeof(cl_mem);
    args_value[19] = (void *) & m_start_index;
    args_size[19] = sizeof(int);

    int i;
    int return_value = CL_SUCCESS;
    for (i = 0; i < 20; i++)
        return_value |= clSetKernelArg(m_compute_kernel, i, args_size[i], args_value[i]);

    if (return_value)
        return -1;

    return 0;
}

void CPUSimulation::getPartialPositionData(float *p)
{
    int data_offset_in_floats = m_start_index * 4;
    int data_size_in_floats = (m_end_index - m_start_index) * 4;
    int data_size_bytes = data_size_in_floats * sizeof(float);

    memcpy( p + data_offset_in_floats, m_host_position + (data_offset_in_floats / 4), data_size_bytes );
}

void CPUSimulation::getSourcePositionData(float *p)
{
    memcpy(p, m_host_position, sizeof(float)*4*m_body_count);
}

void CPUSimulation::setSourcePositionData(float *pSrc)
{
    for ( unsigned int i = 0; i < m_body_count; i++ )
    {
        m_host_position_x[m_read_index][i] = ((float *)m_host_position)[4*i + 0] = pSrc[4*i + 0];
        m_host_position_y[m_read_index][i] = ((float *)m_host_position)[4*i + 1] = pSrc[4*i + 1];
        m_host_position_z[m_read_index][i] = ((float *)m_host_position)[4*i + 2] = pSrc[4*i + 2];
    }
}

void CPUSimulation::getSourceVelocityData(float *pDest)
{
    for ( unsigned int i = 0; i < m_body_count; i++ )
    {
        pDest[4*i + 0] = m_host_velocity_x[m_read_index][i];
        pDest[4*i + 1] = m_host_velocity_y[m_read_index][i];
        pDest[4*i + 2] = m_host_velocity_z[m_read_index][i];
    }
}

void CPUSimulation::setSourceVelocityData(float *pSrc)
{
    for ( unsigned int i = 0; i < m_body_count; i++ )
    {
        m_host_velocity_x[m_read_index][i] = pSrc[4*i + 0];
        m_host_velocity_y[m_read_index][i] = pSrc[4*i + 1];
        m_host_velocity_z[m_read_index][i] = pSrc[4*i + 2];
    }
}
