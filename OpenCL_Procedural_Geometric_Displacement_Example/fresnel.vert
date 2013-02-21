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

uniform vec3 LightPosition;
uniform vec3 EyePosition;
uniform float ChromaticDispersion;

uniform float FresnelBias;
uniform float FresnelScale;
uniform float FresnelPower;

varying float LightIntensity;
varying float Alpha;

varying vec4 ProjShadow;
varying vec3 ViewDir;

varying vec3 Reflection;
varying vec3 RefractRed;
varying vec3 RefractGreen;
varying vec3 RefractBlue;
varying float Fresnel;

float fresnel(vec3 incident, vec3 normal, float power, float scale, float bias)
{
  return bias + (pow(min(0.0, 1.0 - dot(incident, normal)), power) * scale);
}

void main() 
{
	vec3 VertexPosition = vec3(gl_ModelViewMatrix * gl_Vertex);
	vec3 VertexNormal = normalize(gl_NormalMatrix * gl_Normal);
	vec3 ViewDir = normalize(-VertexPosition);

    vec3 Incident = normalize(-VertexPosition);
    Reflection = reflect(Incident, VertexNormal);
    RefractRed = refract(Incident, VertexNormal, ChromaticDispersion);
    RefractGreen = refract(Incident, VertexNormal, ChromaticDispersion*2.0);
    RefractBlue = refract(Incident, VertexNormal, ChromaticDispersion*3.0);
    Fresnel = fresnel(Incident, VertexNormal, FresnelPower, FresnelScale, FresnelBias);
	ProjShadow = (gl_TextureMatrix[1] * gl_Vertex);

	gl_Position = ftransform();	
	gl_TexCoord[0] = gl_MultiTexCoord0 * 1.0;

}

