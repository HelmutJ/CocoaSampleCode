//
// Fragment shader for heathaze.
//
// Author: Jon Kennedy
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

uniform float FrameWidth;
uniform float FrameHeight;
uniform float textureWidth;
uniform float textureHeight;
uniform float Frequency;
uniform float Offset;
uniform float Fade;
uniform int   Speed;

uniform sampler2D FrameBuffer;

varying vec4  EyePos;

void main (void)
{
    vec2 index;

    // perform the div by w to put the texture into screen space
    float recipW = 1.0 / EyePos.w;
    vec2 eye = EyePos.xy * vec2(recipW);

    // calc the heathaze fade - this makes it do a linear fade proportional to the Y value.
    float blend = max(1.0 - (eye.y + Fade), 0.0);   
        
    // calc the wobble
    index.s = eye.x ;
    index.t = eye.y + blend * sin(Frequency * 5.0 * eye.y + Offset * float(Speed)) * 0.06;
        
    // scale and shift so we're in the range 0-1
    index.s = index.s / 2.0 + 0.5;
    index.t = index.t / 2.0 + 0.5;
        
    // as we're looking at the framebuffer, we want it clamping at the edge of the rendered scene, not the edge of the texture,
    // so we clamp before scaling to fit
    float recipTextureWidth = 1.0 / textureWidth;
    float recipTextureHeight = 1.0 / textureHeight;
    index.s = clamp(index.s, 0.0, 1.0 - recipTextureWidth);
    index.t = clamp(index.t, 0.0, 1.0 - recipTextureHeight);

    // scale the texture so we just see the rendered framebuffer
    index.s = index.s * FrameWidth * recipTextureWidth;
    index.t = index.t * FrameHeight * recipTextureHeight;
        
    vec3 RefractionColor = vec3 (texture2D(FrameBuffer, index));
    
    gl_FragColor = vec4 (RefractionColor, 1.0);
}
