//
// Author:    Philip Rideout
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#ifndef ALIEN_H
#define ALIEN_H

#ifdef __cplusplus

#include "Vector.h"
#include "Surface.h"
#include <list>
#include "os.h"

struct TJoint {
    float x, y;       // origin 
    float width;      // ratio of the joint length to the bone length
    float radius;     // radius of the cylinder
    float length0;    // length of the first bone segment
    float length1;    // length of the second bone segment
    float angle0;     // ccw angle between the x-axis and the first bone segment
    float angle1;     // ccw angle between the two bone segments

    // Rotation matrices for the two angles.  Note that quaternions would be more efficient.
    mat4 transform0;
    mat4 transform1;
};

struct TAlienMovement {
    TAlienMovement(int joint, float dps) : joint(joint), dps(dps) {}
    int joint;
    float dps; // degrees per second
};

typedef std::list<TAlienMovement> TAlienMovements;

struct TAlienMotion {
    TAlienMotion(float seconds) : seconds(seconds) {}
    float seconds;
    TAlienMovements movements;
    void add(int joint, float dps) { movements.push_back(TAlienMovement(joint, dps)); }
};

typedef std::list<TAlienMotion> TAlienMotions;

class TAlien {
  public:
    TAlien();
    void Draw(GLhandleARB program_object) const;
    void Update();
    void Reset();
    void Load(GLhandleARB program_object);
    ~TAlien();
    void Flex(int index, float delta) const;
    float& GetAngle(int index) const;
    void SetAngle(int index, float theta) const;
    TJoint& GetJoint(int index) const;
    mat4& GetTransform(int index);

    enum {
        RightAntennaBase,
        RightAntennaExt,
        LeftAntennaBase,
        LeftAntennaExt,
        RightArmBase,
        RightArmExt,
        LeftArmBase,
        LeftArmExt,
        RightLegBase,
        RightLegExt,
        LeftLegBase,
        LeftLegExt,
        NumAngles,
    };

    static const int NumJoints = NumAngles / 2;
    static const int NumSurfaces = NumJoints + 5;

private:
    int draw(GLhandleARB program_object) const;
    void animate();
    GLuint weightLocation;
    GLuint program;
    TParametricSurface* surface[NumSurfaces];
    mutable GLint index0; // integer pointing to the first transform matrix
    mutable GLint index1; // integer pointing to the second transform matrix
    mat4 transforms[NumAngles + 1]; // transform[0] is for the body; the others are for the joints
    float countdown; // animation counter
    TAlienMotions::iterator motion;

    TAlienMotions animation;
};

class TRevolveBezier : public TParametricSurface {
  public:
    TRevolveBezier(int a, int b, int c, int d);
  protected:
    void Eval(vec2& domain, vec3& range);
    vec2 p0, p1, p2, p3;
};

class TRevolveLine : public TParametricSurface {
  public:
    TRevolveLine(int a, int b);
  protected:
    void Eval(vec2& domain, vec3& range);
    vec2 p0, p1;
};

class TEllipsoid : public TParametricSurface {
  public:
    TEllipsoid(float x, float y, float z) : center(x, y, z) {}
    bool Flip(const vec2& domain);
    void Eval(vec2& domain, vec3& range);
  protected:
    vec3 center;
    static const vec2 radii;
};

class TAppendage : public TParametricSurface {
  public:
    TAppendage(const TJoint& joint, int location) : joint(joint), location(location) {}
    void Eval(vec2& domain, vec3& range);
    int CustomAttributeLocation() { return location; }
    float CustomAttributeValue(const vec2& domain);
  protected:
    TJoint joint;
    int location;
    friend class TAlien;
};
#endif __cplusplus

#ifdef __cplusplus
extern "C" {
#endif

void* newAlien(GLhandleARB program_object, int time);

void updateDrawAlien(void* newAlien, GLhandleARB program_object, int time);

void deleteAlien(void* newAlien);

#ifdef __cplusplus
}
#endif

#endif
