//
// File:       phong.frag
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

uniform vec3 LightPosition;
uniform vec3 EyePosition;
uniform vec3 DiffuseColor;
uniform float ShadowMapSize;
uniform float ShadowMapSoftness;
uniform float JitterTableSize;

uniform float NormalIntensity;

uniform sampler2DShadow ShadowMap;
uniform sampler3D JitterTable;

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
    
    if( value * (value - 1.0) != 0.0 )
    {
        value *= weight;
        for( int i = 0; i < 28; i++)
        {
            vec4 offset = texture3D( JitterTable, jitterCoord ) * softwidth;
            value = value + shadow2DProj(ShadowMap, coord + vec4(offset.x, offset.y, 0.0, 0.0)).x * weight2;
            value = value + shadow2DProj(ShadowMap, coord + vec4(offset.w, offset.z, 0.0, 0.0)).x * weight2;
            jitterCoord.z += 0.03125;
        }
        
    }
    return value;
}

vec3 phong( vec3 light, vec3 eye, vec3 pt, vec3 N )
{
   vec3 diffuse = DiffuseColor; 
   float specularExponent = 16.0;  
   float specularity = 0.45;        

   vec3 L = normalize( light - pt ); 
   vec3 E = normalize( -eye   - pt );  
   float NdotL = dot( N, L );   
   vec3 R = L - 2.0 * NdotL * N; 

   diffuse += abs( N ) * NormalIntensity;
   
   return diffuse * max( NdotL, 0.0 ) + specularity*pow( max(dot(E,R),0.00001), specularExponent );
}

void main(void)
{
    float ambient = 0.5;
    
	vec4 color;
	color.rgb = phong(LightPosition, EyePosition, VertexPosition, VertexNormal);
	color.a = 1.0;
	
    float jitterScale = (1.0 / JitterTableSize);
    vec3 jitterCoord = vec3( gl_FragCoord.xy * jitterScale, 0.0 );
    float shadowScale = (1.0/ShadowMapSize);

    float shadow = jitterShadow(ProjShadow, shadowScale, ShadowMapSize, jitterCoord, jitterScale, ShadowMapSoftness);
    color.rgb *= ambient + shadow * ambient;
	gl_FragColor = color;
}


