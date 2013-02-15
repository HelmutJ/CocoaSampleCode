//
// File:       nbody.cpp
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
#include <cmath>

#include <OpenGL/OpenGL.h>
#include <OpenGL/glu.h>

#include "graphics.h"
#include "hud.h"
#include "nbody.h"
#include "simulation.h"
#include "timing.h"
#include "counter.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

static Button *GraphicsButton                   = NULL;
static Button *SimulationButton                 = NULL;
static Button *ActiveButton                     = NULL;
TrackingState tracking = NOTHING;

////////////////////////////////////////////////////////////////////////////////////////////////////

bool GraphicsIntegrated                         = false;
bool SimulatorIntegrated                        = false;
GLuint ButtonBackgroundTexture                  = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////

static unsigned int RendererIndex               = 0;
static unsigned int RendererCount               = 0;

static unsigned int SimulatorIndex              = 0;
static unsigned int SimulatorCount              = 0;
static Simulation *ScalarSingleCoreSimulator    = NULL;
static Simulation *VectorSingleCoreSimulator    = NULL;
static Simulation *VectorMultiCoreSimulator     = NULL;
static Simulation *PrimaryGpuSimulator          = NULL;
static Simulation *SecondaryGpuSimulator        = NULL;
static Simulation *ActiveSimulator              = NULL;
static unsigned int NBodyCount                  = CCN_NUM_BODIES;

////////////////////////////////////////////////////////////////////////////////////////////////////

static float RotationSpeed                      = 0.0f;
static bool FirstPrimaryGpuFrame                = true;
static bool FirstSecondaryGpuFrame              = true;
static bool FirstFrame                          = true;
static bool WaitingForData                      = true;
static bool ShowTurbo                           = false;
static bool ShowUpdatesMeter                    = false;
static bool ShowFpsMeter                        = false;
static bool ShowHud                             = true;
static bool ShowDock                            = true;
static bool ShowGFlopsMeter                     = true;
static bool ShowYear                            = false;
static bool ShowEarthView                       = false;

////////////////////////////////////////////////////////////////////////////////////////////////////

static bool PauseSimulation                     = false;
static bool Resetting                           = false;
static bool HandleClick                         = false;
static bool Rotating                            = false;
static bool Rotate                              = false;
static float ResetViewTime                      = 0.0f;
static float ViewAnimateZoomStart               = 0.0f;
static float ViewAnimateRotXStart               = 0.0f;
static float ViewAnimateRotYStart               = 0.0f;
static float RotateX                            = 0.0f;
static float RotateY                            = 0.0f;
static GLuint PointSize                         = 0;
static double ViewDistance                      = 30.0;
static float StarSize                           = 0.0f;
static float HudPosition                        = 0.0f;
static float DockVerticalPosition               = 0.0f;
static float DockHorizontalPosition             = 0.0f;
static float HorizontalTile                     = 0.0f;
static float ClearColor                         = 0.0f;
static int WindowWidth                          = 0;
static int WindowHeight                         = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////

Counter                                         YearCounter("million years in the future");
SmoothMeter                                     GFlopsMeter(METER_SIZE, METER_SIZE, 256, "Gigaflops");
SmoothMeter                                     UpdatesMeter(METER_SIZE, METER_SIZE, 40, "Updates/sec");
StuffPerSecondMeter                             FpsCounter(20, false);
SmoothMeter                                     FpsMeter(METER_SIZE, METER_SIZE, 80, "Frames/sec");

////////////////////////////////////////////////////////////////////////////////////////////////////

struct RendererButton
{
    GLint renderer;
    char name[1024];
    GLuint label;
};
static RendererButton RendererButtons[32];

////////////////////////////////////////////////////////////////////////////////////////////////////

struct SimulatorButton
{
    Simulation* simulator;
    char name[1024];
    GLuint label;
};
static SimulatorButton SimulatorButtons[32];

////////////////////////////////////////////////////////////////////////////////////////////////////

static const NBodyParams DemoParams[] =
{
    // timestep, cluster_scale, velScale, softening, damping
    // pointSizeScale, rotX, rotY, viewDistance, config

    { CCN_TIME_SCALE * 0.25f,    1.0f,     1.0f,     0.025f,   1.0f,
        0.7f, 66, 137,    30.0f,  NBODY_CONFIG_MWM31 },

    { CCN_TIME_SCALE * 0.016f,   1.54f,    8.0f,     CCN_SOFTENING_SCALE * 0.1f,     1.0f,
      1.0f,   0,    0,  30.0f,  NBODY_CONFIG_SHELL },

    { CCN_TIME_SCALE * 0.0019f,  0.32f,    276.0f,   CCN_SOFTENING_SCALE * 1.0f,     1.0f,
      0.18f,  90,   0,  9.0f,   NBODY_CONFIG_SHELL },

    { CCN_TIME_SCALE * 0.016f,   0.68f,    20.0f,    CCN_SOFTENING_SCALE * 0.1f,     1.0f,
      1.2f,   39,   2, 50.0f,  NBODY_CONFIG_SHELL },

    { CCN_TIME_SCALE * 0.0006f,  0.16f,    1000.0f,  CCN_SOFTENING_SCALE * 1.0f,     1.0f,
      0.15f,  -83,  10, 5.0f,   NBODY_CONFIG_SHELL },

    { CCN_TIME_SCALE * 0.0016f,  0.32f,    272.0f,   CCN_SOFTENING_SCALE * 0.145f,   1.0f,
      0.1f,   0,    0,  4.15f,  NBODY_CONFIG_SHELL },

    { CCN_TIME_SCALE * 0.016000, 6.040000, 0.000000, CCN_SOFTENING_SCALE * 1.000000, 1.000000,
      1.0f,   0,    0,  50.0f,  NBODY_CONFIG_SHELL },
};

const static int DemoParamsCount = sizeof(DemoParams) / sizeof(NBodyParams);
static int ActiveDemo;
static NBodyParams    ActiveParams;

////////////////////////////////////////////////////////////////////////////////////////////////////

static GLuint    VertexBufferIds[2];
static GLuint    ColorBufferId;
static GLuint    tex, tex2;
static GLuint    GalaxiesShader;

void *HostPositionData = NULL;
void *HostColorData = NULL;

unsigned int InputVertexBufferId  = 0;
unsigned int OutputVertexBufferId = 1;


////////////////////////////////////////////////////////////////////////////////////////////////////

void SetParticleCount(int n)
{
    // Override default count
    NBodyCount = n;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void DestroyAllSimulators(void);
void SelectSimulator(unsigned int index);

void RepositionCounter(void)
{
    YearCounter.setX( (WindowWidth - COUNTER_WIDTH) / 2.0 );
    YearCounter.setY( WindowHeight - COUNTER_HEIGHT - 25 ); 
    YearCounter.setW( COUNTER_WIDTH );
    YearCounter.setH( COUNTER_HEIGHT );
}

void MakeButtons(void)
{
    ActiveButton = NULL;
    tracking = NOTHING;
    
    if(GraphicsButton)
        delete GraphicsButton;
    
    if(SimulationButton)
        delete SimulationButton;

    GraphicsButton = new Button(
        0.25 * WindowWidth - 0.5 * BUTTON_WIDTH,
        BUTTON_SPACING,
        BUTTON_WIDTH,
        BUTTON_HEIGHT);

    SimulationButton = new Button(
        0.75 * WindowWidth - 0.5 * BUTTON_WIDTH,
        BUTTON_SPACING,
        BUTTON_WIDTH,
        BUTTON_HEIGHT);
}

void ResizeCallback(int x, int y)
{
    WindowWidth = x;
    WindowHeight = y;

    MakeButtons();
    RepositionCounter();
}

void PauseAllSimulators(void)
{
    unsigned int i;
    for(i = 0; i < SimulatorCount; i++)
        SimulatorButtons[i].simulator->pause();
}

void StopAllSimulators(void)
{
    unsigned int i;
    for(i = 0; i < SimulatorCount; i++)
        SimulatorButtons[i].simulator->stop();
}

void ResetDemo(void)
{
    if(!ActiveSimulator)
        return;
        
    if (PauseSimulation)
    {
        ActiveSimulator->unpause();
        PauseSimulation = 0;
    }

    PauseAllSimulators();

    if(HostPositionData)
    {
        free(HostPositionData);
        HostPositionData = NULL;
        free(ActiveSimulator->takeData());
    }
    
    ActiveSimulator->reset(ActiveParams);
    
    if (ActiveSimulator == PrimaryGpuSimulator && SecondaryGpuSimulator)
    {
        PrimaryGpuSimulator->setUpdateExternalData(true);
        SecondaryGpuSimulator->setUpdateExternalData(false);
    }
    else if (ActiveSimulator == SecondaryGpuSimulator && PrimaryGpuSimulator)
    {
        PrimaryGpuSimulator->setUpdateExternalData(false);
        SecondaryGpuSimulator->setUpdateExternalData(true);
    }
    else if (ActiveSimulator == PrimaryGpuSimulator)
    {
        PrimaryGpuSimulator->setUpdateExternalData(true);
    }

    ActiveSimulator->unpause();
}

static void ResetView(void)
{
    ViewDistance = DemoParams[ActiveDemo].m_viewDistance;
    RotateX       = DemoParams[ActiveDemo].m_rotate_x;
    RotateY       = DemoParams[ActiveDemo].m_rotate_y;
}

static void SelectDemo(int index)
{
    Rotate = 0;
    RotationSpeed = 0.0f;
    ActiveParams = DemoParams[index];
    ResetDemo();
    ResetView();
}

void SetSimulatorDescription(
    unsigned int index, 
    const char* name,
    Simulation* simulator)
{
    sprintf(SimulatorButtons[index].name, "SIM: %s", (const char*)name);
    SimulatorButtons[index].label = CreateButtonLabel(SimulatorButtons[index].name);        
    SimulatorButtons[index].simulator = simulator;
}

void SelectSimulator(unsigned int index)
{
    if(index >= SimulatorCount)
        index = 0;

    FirstSecondaryGpuFrame = true;
    FirstPrimaryGpuFrame = true;
    FirstFrame = true;

    ActiveSimulator = SimulatorButtons[index].simulator;
    SimulatorIndex = index;

    if (!ActiveSimulator->isInitialized())
        ActiveSimulator->start(true);

    if(ActiveSimulator == PrimaryGpuSimulator || ActiveSimulator == SecondaryGpuSimulator)
        SetSimulatorDescription(SimulatorIndex, ActiveSimulator->getDeviceName(), ActiveSimulator);
        
    printf("Using %s simulator w/ %d bodies...\n", SimulatorButtons[index].name, NBodyCount);
}

void SelectRenderer(unsigned int index)
{
    if(index >= RendererCount)
        index = 0;
        
    GLint sync = 1;
    CGLContextObj ctx = CGLGetCurrentContext();
    CGLSetVirtualScreen(ctx, RendererButtons[index].renderer);
    CGLSetParameter(ctx, kCGLCPSwapInterval, &sync);

    RendererIndex = index;
    
    printf("Using %s renderer...\n", RendererButtons[index].name);
}

void SwapGraphicsDevices(void)
{
    ClearColor = 1.0f;
    DisplayCallback();
    glFinish();

    SelectRenderer(RendererIndex + 1);
    WaitingForData = true;
    ResetView();
}

void SwapSimulationDevices(void)
{
    ClearColor = 1.0f;
    DisplayCallback();
    glFinish();

    PauseAllSimulators();
    WaitingForData = true;
    SelectSimulator(SimulatorIndex + 1);
    ResetView();
    ResetDemo();
}

void DrawStars(void)
{
    const float rotAccel = 0.06f;

    if (RotateX > 180 || RotateY > 180)
    {
        while (RotateX > 180)
            RotateX -= 360;
        while (RotateY > 180)
            RotateY -= 360;
    }
    if (RotateX < -180 || RotateY < -180)
    {
        while (RotateX < -180)
            RotateX += 360;
        while (RotateY < -180)
            RotateY += 360;
    }

    if (Rotate)
    {
        // (cos(0 to pi) + 1) * 0.5f
        RotationSpeed += rotAccel;
        if (RotationSpeed > M_PI)
            RotationSpeed = M_PI;
    }
    else
    {
        RotationSpeed -= rotAccel;
        if (RotationSpeed < 0.0f)
            RotationSpeed = 0.0f;
    }

    if (Resetting)
    {
        ResetViewTime += 0.02;
        if (ResetViewTime >= M_PI*0.5f)
        {
            RotationSpeed = 0.0f;
            ResetView();
            Resetting = false;
        }
        else
        {
            const float t = sinf(ResetViewTime);
            const float T = 1.0f - t;
            ViewDistance =
                t * DemoParams[ActiveDemo].m_viewDistance +
                T * ViewAnimateZoomStart;
            RotateX =
                t * DemoParams[ActiveDemo].m_rotate_x +
                T * ViewAnimateRotXStart;
            RotateY =
                t * DemoParams[ActiveDemo].m_rotate_y +
                T * ViewAnimateRotYStart;
        }
    }

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(60, (float)WindowWidth / (float)WindowHeight, 0.1, 10000);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    if (ActiveDemo == 0 && ShowEarthView)
    {
        float *pE = (float*)((long)HostPositionData + 4 * 4 * 217);
        gluLookAt(pE[0], pE[1], pE[2], 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    }
    else
    {
        gluLookAt(-ViewDistance, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    }
    
    glViewport(0, 0, WindowWidth, WindowHeight);

    glBlendFunc(GL_ONE, GL_ONE);
    glEnable(GL_BLEND);

    glUseProgram(GalaxiesShader);

    glActiveTextureARB(GL_TEXTURE0_ARB);

    glBindBufferARB(GL_ARRAY_BUFFER_ARB, VertexBufferIds[OutputVertexBufferId]);
    glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, NBodyCount * 4 * sizeof(float), HostPositionData);
    glVertexPointer(4, GL_FLOAT, 0, 0);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

    glPushMatrix();

    if (!Resetting)
    {
        const float rotFactor = 1.0f - (1.0f + cosf(RotationSpeed)) * 0.5f;
        RotateX += 1.6f * CCN_TIME_SCALE * rotFactor;
        RotateY += 0.8f * CCN_TIME_SCALE * rotFactor;
    }

    if (ActiveDemo != 0 || !ShowEarthView)
    {
        glRotatef(RotateY, 1, 0, 0);
        glRotatef(RotateX, 0, 1, 0);
    }

    glUniform1f(PointSize, StarSize * (float)DemoParams[ActiveDemo].m_point_size);

    glBindTexture(GL_TEXTURE_2D, tex);

    if (ActiveDemo == 0)
    {
        static int init = 0;
        {
            glBindBufferARB(GL_ARRAY_BUFFER_ARB, ColorBufferId);
            // This should only be done once -- colors don't change
            glBufferSubData(GL_ARRAY_BUFFER_ARB, 0, NBodyCount * 4 * sizeof(float), HostColorData);
            glColorPointer(4, GL_FLOAT, 0, 0);
            glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
            init = 1;
        }
        glEnableClientState(GL_COLOR_ARRAY);

        glDrawArrays(GL_POINTS, 0, NBodyCount);
    }
    else
    {
        // white stars
        glColor3f(0.8, 0.8, 0.8);
        glDrawArrays(GL_POINTS, 0, NBodyCount / 4*2);

        // blue stars
        //glColor3f(0.7, 0.8, 1.0);
        glColor3f(0.4, 0.6, 1.0);
        glDrawArrays(GL_POINTS, NBodyCount / 4*2, NBodyCount / 4*1);

        // red stars
        //glColor3f(1.0, 0.9, 0.9);
        glColor3f(1.0, 0.6, 0.6);
        glDrawArrays(GL_POINTS, NBodyCount / 4*3, NBodyCount / 4*1);
    }

    glDisableClientState(GL_COLOR_ARRAY);

    if (ActiveDemo == 0)
    {
#if (NBodyCount == 16384)
        glUniform1f(PointSize, 32.0f);
        glColor3f(0.2f, 0.3f, 1.0f);
        glDrawArrays(GL_POINTS, 217, 1);
#endif
    }

    glBindTexture(GL_TEXTURE_2D, tex2);

    if (ActiveDemo != 0)
    {
        glUniform1f(PointSize, 300.f * (float)DemoParams[ActiveDemo].m_point_size);
        // purple clouds
        glColor3f(0.032f, 0.01f, 0.026f);
        glDrawArrays(GL_POINTS, 0, 64);

        // blue clouds
        glColor3f(0.018f, 0.01f, 0.032f);
        glDrawArrays(GL_POINTS, 64, 64);
    }
    else
    {
        unsigned int i, step;
        glUniform1f(PointSize, 300.f);
        step = NBodyCount / 24;

        // pink 
        glColor3f(0.04f, 0.015f, 0.025f);
        for ( i = 0; i < NBodyCount / 12*7; i += step )
        {
            glDrawArrays( GL_POINTS, i, 1 );
        }

        // blue
        glColor3f(0.04f, 0.001f, 0.08f);
        for ( i = 64; i < NBodyCount / 12*7; i += step )
        {
            glDrawArrays( GL_POINTS, i, 1 );
        }
    }

    glPopMatrix();

    glColor3f(1, 1, 1);

    glUseProgram(0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

void InitDefaults(
    int _initDemo, 
    float _starScale, 
    bool _ShowHud, 
    bool _showUpdates, 
    bool _showFramerate, 
    bool _showGigaflops, 
    bool _ShowDock)
{
    ActiveDemo = _initDemo;
    ActiveParams = DemoParams[ActiveDemo];

    StarSize = 4.0f * _starScale;

    ShowUpdatesMeter = _showUpdates;
    ShowFpsMeter     = _showFramerate;
    ShowGFlopsMeter  = _showGigaflops;
    ShowHud = _ShowHud;
    HudPosition  = _ShowHud ? M_PI * 0.5f : 0.0f;

    ShowDock = _ShowDock;
    DockVerticalPosition  = _ShowDock ? M_PI * 0.5f : 0.0f;
}

void DrawHeadsUpDisplay(void)
{
    static uint64_t lastFrameTime = 0;
    if (lastFrameTime == 0)
    {
        lastFrameTime = mach_absolute_time();
    }
    else
    {
        uint64_t now = mach_absolute_time();
        double dt = SubtractTime(now, lastFrameTime);
        lastFrameTime = now;

        FpsCounter.recordFrame(1, dt);
        FpsMeter.setTargetValue(FpsCounter.stuffPerSecond());
        FpsMeter.update();
    }

    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0.0, WindowWidth, 0.0, WindowHeight);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    GFlopsMeter.setTargetValue(ActiveSimulator->getGigaFlops());
    GFlopsMeter.update();

    UpdatesMeter.setTargetValue(ActiveSimulator->getUpdatesPerSecond());
    UpdatesMeter.update();

    const float hudSpeed = 0.06f;

    if (FirstPrimaryGpuFrame && ActiveSimulator == PrimaryGpuSimulator)
    {
        FirstPrimaryGpuFrame = false;
        FirstFrame = false;
    }

    if (FirstSecondaryGpuFrame && ActiveSimulator == SecondaryGpuSimulator)
    {
        FirstSecondaryGpuFrame = false;
        FirstFrame = false;
    }

    if (ShowHud)
    {
        if (HudPosition <= (M_PI * 0.5f) - hudSpeed)
            HudPosition += hudSpeed;
    }
    else if (HudPosition > 0.0f)
    {
        HudPosition -= hudSpeed;
    }

    glPushMatrix();
    glTranslatef(0.0f, 416.0f - sinf(HudPosition) * 416.0f, 0.0f);

    if (ShowFpsMeter)
    {
        DrawMeter(
            208.0,
            WindowHeight - 160.0,
            FpsMeter);
    }
   
    if (ShowUpdatesMeter)
    {
        DrawMeter(
            0.5 * WindowWidth,
            WindowHeight - 160.0,
            UpdatesMeter);
    }

    if (ShowGFlopsMeter)
    {
        DrawMeter(
            WindowWidth - 208.0,
            WindowHeight - 160.0,
            GFlopsMeter);
    }

    glPopMatrix();

    if (ShowYear)
    {
        YearCounter.setCounter(lrint(ActiveSimulator->getYear() / (1.0e6)));
        YearCounter.draw();
    }

    const float dockVSpeed = 0.06f;

    if (ShowDock)
    {
        if (DockVerticalPosition <= (M_PI * 0.5f) - dockVSpeed)
            DockVerticalPosition += dockVSpeed;
    }
    else if (DockVerticalPosition > 0.0f)
    {
        DockVerticalPosition -= dockVSpeed;
    }

    glPushMatrix();
    glTranslatef(sinf(DockHorizontalPosition) * -BUTTON_WIDTH,
                 sinf(DockVerticalPosition) * 100.0f - 100.0f, 0.0f);

    glEnable(GL_TEXTURE_2D);

    DrawButton(
        GraphicsButton,
        RendererButtons[RendererIndex].label,
        ButtonBackgroundTexture,
        false);

    DrawButton(
        SimulationButton,
        SimulatorButtons[SimulatorIndex].label,
        ButtonBackgroundTexture,
        true);

    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);

    glPopMatrix();
}

void DisplayCallback(void)
{
    void *newData = ActiveSimulator->takeData();
    if (newData != NULL)
    {
        free(HostPositionData);
        HostPositionData = newData;
    }

    glClearColor(ClearColor, ClearColor, ClearColor, 1.0f);
    if (ClearColor > 0.0f)
        ClearColor -= 0.05f;

    glClear(GL_COLOR_BUFFER_BIT);
    if (HostPositionData == NULL)
    {
        if (WaitingForData)
        {
            CGLFlushDrawable(CGLGetCurrentContext());
        }
        return;
    }
    WaitingForData = false;
    HostColorData = ActiveSimulator->getColorData();

    glClear(GL_COLOR_BUFFER_BIT);

    DrawStars();
    DrawHeadsUpDisplay();

    CGLFlushDrawable(CGLGetCurrentContext());
}

void FindRenderers(void)
{
    GLint i = 0;
    GLint count = 0;
    GLint current = 0;
    
    CGLContextObj ctx = CGLGetCurrentContext();
    CGLGetVirtualScreen(ctx, &current);
    
    while( CGLSetVirtualScreen(ctx, i) == kCGLNoError )
    {
        sprintf(RendererButtons[i].name, "GFX: %s", (const char*)glGetString(GL_RENDERER));
        RendererButtons[i].label = CreateButtonLabel(RendererButtons[i].name);        
        RendererButtons[i].renderer = i;
        count++;
        i++;
    }
    
    RendererIndex = current;
    RendererCount = count;
    
    GLint sync = 1;
    CGLFlushDrawable(ctx);
    CGLSetVirtualScreen(ctx, current);
    CGLSetParameter(ctx, kCGLCPSwapInterval, &sync);
}

void InitGraphics(void)
{
    FindRenderers();
    
    
    WindowWidth = GetMainDisplayWidth();
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

#define VBO_USAGE GL_DYNAMIC_DRAW_ARB
// #define VBO_USAGE GL_STATIC_DRAW_ARB

    glEnableClientState(GL_VERTEX_ARRAY);

    glGenBuffers(1, &VertexBufferIds[0]);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, VertexBufferIds[0]);
    glBufferData(GL_ARRAY_BUFFER_ARB, NBodyCount * 4 * sizeof(float), NULL, VBO_USAGE);
    glVertexPointer(4, GL_FLOAT, 0, 0);
    glBindBuffer( GL_ARRAY_BUFFER_ARB, 0);

    glGenBuffers(1, &VertexBufferIds[1]);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, VertexBufferIds[1]);
    glBufferData(GL_ARRAY_BUFFER_ARB, NBodyCount * 4 * sizeof(float), NULL, VBO_USAGE);
    glVertexPointer(4, GL_FLOAT, 0, 0);
    glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);

    glGenBuffers(1, &ColorBufferId);
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, ColorBufferId);
    glBufferData(GL_ARRAY_BUFFER_ARB, NBodyCount * 4 * sizeof(float), NULL, VBO_USAGE);
    glColorPointer(4, GL_FLOAT, 0, 0);
    glBindBuffer( GL_ARRAY_BUFFER_ARB, 0 );

    tex = LoadTexture("star.png", GL_TEXTURE_2D, true);

    {
        const int texRes = 32;
        unsigned char* texData = CreateGaussianMap(texRes);
        glGenTextures(1, &tex2);
        glBindTexture(GL_TEXTURE_2D, tex2);
        glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE8, texRes, texRes, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, texData);
        delete texData;
    }

    glGenTextures(1, &ButtonBackgroundTexture);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, ButtonBackgroundTexture);
    InitButton(BUTTON_WIDTH, BUTTON_HEIGHT);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

    glBindTexture(GL_TEXTURE_2D, 0);

    GalaxiesShader = LoadShader("nbody.vsh", "nbody.gsh", "nbody.fsh", GL_POINTS, GL_TRIANGLE_STRIP, 4);

    glUseProgram(GalaxiesShader);
    GLuint texLoc = glGetUniformLocation(GalaxiesShader, "splatTexture");
    glUniform1i(texLoc, 0);

    PointSize = glGetUniformLocation(GalaxiesShader, "pointSize");

    glUseProgram(0);

    const GLint sync = 1;
    CGLSetParameter(CGLGetCurrentContext(), kCGLCPSwapInterval, &sync);
}

void KeyboardCallback(unsigned char key, int x, int y)
{
    switch (key)
    {
    case ' ':
    {
        PauseSimulation = !PauseSimulation;
        if (PauseSimulation)
            ActiveSimulator->pause();
        else
            ActiveSimulator->unpause();
        break;
    }
    case 'r':
        Rotate = !Rotate;
        break;
    case 'e':
        ShowEarthView = !ShowEarthView;
        break;
    case 't':
        ShowTurbo = !ShowTurbo;
        break;
    case 'R':
        ViewAnimateZoomStart = ViewDistance;
        ViewAnimateRotXStart = RotateX;
        ViewAnimateRotYStart = RotateY;
        Resetting = true;
        ResetViewTime = 0.0f;
        Rotate = false;
        break;
    case 'n':
        ActiveDemo = (ActiveDemo + 1) % DemoParamsCount;
        SelectDemo(ActiveDemo);
        ResetView();
        break;
    case '0': // galaxy
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    {
        int demo = (key - '0');
        if (demo < DemoParamsCount)
        {
            ShowYear = (demo == 0);
            ActiveDemo = demo;
            SelectDemo(ActiveDemo);
            ResetView();
        }
        break;
    }
    case 'h':
        ShowHud = !ShowHud;
        break;
    case 'd':
        ShowDock = !ShowDock;
        break;
    case 'u':
        ShowUpdatesMeter = !ShowUpdatesMeter;
        break;
    case 'f':
        ShowFpsMeter = !ShowFpsMeter;
        break;
    case 's':
        SwapSimulationDevices();
        break;
    case 'g':
        SwapGraphicsDevices();
        break;
    }
}

void MouseMovementCallback(int x, int y)
{
    if (Rotating)
    {
        static int oldX, oldY;
        if (HandleClick)
        {
            oldX = x;
            oldY = y;
            HandleClick = false;
        }

        RotateX += (x - oldX) * 0.2f;
        RotateY += (y - oldY) * 0.2f;
        oldX = x;
        oldY = y;
    }
}

void EnableDock(bool show)
{
    ShowDock = show;
}

void MouseClickCallback(int button, int state, int x, int y)
{
    float gly = WindowHeight - y;
    float glx = x;

    if ((state == MOUSE_DOWN) &&
            (gly <= 2*BUTTON_HEIGHT) &&
            (glx >= 0.25 * WindowWidth - 0.5 * BUTTON_WIDTH) &&
            (glx <= 0.25 * WindowWidth + 0.5 * BUTTON_WIDTH))
    {
        ActiveButton = GraphicsButton;
        SwapGraphicsDevices();
    }

    if ((state == MOUSE_DOWN) &&
            (gly <= 2*BUTTON_HEIGHT) &&
            (glx >= 0.75 * WindowWidth - 0.5 * BUTTON_WIDTH) &&
            (glx <= 0.75 * WindowWidth + 0.5 * BUTTON_WIDTH))
    {
        ActiveButton = SimulationButton;
        SwapSimulationDevices();
    }
}

void ScrollCallback(float delta)
{
    ViewDistance = ViewDistance + delta * SCROLL_ZOOM_SPEED;
    if (ViewDistance < 1.0)
    {
        ViewDistance = 1.0;
    }
}

unsigned int GetComputeDeviceCount(int type)
{
    static const unsigned int MAX_DEVICE_COUNT = 128;
    
    cl_device_id ids[MAX_DEVICE_COUNT] = {0};
    unsigned int count = 0;
    
    int err = clGetDeviceIDs(NULL, type, MAX_DEVICE_COUNT, ids, &count);
    if (err != CL_SUCCESS)
        return -1;

    return count;
}

void DestroyGpuSimulators(void)
{
    if(PrimaryGpuSimulator)
        delete PrimaryGpuSimulator;
    
    if(SecondaryGpuSimulator)
        delete SecondaryGpuSimulator;
}

void CreateGpuSimulators(void)
{
    unsigned int i = 0;
    unsigned int spin = 0;
    
    int gpus = GetComputeDeviceCount(CL_DEVICE_TYPE_GPU);
    if(gpus > 0)
    {
        PrimaryGpuSimulator = new GPUSimulation(NBodyCount, ActiveParams, 1, 0);
        PrimaryGpuSimulator->start(true);
    }

    if(gpus > 1)
    {    
        SecondaryGpuSimulator = new GPUSimulation(NBodyCount, ActiveParams, 1, 1);
        SecondaryGpuSimulator->start(true);
    }
    
    if(PrimaryGpuSimulator)
    {
        while(!PrimaryGpuSimulator->isInitialized())
            spin++;

        SetSimulatorDescription(SimulatorCount, PrimaryGpuSimulator->getDeviceName(), PrimaryGpuSimulator);
        SimulatorCount += 1;
    
    }
    
    if(SecondaryGpuSimulator)
    {
        while(!SecondaryGpuSimulator->isInitialized())
            spin++;
    
        SetSimulatorDescription(SimulatorCount, SecondaryGpuSimulator->getDeviceName(), SecondaryGpuSimulator);
        SimulatorCount += 1;
    }

    for(i = 0; i < INTEGRATED_GPU_DEVICE_NAME_COUNT; i++)
    {
        if(PrimaryGpuSimulator && !SecondaryGpuSimulator)
        {
            if(strstr(PrimaryGpuSimulator->getDeviceName(), INTEGRATED_GPU_DEVICE_NAMES[i]) != 0)
            {
                NBodyCount /= 2;
                break;
            }
        }
        i++;
    }
}

void DestroyCpuSimulators(void)
{
    if(ScalarSingleCoreSimulator)
        delete ScalarSingleCoreSimulator;

    if(VectorSingleCoreSimulator)
        delete VectorSingleCoreSimulator;

    if(VectorMultiCoreSimulator)
        delete VectorMultiCoreSimulator;
}

void CreateCpuSimulators(void)
{
    DestroyCpuSimulators();
    
    int cpus = GetComputeDeviceCount(CL_DEVICE_TYPE_CPU);

    if(cpus)
    {
        // Scalar CPU Simulation is disabled since it is too slow for the default particle counts
        // ScalarSingleCoreSimulator = new CPUSimulation(NBodyCount, ActiveParams, false, false);
        // ScalarSingleCoreSimulator->start(true);
        // SetSimulatorDescription(SimulatorCount, "Scalar Single Core CPU", ScalarSingleCoreSimulator);
        // SimulatorCount += 1;

        VectorSingleCoreSimulator = new CPUSimulation(NBodyCount, ActiveParams, true, false);
        VectorSingleCoreSimulator->start(true);
        SetSimulatorDescription(SimulatorCount, "Vector Single Core CPU", VectorSingleCoreSimulator);
        SimulatorCount += 1;

        VectorMultiCoreSimulator  = new CPUSimulation(NBodyCount, ActiveParams, true, true);
        VectorMultiCoreSimulator->start(true);
 
        SetSimulatorDescription(SimulatorCount, "Vector Multi Core CPU", VectorMultiCoreSimulator);
        SimulatorCount += 1;
    }
}

void DestroyAllSimulators(void)
{
    StopAllSimulators();

    DestroyCpuSimulators();
    DestroyGpuSimulators();

    SimulatorCount = 0;
    SimulatorIndex = 0;
}

void InitSimulation(int simulator)
{
    FirstFrame = true;

    if (ActiveSimulator)
        DestroyAllSimulators();

    SimulatorIndex = 0;
    SimulatorCount = 0;
    
    CreateCpuSimulators();
    CreateGpuSimulators();
    
    SelectSimulator(simulator);
    HorizontalTile = 1.0f * simulator;

    ResetDemo();
    ResetView();
}

void InitGalaxies(int initMode)
{
    InitGraphics();
    InitSimulation(initMode);
}

