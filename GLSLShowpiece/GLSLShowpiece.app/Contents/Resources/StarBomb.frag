/******************************************************************************************* 
*   StarBombGL2.frag                                                                        *
*                                                                                          *
*   Copyright (C) 2002-2006  3Dlabs Inc. Ltd.                                              *
*                                                                                          *
*   Based on wallpaper.sl by Darwyn Peachy.                                                *
*   Converted to OpenGL Shading Language by Joshua Doss                                    *
*                                                                                          *
*   From the book Texturing and Modeling: A Procedural Approach_, by David S. Ebert, ed.,  *
*   F. Kenton Musgrave, Darwyn Peachey, Ken Perlin, and Steven Worley.                     *
*   Academic Press, 1994.  ISBN 0-12-228760-6                                              *
*                                                                                          *
*   See 3Dlabs-License.txt for license information                                         *
*******************************************************************************************/

uniform float     NumberCells, NumberPoints, RadiusMin, RadiusMax;
uniform sampler2D RandomTexture;
uniform vec4      StarColor, ModelColor;
uniform float     OffsetScale;

varying vec2  TexCoord;
varying float LightIntensity;

const float PI = 3.14159265358979;

void main(void)
{
   float cellSize = 1.0 / NumberCells;
   float angle, r, a; 
   float in_out = 0.0;
   float starAngle = ((2.0 * PI)/NumberPoints);
   
   vec2 randomXY, cellCenter, cell, center, sstt;
   
   vec3 p0 = RadiusMax * vec3 (cos(0.0), sin(0.0), 0.0);
   vec3 p1 = RadiusMin * vec3 (cos(starAngle/2.0), sin(starAngle/2.0), 0.0);
   vec3 d0 = (p1 - p0);
   vec3 d1;
   
   vec4 useColor, outColor, randomCS, random, color;
   
   cellCenter = vec2(floor(TexCoord.st * NumberCells));
   
   color = ModelColor;
   
   
   for ( float i = -1.0; i <= 0.0; i += 1.0)
   {
      for ( float j = -1.0; j <= 0.0; j += 1.0)
      {
         cell = cellCenter + vec2 ( i, j );
         
         vec2 randomCellSelect = vec2(.0032 * cell.s, .87 * cell.t);
         randomCS = texture2D(RandomTexture, randomCellSelect);
         randomXY = vec2 (cell.s / (cell.s + 0.5), cell.t / (cell.t + 0.5));
         float priority = -1.0;
         random = texture2D(RandomTexture, randomXY);
         if(randomCS.r < 0.5)
         {
             random *= OffsetScale;
             center  = cellSize * (cell + 0.5 + 0.6 * random.rg);
             sstt    = TexCoord.st - center;
             
             angle = atan(sstt.s, sstt.t) + PI;
             r     = sqrt(sstt.s*sstt.s + sstt.t*sstt.t);
             a     = mod (angle, starAngle) / starAngle;
             if(a >= 0.5)
             {
                a = 1.0 - a;
             }
             d1            = r * vec3 (cos(a), sin(a), 0.0) - p0;
             float checkin = step(0.0, cross(d0, d1).z);
             if (checkin  >= 0.5 && random.w > priority)
             {  
               color    = texture2D(RandomTexture, cellSize * (cell + 0.5));
               priority = random.w;
             }          
             in_out += checkin;      
         }           
      }
   }  
   outColor = mix(ModelColor, color, step(0.5, in_out));
   gl_FragColor = vec4( outColor * LightIntensity);
}

