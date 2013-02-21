//
// File:       noise.c
//
// Abstract:   This example shows how OpenCL can be used for procedural texture synthesis
//             and intermix with existing OpenGL textures for display.  Several compute
//             kernels are provided which generate a variety of procedural functions,
//             including gradient noise (aka Perlin Noise), turbulence and other
//             fractals.
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <OpenGL/OpenGL.h>
#include <OpenCL/opencl.h>
#include <GLUT/glut.h>

#include <mach/mach_time.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

#define USE_GL_ATTACHMENTS (1)             // enable OpenGL attachments for Compute results
#define DEBUG_INFO         (0)             // enable debug info
#define SEPARATOR          ("----------------------------------------------------------------------\n")

////////////////////////////////////////////////////////////////////////////////////////////////////

static cl_context                               ComputeContext;
static cl_command_queue                         ComputeCommands;
static cl_kernel                                ComputeKernel;
static cl_program                               ComputeProgram;
static cl_device_id                             ComputeDeviceId;
static cl_device_type                           ComputeDeviceType;
static cl_mem                                   ComputeResult;
#if USE_GL_ATTACHMENTS
static cl_mem                                   ComputeImage;
#endif

////////////////////////////////////////////////////////////////////////////////

#define COMPUTE_KERNEL_FILENAME                 ("noise_kernel.cl")
#define COMPUTE_KERNEL_COUNT                    4

static cl_kernel ComputeKernels[COMPUTE_KERNEL_COUNT];
static int ComputeKernelWorkGroupSizes[COMPUTE_KERNEL_COUNT];
static const char * ComputeKernelMethods[COMPUTE_KERNEL_COUNT] =
{
    "GradientNoiseArray2d",
    "MonoFractalArray2d",
    "TurbulenceArray2d",
    "RidgedMultiFractalArray2d",
};

////////////////////////////////////////////////////////////////////////////////

static uint TextureId                           = 0;
static uint TextureTarget                       = GL_TEXTURE_2D;
static uint TextureInternal                     = GL_RGBA;
static uint TextureFormat                       = GL_BGRA;
static uint TextureType                         = GL_UNSIGNED_INT_8_8_8_8_REV;
static size_t TextureTypeSize                   = sizeof(char);
static uint ActiveTextureUnit                   = GL_TEXTURE1_ARB;
static void* HostImageBuffer                    = 0;

static int Width                                = 512;
static int Height                               = 512;

static float Scale                              = 20.0f;
static float Bias[2]                            = { 128.0f, 128.0f };
static float Lacunarity                         = 2.02f;
static float Increment                          = 1.0f;
static float Octaves                            = 3.3f;
static float Amplitude                          = 1.0f;

static float ShadowTextColor[4]                 = { 0.0f, 0.0f, 0.0f, 1.0f };
static float HighlightTextColor[4]              = { 0.2f, 0.6f, 0.8f, 1.0f };
static uint TextOffset[2]                       = { 20, 20 };

static int MouseX                               = 0;
static int MouseY                               = 0;
static int ButtonState                          = 0;
static int ActiveKernel                         = 0;

static double TimeElapsed                       = 0;
static int FrameCount                           = 0;
static uint ReportStatsInterval                 = 60;

static char StatsString[1024]                   = "\0";
static char InfoString[1024]                    = "\0";
static uint ShowInfo                            = 0;

////////////////////////////////////////////////////////////////////////////////

static float TexCoords[4][2];
static float VertexPos[4][2] =
{
    { -1.0f, -1.0f },
    {  1.0f, -1.0f },
    {  1.0f,  1.0f },
    { -1.0f,  1.0f }
};

////////////////////////////////////////////////////////////////////////////////

static uint64_t
GetCurrentTime()
{
    return mach_absolute_time();
}
	
static double 
SubtractTime( uint64_t uiEndTime, uint64_t uiStartTime )
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


static int 
FloorPow2(int n)
{
    int exp;
    frexp((float)n, &exp);
    return 1 << (exp - 1);
}

////////////////////////////////////////////////////////////////////////////////

static int LoadTextFromFile(
    const char *file_name, char **result_string, size_t *string_len)
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

static void 
CreateTexture(uint width, uint height)
{
    if (HostImageBuffer)
        free(HostImageBuffer);

    HostImageBuffer = malloc(Width * Height * TextureTypeSize * 4);
    memset(HostImageBuffer, 0, Width * Height * TextureTypeSize * 4);

    glActiveTextureARB(ActiveTextureUnit);
    glGenTextures(1, &TextureId);
    glBindTexture(TextureTarget, TextureId);
    glTexParameteri(TextureTarget, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(TextureTarget, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameteri(TextureTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(TextureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(TextureTarget, 0, TextureInternal, width, height, 0, 
                TextureFormat, TextureType, HostImageBuffer);
    glBindTexture(TextureTarget, 0);

#if USE_GL_ATTACHMENTS
    free(HostImageBuffer);
    HostImageBuffer = 0;
#endif
}

static void 
RenderTexture( void *pvData )
{
    glDisable( GL_LIGHTING );

    glViewport( 0, 0, Width, Height );

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluOrtho2D( -1.0, 1.0, -1.0, 1.0 );

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    glMatrixMode( GL_TEXTURE );
    glLoadIdentity();

    glEnable( TextureTarget );
    glBindTexture( TextureTarget, TextureId );

    if(pvData)
        glTexSubImage2D(TextureTarget, 0, 0, 0, Width, Height, 
                        TextureFormat, TextureType, pvData);

    glTexParameteri(TextureTarget, GL_TEXTURE_COMPARE_MODE_ARB, GL_NONE);
    glBegin( GL_QUADS );
    {
        glColor3f(1.0f, 1.0f, 1.0f);
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
    glBindTexture( TextureTarget, 0 );
    glDisable( TextureTarget );
}

static int
Recompute(void)
{
    void *values[10];
    size_t sizes[10];
    size_t global[2];
    size_t local[2];

    int arg = 0;
    int err = 0;
    float bias[2] = { fabs(Bias[0]), fabs(Bias[1]) };
    float scale[2] = { fabs(Scale), fabs(Scale) };

    unsigned int v = 0, s = 0;
    values[v++] = &ComputeResult;
    values[v++] = bias;
    values[v++] = scale;
    if(ActiveKernel > 0)
    {
        values[v++] = &Lacunarity;
        values[v++] = &Increment;
        values[v++] = &Octaves;
    }
    values[v++] = &Amplitude;

    sizes[s++] = sizeof(cl_mem);
    sizes[s++] = sizeof(float) * 2;
    sizes[s++] = sizeof(float) * 2;
    if(ActiveKernel > 0)
    {
        sizes[s++] = sizeof(float);
        sizes[s++] = sizeof(float);
        sizes[s++] = sizeof(float);
    }
    sizes[s++] = sizeof(float);

    err = CL_SUCCESS;
    for (arg = 0; arg < s; arg++)
    {
        err |= clSetKernelArg(ComputeKernels[ActiveKernel], arg, sizes[arg], values[arg]);
    }

    if (err)
        return -10;

    global[0] = Width;
    global[1] = Height;

    local[0] = ComputeKernelWorkGroupSizes[ActiveKernel];
    local[1] = 1;

#if DEBUG_INFO
    if(FrameCount <= 1)
        printf("Global[%4d %4d] Local[%4d %4d]\n", 
            (int)global[0], (int)global[1],
            (int)local[0], (int)local[1]);
#endif

    err = clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[ActiveKernel], 2, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Failed to enqueue kernel! %d\n", err);
        return EXIT_FAILURE;
    }

#if USE_GL_ATTACHMENTS

    err = clEnqueueAcquireGLObjects(ComputeCommands, 1, &ComputeImage, 0, 0, 0);
    if (err != CL_SUCCESS)
    {
        printf("Failed to acquire GL object! %d\n", err);
        return EXIT_FAILURE;
    }

    size_t origin[] = { 0, 0, 0 };
    size_t region[] = { Width, Height, 1 };

    err = clEnqueueCopyBufferToImage(ComputeCommands, ComputeResult, ComputeImage, 
                                     0, origin, region, 0, NULL, 0);
    
    if(err != CL_SUCCESS)
    {
        printf("Failed to copy buffer to image! %d\n", err);
        return EXIT_FAILURE;
    }
        
    err = clEnqueueReleaseGLObjects(ComputeCommands, 1, &ComputeImage, 0, 0, 0);
    if (err != CL_SUCCESS)
    {
        printf("Failed to release GL object! %d\n", err);
        return EXIT_FAILURE;
    }

#else
    err = clEnqueueReadBuffer( ComputeCommands, ComputeResult, CL_TRUE, 0, 
                               Width * Height * TextureTypeSize * 4, 
                               HostImageBuffer, 0, NULL, NULL );      
    if (err)
        return -5;
#endif
        
    return CL_SUCCESS;
}

////////////////////////////////////////////////////////////////////////////////

static int 
CreateComputeResult(void)
{

    int err = 0;
    printf(SEPARATOR);

#if USE_GL_ATTACHMENTS

    printf("Allocating compute result image...\n");
	ComputeImage = clCreateFromGLTexture2D(ComputeContext, CL_MEM_WRITE_ONLY, TextureTarget, 0, TextureId, &err);
    if (!ComputeImage || err != CL_SUCCESS)
    {
        printf("Failed to create OpenGL texture reference! %d\n", err);
        return -1;
    }
    
#endif

    printf("Allocating compute result buffer...\n");
    ComputeResult = clCreateBuffer(ComputeContext, CL_MEM_WRITE_ONLY, TextureTypeSize * 4 * Width * Height, NULL, &err);
    if (!ComputeResult || err != CL_SUCCESS)
    {
        printf("Failed to create OpenCL array! %d\n", err);
        return EXIT_FAILURE;
    }

    return CL_SUCCESS;
}

static int 
SetupComputeKernels(void)
{
    int err = 0;
    char *source = 0;
    size_t length = 0;

    printf(SEPARATOR);
    printf("Loading kernel source from file '%s'...\n", COMPUTE_KERNEL_FILENAME);    
    err = LoadTextFromFile(COMPUTE_KERNEL_FILENAME, &source, &length);
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

        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(ComputeProgram, ComputeDeviceId, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
        printf("%s\n", buffer);
        return EXIT_FAILURE;
    }

    // Create the compute kernel from within the program
    //
    int i = 0;
    for(i = 0; i < COMPUTE_KERNEL_COUNT; i++)
    {   
        printf("Creating kernel '%s'...\n", ComputeKernelMethods[i]);

        ComputeKernels[i] = clCreateKernel(ComputeProgram, ComputeKernelMethods[i], &err);
        if (!ComputeKernels[i] || err != CL_SUCCESS)
        {
            printf("Error: Failed to create compute kernel!\n");
            return EXIT_FAILURE;
        }
    
        // Get the maximum work group size for executing the kernel on the device
        //
        size_t max = 1;
        err = clGetKernelWorkGroupInfo(ComputeKernels[i], ComputeDeviceId, CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &max, NULL);
        if (err != CL_SUCCESS)
        {
            printf("Error: Failed to retrieve kernel work group info! %d\n", err);
            return EXIT_FAILURE;
        }

        ComputeKernelWorkGroupSizes[i] = (max > 1) ? FloorPow2(max) : max;  // use nearest power of two (less than max)

        printf("%s MaxWorkGroupSize: %d\n", ComputeKernelMethods[i], (int)ComputeKernelWorkGroupSizes[i]);

    }

    return CreateComputeResult();

}

static int 
SetupComputeDevices(int gpu)
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
    if (!ComputeContext)
    {
        printf("Error: Failed to create a compute context!\n");
        return EXIT_FAILURE;
    }

#else

    // Locate a compute device
    //
    err = clGetDeviceIDs(NULL, ComputeDeviceType, 1, &ComputeDeviceId, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: Failed to locate compute device!\n");
        return EXIT_FAILURE;
    }
  
    // Create a context containing the compute device(s)
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

static void
ShutdownCompute(void)
{
    printf(SEPARATOR);
    printf("Shutting down...\n");

    clFinish(ComputeCommands);
    clReleaseKernel(ComputeKernel);
    clReleaseProgram(ComputeProgram);
    clReleaseCommandQueue(ComputeCommands);
    clReleaseMemObject(ComputeResult);
#if USE_GL_ATTACHMENTS
    clReleaseMemObject(ComputeImage);
#endif
}

////////////////////////////////////////////////////////////////////////////////

static int 
SetupGraphics(void)
{
    glClearColor (0.0f, 0.0f, 0.0f, 0.0f);

    CreateTexture(Width, Height);

    glDisable(GL_DEPTH_TEST);
    glActiveTexture(GL_TEXTURE0);
    
    glViewport(0, 0, Width, Height);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    TexCoords[3][0] = 0.0f;
    TexCoords[3][1] = 0.0f;
    TexCoords[2][0] = Width;
    TexCoords[2][1] = 0.0f;
    TexCoords[1][0] = Width;
    TexCoords[1][1] = Height;
    TexCoords[0][0] = 0.0f;
    TexCoords[0][1] = Height;

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, VertexPos);
    glClientActiveTexture(GL_TEXTURE0);
    glTexCoordPointer(2, GL_FLOAT, 0, TexCoords);
    return GL_NO_ERROR;
}

static int 
Initialize(int gpu)
{
    int err;
    err = SetupGraphics();
    if (err != GL_NO_ERROR)
    {
        printf ("Failed to setup OpenGL state!");
        exit (err);
    }

    err = SetupComputeDevices(gpu);
    if(err != CL_SUCCESS)
    {
        printf ("Failed to connect to compute device! Error %d\n", err);
        exit (err);
    }

    err = SetupComputeKernels();
    if (err != CL_SUCCESS)
    {
        printf ("Failed to setup compute kernel! Error %d\n", err);
        exit (err);
    }
    printf(SEPARATOR);
    printf("Starting event loop...\n");

    return CL_SUCCESS;
}

static void
DrawString(float x, float y, float color[4], char *buffer)
{
	unsigned int uiLen, i;

	glRasterPos2f(x, y);
	glColor3f(color[0], color[1], color[2]);
	uiLen = (unsigned int) strlen(buffer);
	for (i = 0; i < uiLen; i++)
	{
		glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, buffer[i]);
	}
}


static void 
DrawText(float x, float y, float color[4], char *acString) 
{
    GLint iVP[4];
    GLint iMatrixMode;
       
    glColor3f(color[0], color[1], color[2]);
   
    glDisable(GL_DEPTH_TEST);
	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	glGetIntegerv(GL_VIEWPORT, iVP);
	glViewport(0, 0, Width, Height);

	glGetIntegerv(GL_MATRIX_MODE, &iMatrixMode);

	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();

	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();

	glScalef(2.0f / (float)Width, -2.0f / (float)Height, 1.0f);
	glTranslatef(-(float)Width / 2.0f, -(float)Height / 2.0f, 0.0f);
    DrawString(x, y, color, acString);

	glPopMatrix();
	glMatrixMode(GL_PROJECTION);

	glPopMatrix();
	glMatrixMode(iMatrixMode);

	glPopAttrib();
    
	glViewport(iVP[0], iVP[1], iVP[2], iVP[3]);
}

static void 
ReportStats(
    uint64_t uiStartTime, uint64_t uiEndTime)
{
    TimeElapsed += SubtractTime(uiEndTime, uiStartTime);

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

static void
ReportInfo(void)
{
    if(ShowInfo == 0)
        return;
        
    int iX = TextOffset[0];
    int iY = TextOffset[1];
    
    DrawText(Width - iX - 1 - strlen(InfoString) * 10, Height - iY - 1, ShadowTextColor, InfoString);
    DrawText(Width - iX - 2 - strlen(InfoString) * 10, Height - iY - 2, ShadowTextColor, InfoString);
    DrawText(Width - iX - strlen(InfoString) * 10, Height - iY, HighlightTextColor, InfoString);

    ShowInfo = (ShowInfo > 200) ? 0 : ShowInfo + 1;
}

static void
Display(void)
{
    FrameCount++;
    uint64_t uiStartTime = GetCurrentTime();
    
    glClear (GL_COLOR_BUFFER_BIT);
    
    int err = Recompute();
    if (err != 0)
    {
        printf("Error %d from Recompute!\n", err);
        exit(1);
    }

    RenderTexture(HostImageBuffer);
    ReportInfo();
    
    glFinish(); // for timing

    uint64_t uiEndTime = GetCurrentTime();
    ReportStats(uiStartTime, uiEndTime);

    glutSwapBuffers();
    glutPostRedisplay();
}

static void 
Reshape (int w, int h)
{
    glViewport(0, 0, w, h);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
}

static void 
Keyboard(unsigned char key, int x, int y)
{
    switch (key)
    {
    case '1':
    case '2':
    case '3':
    case '4':
        ActiveKernel = key - '1';
        sprintf(InfoString, "%s\n", ComputeKernelMethods[ActiveKernel]);
        ShowInfo = 1;        
        break;

    case '=':
        Scale *= 0.90;
        sprintf(InfoString,"Scale = %f\n", Scale);
        ShowInfo = 1;        
        break;

    case '-':
        Scale *= 1.10;
        sprintf(InfoString,"Scale = %f\n", Scale);
        ShowInfo = 1;        
        break;

    case 'q':
        exit(0);
        break;
    
    case 'z':
        Amplitude *= (1.0f / 1.1f);
        Amplitude = Amplitude < 0.0001f ? 0.0001f : Amplitude;
        sprintf(InfoString,"Amplitude = %f\n", Amplitude);
        ShowInfo = 1;
        break;

    case 'x':
        Amplitude *= (1.1f);
        sprintf(InfoString,"Amplitude = %f\n", Amplitude);
        ShowInfo = 1;
        break;
    
    case 'c':
        Octaves *= (1.0f / 1.1f);
        Octaves = Octaves < 1.0f ? 1.0f : Octaves;
        sprintf(InfoString,"Octaves = %f\n", Octaves);
        ShowInfo = 1;
        break;

    case 'v':
        Octaves *= (1.1f);
        Octaves = Octaves > 10.0f ? 10.0f : Octaves;
        sprintf(InfoString,"Octaves = %f\n", Octaves);
        ShowInfo = 1;
        break;

    case 'b':
        Lacunarity *= (1.0f / 1.0001f);
        printf("Lacunarity = %f\n", Lacunarity);
        sprintf(InfoString,"Lacunarity = %f\n", Lacunarity);
        ShowInfo = 1;
        break;

    case 'n':
        Lacunarity *= (1.0001f);
        sprintf(InfoString,"Lacunarity = %f\n", Lacunarity);
        ShowInfo = 1;
        break;
        
    case 'm':
        Increment *= (1.0f / 1.1f);
        sprintf(InfoString, "Increment = %f\n", Increment);
        ShowInfo = 1;
        break;

    case ',':
        Increment *= (1.1f);
        sprintf(InfoString, "Increment = %f\n", Increment);
        ShowInfo = 1;
        break;

    case 27:
        ShutdownCompute();
        exit(0);
        break;
    }
    glutPostRedisplay();
}

static void
Motion(int x, int y)
{
    float dx, dy;
    dx = x - MouseX;
    dy = y - MouseY;

    if (ButtonState == 3) 
    {
        Scale += (dy / 100.0) * 0.5 * fabs(Scale);
        sprintf(InfoString,"Scale = %.3f\n", Scale);
        ShowInfo = 1;
    } 
    else if (ButtonState & 1) 
    {
        Bias[0] += dx / 100.0f / Scale;
        Bias[1] += dy / 100.0f / Scale;
        sprintf(InfoString,"Bias = (%.3f, %.3f)\n", Bias[0], Bias[1]);
        ShowInfo = 1;
    }
    else if (ButtonState & 2) 
    {
        Bias[0] += dy / 5.0;
        Bias[1] += dx / 5.0;
        sprintf(InfoString,"Bias = (%.3f, %.3f)\n", Bias[0], Bias[1]);
        ShowInfo = 1;
    }

    MouseX = x; MouseY = y;
    glutPostRedisplay();
}
static void
Mouse(int button, int state, int x, int y)
{
    int mods;

    if (state == GLUT_DOWN)
        ButtonState |= 1<<button;
    
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

    MouseX = x; MouseY = y;
    glutPostRedisplay();
}

int main(int argc, char** argv)
{
    int use_gpu = 1;
    
    // Parse command line options
    //
    int i;
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
    }
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
    glutInitWindowSize (Width, Height);
    glutInitWindowPosition (0, 0);
    glutCreateWindow (argv[0]);

    if (Initialize(use_gpu) == GL_NO_ERROR)
    {
        glutDisplayFunc(Display);
        glutIdleFunc(Display);
        glutReshapeFunc(Reshape);
        glutKeyboardFunc(Keyboard);
        glutMouseFunc(Mouse);
        glutMotionFunc(Motion);        
        glutMainLoop();
    }
    
    atexit(ShutdownCompute);
    
    return 0;
}

