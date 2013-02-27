/*

File: main.c

Abstract: PBO render to vertex array

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

//  Demonstrate one usage of PBO:
//  * render to vertex array
//
//  See the specification for full details:
//  http://www.opengl.org/registry/specs/ARB/pixel_buffer_object.txt

#include <GLUT/glut.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

extern GLuint load_texure(const char *filename);
extern void setcwd(void);

#define WINDOWWIDE 800
#define WINDOWHIGH 600
#define RTVASIZE   128
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#if DEBUG
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


typedef struct glExtension {
    char		*name;
    GLfloat		promoted;
    GLboolean	supported;
} glExtension;

// globals
int    winwide = WINDOWWIDE, winhigh = WINDOWHIGH;
GLuint fb, rb;
GLuint tx, logo, hmap, atanmap;
GLuint ibo;
GLuint  vbo;	// VBO & PBO
GLuint  dlist[3];
int    fullscreen = 0, wireframe = 0, showmesh = 1, rings = 0, help = 1;
int    click = 0, clickx, clicky;
float  tilt = -60.0;
float  ripple_freq = 30.0, ripple_scale = 0.05, logo_scale = 0.5, twirl_angle = 0.0;
float  center[4];
float  glCoreVersion;
glExtension	extension[] = {
	{"GL_EXT_framebuffer_object",   0.0, 0},
	{"GL_ARB_pixel_buffer_object",  2.1, 0},
	{"GL_ARB_vertex_buffer_object", 1.5, 0},
	{"GL_ARB_shader_objects",       2.0, 0},
	{"GL_ARB_shading_language_100", 2.0, 0},
	{"GL_ARB_vertex_shader",        2.0, 0},
	{"GL_ARB_fragment_shader",      2.0, 0},
	{"GL_ARB_texture_rectangle",    0.0, 0},
	{"GL_APPLE_float_pixels",       0.0, 0},
};

// extension index
enum {
	EXT_framebuffer_object,
	ARB_pixel_buffer_object,
	ARB_vertex_buffer_object,
	ARB_shader_objects,
	ARB_shading_language_100,
	ARB_vertex_shader,
	ARB_fragment_shader,
	ARB_texture_rectangle,
	APPLE_float_pixels,
};

// GLSL shader to draw coincentric ripples
// note: this shader has been tuned to run in hardware on less-capable GPUs
GLhandleARB ripple_vs, ripple_fs, ripple_pr;
// vertex shader
char *ripplevs =
	"uniform vec4 centers;\n"
	"uniform float rtvasize;\n"
	"varying vec4 deltas;\n"
	"varying vec2 deltac;\n"
	"void main() {\n"
		// precalc deltas and interpolate across fragments
	"	deltas = gl_MultiTexCoord0.stst - centers;\n"
	"	deltac = gl_MultiTexCoord0.st - 0.5;\n"
	"	gl_TexCoord[0] = gl_MultiTexCoord0;\n"
	"	gl_TexCoord[1] = gl_MultiTexCoord0 * rtvasize;\n"
	"	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\n"
	"}\n";

//fragment shader
char *ripplefs =
	"uniform sampler2D unit0;\n"
	"uniform sampler2DRect unit1;\n"
	"uniform float ripple_scale;\n"
	"uniform float ripple_freq;\n"
	"uniform float ripple_xlate;\n"
	"uniform float logo_scale;\n"
	"uniform float twirl_angle;\n"
	"varying vec4 deltas;\n"
	"varying vec2 deltac;\n"
	"void main() {\n"
		// sum two ripples into Z component
	"	vec2 dist = sqrt(vec2(dot(deltas.xy,deltas.xy), dot(deltas.zw,deltas.zw)));\n"
	"	vec2 damp = 1.0 - dist;\n"
	"	vec2 damp2 = damp * damp;\n"
	"	vec2 wave = sin(dist * ripple_freq + ripple_xlate) * damp2;\n"
	"	float z = (wave.x + wave.y) * ripple_scale;\n"
		// add in a texture lookup
	"	float logo  = texture2D(unit0, gl_TexCoord[0].st).r;\n"
	"	z += logo * logo_scale;\n"
		// twirl texcoords into X and Y (use a texture lookup for atan2)
	"	float distc = length(deltac);\n"
	"	float a = texture2DRect(unit1, gl_TexCoord[1].st).r;\n"
	"	a -= 0.5; a *= 6.28318530718;\n"
	"	a = a + twirl_angle * (1.0 - distc);\n"
	"	gl_FragColor = vec4(0.5 + distc * sin(a), 0.5 + distc * cos(a), z, 1.0);\n"
	"}\n";

// GLSL shader to put geometry's depth into B
GLhandleARB blue_fs, blue_pr;
char *bluefs =
	"void main() {\n"
		// bias and scale are hardcoded to "look good" for the demo
	"	gl_FragColor.b = ((1.0-gl_FragCoord.z)+0.02)*4.0;\n"
	"}\n";

#pragma mark -
#pragma mark Shader support
// load and compile shader 
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

// link shader
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
	
	glGetObjectParameterivARB(ripple_pr, GL_OBJECT_LINK_STATUS_ARB, &status);
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
#pragma mark Window reshape
void reshape(int width, int height, int ortho) {
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	if (ortho)
		gluOrtho2D(0, width, 0, height);
	else
		gluPerspective(60, width/(float)height, 0.8, 8);
	glMatrixMode(GL_MODELVIEW);
}


void reshapeGLUT(int width, int height) {
	winwide = width;
	winhigh = height;
	reshape(width, height, 0);
}

#pragma mark -
#pragma mark Keyboard input
void key(unsigned char key, int x, int y) {
    switch (key) {
	case '{': ripple_freq  -= 1.0; if (ripple_freq  <   0) ripple_freq  =   0; break;
	case '}': ripple_freq  += 1.0; if (ripple_freq  >  50) ripple_freq  =  50; break;
	case '[': ripple_scale -=.0125;if (ripple_scale <  0 ) ripple_scale =   0; break;
	case ']': ripple_scale +=.0125;if (ripple_scale > .45) ripple_scale = .45; break;
	case ';': logo_scale   -= .05; if (logo_scale   <  0 ) logo_scale   =   0; break;
	case '\'': logo_scale  += .05; if (logo_scale   >  .5) logo_scale   =  .5; break;
	case ',': twirl_angle  -= 0.1; if (twirl_angle  < -30) twirl_angle  = -30; break;
	case '.': twirl_angle  += 0.1; if (twirl_angle  >  30) twirl_angle  =  30; break;
    case 'f':
    case 'F':
    	fullscreen = !fullscreen;
    	if (fullscreen)
    		glutFullScreen();
    	else
    		glutReshapeWindow(WINDOWWIDE, WINDOWHIGH);
    	break;
    case 'm':
    case 'M':
    	showmesh = !showmesh;
		break;
    case 'r':
    case 'R':
    	rings = !rings;
		break;
    case 'w':
    case 'W':
    	wireframe = !wireframe;
		break;
    case 'h':
    case 'H':
    	help = !help;
		break;
    }
}


void specialkey(int key, int x, int y) {
    switch (key) {
	case GLUT_KEY_DOWN: tilt += 2.0; if (tilt > -40) tilt = -40;
		break;
	case GLUT_KEY_UP:   tilt -= 2.0; if (tilt < -90) tilt = -90;
		break;
    }
}

#pragma mark -
#pragma mark Mouse input
void motion(int x, int y) {
	if (click) {
		// convert window coord to new center
		float cx = (          x - winwide*.5+RTVASIZE)/(RTVASIZE*2);
		float cy = ((winhigh-y) - winhigh*.7+RTVASIZE)/(RTVASIZE*2);
		
		if (cx < 0) cx = 0;
		if (cx > 1) cx = 1;
		if (cy < 0) cy = 0;
		if (cy > 1) cy = 1;

		center[(click-1)*2+0] = cx;
		center[(click-1)*2+1] = cy;
		clickx = x; clicky = y;   	
  	}
}


void mouse(int button, int state, int x, int y) {
	int i;

    click = 0;
    clickx = x; clicky = y;

  	// hit detection
    if (state == GLUT_DOWN) {
    	for (i = 0; i < 2; i++) {
			int dx =          x  - winwide*.5+RTVASIZE - center[i*2+0]*RTVASIZE*2;
			int dy = (winhigh-y) - winhigh*.7+RTVASIZE - center[i*2+1]*RTVASIZE*2;
			
			if ((abs(dx) < 20) && (abs(dy) < 20)) {
				click = i+1;
				break;
			}
		}
	}    
}

#pragma mark -
#pragma mark Render

void drawString(GLint x, GLint y, const char *string) {
	int i;
	
	glPushAttrib(GL_TRANSFORM_BIT | GL_CURRENT_BIT);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	glOrtho(0, winwide, 0, winhigh, -10.0, 10.0);
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	glColor3f(.2f, 1.0f, .2f);
	
	glRasterPos2i(x, y);
	
	int len = (int)strlen(string);
	for ( i = 0; i < len; i++) {
		glutBitmapCharacter(GLUT_BITMAP_8_BY_13, string[i]);
	}
	
	glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	glPopAttrib();
}

void drawHelp(void) {
	drawString(10,winhigh-10,"Press the following keys:");
	drawString(10,winhigh-(13*1+10), " up and down arrow for tilt");
	drawString(10,winhigh-(13*2+10), " W toggles wireframe");
	drawString(10,winhigh-(13*3+10), " M toggles mesh");
	drawString(10,winhigh-(13*4+10), " F toggles fullscreen");
	drawString(10,winhigh-(13*5+10), " R toggles rings");
	drawString(10,winhigh-(13*6+10), " { or } adj ripple freq");
	drawString(10,winhigh-(13*7+10), " [ or ] adj ripple scale");
	drawString(10,winhigh-(13*8+10), " \' or ; adj logo scale");
	drawString(10,winhigh-(13*9+10), " , or . adj twirl angle");
	drawString(10,winhigh-(13*10+10)," H toggles help");
	
}

// rendertovertexarray() is the heart of this demo
// it moves the ripple by decrementing ripple_xlate
// binds to the FBO to render into 
// it renders the logo texture and the ripple shaders, 
// if rings are enable it renders those as well to 
// the FBO, then it uses the PBO extension to 
// read the FBO via glReadPixels and place the result 
// into the VBO 

void rendertovertexarray(void) {
	static float ripple_xlate = 0;
	
	// animate parameters
	ripple_xlate -= 0.1;

	glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, fb);
	reshape(RTVASIZE, RTVASIZE, 1);
	
	// draw ripples
	glLoadIdentity();
	glBindTexture(GL_TEXTURE_2D, logo);
	glUseProgramObjectARB(ripple_pr);	
	glUniform4fvARB(get_location(ripple_pr, "centers"), 4, center);
	glUniform1fARB(get_location(ripple_pr, "ripple_freq"),  ripple_freq);
	glUniform1fARB(get_location(ripple_pr, "ripple_scale"), ripple_scale);
	glUniform1fARB(get_location(ripple_pr, "ripple_xlate"), ripple_xlate);
	glUniform1fARB(get_location(ripple_pr, "logo_scale"), logo_scale);
	glUniform1fARB(get_location(ripple_pr, "twirl_angle"), twirl_angle);
	glBegin(GL_QUADS);
		glTexCoord2f(0, 0); glVertex2f(0,        0);
		glTexCoord2f(1, 0); glVertex2f(RTVASIZE, 0);
		glTexCoord2f(1, 1); glVertex2f(RTVASIZE, RTVASIZE);
		glTexCoord2f(0, 1); glVertex2f(0,        RTVASIZE);
	glEnd();
	glUseProgramObjectARB(0);
	
	if (rings) {
		// draw 3D rings into blue channel
		static float rot1 = 0, rot2 = 0;
		rot1 += 0.5; rot2 += 0.3;
		
		reshape(RTVASIZE, RTVASIZE, 0);
		glClear(GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgramObjectARB(blue_pr);	
		glColorMask(0, 0, 1, 0);
		glLoadIdentity();
		glTranslatef(0, 0, -5.5);
		glScalef(2.5, 2.5, 2.5);
		glRotatef(rot1, 0, 1, 1);
		glRotatef(rot2, 1, 0, 0);
		glCallList(dlist[0]);
		glRotatef(rot1*1.5, -1, 1, 0);
		glRotatef(rot2*1.5,  0, 0, 1);
		glCallList(dlist[1]);
		glRotatef(rot1*2.0, -1, 0, 1);
		glRotatef(rot2*2.0,  0, 1, 0);
		glCallList(dlist[2]);
		glColorMask(1, 1, 1, 1);
		glUseProgramObjectARB(0);
		glDisable(GL_DEPTH_TEST);	
	}
#pragma mark PBO read back
	// now that rendering is done, read the pixel colors into the VBO mesh
	glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, vbo);	
	glReadPixels(0, 0, RTVASIZE, RTVASIZE, GL_RGBA, GL_FLOAT, NULL);
	glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
}

// the display() function calls rendertovertexarray()
// which renders to an FBO, reads it back with a PBO 
// into a VBO. display() uses the FBO as a texture for 
// reference and if showmesh is enabled it renders the 
// VBO using the height to color 1D texture lookup.
// Optionally it uses drawHelp() and drawString()
// to overlay a help reference text indicating 
// the available key presses and their functionality. 

void display() {
#pragma mark render to FBO
	// render fragment data to FBO and readback to VBO via PBO
	rendertovertexarray();

	// visualize the FBO texture for reference
	glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, 0);

	reshape(winwide, winhigh, 1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity ();
	
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tx);
	glEnable(GL_TEXTURE_RECTANGLE_ARB);
	glBegin(GL_QUADS);
		glTexCoord2f(0,        0);        glVertex2f(winwide*.5-RTVASIZE, winhigh*.7-RTVASIZE);
		glTexCoord2f(RTVASIZE, 0);        glVertex2f(winwide*.5+RTVASIZE, winhigh*.7-RTVASIZE);
		glTexCoord2f(RTVASIZE, RTVASIZE); glVertex2f(winwide*.5+RTVASIZE, winhigh*.7+RTVASIZE);
		glTexCoord2f(0,        RTVASIZE); glVertex2f(winwide*.5-RTVASIZE, winhigh*.7+RTVASIZE);
	glEnd();
	glDisable(GL_TEXTURE_RECTANGLE_ARB);

#pragma mark render to VBO
	if (showmesh) {
		// render vertex array as triangle mesh
		reshape(winwide, winhigh, 0);
		glLoadIdentity();
		glTranslatef(0, -0.75, -3.5);
		glRotatef(tilt, 1, 0, 0);
		glScalef(3, 3, 1);
		glTranslatef(-0.5, -0.5, 0);
		
		glEnable(GL_TEXTURE_1D);
		glEnable(GL_TEXTURE_GEN_S);
		glEnable(GL_DEPTH_TEST);
		glEnable(GL_FOG);
		if (wireframe)
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		glEnableClientState(GL_VERTEX_ARRAY);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, ibo);
		glVertexPointer (4, GL_FLOAT, 0, 0);
		glDrawElements(GL_TRIANGLES, (RTVASIZE-1)*(RTVASIZE-1)*6, GL_UNSIGNED_INT, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glDisableClientState (GL_VERTEX_ARRAY);
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		glDisable(GL_FOG);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_TEXTURE_GEN_S);
		glDisable(GL_TEXTURE_1D);
	}
	
	if (help)
		drawHelp();
	
	glutSwapBuffers();
	glError();
	
	glutPostRedisplay();
}

#pragma mark -
#pragma mark Initialization

void initGL() {
#pragma mark Check OpenGL extensions
	// check core version and extensions we're interested in
	{
		int supported = 1;
		
		sscanf((char *)glGetString(GL_VERSION), "%f", &glCoreVersion);
		printf("%s %s\n", (char *)glGetString(GL_RENDERER), (char *)glGetString(GL_VERSION));
		printf("----------------------------------\n");
		
		int i, j = sizeof(extension)/sizeof(glExtension);
		for (i = 0; i < j; i++) {
			extension[i].supported = glutExtensionSupported(extension[i].name) |
									 (extension[i].promoted && (glCoreVersion >= extension[i].promoted));
			printf("%-32s %d\n", extension[i].name, extension[i].supported);
			// float pixels not required, but geometry will clamp to [0..1]
			if (i != APPLE_float_pixels) supported &= extension[i].supported;
		}	
		printf("----------------------------------\n");
		
		if (!supported) {
			printf("Required functionality not available on this renderer.\n");
			// A robust app could fall back to other methods here.
			// This is just a demo, so quit.
			exit(0);
		}
	}
	
	// constant state
	{
		float s_plane[] = { 0, 0, 1, 0 };
		GLfloat fogc[4] = { .3, .4, .5, 1 };
		glClearColor(.3, .4, .5, 1);
		glFogi(GL_FOG_MODE, GL_LINEAR);
		glFogf(GL_FOG_START, 2.0);
		glFogf(GL_FOG_END, 5.5);
		glFogfv(GL_FOG_COLOR, fogc);
		glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
		glTexGenfv(GL_S, GL_OBJECT_PLANE, s_plane);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	}
#pragma mark FBO setup
	// setup FBO to render into
	{
		// use float pixels if available
		GLenum internal = extension[APPLE_float_pixels].supported?GL_RGBA_FLOAT32_APPLE:GL_RGBA8;
		GLenum type     = extension[APPLE_float_pixels].supported?GL_FLOAT:GL_UNSIGNED_BYTE;
		GLenum status;
		int loop;
		
		glGenFramebuffersEXT(1, &fb);
		glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, fb);

		// renderbuffer depth attachment
		glGenRenderbuffersEXT(1, &rb);
		glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rb);
		glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, RTVASIZE, RTVASIZE);
		glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, rb);

		// float rectangle texture color attachment
		// note: some hardware only supports float textures with the rectangle target
		glGenTextures(1, &tx);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tx);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		for (loop = 0; loop < 2; loop++) {
			glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, internal, RTVASIZE, RTVASIZE, 0, GL_RGBA, type, NULL);
			glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, tx, 0);
			
			status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
			if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
				if ((loop == 0) && (internal == GL_RGBA_FLOAT32_APPLE)) {
					// if float texture attachment didn't work, try again with integer.
					// note: some hardware did not fully support float attachments in the 10.4.3 FBO implementation
					internal = GL_RGBA8;
				}
				else {
					printf("Error, FBO status %04x\n", (int)status);
					exit(0);
				}
			}
		}
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	}
#pragma mark VBO setup	
	// setup buffer object for 4 floats per item
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, RTVASIZE*RTVASIZE*4*sizeof(GLfloat), NULL, GL_STREAM_COPY);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// setup buffer index
	{
		int x, y, i = 0;
		GLuint *indices = malloc((RTVASIZE-1)*(RTVASIZE-1)*6 * sizeof(GLuint));

		for (y = 0; y < RTVASIZE-1; y++) {
			for (x = 0; x < RTVASIZE-1; x++) {
				indices[i+0] = x+y*RTVASIZE+0;
				indices[i+1] = x+y*RTVASIZE+1;
				indices[i+2] = x+y*RTVASIZE+RTVASIZE;
				indices[i+3] = x+y*RTVASIZE+1;
				indices[i+4] = x+y*RTVASIZE+RTVASIZE+1;
				indices[i+5] = x+y*RTVASIZE+RTVASIZE;
				i += 6;
			}
		}

		glGenBuffers(1, &ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, ibo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER_ARB, (RTVASIZE-1)*(RTVASIZE-1)*6 * sizeof(GLuint), indices, GL_STATIC_DRAW);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		free(indices);
	}
	
	// setup display lists
	{
		dlist[0] = glGenLists(1);
		glNewList(dlist[0], GL_COMPILE);
			glutSolidTorus(0.09, 0.9, 40, 50);
		glEndList();
		dlist[1] = glGenLists(1);
		glNewList(dlist[1], GL_COMPILE);
			glutSolidTorus(0.09, 0.65, 30, 40);
		glEndList();
		dlist[2] = glGenLists(1);
		glNewList(dlist[2], GL_COMPILE);
			glutSolidTorus(0.09, 0.4, 20, 30);
		glEndList();
	}
#pragma mark Shader setup	
	// setup shaders
	{
		ripple_vs = load_shader(GL_VERTEX_SHADER_ARB, ripplevs);
		ripple_fs = load_shader(GL_FRAGMENT_SHADER_ARB, ripplefs);
		ripple_pr = glCreateProgramObjectARB();
		glAttachObjectARB(ripple_pr, ripple_vs);
		glAttachObjectARB(ripple_pr, ripple_fs);
		link_program(ripple_pr);
		glUseProgramObjectARB(ripple_pr);	
		glUniform1iARB(get_location(ripple_pr, "unit0"), 0);
		glUniform1iARB(get_location(ripple_pr, "unit1"), 1);
		glUniform1fARB(get_location(ripple_pr, "rtvasize"), (float)RTVASIZE);
		glUseProgramObjectARB(0);	
		center[0] = center[1] = center[2] = center[3] = 0.5;

		blue_fs = load_shader(GL_FRAGMENT_SHADER_ARB, bluefs);
		blue_pr = glCreateProgramObjectARB();
		glAttachObjectARB(blue_pr, blue_fs);
		link_program(blue_pr);
	}
#pragma mark Texture setup
	// setup textures
	{
		// use float pixels if available
		GLenum internal = extension[APPLE_float_pixels].supported?GL_RGBA_FLOAT32_APPLE:GL_LUMINANCE8;
		const int atansize = RTVASIZE;
		float *atandata = malloc(atansize * atansize * sizeof(float));
		unsigned char heightmap[] = { 255, 255, 255, 0, 0, 255 };	// heightfield mapped from white to blue
		int x, y;
	
		// generate atan2 lookup table (this is to avoid atan in shader which is expensive on some hardware.)
		for (y = 0; y < atansize; y++) {
			for (x = 0; x < atansize; x++) {
				atandata[y*atansize+x] = (atan2(x-atansize*0.5, y-atansize*0.5) + M_PI) / (M_PI*2.0);
			}
		}
		// place the atan2 lookup table on GL_TEXTURE1
		glGenTextures(1, &atanmap);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, atanmap);
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, internal, atansize, atansize, 0, GL_LUMINANCE, GL_FLOAT, atandata);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glActiveTexture(GL_TEXTURE0);
		free(atandata);

		// This is the one dimension texture for height to color mapping
		glGenTextures(1, &hmap);
		glBindTexture(GL_TEXTURE_1D, hmap);
		glTexImage1D(GL_TEXTURE_1D, 0, GL_RGB8, 2, 0, GL_RGB, GL_UNSIGNED_BYTE, heightmap);
		glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);

		logo = load_texure("logo.png");
	}
	
	glError();	
}


int main(int argc, char **argv) {
	glutInit(&argc, argv);
	glutInitWindowSize(WINDOWWIDE, WINDOWHIGH);
	glutInitDisplayString("double rgb depth samples=4");
	glutCreateWindow("PBO Render To Vertex Array");

	setcwd();
	initGL();

	glutReshapeFunc(reshapeGLUT);
	glutDisplayFunc (display);	
    glutKeyboardFunc(key);
    glutSpecialFunc(specialkey);
    glutMouseFunc(mouse);
    glutMotionFunc(motion);
	glutMainLoop();

	return 0;
}

