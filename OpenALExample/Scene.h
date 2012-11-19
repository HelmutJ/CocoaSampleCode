/*
     File: Scene.h
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
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

#include "MyOpenALSupport.h"

@interface Scene : NSObject {
@public

	bool	mHasInput;
	bool	mHasASAExtension;
	int		mCurrentObject;
	float	mCenterOffset;
	float	mVelocityScaler;
	float	mListenerElevation;
	float	mAngle;					// listener direction in degrees
	int		mSourceOn[5];			// play state
	float	mSourceDirection[5];	// angle in degrees
	float	mSourceVelocityScaler[5];
	float	mSourceOuterConeGain[5];
	float	mSourceInnerConeAngle[5];
	float	mSourceOuterConeAngle[5];
}

- (id)	 init;
- (void) initOpenAL; 

// OpenGLView
- (void) drawObjects;
- (void) drawListener;
- (void) drawSourceWithDirection :(int)inTag;
- (void) drawSources;
- (void) resetCurrentObject;
- (bool) pointInCircle:(NSPoint *)point x:(float)x  y:(float)y  r:(float)r;
- (void) setObjectPosition:(NSPoint *)point;
- (int)	 selectCurrentObject:(NSPoint *)point;
- (void) setListenerPosition:(NSPoint *)point;
- (void) setSourcePositionFromPoint:(NSPoint *)point;
- (void )setSourcePositionX:(int) inTag : (float)inX;
- (void )setSourcePositionY:(int) inTag : (float)inY;
- (void )setSourcePositionZ:(int) inTag : (float)inZ;

- (void) getCurrentObjectPosition:(int*)outCurObject : (float*) outX : (float*) outZ;
- (void) getObjectPosition:(int)inObject : (float*) outX : (float*) outZ;

// Context Settings

- (void) setListenerPositionX: (float)inX;
- (void) setListenerPositionZ: (float)inZ;
- (void) setListenerOrientation: (float)angle : (float*) outX : (float*) outZ;
- (void) setListenerElevation: (float)elevation;
- (void) setListenerVelocity:(float) inVelocity : (float*) outX : (float*) outZ;
- (void) setListenerGain :(float)inGain;

- (void) setDopplerFactor :(float)inValue;
- (void) setSpeedOfSound :(float)inValue;
- (void) setDistanceModel:(int)inTag;

- (void) setReverbOn:(int)inCheckBoxValue;
- (void) setGlobalReverb :(float)inReverbLevel;
- (void) setReverbRoomType:(int)inTag controlIndex:(int) inIndex title:(NSString*) inTitle;
- (void) setReverbQuality:(int)inTag;
- (void) setReverbEQGain:(float)inLevel;
- (void) setReverbEQBandwidth:(float)inLevel;
- (void) setReverbEQFrequency:(float)inLevel;

- (void) setRenderChannels:(int)inCheckBoxValue;
- (void) setRenderQuality:(int)inCheckBoxValue;

// Source Settings

- (void) setSourcePlayState:(int)inTag :(int)inCheckBoxValue;

- (void) setSourcePitch:(int)inTag :(float)inPitch;
- (void) setSourceGain:(int)inTag :(float)inGain;

- (void) setSourceRolloffFactor:(int)inTag :(float)inRolloff;
- (float) getSourceRolloffFactor:(int)inTag;

- (void) setSourceReferenceDistance:(int)inTag :(float)inReferenceDistance;
- (float) getSourceReferenceDistance:(int)inTag;

- (void) setSourceMaxDistance:(int)inTag :(float)inMaxDistance;
- (float) getSourceMaxDistance:(int)inTag;

- (void) setSourceDirectionOnOff:(int)inTag :(int)inCheckBoxValue;
- (void) setSourceReverb:(int)inTag :(float)inReverbSendLevel;
- (void) setSourceOcclusion:(int)inTag :(float)inLevel;
- (void) setSourceObstruction:(int)inTag :(float)inLevel;

- (void) getSourceVelocities:(int)inTag : (float*) outX : (float*) outZ;
- (void) getSourceDirections:(int)inTag : (float*) outX : (float*) outZ;

- (void) setSourceAngle:(int)inTag :(float)inAngle;
- (void) setSourceDirection:(int)inTag;
- (void) setSourceVelocity:(int)inTag :(float) inVelocity;

- (void) setSourceOuterConeGain:(int)inTag :(float) inGain;
- (void) setSourceInnerConeAngle:(int)inTag :(float) inAngle;
- (void) setSourceOuterConeAngle:(int)inTag :(float) inAngle;


- (void) captureSamples :(int*)outValue;
- (bool) hasInput;
- (bool) hasASAExtension;

@end
