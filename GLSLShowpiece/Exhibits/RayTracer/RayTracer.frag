/*

File: RayTracer.frag

Abstract: Ray Tracing Shader


 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
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
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
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

  Copyright (c) 2004-2006 Apple Computer, Inc., All rights reserved.

*/

struct Ray
{
	vec3 start;
	vec3 direction;
};

//Light

uniform vec3 lightColor;
uniform vec3 lightPosition;

void applyLight(inout vec3 pixelColor,vec3 intersection,vec3 normal,float exposed)
{
	vec3 direction=normalize(lightPosition-intersection);
	float intensity=dot(direction,normal)*exposed;
	//if(intensity>0.0)//its ok if color is negative... (it will get clamped)
	{
		pixelColor+=lightColor*intensity;
	}
}

//Ray

vec3 pointOnRay(Ray ray,float uValue)
{
	return ray.start+(ray.direction*uValue);
}

struct HitInformation
{
	float uValue;
	//Texture texture;
	//Solid solidHit;
	bool negate;
vec3 solidColor;
};

struct HitInformations
{
	int numberOfHits;//number of hits
	HitInformation hits[8];//max number of hits for a Solid
};

//Sphere

uniform vec3 sphereColor;
uniform vec3 spherePosition;
uniform float radius;

HitInformations intersectsRayAt(Ray ray)
{
	HitInformations hitInfo;
	Ray detransformedRay;

	detransformedRay.start=ray.start-spherePosition;
	//detransformEquals(detransformedRay.start);//cant rotate sphere anyhow...
	////A2(T*T)+A1(T)+A0
	//need length squared of detransformedRay.start
	float A0=dot(detransformedRay.start,detransformedRay.start)-(radius*radius);
	float A1=dot(detransformedRay.start,ray.direction);
	////A2=1
	float squared=A1*A1-A0;
	if(squared>=0.0)//(A0<=0||A1<=0)&&
	{
		float sqrted=sqrt(squared);
		hitInfo.hits[0].uValue=-A1-sqrted;
		//hitInfo.hits[0].texture=texture;
		//hitInfo.hits[0].solidHit=this;
		hitInfo.hits[0].negate=false;
		hitInfo.hits[0].solidColor=sphereColor;//hardcoded sphere color
		hitInfo.hits[1].uValue=-A1+sqrted;
		//hitInfo.hits[1].texture=texture;
		//hitInfo.hits[1].solidHit=this;
		hitInfo.hits[1].negate=false;
		hitInfo.hits[1].solidColor=sphereColor;//hardcoded sphere color
		hitInfo.numberOfHits=2;
	}
	else
	{
		hitInfo.numberOfHits=0;
	}
	return hitInfo;
}

vec3 normalAt(vec3 intersection)
{
	return (intersection-spherePosition)/radius;
}

//Solid

HitInformations intersectsRayAt(Ray ray);
vec3 normalAt(vec3 intersection);

//Ray

vec3 pointOnRay(Ray ray,float uValue);

//Light

void applyLight(inout vec3 pixelColor,vec3 intersection,vec3 normal,float exposed);

//RayTracer

uniform vec2 frame;

void main()
{
	Ray ray;
	//setup ray
	ray.start=vec3(0,0,3);//eye
	vec3 fixedFragCoord=vec3(gl_FragCoord.xy*vec2(1.0/(frame*0.5))-1.0,0.0);

	ray.direction=normalize(fixedFragCoord-ray.start);//from eye
	HitInformations hitInfo=intersectsRayAt(ray);
	if(hitInfo.numberOfHits==0||hitInfo.hits[0].uValue<=0.0)
	{
		discard;//discard early...
	}
	//else//discard in true part
	{
		vec3 intersection=pointOnRay(ray,hitInfo.hits[0].uValue);
		vec3 normal=normalAt(intersection);
		vec3 solidColor=hitInfo.hits[0].solidColor;//vec4(normal.xyz,1);
		vec3 rayColor=vec3(0);
		applyLight(rayColor,intersection,normal,1.0);
		/*if(solidColor.reflectivity!=0&&lightRay!=null)//lights[i].getClass()==PointLight.class)
		{
			double dotProd=reflectionVector.dot(lightRay.direction);
			if(dotProd>0)
			{
				dotProd=Math.pow(dotProd,16);
				highlightColor.addEquals(lights[i].color,dotProd);
			}
		}*/
		gl_FragColor=vec4(rayColor*solidColor,1);
		//gl_FragColor=vec4(intersection,1);//show the intersections with the surface
		//gl_FragColor=vec4(normal,1);//show the normals of the surface
		//gl_FragColor=vec4(vec3(hitInfo.hits[0].uValue),1);//show the distance from the surface
		//gl_FragDepth=f(hitInfo.hits[0].uValue);//depth is a function of uValue
	}
}
