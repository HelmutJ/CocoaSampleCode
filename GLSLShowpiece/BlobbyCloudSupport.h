//
// Author:    Jon Kennedy
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#ifndef BLOBBYCLOUD_H
#define BLOBBYCLOUD_H

#ifdef __cplusplus

#include "Vector.h"
#include "Surface.h"
#include <vector>
#include "os.h"

// structure used for qsort algorithm.
struct TBlobby {
    float distSqr;
    int   blob;
};

typedef std::vector<vec3> TPositions;
typedef std::vector<vec3> TVelocities;
typedef std::vector<TBlobby> TBlobbies;

// vertex shader based blobby cloud
class TBlobbyCloud {
  public:
    TBlobbyCloud(double startTime);
    void Draw(GLhandleARB program_object) const;
    void Update(double elapsedTime);
    void Reset();
    void Load(GLhandleARB program_object);

  private:

    static const int blobCount = 10;
    static const int maxNearestBlobs = 5;

    TPositions positions;
    TVelocities velocities;
    vec3 limit;                         // bounding cube the blobs bounce around within
    double previousTime;                   // used for animation
    mutable GLint count;             // number of blobs to test against
    mutable TPositions blobbyPos;
    mutable TBlobbies nearestBlobs;     // list of neighbouring blobby positions to pass to the current blob getting rendered
    float blobbyCutoff;                 // the radius squared distance used to help determine the nearest neighbours
};
#endif

#ifdef __cplusplus
extern "C" {
#endif

void* newCloud(GLhandleARB program_object, double time);

void updateDrawCloud(void* cloud, GLhandleARB program_object, double time);

void deleteCloud(void* cloud);

#ifdef __cplusplus
}
#endif

#endif