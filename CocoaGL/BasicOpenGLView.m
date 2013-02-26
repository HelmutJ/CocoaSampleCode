//
// File:		BasicOpenGLView.m
//
// Abstract:	Basic OpenGL View with Renderer information
//
// Version:		1.1 - minor fixes.
//				1.0 - Original release.
//				
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//

#import "BasicOpenGLView.h"
#import "GLCheck.h"
#import "trackball.h"
#import "drawinfo.h"

// ==================================

// simple cube data
GLint cube_num_vertices = 8;

GLfloat cube_vertices [8][3] = {
{1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}, {-1.0, 1.0, 1.0},
{1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0} };

GLfloat cube_vertex_colors [8][3] = {
{1.0, 1.0, 1.0}, {1.0, 1.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 1.0, 1.0},
{1.0, 0.0, 1.0}, {1.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0} };

GLint num_faces = 6;

short cube_faces [6][4] = {
{3, 2, 1, 0}, {2, 3, 7, 6}, {0, 1, 5, 4}, {3, 0, 4, 7}, {1, 2, 6, 5}, {4, 5, 6, 7} };

recVec gOrigin = {0.0, 0.0, 0.0};

// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE;
GLboolean gPan = GL_FALSE;
GLboolean gTrackball = GL_FALSE;
BasicOpenGLView * gTrackingViewInfo = NULL;

// time and message info
CFAbsoluteTime gMsgPresistance = 10.0f;

// error output
GLString * gErrStringTex;
float gErrorTime;

// ==================================

#pragma mark ---- OpenGL Capabilities ----

// GL configuration info globals
// see GLCheck.h for more info
GLCaps * gDisplayCaps = NULL; // array of GLCaps
CGDisplayCount gNumDisplays = 0;

static void getCurrentCaps (void)
{
 	// Check for existing opengl caps here
	// This can be called again with same display caps array when display configurations are changed and
	//   your info needs to be updated.  Note, if you are doing dynmaic allocation, the number of displays
	//   may change and thus you should always reallocate your display caps array.
	if (gDisplayCaps && HaveOpenGLCapsChanged (gDisplayCaps, gNumDisplays)) { // see if caps have changed
		free (gDisplayCaps);
		gDisplayCaps = NULL;
	}
	if (!gDisplayCaps) { // if we do not have caps
		CheckOpenGLCaps (0, NULL, &gNumDisplays); // will just update number of displays
		gDisplayCaps = (GLCaps*) malloc (sizeof (GLCaps) * gNumDisplays);
		CheckOpenGLCaps (gNumDisplays, gDisplayCaps, &gNumDisplays);
		initCapsTexture (gDisplayCaps, gNumDisplays); // (re)init the texture for printing caps
	}
}

#pragma mark ---- Utilities ----

static CFAbsoluteTime gStartTime = 0.0f;

// set app start time
static void setStartTime (void)
{	
	gStartTime = CFAbsoluteTimeGetCurrent ();
}

// ---------------------------------

// return float elpased time in seconds since app start
static CFAbsoluteTime getElapsedTime (void)
{	
	return CFAbsoluteTimeGetCurrent () - gStartTime;
}

#pragma mark ---- Error Reporting ----

// error reporting as both window message and debugger string
void reportError (char * strError)
{
    NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
    [attribs setObject: [NSFont fontWithName: @"Monaco" size: 9.0f] forKey: NSFontAttributeName];
    [attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];

	gErrorTime = getElapsedTime ();
	NSString * errString = [NSString stringWithFormat:@"Error: %s (at time: %0.1f secs).", strError, gErrorTime];
	NSLog (@"%@\n", errString);
	if (gErrStringTex)
		[gErrStringTex setString:errString withAttributes:attribs];
	else {
		gErrStringTex = [[GLString alloc] initWithString:errString withAttributes:attribs withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:0.3f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:0.8f]];
	}
}

// ---------------------------------

// if error dump gl errors to debugger string, return error
GLenum glReportError (void)
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err)
		reportError ((char *) gluErrorString (err));
	return err;
}

#pragma mark ---- OpenGL Utils ----

// ---------------------------------

// draw our simple cube based on current modelview and projection matrices
static void drawCube (GLfloat fSize)
{
	long f, i;
	if (1) {
		glColor3f (1.0, 0.5, 0.0);
		glBegin (GL_QUADS);
		for (f = 0; f < num_faces; f++)
			for (i = 0; i < 4; i++) {
				glColor3f (cube_vertex_colors[cube_faces[f][i]][0], cube_vertex_colors[cube_faces[f][i]][1], cube_vertex_colors[cube_faces[f][i]][2]);
				glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
			}
		glEnd ();
	}
	if (1) {
		glColor3f (0.0, 0.0, 0.0);
		for (f = 0; f < num_faces; f++) {
			glBegin (GL_LINE_LOOP);
				for (i = 0; i < 4; i++)
					glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
			glEnd ();
		}
	}
}

// ===================================

@implementation BasicOpenGLView

// pixel format definition
+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16, // 16 bit depth buffer
        (NSOpenGLPixelFormatAttribute)nil
    };
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

// ---------------------------------

// update the projection matrix based on camera and view info
- (void) updateProjection
{
	GLdouble ratio, radians, wd2;
	GLdouble left, right, top, bottom, near, far;

    [[self openGLContext] makeCurrentContext];

	// set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians 
	wd2 = near * tan(radians);
	ratio = camera.viewWidth / (float) camera.viewHeight;
	if (ratio >= 1.0) {
		left  = -ratio * wd2;
		right = ratio * wd2;
		top = wd2;
		bottom = -wd2;	
	} else {
		left  = -wd2;
		right = wd2;
		top = wd2 / ratio;
		bottom = -wd2 / ratio;	
	}
	glFrustum (left, right, bottom, top, near, far);
	[self updateCameraString];
}

// ---------------------------------

// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
	// move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
			
	// if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);
	else {
	}
	// accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
	// object itself rotating applied after camera rotation
	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
	rRot[0] = 0.0f; // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
	rRot[1] = 0.0f;
	rRot[2] = 0.0f;
	[self updateCameraString];
}

// ---------------------------------

// handles resizing of GL need context update and if the window dimensions change, a
// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	
	// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) {
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
		[self updateInfoString];
	}
}

// ---------------------------------

// move camera in z axis
-(void)mouseDolly: (NSPoint) location
{
	GLfloat dolly = (gDollyPanStartPoint[1] -location.y) * -camera.viewPos.z / 300.0f;
	camera.viewPos.z += dolly;
	if (camera.viewPos.z == 0.0) // do not let z = 0.0
		camera.viewPos.z = 0.0001;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}
	
// ---------------------------------
	
// move camera in x/y plane
- (void)mousePan: (NSPoint) location
{
	GLfloat panX = (gDollyPanStartPoint[0] - location.x) / (900.0f / -camera.viewPos.z);
	GLfloat panY = (gDollyPanStartPoint[1] - location.y) / (900.0f / -camera.viewPos.z);
	camera.viewPos.x -= panX;
	camera.viewPos.y -= panY;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

// ---------------------------------

// sets the camera data to initial conditions
- (void) resetCamera
{
   camera.aperture = 40;
   camera.rotPoint = gOrigin;

   camera.viewPos.x = 0.0;
   camera.viewPos.y = 0.0;
   camera.viewPos.z = -10.0;
   camera.viewDir.x = -camera.viewPos.x; 
   camera.viewDir.y = -camera.viewPos.y; 
   camera.viewDir.z = -camera.viewPos.z;

   camera.viewUp.x = 0;  
   camera.viewUp.y = 1; 
   camera.viewUp.z = 0;
}

// ---------------------------------

// given a delta time in seconds and current rotation accel, velocity and position, update overall object rotation
- (void) updateObjectRotationForTimeDelta:(CFAbsoluteTime)deltaTime
{
	// update rotation based on vel and accel
	float rotation[4] = {0.0f, 0.0f, 0.0f, 0.0f};
	GLfloat fVMax = 2.0;
	short i;
	// do velocities
	for (i = 0; i < 3; i++) {
		rVel[i] += rAccel[i] * deltaTime * 30.0;
		
		if (rVel[i] > fVMax) {
			rAccel[i] *= -1.0;
			rVel[i] = fVMax;
		} else if (rVel[i] < -fVMax) {
			rAccel[i] *= -1.0;
			rVel[i] = -fVMax;
		}
		
		rRot[i] += rVel[i] * deltaTime * 30.0;
		
		while (rRot[i] > 360.0)
			rRot[i] -= 360.0;
		while (rRot[i] < -360.0)
			rRot[i] += 360.0;
	}
	rotation[0] = rRot[0];
	rotation[1] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = rRot[1];
	rotation[1] = 0.0f; rotation[2] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = rRot[2];
	rotation[2] = 0.0f; rotation[3] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
}

// ---------------------------------

// per-window timer function, basic time based animation preformed here
- (void)animationTimer:(NSTimer *)timer
{
	BOOL shouldDraw = NO;
	if (fAnimate) {
		CFTimeInterval deltaTime = CFAbsoluteTimeGetCurrent () - time;
			
		if (deltaTime > 10.0) // skip pauses
			return;
		else {
			// if we are not rotating with trackball in this window
			if (!gTrackball || (gTrackingViewInfo != self)) {
				[self updateObjectRotationForTimeDelta: deltaTime]; // update object rotation
			}
			shouldDraw = YES; // force redraw
		}
	}
	time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
	// if we have current messages
	if (((getElapsedTime () - msgTime) < gMsgPresistance) || ((getElapsedTime () - gErrorTime) < gMsgPresistance))
		shouldDraw = YES; // force redraw
	if (YES == shouldDraw) 
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
}

#pragma mark ---- Text Drawing ----

// these functions create or update GLStrings one should expect to have to regenerate the image, bitmap and texture when the string changes thus these functions are not particularly light weight

- (void) updateInfoString
{ // update info string texture
	NSString * string = [NSString stringWithFormat:@"(%0.0f x %0.0f) \n%s \n%s", [self bounds].size.width, [self bounds].size.height, glGetString (GL_RENDERER), glGetString (GL_VERSION)];
	if (infoStringTex)
		[infoStringTex setString:string withAttributes:stanStringAttrib];
	else {
		infoStringTex = [[GLString alloc] initWithString:string withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.5f green:0.5f blue:0.5f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.8f alpha:0.8f]];
	}
}

// ---------------------------------

- (void) createHelpString
{
	NSString * string = [NSString stringWithFormat:@"Cmd-A: animate    Cmd-I: show info \n'h': toggle help    'c': toggle OpenGL caps"];
	helpStringTex = [[GLString alloc] initWithString:string withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.0f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.3f green:0.8f blue:0.3f alpha:0.8f]];
}

// ---------------------------------

- (void) createMessageString
{
	NSString * string = [NSString stringWithFormat:@"No messages..."];
	msgStringTex = [[GLString alloc] initWithString:string withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.5f green:0.5f blue:0.5f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.8f alpha:0.8f]];
}

// ---------------------------------

- (void) updateCameraString
{ // update info string texture
	static recCamera savedCamera; 
	
	// This is a compromise between a heavy comparison
	// and updating the camera texture when not needed
	// what is faster the comparison or the texture update
	// only empirical data on a particular configuration
	// will yield a real answer
	
	if  ( (savedCamera.viewPos.x == camera.viewPos.x) &&
		  (savedCamera.viewPos.y == camera.viewPos.y) &&
		  (savedCamera.viewPos.z == camera.viewPos.z) &&
		  (savedCamera.viewDir.x == camera.viewDir.x) &&
		  (savedCamera.viewDir.y == camera.viewDir.y) &&
		  (savedCamera.viewDir.z == camera.viewDir.z) &&
		  (savedCamera.aperture == camera.aperture) )
	{
		return; // Don't update texture! (which usually is more expensive than the comparison above)
	} else {
		NSString * string = [NSString stringWithFormat:@"Camera at (%0.1f, %0.1f, %0.1f) looking at (%0.1f, %0.1f, %0.1f) with %0.1f aperture", camera.viewPos.x, camera.viewPos.y, camera.viewPos.z, camera.viewDir.x, camera.viewDir.y, camera.viewDir.z, camera.aperture];
		if (camStringTex)
			[camStringTex setString:string withAttributes:stanStringAttrib];
		else {
			camStringTex = [[GLString alloc] initWithString:string withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.5f green:0.5f blue:0.5f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.8f alpha:0.8f]];
		}
	}
	
	savedCamera = camera;
}

// ---------------------------------

// draw text info using our GLString class for much more optimized text drawing
- (void) drawInfo
{	
	GLint matrixMode;
	GLboolean depthTest = glIsEnabled (GL_DEPTH_TEST);
	GLfloat height, width, messageTop = 10.0f;
	
	height = camera.viewHeight;
	width = camera.viewWidth;
		
	// set orthograhic 1:1  pixel transform in local view coords
	glGetIntegerv (GL_MATRIX_MODE, &matrixMode);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
		glLoadIdentity ();
		glMatrixMode (GL_MODELVIEW);
		glPushMatrix();
			glLoadIdentity ();
			glScalef (2.0f / width, -2.0f /  height, 1.0f);
			glTranslatef (-width / 2.0f, -height / 2.0f, 0.0f);
			
			glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
			[infoStringTex drawAtPoint:NSMakePoint (10.0f, height - [infoStringTex frameSize].height - 10.0f)];
			[camStringTex drawAtPoint:NSMakePoint (10.0f, messageTop)];
			messageTop += [camStringTex frameSize].height + 3.0f;

			if (fDrawHelp)
				[helpStringTex drawAtPoint:NSMakePoint (floor ((width - [helpStringTex frameSize].width) / 2.0f), floor ((height - [helpStringTex frameSize].height) / 3.0f))];
			
			if (fDrawCaps) {
				long renderer;
				[[self pixelFormat] getValues:&renderer forAttribute:NSOpenGLPFARendererID forVirtualScreen:[[self openGLContext] currentVirtualScreen]];
				drawCaps (gDisplayCaps, gNumDisplays, renderer, width);
			}

			// message string
			float currTime = getElapsedTime ();
			if ((currTime - msgTime) < gMsgPresistance) {
				GLfloat comp = (gMsgPresistance - getElapsedTime () + msgTime) * 0.1; // premultiplied fade
				glColor4f (comp, comp, comp, comp);
				[msgStringTex drawAtPoint:NSMakePoint (10.0f, messageTop)];
				messageTop += [msgStringTex frameSize].height + 3.0f;
			}
			// global error message
			if ((currTime - gErrorTime) < gMsgPresistance) {
				GLfloat comp = (gMsgPresistance - getElapsedTime () + gErrorTime) * 0.1; // premultiplied fade
				glColor4f (comp, comp, comp, comp);
				[gErrStringTex drawAtPoint:NSMakePoint (10.0f, messageTop)];
			}

		// reset orginal martices
		glPopMatrix(); // GL_MODELVIEW
		glMatrixMode (GL_PROJECTION);
	glPopMatrix();
	glMatrixMode (matrixMode);

	glDisable (GL_TEXTURE_RECTANGLE_EXT);
	glDisable (GL_BLEND);
	if (depthTest)
		glEnable (GL_DEPTH_TEST);
	glReportError ();
}

#pragma mark ---- IB Actions ----

-(IBAction) animate: (id) sender
{
	fAnimate = 1 - fAnimate;
	if (fAnimate)
		[animateMenuItem setState: NSOnState];
	else 
		[animateMenuItem setState: NSOffState];
}

// ---------------------------------

-(IBAction) info: (id) sender
{
	fInfo = 1 - fInfo;
	if (fInfo)
		[infoMenuItem setState: NSOnState];
	else
		[infoMenuItem setState: NSOffState];
	[self setNeedsDisplay: YES];
}

#pragma mark ---- Method Overrides ----

-(void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent characters];
    if ([characters length]) {
        unichar character = [characters characterAtIndex:0];
		switch (character) {
			case 'h':
				// toggle help
				fDrawHelp = 1 - fDrawHelp;
				[self setNeedsDisplay: YES];
				break;
			case 'c':
				// toggle caps
				fDrawCaps = 1 - fDrawCaps;
				[self setNeedsDisplay: YES];
				break;
		}
	}
}

// ---------------------------------

- (void)mouseDown:(NSEvent *)theEvent // trackball
{
    if ([theEvent modifierFlags] & NSControlKeyMask) // send to pan
		[self rightMouseDown:theEvent];
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) // send to dolly
		[self otherMouseDown:theEvent];
	else {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		location.y = camera.viewHeight - location.y;
		gDolly = GL_FALSE; // no dolly
		gPan = GL_FALSE; // no pan
		gTrackball = GL_TRUE;
		startTrackball (location.x, location.y, 0, 0, camera.viewWidth, camera.viewHeight);
		gTrackingViewInfo = self;
	}
}

// ---------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent // pan
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_FALSE; // no dolly
	gPan = GL_TRUE; 
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

// ---------------------------------

- (void)otherMouseDown:(NSEvent *)theEvent //dolly
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_TRUE;
	gPan = GL_FALSE; // no pan
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

// ---------------------------------

- (void)mouseUp:(NSEvent *)theEvent
{
	if (gDolly) { // end dolly
		gDolly = GL_FALSE;
	} else if (gPan) { // end pan
		gPan = GL_FALSE;
	} else if (gTrackball) { // end trackball
		gTrackball = GL_FALSE;
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	} 
	gTrackingViewInfo = NULL;
}

// ---------------------------------

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

// ---------------------------------

- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

// ---------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) {
		rollToTrackball (location.x, location.y, gTrackBallRotation);
		[self setNeedsDisplay: YES];
	} else if (gDolly) {
		[self mouseDolly: location];
		[self updateProjection];  // update projection matrix (not normally done on draw)
		[self setNeedsDisplay: YES];
	} else if (gPan) {
		[self mousePan: location];
		[self setNeedsDisplay: YES];
	}
}

// ---------------------------------

- (void)scrollWheel:(NSEvent *)theEvent
{
	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
	if (wheelDelta)
	{
		GLfloat deltaAperture = wheelDelta * -camera.aperture / 200.0f;
		camera.aperture += deltaAperture;
		if (camera.aperture < 0.1) // do not let aperture <= 0.1
			camera.aperture = 0.1;
		if (camera.aperture > 179.9) // do not let aperture >= 180
			camera.aperture = 179.9;
		[self updateProjection]; // update projection matrix
		[self setNeedsDisplay: YES];
	}
}

// ---------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

// ---------------------------------

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

// ---------------------------------

- (void) drawRect:(NSRect)rect
{		
	// setup viewport and prespective
	[self resizeGL]; // forces projection matrix update (does test for size changes)
	[self updateModelView];  // update model view matrix for object

	// clear our drawable
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// model view and projection matricies already set

	drawCube (1.5f); // draw scene
    if (fInfo)
		[self drawInfo];
		
	if ([self inLiveResize] && !fAnimate)
		glFlush ();
	else
		[[self openGLContext] flushBuffer];
	glReportError ();
}

// ---------------------------------

// set initial OpenGL state (current context is set)
// called after context is created
- (void) prepareOpenGL
{
    long swapInt = 1;

    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync

	// init GL stuff here
	glEnable(GL_DEPTH_TEST);

	glShadeModel(GL_SMOOTH);    
	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CCW);
	glPolygonOffset (1.0f, 1.0f);
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	[self resetCamera];
	shapeSize = 7.0f; // max radius of of objects

	// init fonts for use with strings
	NSFont * font =[NSFont fontWithName:@"Helvetica" size:12.0];
	stanStringAttrib = [[NSMutableDictionary dictionary] retain];
	[stanStringAttrib setObject:font forKey:NSFontAttributeName];
	[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[font release];
	
	// ensure strings are created
	[self createHelpString];
	[self createMessageString];

}
// ---------------------------------

// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes.  So be
// careful of doing too much here.
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
msgTime	= getElapsedTime ();
[msgStringTex setString:[NSString stringWithFormat:@"update at %0.1f secs", msgTime]  withAttributes:stanStringAttrib];
	[super update];
	if (![self inLiveResize])  {// if not doing live resize
		[self updateInfoString]; // to get change in renderers will rebuld string every time (could test for early out)
		getCurrentCaps (); // this call checks to see if the current config changed in a reasonably lightweight way to prevent expensive re-allocations
	}
}

// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	NSOpenGLPixelFormat * pf = [BasicOpenGLView basicPixelFormat];

	self = [super initWithFrame: frameRect pixelFormat: pf];
    return self;
}

// ---------------------------------

- (BOOL)acceptsFirstResponder
{
  return YES;
}

// ---------------------------------

- (BOOL)becomeFirstResponder
{
  return  YES;
}

// ---------------------------------

- (BOOL)resignFirstResponder
{
  return YES;
}

// ---------------------------------

- (void) awakeFromNib
{
	setStartTime (); // get app start time
	getCurrentCaps (); // get current GL capabilites for all displays
	
	// set start values...
	rVel[0] = 0.3; rVel[1] = 0.1; rVel[2] = 0.2; 
	rAccel[0] = 0.003; rAccel[1] = -0.005; rAccel[2] = 0.004;
	fInfo = 1;
	fAnimate = 1;
	time = CFAbsoluteTimeGetCurrent ();  // set animation time start time
	fDrawHelp = 1;

	// start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
}


@end
