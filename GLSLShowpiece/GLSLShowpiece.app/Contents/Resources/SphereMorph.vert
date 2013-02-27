
//
// spheremorph.vert: morphs a plane into a sphere
//
// author: Philip Rideout
//
// Copyright (c) 2005-2006: 3Dlabs, Inc.
//
//
// See 3Dlabs-License.txt for license information
//

varying vec4 Color;

uniform vec3 LightPosition;
uniform vec3 SurfaceColor;

const float twopi = 6.28318;
const float pi = 3.14159;

uniform float radius;
uniform float blend;

vec3 sphere(vec2 domain)
{
    vec3 range;
    range.x = radius * cos(domain.y) * sin(domain.x);
    range.y = radius * sin(domain.y) * sin(domain.x);
    range.z = radius * cos(domain.x);
    return range;
}

void main(void)
{
    vec2 p0 = gl_Vertex.xy * twopi;

    vec3 normal = sphere(p0);;
    vec3 r0 = radius * normal;
    vec3 vertex = r0;

    normal = normal * blend + gl_Normal * (1.0 - blend);
    vertex = vertex * blend + gl_Vertex.xyz * (1.0 - blend);

    normal = normalize(gl_NormalMatrix * normal);
    vec3 position = vec3(gl_ModelViewMatrix * vec4(vertex,1.0));

    vec3 lightVec   = normalize(LightPosition - position);
    float diffuse   = max(dot(lightVec, normal), 0.0);

    if (diffuse < 0.125)
         diffuse = 0.125;

    Color = vec4(SurfaceColor * diffuse, 1.0);
    gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex,1.0);
}
