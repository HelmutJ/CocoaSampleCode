
//
// particle.vert: Vertex shader for a particle fountain.
//
// author: Philip Rideout
//
// Copyright (c) 2005-2006: 3Dlabs, Inc.
//
//
// See 3Dlabs-License.txt for license information
//

uniform float time;
varying vec4 Color;

const float radius = 0.3;

void main(void)
{
	vec4 vertex = gl_Vertex;
	float t1 = mod(time, 5.0);
	vertex.x = radius * gl_Color.y * t1 * sin(gl_Color.x * 6.28);
	vertex.z = radius * gl_Color.y * t1 * cos(gl_Color.x * 6.28);

	float h = gl_Color.y * 1.25;
	float t2 = mod(t1, h*2.0);
	vertex.y = -(t2-h)*(t2-h)+h*h;
	vertex.y -= 1.0;
	gl_Position = gl_ModelViewProjectionMatrix * vertex;

	Color.r = 1.0;
	Color.g = 1.0 - gl_Color.y;
	Color.b = 0.0;
	Color.a = 1.0 - t1 / 5.0;
}
