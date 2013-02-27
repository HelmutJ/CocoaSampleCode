//
// Fragment shader for blobby molecule bubbles
//
// Author: Jon Kennedy
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd. 
//
// See 3Dlabs-License.txt for license information
//

//
// Required constants
//
const vec3 Xunitvec = vec3 (1.0, 0.0, 0.0);
const vec3 Yunitvec = vec3 (0.0, 1.0, 0.0);
const vec3 Luminance = vec3(0.2125, 0.7154, 0.0721);

// 
// Uniforms
//
uniform vec3      BaseColor;
uniform float     MixRatio;
uniform sampler2D EnvMap;
uniform sampler2D RefractionMap;
uniform sampler2D RainbowMap;

// need to scale our framebuffer
uniform float FrameWidth;
uniform float FrameHeight;
uniform float textureWidth;
uniform float textureHeight;

//
// Varyings from the vertex shader
//
varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;
varying float Radius;

void main (void)
{
	//
    // Compute reflection vector
    //
    vec3 reflectDir = reflect(EyeDir, Normal);

	//
    // Compute altitude and azimuth angles
	//
    vec2 index;

    index.y = dot(normalize(reflectDir), Yunitvec);
    reflectDir.y = 0.0;
    index.x = dot(normalize(reflectDir), Xunitvec) * 0.5;

	//
    // Translate index values into proper range
	//
    if (reflectDir.z >= 0.0)
        index = (index + 1.0) * 0.5;
    else
    {
        index.t = (index.t + 1.0) * 0.5;
        index.s = (-index.s) * 0.5 + 1.0;
    }
    
    // if reflectDir.z >= 0.0, s will go from 0.25 to 0.75
    // if reflectDir.z <  0.0, s will go from 0.75 to 1.25, and
    // that's OK, because we've set the texture to wrap.
  
	//
    // Do a lookup into the environment map.
    //
    vec3 envColor = vec3 (texture2D(EnvMap, index));
    
    //
    // Do a lookup into the bubblemap - this provides the oily swirly surface, so it needs to animate
    //
    vec3 rainbowColor = vec3 (texture2D(RainbowMap, sin(EyeDir.xy) + index)) + 0.6;
    
    //
    // calc fresnels term.  This allows a view dependant blend of reflection/refraction
    //
    float fresnel = abs(dot(normalize(EyeDir), Normal));
    fresnel *= MixRatio;
    fresnel = clamp(fresnel, 0.5, 0.9);		

	//
	// Perform the framebuffer lookup
	//
	
	//
	// perform the div by w
	//
	float recipW = 1.0 / EyePos.w;
	vec2 eye = EyePos.xy * vec2(recipW);

	//
	// scale and shift so we're in the range 0-1
	//
	index.s = eye.x / 2.0 + 0.5;
	index.t = eye.y / 2.0 + 0.5;
	
	//
	// as we're looking at the framebuffer, we want it clamping at the edge of the rendered scene, not the edge of the texture,
	// so we clamp before scaling to fit
	//
    float recipTextureWidth = 1.0 / textureWidth;
    float recipTextureHeight = 1.0 / textureHeight;
	index.s = clamp(index.s, 0.0, 1.0 - recipTextureWidth);
	index.t = clamp(index.t, 0.0, 1.0 - recipTextureHeight);
	
	//
	// scale the texture so we just see the rendered framebuffer
	//
	index.s = index.s * FrameWidth * recipTextureWidth;
	index.t = index.t * FrameHeight * recipTextureWidth;
	
	//
	// do the lookup
	//
    vec3 RefractionColor = vec3 (texture2D(RefractionMap, index));
    
    //
    // We only want the luminance to be reflected, not the colour.  Multiply it up to saturate it slightly
    //
    float envIntensity = dot(envColor, Luminance) * 2.0;
    rainbowColor *= envIntensity;
    
    //
    // Mix in the refracted colour
    //
    envColor = mix(rainbowColor, RefractionColor, fresnel);
    
    //
    // Add lighting to base color and mix
    //
    vec3 base = LightIntensity * BaseColor;
    envColor = mix(envColor, base, 0.2);
    gl_FragColor = vec4 (envColor, 1.0);
}