//
// Fragment shader for drawing the earth with multiple textures
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd. 
//
// See 3Dlabs-License.txt for license information
//

uniform sampler2D EarthDay;
uniform sampler2D EarthNight;
uniform sampler2D EarthCloudGloss;

varying float Diffuse;
varying vec3  Specular;
varying vec2  TexCoord;

void main (void)
{
    // Monochrome cloud cover value will be in clouds.r
    // Gloss value will be in clouds.g
    // clouds.b will be unused

    vec2 clouds    = texture2D(EarthCloudGloss, TexCoord).rg;
    vec3 daytime   = (texture2D(EarthDay, TexCoord).rgb * Diffuse + 
                          Specular * clouds.g) * (1.0 - clouds.r) +
                          clouds.r * Diffuse;
    vec3 nighttime = texture2D(EarthNight, TexCoord).rgb * 
                         (1.0 - clouds.r) * 2.0;

    vec3 color = daytime;

    if (Diffuse <= 0.1)
        color = mix(nighttime, daytime, (Diffuse + 0.1) * 5.0);

    gl_FragColor = vec4 (color, 1.0);
}