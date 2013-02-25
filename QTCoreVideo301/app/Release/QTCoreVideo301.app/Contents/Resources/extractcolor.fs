uniform sampler2DRect tex;
uniform float         threshold;
uniform vec3          color;

void main( void )
{
	vec4  sample = texture2DRect( tex, gl_TexCoord[0].st );
	float dist   = distance( sample.rgb, color );
	
	if( dist <= threshold )
	{
		gl_FragColor = vec4( color, 1.0 );
	}
	else
	{
		gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	}
}
