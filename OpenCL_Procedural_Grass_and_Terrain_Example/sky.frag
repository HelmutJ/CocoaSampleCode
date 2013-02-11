//
// File:       sky.frag
//
// Abstract:   This example shows how OpenCL can be used to create a procedural field of 
//             grass on a generated terrain model which is then rendered with OpenGL.  
//             Because OpenGL buffers are shared with OpenCL, the data can remain on the 
//             graphics card, thus eliminating the API overhead of creating and submitting 
//             the vertices from the host.
//
//             All geometry is generated on the compute device, and outputted into
//             a shared OpenGL buffer.  The terrain gets generated only within the 
//             visible arc covering the camera's view frustum to avoid the need for 
//             culling.  A page of grass is computed on the surface of the terrain as
//             bezier patches, and flow noise is applied to the angle of the blades
//             to simulate wind.  Multiple instances of grass are rendered at jittered
//             offsets to add more grass coverage without having to compute new pages.
//             Finally, a physically based sky shader (via OpenGL) is applied to 
//             the background to provide an environment for the grass.
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


varying vec4 ViewDir;
uniform vec4 CameraPosition;
uniform vec4 CameraDirection;
uniform float Exposure;
uniform float SunAzimuth;

const vec4 SunDirection = vec4(0.0, 300.0, -100.0, 1.0);
const vec4 SunIntensity = vec4(10.0, 10.0, 10.0, 1.0);
const float AtmosphereLengthBias = 1.0;

const float AirZenith = 8400.0;
const float AirHazeRatio = (1.25/8.4);
const float OuterRadius = (6378000.0+AirZenith);
const float InnerRadius = 6378000.0;

const vec4 RaleighCoefficients = vec4(4.1e-06,6.93327e-06,1.43768e-05, 1.0); 
const vec4 MieCoefficients = vec4(2.3e-06,2.3e-06,2.3e-06, 1.0);         
const float Eccentricty = -0.994;                                  

const float PI = 3.14159265358979323846;                           

void AerialPerspective(
	vec3 pos,
	vec3 camera,
	vec3 sun_dir,
    out vec3 extinction,
	out vec3 scatter,
	out vec3 sun_color)
{
    // force viewpoint close to the ground to avoid color shifts
    camera.z = min(camera.z, InnerRadius + (OuterRadius-InnerRadius) * 0.25);

    float s_air  = length(pos - camera);
    float s_haze = s_air * AirHazeRatio;

    vec3 extinction_air_haze = exp( - s_haze * (MieCoefficients.xyz + RaleighCoefficients.xyz) );
    vec3 extinction_air = exp( - (s_air-s_haze)  * RaleighCoefficients.xyz );

    vec3 view_dir = normalize(pos - camera);
    float cos_theta = dot(sun_dir, view_dir);

    vec3 raleigh_theta = (1.0 + cos_theta * cos_theta) * RaleighCoefficients.xyz * 3.0/(16.0*PI);

    vec3 mie_theta = 1.0/(4.0*PI) * MieCoefficients.xyz * (1.0 - (Eccentricty * Eccentricty)) *
                    pow(1.0 + (Eccentricty * Eccentricty) - (2.0 * Eccentricty * cos_theta), -3.0/2.0 );

    float cos_theta_sun = -sun_dir.z;
    float theta_sun = (180.0/PI)*acos(cos_theta_sun);

    float t_air = AirZenith / (cos_theta_sun + 0.15 * pow(93.885 - theta_sun, -1.253) );
    float t_haze = t_air * AirHazeRatio;
    
    sun_color = exp( - (RaleighCoefficients.xyz * t_air + MieCoefficients.xyz * t_haze)  );

    scatter = sun_color * SunIntensity.xyz *
              ( ((raleigh_theta + mie_theta) / (RaleighCoefficients.xyz + MieCoefficients.xyz)) * (1.0 - extinction_air_haze) +
              (raleigh_theta / RaleighCoefficients.xyz) * (1.0 - extinction_air) * extinction_air_haze);
    
    extinction = extinction_air * extinction_air_haze;
}

vec3 ToneMap(vec3 light)
{
    return (1.0 - exp(- light * Exposure));
}

vec3 SkyColorFromAtmosphere(
    vec3 pos, 
    vec3 camera, 
    vec3 sun_dir)
{
    vec3 extinction, scatter, sun_color;
    AerialPerspective(pos, camera, sun_dir, extinction, scatter, sun_color);
    return ToneMap(scatter);
}

void main()
{
    vec3 cam_dir = normalize(vec3(-CameraDirection.x, -CameraDirection.z, CameraDirection.y));
    vec3 view_dir  = cam_dir + normalize(ViewDir.xzy);
    vec3 ray_dir   = view_dir;
    vec3 ray_start = vec3(CameraPosition.xyz) + vec3(0.0, 0.0, InnerRadius);

    float  sin_phi = view_dir.z;
    float  l = (-InnerRadius * sin_phi);
    l += sqrt( (InnerRadius * InnerRadius) * ((sin_phi * sin_phi) - 1.0) + OuterRadius * OuterRadius );
    
    vec3 aerial_dir = normalize(vec3(SunDirection.x, SunAzimuth, SunDirection.z));
    vec3 pos = vec3(0.0, 0.0, InnerRadius) + l * view_dir;
    vec4 color = vec4(SkyColorFromAtmosphere(pos, vec3(0.0, 0.0, InnerRadius), aerial_dir), 1.0);

    gl_FragColor = color;
}

