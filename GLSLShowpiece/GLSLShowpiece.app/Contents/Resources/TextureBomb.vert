//
// Vertex shader for texture bombing
//
// Uses a random texture to place 3D polka dots of random color
//	in random locations on the model.  For more information
//	on Texture Bombing techniques see the following books:
//		1.  Texturing and Modeling - A Procedural Approach
//			Copyright 1998 by Ebert et al.
//		2.  GPU Gems Copyright 2005 
//			Edited by Randima Fernando
//
// Author: Joshua Doss
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

//Create uniform variables for lighting to allow user interaction
uniform float SpecularContribution;
uniform vec3 LightPosition;

varying vec3 MCPosition;
varying float LightIntensity;

void main(void)
{
    float diffusecontribution  = 1.0 - SpecularContribution;
    
    // compute the vertex position in eye coordinates
    vec3  ecPosition           = vec3(gl_ModelViewMatrix * gl_Vertex);
    
    // compute the transformed normal
    vec3  tnorm                = normalize(gl_NormalMatrix * gl_Normal);
    
    // compute a vector from the model to the light position
    vec3  lightVec             = normalize(LightPosition - ecPosition);
    
    // compute the reflection vector
    vec3  reflectVec           = reflect(-lightVec, tnorm);
    
    // compute a unit vector in direction of viewing position
    vec3  viewVec              = normalize(-ecPosition);
    
    // calculate amount of diffuse light based on normal and light angle
    float diffuse              = max(dot(lightVec, tnorm), 0.0);
    float spec                 = 0.0;
    
    // if there is diffuse lighting, calculate specular
    if(diffuse > 0.0)
       {
          spec = max(dot(reflectVec, viewVec), 0.0);
          spec = pow(spec, 16.0);
       }
    
    // add up the light sources, since this is a varying (global) it will pass to frag shader     
    LightIntensity  = diffusecontribution * diffuse * 1.5 + SpecularContribution * spec;
    
    // the varying variable MCPosition will be used by the fragment shader to determine where
    //    in model space the current pixel is                      
    MCPosition      = vec3(gl_Vertex);
    
    // send vertex information
    gl_Position     = ftransform();
}
