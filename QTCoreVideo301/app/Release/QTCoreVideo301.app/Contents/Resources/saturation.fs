// saturation fragment shader

uniform sampler2DRect tex;

uniform float alpha;

void main( void )
{
	const vec3 lumCoeff = vec3( 0.2125, 0.7154, 0.0721 ); 
	
	vec4 fragColor = texture2DRect( tex, gl_TexCoord[0].st ); 
	vec3 intensity = vec3( dot( fragColor.rgb, lumCoeff ) ); 
	vec3 color     = mix( intensity, fragColor.rgb, alpha );
	
	gl_FragColor = vec4( color, 1.0 );
}
