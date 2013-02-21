//
// File:       fresnel.frag
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

varying vec3 VertexPosition;
varying vec3 VertexNormal;
varying vec4 ProjShadow;
varying vec3 ScreenPosition;
varying vec3 ViewDir;

varying vec3 Reflection;
varying vec3 RefractRed;
varying vec3 RefractGreen;
varying vec3 RefractBlue;
varying float Fresnel;

uniform vec3 LightPosition;
uniform vec3 EyePosition;
uniform vec3 DiffuseColor;
uniform float ShadowMapSize;
uniform float ShadowMapSoftness;
uniform float JitterTableSize;
uniform float RefractiveIndex;
uniform float ChromaticDispersion;
uniform float NormalIntensity;

uniform sampler2D LightProbeMap;
uniform sampler2DShadow ShadowMap;
uniform sampler3D JitterTable;

vec2 angularMapCoord(vec3 dir)
{   
    float r = (1.0 / 3.1415927) * acos(dir.z) / sqrt(dir.x*dir.x + dir.y*dir.y);
    vec2 st = vec2(0.5 + 0.5 * r * dir.x, 0.5 + 0.5 * r * -dir.y);    
    return st;    
}

void refractFresnel(
    vec3 view, vec3 normal, float outside, float inside, 
    out vec3 reflection, out vec3 refraction, 
    out float reflectance, out float transmittance)
{
    float eta = outside / inside;
    float theta1 = dot(view, normal);
    float theta2 = sqrt(1.0 - ((eta * eta) * ( 1.0 - (theta1 * theta1))));

    float rs = (outside * theta1 - inside * theta2) / (outside * theta1 + inside * theta2);
    float rp = (inside * theta1 - outside * theta2) / (inside * theta1 + outside * theta2);
    float omrs = 1.0 - rs;    
    float omrp = 1.0 - rp;

    reflection = view - 2.0 * theta1 *normal;
    refraction = (eta * view) + (theta2 - eta * theta1) * normal;
    
    reflectance = (rs * rs + rp * rp) * 0.5;
    transmittance = (omrs * omrs + omrp * omrp) * 0.5;
}

float jitterShadow(vec4 coord, float dt, float size, vec3 jitterCoord, float jitterSize, float softwidth) 
{
    float value = 0.0;
    float weight = 0.125;
    float weight2 = 0.015625;
    
    for( int i = 0; i < 4; i++)
    {
        vec4 offset = texture3D( JitterTable, jitterCoord ) * softwidth;
        value = value + shadow2DProj(ShadowMap, coord + vec4(offset.x, offset.y, 0.0, 0.0)).x * weight;
        value = value + shadow2DProj(ShadowMap, coord + vec4(offset.w, offset.z, 0.0, 0.0)).x * weight;
        jitterCoord.z += 0.03125;
    }
    return value;
}

void main(void)
{
    float ambient = 0.5;
    
    vec3 reflectionRed;
    vec3 refractionRed;
    float reflectanceRed;
    float transmittanceRed;

    vec3 reflectionGreen;
    vec3 refractionGreen;
    float reflectanceGreen;
    float transmittanceGreen;

    vec3 reflectionBlue;
    vec3 refractionBlue;
    float reflectanceBlue;
    float transmittanceBlue;
    
    vec4 reflectDir;
    vec4 refractDir;
    
    vec2 reflectUV;
    vec2 refractUV;
       
    reflectDir = normalize(gl_ModelViewMatrix * vec4(Reflection, 0.0));
    reflectUV = angularMapCoord(Reflection.xyz);
    vec4 reflect = texture2D(LightProbeMap, reflectUV);

    refractDir = normalize(gl_ModelViewMatrix * vec4(RefractRed, 0.0));
    refractUV = angularMapCoord(RefractRed.xyz);
    vec4 refractRed = texture2D(LightProbeMap, refractUV);

    refractDir = normalize(gl_ModelViewMatrix * vec4(RefractGreen, 0.0));
    refractUV = angularMapCoord(RefractGreen.xyz);
    vec4 refractGreen = texture2D(LightProbeMap, refractUV);
    
    refractDir = normalize(gl_ModelViewMatrix * vec4(RefractBlue, 0.0));
    refractUV = angularMapCoord(RefractBlue.xyz);    
    vec4 refractBlue = texture2D(LightProbeMap, refractUV);

    vec4 FresnelColor = mix(reflect, vec4(refractRed.r, refractGreen.g, refractBlue.b, 1.0), Fresnel);
    vec4 color = FresnelColor;
    color.a = Fresnel * 0.5 + 0.5;
    
    float jitterScale = (1.0 / JitterTableSize);
    vec3 jitterCoord = vec3( gl_FragCoord.xy * jitterScale, 0.0 );
    float shadowScale = (1.0/ShadowMapSize);

    float shadow = jitterShadow(ProjShadow, shadowScale, ShadowMapSize, jitterCoord, jitterScale, ShadowMapSoftness);
    color.rgb *= ambient + shadow * ambient;	

	gl_FragColor = color;
}


