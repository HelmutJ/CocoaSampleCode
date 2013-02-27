//
// Fragment shader for blobby molecules
//
// Author: Jon Kennedy
//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd. 
//
// See 3Dlabs-License.txt for license information
//

uniform sampler2D EnvMap;

//
// Pretty simple env map lookup
//
void main (void)
{
    // Add lighting to base color and mix
    vec3 envColor = vec3(texture2D(EnvMap, gl_TexCoord[0].st));
    gl_FragColor = vec4(envColor, 1.0);
}
