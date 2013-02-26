/*

File: WoodShader.fragment

Abstract: Wood Shader

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

  Copyright (c) 2004-2006 Apple Inc., All rights reserved.

*/

uniform float graininess;
uniform float lininess;
uniform float linecount;
uniform float lineperiod;
uniform float linethickness;
uniform vec2 seed;

varying vec2 MCposition;
varying float LightIntensity;

const vec3 basewood_a = vec3((182.0 * 0.004), (154.0 * 0.004), (122.0 * 0.004));
const vec3 basewood_b = vec3((96.0 * 0.004), (57.0 * 0.004), (19.0 * 0.004));

uniform sampler3D Noise;

void main() 
{
	float noise;
	float f;
	vec3  basewood;
	float woodgrain;
	vec3  woodlines;
	vec3  color;
	vec2  v = MCposition;

	v += seed;

	/* Generate the base wood color */
	v.y *= 0.2;
	//noise = float(noise2(v * 4.0) * 0.5 + 0.5);
	noise = float(texture3D(Noise, vec3(v * 4.0, v.x) * 0.25) * 0.5 + 0.5);
	basewood = mix(basewood_a, basewood_b, noise);

	/* Generate the wood grain */
	v.y *= 0.2;
	//woodgrain = float(noise2(v * 150.0) * 0.5 + 0.5);
	woodgrain = float(texture3D(Noise, vec3(v * 150.0, v.x) * 0.25) * 0.5 + 0.5);
	
	/* Generate the wood lines */
	//noise = noise1(v.x);
	noise = float(texture3D(Noise, vec3(v.x) * 0.25));
	f = step(fract( (woodgrain * 0.30 * graininess) + ((v.y * linecount) + (sin(v.x * lineperiod) * noise)) * 6.0), 
		    linethickness);

	/* Build a composite of all the component colors */
	color = basewood - (woodgrain * graininess) - (f * lininess);

	color *= LightIntensity;
	gl_FragColor = vec4(color, 1.0);

	
}