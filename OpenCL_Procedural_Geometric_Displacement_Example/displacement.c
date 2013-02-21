//
// File:       displacement.c
//
// Abstract:   This example shows how OpenCL can bind to existing OpenGL buffers
//             to avoid copying data back off a compute device when using the results
//             for rendering.  This is demonstrated by displacing the vertices of
//             an OpenGL managed vertex buffer object (VBO) using a compute
//             kernel which calculates several octaves of procedural noise to push
//             the resulting vertex positions outwards and calculate new normal 
//             directions using finite differences.
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

#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <OpenGL/OpenGL.h>
#include <GLUT/glut.h>
#include <OpenCL/opencl.h>

#include <mach/mach_time.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

#define USE_GL_ATTACHMENTS                      (1)  // enable OpenGL attachments for Compute results
#define COMPUTE_KERNEL_FILENAME                 ("displacement_kernel.cl")
#define COMPUTE_KERNEL_METHOD_NAME              ("displace")
#define SEPARATOR                               ("----------------------------------------------------------------------\n")

////////////////////////////////////////////////////////////////////////////////////////////////////

static int Animate                              = 1;

static int Width                                = 1024;
static int Height                               = 1024;

static int SphereResolution                     = 8;
static float Frequency                          = 1.0f; 
static float Amplitude                          = 0.35f; 
static float Octaves                            = 5.5f; 
static float Roughness                          = 0.025f;
static float Lacunarity                         = 2.0f;
static float Increment                          = 1.5f; 

static float RefractiveIndex                    = 1.33f;   // water
static float ChromaticDispersion                = 0.01f;

static float FresnelBias                        = 0.5f;
static float FresnelScale                       = 1.0f;
static float FresnelPower                       = 1.0f;

static float LightPosition[4]                   = { -7.0f, 10.0f, 7.0f, 1.0f };

static float LightFovY                          = 45.0f;
static float LightNearZ                         = 10.0f;
static float LightFarZ                          = 20.0f;

static float CameraAspect                       = 1.0f;
static float CameraFovY                         = 55.0f;
static float CameraNearZ                        = 0.1f;
static float CameraFarZ                         = 20.0f;

static float CameraRotation[]                   = { 0.0f, 0.0f, 0.0f, 0.0f  };
static float CameraPositionLag[]                = { 0.0f, 0.0f, -3.0f, 1.0f };
static float CameraRotationLag[]                = { 0.0f, 0.0f, 0.0f, 1.0f  };

static float CameraPosition[4]                  = { 0.0f, 0.5f, -7.0f, 1.0f };
static float CameraView[4]                      = { 0.0f, 0.0f, 1.0f, 1.0f };
static float CameraUp[4]                        = { 0.0f, 1.0f, 0.0f, 1.0f };

static float ShadowTextColor[4]                 = { 0.2f, 0.2f, 0.2f, 1.0f };
static float HighlightTextColor[4]              = { 0.8f, 0.8f, 0.8f, 1.0f };

////////////////////////////////////////////////////////////////////////////////

#if (USE_GL_ATTACHMENTS)
static GLenum BufferModeType                    = GL_STATIC_DRAW_ARB;
#else
static GLenum BufferModeType                    = GL_DYNAMIC_DRAW_ARB;
#endif

static unsigned int VertexBytes                 = 0;
static unsigned int VertexElements              = 0;
static unsigned int VertexComponents            = 4;

static float* VertexBuffer                      = 0;
static unsigned int VertexBufferId              = 0;

static float* NormalBuffer                      = 0;
static unsigned int NormalBufferId              = 0;

static unsigned int DisableTexUnit              = GL_TEXTURE0_ARB;

static unsigned int ShadowMapTexUnit            = GL_TEXTURE1_ARB;
static unsigned int ShadowMapTextureId          = 0;
static unsigned int ShadowMapFrameBufferId      = 0;
static unsigned int ShadowMapTextureWidth       = 1024;
static unsigned int ShadowMapTextureHeight      = 1024;
static float ShadowMapSoftness                  = 1.0f / 8.0f;

static unsigned int JitterTexUnit               = GL_TEXTURE2_ARB;
static unsigned int JitterTextureId             = 0;
static unsigned int JitterTextureBytes          = 0;
static unsigned int JitterTextureSize           = 16;
static unsigned int JitterTextureSamples        = 8;

static unsigned int LightProbeTexUnit           = GL_TEXTURE3_ARB;
static unsigned int LightProbeTextureId         = 0;
static unsigned int LightProbeWidth             = 0;
static unsigned int LightProbeHeight            = 0;
static unsigned int LightProbeComponents        = 0;

static int ox                                   = 0;
static int oy                                   = 0;
static int ButtonState                          = 0;
const float Inertia                             = 0.1;
enum { M_VIEW = 0, M_MOVE };
static uint MouseMode                           = 0;

static float PolygonOffsetScale                 = 1.0f;
static float PolygonOffsetBias                  = 1024.0f;

static unsigned int QuadDisplayListId           = 0;
static unsigned int SplitCount                  = 1;

static double TimeElapsed                       = 0;
static int FrameCount                           = 0;
static uint ReportStatsInterval                 = 60;
static float Phase                              = 0.0f;

char StatsString[1024]                          = "\0";
unsigned int ShowStats                          = 1;

char InfoString[1024]                           = "\0";
unsigned int ShowInfo                           = 1;

GLUquadric *SkyBoxQuadric                       = 0;
unsigned int SkyBoxDisplayListId                = 0;

static unsigned int GlobalDimX                  = 0;
static unsigned int GlobalDimY                  = 0;

static unsigned int ActualDimX                  = 0;
static unsigned int ActualDimY                  = 0;

////////////////////////////////////////////////////////////////////////////////

static cl_context ComputeContext;
static cl_kernel ComputeKernel;
static cl_program ComputeProgram;
static cl_device_id ComputeDeviceId;
static cl_command_queue ComputeCommands;
static cl_device_type ComputeDeviceType;
static cl_mem InputVertexBuffer;
static cl_mem OutputVertexBuffer;
static cl_mem OutputNormalBuffer;
static CGLContextObj OpenGLContext;
static int MaxWorkGroupSize;
static int GroupSize = 4;

static GLhandleARB FresnelShader;
static GLhandleARB PhongShader;
static GLhandleARB SphereShader;
static GLhandleARB EnvShader;
static GLhandleARB SkyBoxShader;

static float SplitDistances[10];
static float ModelView[16];

static float CameraProjectionMatrix[16];
static float CameraModelViewMatrix[16];

static float LightCameraMatrix[16];
static float LightProjectionMatrix[16];
static float LightModelViewMatrix[16];

////////////////////////////////////////////////////////////////////////////////

int matrix_inverse(float inv[16], float m[16]);

////////////////////////////////////////////////////////////////////////////////

static uint64_t
current_time()
{
    return mach_absolute_time();
}
	
static double 
subtract_time( uint64_t uiEndTime, uint64_t uiStartTime )
{    
	static double s_dConversion = 0.0;
	uint64_t uiDifference = uiEndTime - uiStartTime;
	if( 0 == s_dConversion )
	{
		mach_timebase_info_data_t kTimebase;
		kern_return_t kError = mach_timebase_info( &kTimebase );
		if( kError == 0  )
			s_dConversion = 1e-9 * (double) kTimebase.numer / (double) kTimebase.denom;
    }
		
	return s_dConversion * (double) uiDifference; 
}

////////////////////////////////////////////////////////////////////////////////

int 
divide_up(int a, int b) 
{
    return ((a % b) != 0) ? (a / b + 1) : (a / b);
}

////////////////////////////////////////////////////////////////////////////////

static float
reverse_bytes_float(float x)
{
    union
    {
        int i;
        float f;
    } fi;

    fi.f = x;
    fi.i = (((fi.i & 255) << 24) |
            (((fi.i >> 8) & 255 ) << 16 ) |
            (((fi.i >> 16) & 255 ) << 8 ) |
            ((fi.i >> 24) & 255 ));

    return fi.f;
}

static int
file_to_string(const char *file_name, char **result_string, size_t *string_len)
{
    int fd;
    unsigned file_len;
    struct stat file_status;
    int ret;

    *string_len = 0;
    fd = open(file_name, O_RDONLY);
    if (fd == -1)
    {
        printf("Error opening file %s\n", file_name);
        return -1;
    }
    ret = fstat(fd, &file_status);
    if (ret)
    {
        printf("Error reading status for file %s\n", file_name);
        return -1;
    }
    file_len = file_status.st_size;

    *result_string = (char*)calloc(file_len + 1, sizeof(char));
    ret = read(fd, *result_string, file_len);
    if (!ret)
    {
        printf("Error reading from file %s\n", file_name);
        return -1;
    }

    close(fd);

    *string_len = file_len;
    return 0;
}

static int
load_pfm(
    const char *file_name, 
    float **data, 
    unsigned int *width, 
    unsigned int *height, 
    unsigned int *channels)
{

    FILE *fd = 0;
    int a, b, x, y;
    char tmp;
    unsigned int w, h, c;
    unsigned int bytes;

    float scale;
    float *buffer;
    float *scanline;

    fd = fopen(file_name, "rb");
    if (!fd)
    {
        printf("Error opening file %s\n", file_name);
        return -1;
    }

    a = fgetc(fd);
    b = fgetc(fd);
    tmp = fgetc(fd);

    if ((a != 'P') || ((b != 'F') && (b != 'f')))
    {
        fclose(fd);
        printf("Error opening file %s:  Does not appear to be a PFM image!\n", file_name);
        return 0;
    }

    fscanf(fd, "%d %d%c", &x, &y, &tmp);
    if ((x <= 0) || (y <= 0))
    {
        fclose(fd);
        printf("Error opening file %s:  Invalid dimensions in PFM header!\n", file_name);
        return 0;
    }

    w = x;
    h = y;
    c = (b == 'F' ? 3 : 1); // 'F' = RGB,  'f' = monochrome

    fscanf(fd, "%f%c", &scale, &tmp);

    bytes = w * h * c * sizeof(float);
    buffer = (float*)calloc(w * h * c, sizeof(float));
    scanline = (float*)calloc(w * c, sizeof(float));
    if (!buffer || !scanline)
    {
        fclose(fd);
        printf("Error opening file %s:  Out of memory!\n", file_name);
        return 0;
    }


    float *f = buffer;
    for (y = 0; y < h; y++)
    {
        if (fread(scanline, sizeof(float), w * c, fd) != (size_t) (w * c))
        {
            fclose(fd);
            free(scanline);
            free(buffer);
            return 0;
        }

        float *temp = scanline;
        for (x = 0; x < w; x++)
        {
            if (c == 3)
            {
                f[0] = *temp++;
                f[1] = *temp++;
                f[2] = *temp++;
            }
            else
            {
                f[0] = *temp++;
                f[1] = f[0];
                f[2] = f[0];
            }

            if (scale > 0.0)		// MSB
            {
                f[0] = reverse_bytes_float(f[0]);
                f[1] = reverse_bytes_float(f[1]);
                f[2] = reverse_bytes_float(f[2]);
            }
            f = f + 3;
        }
    }

    free(scanline);
    fclose(fd);

    *data = buffer;
    *width = w;
    *height = h;
    *channels = 3;
    return 1;
}

void normalize(float v[3])
{
    float d = sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (d != 0.0f)
    {
        v[0] /= d;
        v[1] /= d;
        v[2] /= d;
    }
}

void fill_sphere(int resolution)
{
    int subdiv = (int)powf(2.0f, resolution);
    int stacks = subdiv / 2;
    int slices = subdiv;
    float pi = M_PI; // 3.1415927f;

    VertexElements = (stacks - 1) * slices * 2;
    VertexBytes = VertexElements * VertexComponents * sizeof(float);

    VertexBuffer = (float*)malloc(VertexBytes);
    NormalBuffer = (float*)malloc(VertexBytes);

    memset(VertexBuffer, 0, VertexBytes);
    memset(NormalBuffer, 0, VertexBytes);

    ActualDimX = stacks - 1;
    ActualDimY = slices * 2;

    GlobalDimX = ActualDimX;
    GlobalDimY = ActualDimY;

    printf(SEPARATOR);
    printf("Filling Sphere %d bytes %d elements (%d x %d) => (%d x %d)\n",
           VertexBytes, VertexElements, ActualDimX, ActualDimY, GlobalDimX, GlobalDimY);

    int i = 0, j = 0;
    unsigned int index = 0;
    for (i = 0; i < stacks - 1; i++)
    {
        float t = i / (stacks - 1.f);
        float t2 = (i + 1) / (stacks - 1.f);
        float phi = pi * t - pi / 2;
        float phi2 = pi * t2 - pi / 2;

        for ( j = 0; j < slices; j++)
        {
            float s = j / (slices - 1.f);
            float theta = 2 * pi * s;
            float v[4] = {0.0f, 0.0f, 0.0f, 1.0f};

            v[0] = cos(phi) * cos(theta);
            v[1] = sin(phi);
            v[2] = cos(phi) * sin(theta);

            normalize(v);

            NormalBuffer[index+0] = VertexBuffer[index+0] = v[0];
            NormalBuffer[index+1] = VertexBuffer[index+1] = v[1];
            NormalBuffer[index+2] = VertexBuffer[index+2] = v[2];
            NormalBuffer[index+3] = VertexBuffer[index+3] = 1.0;

            index += VertexComponents;

            v[0] = cos(phi2) * cos(theta);
            v[1] = sin(phi2);
            v[2] = cos(phi2) * sin(theta);

            normalize(v);

            NormalBuffer[index+0] = VertexBuffer[index+0] = v[0];
            NormalBuffer[index+1] = VertexBuffer[index+1] = v[1];
            NormalBuffer[index+2] = VertexBuffer[index+2] = v[2];
            NormalBuffer[index+3] = VertexBuffer[index+3] = 1.0;

            index += VertexComponents;
        }
    }
}

void create_quad()
{
    QuadDisplayListId = glGenLists(1);
    glNewList(QuadDisplayListId, GL_COMPILE);
    glPushMatrix();
    glBegin( GL_QUADS );
    {
        glColor3f( 0.9f, 0.9f, 0.9f );
        glNormal3f( 0.0f, 1.0f,  0.0f );
        glTranslatef(0.0f, 0.0f, -50.0f);
        glVertex3f(-100.0f, -4.0f, -100.0f );
        glVertex3f(-100.0f, -4.0f,  100.0f );
        glVertex3f( 100.0f, -4.0f,  100.0f );
        glVertex3f( 100.0f, -4.0f, -100.0f );
    }
    glEnd();
    glPopMatrix();
    glEndList();
}

void create_skybox()
{
    SkyBoxDisplayListId = glGenLists(1);
    glNewList(SkyBoxDisplayListId, GL_COMPILE);
    glPushMatrix();
    glTranslatef(0.0f, 0.0f, 0.0f);
    glutSolidSphere(10.0f, 200, 200);
    glPopMatrix();
    glEndList();

}

////////////////////////////////////////////////////////////////////////////////

static int
recompute(void)
{
    int err = 0;
    unsigned int a;

    void *values[32];
    size_t sizes[32];

    size_t global[2];
    size_t local[2];

    float dimx = ActualDimX;
    float dimy = ActualDimY;
    float freq = Frequency;
    float amp = Amplitude; // (1.0f / Amplitude);
    float phase = Phase;
    float lacunarity = Lacunarity;
    float increment = Increment;
    float octaves = Octaves;
    float roughness = Roughness;

    unsigned int v = 0, s = 0;
    unsigned int count = VertexElements;
    values[v++] = &InputVertexBuffer;
    values[v++] = &OutputNormalBuffer;
    values[v++] = &OutputVertexBuffer;
    values[v++] = &dimx;
    values[v++] = &dimy;
    values[v++] = &freq;
    values[v++] = &amp;
    values[v++] = &phase;
    values[v++] = &lacunarity;
    values[v++] = &increment;
    values[v++] = &octaves;
    values[v++] = &roughness;
    values[v++] = &count;

    sizes[s++] = sizeof(cl_mem);
    sizes[s++] = sizeof(cl_mem);
    sizes[s++] = sizeof(cl_mem);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(float);
    sizes[s++] = sizeof(unsigned int);

    if ( s != v )
    {
        printf("Error: Kernel Args Array Mismatch!\n");
        return -1;
    }

#if (USE_GL_ATTACHMENTS)

    err = clEnqueueAcquireGLObjects(ComputeCommands, 1, &OutputVertexBuffer, 0, 0, 0);
    if (err != CL_SUCCESS)
    {
        printf("Failed to attach Vertex Buffer!\n");
        return -1;
    }

    err = clEnqueueAcquireGLObjects(ComputeCommands, 1, &OutputNormalBuffer, 0, 0, 0);
    if (err != CL_SUCCESS)
    {
        printf("Failed to attach Normal Buffer!\n");
        return -1;
    }

#endif

    err = CL_SUCCESS;
    for (a = 0; a < s; a++)
        err |= clSetKernelArg(ComputeKernel, a, sizes[a], values[a]);

    if (err)
        return -16;

    uint uiSplitCount = ceilf(sqrtf(VertexElements));
    uint uiActive = (MaxWorkGroupSize / GroupSize);
    uiActive = uiActive < 1 ? 1 : uiActive;
    
    uint uiQueued = MaxWorkGroupSize / uiActive;
    
	local[0] = uiActive;
	local[1] = uiQueued;

	global[0] = divide_up(uiSplitCount, uiActive) * uiActive;
	global[1] = divide_up(uiSplitCount, uiQueued) * uiQueued;

    err = clEnqueueNDRangeKernel(ComputeCommands, ComputeKernel, 2, NULL, global, local, 0, NULL, NULL);
    if (err)
        return -17;

#if (USE_GL_ATTACHMENTS)

    cl_mem objects[] = { OutputVertexBuffer, OutputNormalBuffer };
    err = clEnqueueReleaseGLObjects(ComputeCommands, 2, objects, 0, 0, 0);
    if (err != CL_SUCCESS)
        return -19;

//   clFlush(ComputeCommands);
    

#else

    err = clEnqueueReadBuffer(ComputeCommands, OutputVertexBuffer, CL_TRUE, 0, VertexBytes, VertexBuffer, 0, NULL, NULL);
    if (err != CL_SUCCESS)
        return -19;

    err = clEnqueueReadBuffer(ComputeCommands, OutputNormalBuffer, CL_TRUE, 0, VertexBytes, NormalBuffer, 0, NULL, NULL);
    if (err != CL_SUCCESS)
        return -19;

#endif

    return 0;
}

////////////////////////////////////////////////////////////////////////////////

static int
setup_compute_devices(int gpu)
{
    int err;
	size_t returned_size;
    ComputeDeviceType = gpu ? CL_DEVICE_TYPE_GPU : CL_DEVICE_TYPE_CPU;

#if (USE_GL_ATTACHMENTS)

    printf(SEPARATOR);
    printf("Using active OpenGL context...\n");

    CGLContextObj kCGLContext = CGLGetCurrentContext();              
    CGLShareGroupObj kCGLShareGroup = CGLGetShareGroup(kCGLContext);
    
    cl_context_properties properties[] = { 
        CL_CONTEXT_PROPERTY_USE_CGL_SHAREGROUP_APPLE, 
        (cl_context_properties)kCGLShareGroup, 0 
    };
        
    // Create a context from a CGL share group
    //
    ComputeContext = clCreateContext(properties, 0, 0, clLogMessagesToStdoutAPPLE, 0, 0);
	if(!ComputeContext)
		return -2;

#else	

    // Connect to a compute device
    //
    err = clGetDeviceIDs(NULL, ComputeDeviceType, 1, &ComputeDeviceId, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to locate compute device!\n");
        return EXIT_FAILURE;
    }
  
    // Create a compute context 
    //
    ComputeContext = clCreateContext(0, 1, &ComputeDeviceId, clLogMessagesToStdoutAPPLE, NULL, &err);
    if (!ComputeContext)
    {
        printf("Error: Failed to create a compute context!\n");
        return EXIT_FAILURE;
    }
#endif

	unsigned int device_count;
	cl_device_id device_ids[16];

	err = clGetContextInfo(ComputeContext, CL_CONTEXT_DEVICES, sizeof(device_ids), device_ids, &returned_size);
	if(err)
	{
        printf("Error: Failed to retrieve compute devices for context!\n");
        return EXIT_FAILURE;
	}
	
	device_count = returned_size / sizeof(cl_device_id);
	
	int i = 0;
	int device_found = 0;
	cl_device_type device_type;	
	for(i = 0; i < device_count; i++) 
	{
		clGetDeviceInfo(device_ids[i], CL_DEVICE_TYPE, sizeof(cl_device_type), &device_type, NULL);
		if(device_type == ComputeDeviceType) 
		{
			ComputeDeviceId = device_ids[i];
			device_found = 1;
			break;
		}	
	}
	
	if(!device_found)
	{
        printf("Error: Failed to locate compute device!\n");
        return EXIT_FAILURE;
	}

    // Create a command queue
    //
    ComputeCommands = clCreateCommandQueue(ComputeContext, ComputeDeviceId, 0, &err);
    if (!ComputeCommands)
    {
        printf("Error: Failed to create a command queue!\n");
        return EXIT_FAILURE;
    }

    // Report the device vendor and device name
    // 
    cl_char vendor_name[1024] = {0};
    cl_char device_name[1024] = {0};
    err = clGetDeviceInfo(ComputeDeviceId, CL_DEVICE_VENDOR, sizeof(vendor_name), vendor_name, &returned_size);
    err|= clGetDeviceInfo(ComputeDeviceId, CL_DEVICE_NAME, sizeof(device_name), device_name, &returned_size);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to retrieve device info!\n");
        return EXIT_FAILURE;
    }

    printf(SEPARATOR);
    printf("Connecting to %s %s...\n", vendor_name, device_name);

    return CL_SUCCESS;
}

static int
setup_compute_memory()
{
    int err;

    size_t bytes = sizeof(float) * VertexComponents * VertexElements;

    printf(SEPARATOR);
    printf("Allocating buffers on compute device...\n");

    InputVertexBuffer = clCreateBuffer(ComputeContext, CL_MEM_READ_ONLY, bytes, NULL, &err);
    if (!InputVertexBuffer || err != CL_SUCCESS)
    {
        printf("Failed to create InputVertexBuffer! %d\n", err);
        return EXIT_FAILURE;
    }

#if (USE_GL_ATTACHMENTS)
	
    OutputVertexBuffer = clCreateFromGLBuffer(ComputeContext, CL_MEM_READ_WRITE, VertexBufferId, &err);
    if (!OutputVertexBuffer || err != CL_SUCCESS)
    {
        printf("Failed to create OutputVertexBuffer! %d\n", err);
        return EXIT_FAILURE;
    }

    OutputNormalBuffer = clCreateFromGLBuffer(ComputeContext, CL_MEM_READ_WRITE, NormalBufferId, &err);
    if (!OutputNormalBuffer || err != CL_SUCCESS)
    {
        printf("Failed to create OutputNormalBuffer! %d\n", err);
        return EXIT_FAILURE;
    }

#else

    OutputVertexBuffer = clCreateBuffer(ComputeContext, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!OutputVertexBuffer || err != CL_SUCCESS)
    {
        printf("Failed to create OutputVertexBuffer! %d\n", err);
        return EXIT_FAILURE;
    }

    OutputNormalBuffer = clCreateBuffer(ComputeContext, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!OutputNormalBuffer || err != CL_SUCCESS)
    {
        printf("Failed to create OutputNormalBuffer! %d\n", err);
        return EXIT_FAILURE;
    }

#endif

    err = clEnqueueWriteBuffer(ComputeCommands, InputVertexBuffer, CL_TRUE, 0, VertexBytes, VertexBuffer, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to write to InputVertexBuffer!\n");
        return EXIT_FAILURE;
    }

    return CL_SUCCESS;
}

static int
setup_compute_kernels(void)
{
    int err = 0;
    char *source = 0;
    size_t length = 0;

    printf(SEPARATOR);
    printf("Loading kernel source from file '%s'...\n", COMPUTE_KERNEL_FILENAME);    
    err = file_to_string(COMPUTE_KERNEL_FILENAME, &source, &length);
    if (err)
        return -8;

    // Create the compute program from the source buffer
    //
    ComputeProgram = clCreateProgramWithSource(ComputeContext, 1, (const char **) & source, NULL, &err);
    if (!ComputeProgram || err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute program! %d\n", err);
        return EXIT_FAILURE;
    }

    // Build the program executable
    //
    printf(SEPARATOR);
    printf("Building compute program...\n");
    err = clBuildProgram(ComputeProgram, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        size_t len;
        char buffer[2048];

        printf(SEPARATOR);
        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(ComputeProgram, ComputeDeviceId, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf(SEPARATOR);
        printf("%s\n", buffer);
        printf(SEPARATOR);
        return EXIT_FAILURE;
    }

    // Create the compute kernel from within the program
    //
    printf("Creating kernel '%s'...\n", COMPUTE_KERNEL_METHOD_NAME);    
    ComputeKernel = clCreateKernel(ComputeProgram, COMPUTE_KERNEL_METHOD_NAME, &err);
    if (!ComputeKernel|| err != CL_SUCCESS)
    {
        printf("Error: Failed to create compute kernel!\n");
        return EXIT_FAILURE;
    }
    
    // Get the maximum work group size for executing the kernel on the device
    //
    size_t max = 1;
    err = clGetKernelWorkGroupInfo(ComputeKernel, ComputeDeviceId, CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &max, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to retrieve kernel work group info! %d\n", err);
        return EXIT_FAILURE;
    }
    
    MaxWorkGroupSize = max;
    printf("Maximum Workgroup Size '%d'\n", MaxWorkGroupSize);

    return CL_SUCCESS;
}

static int
setup_opencl(int use_gpu)
{
    printf(SEPARATOR);
    printf("Setting up Compute...\n");
    
    int err;
    err = setup_compute_devices(use_gpu);
    if (err != CL_SUCCESS)
        return err;

    err = setup_compute_memory();
    if (err != CL_SUCCESS)
        return err;

    err = setup_compute_kernels();
    if (err != CL_SUCCESS)
        return err;

    return CL_SUCCESS;
}


static void
shutdown_opencl(void)
{
    clFinish(ComputeCommands);

    clReleaseMemObject(InputVertexBuffer);
    clReleaseMemObject(OutputVertexBuffer);
    clReleaseMemObject(OutputNormalBuffer);

    clReleaseKernel(ComputeKernel);
    clReleaseProgram(ComputeProgram);
    clReleaseContext(ComputeContext);

    if(VertexBuffer)
        free(VertexBuffer);
    
    if(NormalBuffer)
        free(NormalBuffer);
}

////////////////////////////////////////////////////////////////////////////////

GLboolean
check_opengl(void)
{
    const GLubyte* extensions = glGetString(GL_EXTENSIONS);

    if (GL_FALSE == gluCheckExtension((const GLubyte*) "GL_ARB_shader_objects", extensions))
        return GL_FALSE;
    if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_vertex_shader", extensions))
        return GL_FALSE;
    if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_fragment_shader", extensions))
        return GL_FALSE;
    if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_shading_language_100", extensions))
        return GL_FALSE;

    return GL_TRUE;
}

void
create_sphere(void)
{
    fill_sphere(SphereResolution);

    glGenBuffers(1, &VertexBufferId);
    glBindBuffer(GL_ARRAY_BUFFER_ARB, VertexBufferId);
    glBufferData(GL_ARRAY_BUFFER_ARB, VertexBytes, NULL, BufferModeType);
    glVertexPointer(VertexComponents, GL_FLOAT, 0, 0);
    glBindBuffer( GL_ARRAY_BUFFER_ARB, 0);

    glGenBuffers(1, &NormalBufferId);
    glBindBuffer(GL_ARRAY_BUFFER_ARB, NormalBufferId);
    glBufferData(GL_ARRAY_BUFFER_ARB, VertexBytes, NULL, BufferModeType);
    glNormalPointer(GL_FLOAT, VertexComponents * sizeof(float), 0);
    glBindBuffer( GL_ARRAY_BUFFER_ARB, 0);

    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
        printf("Error: OpenGL Get Error: %d\n", err);

}

void
create_light_probe_texture(const char *filename)
{
    float *data;

    printf("Loading Light Probe \"%s\"\n", filename);

    load_pfm(filename, &data, 
             &LightProbeWidth, 
             &LightProbeHeight, 
             &LightProbeComponents);

    printf("Creating Light Probe Texture (%d x %d)....\n", 
        LightProbeWidth, LightProbeHeight);
    
    glActiveTextureARB(LightProbeTexUnit);
    glGenTextures(1, &LightProbeTextureId);
    glBindTexture(GL_TEXTURE_2D, LightProbeTextureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F_ARB, 
                 LightProbeWidth, LightProbeHeight, 0,
                 GL_RGB, GL_FLOAT, data);
    glActiveTextureARB(DisableTexUnit);

    free(data);

}

void
create_jitter_texture(unsigned int size, unsigned int du, unsigned int dv)
{
    int i, j, k;
    unsigned char *data = 0;
    static const float twopi = 2.0 * M_PI;

    printf("Creating Jitter Texture...\n");

    JitterTextureSize = size;

    glActiveTextureARB(JitterTexUnit);
    glGenTextures(1, &JitterTextureId);
    glBindTexture(GL_TEXTURE_3D, JitterTextureId);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_REPEAT);

    int tw = size;
    int th = size;
    int td = du * dv * 0.5f;

    JitterTextureBytes = 4 * tw * th * td * sizeof(unsigned char);
    data = (unsigned char *) malloc(JitterTextureBytes);

    for (i = 0; i < tw; i++)
    {
        for (j = 0; j < th; j++)
        {
            for (k = 0; k < td; k++)
            {
                int x, y;
                float d[4];
                float v[4];

                x = k % (du / 2);
                y = (dv - 1) - k / (du / 2);

                v[0] = (float)(x * 2 + 0.5f) / du;
                v[1] = (float)(y + 0.5f) / dv;
                v[2] = (float)(x * 2 + 1 + 0.5f) / du;
                v[3] = v[1];

                v[0] += ((float)rand() * 2 / RAND_MAX - 1) * (0.5f / du);
                v[1] += ((float)rand() * 2 / RAND_MAX - 1) * (0.5f / dv);
                v[2] += ((float)rand() * 2 / RAND_MAX - 1) * (0.5f / du);
                v[3] += ((float)rand() * 2 / RAND_MAX - 1) * (0.5f / dv);

                d[0] = sqrtf(v[1]) * cosf(twopi * v[0]);
                d[1] = sqrtf(v[1]) * sinf(twopi * v[0]);
                d[2] = sqrtf(v[3]) * cosf(twopi * v[2]);
                d[3] = sqrtf(v[3]) * sinf(twopi * v[2]);

                unsigned int index = (k * tw * th + j * tw + i) * 4;
                data[index + 0] = (1.0f + d[0]) * 127;
                data[index + 1] = (1.0f + d[1]) * 127;
                data[index + 2] = (1.0f + d[2]) * 127;
                data[index + 3] = (1.0f + d[3]) * 127;
            }
        }
    }

    glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA4, tw, th, td, 0, 
                 GL_RGBA, GL_UNSIGNED_BYTE, data);

    free(data);

    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
        printf("Error: OpenGL Error Code Creating Jitter Texture: %d\n", err);
}

int
create_shadow_fbo(void)
{
    GLint depth;
    GLint format;
    GLenum status;

    printf("Creating Shadow FrameBuffer...\n");

    glActiveTextureARB(ShadowMapTexUnit);
    glGenTextures(1, &ShadowMapTextureId);
    glBindTexture(GL_TEXTURE_2D, ShadowMapTextureId);
    glGetIntegerv(GL_DEPTH_BITS, &depth);

    if (depth == 16)
        format = GL_DEPTH_COMPONENT16_ARB;
    else
        format = GL_DEPTH_COMPONENT24_ARB;

    glTexImage2D(GL_TEXTURE_2D, 0, format, 
                 ShadowMapTextureWidth, 
                 ShadowMapTextureHeight, 
                 0, GL_DEPTH_COMPONENT, 
                 GL_FLOAT, NULL);
                 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_COMPARE_R_TO_TEXTURE_ARB);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC_ARB, GL_LEQUAL);

    glGenFramebuffersEXT(1, &ShadowMapFrameBufferId);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, ShadowMapFrameBufferId);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, 
                              GL_TEXTURE_2D, ShadowMapTextureId, 0);

    glDrawBuffer(GL_NONE);
    glReadBuffer(GL_NONE);

    status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    switch (status)
    {
    case GL_FRAMEBUFFER_COMPLETE_EXT:
        break;
    case GL_FRAMEBUFFER_UNSUPPORTED_EXT:
        printf("Error: FBO Format Unsupported!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT:
        printf("Error: FBO Incomplete Attachment!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT:
        printf("Error: FBO Incomplete Missing Attachment!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT:
        printf("Error: FBO Incomplete Dimensions!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT:
        printf("Error: FBO Incomplete Formats!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT:
        printf("Error: FBO Incomplete Draw Buffer!\n");
        break;
    case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT:
        printf("Error: FBO Incomplete Read Buffer!\n");
        break;
    default:
        printf("Error: FBO status %d\n", (int)status);
        break;
    }

    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
        printf("Error: OpenGL Error Code Creating FBO: %d\n", err);

    return CL_SUCCESS;
}

void
set_sphere_material(void)
{
    GLfloat ambient[4]  = {0.1f, 0.1f, 0.1f, 1.0f};
    GLfloat diffuse[4]  = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat specular[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat shininess[1] = {128.0f};

    glEnable(GL_COLOR_MATERIAL);
    glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, ambient);
    glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, diffuse);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, specular);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SHININESS, shininess);
    glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
}

void
set_quad_material(void)
{
    GLfloat ambient[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat diffuse[4] = {0.1f, 0.5f, 0.8f, 1.0f};
    GLfloat specular[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    GLfloat shininess[1] = { 0.0f};

    glEnable(GL_COLOR_MATERIAL);
    glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, ambient);
    glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, diffuse);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, specular);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SHININESS, shininess);
    glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
}

void
setup_lights(void)
{
    GLfloat ambient[4]  = {0.1f, 0.1f, 0.1f, 1.0f};
    GLfloat diffuse[4]  = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat specular[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat attenuation[] = { 0.1f };

    glLightfv(GL_LIGHT0, GL_POSITION, LightPosition);
    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
    glLightfv(GL_LIGHT0, GL_LINEAR_ATTENUATION , attenuation );
    glLightModeli(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR);
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE);
    glEnable(GL_LIGHT0);

}

GLenum
link_shader(GLhandleARB shader)
{
    GLint err = 0;
    GLint length = 0;
    GLint linked = 0;

    glLinkProgramARB(shader);

    err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("Error Code Returned Linking Shader: %d\n", err);
        exit(err);
    }

    glGetObjectParameterivARB(shader, GL_OBJECT_LINK_STATUS_ARB, &linked);
    glGetObjectParameterivARB(shader, GL_OBJECT_INFO_LOG_LENGTH_ARB, &length);

    if (length)
    {
        GLint actual;
        GLcharARB *log = malloc(length + 128);

        glGetInfoLogARB(shader, length, &actual, log);
        printf("Error Linking Shader %d:\n%s\n", length, log);
        free (log);
    }

    if (linked == 0)
    {
        printf("Failed to Link Shader!\n");
        exit(1);
    }

    return GL_NO_ERROR;
}

GLhandleARB
compile_shader(GLenum target, const GLcharARB* sourcecode)
{
    GLint err;
    GLint length;
    GLint compiled;
    GLhandleARB shader;

    if (sourcecode != 0)
    {
        shader = glCreateShaderObjectARB(target);
        err = glGetError();
        if (err != GL_NO_ERROR)
        {
            printf("Error Code Returned Getting Shader Target: %d\n", err);
            exit(err);
        }

        glShaderSourceARB(shader, 1, (const GLcharARB **)&sourcecode, 0);
        err = glGetError();
        if (err != GL_NO_ERROR)
        {
            printf("Error Code Returned Creating Shader: %d\n", err);
            exit(err);
        }

        glCompileShaderARB(shader);
        err = glGetError();
        if (err != GL_NO_ERROR)
        {
            printf("Error Code Returned Compiling Shader: %d\n", err);
            exit(err);
        }

        glGetObjectParameterivARB(shader, GL_OBJECT_COMPILE_STATUS_ARB, &compiled);
        glGetObjectParameterivARB(shader, GL_OBJECT_INFO_LOG_LENGTH_ARB, &length);
        if (length)
        {
            GLcharARB *log = malloc(length + 128);
            glGetInfoLogARB(shader, length, &length, log);
            printf("Compile log:\n%s\n", log);
            free (log);
        }
        if (!compiled)
        {
            printf("Failed to Compile Shader!\n");
            exit(1);
        }
    }
    return shader;
}

int
get_uniform_location(GLhandleARB shader, const char * name )
{
    GLint uid = glGetUniformLocation( (long)shader, name );
    return uid;
}

GLhandleARB
create_shader(const char* vertfile, const char* fragfile)
{
    int err = 0;
    char *shader_source = 0;
    size_t shader_length = 0;
    GLhandleARB frag_shader = 0;
    GLhandleARB vert_shader = 0;
    GLhandleARB shader_program = 0;

    if (vertfile)
    {
        printf("Loading Shader Program \"%s\"...\n", vertfile);
        err = file_to_string(vertfile, &shader_source, &shader_length);
        if (err)
            return shader_program;

        vert_shader = compile_shader(GL_VERTEX_SHADER_ARB, shader_source);
        free(shader_source);
        shader_source = 0;
        shader_length = 0;
    }

    if (fragfile)
    {
        printf("Loading Shader Program \"%s\"...\n", fragfile);
        err = file_to_string(fragfile, &shader_source, &shader_length);
        if (err)
            return shader_program;

        frag_shader = compile_shader(GL_FRAGMENT_SHADER_ARB, shader_source);
        free(shader_source);
        shader_source = 0;
        shader_length = 0;
    }

    shader_program = glCreateProgramObjectARB();

    if (vert_shader)
        glAttachObjectARB(shader_program, vert_shader);

    if (frag_shader)
        glAttachObjectARB(shader_program, frag_shader);

    err = link_shader(shader_program);
    if (GL_NO_ERROR != err)
    {
        printf ("Program could not link");
        exit (1);
    }

    if (vert_shader)
        glDeleteObjectARB(vert_shader);

    if (frag_shader)
        glDeleteObjectARB(frag_shader);

    return shader_program;
}

void bind_sphere_shader()
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glActiveTextureARB(ShadowMapTexUnit);
    glBindTexture( GL_TEXTURE_2D, ShadowMapTextureId );

    glActiveTextureARB(JitterTexUnit);
    glBindTexture( GL_TEXTURE_3D, JitterTextureId );

    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, LightProbeTextureId );

    glUseProgramObjectARB(SphereShader);
    glUniform1iARB(get_uniform_location(SphereShader, "JitterTable"), JitterTexUnit - GL_TEXTURE0);
    glUniform1iARB(get_uniform_location(SphereShader, "JitterTableSize"), JitterTextureSize);
    glUniform1fARB(get_uniform_location(SphereShader, "ShadowMapSize"), ShadowMapTextureWidth);
    glUniform1fARB(get_uniform_location(SphereShader, "ShadowMapSoftness"), ShadowMapSoftness);
    glUniform1iARB(get_uniform_location(SphereShader, "ShadowMap"), ShadowMapTexUnit - GL_TEXTURE0);
    glUniform3fARB(get_uniform_location(SphereShader, "LightPosition"),
                   LightPosition[0], LightPosition[1], LightPosition[2]);
    glUniform3fARB(get_uniform_location(SphereShader, "EyePosition"),
                   CameraPosition[0], CameraPosition[1], CameraPosition[2]);

    glUniform1fARB(get_uniform_location(SphereShader, "NormalIntensity"), 0.3f);
    if (SphereShader == FresnelShader)
    {
        glUniform1fARB(get_uniform_location(SphereShader, "RefractiveIndex"), RefractiveIndex);
        glUniform1fARB(get_uniform_location(SphereShader, "FresnelBias"), FresnelBias);
        glUniform1fARB(get_uniform_location(SphereShader, "FresnelScale"), FresnelScale);
        glUniform1fARB(get_uniform_location(SphereShader, "FresnelPower"), FresnelPower);
        glUniform1fARB(get_uniform_location(SphereShader, "ChromaticDispersion"), ChromaticDispersion);
        glUniform1iARB(get_uniform_location(SphereShader, "LightProbeMap"), LightProbeTexUnit - GL_TEXTURE0);
        glUniform3fARB(get_uniform_location(SphereShader, "DiffuseColor"),
                       0.1f, 0.1f, 0.2f);
    }
    else
    {
        glUniform3fARB(get_uniform_location(SphereShader, "DiffuseColor"),
                       0.10f, 0.45f, 0.85f);
    }


}

void unbind_sphere_shader()
{
    glDisable(GL_BLEND);

    glActiveTextureARB(ShadowMapTexUnit);
    glBindTexture( GL_TEXTURE_2D, 0 );

    glActiveTextureARB(JitterTexUnit);
    glBindTexture( GL_TEXTURE_3D, 0 );

    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, 0 );

    glActiveTextureARB(DisableTexUnit);
    glUseProgramObjectARB(0);
}

void bind_quad_shader()
{
    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, LightProbeTextureId );

    glActiveTextureARB(ShadowMapTexUnit);
    glBindTexture( GL_TEXTURE_2D, ShadowMapTextureId );

    glActiveTextureARB(JitterTexUnit);
    glBindTexture( GL_TEXTURE_3D, JitterTextureId );

    glUseProgramObjectARB(EnvShader);
    glUniform1iARB(get_uniform_location(EnvShader, "JitterTable"), JitterTexUnit - GL_TEXTURE0);
    glUniform1iARB(get_uniform_location(EnvShader, "JitterTableSize"), JitterTextureSize);
    glUniform1fARB(get_uniform_location(EnvShader, "ShadowMapSize"), ShadowMapTextureWidth);
    glUniform1fARB(get_uniform_location(EnvShader, "ShadowMapSoftness"), ShadowMapSoftness);
    glUniform1iARB(get_uniform_location(EnvShader, "ShadowMap"), ShadowMapTexUnit - GL_TEXTURE0);
    glUniform3fARB(get_uniform_location(EnvShader, "LightPosition"),
                   LightPosition[0], LightPosition[1], LightPosition[2]);
    glUniform3fARB(get_uniform_location(EnvShader, "EyePosition"),
                   CameraPosition[0], CameraPosition[1], CameraPosition[2]);
    glUniform3fARB(get_uniform_location(EnvShader, "DiffuseColor"),
                   1.5f, 1.5f, 1.5f);
    glUniform1fARB(get_uniform_location(EnvShader, "NormalIntensity"), 0.0f);
}

void unbind_quad_shader()
{
    glActiveTextureARB(ShadowMapTexUnit);
    glBindTexture( GL_TEXTURE_2D, 0 );

    glActiveTextureARB(JitterTexUnit);
    glBindTexture( GL_TEXTURE_3D, 0 );

    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, 0 );

    glActiveTextureARB(DisableTexUnit);
    glUseProgramObjectARB(0);

}

void bind_skybox_shader()
{
    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, LightProbeTextureId );

    glUseProgramObjectARB(SkyBoxShader);
    glUniform1iARB(get_uniform_location(SkyBoxShader, "LightProbeMap"), LightProbeTexUnit - GL_TEXTURE0);
    glUniform3fARB(get_uniform_location(EnvShader, "EyePosition"),
                   CameraPosition[0], CameraPosition[1], CameraPosition[2]);
}

void unbind_skybox_shader()
{
    glActiveTextureARB(LightProbeTexUnit);
    glBindTexture( GL_TEXTURE_2D, 0 );

    glActiveTextureARB(DisableTexUnit);
    glUseProgramObjectARB(0);
}

int setup_opengl(void)
{
    printf(SEPARATOR);
    printf("Setting up Graphics...\n");
    printf(SEPARATOR);
    
    if ( !check_opengl())
    {
        printf ("%s doesn't support GLSL\n", glGetString(GL_RENDERER));
        return 1;
    }

    OpenGLContext = CGLGetCurrentContext();

    glViewport(0, 0, Width, Height);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    glEnable(GL_DEPTH_TEST);
    glClearDepth(1.0f);
    glDepthFunc(GL_LEQUAL);
    glDepthRange(0.0f, 1.0f);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    glClearColor(0.85f, 0.85f, 0.85f, 0.0f);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);


    create_shadow_fbo();
    create_jitter_texture(JitterTextureSize, JitterTextureSamples, JitterTextureSamples);
    create_light_probe_texture("stpeters_probe.pfm");

    create_quad();
    create_skybox();
    create_sphere();
    setup_lights();

    FresnelShader = create_shader("fresnel.vert", "fresnel.frag");
    PhongShader = create_shader("phong.vert", "phong.frag");
    SkyBoxShader = create_shader("skybox.vert", "skybox.frag");
    SphereShader = PhongShader;
    EnvShader = PhongShader;

    glClientActiveTexture(DisableTexUnit);
    return GL_NO_ERROR;
}

void set_texgen_planes(GLenum plane)
{
    static float s[4] = { 1.0f, 0.0f, 0.0f, 0.0f };
    static float t[4] = { 0.0f, 1.0f, 0.0f, 0.0f };
    static float r[4] = { 0.0f, 0.0f, 1.0f, 0.0f };
    static float q[4] = { 0.0f, 0.0f, 0.0f, 1.0f };

    glTexGenfv(GL_S, plane, s);
    glTexGenfv(GL_T, plane, t);
    glTexGenfv(GL_R, plane, r);
    glTexGenfv(GL_Q, plane, q);
}

void set_eye_linear_texgen()
{
    set_texgen_planes(GL_EYE_PLANE);
    glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
    glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
    glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
    glTexGeni(GL_Q, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
}

void set_obj_linear_texgen()
{
    set_texgen_planes(GL_OBJECT_PLANE);
    glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
    glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
    glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
    glTexGeni(GL_Q, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
}

void set_texgen(int enable)
{
    if (enable)
    {
        glEnable(GL_TEXTURE_GEN_S);
        glEnable(GL_TEXTURE_GEN_T);
        glEnable(GL_TEXTURE_GEN_R);
        glEnable(GL_TEXTURE_GEN_Q);
    }
    else
    {
        glDisable(GL_TEXTURE_GEN_S);
        glDisable(GL_TEXTURE_GEN_T);
        glDisable(GL_TEXTURE_GEN_R);
        glDisable(GL_TEXTURE_GEN_Q);
    }
}

void render_quad()
{
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    glPushMatrix();
    set_obj_linear_texgen();
    set_texgen(1);
    glCallList(QuadDisplayListId);
    glPopMatrix();
}

void render_skybox()
{
    float imv[16];

    matrix_inverse(imv, CameraModelViewMatrix);

    glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glCallList(SkyBoxDisplayListId);
    glPopMatrix();
    glEnable(GL_DEPTH_TEST);
}


void
render_sphere(void)
{
    glPushMatrix();

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

    glBindBuffer(GL_ARRAY_BUFFER_ARB, VertexBufferId);
#if (USE_GL_ATTACHMENTS == 0)
    glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, VertexBytes, VertexBuffer);
#endif
    glVertexPointer(VertexComponents, GL_FLOAT, 0, 0);

    glBindBuffer(GL_ARRAY_BUFFER_ARB, NormalBufferId);
#if (USE_GL_ATTACHMENTS == 0)
    glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, VertexBytes, NormalBuffer);
#endif
    glNormalPointer(GL_FLOAT, VertexComponents * sizeof(float), 0);

    glDrawArrays(GL_QUAD_STRIP, 0, VertexElements);

    glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);

    glPopMatrix();
}

void
render_scene(int shaded)
{
    if (shaded)
    {
        glEnable(GL_MULTISAMPLE);
        glMatrixMode( GL_MODELVIEW );
        glPushMatrix();

        if (SphereShader == FresnelShader)
        {
            bind_skybox_shader();
            render_skybox();
            unbind_skybox_shader();
        }
        else
        {
            bind_quad_shader();
            render_quad();
            unbind_quad_shader();
        }

        bind_sphere_shader();
        render_sphere();
        unbind_sphere_shader();

        glPopMatrix();
        glDisable(GL_MULTISAMPLE);
    }
    else
    {
        render_quad();
        render_sphere();
    }
}

////////////////////////////////////////////////////////////////////////////////

float clamp(float v, float min, float max)
{
    return (v < min) ? min : ((v > max) ? max : v);
}

void vector_scale( float v[4], float s)
{
    v[0] *= s;
    v[1] *= s;
    v[2] *= s;
}

void vector_sub( float v[4], float va[4], float vb[4])
{
    v[0] = va[0] - vb[0];
    v[1] = va[1] - vb[1];
    v[2] = va[2] - vb[2];
}

void vector_add( float v[4], float va[4], float vb[4])
{
    v[0] = va[0] + vb[0];
    v[1] = va[1] + vb[1];
    v[2] = va[2] + vb[2];
}

void vector_cross( float v[4], float va[4], float vb[4])
{
    v[0] = va[1] * vb[2] - va[2] * vb[1];
    v[1] = va[2] * vb[0] - va[0] * vb[2];
    v[2] = va[0] * vb[1] - va[1] * vb[0];
}

void vector_normalize(float v[4])
{
    float d = sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    d = (d != 0.0f) ? d : 1.0f;

    v[0] /= d;
    v[1] /= d;
    v[2] /= d;
}

void multiply_matrix_vector(float v[4], float m[16], float va[4])
{
    v[0] = m[0] * va[0] + m[4] * va[1] + m[8]  * va[2] + m[12] * va[3];
    v[1] = m[1] * va[0] + m[5] * va[1] + m[9]  * va[2] + m[13] * va[3];
    v[2] = m[2] * va[0] + m[6] * va[1] + m[10] * va[2] + m[14] * va[3];
    v[3] = m[3] * va[0] + m[7] * va[1] + m[11] * va[2] + m[15] * va[3];
}

int matrix_inverse(float inv[16], float m[16])
{
    static float identity[16] = { 1.0f, 0.0f, 0.0f, 0.0f,
                                  0.0f, 1.0f, 0.0f, 0.0f,
                                  0.0f, 0.0f, 1.0f, 0.0f,
                                  0.0f, 0.0f, 0.0f, 1.0f
                                };

    float tmp[16] = {0};
    float d12, d13, d23, d24, d34, d41;

    d12 = m[2]  * m[7]  - m[3]  * m[6];
    d13 = m[2]  * m[11] - m[3]  * m[10];
    d23 = m[6]  * m[11] - m[7]  * m[10];
    d24 = m[6]  * m[15] - m[7]  * m[14];
    d34 = m[10] * m[15] - m[11] * m[14];
    d41 = m[14] * m[3]  - m[15] * m[2];

    tmp[0] =   m[5] * d34 - m[9] * d24 + m[13] * d23;
    tmp[1] = -(m[1] * d34 + m[9] * d41 + m[13] * d13);
    tmp[2] =   m[1] * d24 + m[5] * d41 + m[13] * d12;
    tmp[3] = -(m[1] * d23 - m[5] * d13 + m[9]  * d12);

    float determinant = m[0] * tmp[0] + m[4] * tmp[1] + m[8] * tmp[2] + m[12] * tmp[3];

    if (determinant == 0.0)
    {
        memcpy(inv, identity, 16 * sizeof(float));
        return 0;
    }

    float invDeterminant = 1.0f / determinant;

    tmp[0] *= invDeterminant;
    tmp[1] *= invDeterminant;
    tmp[2] *= invDeterminant;
    tmp[3] *= invDeterminant;

    tmp[4] = -(m[4] * d34 - m[8] * d24 + m[12] * d23) * invDeterminant;
    tmp[5] =   m[0] * d34 + m[8] * d41 + m[12] * d13  * invDeterminant;
    tmp[6] = -(m[0] * d24 + m[4] * d41 + m[12] * d12) * invDeterminant;
    tmp[7] =   m[0] * d23 - m[4] * d13 + m[8]  * d12  * invDeterminant;

    d12 = m[0]  * m[5]  - m[1]  * m[12];
    d13 = m[0]  * m[9]  - m[1]  * m[8];
    d23 = m[4]  * m[9]  - m[5]  * m[8];
    d24 = m[4]  * m[13] - m[5]  * m[12];
    d34 = m[8]  * m[13] - m[9]  * m[12];
    d41 = m[12] * m[1]  - m[13] * m[0];

    tmp[8]  =   m[7] * d34 - m[11] * d24 + m[15] * d23 * invDeterminant;
    tmp[9]  = -(m[3] * d34 + m[11] * d41 + m[15] * d13) * invDeterminant;
    tmp[10] =   m[3] * d24 + m[7]  * d41 + m[15] * d12 * invDeterminant;
    tmp[11] = -(m[3] * d23 - m[7]  * d13 + m[11] * d12) * invDeterminant;
    tmp[12] = -(m[6] * d34 - m[10] * d24 + m[14] * d23) * invDeterminant;
    tmp[13] =   m[2] * d34 + m[10] * d41 + m[14] * d13 * invDeterminant;
    tmp[14] = -(m[2] * d24 + m[6]  * d41 + m[14] * d12) * invDeterminant;
    tmp[15] =   m[2] * d23 - m[6]  * d13 + m[10] * d12 * invDeterminant;

    memcpy(inv, tmp, 16 * sizeof(float));

    return 1;
}

void multiply_matrices(float m[16], float a[16], float b[16])
{
    m[ 0] = b[0] * a[0]  + b[4] * a[1]  + b[8]  * a[2]  + b[12] * a[3];
    m[ 1] = b[1] * a[0]  + b[5] * a[1]  + b[9]  * a[2]  + b[13] * a[3];
    m[ 2] = b[2] * a[0]  + b[6] * a[1]  + b[10] * a[2]  + b[14] * a[3];
    m[ 3] = b[3] * a[0]  + b[7] * a[1]  + b[11] * a[2]  + b[15] * a[3];
    m[ 4] = b[0] * a[4]  + b[4] * a[5]  + b[8]  * a[6]  + b[12] * a[7];
    m[ 5] = b[1] * a[4]  + b[5] * a[5]  + b[9]  * a[6]  + b[13] * a[7];
    m[ 6] = b[2] * a[4]  + b[6] * a[5]  + b[10] * a[6]  + b[14] * a[7];
    m[ 7] = b[3] * a[4]  + b[7] * a[5]  + b[11] * a[6]  + b[15] * a[7];
    m[ 8] = b[0] * a[8]  + b[4] * a[9]  + b[8]  * a[10] + b[12] * a[11];
    m[ 9] = b[1] * a[8]  + b[5] * a[9]  + b[9]  * a[10] + b[13] * a[11];
    m[10] = b[2] * a[8]  + b[6] * a[9]  + b[10] * a[10] + b[14] * a[11];
    m[11] = b[3] * a[8]  + b[7] * a[9]  + b[11] * a[10] + b[15] * a[11];
    m[12] = b[0] * a[12] + b[4] * a[13] + b[8]  * a[14] + b[12] * a[15];
    m[13] = b[1] * a[12] + b[5] * a[13] + b[9]  * a[14] + b[13] * a[15];
    m[14] = b[2] * a[12] + b[6] * a[13] + b[10] * a[14] + b[14] * a[15];
    m[15] = b[3] * a[12] + b[7] * a[13] + b[11] * a[14] + b[15] * a[15];
}


void matrix_vector_multiply(float *v, float *r, GLfloat *m)
{
    r[0] = v[0] * m[0] + v[1] * m[4] + v[2] * m[8] + m[12];
    r[1] = v[0] * m[1] + v[1] * m[5] + v[2] * m[9] + m[13];
    r[2] = v[0] * m[2] + v[1] * m[6] + v[2] * m[10] + m[14];
}

void inv_matrix_vector_multiply(float *v, float *r, GLfloat *m)
{
    r[0] = v[0] * m[0] + v[1] * m[1] + v[2] * m[2];
    r[1] = v[0] * m[4] + v[1] * m[5] + v[2] * m[6];
    r[2] = v[0] * m[8] + v[1] * m[9] + v[2] * m[10];
}

void inv_matrix_vector_multiply_point(float *v, float *r, GLfloat *m)
{
    float x[4];
    x[0] = v[0] - m[12];
    x[1] = v[1] - m[13];
    x[2] = v[2] - m[14];
    x[3] = 1.0f;
    inv_matrix_vector_multiply(x, r, m);
}

void
calc_light_matrices(
    float projection[16],
    float modelview[16],
    float frustum[8][4],
    float position[4])
{
    int i = 0;
    float dx, dy;
    float mvp[16] = {0};
    float tmp[16] = {0};
    float farlight = 0.0f;
    float scalex = 0.0f, scaley = 0.0f;
    float offsetx = 0.0f, offsety = 0.0f;

    float minx = + 1.0f, miny = + 1.0f, minz = 1.0f;
    float maxx = -1.0f, maxy = -1.0f, maxz = -1.0f;

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    gluPerspective(LightFovY, 1.0f, LightNearZ, LightFarZ);
    glGetFloatv(GL_PROJECTION_MATRIX, projection);
    glPopMatrix();

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    gluLookAt( position[0], position[1], position[2],
               0.0f, 0.0f, 0.0f,
               0.0f, 1.0f, 0.0f );

    glGetFloatv( GL_MODELVIEW_MATRIX, modelview );
    glPopMatrix();

    multiply_matrices(mvp, projection, modelview);

    for (i = 0; i < 8; i++)
    {
        float v[4];
        multiply_matrix_vector(v, mvp, frustum[i]);

        v[0] /= v[3];
        v[1] /= v[3];

        maxx = (v[0] > maxx) ? v[0] : maxx;
        maxy = (v[1] > maxy) ? v[1] : maxy;
        maxz = (v[2] > maxz) ? v[2] : maxz;

        minx = (v[0] < minx) ? v[0] : minx;
        miny = (v[1] < miny) ? v[1] : miny;
        minz = (v[2] < minz) ? v[2] : minz;
    }

    maxx = clamp(maxx, -1.0f, 1.0f);
    maxy = clamp(maxy, -1.0f, 1.0f);

    minx = clamp(minx, -1.0f, 1.0f);
    miny = clamp(miny, -1.0f, 1.0f);

    farlight = maxz + 1.0f + 1.5f;

    glMatrixMode( GL_PROJECTION );
    glPushMatrix();
    glLoadIdentity();
    gluPerspective(LightFovY, 1.0f, LightNearZ, farlight);
    // glOrtho(-1.0, 1.0, -1.0, 1.0, -farlight, -LightNearZ);
    glGetFloatv(GL_PROJECTION_MATRIX, projection);
    glPopMatrix();

    dx = (maxx - minx);
    dy = (maxy - miny);

    scalex = (dx != 0.0f) ? (2.0f / dx) : 0.0f;
    scaley = (dy != 0.0f) ? (2.0f / dy) : 0.0f;

    offsetx = -0.5f * (maxx + minx) * scalex;
    offsety = -0.5f * (maxy + miny) * scaley;

    float cvm[16] = { scalex,    0.0f, 0.0f, 0.0f,
                      0.0f,  scaley, 0.0f, 0.0f,
                      0.0f,    0.0f, 1.0f, 0.0f,
                      offsetx, offsety, 0.0f, 1.0f
                    };

    multiply_matrices(tmp, projection, cvm);
    memcpy(projection, tmp, 16 * sizeof(float));

}

void calc_split_distances(
    float *distances, unsigned int count, float near, float far)
{
    int i = 0;
    float lambda = 0.6f;
    float ratio = far / near;
    for (i = 0; i < count; i++)
    {
        float idm = i / (float) count;
        float log = near * powf(ratio, idm);
        float uniform = near + (far - near) * idm;
        distances[i] = log * lambda + uniform * (1.0f - lambda);
    }

    distances[0] = near;
    distances[count] = far;
}

void calc_frustum_corners(
    float frustum[8][4], float pos[4], float view[4], float up[4],
    float near, float far, float scale, float fov, float aspect)
{
    int i;
    float vx[4];
    float vy[4];
    float vz[4];
    float vt[4];
    float vtx[4];
    float vty[4];
    float npc[4];
    float fpc[4];
    float c[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    float smo = scale - 1.0f;

    float nearheight, farheight;
    float nearwidth, farwidth;


    static const float radians = M_PI / 180.0f;
    float viewdir[4] = { 0.0f, 0.0f, -1.0f, 1.0 };
    float updir[4] = { 0.0f, 1.0f, 0.0f, 1.0 };


    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glRotatef(CameraRotationLag[0], 1.0, 0.0, 0.0);
    glRotatef(CameraRotationLag[1], 0.0, 1.0, 0.0);
    glGetFloatv(GL_MODELVIEW_MATRIX, ModelView);

    matrix_vector_multiply(view, CameraModelViewMatrix, viewdir);
    matrix_vector_multiply(up, CameraModelViewMatrix, updir);

    vector_sub(vz, view, pos);
    vector_normalize(vz);
    vz[3] = 1.0f;

    vector_cross(vx, up, vz);
    vector_normalize(vx);
    vx[3] = 1.0f;

    vector_cross(vy, vz, vx);
    vy[3] = 1.0f;

    nearheight = tanf(radians * fov * 0.5f) * near;
    nearwidth = nearheight * aspect;

    farheight = tanf(radians * fov * 0.5f) * far;
    farwidth = farheight * aspect;

    // near plane center
    memcpy(vt, vz, 4 * sizeof(float));
    vector_scale(vt, near);
    vector_add(npc, pos, vt);

    // far plane center
    memcpy(vt, vz, 4 * sizeof(float));
    vector_scale(vt, far);
    vector_add(fpc, pos, vt);

    memcpy(vtx, vx, 4 * sizeof(float));
    vector_scale(vtx, nearwidth);

    memcpy(vty, vy, 4 * sizeof(float));
    vector_scale(vty, nearheight);


    // corner 0
    vector_sub(vt, vtx, vty);
    vector_sub(frustum[0], npc, vt);

    // corner 1
    vector_add(vt, vtx, vty);
    vector_sub(frustum[1], npc, vt);

    // corner 2
    vector_add(vt, vtx, vty);
    vector_add(frustum[2], npc, vt);

    // corner 3
    vector_sub(vt, vtx, vty);
    vector_add(frustum[3], npc, vt);

    memcpy(vtx, vx, 4 * sizeof(float));
    vector_scale(vtx, farwidth);

    memcpy(vty, vy, 4 * sizeof(float));
    vector_scale(vty, farheight);

    // corner 4
    vector_sub(vt, vtx, vty);
    vector_sub(frustum[4], fpc, vt);

    // corner 5
    vector_add(vt, vtx, vty);
    vector_sub(frustum[5], fpc, vt);

    // corner 6
    vector_add(vt, vtx, vty);
    vector_add(frustum[6], fpc, vt);

    // corner 7
    vector_sub(vt, vtx, vty);
    vector_add(frustum[7], fpc, vt);

    for ( i = 0; i < 8; i++ )
        vector_add(c, c, frustum[i]);

    c[0] /= 8.0f;
    c[1] /= 8.0f;
    c[2] /= 8.0f;

    for ( i = 0; i < 8; i++ )
    {
        vector_sub(vt, frustum[i], c);
        vector_scale(vt, smo);
        vector_add(vtx, frustum[i], vt);
        memcpy(&frustum[i][0], vtx, 4 * sizeof(float));
    }
}

void
bind_shadowmap(float projection[16], float modelview[16])
{
    const GLfloat bias[] = {0.5f, 0.0f, 0.0f, 0.0f,
                            0.0f, 0.5f, 0.0f, 0.0f,
                            0.0f, 0.0f, 0.5f, 0.0f,
                            0.5f, 0.5f, 0.5f, 1.0f
                           };

    glEnable( GL_LIGHTING );
    set_eye_linear_texgen();
    set_texgen(1);

    glActiveTextureARB(ShadowMapTexUnit);
    glMatrixMode( GL_TEXTURE );
    glLoadMatrixf( bias );
    glMultMatrixf( projection );
    glMultMatrixf( modelview );

    glMatrixMode(GL_MODELVIEW);

    glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, ShadowMapTextureId );
}

void unbind_shadowmap(void)
{
    glActiveTextureARB(DisableTexUnit);
    glDisable( GL_TEXTURE_2D );

    set_texgen(0);

    glMatrixMode( GL_TEXTURE );
    glLoadIdentity();
}

void
render_scene_from_light_view()
{
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    gluLookAt( LightPosition[0], LightPosition[1], LightPosition[2],
               0.0f, 0.0f, 0.0f,
               0.0f, 1.0f, 0.0f );

    glGetFloatv( GL_MODELVIEW_MATRIX, LightCameraMatrix );

    int viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, ShadowMapFrameBufferId);
    glViewport(0, 0, ShadowMapTextureWidth, ShadowMapTextureHeight);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable( GL_LIGHTING );
    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(PolygonOffsetScale, PolygonOffsetBias);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    static const float origin[] = { 0.0f, 0.0f, 0.0f, 1.0f };
    glLightfv( GL_LIGHT0, GL_POSITION, origin );

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective(LightFovY, 1, LightNearZ, LightFarZ);

    glMatrixMode( GL_MODELVIEW );
    glMultMatrixf( LightCameraMatrix );

    render_scene(0);

    glDisable(GL_POLYGON_OFFSET_FILL);

    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);

}

void render_scene_plain(void)
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(CameraFovY, CameraAspect, CameraNearZ, CameraFarZ);
    glGetFloatv(GL_PROJECTION_MATRIX, CameraProjectionMatrix);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(CameraPositionLag[0], CameraPositionLag[1], CameraPositionLag[2]);
    glRotatef(CameraRotationLag[0], 1.0, 0.0, 0.0);
    glRotatef(CameraRotationLag[1], 0.0, 1.0, 0.0);

    glGetFloatv(GL_MODELVIEW_MATRIX, ModelView);
    glGetFloatv(GL_MODELVIEW_MATRIX, CameraModelViewMatrix);

    glEnable( GL_LIGHTING );
    glEnable( GL_LIGHT0 );
    glDisable( GL_CULL_FACE );

    render_scene(1);

    glDisable( GL_LIGHT0 );
    glDisable( GL_LIGHTING );
}

void render_light( void )
{
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glPointSize(10.0f);
    glColor3f(1.0f, 1.0f, 0.0f);
    glBegin(GL_POINTS);
    glVertex3f(LightPosition[0], LightPosition[1], LightPosition[2]);
    glEnd();
    glPopMatrix();

    glLightfv(GL_LIGHT0, GL_POSITION, LightPosition);

}

void render_frustum(float frustum[8][4])
{
    glDisable(GL_LIGHTING);
    glDisable(GL_TEXTURE_2D);

    glBegin(GL_LINES);
    glColor3ub(255, 255, 0);
    glPushMatrix();
    glTranslatef(0, 50, 0);

    // near plane
    glVertex3fv(frustum[0]);
    glVertex3fv(frustum[1]);

    glVertex3fv(frustum[1]);
    glVertex3fv(frustum[2]);

    glVertex3fv(frustum[2]);
    glVertex3fv(frustum[3]);

    glVertex3fv(frustum[3]);
    glVertex3fv(frustum[0]);

    // left plane
    glVertex3fv(frustum[4]);
    glVertex3fv(frustum[0]);

    glVertex3fv(frustum[0]);
    glVertex3fv(frustum[3]);

    glVertex3fv(frustum[3]);
    glVertex3fv(frustum[7]);

    glVertex3fv(frustum[7]);
    glVertex3fv(frustum[4]);

    // right plane
    glVertex3fv(frustum[1]);
    glVertex3fv(frustum[5]);

    glVertex3fv(frustum[5]);
    glVertex3fv(frustum[6]);

    glVertex3fv(frustum[6]);
    glVertex3fv(frustum[2]);

    glVertex3fv(frustum[2]);
    glVertex3fv(frustum[1]);

    // far plane
    glVertex3fv(frustum[4]);
    glVertex3fv(frustum[5]);

    glVertex3fv(frustum[5]);
    glVertex3fv(frustum[6]);

    glVertex3fv(frustum[6]);
    glVertex3fv(frustum[7]);

    glVertex3fv(frustum[7]);
    glVertex3fv(frustum[4]);

    glPushMatrix();
    glEnd();

    glEnable(GL_LIGHTING);
    glEnable(GL_TEXTURE_2D);
}

void render_depth_texture( void )
{
    glDisable( GL_LIGHTING );

    glViewport( 0, 0, ShadowMapTextureWidth, ShadowMapTextureHeight );

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluOrtho2D( -1.0, 1.0, -1.0, 1.0 );

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    glMatrixMode( GL_TEXTURE );
    glLoadIdentity();

    glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, ShadowMapTextureId );

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_NONE);
    glBegin( GL_QUADS );
    {
        glTexCoord2f( 0.0f, 0.0f );
        glVertex3f( -1.0f, -1.0f, 0.0f );

        glTexCoord2f( 0.0f, 1.0f );
        glVertex3f( -1.0f, 1.0f, 0.0f );

        glTexCoord2f( 1.0f, 1.0f );
        glVertex3f( 1.0f, 1.0f, 0.0f );

        glTexCoord2f( 1.0f, 0.0f );
        glVertex3f( 1.0f, -1.0f, 0.0f );
    }
    glEnd();
    glEnable( GL_LIGHTING );
    glDisable( GL_TEXTURE_2D );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE_ARB, GL_COMPARE_R_TO_TEXTURE_ARB);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glViewport(0, 0, Width, Height);
    gluPerspective(CameraFovY, CameraAspect, CameraNearZ, CameraFarZ);
    glMatrixMode(GL_MODELVIEW);

}

void render_scene_with_shadowmap(void)
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    glTranslatef( 0.0f, -2.0f, -10.0f );

    glEnable( GL_LIGHTING );
    glEnable( GL_LIGHT0 );

    set_eye_linear_texgen();
    set_texgen(1);

    // Set up the depth texture projection
    glMatrixMode( GL_TEXTURE );
    glLoadIdentity();
    glTranslatef( 0.5f, 0.5f, 0.5f);
    glScalef( 0.5f, 0.5f, 0.5f);
    gluPerspective(LightFovY, 1.0f, LightNearZ, LightFarZ);
    glMultMatrixf( LightCameraMatrix );
    glMatrixMode(GL_MODELVIEW);

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective(CameraFovY, CameraAspect, CameraNearZ, CameraFarZ);

    glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, ShadowMapTextureId );
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glActiveTextureARB(ShadowMapTexUnit);

    render_scene(0);

    glActiveTextureARB(DisableTexUnit);
    glDisable( GL_TEXTURE_2D );

    set_texgen(0);

    glMatrixMode( GL_TEXTURE );
    glLoadIdentity();
}

void render_into_depthmap(
    unsigned int width,
    unsigned int height,
    float projection[16],
    float modelview[16])
{
    int viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, ShadowMapFrameBufferId);
    glViewport(0, 0, width, height);

    glClear(GL_DEPTH_BUFFER_BIT);

    glDisable(GL_LIGHTING);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_ALPHA_TEST);

    glPolygonOffset(PolygonOffsetScale, PolygonOffsetBias);
    glEnable(GL_POLYGON_OFFSET_FILL);

    glDepthMask(1.0f);
    glDepthFunc(GL_LESS);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    glMatrixMode( GL_PROJECTION );
    glLoadMatrixf( projection );

    glMatrixMode(GL_MODELVIEW);
    glLoadMatrixf( modelview );

    render_scene(0);

    glDisable(GL_CULL_FACE);
    glDepthFunc(GL_LEQUAL);
    glDisable(GL_POLYGON_OFFSET_FILL);
    glEnable(GL_LIGHTING);

    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
}

void render_scene_with_pssm(
    float frustum[8][4],
    float projection[16],
    float modelview[16],
    float near, float far)
{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(CameraFovY, CameraAspect, near, far);
    glGetFloatv(GL_PROJECTION_MATRIX, CameraProjectionMatrix);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(CameraPositionLag[0], CameraPositionLag[1], CameraPositionLag[2]);
    glRotatef(CameraRotationLag[0], 1.0, 0.0, 0.0);
    glRotatef(CameraRotationLag[1], 0.0, 1.0, 0.0);

    glGetFloatv(GL_MODELVIEW_MATRIX, ModelView);
    glGetFloatv(GL_MODELVIEW_MATRIX, CameraModelViewMatrix);

    bind_shadowmap(projection, modelview);
    render_scene(1);
    unbind_shadowmap();
}


void render_scene_pssm(void)
{
    unsigned int i = 0;

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    calc_split_distances(SplitDistances, SplitCount, 1.0f, LightFarZ);

    for ( i = 0; i < SplitCount; i++)
    {
        float frustum[8][4];
        float near = SplitDistances[i + 0];
        float far = SplitDistances[i + 1];

        calc_frustum_corners(frustum, CameraPositionLag, CameraView, CameraUp,
                             1.0f, far, 1.0f, 45.0f, CameraAspect);

        calc_light_matrices(LightProjectionMatrix, LightModelViewMatrix, frustum, LightPosition);

        render_into_depthmap(ShadowMapTextureWidth, ShadowMapTextureHeight, LightProjectionMatrix, LightModelViewMatrix);

        // glDepthRange( (i+0.0f) / (float)SplitCount, (i+1.0f) / (float)SplitCount);

        render_scene_with_pssm(frustum, LightProjectionMatrix, LightModelViewMatrix, near, far);
    }

}

////////////////////////////////////////////////////////////////////////////////

void draw_string(float x, float y, float color[4], char *buffer)
{
    unsigned int uiLen, i;

    glPushAttrib(GL_LIGHTING_BIT);
    glDisable(GL_LIGHTING);

    glRasterPos2f(x, y);
    glColor3f(color[0], color[1], color[2]);
    uiLen = (unsigned int) strlen(buffer);
    for (i = 0; i < uiLen; i++)
    {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, buffer[i]);
    }
    glPopAttrib();
}

void draw_text(float x, float y, int light, char *format, ...)
{
    va_list args;
    char buffer[256];
    GLint iVP[4];
    GLint iMatrixMode;

    va_start(args, format);
    vsprintf(buffer, format, args);
    va_end(args);

    // disable lighting
    glPushAttrib(GL_LIGHTING_BIT);
    glDisable(GL_LIGHTING);
    glDisable(GL_BLEND);

    // save the current viewport
    glGetIntegerv(GL_VIEWPORT, iVP);
    glViewport(0, 0, Width, Height);

    // save the current matrixmode
    glGetIntegerv(GL_MATRIX_MODE, &iMatrixMode);

    // clear out the projection matrix
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();

    // clear out the modelview matrix
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    // start outputting from the bottom of the screen, upwards
    glScalef(2.0f / Width, -2.0f / Height, 1.0f);
    glTranslatef(-Width / 2.0f, -Height / 2.0f, 0.0f);

    if(light)
    {
        glColor4fv(ShadowTextColor);
        draw_string(x-0, y-0, ShadowTextColor, buffer);

        glColor4fv(HighlightTextColor);
        draw_string(x-2, y-2, HighlightTextColor, buffer);
    }
    else
    {
        glColor4fv(HighlightTextColor);
        draw_string(x-0, y-0, HighlightTextColor, buffer);

        glColor4fv(ShadowTextColor);
        draw_string(x-2, y-2, ShadowTextColor, buffer);   
    }
    
    // restore the projection matrix
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);

    // restore the previous matrix
    glPopMatrix();
    glMatrixMode(iMatrixMode);

    // restor the previous attributes
    glPopAttrib();

    // restore the previous viewport
    glViewport(iVP[0], iVP[1], iVP[2], iVP[3]);
}

static void 
report_stats(uint64_t start, uint64_t end)
{
    TimeElapsed += subtract_time(end, start);

    if(TimeElapsed && FrameCount && FrameCount > ReportStatsInterval) 
	{
        double fMs = (TimeElapsed * 1000.0 / (double) FrameCount);
        double fFps = 1.0 / (fMs / 1000.0);
        
        sprintf(StatsString, "[%s] Compute: %3.2f ms  Display: %3.2f fps (%s)\n", 
                (ComputeDeviceType == CL_DEVICE_TYPE_GPU) ? "GPU" : "CPU", 
                fMs, fFps, USE_GL_ATTACHMENTS ? "attached" : "copying");
		
		glutSetWindowTitle(StatsString);

		FrameCount = 0;
        TimeElapsed = 0;
	}    
}

void
display(void)
{
    FrameCount++;

    uint64_t start = current_time();
    int err = recompute();
    if (err != 0)
    {
        printf("error %d from recompute!\n", err);
        shutdown_opencl();
        exit(1);
    }
    
    int c = 0;
    for (c = 0; c < 3; ++c)
    {
        CameraPositionLag[c] += (CameraPosition[c] - CameraPositionLag[c]) * Inertia;
        CameraRotationLag[c] += (CameraRotation[c] - CameraRotationLag[c]) * Inertia;
    }

    if (SphereShader == FresnelShader)
        render_scene_plain();
    else
        render_scene_pssm();

    if ( ShowStats)
    {
        draw_text(20, Height - 20, SphereShader == FresnelShader, StatsString);
    }

    if (ShowInfo)
    {
        draw_text(Width - strlen(InfoString) * 10, Height - 20, SphereShader == FresnelShader, InfoString);
        ShowInfo = (ShowInfo > 200) ? 0 : ShowInfo + 1;
    }
    draw_text(20, 30, SphereShader == FresnelShader, "Press ~ to change shaders");
    
    glutSwapBuffers();

    uint64_t end = current_time();
    report_stats(start, end);

    if (Animate)
        Phase += 0.01f;

}

void motion(int x, int y)
{
    float dx, dy;
    dx = x - ox;
    dy = y - oy;

    switch (MouseMode)
    {
    case M_VIEW:
        if (ButtonState == 3)
        {
            // left+middle = zoom
            CameraPosition[2] += (dy / 100.0) * 0.5 * fabs(CameraPosition[2]);
            CameraPosition[2] = CameraPosition[2] < -10.0f ? -10.0f : CameraPosition[2];
            CameraPosition[2] = CameraPosition[2] > -3.0f ? -3.0f : CameraPosition[2];
        }
        else if (ButtonState & 2)
        {
            // middle = translate
            CameraPosition[0] += dx / 100.0;
            CameraPosition[1] -= dy / 100.0;
        }
        else if (ButtonState & 1)
        {
            // left = rotate
            CameraRotation[0] += dy / 5.0;
            CameraRotation[1] += dx / 5.0;
        }
        break;

    case M_MOVE:
    {
        float translateSpeed = 0.003f;
        if (ButtonState == 1)
        {
            float v[3], r[3];
            v[0] = dx * translateSpeed;
            v[1] = -dy * translateSpeed;
            v[2] = 0.0f;
            inv_matrix_vector_multiply(v, r, ModelView);
        }
        else if (ButtonState == 2)
        {
            float v[3], r[3];
            v[0] = 0.0f;
            v[1] = 0.0f;
            v[2] = dy * translateSpeed;
            inv_matrix_vector_multiply(v, r, ModelView);
        }
    }
    break;
    }

    ox = x;
    oy = y;
    glutPostRedisplay();
}

void mouse(int button, int state, int x, int y)
{
    int mods;

    if (state == GLUT_DOWN)
        ButtonState |= 1 << button;

    else if (state == GLUT_UP)
        ButtonState = 0;

    mods = glutGetModifiers();
    if (mods & GLUT_ACTIVE_SHIFT)
    {
        ButtonState = 2;
    }
    else if (mods & GLUT_ACTIVE_CTRL)
    {
        ButtonState = 3;
    }

    ox = x;
    oy = y;
    glutPostRedisplay();
}

void reshape (int w, int h)
{
    // Prevent a divide by zero, when window is too short
    if ( h == 0 )
        h = 1;

    CameraAspect = 1.0f * w / h;
    Width = w;
    Height = h;

    // Reset the coordinate system before modifying
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Set the viewport to be the entire window
    glViewport(0, 0, Width, Height);

    // Set the correct perspective.
    gluPerspective(CameraFovY, CameraAspect, CameraNearZ, CameraFarZ);
    glMatrixMode(GL_MODELVIEW);
}

void keyboard(unsigned char key, int x, int y)
{
    switch (key)
    {
    case '=':
        Frequency *= 1.01;
        sprintf(InfoString,"Frequency = %f\n", Frequency);
        ShowInfo = 1;
        break;

    case '-':
        Frequency *= 0.99;
        sprintf(InfoString,"Frequency = %f\n", Frequency);
        ShowInfo = 1;
        break;

    case '[':
        Amplitude *= 0.95f;
        sprintf(InfoString,"Amplitude = %f\n", Amplitude);
        ShowInfo = 1;
        break;

    case ']':
        Amplitude = (Amplitude < 7.0f) ? (Amplitude * 1.05f) : Amplitude;
        sprintf(InfoString,"Amplitude = %f\n", Amplitude);
        ShowInfo = 1;
        break;

    case ';':
        Lacunarity *= 1.01;
        sprintf(InfoString,"Lacunarity = %f\n", Lacunarity);
        ShowInfo = 1;
        break;

    case '\'':
        Lacunarity *= 0.99;
        sprintf(InfoString,"Lacunarity = %f\n", Lacunarity);
        ShowInfo = 1;
        break;

    case '.':
        Increment *= 1.05;
        sprintf(InfoString,"Increment = %f\n", Increment);
        ShowInfo = 1;
        break;

    case '/':
        Increment *= 0.95;
        sprintf(InfoString,"Increment = %f\n", Increment);
        ShowInfo = 1;
        break;

    case 'x':
        Octaves = (Octaves < 7.0f) ? (Octaves * 1.05f) : Octaves;
        sprintf(InfoString,"Octaves = %f\n", Octaves);
        ShowInfo = 1;
        break;

    case 'z':
        Octaves *= 0.95;
        sprintf(InfoString,"Octaves = %f\n", Octaves);
        ShowInfo = 1;
        break;

    case 'c':
        Roughness *= 1.05;
        sprintf(InfoString,"Roughness = %f\n", Roughness);
        ShowInfo = 1;
        break;

    case 'v':
        Roughness *= 0.95;
        sprintf(InfoString,"Roughness = %f\n", Roughness);
        ShowInfo = 1;
        break;

    case 'b':
        ShadowMapSoftness *= 1.05;
        sprintf(InfoString,"ShadowMapSoftness = %f\n", ShadowMapSoftness);
        ShowInfo = 1;
        break;

    case 'n':
        ShadowMapSoftness *= 0.95;
        sprintf(InfoString,"ShadowMapSoftness = %f\n", ShadowMapSoftness);
        ShowInfo = 1;
        break;

    case '1':
        RefractiveIndex = (RefractiveIndex > 1.0f) ? (RefractiveIndex * 0.95f) : (RefractiveIndex * 1.0f);
        sprintf(InfoString,"RefractiveIndex = %f\n", RefractiveIndex);
        ShowInfo = 1;
        break;

    case '2':
        RefractiveIndex = (RefractiveIndex < 3.0f) ? (RefractiveIndex * 1.05f) : (RefractiveIndex * 1.0f);
        sprintf(InfoString,"RefractiveIndex = %f\n", RefractiveIndex);
        ShowInfo = 1;
        break;

    case '3':
        ChromaticDispersion *= 0.95f;
        sprintf(InfoString,"ChromaticDispersion = %f\n", ChromaticDispersion);
        ShowInfo = 1;
        break;

    case '4':
        ChromaticDispersion *= 1.05f;
        sprintf(InfoString,"ChromaticDispersion = %f\n", ChromaticDispersion);
        ShowInfo = 1;
        break;

    case '5':
        FresnelBias *= 0.95f;
        sprintf(InfoString,"FresnelBias = %f\n", FresnelBias);
        ShowInfo = 1;
        break;

    case '6':
        FresnelBias *= 1.05f;
        sprintf(InfoString,"FresnelBias = %f\n", FresnelBias);
        ShowInfo = 1;
        break;

    case '7':
        FresnelScale *= 0.95f;
        sprintf(InfoString,"FresnelScale = %f\n", FresnelScale);
        ShowInfo = 1;
        break;

    case '8':
        FresnelScale *= 1.05f;
        sprintf(InfoString,"FresnelScale = %f\n", FresnelScale);
        ShowInfo = 1;
        break;

    case '9':
        FresnelPower *= 0.95f;
        sprintf(InfoString,"FresnelPower = %f\n", FresnelPower);
        ShowInfo = 1;
        break;

    case '0':
        FresnelPower *= 1.05f;
        sprintf(InfoString,"FresnelPower = %f\n", FresnelPower);
        ShowInfo = 1;
        break;

    case ' ':
        Animate = Animate == 1 ? 0 : 1;
        sprintf(InfoString,"Animate = %d\n", Animate);
        ShowInfo = 1;
        break;

    case '`':
        SphereShader = (SphereShader == PhongShader) ? FresnelShader : PhongShader;
        break;

    case 't':
        PolygonOffsetScale *= 0.95f;
        sprintf(InfoString,"PolygonOffsetScale = %f\n", PolygonOffsetScale);
        break;

    case 'y':
        PolygonOffsetScale *= 1.05f;
        sprintf(InfoString,"PolygonOffsetScale = %f\n", PolygonOffsetScale);
        ShowInfo = 1;
        break;

    case 'u':
        PolygonOffsetBias *= 0.95f;
        sprintf(InfoString,"PolygonOffsetBias = %f\n", PolygonOffsetBias);
        ShowInfo = 1;
        break;

    case 'i':
        PolygonOffsetBias *= 1.05f;
        sprintf(InfoString,"PolygonOffsetBias = %f\n", PolygonOffsetBias);
        ShowInfo = 1;
        break;

    case '\\':
        ShowStats = ShowStats ? 0 : 1;
        break;

    case 'q':
    case 27:
        shutdown_opencl();
        exit(0);
        break;
    }
    glutPostRedisplay();
}

int init(int gpu)
{
    int err;

    err = setup_opengl();
    if (err != GL_NO_ERROR)
    {
        printf ("Failed to setup OpenGL state!");
        exit (err);
    }

    err = setup_opencl(gpu);
    if (err != GL_NO_ERROR)
    {
        printf ("Failed to setup OpenCL state! Error %d\n", err);
        exit (err);
    }

    return CL_SUCCESS;
}

int main(int argc, char** argv)
{
    int use_gpu = 1;
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
    glutInitWindowSize (Width, Height);
    glutInitWindowPosition (100, 100);
    glutCreateWindow (argv[0]);
    if (init(use_gpu) == GL_NO_ERROR)
    {
        glutDisplayFunc(display);
        glutIdleFunc(display);
        glutMouseFunc(mouse);
        glutMotionFunc(motion);
        glutReshapeFunc(reshape);
        glutKeyboardFunc(keyboard);
        
        printf(SEPARATOR);
        printf("Starting event loop...\n");
        printf(SEPARATOR);
        
        glutMainLoop();
    }
    return 0;
}

