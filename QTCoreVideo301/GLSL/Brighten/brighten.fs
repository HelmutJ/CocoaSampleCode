uniform sampler2DRect tex;

uniform float exposure;

void main(void)
{
	const float bloomStart = 0.85;
	const vec4  bloomvec   = vec4(bloomStart);
 
   	vec4 color = texture2DRect(tex,gl_TexCoord[0].st)*exposure;
	
	gl_FragColor =  max(vec4(0.0),color-bloomvec);
}
