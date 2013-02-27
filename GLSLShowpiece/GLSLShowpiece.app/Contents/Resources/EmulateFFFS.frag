//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

uniform sampler2D Tex;

void main(void)
{
	gl_FragColor = texture2D(Tex, gl_TexCoord[0].st);
}