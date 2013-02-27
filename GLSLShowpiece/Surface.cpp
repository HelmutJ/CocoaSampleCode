//
// Author:    Philip Rideout
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#include "Surface.h"
#define _USE_MATH_DEFINES
#include <cmath>
#include "os.h"

// Draw a parametric surface.  'slices' is the tesselation factor.  Returns the number of vertices.
int TParametricSurface::Draw(int slices, int tangentLoc, int binormalLoc)
{
    int totalVerts = 0;
    int stacks = slices / 2;
    du = 1.0f / (float) slices;
    dv = 1.0f / (float) stacks;
    this->tangentLoc = tangentLoc;
    this->binormalLoc = binormalLoc;

    for (float u = 0; u < 1 - du / 2; u += du) {
        glBegin(GL_QUAD_STRIP);
        if (flipped = Flip(vec2(u,0))) {
            for (float v = 0; v < 1 + dv / 2; v += dv) {
                Vertex(vec2(u + du, v));
                Vertex(vec2(u, v));
                totalVerts += 2;
            }
        } else {
            for (float v = 0; v < 1 + dv / 2; v += dv) {
                Vertex(vec2(u, v));
                Vertex(vec2(u + du, v));
                totalVerts += 2;
            }
        }
        glEnd();
    }

    return totalVerts;
}

// Send out a normal, texture coordinate, vertex coordinate, and an optional custom attribute.
void TParametricSurface::Vertex(vec2 domain)
{
    vec3 p0, p1, p2, p3;
    vec3 normal;
    float u = domain.u;
    float v = domain.v;

    Eval(domain, p0);
    vec2 z1(u + du/2, v);
    Eval(z1, p1);
    vec2 z2(u + du/2 + du, v);
    Eval(z2, p3);

    if (flipped) {
        vec2 z3(u + du/2, v - dv);
        Eval(z3, p2);
    } else {
        vec2 z4(u + du/2, v + dv);
        Eval(z4, p2);
    }

    const float epsilon = 0.00001f;

    vec3 tangent = p3 - p1;
    vec3 binormal = p2 - p1;
    normal = cross(tangent, binormal);
    if (normal.magnitude() < epsilon)
        normal = p0;
    normal.unitize();

    if (tangentLoc != -1)
    {
        if (tangent.magnitude() < epsilon)
            tangent = cross(binormal, normal);
        tangent.unitize();
        glVertexAttrib(tangentLoc, tangent);
    }

    if (binormalLoc != -1)
    {
        binormal.unitize();
        glVertexAttrib(binormalLoc, -binormal);
    }

    if (CustomAttributeLocation() != -1)
        glVertexAttrib1f(CustomAttributeLocation(), CustomAttributeValue(domain));

    glNormal(normal);
    glTexCoord(domain);
    glVertex(p0);
}

void TKlein::Eval(vec2& domain, vec3& range)
{
    float u = (1 - domain.u) * twopi;
    float v = domain.v * twopi;

    float x0 = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) * cosf(u) * cosf(v);
    float y0  = 8 * sinf(u) + (2 * (1 - cosf(u) / 2)) * sinf(u) * cosf(v);

    float x1 = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) * cosf(v + pi);
    float y1 = 8 * sinf(u);

    range.x = u < pi ? x0 : x1;
    range.y = u < pi ? y0 : y1;
    range.z = (2 * (1 - cosf(u) / 2)) * sinf(v);
    range = range / 10;
    range.y = -range.y;

    // Tweak the texture coordinates.
    domain.u *= 4;
}

// Flip the normals along a segment of the Klein bottle so that we don't need two-sided lighting.
bool TKlein::Flip(const vec2& domain)
{
    return (domain.u < .125);
}

void TTrefoil::Eval(vec2& domain, vec3& range)
{
    const float a = 0.5f;
    const float b = 0.3f;
    const float c = 0.5f;
    const float d = 0.1f;
    float u = (1 - domain.u) * twopi * 2;
    float v = domain.v * twopi;

    float r = a + b * cosf(1.5f * u);
    float x = r * cosf(u);
    float y = r * sinf(u);
    float z = c * sinf(1.5f * u);

    vec3 dv;
    dv.x = -1.5f * b * sinf(1.5f * u) * cosf(u) - (a + b * cosf(1.5f * u)) * sinf(u);
    dv.y = -1.5f * b * sinf(1.5f * u) * sinf(u) + (a + b * cosf(1.5f * u)) * cosf(u);
    dv.z = 1.5f * c * cosf(1.5f * u);

    vec3 q = dv; q.unitize();
    vec3 qvn(q.y, -q.x, 0); qvn.unitize();
    vec3 ww = cross(q,qvn);

    range.x = x + d * (qvn.x * cosf(v) + ww.x * sinf(v));
    range.y = y + d * (qvn.y * cosf(v) + ww.y * sinf(v));
    range.z = z + d * ww.z * sinf(v);

    // Tweak the texture coordinates.
    domain.u *= 20;
    domain /= 3;
}

void TConic::Eval(vec2& domain, vec3& range)
{
    const float a = 0.2f;
    const float b = 1.5f;
    const float c = 0.1f;
    const float n = 2;

    float u = domain.u * twopi;
    float v = domain.v * twopi;

    range.x = a * (1 - v / twopi) * cosf(n * v) * (1 + cosf(u)) + c * cosf(n * v);
    range.z = a * (1 - v / twopi) * sinf(n * v) * (1 + cosf(u)) + c * sinf(n * v);
    range.y = b * v / twopi + a * (1 - v / twopi) * sinf(u) - 0.7f;
    range *= 1.25;
    range.y += 0.125;

    // Tweak the texture coordinates.
    domain.v *= 4;
}

void TTorus::Eval(vec2& domain, vec3& range)
{
    const float major = 0.8f;
    const float minor = 0.2f;
    float u = domain.u * twopi;
    float v = domain.v * twopi;

    range.x = (major + minor * cosf(v)) * cosf(u);
    range.y = (major + minor * cosf(v)) * sinf(u);
    range.z = minor * sinf(v);

    // Tweak the texture coordinates.
    domain.u *= 4;
}

void TSphere::Eval(vec2& domain, vec3& range)
{
    const float radius = 1;
    float u = fabsf(domain.v * pi);
    float v = fabsf(domain.u * twopi);

    range.x = radius * cosf(v) * sinf(u);
    range.z = -radius * sinf(v) * sinf(u);
    range.y = -radius * cosf(u);
}

void TPlane::Eval(vec2& domain, vec3& range)
{
    if (z < 0) {
        range.x = -width * (domain.u - 0.5f);
        range.y = width * (domain.v - 0.5f);
    } else {
        range.x = width * (domain.u - 0.5f);
        range.y = width * (domain.v - 0.5f);
    }
    range.z = z;
}


// Using two points of differing signs, converge to zero crossing
vec3 TImplicitSurface::Converge(const vec3& p1, const vec3& p2, int depth) const
{
    return Converge(p1, p2, eval(p1), depth);
}

// Using two points of differing signs, converge to zero crossing
vec3 TImplicitSurface::Converge(const vec3& p1, const vec3& p2, float p1v, int depth) const
{
    int i = 0;
    vec3 pos, neg;
    vec3 p;

    if (p1v < 0) {
        pos = p2;
        neg = p1;
    } else {
        pos = p1;
        neg = p2;
    }

    for (;;) {
        p = (pos + neg) * 0.5f;
        if (i++ == depth)
            return p;
        if (IsInside(p))
            pos = p;
        else
            neg = p;
    }

    return p;
}

// Find the normal at the specified point on the surface.
vec3 TImplicitSurface::Normal(const vec3& p, float delta) const
{
    vec3 n;
    float f = eval(p);
    n.x = f - eval(p + vec3(delta, 0, 0));
    n.y = f - eval(p + vec3(0, delta, 0));
    n.z = f - eval(p + vec3(0, 0, delta));
    n.unitize();
    return -n;
}

// Generate a texture coordinate at the specified point on the surface.
vec2 TImplicitSurface::TexCoord(const vec3& p) const
{
    return vec2(p.x, p.y);
}

float TMetaBall::eval(const vec3& v) const
{
    float mag2 = (v - center).mag2();
    mag2 /= radius2;

    if (mag2 > bound)
        return 0;

    if (strength > 0)
        return expf(-strength * mag2);

    return -expf(strength * mag2);
}

float TTube::eval(const vec3& v) const
{
    float mag2;

    if (dot(d, a - v) > 0)
        mag2 = (v - a).mag2();
    else if (dot(-d, b - v) > 0)
        mag2 = (v - b).mag2();
    else
        mag2 = cross(d, a - v).mag2() / length2;

    mag2 /= radius2;

    if (mag2 > bound)
        return 0;

    return expf(-strength * mag2);
}

TMetaBall::TMetaBall(vec3 center, float radius, float strength) : center(center), strength(strength)
{
    const float epsilon = 0.001f;
    bound = -logf(epsilon) / fabsf(strength);
    radius2 = radius * radius;
}

TTube::TTube(vec3 a, vec3 b, float radius, float strength) : a(a), b(b), strength(strength)
{
    const float epsilon = 0.001f;
    bound = -logf(epsilon) / strength;
    radius2 = radius * radius;
    d = b - a;
    length2 = d.mag2();
}

void drawKlein()
{
	static int init = 0;
	static GLuint kleinListID;

	if(!init)
	{
		init = 1;
		kleinListID = glGenLists(1);
		glNewList(kleinListID, GL_COMPILE);
		TKlein().Draw(35);
		glEndList();
	}

	glCallList(kleinListID);
}
