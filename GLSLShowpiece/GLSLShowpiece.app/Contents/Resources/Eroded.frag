//
// Fragment shader for erosion effect
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying float lightIntensity; 
varying vec3 Position;

uniform vec3 Offset;
uniform sampler3D sampler3d;

void main (void)
{
    vec4 noisevec;
    vec3 color;
    float intensity;

    noisevec = texture3D(sampler3d, 1.2 * (vec3 (0.5) + Position));

    intensity = 0.75 * (noisevec.x + noisevec.y + noisevec.z + noisevec.w);

    intensity = 1.95 * abs(2.0 * intensity - 1.0);
    intensity = clamp(intensity, 0.0, 1.0);

    if (intensity < fract(0.5-Offset.x-Offset.y-Offset.z)) discard;

    color = mix(vec3 (0.2, 0.1, 0.0), vec3(0.8, 0.8, 0.8), intensity);
    
    color *= lightIntensity;
    color = clamp(color, 0.0, 1.0); 

    gl_FragColor = vec4 (color, 1.0);
    
}
