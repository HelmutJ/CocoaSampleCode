//
// Vertex shader for producing clouds (mostly sunny)
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying float LightIntensity;
varying vec3  MCposition;

uniform vec3  LightPos;
uniform float Scale;

void main(void)
{
    vec4 ECposition = gl_ModelViewMatrix * gl_Vertex;
    MCposition      = vec3 (gl_Vertex) * Scale;
    vec3 tnorm      = normalize(vec3 (gl_NormalMatrix * gl_Normal));
    LightIntensity  = dot(normalize(LightPos - vec3 (ECposition)), tnorm) * 1.5;
    gl_Position     = gl_ModelViewProjectionMatrix * gl_Vertex;
}
