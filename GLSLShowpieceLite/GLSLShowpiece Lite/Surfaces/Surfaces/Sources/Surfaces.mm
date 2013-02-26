//---------------------------------------------------------------------------
//
//	File: Surfaces.mm
//
//  Abstract: Exotic surface geometry class
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
//
// Uses techniques described by Paul Bourke 1999 - 2002
// Tranguloid Trefoil and other example surfaces by Roger Bagula 
// see <http://astronomy.swin.edu.au/~pbourke/surfaces/> 
//
//---------------------------------------------------------------------------

//------------------------------------------------------------------------

//------------------------------------------------------------------------

#include <cmath>
#include <vector>

//------------------------------------------------------------------------

#include "Vector3.hpp"

//------------------------------------------------------------------------

#include "Surfaces.h"

//------------------------------------------------------------------------

#include "GeometryConstants.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef struct
{
	FPosition3   positions;
	FPosition3   normals;
	FPosition2   texCoords;
} Vertex; 

//------------------------------------------------------------------------

typedef std::vector<Vertex>  Vertices;

//------------------------------------------------------------------------

typedef struct
{
	GLint     rows;
	GLint     columns;
	Vertices  vertices;
} Geometry; 

//------------------------------------------------------------------------

//------------------------------------------------------------------------

static FPosition3 ComputeNormals(const FPosition3 *p, const FPosition3 *q, const FPosition3 *r)
{
	FPosition3 normalPos;
	
	FVector3 u(p);
	FVector3 v(q);
	FVector3 w(r);
		
	FVector3 n;

	n = u.normals( v, w );
	
	normalPos = n.getVector();

	return normalPos;
} // ComputeNormals

//------------------------------------------------------------------------
//
// Note that -Pi <= u <= Pi and -Pi <= v <= Pi
//
//------------------------------------------------------------------------

static void TranguloidTrefoilGeometry(GLdouble u, GLdouble v, FPosition3  *p)
{
	p->x = sin(3*u) * 2 / (2 + cos(v));
	p->y = (sin(u) + 2 * sin(2*u)) * 2 / (2 + cos(v + kTwoPi / 3));
	p->z = (cos(u) - 2 * cos(2*u)) * (2 + cos(v)) * (2 + cos(v + kTwoPi/3))/4;
} // TranguloidTrefoilGeometry

//------------------------------------------------------------------------

static void TriaxialTritorusGeometry(GLdouble u, GLdouble v, FPosition3  *p)
{
	p->x = 2.0 * sin (u) * (1 + cos (v));
	p->y = 2.0 * sin (u + 2 * kPi / 3) * (1 + cos (v + 2 * kPi / 3));
	p->z = 2.0 * sin (u + 4 * kPi / 3) * (1 + cos (v + 4 * kPi / 3));
} // TriaxialTritorusGeometry

//------------------------------------------------------------------------

static void StilettoSurfaceGeometry(GLdouble u, GLdouble v, FPosition3  *p)
{
	// reverse u and v for better distribution or points

	GLdouble w = u;

	u = v + kPi; 
	v = (w + kPi) / 2.0; // convert to: 0 <= u <= 2 kPi, 0 <= v <= 2 kPi
	 
	p->x = 4.0 *  (2.0 + cos(u)) * pow(cos(v), 3.0) * sin(v);
	p->y = 4.0 *  (2.0 + cos(u+kTwoPi/3.0)) * pow (cos(v+kTwoPi/3.0), 2.0) * pow (sin(v+kTwoPi/3.0), 2.0);
	p->z = 4.0 * -(2.0 + cos(u-kTwoPi/3.0)) * pow (cos(v+kTwoPi/3.0), 2.0) * pow (sin(v+kTwoPi/3.0), 2.0);
} // StilettoSurfaceGeometry

//------------------------------------------------------------------------

static void SlippersSurfaceGeometry(GLdouble u, GLdouble v, FPosition3  *p)
{
	GLdouble w = u;

	u = v + kPi * 2; 
	v = w + kPi; // convert to: 0 <= u <= 4 kPi, 0 <= v <= 2 kPi 

	p->x = 4.0 *  (2 + cos (u)) * pow (cos (v), 3) * sin(v);
	p->y = 4.0 *  (2 + cos (u + kTwoPi / 3)) * pow (cos (kTwoPi / 3 + v), 2) * pow (sin (kTwoPi / 3 + v), 2);
	p->z = 4.0 * -(2 + cos (u - kTwoPi / 3)) * pow (cos (kTwoPi / 3 - v), 2) * pow (sin (kTwoPi / 3 - v), 3);
} // SlippersSurfaceGeometry

//------------------------------------------------------------------------

static void MaedersOwlSurfaceGeometry(GLdouble u, GLdouble v, FPosition3  *p)
{
	u = (u + kPi) * 2; 
	v = (v + kPi) / kTwoPi; // convert to: 0 <= u <= 4 kPi, 0 <= v <= 1 
	
	p->x = 3.0 *  v * cos(u) - 0.5 * v * v * cos(2 * u);
	p->y = 3.0 * -v * sin(u) - 0.5 * v * v * sin(2 * u);
	p->z = 3.0 *  4 * pow(v,1.5) * cos(1.5 * u) / 3;
} // MaedersOwlSurfaceGeometry

//------------------------------------------------------------------------

static void DefaultSurfaceGeometry(FPosition3  *p)
{
	p->x = 0.0;
	p->y = 0.0;
	p->z = 0.0;
} // DefaultSurfaceGeometry

//------------------------------------------------------------------------

static FPosition3 ComputeForSurfaceGeometry( const GLuint surfaceType, GLdouble u, GLdouble v )
{
	FPosition3  p;
	
	switch ( surfaceType ) 
	{
		case kTranguloidTrefoil:
			
			TranguloidTrefoilGeometry(u, v, &p);
			break;
		
		case kTriaxialTritorus:
		
			TriaxialTritorusGeometry(u, v, &p);
			break;
		
		case kStilettoSurface:
			
			StilettoSurfaceGeometry(u, v, &p);
			break;
			
		case kSlipperSurface:
			
			SlippersSurfaceGeometry(u, v, &p);
			break;

		case kMaedersOwl:
			
			MaedersOwlSurfaceGeometry(u, v, &p);
			break;

		default:
			DefaultSurfaceGeometry( &p );			
			break;
	} // switch
	
	return  p;
} // ComputeForSurfaceGeometry

//------------------------------------------------------------------------

static void NewSurfaceGeometry(const GLuint surfaceType, Geometry *geometry)
{
	GLint       i;
	GLint       j;
	GLint       maxI = geometry->rows;
	GLint       maxJ = geometry->columns;
	GLdouble    u[2];
	GLdouble    delta = 0.0005;
	Vertex      vertex;
	FPosition3  position[2];
	
	for(i = 0; i < maxI; i++) 
	{
		for(j = 0; j < maxJ; j++) 
		{
			u[0]  = -kPi + (i % maxI) * kTwoPi / maxI;
			u[1]  = -kPi + (j % maxJ) * kTwoPi / maxJ;
			
			vertex.positions = ComputeForSurfaceGeometry(surfaceType, u[0], u[1]);
			
			position[0] = ComputeForSurfaceGeometry(surfaceType, u[0] + delta, u[1]);
			position[1] = ComputeForSurfaceGeometry(surfaceType, u[0], u[1] + delta);
			
			vertex.normals = ComputeNormals(&vertex.positions, &position[0], &position[1]);
			
			vertex.texCoords.s = (GLfloat) i * 5.0f / (GLfloat) maxI;
			vertex.texCoords.t = (GLfloat) j * 1.0f / (GLfloat) maxJ;
			
			geometry->vertices.push_back(vertex);
		} // for
	} // for
} // NewSurfaceGeometry

//------------------------------------------------------------------------

static void BuildVertex(const GLint index, Geometry *geometry)
{
	glNormal3fv(geometry->vertices[index].normals.V);
	glTexCoord2fv(geometry->vertices[index].texCoords.V);
	glVertex3fv(geometry->vertices[index].positions.V);
} // BuildVertex

//------------------------------------------------------------------------

static GLuint NewSurfaceGeometryDisplayList(Geometry *geometry)
{
	GLint   i;
	GLint   j;
	GLint   k;
	GLint   l;
	GLint   maxI = geometry->rows;
	GLint   maxJ = geometry->columns;
	GLuint  displayList;
	
	displayList = glGenLists(1);
	
	glNewList(displayList, GL_COMPILE);
	
		for(i = 0; i < maxI; i++) 
		{
			glBegin(GL_TRIANGLE_STRIP);
			
				for(j = 0; j <= maxJ; j++) 
				{
					k = (i % maxI) * maxJ + (j % maxJ);

					BuildVertex(k, geometry);
		
					l = ((i + 1) % maxI) * maxJ + (j % maxJ);

					BuildVertex(l, geometry);
				} // for
			
			glEnd();
		} // for
		
	glEndList();
	
	return displayList;
} // NewSurfaceGeometryDisplayList

//------------------------------------------------------------------------

static void GetSurfaceGeometryDisplayList(const GLuint surfaceType, const GLuint subdivisions, const GLuint xyRatio, GLuint *displayList)
{
	Geometry  geometry;

	// Delete existing list
	
	if(*displayList)
	{
		glDeleteLists(*displayList, 1);
	
		*displayList = 0;
	} // if

	geometry.rows    = subdivisions * xyRatio;  
	geometry.columns = subdivisions;  
		
	// Build surface

	NewSurfaceGeometry(surfaceType, &geometry);
		
	// Now get the display list

	*displayList = NewSurfaceGeometryDisplayList(&geometry);
} // GetSurfaceGeometryDisplayList

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation Surfaces

//------------------------------------------------------------------------

-(id) init
{
	subdivisions = 64;
	xyRatio      = 4;
	displayList  = 0;
	surfaceType = kTranguloidTrefoil;
	
	return self;
} // init

//------------------------------------------------------------------------

- (void) setSurfaceType:(GLuint)theSurfaceType
{
	surfaceType = theSurfaceType;
} // setSurfaceType

//------------------------------------------------------------------------

- (void) setSubdivisions:(GLuint)theSubdivisions
{
	subdivisions = theSubdivisions;
} // setSubdivisions

//------------------------------------------------------------------------

- (void) setXYRatio:(GLuint)theXYRatio
{
	xyRatio = theXYRatio;
} // setXYRatio

//------------------------------------------------------------------------

- (GLuint) getDisplayList
{
	GetSurfaceGeometryDisplayList(surfaceType, subdivisions, xyRatio,  &displayList);
	
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
