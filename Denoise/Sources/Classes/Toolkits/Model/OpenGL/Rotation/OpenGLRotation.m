//---------------------------------------------------------------------------
//
//	File: OpenGLRotation.m
//
//  Abstract: OpenGL class for managing a 3D objects rotation.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2009, 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLRotation.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const GLdouble kRotationFrequency = 30.0;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLRotationData
{
	GLfloat   roll;
	GLfloat   pitch;
	GLdouble  time;
	GLdouble  frequency;
};

typedef struct OpenGLRotationData  OpenGLRotationData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static OpenGLRotationDataRef OpenGLRotationCreate(const GLdouble frequency)
{
    OpenGLRotationDataRef pRotation = (OpenGLRotationDataRef)calloc(1, sizeof(OpenGLRotationData));
    
    if( pRotation != NULL )
    {
        pRotation->time  = -1.0f;
        pRotation->roll  =  0.0f;
        pRotation->pitch =  0.0f;
        
        pRotation->frequency = frequency;
    } // if
    else
    {
        NSLog( @">> ERROR: OpenGL Rotation - Allocating Memory For OpenGL Rotation Data Failed!" );
    } // else
	
	return( pRotation );
} // init

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLRotationDelete(OpenGLRotationDataRef pRotation) 
{
	if( pRotation != NULL )
	{
		free( pRotation );
		
		pRotation = NULL;
	} // if
} // OpenGLRotationDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilties

//---------------------------------------------------------------------------

static GLdouble OpenGLRotationUpdateTime(OpenGLRotationDataRef pRotation) 
{
	GLdouble  timeDelta = 0.0;
	GLdouble  timeNow   = (GLdouble)[NSDate timeIntervalSinceReferenceDate];
	
	if( pRotation->time < 0 )
	{
		timeDelta = 0;
	} // if
	else
	{
		timeDelta = timeNow - pRotation->time;
	} // else
	
	pRotation->time = timeNow;
    
	return( timeDelta );
} // OpenGLRotationUpdateTime

//------------------------------------------------------------------------

static void OpenGLRotationUpdatePitch(OpenGLRotationDataRef pRotation) 
{
	if( pRotation->pitch < -45.0f )
	{
		pRotation->pitch = -45.0f;
	} // if
	else if( pRotation->pitch > 90.0f )
	{
		pRotation->pitch = 90.0f;
	} // else if
	
	glRotatef( pRotation->pitch, 1.0f, 0.0f, 0.0f );
} // OpenGLRotationUpdatePitch

//------------------------------------------------------------------------

static void OpenGLRotationUpdateRoll(OpenGLRotationDataRef pRotation) 
{
	GLdouble timeDelta = OpenGLRotationUpdateTime(pRotation);
	
	pRotation->roll += pRotation->frequency * timeDelta;
	
	if( pRotation->roll >= 360.0f )
	{
		pRotation->roll -= 360.0f;
	} // if
	
	glRotatef( pRotation->roll, 0.0f, 1.0f, 0.0f );
	
	// Increment the mpRotation angle
	
	pRotation->roll += 0.2f;
} // OpenGLRotationUpdateRoll

//------------------------------------------------------------------------

static void OpenGLRotationUpdate(OpenGLRotationDataRef pRotation) 
{
    OpenGLRotationUpdatePitch(pRotation);
    OpenGLRotationUpdateRoll(pRotation);
} // OpenGLRotationUpdate

//------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessors

//---------------------------------------------------------------------------

static inline void OpenGLRotationSetFrequency(const GLdouble frequency,
                                              OpenGLRotationDataRef pRotation)
{
    pRotation->frequency = (frequency > 0.0) ? frequency : kRotationFrequency;
} // OpenGLRotationSetFrequency

//------------------------------------------------------------------------

static inline void OpenGLRotationSetRotation(const NSPoint *pEndPoint,
                                             const NSPoint *pStartPoint,
                                             OpenGLRotationDataRef pRotation)                                            
{
    if( (pEndPoint != NULL) && (pStartPoint != NULL) )
    {
        pRotation->roll  -= pEndPoint->x - pStartPoint->x;
        pRotation->pitch += pEndPoint->y - pStartPoint->y;
    } // if
} // OpenGLRotationSetRotation

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLRotation

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if( self )
	{
		mpRotation = OpenGLRotationCreate(kRotationFrequency);
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (id) initRotationWithFrequency:(const GLdouble)theFrequency
{
	self = [super init];
	
	if( self )
	{
		mpRotation = OpenGLRotationCreate(theFrequency);
	} // if
	
	return( self );
} // initRotationWithFrequency

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	OpenGLRotationDelete(mpRotation);
	
    [super dealloc];
} // dealloc

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//------------------------------------------------------------------------

- (void) update
{
    OpenGLRotationUpdate(mpRotation);
} // update

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//------------------------------------------------------------------------

- (void) setFrequency:(const GLdouble)theFrequency
{
    OpenGLRotationSetFrequency(theFrequency, mpRotation);
} // setFrequency

//------------------------------------------------------------------------

- (void) setRotation:(const NSPoint *)theEndPoint
               start:(const NSPoint *)theStartPoint
{
	OpenGLRotationSetRotation(theEndPoint, theStartPoint, mpRotation);
} // setPitch

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
