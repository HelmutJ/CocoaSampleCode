//
// Author:    Jon Kennedy
// Copyright: 2002-2006  3Dlabs Inc. Ltd.  All rights reserved.
// License:   see 3Dlabs-license.txt
//

#define _USE_MATH_DEFINES
#include "BlobbyCloudSupport.h"
#include "os.h"
#include <algorithm>
#include <vector>

// sorting predicate
bool compareBlobs(const TBlobby& b1, const TBlobby& b2)
{
    return b1.distSqr < b2.distSqr;
}

#define slices 16

TBlobbyCloud::TBlobbyCloud(double startTime):positions(blobCount), velocities(blobCount), nearestBlobs(blobCount), blobbyPos(maxNearestBlobs)
{
    blobbyCutoff = 100.0;
    limit = vec3(10.0f, 10.0f, 10.0f);
    previousTime = startTime;

    srand(30757);

    // seed the positions
    for(int ii = 0; ii < blobCount; ++ii) {
        positions[ii].x = ((float) rand() / RAND_MAX) * 0.5f;
        positions[ii].y = ((float) rand() / RAND_MAX) * 0.5f;
        positions[ii].z = ((float) rand() / RAND_MAX) * 0.5f;
    }

    // seed the velocities
    for(int ii = 0; ii < blobCount; ++ii) {
        velocities[ii].x = (((float) rand() / RAND_MAX) - 0.5) * 2.0;
        velocities[ii].y = (((float) rand() / RAND_MAX) - 0.5) * 2.0;
        velocities[ii].z = (((float) rand() / RAND_MAX) - 0.5) * 2.0;
    }
}

void TBlobbyCloud::Update(double elapsedTime)
{
    float deltaTime;

    deltaTime = float(elapsedTime - previousTime);

    previousTime = elapsedTime;

    //deltaTime *= 100.0f;

    for(int ii = 0; ii < (blobCount); ii++) {
        positions[ii] = positions[ii] + velocities[ii] * deltaTime;

        if (positions[ii].x > limit.x) {
            velocities[ii].x = 0 - velocities[ii].x;
            positions[ii].x = limit.x;
        } else if (positions[ii].x < -limit.x) {
            velocities[ii].x = 0 - velocities[ii].x;
            positions[ii].x = -limit.x;
        }
        
        if (positions[ii].y > limit.y) {
            velocities[ii].y = 0 - velocities[ii].y;
            positions[ii].y = limit.y;
        } else if (positions[ii].y < -limit.y) {
            velocities[ii].y = 0 - velocities[ii].y;
            positions[ii].y = -limit.y;
        }
        
        if (positions[ii].z > limit.z) {
            velocities[ii].z = 0 - velocities[ii].z;
            positions[ii].z = limit.z;
        } else if (positions[ii].z < -limit.z) {
            velocities[ii].z = 0 - velocities[ii].z;
            positions[ii].z = -limit.z;
        }
    }
}


void TBlobbyCloud::Load(GLhandleARB program_object)
{
     // Set up some default values for the uniforms and send them to the card.
    count = blobCount;
	glUniform1iARB(glGetUniformLocationARB(program_object, "BlobbyCount"), count);

    char name[] = "BlobbyPos[xx]";
    for(int ii = 0; ii < maxNearestBlobs; ++ii) {
        sprintf(name, "BlobbyPos[%2d]", ii);
		blobbyPos[ii] = vec3(0, 0, 0);
		glUniform3fARB(glGetUniformLocationARB(program_object, name), blobbyPos[ii].x, blobbyPos[ii].y, blobbyPos[ii].z);
    }
}

void TBlobbyCloud::Draw(GLhandleARB program_object) const
{
    for (int ii = 0; ii < blobCount; ++ii) {
        //
        // Find the closest neighbours
        //
        for(int jj = 0; jj < blobCount; ++jj) {
            vec3 distSqr = positions[ii] - positions[jj];
            nearestBlobs[jj].blob = jj;
            nearestBlobs[jj].distSqr = distSqr.mag2();
        }

        std::sort(nearestBlobs.begin(), nearestBlobs.end(), compareBlobs);

        //
        // This is safe as we should always get 1 (ie. the actual blob itself)
        //
        int nearestCount = 0;
        TBlobbies::iterator pBlobs = nearestBlobs.begin();
		char name[] = "BlobbyPos[xx]";
        do {
            vec3 center = positions[pBlobs->blob];
			sprintf(name, "BlobbyPos[%2d]", pBlobs->blob);
            blobbyPos[nearestCount] = vec3(center.x, center.y + 2.5f, center.z);
            glUniform3fARB(glGetUniformLocationARB(program_object, name), blobbyPos[nearestCount].x, blobbyPos[nearestCount].y, blobbyPos[nearestCount].z);
            ++nearestCount;
            ++pBlobs;
        } while((pBlobs->distSqr < blobbyCutoff) && (nearestCount < maxNearestBlobs));

        //
        // Tell the shader how many blobs to test
        //
		count = nearestCount;
        glUniform1iARB(glGetUniformLocationARB(program_object, "BlobbyCount"), count);

        //
        // Render it.  
        // The scale factor is to adjust each vertex so it is closer to the desirable radius of influence,
        // hence ensures less travel is required for the verts as they migrate along the normal to find the isosurface.
        // Ideally we would change the size of the original sphere, but this works just as well.
        //
        glPushMatrix();
        glScalef(0.1f, 0.1f, 0.1f);
glTranslatef(blobbyPos[ii].x, blobbyPos[ii].y, blobbyPos[ii].z);
		TSphere().Draw(slices);
        glPopMatrix();
    }
}

void* newCloud(GLhandleARB program_object, double time)
{
	TBlobbyCloud* blobbyCloud = new TBlobbyCloud(time);
	blobbyCloud->Load(program_object);
	return blobbyCloud;
}

void updateDrawCloud(void* cloud, GLhandleARB program_object, double time)
{
	TBlobbyCloud* blobbyCloud = (TBlobbyCloud*)cloud;
	blobbyCloud->Update(time);
	blobbyCloud->Draw(program_object);
}

void deleteCloud(void* cloud)
{
	TBlobbyCloud* blobbyCloud = (TBlobbyCloud*)cloud;
	delete blobbyCloud;
}
