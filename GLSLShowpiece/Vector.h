//
// Author:    Philip Rideout
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

// Basic vector math.  This is by no means complete; add to this file as necessary.

#ifndef VECTOR_H
#define VECTOR_H

static const float pi = 3.14159265358979323846f;
static const float twopi = 6.28318530717958647692f;
static const float sqrt2 = 1.4142135623730950488016887242097f;

struct ivec2 {
    ivec2() : x(0), y(0) {}
    ivec2(int x, int y) : x(x), y(y) {}
    int x, y;
};

struct vec2 {
    vec2() : x(0), y(0) {}
    vec2(float x, float y) : x(x), y(y) {}
    vec2(float x) : x(x), y(x) {}
    vec2(const float p[]) : x(p[0]), y(p[1]) {}
    vec2 operator/(float f) const { return vec2(x / f, y / f); }
    vec2 operator*(float scale) const { return vec2(x * scale, y * scale); }
    vec2 operator+(vec2 v) const { return vec2(v.x + x, v.y + y); }
    void operator*=(float scale) { x *= scale; y *= scale; }
    void operator/=(float scale) { x /= scale; y /= scale; }
    union { float x, u, s; };
    union { float y, v, t; };
    void flip() { float temp = x; x = y; y = temp; }
};

struct ivec3 {
    ivec3() : x(0), y(0), z(0) {}
    ivec3 operator+(const ivec3& v) const { return ivec3(v.x + x, v.y + y, v.z + z); }
    ivec3(int x, int y, int z) : x(x), y(y), z(z) {}
    union {
        struct { int x, y, z; };
        struct { int i, j, k; };
    };
};

struct vec3 {
    vec3() : x(0), y(0), z(0) {}
    vec3(float x, float y, float z) : x(x), y(y), z(z) {}
    vec3 operator-(const vec3& v) const { return vec3(x - v.x, y - v.y, z - v.z); }
    vec3 operator+(const vec3& v) const { return vec3(x + v.x, y + v.y, z + v.z); }
    vec3 operator-() const { return vec3(-x, -y, -z); }
    vec3 operator/(float f) const { return vec3(x / f, y / f, z / f); }
    vec3 operator*(float f) const { return vec3(x * f, y * f, z * f); }
    void operator*=(float scale) { x *= scale; y *= scale; z *= scale; }
    void operator/=(float f) { x /= f; y /= f; z /= f; }
    float magnitude() const;
    float mag2() const;
    void unitize();
    float x, y, z;
    bool operator<(const vec3& v) const;
};

struct mat2 { float data[4]; };

struct mat3 { float data[9]; };

struct mat4 {
    float data[16];
    void identity();
};

mat4 operator*(const mat4& a, const mat4& b);

void glVertex(const vec2& v);
void glVertex(const vec3& v);
void glNormal(const vec3& v);
void glColor(const vec3& v);
void glTexCoord(const vec2& v);
void glTranslate(const vec3& v);
void glVertexAttrib(unsigned int loc, const vec3& v);

vec3 blend(const vec3& v, const mat4& m0, const mat4& m1, float w0, float w1);
vec3 cross(const vec3& a, const vec3& b);
float dot(const vec3& a, const vec3& b);
vec2 operator*(const vec2& v, const mat4& m);
vec3 operator*(const vec3& v, const mat4& m);

#endif
