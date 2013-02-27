//
// Fragment shader for producing a fire effect
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying vec3 Position;

uniform float Offset;
uniform vec3 FireColor1;
uniform vec3 FireColor2;
uniform bool Teapot;
uniform float Extent;
uniform sampler3D sampler3d;
void main (void)
{
    vec4 noisevec;
    vec3 color;
    float intensity;
    float alpha;

    noisevec = texture3D(sampler3d, Position);
    noisevec = texture3D(sampler3d, vec3 (Position.x+noisevec[1],
                 Position.y-noisevec[3]+Offset,
                 Position.z+noisevec[1]));

    intensity = 0.75 * (noisevec[0] + noisevec[1] + noisevec[2] + noisevec[3]);

    intensity = 1.95 * abs(2.0 * intensity - 0.35);
    intensity = clamp(intensity, 0.0, 1.0);

    alpha = fract((Position.y+Extent)*0.65);

    color = mix(FireColor1, FireColor2, intensity) * (1.0 - alpha) * 2.0;
    color = clamp(color, 0.0, 1.0);
    alpha = 1.0 - alpha  * intensity;
    alpha *= alpha;

    gl_FragColor = vec4(color, alpha);
}
