//
// Fragment shader for environment mapping with an
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

const vec3 Xunitvec = vec3 (1.0, 0.0, 0.0);
const vec3 Yunitvec = vec3 (0.0, 1.0, 0.0);

uniform vec3  BaseColor;
uniform float Depth;
uniform float MixRatio;

// need to scale our framebuffer - it has a fixed width/height of 2048
uniform float FrameWidth;
uniform float FrameHeight;
uniform float textureWidth;
uniform float textureHeight;

uniform sampler2D EnvMap;
uniform sampler2D RefractionMap;

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;

void main (void)
{
    // Compute reflection vector
    vec3 reflectDir = reflect(EyeDir, Normal);

    // Compute altitude and azimuth angles

    vec2 index;

    index.y = dot(normalize(reflectDir), Yunitvec);
    reflectDir.y = 0.0;
    index.x = dot(normalize(reflectDir), Xunitvec) * 0.5;

    // Translate index values into proper range

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
  
    // Do a lookup into the environment map.

    vec3 envColor = vec3 (texture2D(EnvMap, index));
    
    // calc fresnels term.  This allows a view dependant blend of reflection/refraction
    float fresnel = abs(dot(normalize(EyeDir), Normal));
    fresnel *= MixRatio;
    fresnel = clamp(fresnel, 0.1, 0.9);

	// calc refraction
	vec3 refractionDir = normalize(EyeDir) - normalize(Normal);

	// Scale the refraction so the z element is equal to depth
	float depthVal = Depth / -refractionDir.z;
	
	// perform the div by w
	float recipW = 1.0 / EyePos.w;
	vec2 eye = EyePos.xy * vec2(recipW);

	// calc the refraction lookup
	index.s = (eye.x + refractionDir.x * depthVal);
	index.t = (eye.y + refractionDir.y * depthVal);
	
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
	
    vec3 RefractionColor = vec3 (texture2D(RefractionMap, index));
    
    // Add lighting to base color and mix
    vec3 base = LightIntensity * BaseColor;
    envColor = mix(envColor, RefractionColor, fresnel);
    envColor = mix(envColor, base, 0.2);

    gl_FragColor = vec4 (envColor, 1.0);
}