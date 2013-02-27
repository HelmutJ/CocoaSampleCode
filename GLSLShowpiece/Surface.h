//
// Author:    Philip Rideout
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#ifndef SURFACE_H
#define SURFACE_H

#ifdef __cplusplus

#include "Vector.h"

// Abstract base class representing a parametric surface.
class TParametricSurface
{
  public:
    int Draw(int slices, int tangentLoc = -1, int binormalLoc = -1);
    virtual void Eval(vec2& domain, vec3& range) = 0;
    virtual void Vertex(vec2 domain);
    virtual bool Flip(const vec2& domain) { return false; }
    virtual int CustomAttributeLocation() { return -1; }
    virtual float CustomAttributeValue(const vec2& domain) { return 0; }
  protected:
    bool flipped;
    float du, dv;
    int tangentLoc, binormalLoc;
};

class TSphere : public TParametricSurface {
  public:
    void Eval(vec2& domain, vec3& range);
};

class TTorus : public TParametricSurface {
  public:
    void Eval(vec2& domain, vec3& range);
};

class TConic : public TParametricSurface {
  public:
    void Eval(vec2& domain, vec3& range);
};

class TTrefoil : public TParametricSurface {
  public:
    void Eval(vec2& domain, vec3& range);
};

class TKlein : public TParametricSurface {
  public:
    void Eval(vec2& domain, vec3& range);
    bool Flip(const vec2& domain);
};

class TPlane : public TParametricSurface {
  public:
    TPlane(float z = 0, float width = 2) : z(z), width(width) {}
    void Eval(vec2& domain, vec3& range);
  protected:
    float z, width;
};

// Function object that represents an implicit surface
class TImplicitSurface {
  public:
    virtual float operator()(const vec3& v) const { return eval(v); }
    float operator()(float x, float y, float z) const { return eval(vec3(x, y, z)); }
    bool IsInside(const vec3& v) const { return eval(v) > 0; }
    bool IsOutside(const vec3& v) const { return eval(v) < 0; }
    virtual vec3 Center() const = 0;
    vec3 Converge(const vec3& p1, const vec3& p2, int depth) const;
    vec3 Converge(const vec3& p1, const vec3& p2, float p1v, int depth) const;
    vec3 Normal(const vec3& p, float delta) const;
    vec2 TexCoord(const vec3& p) const;
  protected:
    virtual float eval(const vec3& v) const = 0;
};

// Spherical blob component
class TMetaBall : public TImplicitSurface {
  public:
    TMetaBall() {}
    TMetaBall(vec3 center, float radius, float strength);
    vec3 Center() const { return center; }
  private:
    float eval(const vec3& v) const;
    vec3 center;
    float radius2;
    float strength;
    float bound;
};

// Cylindrical blob component
class TTube : public TImplicitSurface {
  public:
    TTube() {}
    TTube(vec3 a, vec3 b, float radius, float strength);
    vec3 Center() const { return (a + b) / 2; }
  private:
    float eval(const vec3& v) const;
    vec3 a, b, d;
    float length2;
    float radius2;
    float strength;
    float bound;
};

#endif

#ifdef __cplusplus
extern "C" {
#endif

void drawKlein();

#ifdef __cplusplus
}
#endif

#endif
