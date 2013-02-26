//-------------------------------------------------------------------------
//
//	File: OpenGLTorusGenerator.cpp
//
//  Abstract: C++ class that implements a generator for an
//            ordinary torus (a surface having genus one).
//
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
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
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
//
// In here our implementation of an ordinary torus (a surface having genus
// one) will be taking advantage of its parametric representation.  That is
// to say,
//
//      x(theta, phi) = R cos(theta) + r cos(theta) cos(phi) 
//                    = ( R + r cos(phi) ) cos(theta)
//
//      y(theta, phi) = R sin(theta) + r sin(theta) cos(phi) 
//                    = ( R + r cos(phi) ) sin(theta)
//
//      z(theta, phi) = r sin(phi)
//
// where
//
//     {theta, phi} are parameters in the open interval [0, 2π);
//
//      R is the distance from the center of the tube to the center  
//        of the torus, i.e., the outer radii;
//
//      r is the radius of the tube, i.e., the inner radii.
//
// Equivalently, an equation in Cartesian coordinates for a torus 
// azimuthally (radially) symmetric about the z-axis is given by
//
//      { R - ( x^2 + y^2 )^(1/2) }^2 + z^2 = r^2
//
// Additionally, note that even though we have used a circle as the 
// generator for a torus, in general this need not be the case. In 
// fact, one can adopt an ellipse or any other conic section as the 
// generator.
//
//-------------------------------------------------------------------------

//------------------------------------------------------------------------

#include "OpenGLModelTypes.h"

#include "OpenGLTorusGenerator.hpp"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const GLdouble kTwoPi = 2.0 * M_PI;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

struct Vector 
{
	union 
	{
		GLdouble v[3];
		
		struct 
		{
			GLdouble x;
			GLdouble y;
			GLdouble z;
		}; // struct
	}; // union
}; // Vector

typedef struct Vector Vector;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

GLvoid Torus::ValidTorusModelType( const GLint theModelType )
{
	if ( theModelType == modelTypeSolid )
	{
		torus.modelType = modelTypeSolid;
	} // if
	else
	{
		torus.modelType = modelTypeWireFrame;
	} // else
} // Torus::ValidTorusModelType

//------------------------------------------------------------------------

GLvoid Torus::ValidTorusSidesCount( const GLint theSidesCount )
{
	if ( theSidesCount < 1 )
	{
		torus.sidesCount = 64;
	} // if
	else
	{
		torus.sidesCount = theSidesCount;
	} // else
} // Torus::ValidTorusSidesCount

//------------------------------------------------------------------------

GLvoid Torus::ValidTorusRingsCount( const GLint theRingsCount )
{
	if ( theRingsCount < 1 )
	{
		torus.ringsCount = 63;
	} // if
	else
	{
		torus.ringsCount = theRingsCount - 1;
	} // else
} // Torus::ValidTorusRingsCount

//------------------------------------------------------------------------

Torus::Torus( )
{
	torus.modelType  = modelTypeSolid;
	torus.sidesCount = 0;
	torus.ringsCount = 0;
	torus.innerRadii = 0.0;
	torus.outerRadii = 0.0;
	torus.ringDelta  = 0.0;
	torus.sideDelta  = 0.0;
	torus.factor     = 0.0;
} // Default Constructor

//------------------------------------------------------------------------

Torus::Torus(	const GLint      theModelType,
				const GLint      theSidesCount, 
				const GLint      theRingsCount,
				const GLdouble   theInnerRadii, 
				const GLdouble   theOuterRadii )
{
	ValidTorusModelType( theModelType );
	ValidTorusSidesCount( theSidesCount );
	ValidTorusRingsCount( theRingsCount );
	
	torus.innerRadii = theInnerRadii;
	torus.outerRadii = theOuterRadii;
	torus.ringDelta  = kTwoPi / torus.ringsCount;
	torus.sideDelta  = kTwoPi / torus.sidesCount;
	torus.factor     = 0.0;
}// Constructor

//------------------------------------------------------------------------

GLvoid Torus::SetTorusAttributes( )
{
	if ( torus.modelType == modelTypeWireFrame )
	{
		glPushAttrib(GL_POLYGON_BIT);
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	} // if
} // Torus::SetTorusAttributes

//------------------------------------------------------------------------

GLvoid Torus::ResetTorusAttributes( )
{
	if ( torus.modelType == modelTypeWireFrame )
	{
		glPopAttrib();
	} // if	
} // Torus::ResetTorusAttributes

//------------------------------------------------------------------------

GLvoid Torus::GetTorusNormal( const Parameter &theParamTheta, const Parameter &theParamPhi )
{
	Vector  normal;
	
	normal.x =  theParamTheta.cos( ) * theParamPhi.cos( );
	normal.y = -theParamTheta.sin( ) * theParamPhi.cos( );
	normal.z =  theParamPhi.cos( );
	
	glNormal3dv( normal.v );
} // Parmeter::GetTorusNormal

//------------------------------------------------------------------------

GLvoid Torus::GetTorusVertex( const Parameter &theParamTheta, const Parameter &theParamPhi )
{
	Vector  vertex;

	vertex.x =  torus.factor     * theParamTheta.cos( );
	vertex.y = -torus.factor     * theParamTheta.sin( );
	vertex.z =  torus.innerRadii * theParamPhi.sin( );
	
	glVertex3dv( vertex.v );
} // Parmeter::GetTorusVertex
 
//------------------------------------------------------------------------

GLvoid Torus::GetTorusSegment( Parameter &theParamTheta, Parameter &theParamPhi )
{
	theParamPhi += torus.sideDelta;
	
	torus.factor = torus.outerRadii + torus.innerRadii * theParamPhi.cos( );

	// Begin the segment here with the normal and the vertex
	
	GetTorusNormal( theParamTheta, theParamPhi );
	GetTorusVertex( theParamTheta, theParamPhi );

	theParamTheta += torus.ringDelta;
	
	// End the segment here with the normal and the vertex

	GetTorusNormal( theParamTheta, theParamPhi );
	GetTorusVertex( theParamTheta, theParamPhi );
} // TorusSegment::GetTorusSegment

//------------------------------------------------------------------------

GLvoid Torus::GetTorusQuadStrip( Parameter  &theParamTheta )
{
	GLint sideIndex;

	Parameter phi;

	glBegin( GL_QUAD_STRIP );

		// Generate segments having the total number of requested sides

		for ( sideIndex = torus.sidesCount; sideIndex >= 0; sideIndex-- )
		{
			GetTorusSegment( theParamTheta, phi );
		} // for

	glEnd( );
} // Torus::GetTorusQuadStrip

//------------------------------------------------------------------------

GLvoid Torus::GetTorus( )
{
	Parameter theta( 0.0, 1.0, 0.0 );
				
	GLint ringIndex;

	// Set OpenGL attributes for a torus if the requested model 
	// was wireframe
	 
	SetTorusAttributes( );
	
	// Generate quad strips having the total number of requested rings
	
	for ( ringIndex = torus.ringsCount; ringIndex >= 0; ringIndex-- ) 
	{
		GetTorusQuadStrip( theta );
	} // for
	
	// Reset OpenGL attributes for a torus if the requested model 
	// was wireframe

	ResetTorusAttributes( );
} // Torus::GetTorus

//------------------------------------------------------------------------

//------------------------------------------------------------------------

