//
// Fragment shader for producing clouds (mostly sunny)
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying float LightIntensity; 
varying vec3 MCposition;

uniform sampler3D Noise;
uniform vec3 Offset;
uniform vec3 SkyColor;
uniform vec3 CloudColor;

void main (void)
{
    vec4 noisevec = texture3D(Noise, 1.2 * (vec3 (0.5) + MCposition + Offset));

    float intensity = (noisevec[0] + noisevec[1] +
                       noisevec[2] + noisevec[3]) * 1.7;

    intensity = 1.95 * abs(2.0 * intensity - 1.0);
    intensity = clamp(intensity, 0.0, 1.0);

    vec3 color = mix(CloudColor, SkyColor, intensity) * LightIntensity;
    color = clamp(color, 0.0, 1.0); 
    gl_FragColor = vec4 (color, 1.0);
}
