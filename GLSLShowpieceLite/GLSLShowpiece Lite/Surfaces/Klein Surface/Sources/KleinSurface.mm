//---------------------------------------------------------------------------
//
//	File: KleinSurface.mm
//
//  Abstract: Klein surface geometry class
//            Based on the work by Philip Rideout ((C) 2002-2006 3Dlabs Inc.)
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
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
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#include <cmath>

//------------------------------------------------------------------------

#include "GeometryConstants.h"

//------------------------------------------------------------------------

#include "Vector3.hpp"

//------------------------------------------------------------------------

#import "KleinSurface.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static const GLfloat  kEpsilon = 0.00001f;

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef struct
{
	FVector3  p[4];
	FVector3  normal;
} Vertex; 

//------------------------------------------------------------------------

//-------------------------------------------------------------------------

static void KleinSurfaceCompute( FVector2& domain, FVector3& range )
{
	GLfloat u = (1 - domain.u) * kTwoPi;
	GLfloat v = domain.v * kTwoPi;

	GLfloat x0 = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) * cosf(u) * cosf(v);
	GLfloat y0 = 8 * sinf(u) + (2 * (1 - cosf(u) / 2)) * sinf(u) * cosf(v);

	GLfloat x1 = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) * cosf(v + kPi);
	GLfloat y1 = 8 * sinf(u);

	range.x = u < kPi ? x0 : x1;
	range.y = u < kPi ? y0 : y1;
	range.z = (2 * (1 - cosf(u) / 2)) * sinf(v);
	
	range = range / 10;
	
	range.y = -range.y;

	// Tweak the texture coordinates.
	
	domain.u *= 4;
	
} // KleinSurfaceCompute

//-------------------------------------------------------------------------
//
// Flip the normals along a segment of the Klein bottle so that we don't 
// need two-sided lighting.
//
//-------------------------------------------------------------------------

static inline bool KleinSurfaceFlipNormals(const GLfloat u)
{
	return (u < .125);
} // KleinSurfaceFlipNormals

//-------------------------------------------------------------------------

static void GetKleinSurfaceVertex(const bool flippedKleinSurface, GLfloat du, GLfloat dv, FVector2& domain, Vertex& vKlein)
{
	GLfloat  u = domain.u;
	GLfloat  v = domain.v;

	KleinSurfaceCompute(domain, vKlein.p[0]);
	
	FVector2 z1(u + du/2, v);
	
	KleinSurfaceCompute(z1, vKlein.p[1]);
	
	FVector2 z2(u + du/2 + du, v);
	
	KleinSurfaceCompute(z2, vKlein.p[3]);

	if (flippedKleinSurface) 
	{
		FVector2 z3(u + du/2, v - dv);
		
		KleinSurfaceCompute(z3, vKlein.p[2]);
	}  // if
	else 
	{
		FVector2 z4(u + du/2, v + dv);
		
		KleinSurfaceCompute(z4, vKlein.p[2]);
	} // else
} // GetKleinSurfaceVertex

//-------------------------------------------------------------------------

static void SetKleinSurfaceVertexAttributes(Vertex& vKlein)
{
	GLint  tangentLoc  = -1;
	GLint  binormalLoc = -1;
	
	FVector3 tangent  = vKlein.p[3] - vKlein.p[1];
	FVector3 binormal = vKlein.p[2] - vKlein.p[1];
	
	vKlein.normal = tangent ^ binormal; // Exterior cross product
	
	if (vKlein.normal.magnitude() < kEpsilon)
	{
		vKlein.normal = vKlein.p[0];
	} // if
	
	vKlein.normal.normalize();

	if (tangent.magnitude() < kEpsilon)
	{
		tangent = binormal ^ vKlein.normal; // Exterior cross product
	} // if
	
	tangent.normalize();
	
	glVertexAttrib3fv(tangentLoc, tangent.getVector().V);

	binormal.normalize();
	
	binormal = -binormal;
	
	glVertexAttrib3fv( binormalLoc, binormal.getVector().V);
} // SetKleinSurfaceVertexAttributes

//-------------------------------------------------------------------------

static void NewKleinSurfaceVertex(FVector2& domain, Vertex& vKlein)
{
	FPosition2 w = domain.getVector();
	
	glNormal3fv( vKlein.normal.getVector().V );
	glTexCoord2f( w.s, w.t );
	glVertex3fv( vKlein.p[0].getVector().V );
} // NewKleinSurfaceVertex

//-------------------------------------------------------------------------
//
// Send out a normal, texture coordinate, vertex coordinate, and an
// optional custom attribute.
//
//-------------------------------------------------------------------------

static void KleinSurfaceGetVertex(const bool flippedKleinSurface, GLfloat du, GLfloat dv, FVector2& domain)
{
	Vertex vKlein;
	
	GetKleinSurfaceVertex(flippedKleinSurface, du, dv, domain, vKlein);
	SetKleinSurfaceVertexAttributes(vKlein);
	NewKleinSurfaceVertex(domain, vKlein);
} // KleinSurfaceGetVertex

//-------------------------------------------------------------------------

static GLuint KleinSurfaceNewDisplayList(GLint tessellationFactor)
{
	GLuint  displayList;
	GLint   stacks = tessellationFactor / 2;

	GLfloat u;
	GLfloat v;
	
	GLfloat du = 1.0f / (GLfloat) tessellationFactor;
	GLfloat dv = 1.0f / (GLfloat) stacks;
	
	bool flippedKleinSurface;

	displayList = glGenLists(1);
	
	glNewList(displayList, GL_COMPILE);
	
		for (u = 0; u < 1 - du / 2; u += du) 
		{
			glBegin(GL_QUAD_STRIP);
			
				flippedKleinSurface = KleinSurfaceFlipNormals(u);
								
				if ( flippedKleinSurface )
				{
					for (v = 0; v < 1 + dv / 2; v += dv) 
					{
						FVector2 domain1(u + du, v);
						FVector2 domain2(u, v);
		
						KleinSurfaceGetVertex(flippedKleinSurface, du, dv, domain1);
						KleinSurfaceGetVertex(flippedKleinSurface, du, dv, domain2);
					} // for
				} // if
				else 
				{
					for (v = 0; v < 1 + dv / 2; v += dv) 
					{
						FVector2 domain1(u, v);
						FVector2 domain2(u + du, v);
		
						KleinSurfaceGetVertex(flippedKleinSurface, du, dv, domain1);
						KleinSurfaceGetVertex(flippedKleinSurface, du, dv, domain2);
					} // for
				} // else
				
			glEnd();
		} // for 

	glEndList();
	
	return displayList;
} // KleinSurfaceNewDisplayList

//-------------------------------------------------------------------------

//------------------------------------------------------------------------

static void GetKleinSurfaceDisplayList(const GLint tessellationFactor, GLuint *displayList)
{
	// Delete existing list
	
	if(*displayList)
	{
		glDeleteLists(*displayList, 1);
	
		*displayList = 0;
	} // if

	// Now get the display list

	*displayList = KleinSurfaceNewDisplayList(tessellationFactor);
} // GetSurfaceGeometryDisplayList

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation KleinSurface

//------------------------------------------------------------------------

-(id) init
{
	tessellationFactor = 35;
	displayList        = 0;
	
	return self;
} // init

//------------------------------------------------------------------------

- (void) setTessellationFactor:(GLint)theTessellationFactor
{
	tessellationFactor = theTessellationFactor;
} // setTessellationFactor

//------------------------------------------------------------------------

- (GLuint) getDisplayList
{
	GetKleinSurfaceDisplayList(tessellationFactor, &displayList);
	
	return displayList;
} // getDisplayList

//------------------------------------------------------------------------

- (void) dealloc 
{
	// delete the last used display list
	
	if(displayList)
	{
		glDeleteLists(displayList, 1);
	} // if
	
	displayList = 0;
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------
