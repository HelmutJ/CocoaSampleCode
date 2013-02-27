/*

File: main.c

Abstract: FBO bunnies

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 

//  Demonstrate a few ways to render-to-texture via FBO:
//  * cache rendering results (imposters)
//  * dynamic cubic environment map
//  * fullscreen shader effects
//
//  See the specification for full details:
//  http://www.opengl.org/registry/specs/EXT/framebuffer_object.txt

#include <GLUT/glut.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <limits.h>				// for INT_MAX
#include "stanfordbunny.h"

#define WINDOWWIDE 800
#define WINDOWHIGH 600
#define NUMFBOS    3
#define NUMCUBES   75

#ifdef DEBUG
	#define glError() { \
		GLenum err = glGetError(); \
		while (err != GL_NO_ERROR) { \
			printf("glError: %s caught at %s:%u\n", (char *)gluErrorString(err), __FILE__, __LINE__); \
			err = glGetError(); \
		} \
	}
#else
	#define glError()
#endif


// ---------------------------------------------------------------------
// RANROT-B PRNG, 32 bits, faster than random()
// ---------------------------------------------------------------------
int	randseed, m_lo, m_hi;
static inline void mysrand(int seed) { randseed = m_lo = seed; m_hi = ~seed; }
static inline            int irand() { m_hi = (m_hi<<16) + (m_hi>>16); m_hi += m_lo; m_lo += m_hi; return m_hi; }
static inline float   frand(float x) { return ((x * irand()) / (float)INT_MAX); }


typedef struct glExtension {
    char		*name;
    GLfloat		promoted;
    GLboolean	supported;
} glExtension;

typedef struct fbodesc {
	GLint  wide, high;
	GLenum color0;
	GLenum filter;
	GLenum depth;
} fbodesc;


// globals
static  GLuint tx[NUMFBOS];
static  GLuint fb[NUMFBOS];
static  GLuint rb[NUMFBOS];
int     winwide = WINDOWWIDE, winhigh = WINDOWHIGH;
GLuint  dlist[3];
GLfloat cuben[NUMCUBES][5];
GLfloat DOFfocus = 0.80, DOFrange = 10.0;
int     fullscreen = 0, mode = 2;
float   mode2move = 1.0;
float   glCoreVersion;
glExtension	extension[] = {
	{"GL_EXT_framebuffer_object",   0.0, 0},
	{"GL_ARB_texture_cube_map",     1.3, 0},
	{"GL_ARB_shader_objects",       2.0, 0},
	{"GL_ARB_shading_language_100", 2.0, 0},
	{"GL_ARB_fragment_shader",      2.0, 0},
};

fbodesc fbos[NUMFBOS] = {
	{  512,  512, GL_TEXTURE_2D,           GL_LINEAR_MIPMAP_NEAREST, GL_RENDERBUFFER_EXT },
	{  128,  128, GL_TEXTURE_CUBE_MAP_ARB, GL_LINEAR,                GL_RENDERBUFFER_EXT },
	{ 1024, 1024, GL_TEXTURE_2D,           GL_LINEAR_MIPMAP_LINEAR,  GL_TEXTURE_2D       },
};

// extension index
enum {
	EXT_framebuffer_object,
	ARB_texture_cube_map,
	ARB_shader_objects,
	ARB_shading_language_100,
	ARB_fragment_shader,
};

// FBO index
enum {
	FBO_BUNNY,
	FBO_ENVMAP,
	FBO_DOF,
};

// dlist index
enum {
	DLIST_BUNNY,
	DLIST_CUBEFILL,
	DLIST_CUBE,
};


// GLSL shader for simple depth-of-field
GLhandleARB fsid, prid;
char *DOFfs = 
	"uniform sampler2D unit0;\n"
	"uniform sampler2D unit1;\n"
	"uniform float focus;\n"
	"uniform float range;\n"
	"void main() {\n"
		"float depth = texture2D(unit1, gl_TexCoord[0].st).x;\n"
		"depth = abs(depth - focus) * range;\n"
		"gl_FragColor = texture2D(unit0, gl_TexCoord[0].st, depth);\n"
	"}\n";

#pragma mark -
#pragma mark Shader support 
GLhandleARB load_shader(GLenum program_type, const char *fs) {
	GLhandleARB program;
	GLint       logLength, status;

	program = glCreateShaderObjectARB(program_type);	
	glShaderSourceARB(program, 1, (const GLcharARB **)&fs, NULL);
	glCompileShaderARB(program);
	glGetObjectParameterivARB(program, GL_OBJECT_INFO_LOG_LENGTH_ARB, &logLength);
	if (logLength > 0) {
		GLcharARB *log = malloc(logLength);
		glGetInfoLogARB(program, logLength, &logLength, log);
		printf("Shader compile log:\n%s\n", log);
		free(log);
	}

	glGetObjectParameterivARB(program, GL_OBJECT_COMPILE_STATUS_ARB, &status);
	if (status == 0)
		printf("Failed to compile shader %s\n", fs);

	return program;
}


void link_program(GLhandleARB program) {
	GLint	logLength, status;
	
	glLinkProgramARB(program);
	glGetObjectParameterivARB(program, GL_OBJECT_INFO_LOG_LENGTH_ARB, &logLength);
	if (logLength > 0) {
		GLcharARB *log = malloc(logLength);
		glGetInfoLogARB(program, logLength, &logLength, log);
		printf("Program link log:\n%s\n", log);
		free(log);
	}
	
	glGetObjectParameterivARB(prid, GL_OBJECT_LINK_STATUS_ARB, &status);
	if (status == 0)
		printf("Failed to link program %d\n", (int)program);
}


GLint get_location(GLhandleARB program, const GLcharARB *name) {
    GLint loc;

    loc = glGetUniformLocationARB(program, name);
    if (loc == -1) {
        printf("No such uniform named %s\n", name);
	}

    return loc;
}
#pragma mark -

#pragma mark Window reshaping
void reshape(int width, int height, int windowaspect, int ortho) {
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	if (ortho)
		gluOrtho2D(0, width, 0, height);
	else
		gluPerspective(60, windowaspect?(winwide/(float)winhigh):(width/(float)height), 0.5, 10);
	glMatrixMode(GL_MODELVIEW);
}


void reshapeGLUT(int width, int height) {
	winwide = width;
	winhigh = height;
	reshape(width, height, 0, 0);
}

#pragma mark -
#pragma mark Keyboard input
void key(unsigned char key, int x, int y) {
    switch (key) {
    case '[': DOFfocus -= 0.05; break;
    case ']': DOFfocus += 0.05; break;
    case '{': DOFrange -= 0.5;  break;
    case '}': DOFrange += 0.5;  break;
    case '1':	//   single bunny
    case '2':	// + render to FBO
    case '3':	// + FBO cube
    case '4': 	// + transparent cube
    case '5':	// + cube cloud
    case '6':	// + cubemap overlay
    case '7':	// + envmap
    case '8':	// + depth of field
    case '9':	// - depth overlay
    		  mode = key - '0'; break;
    case ' ': mode++; if (mode > 9) mode = 1; break;
    case 'f':
    case 'F':
    	fullscreen = !fullscreen;
    	if (fullscreen)
    		glutFullScreen();
    	else
    		glutReshapeWindow(WINDOWWIDE, WINDOWHIGH);
    	break;
    }
	
	// set parameters
	if ((mode >= 2) && (mode <= 4))
		mode2move = 1.0;
	else
		mode2move = 0.0;
}

#pragma mark -
#pragma mark Render

void drawbunny(float rotx, float roty, float rotz, int tint) {
	glEnable(GL_LIGHTING);

	glRotatef(rotx, 1, 0, 0);
	glRotatef(roty, 0, 1, 0);
	glRotatef(rotz, 0, 0, 1);
	if (tint)
		glColor4f(.7, .5, .3, 1);
	else
		glColor4f(1, 1, 1, 1);
	glCallList(dlist[DLIST_BUNNY]);	
}


void drawcloud(int spin) {
	int i;
	static float s = 0;
	static float sanim = 0.05;

	for (i = 0; i < NUMCUBES; i++) {
		glLoadIdentity();
		glTranslatef(0, 0, -2);
		glRotatef(cuben[i][0]*cuben[i][3], 1, 0, 0);
		glRotatef(cuben[i][1]*cuben[i][3], 0, 1, 0);
		glRotatef(cuben[i][2]*cuben[i][3], 0, 0, 1);
		glTranslatef(cuben[i][0]*s, cuben[i][1]*s, cuben[i][2]*s);
		glScalef(.08, .08, .08);

		glCallList(dlist[DLIST_CUBE]);
		if (spin) cuben[i][3] += cuben[i][4];
	}
	
	s += sanim;
	if (sanim > 0.002) sanim -= 0.001;
	if ((s >= 1.3) || (s <= 0.0)) sanim *= -0.0;
}

void display() {
	static float rotx = 0.0, roty = 0.0, rotz = 0.0;
	static float rt2x = 0.0, rt2y = 0.0, rt2z = 0.0;
	
	// animate parameters
	rotx += 0.3; if (roty >= 360) roty -= 360;
	roty += 0.7; if (roty >= 360) roty -= 360;
	rotz += 0.9; if (roty >= 360) roty -= 360;

	if (mode > 2) {
		rt2x += 0.2; if (rt2x >= 360) rt2x -= 360;
		rt2y += 0.3; if (rt2y >= 360) rt2y -= 360;
		rt2z += 0.1; if (rt2z >= 360) rt2z -= 360;
	} else {
		rt2x = rt2y = rt2z = 0;
	}
	
#pragma mark Render inside FBO
	{
		glDisable(GL_TEXTURE_2D);
		if (mode >= 2) {	
			// render bunny to FBO
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb[FBO_BUNNY]);
			if (mode >= 4)
				glClearColor(0, 0, 0, 0);
			else
				glClearColor(0.5, 0.5, 0.5, 1);		
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			reshape(fbos[FBO_BUNNY].wide, fbos[FBO_BUNNY].high, 0, 0);
			glLoadIdentity();
			glTranslatef(0, 0, -1.35);
			drawbunny(rotx, roty, rotz, 1);	
			// At this point we have a texture with the bunny
			glBindTexture(GL_TEXTURE_2D, tx[FBO_BUNNY]);
			glGenerateMipmapEXT(GL_TEXTURE_2D);
			// We bind it such that any geometry will get a bunny texture
			// generate mipmaps for visual quality
		}
	}
	
	if (mode >= 6) {
		// render cloud of bunny cubes to each cubemap face
		GLfloat lookat[6][6] = {
			{  1.0,  0.0,  0.0, 0.0, -1.0,  0.0 }, 
			{ -1.0,  0.0,  0.0, 0.0, -1.0,  0.0 },
			{  0.0,  1.0,  0.0, 0.0,  0.0,  1.0 },
			{  0.0, -1.0,  0.0, 0.0,  0.0, -1.0 },
			{  0.0,  0.0,  1.0, 0.0, -1.0,  0.0 },
			{  0.0,  0.0, -1.0, 0.0, -1.0,  0.0 },
		};
		int face;

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb[FBO_ENVMAP]);
		glViewport(0, 0, fbos[FBO_ENVMAP].wide, fbos[FBO_ENVMAP].high);
		glDisable(GL_LIGHTING);
		glEnable(GL_CULL_FACE);
		glEnable(GL_TEXTURE_2D);
		glEnable(GL_BLEND);

		for (face = 0; face < 6; face++) {
			glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB + face, tx[FBO_ENVMAP], 0);
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb[FBO_ENVMAP]);

			glClearColor(.3, .4, .5, 1);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			gluPerspective(90, 1, 0.5, 10.0);
			gluLookAt(0.0, 0.0, -2.0,
				lookat[face][0], lookat[face][1], lookat[face][2]-2.0,
				lookat[face][3], lookat[face][4], lookat[face][5]);
			glMatrixMode(GL_MODELVIEW);

			drawcloud(0);
		}
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_BLEND);
		glDisable(GL_CULL_FACE);
	}

	// redirect rendering either to the window or DOF FBO
	if (mode >= 8) {
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb[FBO_DOF]);
		reshape(fbos[FBO_DOF].wide, fbos[FBO_DOF].high, 1, 0);
	} else {
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		reshape(winwide, winhigh, 0, 0);
	}
	
	{
		// render real bunny geometry
		glClearColor(.3, .4, .5, 1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
				
		if (mode >= 7) {
			// apply envmap
			glEnable(GL_TEXTURE_GEN_S);
			glEnable(GL_TEXTURE_GEN_T);
			glEnable(GL_TEXTURE_GEN_R);
			glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP_ARB);
			glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP_ARB);
			glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP_ARB);
			glBindTexture(GL_TEXTURE_CUBE_MAP, rb[FBO_ENVMAP]);
			glEnable(GL_TEXTURE_CUBE_MAP);
		}
		
		glLoadIdentity();
		glTranslatef(mode2move * -0.66, 0, -2);
		if (mode <= 4)
			drawbunny(rotx, roty, rotz, 1);
		else
			drawbunny(rt2x, rt2y, rt2z, mode<=6);
			
		glDisable(GL_TEXTURE_GEN_S);
		glDisable(GL_TEXTURE_GEN_T);
		glDisable(GL_TEXTURE_GEN_R);
		glDisable(GL_TEXTURE_CUBE_MAP);
	}

	// render cubes
	glDisable(GL_LIGHTING);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_CULL_FACE);
	if (mode >= 4)
		glEnable(GL_BLEND);
	
	if ((mode >= 2) && (mode <= 4))  {
		// render single cube mapped with FBO
		glLoadIdentity();
		glTranslatef(mode2move * 0.51, 0, -2);
		glRotatef(rt2x, 1, 0, 0);
		glRotatef(rt2y, 0, 1, 0);
		glRotatef(rt2z, 0, 0, 1);
		glScalef(.53, .53, .53);
		glCallList(dlist[DLIST_CUBE]);
	}
	
	if (mode >= 5) {
		// render cloud of cubes
		drawcloud(1);
	}
	
	glDisable(GL_BLEND);
	glDisable(GL_CULL_FACE);
	glColor4f(1,1,1,1);
	
	if ((mode >= 6) && (mode <= 7)) {
		// show cubemap
		int x = 64; 
		int y = winhigh-576;

		reshape(winwide, winhigh, 0, 1);
		glLoadIdentity();

		glDisable(GL_DEPTH_TEST);
		glDisable(GL_FOG);
		glDisable(GL_TEXTURE_2D);
		glEnable(GL_TEXTURE_CUBE_MAP);
		glBegin(GL_QUADS);
			glTexCoord3f( 1, 1, 1); glVertex2f(x+256, y+384);		// pos_x
			glTexCoord3f( 1, 1,-1); glVertex2f(x+384, y+384);
			glTexCoord3f( 1,-1,-1); glVertex2f(x+384, y+256);
			glTexCoord3f( 1,-1, 1); glVertex2f(x+256, y+256);
			glTexCoord3f(-1, 1,-1); glVertex2f(x+0,   y+384);		// neg_x
			glTexCoord3f(-1, 1, 1); glVertex2f(x+128, y+384);
			glTexCoord3f(-1,-1, 1); glVertex2f(x+128, y+256);
			glTexCoord3f(-1,-1,-1); glVertex2f(x+0,   y+256);
			glTexCoord3f(-1, 1,-1); glVertex2f(x+128, y+512);		// pos_y
			glTexCoord3f( 1, 1,-1); glVertex2f(x+256, y+512);
			glTexCoord3f( 1, 1, 1); glVertex2f(x+256, y+384);
			glTexCoord3f(-1, 1, 1); glVertex2f(x+128, y+384);
			glTexCoord3f(-1,-1, 1); glVertex2f(x+128, y+256);		// neg_y
			glTexCoord3f( 1,-1, 1); glVertex2f(x+256, y+256);
			glTexCoord3f( 1,-1,-1); glVertex2f(x+256, y+128);
			glTexCoord3f(-1,-1,-1); glVertex2f(x+128, y+128);
			glTexCoord3f(-1, 1, 1); glVertex2f(x+128, y+384);		// pos_z
			glTexCoord3f( 1, 1, 1); glVertex2f(x+256, y+384);
			glTexCoord3f( 1,-1, 1); glVertex2f(x+256, y+256);
			glTexCoord3f(-1,-1, 1); glVertex2f(x+128, y+256);
			glTexCoord3f( 1, 1,-1); glVertex2f(x+256, y+0  );		// neg_z
			glTexCoord3f(-1, 1,-1); glVertex2f(x+128, y+0  );
			glTexCoord3f(-1,-1,-1); glVertex2f(x+128, y+128);
			glTexCoord3f( 1,-1,-1); glVertex2f(x+256, y+128);
		glEnd();
		glDisable(GL_TEXTURE_CUBE_MAP);
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+256, y+384);
			glVertex2f(x+384, y+384);
			glVertex2f(x+384, y+256);
			glVertex2f(x+256, y+256);
		glEnd();
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+0,   y+384);
			glVertex2f(x+128, y+384);
			glVertex2f(x+128, y+256);
			glVertex2f(x+0,   y+256);
		glEnd();
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+128, y+512);
			glVertex2f(x+256, y+512);
			glVertex2f(x+256, y+384);
			glVertex2f(x+128, y+384);
		glEnd();
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+128, y+256);
			glVertex2f(x+256, y+256);
			glVertex2f(x+256, y+128);
			glVertex2f(x+128, y+128);
		glEnd();
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+128, y+384);
			glVertex2f(x+256, y+384);
			glVertex2f(x+256, y+256);
			glVertex2f(x+128, y+256);
		glEnd();
		glBegin(GL_LINE_LOOP);
			glVertex2f(x+256, y+0  );
			glVertex2f(x+128, y+0  );
			glVertex2f(x+128, y+128);
			glVertex2f(x+256, y+128);
		glEnd();
		glEnable(GL_TEXTURE_2D);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_FOG);
	}

	if (mode >= 8) {
		// blit to window with depth-of-field effect
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		reshape(winwide, winhigh, 0, 1);
		glLoadIdentity();

		glDisable(GL_DEPTH_TEST);
		glDisable(GL_FOG);
		
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, rb[FBO_DOF]);
		glActiveTexture(GL_TEXTURE0);
		
		glBindTexture(GL_TEXTURE_2D, tx[FBO_DOF]);
		glGenerateMipmapEXT(GL_TEXTURE_2D);
	
		glUseProgramObjectARB(prid);
		glUniform1fARB(get_location(prid, "focus"), DOFfocus);
		glUniform1fARB(get_location(prid, "range"), DOFrange);

		glBegin(GL_QUADS);
			glTexCoord2f(0, 0); glVertex2f(0,       0);
			glTexCoord2f(1, 0); glVertex2f(winwide, 0);
			glTexCoord2f(1, 1); glVertex2f(winwide, winhigh);
			glTexCoord2f(0, 1); glVertex2f(0,       winhigh);
		glEnd();
	
		glUseProgramObjectARB(0);
	
		if (mode == 8) {
			// show depth texture
			glBindTexture(GL_TEXTURE_2D, rb[FBO_DOF]);
			glBegin(GL_QUADS);
				glTexCoord2f(0, 0); glVertex2f(winwide/2, 0);
				glTexCoord2f(1, 0); glVertex2f(winwide,   0);
				glTexCoord2f(1, 1); glVertex2f(winwide,   winhigh/2);
				glTexCoord2f(0, 1); glVertex2f(winwide/2, winhigh/2);
			glEnd();	
		}
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_FOG);
	}

	glutSwapBuffers();
	glError();
	
	glutPostRedisplay();
}

#pragma mark -
#pragma mark INITIALIZATION

GLuint buildcube(void) {
	// simple cube data	
	GLfloat cube_pos[8][3] = {
		{1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}, {-1.0, 1.0, 1.0},
		{1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}
	};
	
	GLfloat cube_color[6][3] = {
		{1, 1, 1}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}, {1, 0, 1}
	};
			
	short cube_faces[6][4] = {
		{3, 2, 1, 0}, {2, 3, 7, 6}, {0, 1, 5, 4}, {3, 0, 4, 7}, {1, 2, 6, 5}, {4, 5, 6, 7}
	};
	
	GLfloat cube_tex[2][4] = {
		{0.0, 0.0, 1.0, 1.0}, {1.0, 0.0, 0.0, 1.0}
	};

	long f, i;
	GLuint dlist = glGenLists(1);
	glNewList(dlist, GL_COMPILE);
	glBegin(GL_QUADS);
	for (f = 0; f < 6; f++) {
		for (i = 0; i < 4; i++) {
			glColor3f(cube_color[f][0], cube_color[f][1], cube_color[f][2]);
			glTexCoord2f(cube_tex[0][i], cube_tex[1][i]);
			glVertex3f(cube_pos[cube_faces[f][i]][0], cube_pos[cube_faces[f][i]][1], cube_pos[cube_faces[f][i]][2]);
		}
	}
	glEnd();
	glEndList();
	return dlist;
}

void setlights(void) {
	GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[] = {90.0};

	GLfloat position[4] = {0.0,0.0,12.0,0.0};
	GLfloat ambient[4]  = {0.2,0.2,0.2,1.0};
	GLfloat diffuse[4]  = {1.0,1.0,1.0,1.0};
	GLfloat specular[4] = {1.0,1.0,1.0,1.0};
	
	glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular);
	glMaterialfv (GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess);
	
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
	
	glLightfv(GL_LIGHT0,GL_POSITION,position);
	glLightfv(GL_LIGHT0,GL_AMBIENT,ambient);
	glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuse);
	glLightfv(GL_LIGHT0,GL_SPECULAR,specular);
	glEnable(GL_LIGHT0);
	
	glLightModeli(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR);
}

void initGL() {
	int i;
	
#pragma mark Check OpenGL Extensions

	// check core version and extensions we're interested in
	{
		int supported = 1;
		
		sscanf((char *)glGetString(GL_VERSION), "%f", &glCoreVersion);
		printf("%s %s\n", (char *)glGetString(GL_RENDERER), (char *)glGetString(GL_VERSION));
		printf("----------------------------------\n");
		
		int j = sizeof(extension)/sizeof(glExtension);
		for (i = 0; i < j; i++) {
			extension[i].supported = glutExtensionSupported(extension[i].name) |
									 (extension[i].promoted && (glCoreVersion >= extension[i].promoted));
			printf("%-32s %d\n", extension[i].name, extension[i].supported);
			supported &= extension[i].supported;
		}	
		printf("----------------------------------\n");
		
		if (!supported) {
			printf("Required functionality not available on this renderer.\n");
			// A robust app could fall back to other methods here, like glCopyTexImage.
			// This is just a demo, so quit.
			exit(0);
		}
	}
	
	// constant state
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_ALPHA_TEST);
	glAlphaFunc(GL_GREATER, 0.0);
	glEnable(GL_DEPTH_TEST);
	glFogi(GL_FOG_MODE, GL_LINEAR);
	glFogf(GL_FOG_START, 1.6);
	glFogf(GL_FOG_END, 3.5);
	GLfloat fogc[4] = { .3, .4, .5, 1 };
	glFogfv(GL_FOG_COLOR, fogc);
	glEnable(GL_FOG);
	setlights();
	glLineWidth(3);

	// geometry setup
	dlist[DLIST_BUNNY] = GenStanfordBunnySolidList();
	dlist[DLIST_CUBEFILL] = buildcube();
	dlist[DLIST_CUBE] = glGenLists(1);
	glNewList(dlist[DLIST_CUBE], GL_COMPILE);
		// cube is blended, so draw in two passes
		glCullFace(GL_FRONT);
		glCallList(dlist[1]);
		glCullFace(GL_BACK);
		glCallList(dlist[1]);
	glEndList();
	
#pragma mark FBO Setup
	
	// fbo setup
	{
		GLenum status;
				
		glGenFramebuffersEXT(NUMFBOS, fb);
		glGenRenderbuffersEXT(NUMFBOS, rb);
		glGenTextures(NUMFBOS, tx);
		for (i = 0; i < NUMFBOS; i++) {
			GLenum color0 = fbos[i].color0;
			GLenum depth  = fbos[i].depth;

			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb[i]);
			if (color0) {
				GLenum attach;
				glBindTexture(color0, tx[i]);
				// Framebuffer texture initialization
				glTexParameteri(color0, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glTexParameteri(color0, GL_TEXTURE_MIN_FILTER, fbos[i].filter);
				glTexParameteri(color0, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameteri(color0, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				for (attach  = (color0==GL_TEXTURE_CUBE_MAP?GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB:color0);
				     attach <= (color0==GL_TEXTURE_CUBE_MAP?GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB:color0); attach++) {
					glTexImage2D(attach, 0, GL_RGBA8, fbos[i].wide, fbos[i].high, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
				}
				glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, attach-1, tx[i], 0);
			}

			// Create depth attachment as needed, either a renderbuffer or depth texture
			if (depth == GL_RENDERBUFFER_EXT) {
				glBindRenderbufferEXT(depth, rb[i]);
       			glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, fbos[i].wide, fbos[i].high);
     			glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, rb[i]);
			} else if (depth) {
				glGenTextures(1, &rb[i]);
				glBindTexture(depth, rb[i]);
				glTexParameteri(depth, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				glTexParameteri(depth, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
				glTexParameteri(depth, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameteri(depth, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				glTexImage2D(depth, 0, GL_DEPTH_COMPONENT, fbos[i].wide, fbos[i].high, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);	
				glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, depth, rb[i], 0);
			}
			status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
			if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
				printf("Error, FBO %d status %04x\n", i, (int)status);
		}
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	}
#pragma mark Shader setup
	// shader setup
	fsid = load_shader(GL_FRAGMENT_SHADER_ARB, DOFfs);
	prid = glCreateProgramObjectARB();
	glAttachObjectARB(prid, fsid);
	link_program(prid);
	glUseProgramObjectARB(prid);	
	glUniform1iARB(get_location(prid, "unit0"), 0);
	glUniform1iARB(get_location(prid, "unit1"), 1);
	glUseProgramObjectARB(0);
	
	// PRNG setup
	mysrand(0xDEADBEEF);
	
	// precalc some random normals and velocities
	for (i = 0; i < NUMCUBES; i++) {
		float x = frand(1);
		float y = frand(1);
		float z = frand(1);
		float m = 1.0/sqrtf( (x*x) + (y*y) + (z*z) );
		cuben[i][0] = x*m;
		cuben[i][1] = y*m;
		cuben[i][2] = z*m;
		cuben[i][3] = 0;
		cuben[i][4] = frand(1); cuben[i][4] += (cuben[i][4] > 0)?0.1:-0.1;
	}
	glError();
}
#pragma mark -

int main(int argc, char **argv) {
	glutInit(&argc, argv);
	glutInitWindowSize(WINDOWWIDE, WINDOWHIGH);
	glutInitDisplayString("double rgb depth");
	glutCreateWindow("FBO Bunnies");

	initGL();

	glutReshapeFunc(reshapeGLUT);
	glutDisplayFunc(display);
    glutKeyboardFunc(key);
	glutMainLoop();

	return 0;
}
