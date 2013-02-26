//
// Vertex shader for producing a fire effect
//
// Author: Randi Rost
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

varying vec3 Position;
uniform float Scale;

void main(void)
{
	Position = vec3(gl_Vertex) * Scale;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
