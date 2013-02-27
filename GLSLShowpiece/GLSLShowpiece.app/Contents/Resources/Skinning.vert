
//
// skinning.vert: uses two matrices to create a "blended" vertex
//
// author: Philip Rideout
//
// Copyright (c) 2005-2006: 3Dlabs, Inc.
//
//
// See 3Dlabs-License.txt for license information
//

uniform vec3 LightPosition;
uniform vec3 SurfaceColor;
varying vec4 Color;
uniform int index0;
uniform int index1;
uniform mat4 transforms[13];
attribute float weight;

void main(void)
{
    mat4 transform = transforms[index0] * weight + transforms[index1] * (1.0 - weight);
    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);;
    vec3 position = vec3(gl_ModelViewMatrix * gl_Vertex);
    vec3 lightVec   = normalize(LightPosition - position);
    float diffuse   = max(dot(lightVec, normal), 0.0);

    if (diffuse < 0.125)
         diffuse = 0.125;

    Color = vec4(SurfaceColor * diffuse, 1.0);
    gl_Position = transform * gl_Vertex;
}
