// Laplacian edge detection fragment shader

uniform sampler2DRect  tex;

uniform float offset;

void main( void )
{
	vec2 texCoord = gl_TexCoord[0].st;	

	vec4 center = texture2DRect(tex, texCoord);
	
	vec4 edge = texture2DRect(tex, texCoord + vec2(-offset, -offset)) +
				texture2DRect(tex, texCoord + vec2(-offset,     0.0)) +
				texture2DRect(tex, texCoord + vec2(-offset,  offset)) +
				texture2DRect(tex, texCoord + vec2(     0.0, offset)) +
				texture2DRect(tex, texCoord + vec2( offset,  offset)) +
				texture2DRect(tex, texCoord + vec2( offset,     0.0)) +
				texture2DRect(tex, texCoord + vec2( offset, -offset)) +
				texture2DRect(tex, texCoord + vec2(    0.0, -offset));

	gl_FragColor = 8.0 * (center - 0.125 * edge);
}
