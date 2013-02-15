//
// File:       simulation.h
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

#ifndef __SIMULATION_H__
#define __SIMULATION_H__

#include <cstddef>
#include <cstdlib>
#include <pthread.h>
#include <pthread.h>
#include <sys/time.h>
#include <OpenCL/opencl.h>

#include "nbody.h"
#include "types.h"
#include "data.h"
#include "hud.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

struct NBodyParams
{
    float m_timestep;
    float m_cluster_scale;
    float m_velocity_scale;
    float m_softening;
    float m_damping;
    float m_point_size;
    float m_rotate_x, m_rotate_y;
    float m_viewDistance;
    NBodyConfig m_config;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

class Simulation
{
public:
    Simulation(size_t nbodies, NBodyParams params);
    virtual ~Simulation();

    virtual void initialize() = 0;
    virtual void reset() = 0;
    virtual void step() = 0;
    virtual void terminate() = 0;

    virtual void *getColorData() = 0;
    
    virtual void getSourcePositionData(float*)  = 0;
    virtual void setSourcePositionData(float*)  = 0;
    virtual void setSourceVelocityData(float*)  = 0;
    virtual void getSourceVelocityData(float*)  = 0;
    virtual void getPartialPositionData(float*) = 0;

    virtual const char* getDeviceName() const    { return m_device_name;    }

public:

    void start(bool paused=true);
    void pause();
    void unpause();
    void stop();
    void reset(NBodyParams params);

    bool isInitialized();

    double getGigaFlops() const;
    double getUpdatesPerSecond() const;
    double getYear() const;

    void setActiveParams(NBodyParams params);

    void setStartIndex( int body )      { m_start_index = body;        }
    void setEndIndex( int body )        { m_end_index = body;          }

    int getStartIndex()                 { return m_start_index;        }
    int getEndIndex()                   { return m_end_index;          }
    
    void setUpdateExternalData(bool v = true)    { m_update_external_data = v;  }

    void giveData(void *data);
    void *takeData();


private:

    void run();
    friend void *simulate(void *arg);

protected:

    bool            m_initialized;
    bool            m_update_external_data;

    size_t		    m_body_count;
    int			    m_start_index;
    int			    m_end_index;

    NBodyParams     m_active_params;
    unsigned int    m_device_count;
    char		    m_device_name[1024];

private:
    enum RunMode
    {
        PAUSE,
        RUN,
        STOP,
    };

private:

    void * volatile     m_data;

    pthread_t           m_thread;
    pthread_mutex_t     m_run_lock;

    RunMode m_run_mode;
    bool                m_stop;
    bool                m_reload;
    bool                m_paused;

    StuffPerSecondMeter m_gigaflops_meter;
    double              m_gigaflops;

    StuffPerSecondMeter m_updates_per_second_meter;
    double              m_updates_per_second;

    double              m_year;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

class GPUSimulation : public Simulation
{
public:

    GPUSimulation(
        size_t nbodies, 
        NBodyParams params,
        unsigned int device_count = 1,
        int device_index = -1);

    virtual ~GPUSimulation();

    virtual void initialize();
    virtual void reset();
    virtual void step();
    virtual void terminate();

    virtual void* getColorData();
    virtual void getSourcePositionData(float*);
    virtual void setSourcePositionData(float*);
    virtual void getSourceVelocityData(float*);
    virtual void setSourceVelocityData(float*);
    virtual void getPartialPositionData(float *pDest);

private:

    int setupComputeDevices();
    int executeKernel();
    int resetDevice();

private:
    unsigned int        m_read_index;
    unsigned int        m_write_index;
    int                 m_device_index;

    float4*             m_host_position;
    float4*             m_host_velocity;
    float4*             m_host_color;

    cl_device_id        m_device_id[2];
    cl_command_queue    m_compute_commands[2];
    cl_context          m_compute_context;
    cl_program          m_compute_program;
    cl_kernel           m_compute_kernel;
    cl_mem              m_device_position[2];
    cl_mem              m_device_velocity[2];
    cl_mem              m_body_range_params;
  
    int                 work_item_x;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

class CPUSimulation : public Simulation
{
public:
    CPUSimulation(size_t nbodies, NBodyParams params, bool vectorize, bool thread);
    virtual ~CPUSimulation();
    virtual void *getColorData();
    virtual void initialize();
    virtual void reset();
    virtual void step();
    virtual void terminate();

    virtual void getSourcePositionData(float *);
    virtual void setSourcePositionData(float*);
    virtual void setSourceVelocityData(float*);
    virtual void getSourceVelocityData(float *);
    virtual void getPartialPositionData(float *);

private:
    int setupComputeDevices(bool vectorize, bool thread);
    int executeKernel();
    int executeScalar(unsigned int startDestIndex, unsigned int destCount);
    int resetDevice();

private:
    bool             m_vectorized;
    bool             m_threaded;

    unsigned int     m_compute_units;
    unsigned int     m_read_index;
    unsigned int     m_write_index;

    float4*          m_host_position;
    float4*          m_host_color;
    float*           m_host_position_x[2];
    float*           m_host_position_y[2];
    float*           m_host_position_z[2];
    float*           m_host_mass;
    float*           m_host_velocity_x[2];
    float*           m_host_velocity_y[2];
    float*           m_host_velocity_z[2];

    cl_device_id     m_compute_device_id;
    cl_command_queue m_compute_commands;
    cl_context       m_compute_context;
    cl_program       m_compute_program;
    cl_kernel        m_compute_kernel;

    cl_mem           m_device_position_x[2];
    cl_mem           m_device_position_y[2];
    cl_mem           m_device_position_z[2];
    cl_mem           m_device_mass;
    cl_mem           m_device_velocity_x[2];
    cl_mem           m_device_velocity_y[2];
    cl_mem           m_device_velocity_z[2];
    cl_mem           m_device_position;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

#endif
