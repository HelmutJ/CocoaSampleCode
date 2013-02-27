
// This is a fragment shader to show texture bombing.  It uses
//   a random texture to place 3D polka dots of random color
//   in random locations on the model.  For more information
//   on Texture Bombing techniques see the following books:
//      1.  Texturing and Modeling - A Procedural Approach
//         Copyright 1998 by Ebert et al.
//      2.  GPU Gems Copyright 2005 
//         Edited by Randima Fernando
//
// author(s): Joshua Doss
//
// Copyright (C) 2002-2006  3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//


varying float LightIntensity;
varying vec3 MCPosition;

//Create uniform variables so dots can be spaced and scaled by user
uniform float Scale, DotSize;
uniform sampler2D RandomTex;

//Create colors as uniform variables so they can be easily changed
uniform vec3 ModelColor, PolkaDotColor;
uniform vec3 DotOffset;
uniform vec2 ColourTextureAdditive,  PositionTextureMultiplier;
uniform bool RandomDots, RandomDotColours;

void main(void)
{
   float radius2;
   vec2  randomXY;
   vec3  finalcolor = ModelColor.xyz;
   vec3  dotSpacing = vec3(Scale); 
   vec3  scaledXYZ = MCPosition * dotSpacing;
   vec3  cell = floor(scaledXYZ);
   vec3  offset = scaledXYZ - cell;
   vec3  currentOffset;
   vec4  random;
   
   float priority = -1.0;
   for(float i = -1.0; i <= 0.0; i++)
   {
      for(float j = -1.0; j <= 0.0; j++)
      {
         for(float k = -1.0; k <= 0.0; k++)
         {
             vec3 currentCell = cell + vec3(i, j, k);
       
             vec3 cellOffset = offset - vec3(i, j, k);

             randomXY = currentCell.xy * PositionTextureMultiplier + currentCell.z * 0.003;
             
             random = texture2D(RandomTex, randomXY);
             if(RandomDots)
             {
                currentOffset = cellOffset - (vec3(0.5, 0.5, 0.5) + vec3(random));
             }
             else
             {
                currentOffset = cellOffset - (vec3(0.5, 0.5, 0.5) + DotOffset);
             }
             radius2 = dot(currentOffset, currentOffset);
                          
             if(random.w > priority && radius2 < DotSize)
             {
                if(RandomDotColours)
                {
                   finalcolor = texture2D(RandomTex, randomXY + ColourTextureAdditive).xyz;
                }
                else
                {
                   finalcolor = PolkaDotColor.xyz;
                }               
                priority = random.w;
             }
         }
      }
   }      

   // Output final color and factor in lighting
   gl_FragColor      = (vec4( finalcolor, 1.0 ) * LightIntensity);
}
