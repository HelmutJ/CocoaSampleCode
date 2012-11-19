/*
     File: Scene.m
 Abstract: Scene.h
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
*/
#import "Scene.h"
#include <math.h>

#define DEG2RAD(x) (0.0174532925 * (x))
#define RAD2DEG(x) (57.295779578 * (x))

#define	kSquareSize				500		// needs to be the size of the custom NIB object
#define kSourceCircleRadius		10.0
#define kListenerCircleRadius	20.0
#define kDefaultDistance		175.0
#define NUM_BUFFERS_SOURCES		5		// this test app has 4 Source Objects and 4 Buffer Objects

#define kCaptureSamples				44100 * 5 // capture 5 seconds of data at 44k
#define kCaptureSourceIndex			4
#define	kCapturedAudioSampleRate	44100

#define kListenerIndex			5

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Globals
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ALCdevice	*gCaptureDevice = NULL;
UInt8*		gCaptureData = NULL;

float		gListenerPos[3] = {0.0,  0.0,  0.0};		// default position is centered
float		gListenerDirection = 0;
int			gSourceDirectionOnOff[NUM_BUFFERS_SOURCES] = {0, 0, 0, 0, 0};
float		gSourceAngle[NUM_BUFFERS_SOURCES] = {225, 315, 135, 45, 180}; // each source is now facing the center
float		gSourcePos[NUM_BUFFERS_SOURCES][3]  = {	{kDefaultDistance, 0.0, -kDefaultDistance},
														{kDefaultDistance, 0.0, kDefaultDistance},
														{-kDefaultDistance , 0.0, -kDefaultDistance},
														{-kDefaultDistance , 0.0, kDefaultDistance},
														{0.0 , 0.0, -kDefaultDistance}		}; 

char *	gSourceFile[NUM_BUFFERS_SOURCES - 1];			// only the 1st 4 sources use data from a file
ALuint	gBuffer[NUM_BUFFERS_SOURCES];
ALuint	gSource[NUM_BUFFERS_SOURCES];

float gSourceInnerConeAngle[NUM_BUFFERS_SOURCES] = {90, 90, 90, 90, 90};
float gSourceOuterConeAngle[NUM_BUFFERS_SOURCES] = {180, 180, 180, 180, 180};

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Extension API Procs
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALvoid	AL_APIENTRY	(*alMacOSXRenderChannelCountProcPtr) (const ALint value);
ALvoid  alMacOSXRenderChannelCountProc(const ALint value)
{
	static	alMacOSXRenderChannelCountProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alMacOSXRenderChannelCountProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alMacOSXRenderChannelCount");
    }
    
    if (proc)
        proc(value);

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALvoid	AL_APIENTRY	(*alcMacOSXRenderingQualityProcPtr) (const ALint value);
ALvoid  alcMacOSXRenderingQualityProc(const ALint value)
{
	static	alcMacOSXRenderingQualityProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcMacOSXRenderingQualityProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXRenderingQuality");
    }
    
    if (proc)
        proc(value);

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALvoid	AL_APIENTRY	(*alcMacOSXMixerOutputRateProcPtr) (const ALdouble value);
ALvoid  alcMacOSXMixerOutputRateProc(const ALdouble value)
{
	static	alcMacOSXMixerOutputRateProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcMacOSXMixerOutputRateProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXMixerOutputRate");
    }
    
    if (proc)
        proc(value);

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALdouble (*alcMacOSXGetMixerOutputRateProcPtr) ();
ALdouble  alcMacOSXGetMixerOutputRateProc()
{
	static	alcMacOSXGetMixerOutputRateProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcMacOSXGetMixerOutputRateProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXGetMixerOutputRate");
    }
    
    if (proc)
        return proc();

    return 0.0;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
	static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef OSStatus	(*alcASASetSourceProcPtr)	(const ALuint property, ALuint source, ALvoid *data, ALuint dataSize);
OSStatus  alcASASetSourceProc(const ALuint property, ALuint source, ALvoid *data, ALuint dataSize)
{
    OSStatus	err = noErr;
	static	alcASASetSourceProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcASASetSourceProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcASASetSource");
    }
    
    if (proc)
        err = proc(property, source, data, dataSize);
    return (err);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef OSStatus	(*alcASASetListenerProcPtr)	(const ALuint property, ALvoid *data, ALuint dataSize);
OSStatus  alcASASetListenerProc(const ALuint property, ALvoid *data, ALuint dataSize)
{
    OSStatus	err = noErr;
	static	alcASASetListenerProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alcASASetListenerProcPtr) alcGetProcAddress(NULL, "alcASASetListener");
    }
    
    if (proc)
        err = proc(property, data, dataSize);
    return (err);
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef ALCdevice*	(*alcCaptureOpenDeviceProcPtr)	(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
ALCdevice*  alcCaptureOpenDeviceProc(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize)
{
    ALCdevice*	device = NULL;
	device = alcCaptureOpenDevice (devicename, frequency, format, buffersize);
    return (device);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef void	(*alcCaptureStartProcPtr)	(ALCdevice*	device);
void  alcCaptureStartProc(ALCdevice* device)
{
	alcCaptureStart (device);	

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef void	(*alcCaptureSamplesProcPtr)	(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);
void  alcCaptureSamplesProc(ALCdevice *device, ALCvoid *buffer, ALCsizei samples)
{
	alcCaptureSamples (device, buffer, samples);	

    return;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initialize OpenAL -Get an Audio Device and Set Current OpenAL Context
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ALvoid*		gStaticBufferData = NULL;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void TeardownOpenAL()
{
    ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
	ALuint		returnedNames[NUM_BUFFERS_SOURCES];

	// Delete the Sources
    alDeleteSources(NUM_BUFFERS_SOURCES, returnedNames);
	// Delete the Buffers
    alDeleteBuffers(NUM_BUFFERS_SOURCES, returnedNames);
	
	//Get active context
    context = alcGetCurrentContext();
    //Get device for active context
    device = alcGetContextsDevice(context);
    //Release context
    alcDestroyContext(context);
    //Close device
    alcCloseDevice(device);
	if (gStaticBufferData)
		free(gStaticBufferData);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	InitializeBuffers() 
{
	ALenum  error = AL_NO_ERROR;
	ALenum  format;
	ALvoid* data;
	ALsizei size;
	ALsizei freq;
	UInt32	i;
	
	// only the 1st 4 sources get data from a file. The 5th source gets data from capture
	for (i = 0; i < NUM_BUFFERS_SOURCES - 1; i ++)
	{	
		//Get the current path to the audio file (which is contained in the application bundle) 
		NSString* fileString = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%s", gSourceFile[i]] ofType:@"wav"];
		// get some audio data from a wave file
		CFURLRef fileURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)fileString, NULL);
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		
		CFRelease(fileURL);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error loading %s: ", gSourceFile[i]);
			exit(1);
		}
		
		if (i == 0)
		{
			// use the static buffer data API once for testing
			gStaticBufferData = (ALvoid*)malloc(size);
			memcpy(gStaticBufferData, data, size);
			alBufferDataStaticProc(gBuffer[i], format, gStaticBufferData, size, freq);
		}
		else
		{
			// Attach Audio Data to OpenAL Buffer
			alBufferData(gBuffer[i], format, data, size, freq);
		}
		
		// Release the audio data
		free(data);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error unloading %s: ", gSourceFile[i]);
		}	
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void InitializeSourcesAndPlay() 
{
	UInt32 i;
	ALenum error = AL_NO_ERROR;
	alGetError(); // Clear the error
    
	for (i = 0; i < NUM_BUFFERS_SOURCES; i++)
	{
		// Turn Looping ON
		alSourcei(gSource[i], AL_LOOPING, AL_TRUE);
		// Set Source Position
		alSourcefv(gSource[i], AL_POSITION, gSourcePos[i]);
		// Set Source Reference Distance
		alSourcef(gSource[i],AL_REFERENCE_DISTANCE, 5.0f);

		// only load data and start playing the non capture sources
		if (i < NUM_BUFFERS_SOURCES-1)
		{
			// attach OpenAL Buffer to OpenAL Source
			alSourcei(gSource[i], AL_BUFFER, gBuffer[i]);
			// Start Playing Sound
			alSourcePlay(gSource[i]);
		}
	}
			
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("Error attaching buffer to source");
		exit(1);
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// SCENE class
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@implementation Scene

- (id) init
{
	if((self = [super init])) {
		
		mHasASAExtension = false;
		mHasInput = false;
		
		//4 WAV files in the application bundle resources
		gSourceFile[0] = "sound_engine";
		gSourceFile[1] = "sound_voices";
		gSourceFile[2] = "sound_bubbles";
		gSourceFile[3] = "sound_electric";
	
		mCurrentObject = -1;
		mCenterOffset = kSquareSize/2.0;
		mVelocityScaler = 0.0;
		mAngle = 0.0;
		mListenerElevation = 0.0;

		mSourceOn[0] = 1;
		mSourceOn[1] = 1;
		mSourceOn[2] = 1;
		mSourceOn[3] = 1;
		mSourceOn[4] = 0; // capture

		mSourceDirection[0] = 0.0;
		mSourceDirection[1] = 0.0;
		mSourceDirection[2] = 0.0;
		mSourceDirection[3] = 0.0;
		mSourceDirection[4] = 0.0; // capture

		mSourceVelocityScaler[0] = 0.0;
		mSourceVelocityScaler[1] = 0.0;
		mSourceVelocityScaler[2] = 0.0;
		mSourceVelocityScaler[3] = 0.0;
		mSourceVelocityScaler[4] = 0.0; // capture

		mSourceOuterConeGain[0] = 0.0;
		mSourceOuterConeGain[1] = 0.0;
		mSourceOuterConeGain[2] = 0.0;
		mSourceOuterConeGain[3] = 0.0;
		mSourceOuterConeGain[4] = 0.0; // capture
		
		mSourceInnerConeAngle[0] = 90.0;
		mSourceInnerConeAngle[1] = 90.0;
		mSourceInnerConeAngle[2] = 90.0;
		mSourceInnerConeAngle[3] = 90.0;
		mSourceInnerConeAngle[4] = 90.0; // capture

		mSourceOuterConeAngle[0] = 180.0;
		mSourceOuterConeAngle[1] = 180.0;
		mSourceOuterConeAngle[2] = 180.0;
		mSourceOuterConeAngle[3] = 180.0;
		mSourceOuterConeAngle[4] = 180.0; // capture

		[self initOpenAL];
		[self setListenerOrientation:0 : NULL : NULL];
		[self setListenerVelocity:0 : NULL : NULL];
		[self setListenerGain:0.5];
	}
	return self;
}

- (void) dealloc {
	TeardownOpenAL();
	[super dealloc];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//draws a simple filled circle using quick glu calls
static void drawCircle(GLdouble x, GLdouble y, GLdouble r, GLfloat red, GLfloat grn, GLfloat blu){

	// A GRADIENT CIRCLE - looks better
	glPushMatrix();
		glTranslatef(x, y, 0.0);
		glBegin(GL_TRIANGLE_FAN);

			glColor3f(red, grn, blu);		
			glVertex3f(0.0, 0.0, 0.0);		
			{
				UInt32	i;
				float	x, y;
				float	stepAngle = 20;
				double	theAngle = -90;
				for (i = 0; i <= 18; i++)
				{
					glColor3f(red/2, grn/2, blu/2);		// gradient
					float	rads = DEG2RAD(theAngle);
					x = cos(rads) * r;
					y = sin(rads) * r;
					glVertex3f(x, y, 0.0);
					theAngle += stepAngle;
					glColor3f(red, grn, blu);			// gradient
				}
			}

		glEnd();
	glPopMatrix();
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) drawObjects {
		
	// layer the objects correctly
	if (mListenerElevation > 0)
	{
		[self drawSources];
		[self drawListener];
	}
	else
	{
		[self drawListener];
		[self drawSources];
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) drawListener {
	
	float	elevationSizeScaler = (abs(mListenerElevation) / 200.0)/2; // -1 to 1
	// translate that to .5 to 1.5
	if (mListenerElevation > 0)
		elevationSizeScaler = 1 + elevationSizeScaler;
	else
		elevationSizeScaler = 1 - elevationSizeScaler;
	
	// draw a triangle (nose)
	glPushMatrix();
		glTranslatef(gListenerPos[0] + mCenterOffset, -gListenerPos[2] + mCenterOffset, 0.0);
		//Rotate to show the listeners current orientation
		glRotatef(gListenerDirection, 0.0, 0.0, -1.0);
		glBegin(GL_TRIANGLES);
			glColor3f(0.0, 1.0, 0.0);
			glVertex3f(-6.0 * elevationSizeScaler, 0.0, 0.0);
			glVertex3f(6.0 * elevationSizeScaler, 0.0, 0.0);
			glColor3f(1.0, 0.0, 0.0);
			glVertex3f(0.0, 35.0 * elevationSizeScaler, 0.0);
		glEnd();
	glPopMatrix();


	// ears
	glPushMatrix();
		glTranslatef(gListenerPos[0] + mCenterOffset, -gListenerPos[2] + mCenterOffset, 0.0);
		//Rotate to show the listeners current orientation
		glRotatef(gListenerDirection, 0.0, 0.0, -1.0);
		glBegin(GL_QUADS);
			glColor3f(0.0, 0.0, 0.8);
			glVertex3f(-25.0 * elevationSizeScaler, 8.0 * elevationSizeScaler, 0.0);
			glVertex3f(-25.0 * elevationSizeScaler, -8.0 * elevationSizeScaler, 0.0);
			glVertex3f(24.5 * elevationSizeScaler, -8.0 * elevationSizeScaler, 0.0);
			glVertex3f(24.5 * elevationSizeScaler, 8.0 * elevationSizeScaler, 0.0);
		glEnd();
	glPopMatrix();
	
	// minor adjustments to position circle
	drawCircle(gListenerPos[0]- .5 + mCenterOffset, -gListenerPos[2] - 1 + mCenterOffset, 20 * elevationSizeScaler, 0 , 0, 1);

	if (mListenerElevation != 0.0)
		drawCircle(gListenerPos[0] + mCenterOffset, -gListenerPos[2] + mCenterOffset, 3, 0 , 0, .6);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define	kArcSteps			16
#define	kInnerArcRadius		32	// larger but partially transparent
#define	kOuterArcRadius		26	// smaller with gradient

- (void) drawSourceWithDirection :(int)inTag
{
	
	glEnable(GL_BLEND); // blend the cones so both can be seen, top cone (INNER) is partially transparent
						// bottom cone (OUTER) has a gradient
				
	// CONE DRAWING - OUTER
	if (gSourceDirectionOnOff[inTag])
	{
		float	x, z;
		[self getSourceDirections:inTag : &x : &z];

		glPushMatrix();
			glTranslatef((gSourcePos[inTag][0] + mCenterOffset) + x, (-gSourcePos[inTag][2] + mCenterOffset) + z, 0.0);
			glRotatef(gSourceAngle[inTag], 0.0, 0.0, -1.0);
			glBegin(GL_TRIANGLE_FAN);
				glColor3f(0.0, 0.5, 0.0);		
				glVertex3f(0.0, 0.0, 0.0);		
				{
					UInt32	i;
					float	x, y;
					float	stepAngle = mSourceOuterConeAngle[inTag]/kArcSteps;
					double	theAngle = -(mSourceOuterConeAngle[inTag]/2) + 90;
					for (i = 0; i <= kArcSteps; i++)
					{
						glColor3f(0.0, 0.2, 0.0);		// gradient
						float	rads = DEG2RAD(theAngle);
						x = cos(rads) * kOuterArcRadius;
						y = sin(rads) * kOuterArcRadius;

						glVertex3f(x, y, 0.0);
						theAngle += stepAngle;
						glColor3f(0.0, 0.8, 0.0);		// gradient
					}
				}


			glEnd();
		glPopMatrix();
	}

	// CONE DRAWING - INNER
	if (gSourceDirectionOnOff[inTag])
	{
		float	x, z;
		[self getSourceDirections:inTag : &x : &z];

		glPushMatrix();
			glTranslatef((gSourcePos[inTag][0] + mCenterOffset) + x, (-gSourcePos[inTag][2] + mCenterOffset) + z, 0.0);
			glRotatef(gSourceAngle[inTag], 0.0, 0.0, -1.0);
			glBegin(GL_TRIANGLE_FAN);
				glColor4f(0.0, 1.0, 0.0, .4); // transparency (.4)
				glVertex3f(0.0, 0.0, 0.0);
				{
					UInt32	i;
					float	x, y;
					float	stepAngle = mSourceInnerConeAngle[inTag]/kArcSteps;
					double	theAngle = -(mSourceInnerConeAngle[inTag]/2) + 90;
					for (i = 0; i <= kArcSteps; i++)
					{
						float	rads = DEG2RAD(theAngle);
						x = cos(rads) * kInnerArcRadius;
						y = sin(rads) * kInnerArcRadius;
						glVertex3f(x, y, 0.0);
						theAngle += stepAngle;
					}
				}

			glEnd();
		glPopMatrix();
	}
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);			// blend the cones
	glDisable(GL_BLEND);										// blending is done

	// draw direction triangle if there is any velocity setting above zero
	if (mSourceVelocityScaler[inTag] > 0)
	{
		float	triangleLength = kSourceCircleRadius*2;
		triangleLength += (mSourceVelocityScaler[inTag]/686.0) * (kSourceCircleRadius*2);
		
		glPushMatrix();
			glTranslatef(gSourcePos[inTag][0] + mCenterOffset, -gSourcePos[inTag][2] + mCenterOffset, 0.0);
			glRotatef(gSourceAngle[inTag], 0.0, 0.0, -1.0);
			glBegin(GL_TRIANGLES);
				glColor3f(0.0, 1.0, 0.0);
				glVertex3f(-4.0, 0.0, 0.0);
				glVertex3f(4.0, 0.0, 0.0);
				glColor3f(1.0, 0.0, 0.0);
				glVertex3f(0.0, triangleLength, 0.0);
			glEnd();
		glPopMatrix();
	}
	
	//minor adjustments to position circle
	if (mSourceOn[inTag] == 0)
	{
		// draw a gray circle if source is not playing
		drawCircle(gSourcePos[inTag][0] + mCenterOffset, -gSourcePos[inTag][2] + mCenterOffset, kSourceCircleRadius, .5 , .5, .5); // capture circle is different color
	}
	else
	{
		if (inTag == kCaptureSourceIndex)
			drawCircle(gSourcePos[inTag][0] + mCenterOffset, -gSourcePos[inTag][2] + mCenterOffset, kSourceCircleRadius, 1 , 1, 0); // capture circle is different color
		else
			drawCircle(gSourcePos[inTag][0] + mCenterOffset, -gSourcePos[inTag][2] + mCenterOffset, kSourceCircleRadius, 1 , 0, 0);
	}

	if (gSourcePos[inTag][1] != 0.0)
		drawCircle(gSourcePos[inTag][0] + mCenterOffset, -gSourcePos[inTag][2]+ mCenterOffset, 3, .5 , 0, 0);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) drawSources
{
	//draw sources as 4 red circles
	[self drawSourceWithDirection: 0];
	[self drawSourceWithDirection: 1];
	[self drawSourceWithDirection: 2];
	[self drawSourceWithDirection: 3];

	[self drawSourceWithDirection: kCaptureSourceIndex]; // capture
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void) resetCurrentObject
{
	//set current object to -1 to designate no object selected.
	mCurrentObject = -1;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(int) selectCurrentObject:(NSPoint *)point
{
	//find the object (circle) that contains the point
	//return -1 if none are found
	
	if(mCurrentObject != -1)
	  return mCurrentObject;
	  
	if([self pointInCircle:point x:gSourcePos[0][0] + mCenterOffset y:-gSourcePos[0][2] + mCenterOffset r:kSourceCircleRadius]){
		mCurrentObject = 0;
	}else if	([self pointInCircle:point x:gSourcePos[1][0] + mCenterOffset y:-gSourcePos[1][2] + mCenterOffset r:kSourceCircleRadius])
	    mCurrentObject = 1;
	else if	([self pointInCircle:point x:gSourcePos[2][0] + mCenterOffset y:-gSourcePos[2][2] + mCenterOffset r:kSourceCircleRadius])
	    mCurrentObject = 2;
	else if	([self pointInCircle:point x:gSourcePos[3][0] + mCenterOffset y:-gSourcePos[3][2] + mCenterOffset r:kSourceCircleRadius])
	    mCurrentObject = 3;	
	else if	([self pointInCircle:point x:gSourcePos[4][0] + mCenterOffset y:-gSourcePos[4][2] + mCenterOffset r:kSourceCircleRadius])
	    mCurrentObject = kCaptureSourceIndex;		// CAPTURE SOURCE
	else if	([self pointInCircle:point x:gListenerPos[0] + mCenterOffset y:-gListenerPos[2] + mCenterOffset r:kListenerCircleRadius])
	    mCurrentObject = kListenerIndex;
				
	return mCurrentObject;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// need to detect if point is in a source circle
// if so, return the source pos ID
// if not, return -1
- (bool) pointInCircle:(NSPoint *)point x:(float)x  y:(float)y  r:(float)r
{
   float x1 =point->x;
   float y1 = point->y;

   float dist  =0;
   //calculate distance from the center of the circle to the point clcked
   dist =(((x1 - x )*(x1 - x ))   +   ((y1 - y)*(y1 - y)));

	//Here we can test this for each of the sources
	
	//if the distance is less than the radius (squared), then the point is inside the circle
	if (dist <= r*r)
	  return TRUE;
	else
	 return FALSE;	
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void) setObjectPosition:(NSPoint *)point
{	
	if(mCurrentObject < kListenerIndex){
		[self setSourcePositionFromPoint:point];
	} 
	else if (mCurrentObject == kListenerIndex ) //listener
	{
		[self setListenerPosition:point];
	}
	
	// NOTIFY: Post a notification that object mCurrentObject has moved so the coordinate text can be updated
	[[NSNotificationCenter defaultCenter] postNotificationName: @"OALNotify" object: self];	
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) getCurrentObjectPosition:(int*)outCurObject : (float*) outX : (float*) outZ
{
	if(mCurrentObject < kListenerIndex){
		if(outX) *outX = gSourcePos[mCurrentObject][0];
		if(outX) *outZ = gSourcePos[mCurrentObject][2];
	} 
	else if (mCurrentObject == kListenerIndex ) //listener
	{
		if(outX) *outX = gListenerPos[0];
		if(outX) *outZ = gListenerPos[2];

	}
	if(outCurObject) *outCurObject = mCurrentObject;
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) getObjectPosition:(int)inObject : (float*) outX : (float*) outZ;
{
	if(inObject < kListenerIndex){
		if(outX) *outX = gSourcePos[inObject][0];
		if(outX) *outZ = gSourcePos[inObject][2];
	} 
	else if (inObject == kListenerIndex ) //listener
	{
		if(outX) *outX = gListenerPos[0];
		if(outX) *outZ = gListenerPos[2];

	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initialize OpenAL Context, Buffers, Listener & Sources
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) initOpenAL {
		
	ALenum			error;
	ALCcontext		*newContext = NULL;
	ALCdevice		*newDevice = NULL;

	// Create a new OpenAL Device
	// Pass NULL to specify the systemÕs default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		newContext = alcCreateContext(newDevice, 0);
		if (newContext != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(newContext);

			// Create some OpenAL Buffer Objects
			alGenBuffers(NUM_BUFFERS_SOURCES, gBuffer);
			if((error = alGetError()) != AL_NO_ERROR) {
				printf("Error Generating Buffers: ");
				exit(1);
			}

			// Create some OpenAL Source Objects
			alGenSources(NUM_BUFFERS_SOURCES, gSource);
			if(alGetError() != AL_NO_ERROR) 
			{
				printf("Error generating sources! \n");
				exit(1);
			}
		}
	}

	// Capture
	if (alcIsExtensionPresent( NULL, "ALC_EXT_CAPTURE" ))
	{
		// Setup a Capture Device
		gCaptureDevice = alcCaptureOpenDeviceProc( NULL, kCapturedAudioSampleRate, AL_FORMAT_MONO16, kCaptureSamples );
		if(gCaptureDevice)
		{
			// Capture is supported and there is an input device
			alcCaptureStartProc(gCaptureDevice);		

			mSourceOn[4] = 1; // capture
			mHasInput = true;
		}
		else
			mHasInput = false;	// Capture is supported but there is no input device
	}
	else
		mHasInput = false;	// Capture Not Supported by this OAL version
	
	// Reverb and Effects
	if (alcIsExtensionPresent( NULL, "ALC_EXT_ASA" ))
		mHasASAExtension = true;
	else
		mHasASAExtension = false;
		
	alGetError();
	
	InitializeBuffers();
	InitializeSourcesAndPlay();
}

- (bool) hasInput
{
	return mHasInput;
}

- (bool) hasASAExtension
{
	return mHasASAExtension;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Orientation
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setListenerOrientation: (float) angle : (float*) outX : (float*) outZ
{
	mAngle = angle;
	ALenum  error = AL_NO_ERROR;
	float	rads = DEG2RAD(mAngle);
	float	orientation[6] = {	0.0, 0.0, -1.0,    // direction
								0.0, 1.0, 0.0	}; //up	
								 
	orientation[0] = cos(rads);
	orientation[1] = sin(rads);		// No Change to the Z vector
	gListenerDirection = RAD2DEG(atan2(orientation[1], orientation[0]));
	
	// Change OpenAL Listener's Orientation
	orientation[0] = sin(rads);
	orientation[1] = 0.0;			// No Change to the Y vector
	orientation[2] = -cos(rads);	

	alListenerfv(AL_ORIENTATION, orientation);
	if((error = alGetError()) != AL_NO_ERROR)
		printf("Error Setting Listener Orientation");
		
	// set the listener velocity as well, in this app we are always syncing the velocity to the direction that the listener is facing
	[self setListenerVelocity: mVelocityScaler : outX : outZ];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Listener Velocity Gain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setListenerVelocity:(float) inVelocity : (float*) outX : (float*) outZ
{
	mVelocityScaler = inVelocity;
	
	ALenum  error = AL_NO_ERROR;
	float	rads = DEG2RAD(mAngle);
	float	velocity[3] = {	0.0, 0.0, 0.0}; //up	
								 	
	// Change OpenAL Listener's Orientation
	velocity[0] = sin(rads) * mVelocityScaler;
	velocity[1] = 0.0;			// No Change to the Y vector
	velocity[2] = -cos(rads) * mVelocityScaler;
	
	if (outX) *outX = velocity[0];	
	if (outZ) *outZ = velocity[2];	

	alListenerfv(AL_VELOCITY, velocity);
	if((error = alGetError()) != AL_NO_ERROR)
		printf("Error Setting Listener Velocity");

}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Position
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setSourcePositionFromPoint:(NSPoint *)point
{
	gSourcePos[mCurrentObject][0] = point->x - mCenterOffset;
	gSourcePos[mCurrentObject][2] = -point->y + mCenterOffset;	// top view only in this demo!
	
	alSourcefv(gSource[mCurrentObject], AL_POSITION, gSourcePos[mCurrentObject]);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setSourcePositionX:(int) inTag : (float)inX
{
	gSourcePos[inTag][0] = inX;
	alSourcefv(gSource[inTag], AL_POSITION, gSourcePos[inTag]);
	[self drawSourceWithDirection :inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setSourcePositionY:(int) inTag : (float)inY
{
	gSourcePos[inTag][1] = inY;
	alSourcefv(gSource[inTag], AL_POSITION, gSourcePos[inTag]);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setSourcePositionZ:(int) inTag : (float)inZ
{
	gSourcePos[inTag][2] = inZ;
	alSourcefv(gSource[inTag], AL_POSITION, gSourcePos[inTag]);
	[self drawSourceWithDirection :inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setListenerPosition:(NSPoint *) point
{
	gListenerPos[0] = point->x - mCenterOffset;
	gListenerPos[1] = mListenerElevation;
	gListenerPos[2] = -point->y + mCenterOffset;				// top view only in this demo!

	alListenerfv(AL_POSITION, gListenerPos);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setListenerElevation: (float)elevation
{
	mListenerElevation = elevation;
	
	gListenerPos[1] = mListenerElevation;
	// do not change x or z 
	
	alListenerfv(AL_POSITION, gListenerPos);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setListenerPositionX: (float)inX
{
	gListenerPos[0] = inX;
	alListenerfv(AL_POSITION, gListenerPos);
	[self drawListener];
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)setListenerPositionZ: (float)inX
{
	gListenerPos[2] = inX;
	alListenerfv(AL_POSITION, gListenerPos);
	[self drawListener];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourcePlayState:(int)inTag :(int)inCheckBoxValue
{
	if (mSourceOn[inTag] == inCheckBoxValue)
		return;
	
	mSourceOn[inTag] = inCheckBoxValue;
	
	if (mSourceOn[inTag])
		alSourcePlay(gSource[inTag]);
	else
		alSourceStop(gSource[inTag]);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Pitch
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourcePitch:(int)inTag :(float)inPitch
{
	alSourcef(gSource[inTag], AL_PITCH, inPitch);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Gain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceGain:(int)inTag :(float)inGain
{
	alSourcef(gSource[inTag], AL_GAIN, inGain);
	// alSourcef (gSource[inTag], AL_SEC_OFFSET, 1.0); // quick way to test the set offset API until controls can be added to UI
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Rolloff
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceRolloffFactor:(int)inTag :(float)inRolloff
{
	alSourcef(gSource[inTag], AL_ROLLOFF_FACTOR, inRolloff);
}

- (float) getSourceRolloffFactor:(int)inTag
{
	float	ro;
	alGetSourcef(gSource[inTag], AL_ROLLOFF_FACTOR, &ro);
	return ro;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Reference Distance
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceReferenceDistance:(int)inTag :(float)inReferenceDistance
{
	alSourcef(gSource[inTag], AL_REFERENCE_DISTANCE, inReferenceDistance);
}

- (float) getSourceReferenceDistance:(int)inTag
{
	float	rd;
	alGetSourcef(gSource[inTag], AL_REFERENCE_DISTANCE, &rd);
	return rd;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Max Distance
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceMaxDistance:(int)inTag :(float)inMaxDistance
{
	alSourcef(gSource[inTag], AL_MAX_DISTANCE, inMaxDistance);
}

- (float) getSourceMaxDistance:(int)inTag
{
	float	md;
	alGetSourcef(gSource[inTag], AL_MAX_DISTANCE, &md);
	return md;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Direction & Velocity
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceVelocity:(int)inTag :(float) inVelocity
{
	mSourceVelocityScaler[inTag] = inVelocity;

	float	velocities[3];
	velocities[1] = 0;	// No Change to the Y vector
	[self getSourceVelocities: inTag : &velocities[0] : &velocities[2]];
	
	alSourcefv(gSource[inTag], AL_VELOCITY, velocities);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceDirection:(int)inTag
{
	float	directions[3];
	directions[1] = 0;		// No Change to the Y vector
	
	if (gSourceDirectionOnOff[inTag] == false)
	{
		directions[0] = 0;
		directions[2] = 0;
		alSourcefv(gSource[inTag], AL_DIRECTION, directions);
		
		alSourcef(gSource[inTag], AL_CONE_INNER_ANGLE, 360.0);
		alSourcef(gSource[inTag], AL_CONE_OUTER_ANGLE, 360.0);
		alSourcef(gSource[inTag], AL_CONE_OUTER_GAIN, 0.0);
	}
	else
	{
		[self getSourceDirections: inTag : &directions[0] : &directions[2]];
		
		alSourcefv(gSource[inTag], AL_DIRECTION, directions);
		alSourcef(gSource[inTag], AL_CONE_INNER_ANGLE, 90	);
		alSourcef(gSource[inTag], AL_CONE_OUTER_ANGLE, 180);
		alSourcef(gSource[inTag], AL_CONE_OUTER_GAIN, mSourceOuterConeGain[inTag]	);
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceOuterConeGain:(int)inTag :(float) inGain
{
	mSourceOuterConeGain[inTag] = inGain;
	
	alSourcef(gSource[inTag], AL_CONE_OUTER_GAIN, mSourceOuterConeGain[inTag]);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceInnerConeAngle:(int)inTag :(float) inAngle
{
	mSourceInnerConeAngle[inTag] = inAngle;
	
	alSourcef(gSource[inTag], AL_CONE_INNER_ANGLE, mSourceInnerConeAngle[inTag]);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceOuterConeAngle:(int)inTag :(float) inAngle
{
	mSourceOuterConeAngle[inTag] = inAngle;
	
	alSourcef(gSource[inTag], AL_CONE_OUTER_ANGLE, mSourceOuterConeAngle[inTag]);
	[self drawSourceWithDirection :inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceDirectionOnOff:(int)inTag :(int)inCheckBoxValue
{
	if (gSourceDirectionOnOff[inTag] == inCheckBoxValue)
		return;
	
	gSourceDirectionOnOff[inTag] = inCheckBoxValue;
	[self setSourceDirection: inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceAngle:(int)inTag :(float)inAngle
{
	gSourceAngle[inTag] = inAngle;

	[self setSourceVelocity: inTag : mSourceVelocityScaler[inTag]];
	[self setSourceDirection: inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) getSourceVelocities:(int)inTag : (float*) outX : (float*) outZ
{
	float	rads = DEG2RAD(gSourceAngle[inTag]);
									 
	if (outX) *outX = sin(rads) * mSourceVelocityScaler[inTag];
	if (outZ) *outZ = -cos(rads) * mSourceVelocityScaler[inTag];
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) getSourceDirections:(int)inTag : (float*) outX : (float*) outZ
{
	float	rads = DEG2RAD(gSourceAngle[inTag]);
									 
	if (outX) *outX = sin(rads);		
	if (outZ) *outZ = -cos(rads);
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Listener Gain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setListenerGain:(float)inGain
{
	alListenerf(AL_GAIN, inGain);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Render Channels
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setRenderChannels:(int)inCheckBoxValue
{
	// Global Setting:
	// Used to Force OpenAL to render to stereo, even if the user's default audio hw is multichannel

	UInt32		setting = (inCheckBoxValue == 0) ? alcGetEnumValue(NULL, "ALC_RENDER_CHANNEL_COUNT_MULTICHANNEL") : alcGetEnumValue(NULL, "ALC_RENDER_CHANNEL_COUNT_STEREO");
	
	alMacOSXRenderChannelCountProc((const ALint) setting);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Render Quality
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setRenderQuality:(int)inCheckBoxValue
{
	// Global Setting:
	// Used to turn on HRTF Rendering when OpenAL is rendering to stereo
	
	UInt32		setting = (inCheckBoxValue == 0) ? alcGetEnumValue(NULL, "ALC_SPATIAL_RENDERING_QUALITY_LOW") : alcGetEnumValue(NULL, "ALC_SPATIAL_RENDERING_QUALITY_HIGH");
	
	alcMacOSXRenderingQualityProc((const ALint) setting);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Reverb Level
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceReverb:(int)inTag :(float)inReverbSendLevel
{
	ALfloat		level = inReverbSendLevel;
	alcASASetSourceProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_SEND_LEVEL"), gSource[inTag], &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Reverb Level
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceOcclusion:(int)inTag :(float)inLevel
{
	ALfloat		level = inLevel;
	alcASASetSourceProc(alcGetEnumValue(NULL, "ALC_ASA_OCCLUSION"), gSource[inTag], &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Source Reverb Level
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSourceObstruction:(int)inTag :(float)inReverbSendLevel
{
	ALfloat		level = inReverbSendLevel;
	alcASASetSourceProc(alcGetEnumValue(NULL, "ALC_ASA_OBSTRUCTION"), gSource[inTag], &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Global Reverb Level
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setGlobalReverb :(float)inReverbLevel
{
	ALfloat		level = inReverbLevel;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_GLOBAL_LEVEL"), &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Reverb ON
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbOn:(int)inCheckBoxValue
{
	UInt32		setting = (inCheckBoxValue == 0) ? 0 : 1;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_ON"), &setting, sizeof(setting));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbEQGain:(float)inLevel
{
	ALfloat		level = inLevel;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_GAIN"), &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbEQBandwidth:(float)inLevel
{
	ALfloat		level = inLevel;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_BANDWITH"), (ALvoid *) &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbEQFrequency:(float)inLevel
{
	ALfloat		level = inLevel;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_EQ_FREQ"), &level, sizeof(level));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbRoomType:(int)inTag controlIndex:(int) inIndex title:(NSString*) inTitle
{
	UInt32		roomtype = inTag;
	UInt32		roomIndex = inIndex;
	if (roomIndex < 12)
	{
		// the 1st 12 menu items have the proper reverb constant in the tag value
		alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_ROOM_TYPE"), &roomtype, sizeof(roomtype));
	}
	else
	{
		const char *fullPathToFile;
		fullPathToFile =[[[NSBundle mainBundle] pathForResource:inTitle ofType:@"aupreset" inDirectory:@"ReverbPresets"]UTF8String];

		alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_PRESET"), (void *) fullPathToFile, strlen(fullPathToFile));
	}
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setReverbQuality:(int)inTag
{
	UInt32		quality = inTag;
	alcASASetListenerProc(alcGetEnumValue(NULL, "ALC_ASA_REVERB_QUALITY"), &quality, sizeof(quality));
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Distance Model
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setDistanceModel:(int)inTag
{
	alDistanceModel(inTag);	
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Doppler Factor
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setDopplerFactor :(float)inValue
{
	alDopplerFactor(inValue);
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Speed Of Sound
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) setSpeedOfSound :(float)inValue
{
	alSpeedOfSound(inValue);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CAPTURE
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) captureSamples :(int*)outValue
{
	if (!gCaptureData)
	{
		gCaptureData = (UInt8*) calloc(1, kCaptureSamples * 2); // 1 second of 44k mono 16 bit data
	}
	
	alGetError(); // reset

	alcGetIntegerv( gCaptureDevice, ALC_CAPTURE_SAMPLES, 1, outValue );

	// get some new sample, free gCaptureData if this fails
	alcCaptureSamplesProc( gCaptureDevice, gCaptureData, *outValue );

	UInt32	err = alGetError();
	if (err)
		return;

	alSourceStop(gSource[4]);
	alSourcei(gSource[4], AL_BUFFER, AL_NONE);
	
	ALint	count = 1;
	while (count > 0)
		alGetSourcei(gSource[4], AL_BUFFERS_QUEUED, &count);

	alBufferData(gBuffer[4], AL_FORMAT_MONO16, gCaptureData, *outValue * 2, kCapturedAudioSampleRate);
	alSourcei(gSource[4], AL_BUFFER, gBuffer[4]);
	alSourcePlay(gSource[4]);
}

@end