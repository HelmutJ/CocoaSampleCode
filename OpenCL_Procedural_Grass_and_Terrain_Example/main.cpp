//
// File:       main.cpp
//
// Abstract:   This example shows how OpenCL can be used to create a procedural field of 
//             grass on a generated terrain model which is then rendered with OpenGL.  
//             Because OpenGL buffers are shared with OpenCL, the data can remain on the 
//             graphics card, thus eliminating the API overhead of creating and submitting 
//             the vertices from the host.
//
//             All geometry is generated on the compute device, and outputted into
//             a shared OpenGL buffer.  The terrain gets generated only within the 
//             visible arc covering the camera's view frustum to avoid the need for 
//             culling.  A page of grass is computed on the surface of the terrain as
//             bezier patches, and flow noise is applied to the angle of the blades
//             to simulate wind.  Multiple instances of grass are rendered at jittered
//             offsets to add more grass coverage without having to compute new pages.
//             Finally, a physically based sky shader (via OpenGL) is applied to 
//             the background to provide an environment for the grass.
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

#include <OpenGL/gl.h> 
#include <GLUT/glut.h> 

#include <stdio.h> 
#include <stdlib.h> 
#include <math.h> 

#include "compute_math.h"
#include "compute_engine.h"
#include "grass_simulator.h"
#include "terrain_simulator.h"
#include "mesh_renderer.h"
#include "grid_mesh.h"
#include "camera.h"
#include "shader.h"
#include "timing.h"

//////////////////////////////////////////////////////////////////////////////

#define USE_GL_ATTACHMENT    (1)     // enable gl buffers as attachments

//////////////////////////////////////////////////////////////////////////////

static bool UseGPU                                  = true;
static bool Paused                                  = false;
static bool Wireframe                               = false;
static bool AnimatedSun                             = false;
static uint Width                                   = 1024; 
static uint Height                                  = 1024; 
static float AspectRatio                            = (Width / (float)Height);
static uint FieldPages                              = 1;
static uint FieldInstances                          = 10;
static uint BladeCount                              = 128 * 128;
static uint MaxElementCount                         = 4; 
static uint MaxSegmentCount                         = 6;
static uint Iteration                               = 0;
static float Exposure                               = 1.0f;
static float SunAzimuth                             = 300.0f;
static float FalloffDistance                        = 200.0f;

static uint2 TerrainResolution                      = make_uint2(128, 128);
static uint TerrainVertexBufferId                   = 0;
static uint TerrainNormalBufferId                   = 0;
static uint TerrainTexCoordBufferId                 = 0;
static uint GrassVertexBufferId                     = 0;
static uint GrassColorBufferId                      = 0;
static uint ColorMode                               = 0;

static float2 ClipRange                             = make_float2(0.9f, 1.02f);
static float2 FieldSize                             = make_float2(1000.0f, 1000.0f);
static float2 BladeThicknessRange                   = make_float2(1.99f, 2.0f);
static float2 BladeLengthRange                      = make_float2(5.64f, 1.1f);
static float2 NoiseBias                             = make_float2(0.5f, 0.5f);
static float2 NoiseScale                            = make_float2(1.0f, 10.0f);

static float NoiseAmplitude                         = 0.25f;
static float FlowScale                              = 100.0f;
static float FlowSpeed                              = 100.0f;
static float FlowAmount                             = 30.0f;
static float BladeIntensity                         = 1.4f;
static float BladeOpacity                           = 0.2f;
static float JitterAmount                           = 2.0f;
static float RandomTable[256]                       = {0};

static float CameraFov                              = 70.0f;
static float CameraFarClip                          = FieldSize.x * 0.9f;
static float CameraNearClip                         = 0.1f;
static float3 CameraPosition                        = make_float3(100.0f, 20.0f, -200.0f);
static float3 CameraRotation                        = make_float3(0.0f, 20.0f, 0.0f);
const float CameraInertia                           = 0.1f;

static int ButtonState                              = 0;
static float2 MousePosition                         = make_float2(0.0f, 0.0f);
static float2 OldMousePosition                      = make_float2(0.0f, 0.0f);
static float3 Offset                                = make_float3(0.0f, 0.0f, 0.0f);

static double TimeElapsed                           = 0.0;
static uint ReportStatsInterval                     = 30;
static uint FrameCount                              = 0;

static uint ShowStats                               = 1;
static uint ShowInfo                                = 0;
static char StatsString[1024]                       = "\0";
static char InfoString[1024]                        = "\0";

//////////////////////////////////////////////////////////////////////////////

static Camera           MainCamera;
static ComputeEngine    Compute;
static TerrainSimulator TerrainSimulator;
static MeshRenderer     TerrainRenderer;
static GrassSimulator   GrassSimulator;
static MeshRenderer     GrassRenderer;
static Shader           SkyShader;

//////////////////////////////////////////////////////////////////////////////

static uint 
CreateBufferObject(
    uint target, 
    uint size, 
    uint usage = GL_DYNAMIC_DRAW,
    void* data = 0)
{
    printf("Creating Buffer Object (%d bytes)...\n", size);
    
    GLuint uid;
    glGenBuffers(1, &uid);
    glBindBuffer(target, uid);
    glBufferData(target, size, data, usage);
    glBindBuffer(target, 0);
    return (uint) uid;
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

	glViewport(iVP[0], iVP[1], iVP[2], iVP[3]);
}

static void 
ReportStats(
    uint64_t uiStartTime, uint64_t uiEndTime)
{
    TimeElapsed += SubtractTime(uiEndTime, uiStartTime);
    
	if(FrameCount > ReportStatsInterval) 
	{
        double dMilliseconds = TimeElapsed * 1000.0 / (double) FrameCount;
        float fFps = 1.0f / (dMilliseconds / 1000.0f);
        uint uiMaxVertexCount = GrassSimulator.getMaxVertexCount() * FieldInstances;
        sprintf(StatsString, "[%s] Vertices: %3.2f M  Blades: %d  Compute: %3.2f ms  Display: %3.2f fps (%s)\n", 
                (UseGPU) ? "GPU" : "CPU",
                uiMaxVertexCount / 1000.0f / 1000.0f, 
                BladeCount * FieldInstances * FieldPages,                 
                (float)dMilliseconds,
                fFps,
                USE_GL_ATTACHMENT ? ("attached") : ("copying") );
		
		glutSetWindowTitle(StatsString);

		FrameCount = 0;
        TimeElapsed = 0;
	}    

	if(ShowStats)
	{
		float afColor[4] = { 0.9f, 0.9f, 0.9f, 1.0f };
        DrawText(20, Height - 20, afColor, StatsString);	
	}
	
	if(ShowInfo)
	{
		float afColor[4] = { 0.9f, 0.9f, 0.9f, 1.0f };
		DrawText(Width - 20 - strlen(InfoString) * 10, Height - 20, afColor, InfoString);
		ShowInfo = (ShowInfo > 200) ? 0 : ShowInfo + 1;
        if(ShowInfo == 2) printf("%s", InfoString);
	}  
}

static void
Shutdown(void)
{
    Compute.disconnect();
    exit(0);
}

static void 
Update(void)
{
    MainCamera.update();
}

static void 
IncreaseSunAzimuth(float delta = 1.1f)
{
    if(SunAzimuth > 50000)
    {
        Exposure *= (1.0f / delta);
    }
    else
    {
        SunAzimuth *= delta;
        GrassSimulator.setBladeIntensity(GrassSimulator.getBladeIntensity() * (1.01f / delta));    
    }
}

static void 
DecreaseSunAzimuth(float delta = 1.1f)
{
    if(SunAzimuth > 50000 && Exposure < 1.0f)
        Exposure *= (delta);
    else
    {
        SunAzimuth *= (1.0f / delta);
        if(GrassSimulator.getBladeIntensity() < 1.0f)
            GrassSimulator.setBladeIntensity(GrassSimulator.getBladeIntensity() * (delta));
    }
}


static void 
Solve( bool bUseBlades )
{
    Iteration++;

    GrassSimulator.setCameraFov(MainCamera.getFovInDegrees());
    GrassSimulator.setCameraRotation(MainCamera.getRotation());
    GrassSimulator.setCameraPosition(MainCamera.getPosition());
    GrassSimulator.setCameraFrame(MainCamera.getUpDirection(), 
                                  MainCamera.getViewDirection(), 
                                  MainCamera.getLeftDirection());

    if(bUseBlades)
    {
        GrassSimulator.setClipRange(ClipRange);
        GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
        if(!GrassSimulator.computeGrassOnTerrain(Compute, Iteration))
        {
            Compute.disconnect();
            exit(1);
        }
    }
    else
    {
        GrassSimulator.setClipRange(ClipRange);
        GrassSimulator.setBladeThicknessRange(BladeThicknessRange * 0.85f);
        if(!GrassSimulator.computeGrassOnTerrain(Compute, Iteration))
        {
            Compute.disconnect();
            exit(1);
        }
        GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
    }
}

void RenderTerrain( void )
{
    TerrainSimulator.setCameraFov(MainCamera.getFovInDegrees());
    TerrainSimulator.setCameraPosition(MainCamera.getPosition());
    TerrainSimulator.setCameraRotation(MainCamera.getRotation());
    TerrainSimulator.setCameraFrame(MainCamera.getUpDirection(), 
                                    MainCamera.getViewDirection(), 
                                    MainCamera.getLeftDirection());

    TerrainSimulator.update(Compute, Iteration);
        
    glColor3f(0.9f * 0.10f * GrassSimulator.getBladeIntensity(), 
              0.9f * 0.15f * GrassSimulator.getBladeIntensity(), 
              0.00f * GrassSimulator.getBladeIntensity());

    glPushMatrix();
    if(Wireframe)
    {
        TerrainRenderer.render(GL_LINE_STRIP);
    }
    else
    {
        glEnable( GL_DEPTH_TEST );
        
        TerrainRenderer.render(GL_QUAD_STRIP, ColorMode);

        glDisable( GL_DEPTH_TEST );
    }
    glPopMatrix();
}

void RenderSky( void )
{
    static bool SunSet = true;
    if(AnimatedSun)
    {
        if(SunSet)
            IncreaseSunAzimuth(1.025f);
        else
            DecreaseSunAzimuth(1.025f);
    
        if(Exposure < 0.00001f)
        {
            SunSet = false;
        }
        else if(SunAzimuth < 100.0f)
        {
            SunSet = true;
        }
    }
    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    SkyShader.setUniform4f("CameraPosition", MainCamera.getPosition());
    SkyShader.setUniform4f("CameraDirection", MainCamera.getViewDirection());
    SkyShader.setUniform1f("Exposure", Exposure);
    SkyShader.setUniform1f("SunAzimuth", SunSet ? SunAzimuth : -SunAzimuth);
    SkyShader.enable();

    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    glBegin(GL_QUADS);
    glVertex4f(-1.0f, -1.0f, 1.0f, 1.0f);
    glVertex4f( 1.0f, -1.0f, 1.0f, 1.0f);
    glVertex4f( 1.0f,  1.0f, 1.0f, 1.0f);
    glVertex4f(-1.0f,  1.0f, 1.0f, 1.0f);
    glEnd();

    SkyShader.disable();    

    glPopMatrix();
}

void RenderGrass( void )
{
    GLenum ePrimitive = GL_QUADS;
    if(Wireframe)
        ePrimitive = GL_LINES;
        
    glDisable( GL_LIGHTING );
    glEnable( GL_DEPTH_TEST );

    glPushMatrix();
    {                
        float fScaleX = -20.0f;
        float fScaleY = -20.0f;
        for(uint p = 0; p < FieldPages; p++)
        {
            if(!Paused)
            {
                Solve(false);
                glPushMatrix();
                if(p > 0)
                    glTranslatef(fScaleX * RandomTable[p] , 0.0f, (fScaleY * RandomTable[p+1]));
                GrassRenderer.render(GL_LINES, true);
                glPopMatrix();
            }

            for(uint i = 1; i < FieldInstances; i++)
            {
                glPushMatrix();
                glTranslatef(fScaleX * RandomTable[i] , 0.0f, (fScaleY * RandomTable[i+1]));
                GrassRenderer.render(GL_LINES, true);
                glPopMatrix();
            }
        }
    }
    glPopMatrix();
    glDisable( GL_DEPTH_TEST );
}

void Display ( void )
{
    FrameCount++;
    uint64_t uiStartTime = GetCurrentTime();
    
    glClearColor(0.2f, 0.4f, 0.8f, 0.0f);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    Update();

    MainCamera.enable();
    RenderSky();
    RenderGrass();
    RenderTerrain();
    MainCamera.disable();
    
    glFinish(); // for timing

    uint64_t uiEndTime = GetCurrentTime();
    ReportStats(uiStartTime, uiEndTime);

    glutSwapBuffers(); 
}
    
void Reshape ( int w, int h )
{
    Width = w;
    Height = h;

    AspectRatio = (Width < Height) ? (Height / (float)Width) : (Width / (float)Height);

    MainCamera.setFovInDegrees(CameraFov);
    MainCamera.setAspect(AspectRatio);
    MainCamera.setViewport(Width, Height);

    glViewport(0, 0, Width, Height);    
}

void Motion(int x, int y)
{
    float dx = (float)x - (float)MousePosition.x;
    float dy = (float)y - (float)MousePosition.y;

    if (ButtonState == 3) 
    {
        MainCamera.forward(dy / 100.0f * 0.5f * fabs(MainCamera.getPosition().z));
    } 
    else if (ButtonState & 2) 
    {
        float3 fPos = MainCamera.getPosition();
        fPos.x += (dx / 100.0f);
        fPos.y -= (dy / 100.0f);
        MainCamera.setPosition(fPos);

    }
    else if (ButtonState & 1) 
    {
        MainCamera.yaw(-dx / 5.f);
    }

    MousePosition.x = (float)x;
    MousePosition.y = (float)y;

    glutPostRedisplay();
}

void Mouse ( int button, int state, int x, int y )
{
    int mods;

    OldMousePosition = MousePosition;
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

    MousePosition.x = (float)x;
    MousePosition.y = (float)y;
    
    glutPostRedisplay();
}

void Passive ( int x, int y )
{
    OldMousePosition = MousePosition;
    MousePosition.x = (float)x;
    MousePosition.y = (float)y;
}

void Keyboard ( unsigned char key, int x, int y )
{
    switch (key) 
    {
        case 'w':
            Wireframe = !Wireframe;
            sprintf(InfoString, "Wireframe = %s\n", Wireframe ? "true" : "false");
			ShowInfo = 1;
			break;

        case '/':
            GrassSimulator.setNoiseBias(GrassSimulator.getNoiseBias() * (1.1f));
            sprintf(InfoString, "NoiseBias = (%f, %f)\n", 
                    GrassSimulator.getNoiseBias().x, GrassSimulator.getNoiseBias().y);
			ShowInfo = 1;
			break;

		case '.':
            GrassSimulator.setNoiseBias(GrassSimulator.getNoiseBias() * (1.0f / 1.1f));
            sprintf(InfoString, "NoiseBias = (%f, %f)\n", 
                    GrassSimulator.getNoiseBias().x, GrassSimulator.getNoiseBias().y);
			ShowInfo = 1;
			break;

        case ',':
            GrassSimulator.setNoiseScale(GrassSimulator.getNoiseScale() * (1.1f));
            sprintf(InfoString, "NoiseScale = (%f, %f)\n", 
                    GrassSimulator.getNoiseScale().x, GrassSimulator.getNoiseScale().y);
			ShowInfo = 1;
			break;

		case 'm':
            GrassSimulator.setNoiseScale(GrassSimulator.getNoiseScale() * (1.0f / 1.1f));
            sprintf(InfoString, "NoiseScale = (%f, %f)\n", 
                    GrassSimulator.getNoiseScale().x, GrassSimulator.getNoiseScale().y);
			ShowInfo = 1;
			break;

        case 'n':
            GrassSimulator.setNoiseAmplitude(GrassSimulator.getNoiseAmplitude() * (1.1f));
            sprintf(InfoString, "NoiseAmplitude = %f\n", 
                    GrassSimulator.getNoiseAmplitude());
			ShowInfo = 1;
			break;

		case 'b':
            GrassSimulator.setNoiseAmplitude(GrassSimulator.getNoiseAmplitude() * (1.0f / 1.1f));
            sprintf(InfoString, "NoiseAmplitude = %f\n", 
                    GrassSimulator.getNoiseAmplitude());
			ShowInfo = 1;
			break;

		case '1':
            GrassSimulator.setFalloffDistance(GrassSimulator.getFalloffDistance() * (1.0f / 1.1f));
            sprintf(InfoString, "FalloffDistance = %f\n", 
                    GrassSimulator.getFalloffDistance());
			ShowInfo = 1;			
            break;
		
		case '2':
            GrassSimulator.setFalloffDistance(GrassSimulator.getFalloffDistance() * (1.1f));
            sprintf(InfoString, "FalloffDistance = %f\n", 
                    GrassSimulator.getFalloffDistance());
			ShowInfo = 1;			
            break;
           

		case '3':
            ClipRange.x *= (1.0f / 1.0001f);
            sprintf(InfoString, "ClipRange = (%f, %f)\n", ClipRange.x, ClipRange.y);
			ShowInfo = 1;			
            break;
		
		case '4':
            ClipRange.x *= (1.0001f);
            sprintf(InfoString, "ClipRange = (%f, %f)\n", ClipRange.x, ClipRange.y);
			ShowInfo = 1;			
            break;
            

		case '5':
            ClipRange.y *= (1.0f / 1.0001f);
            sprintf(InfoString, "ClipRange = (%f, %f)\n", ClipRange.x, ClipRange.y);
			ShowInfo = 1;			
            break;
		
		case '6':
            ClipRange.y *= (1.0001f);
            sprintf(InfoString, "ClipRange = (%f, %f)\n", ClipRange.x, ClipRange.y);
			ShowInfo = 1;			
            break;
            

		case '0':
            FieldPages = FieldPages < 5 ? FieldPages + 1 : FieldPages;
			sprintf(InfoString, "FieldPages = %d\n", FieldPages);
			ShowInfo = 1;
			break;
		
		case '9':
            FieldPages = FieldPages > 1 ? FieldPages - 1 : FieldPages;
			sprintf(InfoString, "FieldPages = %d\n", FieldPages);
			ShowInfo = 1;
			break;
        
		case '=':
            FieldInstances = FieldInstances < 25 ? FieldInstances + 1 : FieldInstances;
			sprintf(InfoString, "FieldInstances = %d\n", FieldInstances);
			ShowInfo = 1;
			break;
		
		case '-':
            FieldInstances = FieldInstances > 1 ? FieldInstances - 1 : FieldInstances;
			sprintf(InfoString, "FieldInstances = %d\n", FieldInstances);
			ShowInfo = 1;
			break;

		case '[':
		    AnimatedSun = false;
		    IncreaseSunAzimuth();
            sprintf(InfoString, "SunAzimuth = %f\n",SunAzimuth);
			ShowInfo = 1;
			break;
		
		case ']':
		    AnimatedSun = false;
            DecreaseSunAzimuth();
            sprintf(InfoString, "SunAzimuth = %f\n",SunAzimuth);
			ShowInfo = 1;
			break;

        case '\\':
            AnimatedSun = !AnimatedSun;
            break;
            
		case 'p':
            GrassSimulator.setBladeIntensity(GrassSimulator.getBladeIntensity() * (1.1f));
            sprintf(InfoString, "BladeIntensity = %f\n", GrassSimulator.getBladeIntensity());
			ShowInfo = 1;
			break;
		
		case 'o':
            GrassSimulator.setBladeIntensity(GrassSimulator.getBladeIntensity() * (1.0f / 1.1f));
            sprintf(InfoString, "BladeIntensity = %f\n", GrassSimulator.getBladeIntensity());
			ShowInfo = 1;
			break;

		case 'l':
            GrassSimulator.setFlowScale(GrassSimulator.getFlowScale() * (1.1f));
            sprintf(InfoString, "FlowScale = %f\n", GrassSimulator.getFlowScale());
			ShowInfo = 1;
			break;
		
		case 'k':
            GrassSimulator.setFlowScale(GrassSimulator.getFlowScale() * (1.0f / 1.1f));
            sprintf(InfoString, "FlowScale = %f\n", GrassSimulator.getFlowScale());
			ShowInfo = 1;
			break;
            
		case 'j':
            GrassSimulator.setFlowAmount(GrassSimulator.getFlowAmount() * (1.1f));
            sprintf(InfoString, "FlowAmount = %f\n", GrassSimulator.getFlowAmount());
			ShowInfo = 1;
			break;
		
		case 'h':
            GrassSimulator.setFlowAmount(GrassSimulator.getFlowAmount() * (1.0f / 1.1f));
            sprintf(InfoString, "FlowAmount = %f\n", GrassSimulator.getFlowAmount());
			ShowInfo = 1;
			break;

		case '\'':
            GrassSimulator.setFlowSpeed(GrassSimulator.getFlowSpeed() * (1.1f));
            sprintf(InfoString, "FlowSpeed = %f\n", GrassSimulator.getFlowSpeed());
			ShowInfo = 1;
			break;
		
		case ';':
            GrassSimulator.setFlowSpeed(GrassSimulator.getFlowSpeed() * (1.0f / 1.1f));
            sprintf(InfoString, "FlowSpeed = %f\n", GrassSimulator.getFlowSpeed());
			ShowInfo = 1;
			break;
            
		case 'x':
            BladeLengthRange = GrassSimulator.getBladeLengthRange();
		 	BladeLengthRange.x *= (1.1f);
            GrassSimulator.setBladeLengthRange(BladeLengthRange);
            sprintf(InfoString, "BladeLength = (%.2f, %.2f)\n", BladeLengthRange.x, BladeLengthRange.y);
			ShowInfo = 1;
			break;
		
		case 'z':
            BladeLengthRange = GrassSimulator.getBladeLengthRange();
		 	BladeLengthRange.x *= (1.0f / 1.1f);
            GrassSimulator.setBladeLengthRange(BladeLengthRange);
            sprintf(InfoString, "BladeLength = (%.2f, %.2f)\n", BladeLengthRange.x, BladeLengthRange.y);
			ShowInfo = 1;
			break;

		case 'v':
            BladeLengthRange = GrassSimulator.getBladeLengthRange();
		 	BladeLengthRange.y *= (1.1f);
            GrassSimulator.setBladeLengthRange(BladeLengthRange);
            sprintf(InfoString, "BladeLength = (%.2f, %.2f)\n", BladeLengthRange.x, BladeLengthRange.y);
			ShowInfo = 1;
			break;
		
		case 'c':
            BladeLengthRange = GrassSimulator.getBladeLengthRange();
		 	BladeLengthRange.y *= (1.0f / 1.1f);
            GrassSimulator.setBladeLengthRange(BladeLengthRange);
            sprintf(InfoString, "BladeLength = (%.2f, %.2f)\n", BladeLengthRange.x, BladeLengthRange.y);
			ShowInfo = 1;
			break;
            
		case 's':
            BladeThicknessRange = GrassSimulator.getBladeThicknessRange();
		 	BladeThicknessRange.x *= (1.1f);
            GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
            sprintf(InfoString, "BladeThickness = (%.2f, %.2f)\n", BladeThicknessRange.x, BladeThicknessRange.y);
			ShowInfo = 1;
			break;
		
		case 'a':
            BladeThicknessRange = GrassSimulator.getBladeThicknessRange();
		 	BladeThicknessRange.x *= (1.0f / 1.1f);
            GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
            sprintf(InfoString, "BladeThickness = (%.2f, %.2f)\n", BladeThicknessRange.x, BladeThicknessRange.y);
			ShowInfo = 1;
			break;

		case 'f':
            BladeThicknessRange = GrassSimulator.getBladeThicknessRange();
		 	BladeThicknessRange.y *= (1.1f);
            GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
            sprintf(InfoString, "BladeThickness = (%.2f, %.2f)\n", BladeThicknessRange.x, BladeThicknessRange.y);
			ShowInfo = 1;
			break;
		
		case 'd':
            BladeThicknessRange = GrassSimulator.getBladeThicknessRange();
		 	BladeThicknessRange.y *= (1.0f / 1.1f);
            GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
            sprintf(InfoString, "BladeThickness = (%.2f, %.2f)\n", BladeThicknessRange.x, BladeThicknessRange.y);
			ShowInfo = 1;
			break;

		case 'r':
		    if(GrassSimulator.getJitterAmount() < 5.0f)
    		 	GrassSimulator.setJitterAmount(GrassSimulator.getJitterAmount() * (1.1f));
            sprintf(InfoString, "Jitter = %.2f\n", GrassSimulator.getJitterAmount());
			ShowInfo = 1;
			break;
		
		case 'e':
		    if(GrassSimulator.getJitterAmount() > 0.0f)
    		 	GrassSimulator.setJitterAmount(GrassSimulator.getJitterAmount() * (1.0f / 1.1f));
            sprintf(InfoString, "Jitter = %.2f\n", GrassSimulator.getJitterAmount());
			ShowInfo = 1;
			break;
            
		case 'y':
		 	Exposure *= 1.1f;
            sprintf(InfoString, "Exposure = %.2f\n",Exposure);
			ShowInfo = 1;
			break;
		
		case 't':
		 	Exposure *= (1.0f / 1.1f);
            sprintf(InfoString, "Exposure = %.2f\n", Exposure);
			ShowInfo = 1;
			break;
            
        case ' ':
            Paused = !Paused;
            sprintf(InfoString, "Paused = %s\n", Paused ? "true" : "false");
			ShowInfo = 1;
			break;
            
        case 27:
        case 'q':
            Shutdown();
            exit(0);
            break;
            
    };
}

void Special ( int key, int x, int y )
{
    switch(key)
    {
        case GLUT_KEY_UP:
            MainCamera.forward(2.0f);
            break;
            
        case GLUT_KEY_DOWN:
            MainCamera.forward(-2.0f);
            break;

        case GLUT_KEY_LEFT:
            MainCamera.yaw(+1.0f);
            break;
            
        case GLUT_KEY_RIGHT:
            MainCamera.yaw(-1.0f);
            break;
            
        case GLUT_KEY_HOME:
            MainCamera.setZoom(MainCamera.getZoom() * 1.1f);
            break;

        case GLUT_KEY_END:
            MainCamera.setZoom(MainCamera.getZoom() * (1.0f / 1.1f));
            break;

    };
}

void Idle( void )
{
    glutPostRedisplay();
}

void Initialize( void )
{
    GLuint usage;
    bool copy = false;

    if(UseGPU)
        Compute.connect(ComputeEngine::DEVICE_TYPE_GPU, 1, true);
    else
        Compute.connect(ComputeEngine::DEVICE_TYPE_CPU);

    GrassSimulator.setMaxElementCount(MaxElementCount);
    GrassSimulator.setMaxSegmentCount(MaxSegmentCount);
    
#if USE_GL_ATTACHMENT

    usage = GL_STATIC_DRAW;
    copy = false;
    
#else

    usage = GL_DYNAMIC_DRAW;
    copy = true;

#endif    

    GrassVertexBufferId = CreateBufferObject(GL_ARRAY_BUFFER, GrassSimulator.getRequiredVertexBufferSize(BladeCount), usage );
    GrassColorBufferId = CreateBufferObject(GL_ARRAY_BUFFER, GrassSimulator.getRequiredColorBufferSize(BladeCount), usage );

    TerrainVertexBufferId = CreateBufferObject(GL_ARRAY_BUFFER, TerrainSimulator.getRequiredVertexBufferSize(TerrainResolution.x, TerrainResolution.y), usage );
    TerrainNormalBufferId = CreateBufferObject(GL_ARRAY_BUFFER, TerrainSimulator.getRequiredNormalBufferSize(TerrainResolution.x, TerrainResolution.y), usage );
    TerrainTexCoordBufferId = CreateBufferObject(GL_ARRAY_BUFFER, TerrainSimulator.getRequiredTexCoordBufferSize(TerrainResolution.x, TerrainResolution.y), usage );
    
    TerrainSimulator.setVertexBufferAttachment(TerrainVertexBufferId, copy);
    TerrainSimulator.setNormalBufferAttachment(TerrainNormalBufferId, copy);
    TerrainSimulator.setTexCoordBufferAttachment(TerrainTexCoordBufferId, copy);

    GrassSimulator.setVertexBufferAttachment(GrassVertexBufferId, copy);
    GrassSimulator.setColorBufferAttachment(GrassColorBufferId, copy);
    GrassSimulator.setHeightFieldBufferAttachment("terrain_vertices", TerrainVertexBufferId, TerrainNormalBufferId, TerrainResolution.x, TerrainResolution.y, copy);

    if(!GrassSimulator.setup(Compute, BladeCount, FieldSize.x, FieldSize.y))
        exit(1);

    if(!TerrainSimulator.setup(Compute, TerrainResolution.x, TerrainResolution.y))
        exit(1);
        
    if(!TerrainRenderer.createGridIndexBuffer(TerrainResolution.x, TerrainResolution.y))
        exit(1);
        
    for(uint i = 0; i < 256; i++)
        RandomTable[i] = (rand() / (float) RAND_MAX);

    MainCamera.setInertia(CameraInertia);
    MainCamera.setFovInDegrees(CameraFov);
    MainCamera.setAspect(AspectRatio);
    MainCamera.setNearClip(CameraNearClip);
    MainCamera.setFarClip(CameraFarClip);
    MainCamera.setPosition(CameraPosition);
    MainCamera.setViewport(Width, Height);
    MainCamera.pitch(CameraRotation.x);
    MainCamera.yaw(CameraRotation.y);
    MainCamera.update();
    
    GrassSimulator.setFalloffDistance(FalloffDistance);
    GrassSimulator.setCameraFov(MainCamera.getFovInDegrees());
    GrassSimulator.setCameraPosition(MainCamera.getPosition());
    GrassSimulator.setCameraRotation(MainCamera.getRotation());
    GrassSimulator.setCameraFrame(MainCamera.getUpDirection(), MainCamera.getViewDirection(), MainCamera.getLeftDirection());
    GrassSimulator.setBladeOpacity(BladeOpacity);
    GrassSimulator.setBladeIntensity(BladeIntensity);
    GrassSimulator.setBladeLengthRange(BladeLengthRange);
    GrassSimulator.setBladeThicknessRange(BladeThicknessRange);
    GrassSimulator.setNoiseBias(NoiseBias);
    GrassSimulator.setNoiseScale(NoiseScale);
    GrassSimulator.setNoiseAmplitude(NoiseAmplitude);
    GrassSimulator.setFlowScale(FlowScale);
    GrassSimulator.setFlowSpeed(FlowSpeed);
    GrassSimulator.setFlowAmount(FlowAmount);
    GrassSimulator.setJitterAmount(JitterAmount);
    
    GrassRenderer.setVertexBuffer(GrassVertexBufferId, GrassSimulator.getVertexComponentCount(), GrassSimulator.getMaxVertexCount());
    GrassRenderer.setColorBuffer(GrassColorBufferId, GrassSimulator.getColorComponentCount(), GrassSimulator.getMaxVertexCount());
    
    TerrainRenderer.setVertexBuffer(TerrainVertexBufferId, TerrainSimulator.getVertexComponentCount(), TerrainSimulator.getVertexCount());
    TerrainRenderer.setNormalBuffer(TerrainNormalBufferId, TerrainSimulator.getNormalComponentCount(), TerrainSimulator.getNormalCount());
    TerrainRenderer.setColorBuffer(TerrainNormalBufferId, TerrainSimulator.getNormalComponentCount(), TerrainSimulator.getNormalCount());
    
    SkyShader.loadAndCompile("sky.vert", "sky.frag");
}

int main ( int argc, char** argv )
{
    glutInit( &argc, argv ); 
    glutInitDisplayString( "rgba depth double samples>=16");
	glutInitWindowSize(Width, Height);
    glutInitWindowPosition (0, 10);
    glutCreateWindow( "OpenCL Grass GrassSimulator" ); 

	Initialize();
	
    glEnable(GL_MULTISAMPLE); 
    glutDisplayFunc( Display ); 
    glutIdleFunc( Display ); 
    glutReshapeFunc( Reshape ); 
    glutMouseFunc( Mouse ); 
    glutMotionFunc( Motion ); 
    glutPassiveMotionFunc( Passive ); 
    glutKeyboardFunc( Keyboard );
    glutSpecialFunc( Special ); 
    
    atexit(Shutdown);

    glutMainLoop( );

    return 0; 
}
