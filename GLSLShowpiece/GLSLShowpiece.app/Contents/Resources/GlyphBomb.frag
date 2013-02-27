// This is a fragment shader to show texture bombing.  It uses
//   a random texture to place glyphs of random color
//   in random locations on the model.  For more information
//   on Texture Bombing techniques see the following books:
//      1.  Texturing and Modeling - A Procedural Approach
//         Copyright 1998 by Ebert et al.
//      2.  GPU Gems Copyright 2004 
//         Edited by Randima Fernando
//
// author(s): Joshua Doss
//
// Copyright (C) 2002-2006  3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

uniform vec3      ModelColor;

uniform sampler2D glyphTex;
uniform sampler2D RandomTex;

uniform float     ColAdjust;
uniform float     ScaleFactor;
uniform float     Percentage;
uniform float     SamplesPerSquare;
uniform float     RO1;
uniform float     RO2;

uniform bool      RandomScale;
uniform bool      RandomRotate;

varying vec2      uv;

varying float     LightIntensity;

void main(void)
{
   vec4 color    = vec4(ModelColor, 1.0);
   vec2 scaledUV = (uv * ScaleFactor);
   vec2 cell     = floor(scaledUV);
   vec2 offSet   = scaledUV - cell;
   
// Since we have random offset and random rotation, we must sample cells outside
//   of the cell we are currently in.  Since the offset is always in the same direction,
//   we know which four cells we need to sample.  If we add in rotation, the potential
//   exists for the glyph to exit the cell into any of the surrounding cells, thus we
//   need to iterate through all 9 cells.
//
// Below is a pictorial of the neighboring cells to be checked with rotation and
//   without rotation.  The "X" in a cell denotes the cell where the 
//   current fragment is located.
//
//     No Rotation                       With Rotation
//   ---------------          --------------------------------
//   |      |      |          |          |          |        |
//   |      |   X  |          |          |          |        |
//   |      |      |          |          |          |        |
//   ---------------          --------------------------------
//   |      |      |          |          |          |        |
//   |      |      |          |          |    X     |        |
//   |      |      |          |          |          |        |
//   ---------------          --------------------------------
//                            |          |          |        |
//                            |          |          |        |
//                            |          |          |        |
//                            --------------------------------
//
   
// If random rotation is turned on (RandomRotate == True == 1), 9 cells must be sampled per pass, 
//   if random rotation is off (RandomRotate == False == 0), only 4 cells need to be sampled.
//   We can use an integer constructor here with the boolean uniform RandomRotate in order to set the number
//   of cells to sample.

   for(int i = -1; i<=int (RandomRotate); i++)
   {
   for(int j = -1; j<=int (RandomRotate); j++)
      {
         vec2 currentCell    = cell + vec2 ( float ( i ) , float ( j ) );
         vec2 currentOffSet  = offSet - vec2 ( float ( i ) , float ( j ) );

//   We need a set of random values, to avoid sampling the same point
//      on our texture we multiply the current cell by a vec2 with
//      x, y components less than 1.  To allow for more user interaction
//      we will allow the user to adjust these through the use of uniform
//      variables (RO1, RO2) that are clamped from 0.0 to 1.0.  We will 
//      use the randomUV value to index into our random texture.

         vec2 randomUV       = currentCell.xy * vec2(RO1, RO2);
         
//   To give the option of sampling each cell multiple times, we need to loop
//      again for the number of times we wish to draw a glyph per cell.

         for(int k = 0; k < int (SamplesPerSquare); k++)
            {
             randomUV           += vec2(0.79, 0.388);
             vec4 random         = texture2D(RandomTex, randomUV);
               
//   A more random appearance is generated if some of the cells do not sample
//      the texture for a glyph.  Adjusting the Percentage uniform allows the
//      user to increase or decrease the likelihood of a cell getting sampled.

               if(random.x < Percentage)
               {
                  vec2 glyphIndex;
                  mat2 rotator;
                  
//   We need to index into our glyph texture.  The floor function will divide
//      our texture into 10 sections in each direction, thus giving us 100 glyphs
//      to access.  The variable colAdjust is a uniform that allows the user to select
//      which row to access glyphs from. 
                 
                  float indexs        = floor(random.b * 10.0);
                  float indext        = floor(ColAdjust * 10.0);  
                  
//   If random rotation is turned on, multiply a random component of our random 
//      texture by roughly 2 PI (6.3) so the potential exists for a full rotation.
//      We use a standard 2D rotation matrix.
                                  
                  if(RandomRotate)
                  {
                     float rotationAngle = 6.3 * random.g;                 
                     rotator[0]          = vec2(cos(rotationAngle), sin(rotationAngle));
                     rotator[1]          = vec2(-sin(rotationAngle), cos(rotationAngle));
                     glyphIndex          = -rotator * (currentOffSet.st - random.rg);                 
                  }
                  else
                  {
                     glyphIndex       = currentOffSet.st - random.rg;
                  }
                  
//  Here we do a random scaling of the glyph, if the user has selected this option.

                  if(RandomScale)
                  {
                     glyphIndex /= vec2(1.3 * random.r);
                  }   

//  Get the final coordinates in order to display proper glyph.  It is important that we clamp
//      the glyphIndex value, otherwise we will have artifacts.

                  glyphIndex.s               = (clamp(glyphIndex.s, 0.0, 1.0) + indexs) / 10.0;
                  glyphIndex.t               = (clamp(glyphIndex.t, 0.0, 1.0) + indext) / 10.0;
            
                  vec4 image                 = texture2D(glyphTex, glyphIndex);

//  This determines whether or not to draw the image from the texture, or use the background color
//      which is initialized to ModelColor uniform.  Since the texture is black and white, this
//      looks for white areas and does not draw them.  The mix function for the color gives
//      us nice antialiasing for our glyphs.         
                  if(image.x < 0.9 || image.y < 0.9 || image.z < 0.9)
                  {
                     color.rgb = mix(random.rgb, ModelColor, image.rgb);             
                  }
               } 
             }
         
      }
   }
   
   gl_FragColor   = color * LightIntensity;
   
}

