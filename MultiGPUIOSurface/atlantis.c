
/* Copyright (c) Mark J. Kilgard, 1994. */

/**
 * (c) Copyright 1993, 1994, Silicon Graphics, Inc.
 * ALL RIGHTS RESERVED
 * Permission to use, copy, modify, and distribute this software for
 * any purpose and without fee is hereby granted, provided that the above
 * copyright notice appear in all copies and that both the copyright notice
 * and this permission notice appear in supporting documentation, and that
 * the name of Silicon Graphics, Inc. not be used in advertising
 * or publicity pertaining to distribution of the software without specific,
 * written prior permission.
 *
 * THE MATERIAL EMBODIED ON THIS SOFTWARE IS PROVIDED TO YOU "AS-IS"
 * AND WITHOUT WARRANTY OF ANY KIND, EXPRESS, IMPLIED OR OTHERWISE,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY OR
 * FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL SILICON
 * GRAPHICS, INC.  BE LIABLE TO YOU OR ANYONE ELSE FOR ANY DIRECT,
 * SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY
 * KIND, OR ANY DAMAGES WHATSOEVER, INCLUDING WITHOUT LIMITATION,
 * LOSS OF PROFIT, LOSS OF USE, SAVINGS OR REVENUE, OR THE CLAIMS OF
 * THIRD PARTIES, WHETHER OR NOT SILICON GRAPHICS, INC.  HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH LOSS, HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE
 * POSSESSION, USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * US Government Users Restricted Rights
 * Use, duplication, or disclosure by the Government is subject to
 * restrictions set forth in FAR 52.227.19(c)(2) or subparagraph
 * (c)(1)(ii) of the Rights in Technical Data and Computer Software
 * clause at DFARS 252.227-7013 and/or in similar or successor
 * clauses in the FAR or the DOD or NASA FAR Supplement.
 * Unpublished-- rights reserved under the copyright laws of the
 * United States.  Contractor/manufacturer is Silicon Graphics,
 * Inc., 2011 N.  Shoreline Blvd., Mountain View, CA 94039-7311.
 *
 * OpenGL(TM) is a trademark of Silicon Graphics, Inc.
 */

#ifndef MultiGPU_atlantis_h
#define MultiGPU_atlantis_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>

#include "atlantis.h"

fishRec sharks[NUM_SHARKS];
fishRec momWhale;
fishRec babyWhale;
fishRec dolph;

#define FPS_UPDATE_RATE  0.5f
GLboolean Timing = GL_TRUE;
struct timeval t1;
GLint frame_count = 0;

GLint w_win = 320;
GLint h_win = 240;

GLenum StrMode = GL_VENDOR;

GLboolean moving = GL_TRUE;
GLboolean force_redraw = GL_FALSE;

#if 0
void DrawStr(const char *str)
{
	GLint i = 0;
	
	if(!str) return;
        
	while(str[i])
	{
		glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, str[i]);
		i++;
	}
}
#endif

void
InitFishs(void)
{
    int i;

    for (i = 0; i < NUM_SHARKS; i++) {
        sharks[i].x = 70000.0 + rand() % 6000;
        sharks[i].y = rand() % 6000;
        sharks[i].z = rand() % 6000;
        sharks[i].psi = rand() % 360 - 180.0;
        sharks[i].v = 1.0;
    }

    dolph.x = 30000.0;
    dolph.y = 0.0;
    dolph.z = 6000.0;
    dolph.psi = 90.0;
    dolph.theta = 0.0;
    dolph.v = 3.0;

    momWhale.x = 70000.0;
    momWhale.y = 0.0;
    momWhale.z = 0.0;
    momWhale.psi = 90.0;
    momWhale.theta = 0.0;
    momWhale.v = 3.0;

    babyWhale.x = 60000.0;
    babyWhale.y = -2000.0;
    babyWhale.z = -2000.0;
    babyWhale.psi = 90.0;
    babyWhale.theta = 0.0;
    babyWhale.v = 3.0;
}

void
AtlantisInit(void)
{
    static float ambient[] = {0.2, 0.2, 0.2, 1.0};
    static float diffuse[] = {1.0, 1.0, 1.0, 1.0};
    static float position[] = {0.0, 1.0, 0.0, 0.0};
    static float mat_shininess[] = {90.0};
    static float mat_specular[] = {0.8, 0.8, 0.8, 1.0};
    static float mat_diffuse[] = {0.46, 0.66, 0.795, 1.0};
    static float mat_ambient[] = {0.3, 0.4, 0.5, 1.0};
    static float lmodel_ambient[] = {0.4, 0.4, 0.4, 1.0};
    static float lmodel_localviewer[] = {0.0};
    static float fog_color[] = {0.0, 0.5, 0.9, 1.0};

    glFrontFace(GL_CCW);

    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);

    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
    glLightfv(GL_LIGHT0, GL_POSITION, position);
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
    glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, lmodel_localviewer);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);

    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, mat_diffuse);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, mat_ambient);

//    InitFishs();

    glEnable(GL_FOG);
	glFogi(GL_FOG_MODE, GL_EXP);
	glFogf(GL_FOG_DENSITY, 0.0000025);
	glFogfv(GL_FOG_COLOR, fog_color);

    glClearColor(0.0, 0.5, 0.9, 1.0);
	
	glEnable(GL_SCISSOR_TEST);
}

void
AtlantisReshape(int width, int height)
{
	w_win = width;
	h_win = height;
	
    glViewport(0, 0, width, height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(60.0, (GLfloat) width / (GLfloat) height, 20000.0, 300000.0);
    glMatrixMode(GL_MODELVIEW);
	
	//glScissor(0, 20, w_win, h_win - 20);
	force_redraw = GL_TRUE;
}

void
AtlantisAnimate(void)
{
    int i;

    for (i = 0; i < NUM_SHARKS; i++) {
        SharkPilot(&sharks[i]);
        SharkMiss(i);
    }
    WhalePilot(&dolph);
    dolph.phi++;
    //glutPostRedisplay();
    WhalePilot(&momWhale);
    momWhale.phi++;
    WhalePilot(&babyWhale);
    babyWhale.phi++;
}

#if 0
void
Key(unsigned char key, int x, int y)
{
    switch (key) {
    case 't':
    	Timing = !Timing;
    break;
    case ' ':
    	switch(StrMode)
    	{
		    case GL_EXTENSIONS:
    			StrMode = GL_VENDOR;
		    break;
		    case GL_VENDOR:
		    	StrMode = GL_RENDERER;
		    break;
		    case GL_RENDERER:
		    	StrMode = GL_VERSION;
		    break;
		    case GL_VERSION:
		    	StrMode = GL_EXTENSIONS;
		    break;
		}
	break;
    case 27:           /* Esc will quit */
        exit(1);
    break;
    case 's':             		/* "s" start animation */
        moving = GL_TRUE;
        glutIdleFunc(Animate);
    break;
    case 'a':          			/* "a" stop animation */
        moving = GL_FALSE;
        glutIdleFunc(NULL);
    break;
    case '.':          			/* "." will advance frame */
        if (!moving) {
            Animate();
        }
    }
}
#endif

/*
void Display(void)
{
	static float P123[3] = {-448.94, -203.14, 9499.60};
	static float P124[3] = {-442.64, -185.20, 9528.07};
	static float P125[3] = {-441.07, -148.05, 9528.07};
	static float P126[3] = {-443.43, -128.84, 9499.60};
	static float P127[3] = {-456.87, -146.78, 9466.67};
	static float P128[3] = {-453.68, -183.93, 9466.67};

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glPushMatrix();
    FishTransform(&dolph);
    DrawDolphin(&dolph);
    glPopMatrix();
 
	glutSwapBuffers();
}
*/

void
AtlantisDisplay(void)
{
    int i;
	//float t;
	//struct timeval t2;
	//char num_str[128];
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for (i = 0; i < NUM_SHARKS; i++) {
        glPushMatrix();
        FishTransform(&sharks[i]);
        DrawShark(&sharks[i]);
        glPopMatrix();
    }

    glPushMatrix();
    FishTransform(&dolph);
    DrawDolphin(&dolph);
    glPopMatrix();

    glPushMatrix();
    FishTransform(&momWhale);
    DrawWhale(&momWhale);
    glPopMatrix();

    glPushMatrix();
    FishTransform(&babyWhale);
    glScalef(0.45, 0.45, 0.3);
    DrawWhale(&babyWhale);
    glPopMatrix();
    
#if 0
	frame_count++;
	gettimeofday(&t2, NULL);
	t = (t2.tv_sec - t1.tv_sec) + 0.000001f * (t2.tv_usec - t1.tv_usec);
    if(force_redraw || (Timing && (t > FPS_UPDATE_RATE)))
    {
		t = (GLfloat) frame_count / t;
		
		glScissor(0, 0, w_win, 20);
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		glDisable(GL_LIGHTING);
		//glDisable(GL_DEPTH_TEST);
		
		glColor3f(1.0, 0.0, 0.0);
		
		glMatrixMode (GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		glOrtho(0, w_win, 0, h_win, -10.0, 10.0);
		
		glRasterPos2f(5.0, 5.0);
		
		switch(StrMode)
		{
			case GL_VENDOR:
				sprintf(num_str, "%0.2f Hz, %dx%d, VENDOR: ", t, (int)w_win, (int)h_win);
				DrawStr(num_str);
				DrawStr((char *)glGetString(GL_VENDOR));
			break;
			case GL_RENDERER:
				sprintf(num_str, "%0.2f Hz, %dx%d, RENDERER: ", t, (int)w_win, (int)h_win);
				DrawStr(num_str);
				DrawStr((char *)glGetString(GL_RENDERER));
			break;
			case GL_VERSION:
				sprintf(num_str, "%0.2f Hz, %dx%d, VERSION: ", t, (int)w_win, (int)h_win);
				DrawStr(num_str);
				DrawStr((char *)glGetString(GL_VERSION));
			break;
			case GL_EXTENSIONS:
				sprintf(num_str, "%0.2f Hz, %dx%d, EXTENSIONS: ", t, (int)w_win, (int)h_win);
				DrawStr(num_str);
				DrawStr((char *)glGetString(GL_EXTENSIONS));
			break;
		}
		
		glPopMatrix();
		glMatrixMode(GL_MODELVIEW);
		
		glEnable(GL_LIGHTING);
		//glEnable(GL_DEPTH_TEST);
		
		glScissor(0, 20, w_win, h_win - 20);
		
		gettimeofday(&t1, NULL);
		frame_count = 0;
		force_redraw = GL_FALSE;
	}
	
    glutSwapBuffers();
#endif

}

#if 0

void
Visible(int state)
{
    if (state == GLUT_VISIBLE) {
        if (moving)
            glutIdleFunc(Animate);
    } else {
        if (moving)
            glutIdleFunc(NULL);
    }
}

void
timingSelect(int value)
{
    switch(value)
    {
		case 1:
			StrMode = GL_VENDOR;
		break;
		case 2:
			StrMode = GL_RENDERER;
		break;
		case 3:
			StrMode = GL_VERSION;
		break;
		case 4:
			StrMode = GL_EXTENSIONS;
		break;
    }
}

void
menuSelect(int value)
{
    switch (value) {
    case 1:
        moving = GL_TRUE;
        glutIdleFunc(Animate);
        break;
    case 2:
        moving = GL_FALSE;
        glutIdleFunc(NULL);
        break;
    case 4:
        exit(0);
        break;
    }
}

int
main(int argc, char **argv)
{
	GLboolean fullscreen = GL_FALSE; 
	GLint time_menu;
 	
 	srand(0);
	gettimeofday(&t1, NULL);

        glutInit(&argc, argv);
	if (argc > 1 && !strcmp(argv[1], "-w"))
		fullscreen = GL_FALSE;

	//glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
	glutInitDisplayString("rgba double depth=24");
	if (fullscreen) {
	  glutGameModeString("1024x768:32");
	  glutEnterGameMode();
	} else {
	  glutInitWindowSize(320, 240);
	  glutCreateWindow("Atlantis Timing");
	}
    Init();
    glutDisplayFunc(Display);
    glutReshapeFunc(Reshape);
    glutKeyboardFunc(Key);
    glutIdleFunc(Animate);
    glutVisibilityFunc(Visible);
    
    time_menu = glutCreateMenu(timingSelect);
    glutAddMenuEntry("GL_VENDOR", 1);
    glutAddMenuEntry("GL_RENDERER", 2);
    glutAddMenuEntry("GL_VERSION", 3);
    glutAddMenuEntry("GL_EXTENSIONS", 4);
    
    glutCreateMenu(menuSelect);
    glutAddMenuEntry("Start motion", 1);
    glutAddMenuEntry("Stop motion", 2);
    glutAddSubMenu("Timing Mode", time_menu);
    glutAddMenuEntry("Quit", 4);
    
    //glutAttachMenu(GLUT_RIGHT_BUTTON);
    glutAttachMenu(GLUT_RIGHT_BUTTON);
    glutMainLoop();
    return 0;             /* ANSI C requires main to return int. */
}
#endif

#endif //#ifndef MultiGPU_atlantis_h