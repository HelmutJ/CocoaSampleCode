//
// Vertex shader for environment mapping with an
// equirectangular 2D texture and refraction mapping
// with a background texture blended together using
// the fresnel terms
//
// Author: Jon Kennedy, based on the envmap shader by John Kessenich, Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;

uniform vec3  LightPos;

void main(void) 
{
    gl_Position    = ftransform();
    Normal         = normalize(gl_NormalMatrix * gl_Normal);
    vec4 pos       = gl_ModelViewMatrix * gl_Vertex;
    EyeDir         = pos.xyz;
    EyePos		   = gl_ModelViewProjectionMatrix * gl_Vertex;
    LightIntensity = max(dot(normalize(LightPos - EyeDir), Normal), 0.0);
}