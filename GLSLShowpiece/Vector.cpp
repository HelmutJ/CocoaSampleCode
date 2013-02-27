//
// Author:    Philip Rideout
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#include "os.h"
#include <cmath>
#include "Vector.h"

// Basic vector math.  This is by no means complete; add to this file as necessary.

float vec3::magnitude() const
{
    return sqrtf(mag2());
}

float vec3::mag2() const
{
    return x*x + y*y + z*z;
}

void vec3::unitize()
{
    float m = magnitude();
    x /= m;
    y /= m;
    z /= m;
}

float dot(const vec3& a, const vec3& b)
{
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

vec3 cross(const vec3& u, const vec3& v)
{
    return vec3(u.y*v.z-u.z*v.y, u.z*v.x-u.x*v.z, u.x*v.y-u.y*v.x);
}

mat4 operator*(const mat4& a, const mat4& b)
{
    mat4 retval;
    glPushMatrix();
    glLoadMatrixf(a.data);
    glMultMatrixf(b.data);
    glGetFloatv(GL_MODELVIEW_MATRIX, retval.data);
    glPopMatrix();
    return retval;
}

vec2 operator*(const vec2& v, const mat4& m)
{
    float x = m.data[0] * v.x + m.data[4] * v.y + m.data[12];
    float y = m.data[1] * v.x + m.data[5] * v.y + m.data[13];
    return vec2(x, y);
}

vec3 blend(const vec3& v, const mat4& m0, const mat4& m1, float w0, float w1)
{
    return v * m0 * w0 + v * m1 * w1;
}

vec3 operator*(const vec3& v, const mat4& m)
{
    float x = m.data[0] * v.x + m.data[4] * v.y + m.data[8] * v.z  + m.data[12];
    float y = m.data[1] * v.x + m.data[5] * v.y + m.data[9] * v.z  + m.data[13];
    float z = m.data[2] * v.x + m.data[6] * v.y + m.data[10] * v.z + m.data[14];
    return vec3(x, y, z);
}

void mat4::identity()
{
    for (int i = 0; i < 4; ++i)
        for (int j = 0; j < 4; ++j)
            data[i*4 + j] = (i == j) ? 1.0f : 0.0f;
}

void glVertex(const vec3& v)
{
    glVertex3fv((float*) &v);
}

void glVertex(const vec2& v)
{
    glVertex2fv((float*) &v);
}

void glNormal(const vec3& v)
{
    glNormal3fv((float*) &v);
}

void glColor(const vec3& v)
{
    glColor4f(v.x, v.y, v.z, 1);
}

void glTexCoord(const vec2& v)
{
    glTexCoord2f(v.x, v.y);
}

void glTranslate(const vec3& v)
{
    glTranslatef(v.x, v.y, v.z);
}

void glVertexAttrib(unsigned int loc, const vec3& v)
{
    glVertexAttrib3fv(loc, &v.x);
}

bool vec3::operator<(const vec3& v) const
{
    if (x != v.x)
        return x < v.x;
    if (y != v.y)
        return y < v.y;
    return z < v.z;
}
