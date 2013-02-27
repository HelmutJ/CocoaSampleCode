//
// Vertex shader for heathaze.
//
// Author: Jon Kennedy
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying vec4  EyePos;

void main(void) 
{
    gl_Position = ftransform();
    EyePos      = gl_ModelViewProjectionMatrix * gl_Vertex;
}