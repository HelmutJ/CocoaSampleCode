//
// File:       randomize.cpp
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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <math.h>
#include <unistd.h>
#include <algorithm>
#include <iostream>
#include <fstream>

#include "randomize.h"
#include "types.h"
#include "data.h"

const char * GalaxyDataFiles[] = 
{
    "bodies_16k.dat", 
    "bodies_24k.dat", 
    "bodies_32k.dat", 
    "bodies_64k.dat", 
    "bodies_80k.dat", 
};

const int GalaxyDataFileCount = sizeof(GalaxyDataFiles) / sizeof(char*);

static void SetupGalaxyColor(
    int body, float *color, int bID)
{
    int c = body * 4;
    int index = 3;
    
    static const float palette[][4] =
    {
        {0.3f,  0.4f,  0.6f,  0.05f}, // blue
        {0.6f,  0.6f,  0.6f,  0.05f}, // white
        {0.5f,  0.3f,  0.3f,  0.05f}, // red
        {0.5f,  0.5f,  0.3f,  0.05f}, // yellow
        {0.2f,  0.2f,  0.2f,  0.01f}, // gray
        {0.5f,  0.1f,  0.02f, 0.05f}, // bulge
        {0.4f,  0.3f,  0.02f, 0.05f}, // bulge
    };
    
    if (color)
    {
        if (bID >= 1 && bID <= 4)
        {
            index = body & (4 - 1);
        }
        else
        {   
            index = 4;
        }

        memcpy(&color[c], palette[index], 4*sizeof(float));
    }
}

void RandomizeBodiesPackedData(
    NBodyConfig config, 
    float* pos, 
    float* vel, 
    float* color, 
    float cluster_scale, 
    float velocity_scale, 
    int body_count)
{
    if (color)
    {
        int v = 0;
        for (int i = 0; i < body_count; i++)
        {
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = 1.0f;
        }
    }
    switch (config)
    {
    default:
    case NBODY_CONFIG_RANDOM:
    {
        float scale = cluster_scale * std::max(1.0f, body_count / (1024.f));
        float vscale = velocity_scale * scale;

        int p = 0, v = 0;
        int i = 0;
        while (i < body_count)
        {
            float3 point;
            point[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            float lenSqr = dot3f(point, point);
            if (lenSqr > 1)
                continue;
            float3 velocity;
            velocity[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            velocity[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            velocity[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            lenSqr = dot3f(velocity, velocity);
            if (lenSqr > 1)
                continue;

            pos[p++] = point[0] * scale; // pos.x
            pos[p++] = point[1] * scale; // pos.y
            pos[p++] = point[2] * scale; // pos.z
            pos[p++] = 1.0f; // mass

            vel[v++] = velocity[0] * vscale; // pos.x
            vel[v++] = velocity[1] * vscale; // pos.x
            vel[v++] = velocity[2] * vscale; // pos.x
            vel[v++] = 1.0f; // inverse mass

            i++;
        }
    }
    break;
    case NBODY_CONFIG_SHELL:
    {
        float scale = cluster_scale;
        float vscale = scale * velocity_scale;
        float inner = 2.5f * scale;
        float outer = 4.0f * scale;

        int p = 0, v = 0;
        int i = 0;
        while (i < body_count)
        {
            float x, y, z;
            x = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            y = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            z = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;

            float3 point = { {x, y, z} };
            float len = normalize3f(point);
            if (len > 1)
                continue;

            pos[p++] =  point[0] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            pos[p++] =  point[1] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            pos[p++] =  point[2] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            pos[p++] = 16384.0f / (float)body_count;

            x = 0.0f;
            y = 0.0f;
            z = 1.0f;
            float3 axis = { {x, y, z} };
            normalize3f(axis);

            if (1 - dot3f(point, axis) < 1e-6)
            {
                axis[0] = point[1];
                axis[1] = point[0];
                normalize3f(axis);
            }

            float3 vv = { {pos[4*i], pos[4*i+1], pos[4*i+2]} };
            vv = cross3f(vv, axis);
            vel[v++] = vv[0] * vscale;
            vel[v++] = vv[1] * vscale;
            vel[v++] = vv[2] * vscale;
            vel[v++] = (float)body_count * (1.0f / 16384.0f);

            i++;
        }
    }
    break;
    case NBODY_CONFIG_MWM31:       //////////////     Galaxy collision ////////////////////////////
    {
        float scale = cluster_scale;
        float vscale = scale * velocity_scale;
        float mscale = scale * scale * scale;

        int p = 0;
        int v = 0;

        std::ifstream *infile;

        switch (body_count)
        {
        case 16384:
            infile = new std::ifstream(GalaxyDataFiles[0]);
            break;
        case 24576:
            infile = new std::ifstream(GalaxyDataFiles[1]);
            break;
        case 32768:
            infile = new std::ifstream(GalaxyDataFiles[2]);
            break;
        case 65536:
            infile = new std::ifstream(GalaxyDataFiles[3]);
            break;
        case 81920:
            infile = new std::ifstream(GalaxyDataFiles[4]);
            break;
        default:
            printf("Numbodies must be one of 16384, 24576, 32768, 65536, 81920, 131072 or 1048576.\n");
            exit(1);
            break;
        }

        int numPoints = 0;

        float pX, pY, pZ, vX, vY, vZ, bMass, bIDf;
        int bID;
        if (!infile->fail())
        {
            while (!(infile->eof()) && numPoints < body_count)
            {

                numPoints++;
                *infile >> bMass >> pX >> pY >> pZ >> vX >> vY >> vZ >> bIDf;

                bID = (int)bIDf;

                bMass *= mscale;

                pos[p++] = scale * pX;
                pos[p++] = scale * pY;
                pos[p++] = scale * pZ;
                pos[p++] = bMass;
                vel[v++] = vscale * vX;
                vel[v++] = vscale * vY;
                vel[v++] = vscale * vZ;
                vel[v++] = 1.0 / bMass;
                SetupGalaxyColor(numPoints - 1, color, bID);
            }
        }
        delete infile;
    }
    break;
    case NBODY_CONFIG_EXPAND:
    {
        float scale = cluster_scale * std::max(1.0f, body_count / (1024.f));
        float vscale = scale * velocity_scale;

        int p = 0, v = 0;
        for (int i = 0; i < body_count;)
        {
            float3 point;

            point[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;

            float lenSqr = dot3f(point, point);
            if (lenSqr > 1)
                continue;

            pos[p++] = point[0] * scale; // pos.x
            pos[p++] = point[1] * scale; // pos.y
            pos[p++] = point[2] * scale; // pos.z
            pos[p++] = 1.0f; // mass
            vel[v++] = point[0] * vscale; // pos.x
            vel[v++] = point[1] * vscale; // pos.x
            vel[v++] = point[2] * vscale; // pos.x
            vel[v++] = 1.0f; // inverse mass

            i++;
        }
    }
    break;
    }

}

void RandomizeBodiesSplitData(NBodyConfig config, float* position_x, float *position_y, float *position_z, float *mass,
                         float* velocity_x, float *velocity_y, float *velocity_z, float* color, float cluster_scale, float velocity_scale, int body_count)
{
    if (color)
    {
        int v = 0;
        for (int i = 0; i < body_count; i++)
        {
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = (float) rand() / (float) RAND_MAX;
            color[v++] = 1.0f;
        }
    }
    switch (config)
    {
    default:
    case NBODY_CONFIG_RANDOM:
    {
        float scale = cluster_scale * std::max(1.0f, body_count / (1024.f));
        float vscale = velocity_scale * scale;

        int p = 0, v = 0;
        int i = 0;
        while (i < body_count)
        {
            float3 point;
            point[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            float lenSqr = dot3f(point, point);
            if (lenSqr > 1)
                continue;
            float3 velocity;
            velocity[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            velocity[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            velocity[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            lenSqr = dot3f(velocity, velocity);
            if (lenSqr > 1)
                continue;

            position_x[p] = point[0] * scale; // pos.x
            position_y[p] = point[1] * scale; // pos.y
            position_z[p] = point[2] * scale; // pos.z
            mass[p] = 1.0f; // mass

            velocity_x[v] = velocity[0] * vscale; // pos.x
            velocity_y[v] = velocity[1] * vscale; // pos.x
            velocity_z[v] = velocity[2] * vscale; // pos.x

            p++;
            v++;
            i++;
        }
    }
    break;
    case NBODY_CONFIG_SHELL:
    {
        float scale = cluster_scale;
        float vscale = scale * velocity_scale;
        float inner = 2.5f * scale;
        float outer = 4.0f * scale;

        int p = 0, v = 0;
        int i = 0;
        while (i < body_count)
        {
            float x, y, z;
            x = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            y = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            z = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;

            float3 point = { {x, y, z} };
            float len = normalize3f(point);
            if (len > 1)
                continue;

            position_x[p] =  point[0] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            position_y[p] =  point[1] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            position_z[p] =  point[2] * (inner + (outer - inner) * rand() / (float) RAND_MAX);
            mass[p] = 1.0f;

            x = 0.0f;
            y = 0.0f;
            z = 1.0f;
            float3 axis = { {x, y, z} };
            normalize3f(axis);

            if (1 - dot3f(point, axis) < 1e-6)
            {
                axis[0] = point[1];
                axis[1] = point[0];
                normalize3f(axis);
            }

            float3 vv = { {position_x[i], position_y[i], position_z[i]} };
            vv = cross3f(vv, axis);
            velocity_x[v] = vv[0] * vscale;
            velocity_y[v] = vv[1] * vscale;
            velocity_z[v] = vv[2] * vscale;

            p++;
            v++;
            i++;
        }
    }
    break;
    case NBODY_CONFIG_MWM31:       //////////////     Galaxy collision ////////////////////////////
    {
        float scale = cluster_scale;
        float vscale = scale * velocity_scale;
        float mscale = scale * scale * scale;

        std::ifstream *infile;

        switch (body_count)
        {
        case 16384:
            infile = new std::ifstream(GalaxyDataFiles[0]);
            break;
        case 24576:
            infile = new std::ifstream(GalaxyDataFiles[1]);
            break;
        case 32768:
            infile = new std::ifstream(GalaxyDataFiles[2]);
            break;
        case 65536:
            infile = new std::ifstream(GalaxyDataFiles[3]);
            break;
        case 81920:
            infile = new std::ifstream(GalaxyDataFiles[4]);
            break;
        default:
            printf("Numbodies must be one of 16384, 24576, 32768, 65536 or 81920.\n");
            exit(1);
            break;
        }

        int numPoints = 0;

        int p = 0;

        float pX, pY, pZ, vX, vY, vZ, bMass, bIDf;
        int bID;
        if (!infile->fail())
        {

            while (!(infile->eof()) && numPoints < body_count)
            {

                numPoints++;

                *infile >> bMass >> pX >> pY >> pZ >> vX >> vY >> vZ >> bIDf;

                bID = (int)bIDf;

                bMass *= mscale;

                position_x[p] = scale * pX;
                position_y[p] = scale * pY;
                position_z[p] = scale * pZ;
                mass[p] = bMass;
                velocity_x[p] = vscale * vX;
                velocity_y[p] = vscale * vY;
                velocity_z[p] = vscale * vZ;
                SetupGalaxyColor(p, color, bID);
                p++;
            }
        }
        delete infile;
    }
    break;
    case NBODY_CONFIG_EXPAND:
    {
        float scale = cluster_scale * std::max(1.0f, body_count / (1024.f));
        float vscale = scale * velocity_scale;

        int p = 0, v = 0;
        for (int i = 0; i < body_count;)
        {
            float3 point;

            point[0] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[1] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;
            point[2] = (float) rand() / (float) RAND_MAX * 2.0f - 1.0f;

            float lenSqr = dot3f(point, point);
            if (lenSqr > 1)
                continue;

            position_x[p] = point[0] * scale; // pos.x
            position_y[p] = point[1] * scale; // pos.y
            position_z[p] = point[2] * scale; // pos.z
            mass[p] = 1.0f; // mass
            
            velocity_x[v] = point[0] * vscale; // pos.x
            velocity_y[v] = point[1] * vscale; // pos.x
            velocity_z[v] = point[2] * vscale; // pos.x

            p++;
            v++;
            i++;
        }
    }
    break;
    }
}
