//---------------------------------------------------------------------------------------
//
//	File: TranguloidTrefoilGeometry.m
//
//  Abstract: Tranguloid Trefoil geometry class
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
//  Copyright (c) 2007-2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------------------
//
// Uses techniques described by Paul Bourke 1999 - 2002
// Tranguloid Trefoil and other example surfaces by Roger Bagula 
// see <http://astronomy.swin.edu.au/~pbourke/surfaces/> 
//
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#include <cmath>
#include <vector>

//---------------------------------------------------------------------------------------

#include "TranguloidTrefoilGeometry.h"

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

static const GLdouble kTwoPi      = 2.0 * M_PI;
static const GLdouble kPi         = M_PI;
static const GLdouble kTwoPiThird = ( 2.0 * M_PI ) / 3.0;

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private Data Structures

//---------------------------------------------------------------------------------------

struct Position
{
	union 
	{
		GLdouble P[3];
		
		struct 
		{
			GLdouble x;
			GLdouble y;
			GLdouble z;
		}; // union
	}; // struct
};

typedef Position Position;

//---------------------------------------------------------------------------------------

struct TexCoords
{
	union 
	{
		GLdouble T[2];
		
		struct 
		{
			GLdouble s;
			GLdouble t;
		}; // struct
	}; // union
};

typedef TexCoords TexCoords;

//---------------------------------------------------------------------------------------

struct Vertex
{
	Position   positions;
	Position   normals;
	TexCoords  texCoords;
}; 

typedef Vertex Vertex;

//---------------------------------------------------------------------------------------

typedef std::vector<Vertex>  Vertices;

//---------------------------------------------------------------------------------------

struct Geometry
{
	GLint     rows;
	GLint     columns;
	Vertices  vertices;
}; 

typedef Geometry Geometry;

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Vector Class

//---------------------------------------------------------------------------------------

class Vector
{
	public:
	
		Vector();
		Vector(const Position *p);

		Vector normalize();
		
		Vector operator-(Vector &v);
		Vector operator^(Vector &v);  // Exterior cross product
		
		Position position();
		
	public:
		
		GLdouble x;
		GLdouble y;
		GLdouble z;
}; // class Vector

//---------------------------------------------------------------------------------------

Vector::Vector()
{
	x = 0;
	y = 0;
	z = 0;
} // Default Constructor

//---------------------------------------------------------------------------------------

Vector::Vector(const Position *p)
{
	if( p != NULL )
	{
		x = p->x;
		y = p->y;
		z = p->z;
	} // if
	else
	{
		x = 0;
		y = 0;
		z = 0;
	} // else
}// Constructor

//---------------------------------------------------------------------------------------

Vector Vector::operator-(Vector &v)
{
	Vector w;

	w.x = x - v.x;
	w.y = y - v.y;
	w.z = z - v.z;

	return w;
} // Vector::operator-

//---------------------------------------------------------------------------------------
//
// Exterior (vector) cross product
//
//---------------------------------------------------------------------------------------

Vector Vector::operator^(Vector &v)
{
	Vector w;

	w.x = y * v.z - z * v.y;
	w.y = z * v.x - x * v.z;
	w.z = x * v.y - y * v.x;

	return w;
} // Vector::operator^

//---------------------------------------------------------------------------------------

Vector Vector::normalize()
{
	GLdouble L = (GLdouble)std::sqrt(x * x + y * y + z * z);
	
	Vector w;

	if( L != 0.0 )
	{
		L = 1.0/L;
		
		w.x = L * x;
		w.y = L * y;
		w.z = L * z;
	} // if
	
	return w;
} // Vector::normalize

//---------------------------------------------------------------------------------------

Position Vector::position()
{
	Position p;
	
	p.x = x;
	p.y = y;
	p.z = z;
	
	return p;
} // Vector::position

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Utility Vector Function

//---------------------------------------------------------------------------------------

static Position ComputeNormals(const Position *p, 
							   const Position *q, 
							   const Position *r)
{
	Vector u(p);
	Vector v(q);
	Vector w(r);
	
	Vector n;
	Vector dv;
	Vector dw;

	Position normals;
	
	dv = v - u;
	dv = dv.normalize();
	
	dw = w - u;
	dw = dw.normalize();
	
	n = dv ^ dw;
	n = n.normalize();
	
	normals = n.position();

	return normals;
} // ComputeNormals

//---------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Tranguloid Trefoil Geometry

//---------------------------------------------------------------------------------------
//
// Note that -Pi <= u <= Pi and -Pi <= v <= Pi
//
//---------------------------------------------------------------------------------------

static Position TranguloidTrefoilGeometry(const GLdouble u, 
										  const GLdouble v)
{
	Position  p;
   
	GLdouble t = v + kTwoPiThird;
	GLdouble w = 2.0 * u;
	GLdouble A = 2.0 + cos(t);
	GLdouble B = 2.0 + cos(v);
	
	p.x = 2.0  * sin(3.0 * u) / B;
	p.y = 2.0  * (sin(u) + 2.0 * sin(w)) / A;
	p.z = 0.25 * (cos(u) - 2.0 * cos(w)) * A * B;
	
	return  p;
} // TranguloidTrefoilGeometry

//---------------------------------------------------------------------------------------

static void NewTranguloidTrefoilSurface(Geometry *geometry)
{
	GLint     i;
	GLint     j;
	GLint     maxI    = geometry->rows;
	GLint     maxJ    = geometry->columns;
	GLdouble  invMaxI = 1.0 / (GLdouble)maxI;
	GLdouble  invMaxJ = 1.0 / (GLdouble)maxJ;
	GLdouble  delta   = 0.0005;
	GLdouble  u[2];
	Vertex    vertex;
	Position  position[2];
	
	for(i = 0; i < maxI; i++) 
	{
		for(j = 0; j < maxJ; j++) 
		{
			u[0]  = kTwoPi * (i % maxI) * invMaxI - kPi;
			u[1]  = kTwoPi * (j % maxJ) * invMaxJ - kPi;
			
			vertex.positions = TranguloidTrefoilGeometry(u[0], u[1]);
			
			position[0] = TranguloidTrefoilGeometry(u[0] + delta, u[1]);
			position[1] = TranguloidTrefoilGeometry(u[0], u[1] + delta);
			
			vertex.normals = ComputeNormals(&vertex.positions, &position[0], &position[1]);
			
			vertex.texCoords.s = (GLdouble)i * invMaxI * 5.0;
			vertex.texCoords.t = (GLdouble)j * invMaxJ;
			
			geometry->vertices.push_back(vertex);
		} // for
	} // for
} // NewTranguloidTrefoilSurface

//---------------------------------------------------------------------------------------

static void BuildVertex(const GLint index, 
						Geometry *geometry)
{
	glNormal3dv(geometry->vertices[index].normals.P);
	glTexCoord2dv(geometry->vertices[index].texCoords.T);
	glVertex3dv(geometry->vertices[index].positions.P);
} // BuildVertex

//---------------------------------------------------------------------------------------

static GLuint NewTranguloidTrefoilDisplayList(Geometry *geometry)
{
	GLint   i;
	GLint   j;
	GLint   k;
	GLint   l;
	GLint   m;
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
					m = (j % maxJ);
					
					k = (i % maxI) * maxJ + m;

					BuildVertex(k, geometry);
		
					l = ((i + 1) % maxI) * maxJ + m;

					BuildVertex(l, geometry);
				} // for
			
			glEnd();
		} // for
		
	glEndList();
	
	return displayList;
} // NewTranguloidTrefoilDisplayList

//---------------------------------------------------------------------------------------

static GLuint GetTranguloidTrefoilDisplayList(const GLuint subdivisions, 
											  const GLuint xyRatio)
{
	Geometry  geometry;
	GLuint    displayList = 0;
	
	geometry.rows    = subdivisions * xyRatio;  
	geometry.columns = subdivisions;  
		
	// Build surface

	NewTranguloidTrefoilSurface(&geometry);
		
	// Now get the display list

	displayList = NewTranguloidTrefoilDisplayList(&geometry);
	
	return displayList;
} // GetTranguloidTrefoilDisplayList

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------------

@implementation TranguloidTrefoil

//---------------------------------------------------------------------------------------

- (id) initTranguloidTrefoilWithAttribbutes:(const GLuint)theSubdivisions 
									  ratio:(const GLuint)theRatio
{
	self = [super init];
	
	if( self )
	{
		displayList = GetTranguloidTrefoilDisplayList(theSubdivisions, theRatio);
	} // if
	
	return self;
} // init

//---------------------------------------------------------------------------------------

- (GLuint) displayList
{
	return displayList;
} // displayList

//---------------------------------------------------------------------------------------

- (void) dealloc 
{
	// delete the last used display list
	
	if(displayList)
	{
		glDeleteLists(displayList, 1);
	} // if
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
